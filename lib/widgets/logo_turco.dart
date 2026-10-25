import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Logo de Turco: tijeras sobre un cuadrado redondeado con el color primario.
class LogoTurco extends StatelessWidget {
  const LogoTurco({super.key, this.tamano = 32});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: s.primary,
        borderRadius: BorderRadius.circular(AppRadius.logo),
      ),
      child: Image.asset(
        'assets/images/logo_glyph.png',
        width: tamano * 0.56,
        height: tamano * 0.56,
        color: s.onPrimary,
        semanticLabel: 'Logo de Turco',
      ),
    );
  }
}
