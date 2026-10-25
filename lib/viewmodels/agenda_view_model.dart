import '../data/salon_repository.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/horario.dart';
import '../models/turno.dart';
import 'base_view_model.dart';

/// Resumen del día mostrado en la Agenda.
class ResumenDia {
  const ResumenDia({required this.programados, required this.completados, required this.ingreso});

  final int programados;
  final int completados;

  /// Suma de los totales de turnos programados y completados (sin cancelados).
  final double ingreso;
}

/// Estado de la pantalla Agenda: fecha seleccionada y filtros. Vive mientras la
/// app está abierta, así la pestaña conserva su estado al cambiar de destino.
class AgendaViewModel extends RepoViewModel {
  AgendaViewModel(SalonRepository repo)
      : _fecha = HorarioSalon.proximoDiaHabil(repo.ahora),
        super(repo);

  DateTime _fecha;
  int? _estilistaId;
  FiltroEstado _filtroEstado = FiltroEstado.todos;

  DateTime get fecha => _fecha;
  int? get estilistaId => _estilistaId;
  FiltroEstado get filtroEstado => _filtroEstado;

  List<Estilista> get estilistas => repo.estilistas;

  /// Los siete días (lunes a domingo) de la semana de la fecha seleccionada.
  List<DateTime> get diasSemana {
    final lunes = HorarioSalon.lunesDe(_fecha);
    return [for (var i = 0; i < 7; i++) DateTime(lunes.year, lunes.month, lunes.day + i)];
  }

  bool esSeleccionado(DateTime d) => HorarioSalon.mismoDia(d, _fecha);
  bool esHoy(DateTime d) => HorarioSalon.mismoDia(d, repo.ahora);
  bool estaCerrado(DateTime d) => !HorarioSalon.abre(d);

  List<Turno> get turnosDelDia => repo.turnosDelDia(_fecha);

  bool get diaSinTurnos => turnosDelDia.isEmpty;

  /// Turnos del día ordenados por hora y filtrados por estilista y estado.
  List<Turno> get turnosFiltrados => turnosDelDia
      .where((t) => _estilistaId == null || t.estilistaId == _estilistaId)
      .where((t) => _filtroEstado.acepta(t.estado))
      .toList();

  ResumenDia get resumen {
    var p = 0, c = 0;
    var ingreso = 0.0;
    for (final t in turnosDelDia) {
      if (t.estado == EstadoTurno.cancelado) continue;
      if (t.estado == EstadoTurno.programado) p++;
      if (t.estado == EstadoTurno.completado) c++;
      ingreso += repo.totalDe(t);
    }
    return ResumenDia(programados: p, completados: c, ingreso: ingreso);
  }

  void seleccionarFecha(DateTime d) {
    if (!HorarioSalon.abre(d)) return;
    final nueva = HorarioSalon.soloFecha(d);
    if (HorarioSalon.mismoDia(nueva, _fecha)) return;
    _fecha = nueva;
    notifyListeners();
  }

  void semanaAnterior() => _moverSemana(-7);
  void semanaSiguiente() => _moverSemana(7);

  void _moverSemana(int dias) {
    _fecha = DateTime(_fecha.year, _fecha.month, _fecha.day + dias);
    notifyListeners();
  }

  void filtrarEstilista(int? id) {
    if (id == _estilistaId) return;
    _estilistaId = id;
    notifyListeners();
  }

  void filtrarEstado(FiltroEstado f) {
    if (f == _filtroEstado) return;
    _filtroEstado = f;
    notifyListeners();
  }

  /// Acción rápida: devuelve `null` si salió bien o el mensaje de error.
  String? completar(int turnoId) {
    try {
      repo.completarTurno(turnoId);
      return null;
    } on ReglaNegocioException catch (e) {
      return e.mensaje;
    }
  }

  String? cancelar(int turnoId) {
    try {
      repo.cancelarTurno(turnoId);
      return null;
    } on ReglaNegocioException catch (e) {
      return e.mensaje;
    }
  }
}
