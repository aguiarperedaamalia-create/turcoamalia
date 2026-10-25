import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../widgets/avatares.dart';
import '../../widgets/estado_badge.dart';

enum TipoAccionCliente { nuevoTurno, editar, eliminar, verTurno }

/// Acción elegida en la hoja de detalle del cliente.
class AccionCliente {
  const AccionCliente(this.tipo, [this.turnoId]);

  final TipoAccionCliente tipo;
  final int? turnoId;
}

/// Hoja con los datos del cliente, el historial de sus turnos y las opciones
/// Nuevo turno, Editar y Eliminar.
Future<AccionCliente?> mostrarDetalleCliente(BuildContext context, int clienteId) {
  return showModalBottomSheet<AccionCliente>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DetalleCliente(clienteId: clienteId),
  );
}

class _DetalleCliente extends StatelessWidget {
  const _DetalleCliente({required this.clienteId});

  final int clienteId;

  @override
  Widget build(BuildContext context) {
    final vm = AppScope.of(context).clientes;
    final theme = Theme.of(context);
    final s = theme.colorScheme;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final c = vm.cliente(clienteId);
        if (c == null) {
          return const SizedBox(height: 120, child: Center(child: Text('El cliente ya no existe')));
        }
        final historial = vm.historial(c);
        final secundario = theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: s.onSurfaceVariant);

        return SingleChildScrollView(
          padding: AppSpacing.hoja,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AvatarCliente(c, tamano: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.nombre,
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.phone_outlined, size: 15, color: s.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('${Fmt.telefono(c.telefono)} · ${c.genero.etiqueta}', style: secundario),
                        ]),
                        if (c.correo != null)
                          Row(children: [
                            Icon(Icons.mail_outline, size: 15, color: s.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(child: Text(c.correo!, overflow: TextOverflow.ellipsis, style: secundario)),
                          ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Historial de turnos · ${historial.length}',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: s.onSurface)),
              const SizedBox(height: AppSpacing.xs),
              if (historial.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('Todavía no tiene turnos.', style: secundario),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.3),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: historial.length,
                    itemBuilder: (context, i) {
                      final t = historial[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        onTap: () => Navigator.of(context)
                            .pop(AccionCliente(TipoAccionCliente.verTurno, t.id)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${Fmt.diaMes(t.inicio)} · ${vm.serviciosDe(t)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              EstadoBadge(t.estado),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(const AccionCliente(TipoAccionCliente.nuevoTurno)),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo turno', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(const AccionCliente(TipoAccionCliente.editar)),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.outlined(
                    tooltip: 'Eliminar',
                    style: IconButton.styleFrom(
                      foregroundColor: s.error,
                      side: BorderSide(color: s.outlineVariant),
                      minimumSize: const Size(46, 46),
                    ),
                    onPressed: () => Navigator.of(context).pop(const AccionCliente(TipoAccionCliente.eliminar)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
