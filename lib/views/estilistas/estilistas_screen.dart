import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/formatters.dart';
import '../../models/estilista.dart';
import '../../models/horario.dart';
import '../../viewmodels/estilistas_view_model.dart';
import '../../widgets/avatares.dart';

/// RF6 · Estilistas: CustomScrollView con SliverAppBar plegable y SliverList.
class EstilistasScreen extends StatefulWidget {
  const EstilistasScreen({super.key});

  @override
  State<EstilistasScreen> createState() => _EstilistasScreenState();
}

class _EstilistasScreenState extends State<EstilistasScreen> {
  static const double _alturaExpandida = 170;
  final _scroll = ScrollController();

  EstilistasViewModel get vm => AppScope.of(context).estilistas;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Va a la Agenda con el filtro del estilista (parámetro de consulta).
  void _verAgenda(Estilista e) {
    final agenda = AppScope.of(context).agenda;
    agenda.seleccionarFecha(HorarioSalon.proximoDiaHabil(vm.repo.ahora));
    agenda.filtrarEstilista(e.id);
    context.go('/agenda?estilista=${e.id}');
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final iconosClaros = ThemeData.estimateBrightnessForColor(s.primary) == Brightness.dark;
    return Scaffold(
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final estilistas = vm.estilistas;
          return CustomScrollView(
            key: const PageStorageKey('estilistas-scroll'),
            controller: _scroll,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: _alturaExpandida,
                backgroundColor: s.primary,
                foregroundColor: s.onPrimary,
                surfaceTintColor: s.primary,
                systemOverlayStyle: iconosClaros ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
                automaticallyImplyLeading: false,
                flexibleSpace: _CabeceraPlegable(
                  alturaExpandida: _alturaExpandida,
                  subtitulo:
                      '${Fmt.plural(estilistas.length, 'profesional', 'profesionales')} · '
                      '${Fmt.plural(vm.totalTurnosHoy, 'turno programado', 'turnos programados')} hoy',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaEstilista(
                        estilista: estilistas[i],
                        vm: vm,
                        onTap: () => _verAgenda(estilistas[i]),
                      ),
                    ),
                    childCount: estilistas.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CabeceraPlegable extends StatelessWidget {
  const _CabeceraPlegable({required this.alturaExpandida, required this.subtitulo});

  final double alturaExpandida;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final arriba = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, c) {
        final minimo = kToolbarHeight + arriba;
        final maximo = alturaExpandida + arriba;
        final t = ((c.maxHeight - minimo) / (maximo - minimo)).clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Opacity(
                opacity: t,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, size: 28, color: s.onPrimary),
                    const SizedBox(height: 4),
                    Text('Estilistas', style: theme.textTheme.headlineMedium?.copyWith(color: s.onPrimary)),
                    const SizedBox(height: 4),
                    Text(subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontSize: 13, color: s.onPrimary.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: arriba,
              height: kToolbarHeight,
              child: Opacity(
                opacity: 1 - t,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Estilistas',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, color: s.onPrimary)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TarjetaEstilista extends StatelessWidget {
  const _TarjetaEstilista({required this.estilista, required this.vm, required this.onTap});

  final Estilista estilista;
  final EstilistasViewModel vm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final grupos = vm.serviciosPorCategoria(estilista);
    final hoy = vm.turnosHoy(estilista);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AvatarEstilista(estilista),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(estilista.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    // Servicios agrupados por categoría.
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final g in grupos.entries)
                          Tooltip(
                            message: g.value.map((x) => x.nombre).join(', '),
                            child: Chip(
                              label: Text(g.key.etiqueta),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hoy == 0 ? 'Sin turnos hoy' : '${Fmt.plural(hoy, 'turno', 'turnos')} hoy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: hoy == 0 ? s.onSurfaceVariant : s.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: s.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
