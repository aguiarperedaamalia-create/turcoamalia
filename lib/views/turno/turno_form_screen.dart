import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/salon_repository.dart';
import '../../models/enums.dart';
import '../../models/horario.dart';
import '../../viewmodels/turno_form_view_model.dart';
import '../../widgets/campos.dart';
import '../../widgets/dialogo_confirmacion.dart';
import '../../widgets/estado_vacio.dart';
import '../clientes/cliente_form_sheet.dart';
import 'acciones_turno.dart';

/// RF3 · Formulario de turno (`/turno/nuevo` y `/turno/:id/editar`).
class TurnoFormScreen extends StatefulWidget {
  const TurnoFormScreen({super.key, this.args, this.turnoIdTexto});

  /// Datos iniciales enviados con `extra` (cliente, servicio o fecha).
  final TurnoFormArgs? args;

  /// Parámetro de ruta `id` al editar.
  final String? turnoIdTexto;

  @override
  State<TurnoFormScreen> createState() => _TurnoFormScreenState();
}

class _TurnoFormScreenState extends State<TurnoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Claves de cada campo para localizar el primero con error.
  final _kCliente = GlobalKey<FormFieldState<int>>();
  final _kServicios = GlobalKey<FormFieldState<List<int>>>();
  final _kEstilista = GlobalKey<FormFieldState<int>>();
  final _kFecha = GlobalKey<FormFieldState<DateTime>>();
  final _kHora = GlobalKey<FormFieldState<DateTime>>();
  final _kNotas = GlobalKey<FormFieldState<String>>();

  // FocusNode de cada campo.
  final _fCliente = FocusNode(debugLabel: 'cliente');
  final _fServicios = FocusNode(debugLabel: 'servicios');
  final _fEstilista = FocusNode(debugLabel: 'estilista');
  final _fFecha = FocusNode(debugLabel: 'fecha');
  final _fHora = FocusNode(debugLabel: 'hora');
  final _fNotas = FocusNode(debugLabel: 'notas');

  late final TurnoFormViewModel vm = TurnoFormViewModel(
    AppScope.of(context).repo,
    turnoId: widget.turnoIdTexto == null ? null : (int.tryParse(widget.turnoIdTexto!) ?? -1),
    args: widget.args,
  );
  late final TextEditingController _notas = TextEditingController(text: vm.notas);

  bool _intentado = false;
  bool _permitirSalir = false;

  @override
  void dispose() {
    vm.dispose();
    _notas.dispose();
    for (final f in [_fCliente, _fServicios, _fEstilista, _fFecha, _fHora, _fNotas]) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  void _salir([Object? resultado]) {
    setState(() => _permitirSalir = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(resultado);
      } else {
        context.go('/agenda');
      }
    });
  }

  /// Aviso de confirmación si hay cambios sin guardar.
  Future<void> _intentarSalir() async {
    if (!vm.hayCambios) {
      _salir();
      return;
    }
    final descartar = await confirmar(
      context,
      titulo: '¿Descartar los cambios?',
      mensaje: 'Tienes cambios sin guardar en este turno. Si sales ahora se perderán.',
      textoConfirmar: 'Descartar',
      textoCancelar: 'Seguir editando',
    );
    if (descartar && mounted) _salir();
  }

  void _guardar() {
    FocusScope.of(context).unfocus();
    setState(() => _intentado = true);
    if (!_formKey.currentState!.validate()) {
      _enfocarPrimerError();
      return;
    }
    try {
      final t = vm.guardar();
      _salir(t); // El resultado viaja de vuelta con context.pop(valor).
    } on ReglaNegocioException catch (e) {
      mostrarMensaje(e.mensaje);
    }
  }

  void _enfocarPrimerError() {
    final campos = <(GlobalKey<FormFieldState>, FocusNode)>[
      (_kCliente, _fCliente),
      (_kServicios, _fServicios),
      (_kEstilista, _fEstilista),
      (_kFecha, _fFecha),
      (_kHora, _fHora),
      (_kNotas, _fNotas),
    ];
    for (final (clave, nodo) in campos) {
      final estado = clave.currentState;
      if (estado != null && estado.hasError) {
        nodo.requestFocus();
        final ctx = clave.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 300), alignment: 0.1, curve: Curves.easeOut);
        }
        return;
      }
    }
  }

  Future<void> _crearCliente(FormFieldState<int> campo) async {
    final c = await mostrarFormularioCliente(context);
    if (c == null || !mounted) return;
    vm.seleccionarCliente(c.id);
    campo.didChange(c.id);
    mostrarMensaje('Cliente ${c.nombre} registrado');
  }

  Future<void> _elegirFecha(FormFieldState<DateTime> campo) async {
    final actual = vm.fecha;
    final inicial = (actual != null && vm.esFechaPermitida(actual)) ? actual : vm.primeraFecha;
    final hoy = HorarioSalon.soloFecha(vm.repo.ahora);
    final d = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: hoy,
      lastDate: vm.ultimaFecha,
      selectableDayPredicate: vm.esFechaPermitida,
      helpText: 'Fecha del turno',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (d == null || !mounted) return;
    vm.seleccionarFecha(d);
    campo.didChange(d);
  }

  // ---------------------------------------------------------------------------
  // Construcción
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.turnoInvalido) return _turnoNoEditable(context);
        return PopScope(
          canPop: _permitirSalir || !vm.hayCambios,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _intentarSalir();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.chevron_left, size: 28),
                onPressed: _intentarSalir,
              ),
              titleSpacing: 0,
              title: Text(vm.esEdicion ? 'Editar turno' : 'Nuevo turno'),
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(child: _formulario(context)),
                  _BarraInferior(
                    vm: vm,
                    tecladoAbierto: MediaQuery.viewInsetsOf(context).bottom > 0,
                    alCancelar: _intentarSalir,
                    alGuardar: _guardar,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _turnoNoEditable(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => _salir(),
        ),
        titleSpacing: 0,
        title: const Text('Editar turno'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
        child: Center(
          child: EstadoVacio(
            imagen: 'assets/images/ilustraciones/no_encontrado.png',
            titulo: 'No se puede editar este turno',
            mensaje: 'El turno no existe o ya no está programado. Solo los turnos programados se pueden editar.',
            error: true,
            tamano: 112,
            accion: FilledButton.icon(
              onPressed: () => _salir(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Volver'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final hint = theme.textTheme.bodyMedium?.copyWith(color: s.outline);
    final valor = theme.textTheme.bodyMedium;
    final ocultarTextoError = InputDecoration(errorStyle: TextStyle(fontSize: 0, height: 0, color: s.error));

    return Form(
      key: _formKey,
      autovalidateMode: _intentado ? AutovalidateMode.always : AutovalidateMode.disabled,
      // Todos los campos se construyen a la vez (SingleChildScrollView + Column)
      // para que validate() los revise todos.
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----------------------------------------------------------- Cliente
            FormField<int>(
              key: _kCliente,
              initialValue: vm.clienteId,
              validator: (_) => vm.validarCliente(),
              builder: (campo) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EtiquetaCampo('Cliente', error: campo.hasError),
                  CajaSelector(
                    icono: Icons.person_outline,
                    error: campo.hasError,
                    focusNode: _fCliente,
                    mostrarFlecha: false,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        focusNode: _fCliente,
                        isExpanded: true,
                        value: vm.clienteId,
                        hint: Text('Selecciona un cliente', style: hint),
                        icon: Icon(Icons.keyboard_arrow_down, color: s.onSurfaceVariant),
                        style: valor,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                        items: [
                          for (final c in vm.clientes)
                            DropdownMenuItem(
                              value: c.id,
                              child: Text(c.nombre, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (id) {
                          vm.seleccionarCliente(id);
                          campo.didChange(id);
                        },
                      ),
                    ),
                  ),
                  if (campo.hasError) LineaError(campo.errorText!),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _crearCliente(campo),
                      icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                      label: const Text('Crear cliente nuevo'),
                    ),
                  ),
                ],
              ),
            ),
            // ---------------------------------------------------- Público
            const EtiquetaCampo('Servicios para'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<FiltroGenero>(
                segments: [
                  for (final f in FiltroGenero.values) ButtonSegment(value: f, label: Text(f.etiqueta)),
                ],
                selected: {vm.publico},
                onSelectionChanged: (sel) => vm.cambiarPublico(sel.first),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ---------------------------------------------------- Servicios
            FormField<List<int>>(
              key: _kServicios,
              initialValue: vm.servicios,
              validator: (_) => vm.validarServicios(),
              builder: (campo) => Focus(
                focusNode: _fServicios,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Servicios', style: theme.textTheme.titleSmall),
                    for (final entrada in vm.serviciosPorCategoria.entries) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        entrada.key.etiqueta.toUpperCase(),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600, color: s.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final sv in entrada.value)
                            FilterChip(
                              label: Text(sv.nombre),
                              selected: vm.estaElegido(sv.id),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              tooltip: '${Fmt.duracion(sv.duracionMin)} · ${Fmt.precio(sv.precio)} · ${sv.publico.etiqueta}',
                              onSelected: (_) {
                                final aviso = vm.alternarServicio(sv.id);
                                campo.didChange(vm.servicios);
                                if (aviso != null) mostrarMensaje(aviso);
                              },
                            ),
                        ],
                      ),
                    ],
                    if (campo.hasError) LineaError(campo.errorText!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ---------------------------------------------------- Estilista
            FormField<int>(
              key: _kEstilista,
              initialValue: vm.estilistaId,
              validator: (_) => vm.validarEstilista(),
              builder: (campo) {
                final opciones = vm.estilistasDisponibles;
                final textoVacio = vm.servicios.isEmpty
                    ? 'Primero elige los servicios'
                    : (opciones.isEmpty ? 'Ningún estilista realiza todos' : 'Selecciona un estilista');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EtiquetaCampo('Estilista', error: campo.hasError),
                    CajaSelector(
                      icono: Icons.content_cut,
                      error: campo.hasError,
                      focusNode: _fEstilista,
                      mostrarFlecha: false,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          focusNode: _fEstilista,
                          isExpanded: true,
                          value: vm.estilistaId,
                          hint: Text(textoVacio, style: hint, overflow: TextOverflow.ellipsis),
                          disabledHint: Text(textoVacio, style: hint, overflow: TextOverflow.ellipsis),
                          icon: Icon(Icons.keyboard_arrow_down, color: s.onSurfaceVariant),
                          style: valor,
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          items: [
                            for (final e in opciones)
                              DropdownMenuItem(value: e.id, child: Text(e.nombre, overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: opciones.isEmpty
                              ? null
                              : (id) {
                                  vm.seleccionarEstilista(id);
                                  campo.didChange(id);
                                },
                        ),
                      ),
                    ),
                    if (campo.hasError) LineaError(campo.errorText!),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(Icons.info_outline, size: 15, color: s.onSurfaceVariant),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Solo se muestran estilistas que realizan todos los servicios elegidos.',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            // ---------------------------------------------------- Fecha
            FormField<DateTime>(
              key: _kFecha,
              initialValue: vm.fecha,
              validator: (_) => vm.validarFecha(),
              builder: (campo) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EtiquetaCampo('Fecha', error: campo.hasError),
                  CajaSelector(
                    icono: Icons.calendar_today_outlined,
                    error: campo.hasError,
                    focusNode: _fFecha,
                    onTap: () => _elegirFecha(campo),
                    child: Text(
                      vm.fecha == null ? 'Selecciona una fecha' : Fmt.fechaLarga(vm.fecha!),
                      overflow: TextOverflow.ellipsis,
                      style: vm.fecha == null ? hint : valor,
                    ),
                  ),
                  if (campo.hasError) LineaError(campo.errorText!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ---------------------------------------------------- Hora
            FormField<DateTime>(
              key: _kHora,
              initialValue: vm.hora,
              validator: (_) => vm.validarHora(),
              builder: (campo) => Focus(
                focusNode: _fHora,
                child: _CuadriculaFranjas(
                  vm: vm,
                  error: campo.hasError,
                  alElegir: (inicio) {
                    vm.seleccionarHora(inicio);
                    campo.didChange(inicio);
                  },
                  pie: campo.hasError ? LineaError(campo.errorText!) : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ---------------------------------------------------- Notas
            const EtiquetaCampo('Notas (opcional)'),
            TextFormField(
              key: _kNotas,
              controller: _notas,
              focusNode: _fNotas,
              minLines: 3,
              maxLines: 5,
              maxLength: TurnoFormViewModel.maxNotas,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              decoration: ocultarTextoError.copyWith(
                hintText: 'Preferencias, indicaciones o recordatorios',
              ),
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => Text(
                '$currentLength / $maxLength',
                style: theme.textTheme.labelSmall?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w400),
              ),
              validator: vm.validarNotas,
              onChanged: vm.cambiarNotas,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuadrícula de franjas de 30 minutos (GridView.builder con shrinkWrap y
/// NeverScrollableScrollPhysics dentro del scroll del formulario).
class _CuadriculaFranjas extends StatelessWidget {
  const _CuadriculaFranjas({required this.vm, required this.error, required this.alElegir, this.pie});

  final TurnoFormViewModel vm;
  final bool error;
  final ValueChanged<DateTime> alElegir;
  final Widget? pie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final franjas = vm.franjas;

    Widget mensaje(String texto) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: s.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Row(
            children: [
              Icon(Icons.event_busy_outlined, size: 20, color: s.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(texto, style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant)),
              ),
            ],
          ),
        );

    final Widget cuerpo;
    if (vm.fecha == null) {
      cuerpo = mensaje('Elige una fecha para ver las horas disponibles.');
    } else if (!vm.hayFranjasLibres) {
      cuerpo = mensaje('No quedan horas libres este día con los servicios, el estilista y el cliente elegidos.');
    } else {
      cuerpo = LayoutBuilder(
        builder: (context, c) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: c.maxWidth >= 560 ? 6 : 4,
            mainAxisExtent: 40,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: franjas.length,
          itemBuilder: (context, i) => _Franja(
            franja: franjas[i],
            elegida: vm.esHoraElegida(franjas[i].inicio),
            error: error,
            alElegir: alElegir,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hora de inicio', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _Leyenda(texto: 'Libre', borde: s.outline),
            _Leyenda(texto: 'No disponible', relleno: s.surfaceContainerHighest),
            _Leyenda(texto: 'Elegida', relleno: s.primary),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        cuerpo,
        if (pie != null) pie!,
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.texto, this.relleno, this.borde});

  final String texto;
  final Color? relleno;
  final Color? borde;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: relleno,
            border: borde == null ? null : Border.all(color: borde!),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(texto,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w400)),
      ],
    );
  }
}

class _Franja extends StatelessWidget {
  const _Franja({required this.franja, required this.elegida, required this.error, required this.alElegir});

  final FranjaHoraria franja;
  final bool elegida;
  final bool error;
  final ValueChanged<DateTime> alElegir;

  static String _motivo(MotivoNoDisponible? m) {
    switch (m) {
      case MotivoNoDisponible.pasada:
        return 'Ya pasó';
      case MotivoNoDisponible.excedeCierre:
        return 'Terminaría después de las 19:00';
      case MotivoNoDisponible.ocupadaEstilista:
        return 'El estilista está ocupado';
      case MotivoNoDisponible.ocupadaCliente:
        return 'El cliente ya tiene un turno';
      case null:
        return 'Libre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final radio = BorderRadius.circular(AppRadius.slot);
    final texto = Fmt.hora(franja.inicio);

    if (!franja.disponible) {
      return Tooltip(
        message: _motivo(franja.motivo),
        child: Opacity(
          opacity: 0.55,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(color: s.surfaceContainerHighest, borderRadius: radio),
            child: Text(texto, style: theme.textTheme.labelMedium?.copyWith(color: s.outline)),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      selected: elegida,
      child: Material(
        color: elegida ? s.primary : s.surface.withValues(alpha: 0),
        shape: RoundedRectangleBorder(
          borderRadius: radio,
          side: elegida
              ? BorderSide.none
              : BorderSide(color: error ? s.error : s.outline),
        ),
        child: InkWell(
          borderRadius: radio,
          onTap: () => alElegir(franja.inicio),
          child: Center(
            child: Text(
              texto,
              style: theme.textTheme.labelMedium?.copyWith(
                color: elegida ? s.onPrimary : s.onSurface,
                fontWeight: elegida ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resumen siempre visible (duración, hora de fin y precio) y botones.
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.vm,
    required this.tecladoAbierto,
    required this.alCancelar,
    required this.alGuardar,
  });

  final TurnoFormViewModel vm;
  final bool tecladoAbierto;
  final VoidCallback alCancelar;
  final VoidCallback alGuardar;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final fin = vm.fin;
    return Material(
      color: s.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, tecladoAbierto ? 8 : 12, 16, tecladoAbierto ? 8 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: s.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DatoResumen(icono: Icons.schedule, texto: Fmt.duracion(vm.duracion)),
                  _DatoResumen(icono: Icons.flag_outlined, texto: 'Fin ${fin == null ? '--:--' : Fmt.hora(fin)}'),
                  _DatoResumen(icono: Icons.paid_outlined, texto: Fmt.precio(vm.precio), negrita: true),
                ],
              ),
            ),
            if (!tecladoAbierto) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: alCancelar, child: const Text('Cancelar')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: alGuardar,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Guardar turno', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DatoResumen extends StatelessWidget {
  const _DatoResumen({required this.icono, required this.texto, this.negrita = false});

  final IconData icono;
  final String texto;
  final bool negrita;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: s.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: negrita ? FontWeight.w700 : FontWeight.w600,
                color: s.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
