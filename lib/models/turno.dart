import 'enums.dart';

/// Turno de un cliente con un estilista.
///
/// La hora de fin y el precio total no se guardan: se calculan a partir de
/// los servicios (ver `SalonRepository.finDe` y `SalonRepository.totalDe`).
class Turno {
  const Turno({
    required this.id,
    required this.clienteId,
    required this.estilistaId,
    required this.servicioIds,
    required this.inicio,
    this.notas,
    required this.estado,
    required this.creado,
    required this.modificado,
  });

  final int id;
  final int clienteId;
  final int estilistaId;
  final List<int> servicioIds;

  /// Fecha y hora de inicio.
  final DateTime inicio;
  final String? notas;
  final EstadoTurno estado;
  final DateTime creado;
  final DateTime modificado;

  bool get esProgramado => estado == EstadoTurno.programado;

  bool get tieneNotas => notas != null && notas!.trim().isNotEmpty;

  Turno copyWith({
    int? clienteId,
    int? estilistaId,
    List<int>? servicioIds,
    DateTime? inicio,
    String? notas,
    bool borrarNotas = false,
    EstadoTurno? estado,
    DateTime? modificado,
  }) {
    return Turno(
      id: id,
      clienteId: clienteId ?? this.clienteId,
      estilistaId: estilistaId ?? this.estilistaId,
      servicioIds: servicioIds ?? this.servicioIds,
      inicio: inicio ?? this.inicio,
      notas: borrarNotas ? null : (notas ?? this.notas),
      estado: estado ?? this.estado,
      creado: creado,
      modificado: modificado ?? this.modificado,
    );
  }
}
