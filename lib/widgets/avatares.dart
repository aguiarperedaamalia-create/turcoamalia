import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/estilista.dart';

/// Avatar circular con la inicial del cliente (mujeres en primaryContainer,
/// hombres en tertiaryContainer, como en el diseño).
class AvatarCliente extends StatelessWidget {
  const AvatarCliente(this.cliente, {super.key, this.tamano = 44});

  final Cliente cliente;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final mujer = cliente.genero == Genero.mujer;
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: mujer ? s.primaryContainer : s.tertiaryContainer,
      ),
      child: Text(
        cliente.inicial,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: tamano * 0.4,
          fontWeight: FontWeight.w600,
          color: mujer ? s.onPrimaryContainer : s.onTertiaryContainer,
        ),
      ),
    );
  }
}

/// Avatar del estilista a partir de su recurso gráfico ([Estilista.avatar]).
class AvatarEstilista extends StatelessWidget {
  const AvatarEstilista(this.estilista, {super.key, this.tamano = 56});

  final Estilista estilista;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: s.primaryContainer),
      child: Image.asset(
        estilista.avatar,
        width: tamano * 0.62,
        height: tamano * 0.62,
        color: s.onPrimaryContainer,
        semanticLabel: estilista.nombre,
      ),
    );
  }
}
