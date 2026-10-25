import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/cliente.dart';
import '../../models/enums.dart';
import '../../models/turno.dart';
import '../../viewmodels/clientes_view_model.dart';
import '../../viewmodels/turno_form_view_model.dart';
import '../../widgets/avatares.dart';
import '../../widgets/dialogo_confirmacion.dart';
import '../../widgets/estado_vacio.dart';
import '../turno/acciones_turno.dart';
import 'cliente_detalle_sheet.dart';
import 'cliente_form_sheet.dart';

/// RF4 · Clientes.
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _scroll = ScrollController();
  late final TextEditingController _busqueda = TextEditingController(text: vm.busqueda);

  ClientesViewModel get vm => AppScope.of(context).clientes;

  @override
  void dispose() {
    _scroll.dispose();
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _nuevo() async {
    final c = await mostrarFormularioCliente(context);
    if (c != null) mostrarMensaje('Cliente ${c.nombre} registrado');
  }

  Future<void> _abrirDetalle(Cliente c) async {
    final accion = await mostrarDetalleCliente(context, c.id);
    if (!mounted || accion == null) return;
    switch (accion.tipo) {
      case TipoAccionCliente.nuevoTurno:
        final t = await context.push<Turno>('/turno/nuevo', extra: TurnoFormArgs(clienteId: c.id));
        if (t != null && mounted) mostrarTurnoGuardado(context, t, irAAgenda: true);
      case TipoAccionCliente.editar:
        final editado = await mostrarFormularioCliente(context, cliente: vm.cliente(c.id));
        if (editado != null) mostrarMensaje('Cliente ${editado.nombre} actualizado');
      case TipoAccionCliente.eliminar:
        await _eliminar(c);
      case TipoAccionCliente.verTurno:
        context.push('/turno/${accion.turnoId}');
    }
  }

  Future<void> _eliminar(Cliente c) async {
    final previo = vm.puedeEliminar(c);
    if (!previo.ok) {
      // No se puede eliminar un cliente con turnos programados.
      mostrarMensaje(previo.mensaje!, accion: 'Ver', alPulsar: () => _abrirDetalle(c));
      return;
    }
    final ok = await confirmar(
      context,
      titulo: '¿Eliminar a ${c.nombre}?',
      mensaje: 'Se eliminará el cliente junto con su historial de turnos completados y cancelados.',
      textoConfirmar: 'Eliminar',
      textoCancelar: 'Cancelar',
    );
    if (!ok || !mounted) return;
    final r = vm.eliminar(c);
    mostrarMensaje(r.ok ? 'Cliente ${c.nombre} eliminado' : r.mensaje!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final sinBorde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.search),
      borderSide: BorderSide.none,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: 'Registrar cliente',
            onPressed: _nuevo,
            icon: const Icon(Icons.person_add_alt_outlined),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-clientes',
        onPressed: _nuevo,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Nuevo cliente'),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final lista = vm.clientesFiltrados;
          return Padding(
            padding: AppSpacing.pantalla.copyWith(bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _busqueda,
                  onChanged: vm.buscar,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: s.surfaceContainerHighest,
                    hintText: 'Buscar por nombre o teléfono',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: vm.busqueda.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Borrar búsqueda',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _busqueda.clear();
                              vm.buscar('');
                            },
                          ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: sinBorde,
                    enabledBorder: sinBorde,
                    focusedBorder: sinBorde,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<FiltroGenero>(
                    segments: [
                      for (final f in FiltroGenero.values) ButtonSegment(value: f, label: Text(f.etiqueta)),
                    ],
                    selected: {vm.filtro},
                    onSelectionChanged: (sel) => vm.filtrar(sel.first),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${Fmt.plural(vm.total, 'cliente', 'clientes')} · '
                  '${Fmt.plural(vm.totalMujeres, 'mujer', 'mujeres')} · '
                  '${Fmt.plural(vm.totalHombres, 'hombre', 'hombres')}',
                  style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: lista.isEmpty
                      ? SingleChildScrollView(
                          child: vm.total == 0
                              ? const EstadoVacio(
                                  imagen: 'assets/images/ilustraciones/sin_clientes.png',
                                  titulo: 'Aún no hay clientes',
                                  mensaje: 'Registra el primero con el botón Nuevo cliente.',
                                )
                              : const EstadoVacio(
                                  imagen: 'assets/images/ilustraciones/sin_resultados.png',
                                  titulo: 'Sin resultados',
                                  mensaje: 'Ningún cliente coincide con la búsqueda o el filtro elegido.',
                                ),
                        )
                      : ListView.separated(
                          key: const PageStorageKey('clientes-lista'),
                          controller: _scroll,
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final c = lista[i];
                            return _FilaCliente(
                              cliente: c,
                              turnos: vm.cantidadTurnos(c),
                              onTap: () => _abrirDetalle(c),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilaCliente extends StatelessWidget {
  const _FilaCliente({required this.cliente, required this.turnos, required this.onTap});

  final Cliente cliente;
  final int turnos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AvatarCliente(cliente),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cliente.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text('${Fmt.telefono(cliente.telefono)} · ${cliente.genero.etiqueta}',
                      style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(Fmt.plural(turnos, 'turno', 'turnos'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
