import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_keys.dart';
import '../../core/app_scope.dart';
import '../../core/formatters.dart';
import '../../models/turno.dart';
import '../../widgets/dialogo_confirmacion.dart';

/// Muestra un SnackBar en la pantalla visible.
void mostrarMensaje(String texto, {String? accion, VoidCallback? alPulsar}) {
  final m = rootMessengerKey.currentState;
  if (m == null) return;
  m
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      action: accion == null ? null : SnackBarAction(label: accion, onPressed: alPulsar ?? () {}),
    ));
}

/// Tras volver del formulario de turno: la Agenda se ubica en la fecha del
/// turno guardado y se muestra el SnackBar de confirmación.
void mostrarTurnoGuardado(BuildContext context, Turno turno, {bool irAAgenda = false}) {
  final router = GoRouter.of(context);
  AppScope.of(context).agenda.seleccionarFecha(turno.inicio);
  if (irAAgenda) router.go('/agenda');
  mostrarMensaje(
    'Turno guardado para el ${Fmt.fechaCorta(turno.inicio)}',
    accion: 'Ver',
    alPulsar: () => router.push('/turno/${turno.id}'),
  );
}

/// Pide confirmación y marca el turno como completado.
Future<void> completarConConfirmacion(
  BuildContext context, {
  required String cliente,
  required DateTime inicio,
  required DateTime fin,
  required String? Function() accion,
}) async {
  final ok = await confirmar(
    context,
    titulo: '¿Completar este turno?',
    mensaje:
        'El turno de $cliente (${Fmt.hora(inicio)} a ${Fmt.hora(fin)}) se marcará como completado. Esta acción no se puede deshacer.',
    textoConfirmar: 'Completar',
    destructivo: false,
  );
  if (!ok) return;
  final error = accion();
  mostrarMensaje(error ?? 'Turno de $cliente completado');
}

/// Pide confirmación y cancela el turno (su horario vuelve a quedar libre).
Future<void> cancelarConConfirmacion(
  BuildContext context, {
  required String cliente,
  required DateTime inicio,
  required DateTime fin,
  required String? Function() accion,
}) async {
  final ok = await confirmar(
    context,
    titulo: '¿Cancelar este turno?',
    mensaje:
        'El horario de $cliente (${Fmt.hora(inicio)} a ${Fmt.hora(fin)}) quedará libre. Esta acción no se puede deshacer.',
    textoConfirmar: 'Cancelar turno',
  );
  if (!ok) return;
  final error = accion();
  mostrarMensaje(error ?? 'Turno de $cliente cancelado');
}
