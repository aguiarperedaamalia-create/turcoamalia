// Enumeraciones del dominio de Turco.

/// Categoría de un servicio del salón.
enum Categoria {
  corte('Corte', 'assets/images/categorias/corte.png'),
  color('Color', 'assets/images/categorias/color.png'),
  barba('Barba', 'assets/images/categorias/barba.png'),
  peinado('Peinado', 'assets/images/categorias/peinado.png'),
  tratamiento('Tratamiento', 'assets/images/categorias/tratamiento.png');

  const Categoria(this.etiqueta, this.imagen);

  /// Texto visible (por ejemplo "Corte").
  final String etiqueta;

  /// Ruta del recurso gráfico de la categoría.
  final String imagen;
}

/// Público al que se dirige un servicio.
enum Publico {
  mujeres('Mujeres'),
  hombres('Hombres'),
  unisex('Unisex');

  const Publico(this.etiqueta);
  final String etiqueta;
}

/// Género de un cliente.
enum Genero {
  mujer('Mujer'),
  hombre('Hombre');

  const Genero(this.etiqueta);
  final String etiqueta;
}

/// Estado de un turno.
enum EstadoTurno {
  programado('Programado'),
  completado('Completado'),
  cancelado('Cancelado');

  const EstadoTurno(this.etiqueta);
  final String etiqueta;
}

/// Filtro por género / público usado en Clientes, Servicios y el formulario.
enum FiltroGenero {
  todos('Todos'),
  mujeres('Mujeres'),
  hombres('Hombres');

  const FiltroGenero(this.etiqueta);
  final String etiqueta;

  /// Un servicio unisex se ofrece tanto a mujeres como a hombres.
  bool aceptaPublico(Publico publico) {
    switch (this) {
      case FiltroGenero.todos:
        return true;
      case FiltroGenero.mujeres:
        return publico != Publico.hombres;
      case FiltroGenero.hombres:
        return publico != Publico.mujeres;
    }
  }

  bool aceptaGenero(Genero genero) {
    switch (this) {
      case FiltroGenero.todos:
        return true;
      case FiltroGenero.mujeres:
        return genero == Genero.mujer;
      case FiltroGenero.hombres:
        return genero == Genero.hombre;
    }
  }

  static FiltroGenero desdeGenero(Genero genero) =>
      genero == Genero.mujer ? FiltroGenero.mujeres : FiltroGenero.hombres;
}

/// Filtro por estado de la Agenda.
enum FiltroEstado {
  todos('Todos', null),
  programados('Program.', EstadoTurno.programado),
  completados('Complet.', EstadoTurno.completado),
  cancelados('Cancel.', EstadoTurno.cancelado);

  const FiltroEstado(this.etiqueta, this.estado);
  final String etiqueta;
  final EstadoTurno? estado;

  bool acepta(EstadoTurno e) => estado == null || estado == e;
}
