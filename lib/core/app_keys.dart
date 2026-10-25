import 'package:flutter/material.dart';

/// Navigator raíz: las pantallas Detalle y Formulario se abren por encima de
/// la barra inferior usando `parentNavigatorKey: rootNavigatorKey`.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'raiz');

/// ScaffoldMessenger raíz para mostrar SnackBars desde cualquier pantalla.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>(debugLabel: 'mensajes');
