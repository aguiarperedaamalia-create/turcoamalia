import 'package:flutter/material.dart';

/// Diálogo de confirmación del diseño (icono de alerta, título, texto y dos
/// acciones). Devuelve `true` si se confirma.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String textoConfirmar,
  String textoCancelar = 'Volver',
  bool destructivo = true,
}) async {
  final s = Theme.of(context).colorScheme;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: destructivo ? s.error : s.tertiary),
      iconPadding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
      title: Text(titulo),
      content: Text(mensaje),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(textoCancelar),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: destructivo ? s.error : s.primary),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  return r ?? false;
}
