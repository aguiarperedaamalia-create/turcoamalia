import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/horario.dart';
import '../models/servicio.dart';
import '../models/turno.dart';

/// Conjunto de datos de prueba cargados en memoria al iniciar la app.
class DatosPrueba {
  const DatosPrueba({
    required this.servicios,
    required this.estilistas,
    required this.clientes,
    required this.turnos,
  });

  final List<Servicio> servicios;
  final List<Estilista> estilistas;
  final List<Cliente> clientes;
  final List<Turno> turnos;

  /// 13 servicios en las 5 categorías: 4 solo mujeres, 5 solo hombres y 4 unisex.
  static const List<Servicio> catalogo = [
    Servicio(id: 1, nombre: 'Corte mujer', categoria: Categoria.corte, duracionMin: 60, precio: 30, publico: Publico.mujeres),
    Servicio(id: 2, nombre: 'Corte caballero', categoria: Categoria.corte, duracionMin: 45, precio: 25, publico: Publico.hombres),
    Servicio(id: 3, nombre: 'Corte clásico', categoria: Categoria.corte, duracionMin: 30, precio: 18, publico: Publico.hombres),
    Servicio(id: 4, nombre: 'Color completo', categoria: Categoria.color, duracionMin: 120, precio: 70, publico: Publico.mujeres),
    Servicio(id: 5, nombre: 'Mechas', categoria: Categoria.color, duracionMin: 90, precio: 55, publico: Publico.mujeres),
    Servicio(id: 6, nombre: 'Retoque de raíz', categoria: Categoria.color, duracionMin: 60, precio: 35, publico: Publico.unisex),
    Servicio(id: 7, nombre: 'Barba', categoria: Categoria.barba, duracionMin: 45, precio: 20, publico: Publico.hombres),
    Servicio(id: 8, nombre: 'Afeitado', categoria: Categoria.barba, duracionMin: 30, precio: 15, publico: Publico.hombres),
    Servicio(id: 9, nombre: 'Arreglo de barba', categoria: Categoria.barba, duracionMin: 30, precio: 12, publico: Publico.hombres),
    Servicio(id: 10, nombre: 'Peinado evento', categoria: Categoria.peinado, duracionMin: 60, precio: 40, publico: Publico.unisex),
    Servicio(id: 11, nombre: 'Brushing', categoria: Categoria.peinado, duracionMin: 30, precio: 15, publico: Publico.mujeres),
    Servicio(id: 12, nombre: 'Hidratación', categoria: Categoria.tratamiento, duracionMin: 45, precio: 28, publico: Publico.unisex),
    Servicio(id: 13, nombre: 'Keratina', categoria: Categoria.tratamiento, duracionMin: 90, precio: 60, publico: Publico.unisex),
  ];

  /// 5 estilistas: Marta solo mujeres, Pedro solo hombres, Lucía ambos.
  static const List<Estilista> plantilla = [
    Estilista(id: 1, nombre: 'Marta Salazar', avatar: 'assets/images/estilistas/marta.png', servicioIds: [1, 4, 5, 11]),
    Estilista(id: 2, nombre: 'Pedro Vega', avatar: 'assets/images/estilistas/pedro.png', servicioIds: [2, 3, 7, 8, 9]),
    Estilista(id: 3, nombre: 'Lucía Torres', avatar: 'assets/images/estilistas/lucia.png', servicioIds: [1, 2, 10, 12, 13]),
    Estilista(id: 4, nombre: 'Rafael Núñez', avatar: 'assets/images/estilistas/rafael.png', servicioIds: [3, 7, 8, 9, 12]),
    Estilista(id: 5, nombre: 'Elena Ruiz', avatar: 'assets/images/estilistas/elena.png', servicioIds: [4, 5, 6, 10, 11, 12]),
  ];

  static const String _notaLarga =
      'Clienta de confianza que viene a peinarse para la boda de su hermana. '
      'Quiere un color cálido, sin tonos rojizos, y un corte que conserve el largo '
      'por debajo de los hombros para poder recogerlo el día del evento. Tiene el '
      'cuero cabelludo sensible: usar productos sin amoníaco y probar el tinte detrás '
      'de la oreja antes de aplicarlo. Prefiere que no se use secador muy caliente y '
      'pide terminar con brushing suave. Trae fotos de referencia en el teléfono.';

  /// Genera los datos con fechas relativas a [ahora], para que no queden
  /// vencidos con el paso de los días. Los turnos pasados quedan completados o
  /// cancelados y los futuros, programados.
  static DatosPrueba generar(DateTime ahora) {
    final hoy = HorarioSalon.proximoDiaHabil(ahora);
    DateTime dia(int offset) => HorarioSalon.sumarDiasHabiles(hoy, offset);

    final clientes = <Cliente>[
      Cliente(id: 1, nombre: 'Laura Gómez', telefono: '52111222', genero: Genero.mujer, correo: 'laura.gomez@correo.com', fechaRegistro: ahora.subtract(const Duration(days: 210))),
      Cliente(id: 2, nombre: 'Carlos Ruiz', telefono: '52345678', genero: Genero.hombre, correo: 'carlos.ruiz@correo.com', fechaRegistro: ahora.subtract(const Duration(days: 180))),
      Cliente(id: 3, nombre: 'Ana Martín', telefono: '53220140', genero: Genero.mujer, fechaRegistro: ahora.subtract(const Duration(days: 150))),
      Cliente(id: 4, nombre: 'Diego Pérez', telefono: '55908771', genero: Genero.hombre, fechaRegistro: ahora.subtract(const Duration(days: 120))),
      Cliente(id: 5, nombre: 'Sofía Díaz', telefono: '54667310', genero: Genero.mujer, correo: 'sofia.diaz@correo.com', fechaRegistro: ahora.subtract(const Duration(days: 95))),
      Cliente(id: 6, nombre: 'Javier Soto', telefono: '52774009', genero: Genero.hombre, fechaRegistro: ahora.subtract(const Duration(days: 60))),
      Cliente(id: 7, nombre: 'Marta Peña', telefono: '53441902', genero: Genero.mujer, fechaRegistro: ahora.subtract(const Duration(days: 45))),
      Cliente(id: 8, nombre: 'Luis Hernández', telefono: '56123987', genero: Genero.hombre, correo: 'luis.hdez@correo.com', fechaRegistro: ahora.subtract(const Duration(days: 30))),
      Cliente(id: 9, nombre: 'Elena Castro', telefono: '58776210', genero: Genero.mujer, fechaRegistro: ahora.subtract(const Duration(days: 20))),
      Cliente(id: 10, nombre: 'Andrés Molina', telefono: '59012345', genero: Genero.hombre, fechaRegistro: ahora.subtract(const Duration(days: 12))),
    ];

    // (día hábil relativo, hora, minuto, cliente, estilista, servicios, notas,
    //  estado si ya pasó)
    const planes = <_Plan>[
      _Plan(-3, 10, 0, 1, 1, [1], null, EstadoTurno.completado),
      _Plan(-3, 11, 0, 2, 2, [2], 'Degradado bajo y patillas cortas.', EstadoTurno.completado),
      _Plan(-2, 9, 30, 5, 3, [12, 1], null, EstadoTurno.completado),
      _Plan(-2, 16, 0, 4, 2, [7], 'Avisó que no podía venir.', EstadoTurno.cancelado),
      _Plan(-1, 12, 0, 3, 5, [4], null, EstadoTurno.completado),
      _Plan(-1, 17, 0, 10, 4, [3, 8], null, EstadoTurno.cancelado),
      // Hoy (6 turnos)
      _Plan(0, 9, 0, 1, 1, [1], null, EstadoTurno.completado),
      _Plan(0, 10, 0, 2, 2, [2, 7], 'Prefiere la máquina en el número 2 a los lados. Llega siempre diez minutos antes y pide agua.', EstadoTurno.completado),
      _Plan(0, 10, 30, 3, 5, [6, 11], null, EstadoTurno.completado),
      _Plan(0, 12, 0, 4, 2, [9], null, EstadoTurno.cancelado),
      _Plan(0, 14, 0, 5, 3, [13, 1], 'Keratina suave, sin formol.', EstadoTurno.completado),
      _Plan(0, 17, 30, 8, 3, [2, 12], null, EstadoTurno.completado), // termina a las 19:00
      // Próximos días
      _Plan(1, 9, 0, 9, 1, [4, 1, 11], _notaLarga, EstadoTurno.completado), // 3 servicios
      _Plan(1, 11, 0, 7, 5, [5], null, EstadoTurno.completado),
      _Plan(2, 15, 0, 10, 2, [2, 7], null, EstadoTurno.completado),
      _Plan(3, 10, 0, 2, 4, [8], null, EstadoTurno.completado),
      _Plan(3, 16, 0, 1, 3, [10], 'Recogido para una graduación.', EstadoTurno.completado),
    ];

    int duracion(List<int> ids) => ids.fold(
        0, (s, id) => s + catalogo.firstWhere((x) => x.id == id).duracionMin);

    final turnos = <Turno>[];
    var id = 1;
    for (final p in planes) {
      final d = dia(p.dia);
      final inicio = DateTime(d.year, d.month, d.day, p.hora, p.minuto);
      final fin = inicio.add(Duration(minutes: duracion(p.servicios)));
      final pasado = inicio.isBefore(ahora);
      final estado = pasado ? p.estadoSiPasado : EstadoTurno.programado;

      var creado = DateTime(inicio.year, inicio.month, inicio.day - 6, 10, 15);
      if (creado.isAfter(ahora)) creado = ahora;
      DateTime modificado;
      if (estado == EstadoTurno.completado) {
        modificado = fin.isAfter(ahora) ? ahora : fin;
      } else if (estado == EstadoTurno.cancelado) {
        final m = inicio.subtract(const Duration(hours: 2));
        modificado = m.isAfter(ahora) ? ahora : m;
      } else {
        final m = creado.add(const Duration(days: 1, hours: 3));
        modificado = m.isAfter(ahora) ? creado : m;
      }
      if (modificado.isBefore(creado)) modificado = creado;

      turnos.add(Turno(
        id: id++,
        clienteId: p.cliente,
        estilistaId: p.estilista,
        servicioIds: List.unmodifiable(p.servicios),
        inicio: inicio,
        notas: p.notas,
        estado: estado,
        creado: creado,
        modificado: modificado,
      ));
    }

    return DatosPrueba(
      servicios: catalogo,
      estilistas: plantilla,
      clientes: clientes,
      turnos: turnos,
    );
  }
}

class _Plan {
  const _Plan(this.dia, this.hora, this.minuto, this.cliente, this.estilista,
      this.servicios, this.notas, this.estadoSiPasado);

  final int dia;
  final int hora;
  final int minuto;
  final int cliente;
  final int estilista;
  final List<int> servicios;
  final String? notas;
  final EstadoTurno estadoSiPasado;
}
