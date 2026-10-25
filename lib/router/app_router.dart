import 'package:go_router/go_router.dart';

import '../core/app_keys.dart';
import '../viewmodels/turno_form_view_model.dart';
import '../views/agenda/agenda_screen.dart';
import '../views/clientes/clientes_screen.dart';
import '../views/estilistas/estilistas_screen.dart';
import '../views/servicios/servicios_screen.dart';
import '../views/shell/main_shell.dart';
import '../views/shell/ruta_no_encontrada.dart';
import '../views/turno/turno_detalle_screen.dart';
import '../views/turno/turno_form_screen.dart';

/// Navegación de Turco: solo go_router.
///
/// | Ruta               | Pantalla                                   |
/// |--------------------|--------------------------------------------|
/// | /agenda (inicial)  | Agenda (query `estilista`)                 |
/// | /clientes          | Clientes                                   |
/// | /servicios         | Servicios                                  |
/// | /estilistas        | Estilistas                                 |
/// | /turno/nuevo       | Formulario (crear, datos con `extra`)      |
/// | /turno/:id         | Detalle (pathParameters)                   |
/// | /turno/:id/editar  | Formulario (editar)                        |
GoRouter crearRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/agenda',
    redirect: (context, state) => state.uri.path == '/' ? '/agenda' : null,
    errorBuilder: (context, state) => RutaNoEncontrada(ruta: state.uri.toString()),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/agenda',
              builder: (context, state) =>
                  AgendaScreen(estilistaQuery: state.uri.queryParameters['estilista']),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/clientes', builder: (context, state) => const ClientesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/servicios', builder: (context, state) => const ServiciosScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/estilistas', builder: (context, state) => const EstilistasScreen()),
          ]),
        ],
      ),
      // Detalle y Formulario se abren por encima de la barra inferior.
      GoRoute(
        path: '/turno/nuevo',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          return TurnoFormScreen(args: extra is TurnoFormArgs ? extra : null);
        },
      ),
      GoRoute(
        path: '/turno/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => TurnoDetalleScreen(idTexto: state.pathParameters['id']),
        routes: [
          GoRoute(
            path: 'editar',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => TurnoFormScreen(turnoIdTexto: state.pathParameters['id']),
          ),
        ],
      ),
    ],
  );
}

