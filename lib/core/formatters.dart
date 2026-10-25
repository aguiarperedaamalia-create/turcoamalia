/// Formateo de fechas, horas, precios y textos en español.
abstract final class Fmt {
  static const _diasLargos = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String _dos(int n) => n.toString().padLeft(2, '0');

  static String diaCorto(DateTime d) => _diasCortos[d.weekday - 1];

  static String capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// "Octubre 2026"
  static String mesAnio(DateTime d) => '${capitalizar(_meses[d.month - 1])} ${d.year}';

  /// "Miércoles 21 de octubre de 2026"
  static String fechaLarga(DateTime d) =>
      '${_diasLargos[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]} de ${d.year}';

  /// "mié 21 de octubre"
  static String fechaCorta(DateTime d) =>
      '${diaCorto(d).toLowerCase()} ${d.day} de ${_meses[d.month - 1]}';

  /// "10:30"
  static String hora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';

  /// "19/10"
  static String diaMes(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}';

  /// "15/10/2026"
  static String fechaNumerica(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';

  /// "15/10/2026 14:05"
  static String fechaHora(DateTime d) => '${fechaNumerica(d)} ${hora(d)}';

  /// "1 h 30 min", "45 min", "2 h"
  static String duracion(int minutos) {
    final h = minutos ~/ 60;
    final m = minutos % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h h';
    return '$h h $m min';
  }

  /// "$ 45" o "$ 12.50"
  static String precio(double v) {
    final entero = v == v.roundToDouble();
    return '\$ ${entero ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';
  }

  /// "52 345 678"
  static String telefono(String t) {
    if (t.length != 8) return t;
    return '${t.substring(0, 2)} ${t.substring(2, 5)} ${t.substring(5)}';
  }

  /// "1 turno", "3 turnos"
  static String plural(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';
}

/// Normalización de texto para búsquedas: ignora mayúsculas y acentos.
abstract final class TextoBusqueda {
  static const _con = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
  static const _sin = 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC';

  static String normalizar(String s) {
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = _con.indexOf(ch);
      b.write(i >= 0 ? _sin[i] : ch);
    }
    return b.toString().toLowerCase().trim();
  }

  static String soloDigitos(String s) => s.replaceAll(RegExp(r'\D'), '');
}
