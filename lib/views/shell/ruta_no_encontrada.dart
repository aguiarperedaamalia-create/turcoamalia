import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/estado_vacio.dart';

/// Pantalla para rutas que no existen: mensaje claro y botón para volver.
class RutaNoEncontrada extends StatelessWidget {
  const RutaNoEncontrada({super.key, required this.ruta});

  final String ruta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
        child: Center(
          child: EstadoVacio(
            imagen: 'assets/images/ilustraciones/no_encontrado.png',
            titulo: 'Esta página no existe',
            mensaje: 'La ruta "$ruta" no forma parte de Turco.',
            error: true,
            tamano: 112,
            accion: FilledButton.icon(
              onPressed: () => context.go('/agenda'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Volver a la agenda'),
            ),
          ),
        ),
      ),
    );
  }
}
