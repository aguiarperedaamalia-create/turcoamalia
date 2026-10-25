import 'package:flutter/foundation.dart';

import '../data/salon_repository.dart';
import '../models/turno.dart';

/// ViewModel que escucha al repositorio y vuelve a notificar a su vista, de
/// modo que los cambios en turnos y clientes se reflejan en todas las pantallas.
abstract class RepoViewModel extends ChangeNotifier {
  RepoViewModel(this.repo) {
    repo.addListener(_alCambiarRepositorio);
  }

  final SalonRepository repo;
  bool _desechado = false;

  void _alCambiarRepositorio() {
    alCambiarRepositorio();
    if (!_desechado) notifyListeners();
  }

  /// Punto de extensión para recalcular estado derivado.
  @protected
  void alCambiarRepositorio() {}

  // Textos de presentación comunes de un turno.
  String nombreCliente(Turno t) => repo.cliente(t.clienteId)?.nombre ?? 'Cliente eliminado';
  String nombreEstilista(Turno t) => repo.estilista(t.estilistaId)?.nombreCorto ?? '—';
  String serviciosDe(Turno t) => repo.resumenServicios(t.servicioIds);
  DateTime finDe(Turno t) => repo.finDe(t);
  double totalDe(Turno t) => repo.totalDe(t);
  int duracionDe(Turno t) => repo.duracionDe(t.servicioIds);

  @override
  void dispose() {
    _desechado = true;
    repo.removeListener(_alCambiarRepositorio);
    super.dispose();
  }
}
