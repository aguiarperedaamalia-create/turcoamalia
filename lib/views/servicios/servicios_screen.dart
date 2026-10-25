import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/enums.dart';
import '../../models/servicio.dart';
import '../../models/turno.dart';
import '../../viewmodels/servicios_view_model.dart';
import '../../viewmodels/turno_form_view_model.dart';
import '../../widgets/estado_badge.dart';
import '../../widgets/estado_vacio.dart';
import '../turno/acciones_turno.dart';

/// RF5 · Servicios: catálogo en cuadrícula.
class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  final _scroll = ScrollController();

  ServiciosViewModel get vm => AppScope.of(context).servicios;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Abre el formulario con el servicio ya seleccionado (viaja con `extra`).
  Future<void> _reservar(Servicio s) async {
    final t = await context.push<Turno>('/turno/nuevo', extra: TurnoFormArgs(servicioId: s.id));
    if (t != null && mounted) mostrarTurnoGuardado(context, t, irAAgenda: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Servicios'),
            Text('Toca un servicio para reservar',
                style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final lista = vm.serviciosFiltrados;
          return LayoutBuilder(
            builder: (context, c) {
              // 2 columnas (< 600 dp), 3 (600–840 dp) y 4 (> 840 dp).
              final columnas = ServiciosViewModel.columnasPara(c.maxWidth);
              return Padding(
                padding: AppSpacing.pantalla.copyWith(bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _ChipCategoria(
                            etiqueta: 'Todas',
                            elegido: vm.categoria == null,
                            onTap: () => vm.filtrarCategoria(null),
                          ),
                          for (final cat in Categoria.values)
                            _ChipCategoria(
                              etiqueta: cat.etiqueta,
                              elegido: vm.categoria == cat,
                              onTap: () => vm.filtrarCategoria(cat),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<FiltroGenero>(
                        segments: [
                          for (final f in FiltroGenero.values) ButtonSegment(value: f, label: Text(f.etiqueta)),
                        ],
                        selected: {vm.publico},
                        onSelectionChanged: (sel) => vm.filtrarPublico(sel.first),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: lista.isEmpty
                          ? const SingleChildScrollView(
                              child: EstadoVacio(
                                imagen: 'assets/images/ilustraciones/sin_resultados.png',
                                titulo: 'Sin servicios',
                                mensaje: 'Ningún servicio coincide con los filtros elegidos.',
                              ),
                            )
                          : GridView.builder(
                              key: const PageStorageKey('servicios-grid'),
                              controller: _scroll,
                              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columnas,
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisSpacing: AppSpacing.md,
                                mainAxisExtent: 200,
                              ),
                              itemCount: lista.length,
                              itemBuilder: (context, i) => _TarjetaServicio(
                                servicio: lista[i],
                                onTap: () => _reservar(lista[i]),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  const _ChipCategoria({required this.etiqueta, required this.elegido, required this.onTap});

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

class _TarjetaServicio extends StatelessWidget {
  const _TarjetaServicio({required this.servicio, required this.onTap});

  final Servicio servicio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen de la categoría
              Expanded(
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Image.asset(
                    servicio.categoria.imagen,
                    width: 36,
                    height: 36,
                    color: s.primary,
                    semanticLabel: servicio.categoria.etiqueta,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(servicio.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: s.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(Fmt.duracion(servicio.duracionMin),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                  ),
                  Text(Fmt.precio(servicio.precio),
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: s.primary)),
                ],
              ),
              const SizedBox(height: 6),
              EtiquetaSuave(servicio.publico.etiqueta),
            ],
          ),
        ),
      ),
    );
  }
}
