import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Contenedor de las cuatro pestañas (StatefulShellRoute.indexedStack) con la
/// barra de navegación inferior. Cada destino conserva su estado.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _ir(int i) {
    // Tocar de nuevo la pestaña activa vuelve a su ruta inicial.
    navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return PopScope(
      // Botón atrás coherente: desde otra pestaña vuelve a la Agenda; en la
      // Agenda sale de la app.
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Material(
        color: s.surface,
        child: Column(
          children: [
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: navigationShell,
              ),
            ),
            NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _ir,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Agenda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Clientes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.content_cut),
                  selectedIcon: Icon(Icons.content_cut),
                  label: 'Servicios',
                ),
                NavigationDestination(
                  icon: Icon(Icons.badge_outlined),
                  selectedIcon: Icon(Icons.badge),
                  label: 'Estilistas',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
