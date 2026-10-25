import 'package:flutter/material.dart';

import '../../core/app_scope.dart';

/// Botón de la barra superior para cambiar entre tema del sistema, claro u oscuro.
class SelectorTema extends StatelessWidget {
  const SelectorTema({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = AppScope.of(context).tema;
    final s = Theme.of(context).colorScheme;

    PopupMenuItem<ThemeMode> opcion(ThemeMode modo, IconData icono, String texto) {
      final elegido = tema.modo == modo;
      return PopupMenuItem<ThemeMode>(
        value: modo,
        height: 44,
        child: Row(
          children: [
            Icon(icono, size: 20, color: elegido ? s.primary : s.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(texto)),
            if (elegido) Icon(Icons.check, size: 18, color: s.primary),
          ],
        ),
      );
    }

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Cambiar tema',
      icon: const Icon(Icons.brightness_6_outlined),
      initialValue: tema.modo,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 180),
      onSelected: tema.cambiar,
      itemBuilder: (context) => [
        opcion(ThemeMode.system, Icons.smartphone, 'Sistema'),
        opcion(ThemeMode.light, Icons.light_mode_outlined, 'Claro'),
        opcion(ThemeMode.dark, Icons.dark_mode_outlined, 'Oscuro'),
      ],
    );
  }
}
