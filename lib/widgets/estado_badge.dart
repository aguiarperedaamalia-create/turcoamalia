import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/enums.dart';

/// Etiqueta de estado de un turno con su color (Programado, Completado, Cancelado).
class EstadoBadge extends StatelessWidget {
  const EstadoBadge(this.estado, {super.key});

  final EstadoTurno estado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ColoresEstado.de(theme.colorScheme, estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.contenedor,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        estado.etiqueta,
        style: theme.textTheme.labelSmall?.copyWith(
          color: c.sobreContenedor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Etiqueta neutra (por ejemplo el público de un servicio).
class EtiquetaSuave extends StatelessWidget {
  const EtiquetaSuave(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: s.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
