/// Estilista del salón (solo lectura).
class Estilista {
  const Estilista({
    required this.id,
    required this.nombre,
    required this.avatar,
    required this.servicioIds,
  });

  final int id;
  final String nombre;

  /// Ruta del recurso gráfico del avatar.
  final String avatar;

  /// Servicios que realiza.
  final List<int> servicioIds;

  /// Nombre de pila (se usa en la Agenda: "Marta", "Pedro"...).
  String get nombreCorto => nombre.split(' ').first;

  bool realiza(int servicioId) => servicioIds.contains(servicioId);

  /// Un estilista solo puede recibir turnos con servicios que realiza.
  bool realizaTodos(Iterable<int> ids) => ids.every(realiza);
}
