import '../data/salon_repository.dart';
import '../models/cliente.dart';
import '../models/estilista.dart';
import '../models/servicio.dart';
import '../models/turno.dart';
import 'base_view_model.dart';

/// Estado de la pantalla Detalle de turno (`/turno/:id`).
class TurnoDetalleViewModel extends RepoViewModel {
  TurnoDetalleViewModel(super.repo, String? idTexto) : turnoId = int.tryParse(idTexto ?? '');

  /// `null` si el parámetro de la ruta no es un número.
  final int? turnoId;

  Turno? get turno => turnoId == null ? null : repo.turno(turnoId!);
  bool get existe => turno != null;

  Cliente? get cliente => turno == null ? null : repo.cliente(turno!.clienteId);
  Estilista? get estilista => turno == null ? null : repo.estilista(turno!.estilistaId);
  List<Servicio> get servicios => turno == null ? const [] : repo.serviciosDe(turno!.servicioIds);

  bool get editable => turno?.esProgramado ?? false;

  String? completar() {
    try {
      repo.completarTurno(turnoId!);
      return null;
    } on ReglaNegocioException catch (e) {
      return e.mensaje;
    }
  }

  String? cancelar() {
    try {
      repo.cancelarTurno(turnoId!);
      return null;
    } on ReglaNegocioException catch (e) {
      return e.mensaje;
    }
  }
}
