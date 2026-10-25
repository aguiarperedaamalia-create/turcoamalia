import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Mensaje con ilustración para listas vacías o sin resultados.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.imagen,
    required this.titulo,
    required this.mensaje,
    this.error = false,
    this.accion,
    this.tamano = 120,
  });

  final String imagen;
  final String titulo;
  final String mensaje;

  /// Usa los colores de error (por ejemplo "No encontramos este turno").
  final bool error;
  final Widget? accion;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: tamano,
            height: tamano,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: error ? s.errorContainer : s.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              imagen,
              width: tamano * 0.46,
              height: tamano * 0.46,
              color: error ? s.error : s.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              mensaje,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: s.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          if (accion != null) ...[
            const SizedBox(height: AppSpacing.lg),
            accion!,
          ],
        ],
      ),
    );
  }
}
