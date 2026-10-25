import 'package:flutter/foundation.dart';

import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/horario.dart';
import '../models/servicio.dart';
import '../models/turno.dart';
import 'datos_prueba.dart';

/// Error de una regla de negocio (solape, horario, estado...).
class ReglaNegocioException implements Exception {
  const ReglaNegocioException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Fuente única de datos en memoria y reglas del modelo.
///
/// No hay servidor, base de datos ni almacenamiento local: todo se carga de
/// los datos de prueba al iniciar y vive mientras la app está en ejecución.
/// Notifica a los ViewModels cualquier cambio en turnos o clientes para que se
/// refleje de inmediato en todas las pantallas.
class SalonRepository extends ChangeNotifier {
  SalonRepository({
    required List<Servicio> servicios,
    required List<Estilista> estilistas,
    required List<Cliente> clientes,
    required List<Turno> turnos,
    DateTime Function()? reloj,
  })  : _servicios = List.unmodifiable(servicios),
        _estilistas = List.unmodifiable(estilistas),
        _clientes = [...clientes],
        _turnos = [...turnos],
        _reloj = reloj ?? DateTime.now {
    _siguienteClienteId =
        _clientes.fold<int>(0, (m, c) => c.id > m ? c.id : m) + 1;
    _siguienteTurnoId = _turnos.fold<int>(0, (m, t) => t.id > m ? t.id : m) + 1;
  }

  /// Repositorio con los datos de prueba calculados a partir de `DateTime.now()`.
  factory SalonRepository.conDatosDePrueba([DateTime Function()? reloj]) {
    final r = reloj ?? DateTime.now;
    final datos = DatosPrueba.generar(r());
    return SalonRepository(
      servicios: datos.servicios,
      estilistas: datos.estilistas,
      clientes: datos.clientes,
      turnos: datos.turnos,
      reloj: r,
    );
  }

  final List<Servicio> _servicios;
  final List<Estilista> _estilistas;
  final List<Cliente> _clientes;
  final List<Turno> _turnos;
  final DateTime Function() _reloj;
  late int _siguienteClienteId;
  late int _siguienteTurnoId;

  DateTime get ahora => _reloj();

  // ---------------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------------

  /// Catálogo de solo lectura.
  List<Servicio> get servicios => _servicios;

  /// Estilistas de solo lectura.
  List<Estilista> get estilistas => _estilistas;

  List<Cliente> get clientes => List.unmodifiable(_clientes);

  List<Turno> get turnos => List.unmodifiable(_turnos);

  Servicio? servicio(int id) => _buscar(_servicios, (s) => s.id == id);

  Estilista? estilista(int id) => _buscar(_estilistas, (e) => e.id == id);

  Cliente? cliente(int id) => _buscar(_clientes, (c) => c.id == id);

  Turno? turno(int id) => _buscar(_turnos, (t) => t.id == id);

  static T? _buscar<T>(Iterable<T> items, bool Function(T) test) {
    for (final i in items) {
      if (test(i)) return i;
    }
    return null;
  }

  List<Servicio> serviciosDe(Iterable<int> ids) =>
      ids.map(servicio).whereType<Servicio>().toList();

  /// Suma de las duraciones de los servicios.
  int duracionDe(Iterable<int> servicioIds) =>
      serviciosDe(servicioIds).fold(0, (s, x) => s + x.duracionMin);

  /// Suma de los precios de los servicios.
  double precioDe(Iterable<int> servicioIds) =>
      serviciosDe(servicioIds).fold(0.0, (s, x) => s + x.precio);

  DateTime finDe(Turno t) => t.inicio.add(Duration(minutes: duracionDe(t.servicioIds)));

  double totalDe(Turno t) => precioDe(t.servicioIds);

  /// "Corte caballero + Barba"
  String resumenServicios(Iterable<int> ids) =>
      serviciosDe(ids).map((s) => s.nombre).join(' + ');

  List<Turno> turnosDelDia(DateTime fecha) {
    final l = _turnos.where((t) => HorarioSalon.mismoDia(t.inicio, fecha)).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    return l;
  }

  /// Historial de un cliente, del más reciente al más antiguo.
  List<Turno> turnosDeCliente(int clienteId) {
    final l = _turnos.where((t) => t.clienteId == clienteId).toList()
      ..sort((a, b) => b.inicio.compareTo(a.inicio));
    return l;
  }

  int turnosProgramadosDeCliente(int clienteId) => _turnos
      .where((t) => t.clienteId == clienteId && t.esProgramado)
      .length;

  int turnosProgramadosHoy(int estilistaId) {
    final hoy = ahora;
    return _turnos
        .where((t) =>
            t.estilistaId == estilistaId &&
            t.esProgramado &&
            HorarioSalon.mismoDia(t.inicio, hoy))
        .length;
  }

  /// Solo se ofrecen los estilistas que realizan todos los servicios elegidos.
  List<Estilista> estilistasPara(Iterable<int> servicioIds) {
    final ids = servicioIds.toList();
    if (ids.isEmpty) return const [];
    return _estilistas.where((e) => e.realizaTodos(ids)).toList();
  }

  bool telefonoEnUso(String telefono, {int? exceptoClienteId}) => _clientes
      .any((c) => c.telefono == telefono && c.id != exceptoClienteId);

  // ---------------------------------------------------------------------------
  // Reglas de horario y solapes
  // ---------------------------------------------------------------------------

  /// Turnos programados que ocupan horario (los cancelados no ocupan).
  Iterable<Turno> _ocupantes({int? excluirTurnoId}) =>
      _turnos.where((t) => t.esProgramado && t.id != excluirTurnoId);

  bool _haySolape({
    required DateTime inicio,
    required DateTime fin,
    required bool Function(Turno) aplica,
    int? excluirTurnoId,
  }) {
    for (final t in _ocupantes(excluirTurnoId: excluirTurnoId)) {
      if (!aplica(t)) continue;
      if (HorarioSalon.seSolapan(inicio, fin, t.inicio, finDe(t))) return true;
    }
    return false;
  }

  /// Franjas de 30 minutos de un día con su disponibilidad.
  ///
  /// Una franja no está disponible si ya pasó (cuando la fecha es hoy), si el
  /// turno no terminaría a las 19:00 como máximo, o si el estilista o el
  /// cliente ya tienen un turno programado que se solapa. Al editar, el propio
  /// turno ([excluirTurnoId]) no cuenta como solape consigo mismo.
  List<FranjaHoraria> franjas({
    required DateTime fecha,
    required int duracionMin,
    int? estilistaId,
    int? clienteId,
    int? excluirTurnoId,
  }) {
    final dur = duracionMin <= 0 ? HorarioSalon.franjaMin : duracionMin;
    final cierre = HorarioSalon.cierre(fecha);
    final momento = ahora;
    return [
      for (final inicio in HorarioSalon.franjasDe(fecha))
        FranjaHoraria(
          inicio,
          _motivo(
            inicio: inicio,
            fin: inicio.add(Duration(minutes: dur)),
            cierre: cierre,
            momento: momento,
            estilistaId: estilistaId,
            clienteId: clienteId,
            excluirTurnoId: excluirTurnoId,
          ),
        ),
    ];
  }

  MotivoNoDisponible? _motivo({
    required DateTime inicio,
    required DateTime fin,
    required DateTime cierre,
    required DateTime momento,
    int? estilistaId,
    int? clienteId,
    int? excluirTurnoId,
  }) {
    if (inicio.isBefore(momento)) return MotivoNoDisponible.pasada;
    if (fin.isAfter(cierre)) return MotivoNoDisponible.excedeCierre;
    if (estilistaId != null &&
        _haySolape(
          inicio: inicio,
          fin: fin,
          aplica: (t) => t.estilistaId == estilistaId,
          excluirTurnoId: excluirTurnoId,
        )) {
      return MotivoNoDisponible.ocupadaEstilista;
    }
    if (clienteId != null &&
        _haySolape(
          inicio: inicio,
          fin: fin,
          aplica: (t) => t.clienteId == clienteId,
          excluirTurnoId: excluirTurnoId,
        )) {
      return MotivoNoDisponible.ocupadaCliente;
    }
    return null;
  }

  /// Valida todas las reglas de un turno. Devuelve `null` si es válido o el
  /// mensaje del primer error.
  String? validarTurno({
    required int? clienteId,
    required int? estilistaId,
    required List<int> servicioIds,
    required DateTime? inicio,
    int? excluirTurnoId,
  }) {
    if (clienteId == null || cliente(clienteId) == null) {
      return 'Selecciona un cliente';
    }
    if (servicioIds.isEmpty) return 'Elige al menos un servicio';
    if (serviciosDe(servicioIds).length != servicioIds.length) {
      return 'Hay servicios que no existen en el catálogo';
    }
    final est = estilistaId == null ? null : estilista(estilistaId);
    if (est == null) return 'Selecciona un estilista';
    if (!est.realizaTodos(servicioIds)) {
      return '${est.nombreCorto} no realiza todos los servicios elegidos';
    }
    if (inicio == null) return 'Elige una hora para el turno';
    if (!HorarioSalon.abre(inicio)) return 'El salón cierra los domingos';
    if (!HorarioSalon.esInicioDeFranja(inicio)) {
      return 'El turno debe empezar en una franja de 30 minutos entre 9:00 y 19:00';
    }
    if (inicio.isBefore(ahora)) {
      return 'No se pueden programar turnos en una fecha y hora que ya pasaron';
    }
    final fin = inicio.add(Duration(minutes: duracionDe(servicioIds)));
    if (fin.isAfter(HorarioSalon.cierre(inicio))) {
      return 'El turno terminaría después de las 19:00';
    }
    if (_haySolape(
      inicio: inicio,
      fin: fin,
      aplica: (t) => t.estilistaId == estilistaId,
      excluirTurnoId: excluirTurnoId,
    )) {
      return '${est.nombreCorto} ya tiene un turno en ese horario';
    }
    if (_haySolape(
      inicio: inicio,
      fin: fin,
      aplica: (t) => t.clienteId == clienteId,
      excluirTurnoId: excluirTurnoId,
    )) {
      return 'El cliente ya tiene un turno en ese horario';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Turnos: alta, edición, completar, cancelar
  // ---------------------------------------------------------------------------

  Turno crearTurno({
    required int clienteId,
    required int estilistaId,
    required List<int> servicioIds,
    required DateTime inicio,
    String? notas,
  }) {
    final error = validarTurno(
      clienteId: clienteId,
      estilistaId: estilistaId,
      servicioIds: servicioIds,
      inicio: inicio,
    );
    if (error != null) throw ReglaNegocioException(error);
    final momento = ahora;
    final t = Turno(
      id: _siguienteTurnoId++,
      clienteId: clienteId,
      estilistaId: estilistaId,
      servicioIds: List.unmodifiable(servicioIds),
      inicio: inicio,
      notas: _limpiar(notas),
      estado: EstadoTurno.programado,
      creado: momento,
      modificado: momento,
    );
    _turnos.add(t);
    notifyListeners();
    return t;
  }

  Turno actualizarTurno({
    required int turnoId,
    required int clienteId,
    required int estilistaId,
    required List<int> servicioIds,
    required DateTime inicio,
    String? notas,
  }) {
    final actual = _exigirProgramado(turnoId);
    final error = validarTurno(
      clienteId: clienteId,
      estilistaId: estilistaId,
      servicioIds: servicioIds,
      inicio: inicio,
      excluirTurnoId: turnoId,
    );
    if (error != null) throw ReglaNegocioException(error);
    final notasLimpias = _limpiar(notas);
    final nuevo = actual.copyWith(
      clienteId: clienteId,
      estilistaId: estilistaId,
      servicioIds: List.unmodifiable(servicioIds),
      inicio: inicio,
      notas: notasLimpias,
      borrarNotas: notasLimpias == null,
      modificado: ahora,
    );
    _reemplazar(nuevo);
    return nuevo;
  }

  Turno completarTurno(int turnoId) =>
      _cambiarEstado(turnoId, EstadoTurno.completado);

  /// Los turnos no se eliminan: la baja es la cancelación. Su horario queda libre.
  Turno cancelarTurno(int turnoId) =>
      _cambiarEstado(turnoId, EstadoTurno.cancelado);

  Turno _cambiarEstado(int turnoId, EstadoTurno estado) {
    final actual = _exigirProgramado(turnoId);
    final nuevo = actual.copyWith(estado: estado, modificado: ahora);
    _reemplazar(nuevo);
    return nuevo;
  }

  /// Solo los turnos programados se pueden editar, completar o cancelar.
  Turno _exigirProgramado(int turnoId) {
    final t = turno(turnoId);
    if (t == null) throw const ReglaNegocioException('El turno no existe');
    if (!t.esProgramado) {
      throw ReglaNegocioException(
          'Solo los turnos programados se pueden modificar (este está ${t.estado.etiqueta.toLowerCase()})');
    }
    return t;
  }

  void _reemplazar(Turno t) {
    final i = _turnos.indexWhere((x) => x.id == t.id);
    _turnos[i] = t;
    notifyListeners();
  }

  static String? _limpiar(String? s) {
    final v = s?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  // ---------------------------------------------------------------------------
  // Clientes
  // ---------------------------------------------------------------------------

  Cliente crearCliente({
    required String nombre,
    required String telefono,
    required Genero genero,
    String? correo,
  }) {
    if (telefonoEnUso(telefono)) {
      throw const ReglaNegocioException('Ese teléfono ya está registrado');
    }
    final c = Cliente(
      id: _siguienteClienteId++,
      nombre: nombre.trim(),
      telefono: telefono,
      genero: genero,
      correo: _limpiar(correo),
      fechaRegistro: ahora,
    );
    _clientes.add(c);
    notifyListeners();
    return c;
  }

  Cliente actualizarCliente({
    required int clienteId,
    required String nombre,
    required String telefono,
    required Genero genero,
    String? correo,
  }) {
    final actual = cliente(clienteId);
    if (actual == null) throw const ReglaNegocioException('El cliente no existe');
    if (telefonoEnUso(telefono, exceptoClienteId: clienteId)) {
      throw const ReglaNegocioException('Ese teléfono ya está registrado');
    }
    final correoLimpio = _limpiar(correo);
    final nuevo = actual.copyWith(
      nombre: nombre.trim(),
      telefono: telefono,
      genero: genero,
      correo: correoLimpio,
      borrarCorreo: correoLimpio == null,
    );
    final i = _clientes.indexWhere((c) => c.id == clienteId);
    _clientes[i] = nuevo;
    notifyListeners();
    return nuevo;
  }

  /// No se puede eliminar un cliente con turnos programados. Si no los tiene,
  /// se elimina junto con su historial de turnos completados y cancelados.
  void eliminarCliente(int clienteId) {
    final c = cliente(clienteId);
    if (c == null) throw const ReglaNegocioException('El cliente no existe');
    final programados = turnosProgramadosDeCliente(clienteId);
    if (programados > 0) {
      throw ReglaNegocioException(
          'No se puede eliminar: ${c.nombre} tiene $programados ${programados == 1 ? 'turno programado' : 'turnos programados'}.');
    }
    _turnos.removeWhere((t) => t.clienteId == clienteId);
    _clientes.removeWhere((x) => x.id == clienteId);
    notifyListeners();
  }
}
