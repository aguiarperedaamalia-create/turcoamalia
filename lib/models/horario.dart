/// Reglas de horario del salón.
///
/// Atiende de lunes a sábado de 9:00 a 19:00. Los turnos comienzan en franjas
/// de 30 minutos y deben terminar a las 19:00 como máximo.
abstract final class HorarioSalon {
  static const int aperturaMin = 9 * 60;
  static const int cierreMin = 19 * 60;
  static const int franjaMin = 30;

  /// Domingo cerrado.
  static bool abre(DateTime fecha) => fecha.weekday != DateTime.sunday;

  static DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime apertura(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day, 9);

  static DateTime cierre(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day, 19);

  /// Inicio de todas las franjas de un día (09:00, 09:30, ..., 18:30).
  static List<DateTime> franjasDe(DateTime fecha) {
    final base = soloFecha(fecha);
    return [
      for (var m = aperturaMin; m < cierreMin; m += franjaMin)
        base.add(Duration(minutes: m)),
    ];
  }

  /// La hora de inicio cae en una franja válida.
  static bool esInicioDeFranja(DateTime inicio) {
    final minutos = inicio.hour * 60 + inicio.minute;
    return inicio.second == 0 &&
        minutos >= aperturaMin &&
        minutos < cierreMin &&
        (minutos - aperturaMin) % franjaMin == 0;
  }

  /// Dos intervalos [aInicio, aFin) y [bInicio, bFin) se solapan.
  /// Un turno que termina a las 10:00 no se solapa con otro que empieza a las 10:00.
  static bool seSolapan(
          DateTime aInicio, DateTime aFin, DateTime bInicio, DateTime bFin) =>
      aInicio.isBefore(bFin) && bInicio.isBefore(aFin);

  /// Primer día en que el salón abre a partir de [desde] (incluido).
  static DateTime proximoDiaHabil(DateTime desde) {
    var d = soloFecha(desde);
    while (!abre(d)) {
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return d;
  }

  /// Suma [n] días hábiles (saltando domingos). [n] puede ser negativo.
  static DateTime sumarDiasHabiles(DateTime desde, int n) {
    var d = soloFecha(desde);
    final paso = n >= 0 ? 1 : -1;
    var restantes = n.abs();
    while (restantes > 0) {
      d = DateTime(d.year, d.month, d.day + paso);
      if (abre(d)) restantes--;
    }
    return d;
  }

  /// Lunes de la semana de [fecha].
  static DateTime lunesDe(DateTime fecha) {
    final d = soloFecha(fecha);
    return DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));
  }
}

/// Estado de una franja horaria en el formulario.
enum MotivoNoDisponible {
  pasada,
  excedeCierre,
  ocupadaEstilista,
  ocupadaCliente,
}

class FranjaHoraria {
  const FranjaHoraria(this.inicio, [this.motivo]);

  final DateTime inicio;

  /// `null` si la franja está libre.
  final MotivoNoDisponible? motivo;

  bool get disponible => motivo == null;
}
