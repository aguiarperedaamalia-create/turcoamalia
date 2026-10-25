import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/enums.dart';
import '../../models/turno.dart';
import '../../viewmodels/turno_detalle_view_model.dart';
import '../../widgets/avatares.dart';
import '../../widgets/estado_badge.dart';
import '../../widgets/estado_vacio.dart';
import 'acciones_turno.dart';

/// RF2 · Detalle de turno (`/turno/:id`).
class TurnoDetalleScreen extends StatefulWidget {
  const TurnoDetalleScreen({super.key, required this.idTexto});

  /// Parámetro de ruta `id` (puede no ser válido).
  final String? idTexto;

  @override
  State<TurnoDetalleScreen> createState() => _TurnoDetalleScreenState();
}

class _TurnoDetalleScreenState extends State<TurnoDetalleScreen> {
  late final TurnoDetalleViewModel vm =
      TurnoDetalleViewModel(AppScope.of(context).repo, widget.idTexto);
  final _scrollNotas = ScrollController();

  @override
  void dispose() {
    vm.dispose();
    _scrollNotas.dispose();
    super.dispose();
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/agenda');
    }
  }

  Future<void> _editar(Turno t) async {
    final r = await context.push<Turno>('/turno/${t.id}/editar');
    if (!mounted || r == null) return;
    mostrarTurnoGuardado(context, r);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final t = vm.turno;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.chevron_left, size: 28),
              onPressed: _volver,
            ),
            titleSpacing: 0,
            title: const Text('Detalle del turno'),
          ),
          body: t == null ? _noEncontrado() : _contenido(context, t),
          bottomNavigationBar: t == null ? null : _barraAcciones(context, t),
        );
      },
    );
  }

  Widget _noEncontrado() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
      child: Center(
        child: EstadoVacio(
          imagen: 'assets/images/ilustraciones/no_encontrado.png',
          titulo: 'No encontramos este turno',
          mensaje: 'El turno no existe o ya no está disponible.',
          error: true,
          tamano: 112,
          accion: FilledButton.icon(
            onPressed: () => context.go('/agenda'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Volver a la agenda'),
          ),
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, Turno t) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final repo = vm.repo;
    final cliente = vm.cliente;
    final estilista = vm.estilista;
    final fin = repo.finDe(t);
    final duracion = repo.duracionDe(t.servicioIds);
    final servicios = vm.servicios;
    final secundario = theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant);

    return SingleChildScrollView(
      padding: AppSpacing.pantalla,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cliente, fecha, hora y estilista
          Card(
            child: Padding(
              padding: AppSpacing.tarjeta,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (cliente != null) AvatarCliente(cliente, tamano: 48),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cliente?.nombre ?? 'Cliente eliminado',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 17, fontWeight: FontWeight.w600)),
                            if (cliente != null)
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 15, color: s.onSurfaceVariant),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(Fmt.telefono(cliente.telefono),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontSize: 13, color: s.onSurfaceVariant)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      EstadoBadge(t.estado),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Dato(icono: Icons.calendar_today_outlined, etiqueta: 'Fecha', valor: Fmt.fechaLarga(t.inicio)),
                  _Dato(
                    icono: Icons.schedule,
                    etiqueta: 'Hora',
                    valor: '${Fmt.hora(t.inicio)} a ${Fmt.hora(fin)} (${Fmt.duracion(duracion)})',
                  ),
                  _Dato(icono: Icons.person_outline, etiqueta: 'Estilista', valor: estilista?.nombreCorto ?? '—'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Servicios
          Card(
            child: Padding(
              padding: AppSpacing.tarjeta,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Servicios', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  for (final sv in servicios) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sv.nombre,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                              Text(Fmt.duracion(sv.duracionMin), style: secundario),
                            ],
                          ),
                        ),
                        Text(Fmt.precio(sv.precio), style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(child: Text('Total', style: theme.textTheme.titleSmall)),
                      Text(Fmt.precio(repo.totalDe(t)),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700, color: s.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Notas con scroll propio
          Card(
            child: Padding(
              padding: AppSpacing.tarjeta,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Notas', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 132),
                    child: Scrollbar(
                      controller: _scrollNotas,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollNotas,
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          t.tieneNotas ? t.notas! : 'Sin notas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            height: 1.45,
                            color: s.onSurfaceVariant,
                            fontStyle: t.tieneNotas ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Creado el ${Fmt.fechaHora(t.creado)} · Modificado el ${Fmt.fechaHora(t.modificado)}',
            style: theme.textTheme.labelSmall?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _barraAcciones(BuildContext context, Turno t) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    const compacto = EdgeInsets.symmetric(horizontal: AppSpacing.sm);
    final Widget contenido;
    if (vm.editable) {
      final cliente = vm.cliente?.nombre ?? 'el cliente';
      final fin = vm.repo.finDe(t);
      contenido = Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: compacto),
              onPressed: () => _editar(t),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(padding: compacto),
              onPressed: () => completarConConfirmacion(context,
                  cliente: cliente, inicio: t.inicio, fin: fin, accion: vm.completar),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Completar', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: s.error,
                padding: compacto,
                minimumSize: const Size(0, 46),
              ),
              onPressed: () => cancelarConConfirmacion(context,
                  cliente: cliente, inicio: t.inicio, fin: fin, accion: vm.cancelar),
              icon: const Icon(Icons.block, size: 18),
              label: const Text('Cancelar', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      );
    } else {
      final texto = t.estado == EstadoTurno.completado
          ? 'Turno completado: solo lectura'
          : 'Turno cancelado: solo lectura';
      contenido = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 18, color: s.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(texto,
                style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant)),
          ),
        ],
      );
    }
    return Material(
      color: s.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, vm.editable ? 16 : 14),
          child: contenido,
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.etiqueta, required this.valor});

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icono, size: 20, color: s.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w400)),
                Text(valor, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
