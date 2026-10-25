import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../data/salon_repository.dart';
import '../../models/cliente.dart';
import '../../models/enums.dart';
import '../../viewmodels/clientes_view_model.dart';
import '../../widgets/campos.dart';

/// Abre la hoja inferior de alta / edición de cliente. Se usa desde la
/// pantalla Clientes y desde el Formulario de turno ("Crear cliente nuevo").
/// Devuelve el cliente guardado o `null` si se cancela.
Future<Cliente?> mostrarFormularioCliente(BuildContext context, {Cliente? cliente}) {
  return showModalBottomSheet<Cliente>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ClienteFormSheet(cliente: cliente),
  );
}

/// Form del cliente con validaciones: nombre (3–60), teléfono (8 dígitos, no
/// repetido), género obligatorio y correo opcional con formato válido.
class ClienteFormSheet extends StatefulWidget {
  const ClienteFormSheet({super.key, this.cliente});

  final Cliente? cliente;

  @override
  State<ClienteFormSheet> createState() => _ClienteFormSheetState();
}

class _ClienteFormSheetState extends State<ClienteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.cliente?.nombre);
  late final TextEditingController _telefono = TextEditingController(text: widget.cliente?.telefono);
  late final TextEditingController _correo = TextEditingController(text: widget.cliente?.correo);
  final _fNombre = FocusNode();
  final _fTelefono = FocusNode();
  final _fGenero = FocusNode();
  final _fCorreo = FocusNode();
  late Genero? _genero = widget.cliente?.genero;
  bool _intentado = false;
  String? _errorGeneral;

  ClientesViewModel get vm => AppScope.of(context).clientes;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _correo.dispose();
    _fNombre.dispose();
    _fTelefono.dispose();
    _fGenero.dispose();
    _fCorreo.dispose();
    super.dispose();
  }

  String? _vNombre(String? v) => ValidacionCliente.nombre(v);
  String? _vTelefono(String? v) => ValidacionCliente.telefono(v,
      enUso: (t) => vm.telefonoEnUso(t, exceptoId: widget.cliente?.id));
  String? _vCorreo(String? v) => ValidacionCliente.correo(v);

  void _guardar() {
    setState(() {
      _intentado = true;
      _errorGeneral = null;
    });
    final valido = _formKey.currentState!.validate();
    if (!valido) {
      // El foco va al primer campo con error.
      if (_vNombre(_nombre.text) != null) {
        _fNombre.requestFocus();
      } else if (_vTelefono(_telefono.text) != null) {
        _fTelefono.requestFocus();
      } else if (_genero == null) {
        _fGenero.requestFocus();
      } else {
        _fCorreo.requestFocus();
      }
      return;
    }
    try {
      final c = vm.guardar(
        id: widget.cliente?.id,
        nombre: _nombre.text,
        telefono: _telefono.text.trim(),
        genero: _genero!,
        correo: _correo.text,
      );
      Navigator.of(context).pop(c);
    } on ReglaNegocioException catch (e) {
      setState(() => _errorGeneral = e.mensaje);
    }
  }

  void _alCambiar(String _) {
    if (_intentado) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    // Los mensajes se calculan con los mismos validadores del Form y se muestran
    // bajo cada campo con el estilo del diseño.
    final eNombre = _intentado ? _vNombre(_nombre.text) : null;
    final eTelefono = _intentado ? _vTelefono(_telefono.text) : null;
    final eGenero = _intentado ? ValidacionCliente.genero(_genero) : null;
    final eCorreo = _intentado ? _vCorreo(_correo.text) : null;
    final sinTextoError = InputDecoration(
      errorStyle: TextStyle(fontSize: 0, height: 0, color: s.error),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: AppSpacing.hoja,
        child: Form(
          key: _formKey,
          autovalidateMode: _intentado ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.cliente == null ? 'Nuevo cliente' : 'Editar cliente',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              EtiquetaCampo('Nombre', error: eNombre != null),
              TextFormField(
                controller: _nombre,
                focusNode: _fNombre,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: sinTextoError.copyWith(hintText: 'Nombre y apellidos'),
                validator: _vNombre,
                onChanged: _alCambiar,
                onFieldSubmitted: (_) => _fTelefono.requestFocus(),
              ),
              if (eNombre != null) LineaError(eNombre),
              const SizedBox(height: 14),
              EtiquetaCampo('Teléfono', error: eTelefono != null),
              TextFormField(
                controller: _telefono,
                focusNode: _fTelefono,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: sinTextoError.copyWith(hintText: '8 dígitos'),
                validator: _vTelefono,
                onChanged: _alCambiar,
                onFieldSubmitted: (_) => _fCorreo.requestFocus(),
              ),
              if (eTelefono != null) LineaError(eTelefono),
              const SizedBox(height: 14),
              EtiquetaCampo('Género', error: eGenero != null),
              FormField<Genero>(
                initialValue: _genero,
                validator: (_) => ValidacionCliente.genero(_genero),
                builder: (state) => Focus(
                  focusNode: _fGenero,
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<Genero>(
                      emptySelectionAllowed: true,
                      segments: [
                        for (final g in Genero.values) ButtonSegment(value: g, label: Text(g.etiqueta)),
                      ],
                      selected: _genero == null ? <Genero>{} : {_genero!},
                      onSelectionChanged: (sel) {
                        setState(() => _genero = sel.isEmpty ? null : sel.first);
                        state.didChange(_genero);
                      },
                    ),
                  ),
                ),
              ),
              if (eGenero != null) LineaError(eGenero),
              const SizedBox(height: 14),
              EtiquetaCampo('Correo (opcional)', error: eCorreo != null),
              TextFormField(
                controller: _correo,
                focusNode: _fCorreo,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: sinTextoError.copyWith(hintText: 'nombre@correo.com'),
                validator: _vCorreo,
                onChanged: _alCambiar,
                onFieldSubmitted: (_) => _guardar(),
              ),
              if (eCorreo != null) LineaError(eCorreo),
              if (_errorGeneral != null) LineaError(_errorGeneral!),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _guardar,
                      child: const Text('Guardar cliente'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
