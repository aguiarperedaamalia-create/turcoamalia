import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/enums.dart';
import '../../models/turno.dart';
import '../../viewmodels/agenda_view_model.dart';
import '../../viewmodels/turno_form_view_model.dart';
import '../../widgets/estado_badge.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/logo_turco.dart';
import '../turno/acciones_turno.dart';
import 'selector_tema.dart';

/// RF1 · Agenda: pantalla inicial con los turnos de un día.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key, this.estilistaQuery});

  /// Parámetro de consulta `estilista` de la ruta `/agenda?estilista=3`.
  final String? estilistaQuery;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _scroll = ScrollController();

  AgendaViewModel get vm => AppScope.of(context).agenda;

  @override
  void initState() {
    super.initState();
    _aplicarQuery(widget.estilistaQuery);
  }

  @override
  void didUpdateWidget(covariant AgendaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.estilistaQuery != widget.estilistaQuery) {
      _aplicarQuery(widget.estilistaQuery);
    }
  }

  void _aplicarQuery(String? q) {
    final id = int.tryParse(q ?? '');
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (vm.repo.estilista(id) != null) vm.filtrarEstilista(id);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _nuevoTurno() async {
    final t = await context.push<Turno>('/turno/nuevo', extra: TurnoFormArgs(fecha: vm.fecha));
    if (!mounted || t == null) return;
    mostrarTurnoGuardado(context, t);
  }

  Future<void> _elegirFecha() async {
    final hoy = vm.repo.ahora;
    final fecha = vm.fecha;
    var primera = DateTime(hoy.year - 2);
    var ultima = DateTime(hoy.year + 2, 12, 31);
    if (fecha.isBefore(primera)) primera = fecha;
    if (fecha.isAfter(ultima)) ultima = fecha;
    final d = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: primera,
      lastDate: ultima,
      selectableDayPredicate: (d) => d.weekday != DateTime.sunday,
      helpText: 'Elegir fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (d != null && mounted) vm.seleccionarFecha(d);
  }

  Future<void> _accionesRapidas(Turno t) async {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final accion = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: AppSpacing.hoja,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${vm.nombreCliente(t)} · ${Fmt.hora(t.inicio)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Text('${vm.serviciosDe(t)} · ${vm.nombreEstilista(t)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle_outline, color: s.tertiary),
                title: const Text('Marcar como completado'),
                onTap: () => Navigator.of(ctx).pop('completar'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.block, color: s.error),
                title: Text('Cancelar turno', style: TextStyle(color: s.error)),
                onTap: () => Navigator.of(ctx).pop('cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || accion == null) return;
    final cliente = vm.nombreCliente(t);
    final fin = vm.finDe(t);
    if (accion == 'completar') {
      await completarConConfirmacion(context,
          cliente: cliente, inicio: t.inicio, fin: fin, accion: () => vm.completar(t.id));
    } else {
      await cancelarConConfirmacion(context,
          cliente: cliente, inicio: t.inicio, fin: fin, accion: () => vm.cancelar(t.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const LogoTurco(),
            const SizedBox(width: AppSpacing.md),
            Text('Turco', style: theme.textTheme.titleLarge),
          ],
        ),
        actions: const [SelectorTema(), SizedBox(width: AppSpacing.sm)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-agenda',
        onPressed: _nuevoTurno,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo turno'),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final turnos = vm.turnosFiltrados;
          final vacio = turnos.isEmpty;
          // ListView.builder: el elemento 0 es la cabecera; luego los turnos
          // ordenados por hora (o el mensaje de lista vacía).
          return ListView.builder(
            key: const PageStorageKey('agenda-lista'),
            controller: _scroll,
            padding: AppSpacing.pantalla.copyWith(bottom: 96),
            itemCount: 1 + (vacio ? 1 : turnos.length),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _Cabecera(vm: vm, alElegirFecha: _elegirFecha);
              }
              if (vacio) {
                final sinTurnos = vm.diaSinTurnos;
                return EstadoVacio(
                  imagen: 'assets/images/ilustraciones/agenda_vacia.png',
                  titulo: sinTurnos ? 'No hay turnos para este día' : 'Ningún turno con estos filtros',
                  mensaje: sinTurnos
                      ? 'Crea el primer turno con el botón de abajo o cambia los filtros.'
                      : 'Prueba con otro estilista o estado, o crea un turno nuevo.',
                );
              }
              final t = turnos[i - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TarjetaTurno(
                  turno: t,
                  cliente: vm.nombreCliente(t),
                  servicios: vm.serviciosDe(t),
                  estilista: vm.nombreEstilista(t),
                  fin: vm.finDe(t),
                  onTap: () => context.push('/turno/${t.id}'),
                  onLongPress: t.esProgramado ? () => _accionesRapidas(t) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.vm, required this.alElegirFecha});

  final AgendaViewModel vm;
  final VoidCallback alElegirFecha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final resumen = vm.resumen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabecera de la semana
        Row(
          children: [
            IconButton(
              tooltip: 'Semana anterior',
              visualDensity: VisualDensity.compact,
              onPressed: vm.semanaAnterior,
              icon: const Icon(Icons.chevron_left),
            ),
            Flexible(
              child: Text(
                Fmt.mesAnio(vm.fecha),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
              ),
            ),
            IconButton(
              tooltip: 'Semana siguiente',
              visualDensity: VisualDensity.compact,
              onPressed: vm.semanaSiguiente,
              icon: const Icon(Icons.chevron_right),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: alElegirFecha,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text('Elegir fecha', style: theme.textTheme.labelMedium),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _TiraDias(vm: vm),
        const SizedBox(height: AppSpacing.sm),
        Text('Domingo: salón cerrado',
            style: theme.textTheme.labelSmall?.copyWith(
                color: s.onSurfaceVariant, fontWeight: FontWeight.w400)),
        const SizedBox(height: 10),
        if (!vm.diaSinTurnos) ...[
          Row(
            children: [
              Expanded(child: _Resumen(valor: '${resumen.programados}', etiqueta: 'Programados', color: s.primary)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _Resumen(valor: '${resumen.completados}', etiqueta: 'Completados', color: s.tertiary)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _Resumen(valor: Fmt.precio(resumen.ingreso), etiqueta: 'Ingreso est.', color: s.onSurface)),
            ],
          ),
          const SizedBox(height: 10),
        ],
        // Filtro por estilista
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ChipEstilista(
                etiqueta: 'Todos',
                elegido: vm.estilistaId == null,
                onTap: () => vm.filtrarEstilista(null),
              ),
              for (final e in vm.estilistas)
                _ChipEstilista(
                  etiqueta: e.nombreCorto,
                  elegido: vm.estilistaId == e.id,
                  onTap: () => vm.filtrarEstilista(e.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Filtro por estado
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<FiltroEstado>(
            segments: [
              for (final f in FiltroEstado.values)
                ButtonSegment(value: f, label: Text(f.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            selected: {vm.filtroEstado},
            onSelectionChanged: (sel) => vm.filtrarEstado(sel.first),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ChipEstilista extends StatelessWidget {
  const _ChipEstilista({required this.etiqueta, required this.elegido, required this.onTap});

  final String etiqueta;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(etiqueta),
        selected: elegido,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Tira horizontal con los siete días de la semana (ListView.builder).
class _TiraDias extends StatelessWidget {
  const _TiraDias({required this.vm});

  final AgendaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final dias = vm.diasSemana;
    return SizedBox(
      height: 60,
      child: LayoutBuilder(
        builder: (context, c) => ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemExtent: c.maxWidth / 7,
          itemCount: dias.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _Dia(
              fecha: dias[i],
              elegido: vm.esSeleccionado(dias[i]),
              hoy: vm.esHoy(dias[i]),
              cerrado: vm.estaCerrado(dias[i]),
              onTap: () => vm.seleccionarFecha(dias[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({
    required this.fecha,
    required this.elegido,
    required this.hoy,
    required this.cerrado,
    required this.onTap,
  });

  final DateTime fecha;
  final bool elegido;
  final bool hoy;
  final bool cerrado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final radio = BorderRadius.circular(AppRadius.dayTile);
    final colorEtiqueta = elegido ? s.onPrimary : s.onSurfaceVariant;
    final colorNumero = elegido ? s.onPrimary : (hoy ? s.primary : s.onSurface);
    return Opacity(
      opacity: cerrado ? 0.4 : 1,
      child: Semantics(
        button: !cerrado,
        selected: elegido,
        label: cerrado ? '${Fmt.fechaLarga(fecha)}, cerrado' : Fmt.fechaLarga(fecha),
        child: Material(
          color: elegido ? s.primary : s.surface.withValues(alpha: 0),
          borderRadius: radio,
          child: InkWell(
            borderRadius: radio,
            onTap: cerrado ? null : onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(Fmt.diaCorto(fecha), style: theme.textTheme.labelSmall?.copyWith(color: colorEtiqueta)),
                const SizedBox(height: AppSpacing.xxs),
                Text('${fecha.day}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorNumero)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.valor, required this.etiqueta, required this.color});

  final String valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.summary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, color: color)),
          ),
          Text(etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}

/// Tarjeta de un turno en la lista de la Agenda.
class TarjetaTurno extends StatelessWidget {
  const TarjetaTurno({
    super.key,
    required this.turno,
    required this.cliente,
    required this.servicios,
    required this.estilista,
    required this.fin,
    this.onTap,
    this.onLongPress,
  });

  final Turno turno;
  final String cliente;
  final String servicios;
  final String estilista;
  final DateTime fin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final colores = ColoresEstado.de(s, turno.estado);
    final apagado = turno.estado == EstadoTurno.cancelado;
    final secundario = theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant);
    final fuerte = theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
    return Opacity(
      opacity: apagado ? 0.75 : 1,
      child: Card(
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: colores.acento,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(Fmt.hora(turno.inicio), style: fuerte),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(Fmt.hora(fin), style: secundario),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cliente, maxLines: 1, overflow: TextOverflow.ellipsis, style: fuerte),
                        const SizedBox(height: AppSpacing.xs),
                        Text(servicios, maxLines: 2, overflow: TextOverflow.ellipsis, style: secundario),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 15, color: s.onSurfaceVariant),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(estilista,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: secundario?.copyWith(fontWeight: FontWeight.w500)),
                            ),
                            EstadoBadge(turno.estado),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
