import 'package:flutter/widgets.dart';

import '../data/salon_repository.dart';
import '../viewmodels/agenda_view_model.dart';
import '../viewmodels/clientes_view_model.dart';
import '../viewmodels/estilistas_view_model.dart';
import '../viewmodels/servicios_view_model.dart';
import '../viewmodels/tema_view_model.dart';

/// Inyección de dependencias con un [InheritedWidget] de Flutter (sin paquetes
/// externos de estado). Expone el repositorio y los ViewModels de larga vida
/// de cada pestaña, que así conservan su estado al cambiar de destino.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repo,
    required this.tema,
    required this.agenda,
    required this.clientes,
    required this.servicios,
    required this.estilistas,
    required super.child,
  });

  final SalonRepository repo;
  final TemaViewModel tema;
  final AgendaViewModel agenda;
  final ClientesViewModel clientes;
  final ServiciosViewModel servicios;
  final EstilistasViewModel estilistas;

  /// Las instancias nunca cambian, por eso no se registra dependencia.
  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No hay AppScope en el árbol de widgets');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
