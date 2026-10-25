import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/servicio.dart';
import 'base_view_model.dart';

/// Estado de la pantalla Estilistas.
class EstilistasViewModel extends RepoViewModel {
  EstilistasViewModel(super.repo);

  List<Estilista> get estilistas => repo.estilistas;

  /// Servicios que realiza el estilista agrupados por categoría.
  Map<Categoria, List<Servicio>> serviciosPorCategoria(Estilista e) {
    final mapa = <Categoria, List<Servicio>>{};
    for (final s in repo.serviciosDe(e.servicioIds)) {
      mapa.putIfAbsent(s.categoria, () => []).add(s);
    }
    return mapa;
  }

  int turnosHoy(Estilista e) => repo.turnosProgramadosHoy(e.id);

  int get totalTurnosHoy => estilistas.fold(0, (s, e) => s + turnosHoy(e));
}
