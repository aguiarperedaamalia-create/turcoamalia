import '../models/enums.dart';
import '../models/servicio.dart';
import 'base_view_model.dart';

/// Estado de la pantalla Servicios: filtros por categoría y por público.
class ServiciosViewModel extends RepoViewModel {
  ServiciosViewModel(super.repo);

  Categoria? _categoria;
  FiltroGenero _publico = FiltroGenero.todos;

  /// `null` = Todas.
  Categoria? get categoria => _categoria;
  FiltroGenero get publico => _publico;

  void filtrarCategoria(Categoria? c) {
    if (c == _categoria) return;
    _categoria = c;
    notifyListeners();
  }

  void filtrarPublico(FiltroGenero f) {
    if (f == _publico) return;
    _publico = f;
    notifyListeners();
  }

  List<Servicio> get serviciosFiltrados => repo.servicios
      .where((s) => _categoria == null || s.categoria == _categoria)
      .where((s) => _publico.aceptaPublico(s.publico))
      .toList();

  /// Columnas según el ancho: 2 (< 600 dp), 3 (600–840 dp) y 4 (> 840 dp).
  static int columnasPara(double ancho) {
    if (ancho < 600) return 2;
    if (ancho <= 840) return 3;
    return 4;
  }
}
