import 'package:flutter/foundation.dart';

import '../data/salon_repository.dart';
import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/horario.dart';
import '../models/servicio.dart';
import '../models/turno.dart';
import 'base_view_model.dart';

/// Datos iniciales que otras pantallas envían al formulario (viajan con `extra`).
@immutable
class TurnoFormArgs {
  const TurnoFormArgs({this.clienteId, this.servicioId, this.fecha});

  final int? clienteId;
  final int? servicioId;
  final DateTime? fecha;
}

@immutable
class _Instantanea {
  const _Instantanea(this.clienteId, this.servicios, this.estilistaId, this.fecha, this.hora, this.notas);

  final int? clienteId;
  final List<int> servicios;
  final int? estilistaId;
  final DateTime? fecha;
  final DateTime? hora;
  final String notas;

  bool igualA(_Instantanea o) =>
      clienteId == o.clienteId &&
      listEquals(servicios, o.servicios) &&
      estilistaId == o.estilistaId &&
      fecha == o.fecha &&
      hora == o.hora &&
      notas.trim() == o.notas.trim();
}

/// Estado y reglas del Formulario de turno (crear y editar).
///
/// Las reglas (estilistas válidos, franjas libres, duración, fin y precio)
/// se calculan aquí o en el repositorio, nunca dentro de los widgets.
class TurnoFormViewModel extends RepoViewModel {
  TurnoFormViewModel(super.repo, {this.turnoId, TurnoFormArgs? args}) {
    if (turnoId != null) {
      _cargarTurno(turnoId!);
    } else {
      _aplicarArgs(args);
    }
    _inicial = _instantanea();
  }

  static const int maxNotas = 500;

  /// Id del turno que se edita; `null` al crear.
  final int? turnoId;

  int? _clienteId;
  FiltroGenero _publico = FiltroGenero.todos;
  final List<int> _servicios = [];
  int? _estilistaId;
  DateTime? _fecha;
  DateTime? _hora;
  String _notas = '';
  bool _turnoInvalido = false;
  bool _guardando = false;
  late _Instantanea _inicial;

  bool get esEdicion => turnoId != null;

  /// Se intentó editar un turno que no existe o que ya no está programado.
  bool get turnoInvalido => _turnoInvalido;

  int? get clienteId => _clienteId;
  FiltroGenero get publico => _publico;
  List<int> get servicios => List.unmodifiable(_servicios);
  int? get estilistaId => _estilistaId;
  DateTime? get fecha => _fecha;
  DateTime? get hora => _hora;
  String get notas => _notas;

  List<Cliente> get clientes {
    final l = [...repo.clientes]..sort((a, b) => a.nombre.compareTo(b.nombre));
    return l;
  }

  Cliente? get cliente => _clienteId == null ? null : repo.cliente(_clienteId!);
  Estilista? get estilista => _estilistaId == null ? null : repo.estilista(_estilistaId!);

  bool get hayCambios => !_instantanea().igualA(_inicial);

  // ---------------------------------------------------------------------------
  // Inicialización
  // ---------------------------------------------------------------------------

  void _cargarTurno(int id) {
    final t = repo.turno(id);
    if (t == null || !t.esProgramado) {
      _turnoInvalido = true;
      return;
    }
    _clienteId = t.clienteId;
    final c = repo.cliente(t.clienteId);
    if (c != null) _publico = FiltroGenero.desdeGenero(c.genero);
    _servicios.addAll(t.servicioIds);
    _estilistaId = t.estilistaId;
    _fecha = HorarioSalon.soloFecha(t.inicio);
    _hora = t.inicio;
    _notas = t.notas ?? '';
  }

  void _aplicarArgs(TurnoFormArgs? args) {
    if (args == null) return;
    if (args.clienteId != null && repo.cliente(args.clienteId!) != null) {
      _clienteId = args.clienteId;
      _publico = FiltroGenero.desdeGenero(repo.cliente(args.clienteId!)!.genero);
    }
    if (args.servicioId != null) {
      final s = repo.servicio(args.servicioId!);
      if (s != null) {
        _servicios.add(s.id);
        // Si el filtro de público ocultaría el servicio elegido, se muestra todo.
        if (!_publico.aceptaPublico(s.publico)) _publico = FiltroGenero.todos;
      }
    }
    if (args.fecha != null && esFechaPermitida(args.fecha!)) {
      _fecha = HorarioSalon.soloFecha(args.fecha!);
    }
  }

  _Instantanea _instantanea() =>
      _Instantanea(_clienteId, List.of(_servicios), _estilistaId, _fecha, _hora, _notas);

  // ---------------------------------------------------------------------------
  // Cliente y público
  // ---------------------------------------------------------------------------

  /// Al elegir un cliente, el filtro de público se ajusta por defecto a su género.
  void seleccionarCliente(int? id) {
    _clienteId = id;
    final c = cliente;
    if (c != null) _publico = FiltroGenero.desdeGenero(c.genero);
    _revalidarHora();
    notifyListeners();
  }

  void cambiarPublico(FiltroGenero f) {
    _publico = f;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Servicios y estilista
  // ---------------------------------------------------------------------------

  /// Servicios agrupados por categoría según el filtro de público. Los ya
  /// elegidos se muestran siempre para poder quitarlos.
  Map<Categoria, List<Servicio>> get serviciosPorCategoria {
    final mapa = <Categoria, List<Servicio>>{};
    for (final cat in Categoria.values) {
      final l = repo.servicios
          .where((s) => s.categoria == cat)
          .where((s) => _publico.aceptaPublico(s.publico) || _servicios.contains(s.id))
          .toList();
      if (l.isNotEmpty) mapa[cat] = l;
    }
    return mapa;
  }

  bool estaElegido(int servicioId) => _servicios.contains(servicioId);

  /// Solo los estilistas que realizan todos los servicios elegidos.
  List<Estilista> get estilistasDisponibles => repo.estilistasPara(_servicios);

  /// Activa o desactiva un servicio. Si el estilista elegido deja de ser
  /// válido, se limpia la selección y se devuelve el aviso para mostrarlo.
  String? alternarServicio(int servicioId) {
    if (_servicios.contains(servicioId)) {
      _servicios.remove(servicioId);
    } else {
      _servicios.add(servicioId);
    }
    String? aviso;
    final e = estilista;
    if (e != null && (_servicios.isEmpty || !e.realizaTodos(_servicios))) {
      _estilistaId = null;
      aviso = '${e.nombreCorto} no realiza todos los servicios elegidos. Elige otro estilista.';
    }
    final horaPerdida = _revalidarHora();
    if (aviso == null && horaPerdida) {
      aviso = 'La hora elegida ya no está disponible con estos servicios.';
    }
    notifyListeners();
    return aviso;
  }

  void seleccionarEstilista(int? id) {
    _estilistaId = id;
    _revalidarHora();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Fecha y hora
  // ---------------------------------------------------------------------------

  DateTime get primeraFecha => HorarioSalon.proximoDiaHabil(repo.ahora);
  DateTime get ultimaFecha {
    final h = repo.ahora;
    return DateTime(h.year + 1, h.month, h.day);
  }

  /// No se permiten fechas pasadas ni domingos (ni posteriores a [ultimaFecha],
  /// el límite del selector de fecha).
  bool esFechaPermitida(DateTime d) {
    final hoy = HorarioSalon.soloFecha(repo.ahora);
    final dia = HorarioSalon.soloFecha(d);
    return HorarioSalon.abre(d) && !dia.isBefore(hoy) && !dia.isAfter(ultimaFecha);
  }

  void seleccionarFecha(DateTime d) {
    _fecha = HorarioSalon.soloFecha(d);
    if (_hora != null) {
      _hora = DateTime(_fecha!.year, _fecha!.month, _fecha!.day, _hora!.hour, _hora!.minute);
    }
    _revalidarHora();
    notifyListeners();
  }

  /// Franjas de 30 minutos del día, recalculadas con los servicios, el
  /// estilista, el cliente y la fecha actuales.
  List<FranjaHoraria> get franjas {
    if (_fecha == null) return const [];
    return repo.franjas(
      fecha: _fecha!,
      duracionMin: duracion,
      estilistaId: _estilistaId,
      clienteId: _clienteId,
      excluirTurnoId: turnoId,
    );
  }

  bool get hayFranjasLibres => franjas.any((f) => f.disponible);

  void seleccionarHora(DateTime inicio) {
    _hora = inicio;
    notifyListeners();
  }

  bool esHoraElegida(DateTime inicio) => _hora != null && _hora == inicio;

  /// Si la hora elegida dejó de estar libre, se limpia. Devuelve `true` si se limpió.
  bool _revalidarHora() {
    if (_hora == null || _fecha == null) return false;
    final libre = franjas.any((f) => f.inicio == _hora && f.disponible);
    if (!libre) {
      _hora = null;
      return true;
    }
    return false;
  }

  @override
  void alCambiarRepositorio() {
    // Al guardar, el propio turno nuevo ocupa la franja: no se debe limpiar la hora.
    if (!_guardando) _revalidarHora();
  }

  // ---------------------------------------------------------------------------
  // Notas y resumen
  // ---------------------------------------------------------------------------

  void cambiarNotas(String v) {
    _notas = v;
    notifyListeners();
  }

  int get duracion => repo.duracionDe(_servicios);
  double get precio => repo.precioDe(_servicios);
  DateTime? get fin => _hora?.add(Duration(minutes: duracion));

  // ---------------------------------------------------------------------------
  // Validaciones (mensajes bajo cada campo)
  // ---------------------------------------------------------------------------

  String? validarCliente() => _clienteId == null ? 'Selecciona un cliente' : null;

  String? validarServicios() => _servicios.isEmpty ? 'Elige al menos un servicio' : null;

  String? validarEstilista() {
    if (_estilistaId == null) return 'Selecciona un estilista';
    if (!estilistasDisponibles.any((e) => e.id == _estilistaId)) {
      return 'El estilista no realiza todos los servicios elegidos';
    }
    return null;
  }

  String? validarFecha() {
    if (_fecha == null || !esFechaPermitida(_fecha!)) {
      return 'Elige una fecha válida (no domingos)';
    }
    return null;
  }

  String? validarHora() {
    if (_hora == null) return 'Elige una hora para el turno';
    final f = franjas.where((x) => x.inicio == _hora);
    if (f.isEmpty || !f.first.disponible) return 'La hora elegida ya no está disponible';
    return null;
  }

  String? validarNotas(String? v) =>
      (v ?? '').length > maxNotas ? 'Máximo $maxNotas caracteres' : null;

  // ---------------------------------------------------------------------------
  // Guardar
  // ---------------------------------------------------------------------------

  /// Crea o actualiza el turno. Lanza [ReglaNegocioException] si alguna regla falla.
  Turno guardar() {
    _guardando = true;
    try {
      return _guardar();
    } finally {
      _guardando = false;
    }
  }

  Turno _guardar() {
    final Turno t;
    if (esEdicion) {
      t = repo.actualizarTurno(
        turnoId: turnoId!,
        clienteId: _clienteId!,
        estilistaId: _estilistaId!,
        servicioIds: List.of(_servicios),
        inicio: _hora!,
        notas: _notas,
      );
    } else {
      final error = repo.validarTurno(
        clienteId: _clienteId,
        estilistaId: _estilistaId,
        servicioIds: _servicios,
        inicio: _hora,
      );
      if (error != null) throw ReglaNegocioException(error);
      t = repo.crearTurno(
        clienteId: _clienteId!,
        estilistaId: _estilistaId!,
        servicioIds: List.of(_servicios),
        inicio: _hora!,
        notas: _notas,
      );
    }
    _inicial = _instantanea();
    return t;
  }
}
