import '../core/formatters.dart';
import '../data/salon_repository.dart';
import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/turno.dart';
import 'base_view_model.dart';

/// Resultado de intentar eliminar un cliente.
class ResultadoEliminar {
  const ResultadoEliminar._(this.ok, this.mensaje);
  const ResultadoEliminar.ok() : this._(true, null);
  const ResultadoEliminar.error(String m) : this._(false, m);

  final bool ok;
  final String? mensaje;
}

/// Validaciones del formulario de cliente (hoja inferior).
abstract final class ValidacionCliente {
  static final RegExp _correo = RegExp(r'^[\w.+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$');

  static String? nombre(String? v) {
    final n = (v ?? '').trim().length;
    if (n == 0) return 'El nombre es obligatorio';
    if (n < 3 || n > 60) return 'Escribe entre 3 y 60 caracteres';
    return null;
  }

  static String? telefono(String? v, {required bool Function(String) enUso}) {
    final t = (v ?? '').trim();
    if (!RegExp(r'^\d{8}$').hasMatch(t)) return 'Debe tener exactamente 8 dígitos';
    if (enUso(t)) return 'Ese teléfono ya está registrado';
    return null;
  }

  static String? genero(Genero? g) => g == null ? 'Selecciona un género' : null;

  static String? correo(String? v) {
    final c = (v ?? '').trim();
    if (c.isEmpty) return null;
    return _correo.hasMatch(c) ? null : 'Escribe un correo válido';
  }
}

/// Estado de la pantalla Clientes: búsqueda y filtro por género.
class ClientesViewModel extends RepoViewModel {
  ClientesViewModel(super.repo);

  String _busqueda = '';
  FiltroGenero _filtro = FiltroGenero.todos;

  String get busqueda => _busqueda;
  FiltroGenero get filtro => _filtro;

  void buscar(String texto) {
    if (texto == _busqueda) return;
    _busqueda = texto;
    notifyListeners();
  }

  void filtrar(FiltroGenero f) {
    if (f == _filtro) return;
    _filtro = f;
    notifyListeners();
  }

  /// Búsqueda por nombre o teléfono que ignora mayúsculas y acentos, combinada
  /// con el filtro de género.
  List<Cliente> get clientesFiltrados {
    final q = TextoBusqueda.normalizar(_busqueda);
    final qDigitos = TextoBusqueda.soloDigitos(_busqueda);
    final l = repo.clientes.where((c) {
      if (!_filtro.aceptaGenero(c.genero)) return false;
      if (q.isEmpty) return true;
      final enNombre = TextoBusqueda.normalizar(c.nombre).contains(q);
      final enTelefono = qDigitos.isNotEmpty && c.telefono.contains(qDigitos);
      return enNombre || enTelefono;
    }).toList();
    return l;
  }

  int get total => repo.clientes.length;
  int get totalMujeres => repo.clientes.where((c) => c.genero == Genero.mujer).length;
  int get totalHombres => repo.clientes.where((c) => c.genero == Genero.hombre).length;

  int cantidadTurnos(Cliente c) => repo.turnosDeCliente(c.id).length;
  List<Turno> historial(Cliente c) => repo.turnosDeCliente(c.id);
  Cliente? cliente(int id) => repo.cliente(id);

  bool telefonoEnUso(String t, {int? exceptoId}) =>
      repo.telefonoEnUso(t, exceptoClienteId: exceptoId);

  /// Crea o actualiza un cliente. Devuelve el cliente guardado.
  Cliente guardar({
    int? id,
    required String nombre,
    required String telefono,
    required Genero genero,
    String? correo,
  }) {
    if (id == null) {
      return repo.crearCliente(nombre: nombre, telefono: telefono, genero: genero, correo: correo);
    }
    return repo.actualizarCliente(
        clienteId: id, nombre: nombre, telefono: telefono, genero: genero, correo: correo);
  }

  /// Comprueba si se puede eliminar (sin turnos programados).
  ResultadoEliminar puedeEliminar(Cliente c) {
    final n = repo.turnosProgramadosDeCliente(c.id);
    if (n == 0) return const ResultadoEliminar.ok();
    return ResultadoEliminar.error(
        'No se puede eliminar: ${c.nombre} tiene ${Fmt.plural(n, 'turno programado', 'turnos programados')}.');
  }

  ResultadoEliminar eliminar(Cliente c) {
    try {
      repo.eliminarCliente(c.id);
      return const ResultadoEliminar.ok();
    } on ReglaNegocioException catch (e) {
      return ResultadoEliminar.error(e.mensaje);
    }
  }
}
