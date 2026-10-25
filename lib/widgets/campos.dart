import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Etiqueta sobre un campo; se pinta en color de error cuando el campo falla.
class EtiquetaCampo extends StatelessWidget {
  const EtiquetaCampo(this.texto, {super.key, this.error = false});

  final String texto;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        texto,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: error ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Mensaje de validación con icono bajo un campo.
class LineaError extends StatelessWidget {
  const LineaError(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline, size: 14, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(mensaje, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

/// Caja de selección (cliente, estilista, fecha) con icono inicial y flecha,
/// con el mismo aspecto que los campos del tema.
///
/// Si [onTap] no es nulo la caja es pulsable y enfocable con [focusNode]; si
/// es nulo, [focusNode] solo se escucha para pintar el borde (por ejemplo,
/// cuando el nodo pertenece a un `DropdownButton` interno).
class CajaSelector extends StatelessWidget {
  const CajaSelector({
    super.key,
    required this.icono,
    required this.child,
    this.error = false,
    this.onTap,
    this.focusNode,
    this.mostrarFlecha = true,
  });

  final IconData icono;
  final Widget child;
  final bool error;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool mostrarFlecha;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final radio = BorderRadius.circular(AppRadius.field);
    final nodo = focusNode;

    Widget caja(bool enfocado) => Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: radio,
            border: Border.all(
              color: error ? s.error : (enfocado ? s.primary : s.outline),
              width: error || enfocado ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icono, size: 20, color: s.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(child: child),
              if (mostrarFlecha)
                Icon(Icons.keyboard_arrow_down, size: 22, color: s.onSurfaceVariant),
            ],
          ),
        );

    final Widget contenido = nodo == null
        ? caja(false)
        : ListenableBuilder(
            listenable: nodo,
            builder: (context, _) => caja(nodo.hasFocus),
          );

    if (onTap == null) return contenido;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        focusNode: nodo,
        onTap: onTap,
        borderRadius: radio,
        child: contenido,
      ),
    );
  }
}
