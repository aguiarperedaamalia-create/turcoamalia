import 'package:flutter_test/flutter_test.dart';
import 'package:turco/core/formatters.dart';
import 'package:turco/data/salon_repository.dart';
import 'package:turco/models/enums.dart';
import 'package:turco/models/horario.dart';
import 'package:turco/viewmodels/clientes_view_model.dart';

void main() {
  // Miércoles 21/10/2026 a las 08:00 (antes de abrir).
  final ahora = DateTime(2026, 10, 21, 8);
  late SalonRepository repo;

  setUp(() => repo = SalonRepository.conDatosDePrueba(() => ahora));

  group('Datos de prueba', () {
    test('cumplen los mínimos del enunciado', () {
      expect(repo.servicios.length, greaterThanOrEqualTo(12));
      expect(repo.servicios.map((s) => s.categoria).toSet().length, 5);
      expect(repo.servicios.where((s) => s.publico == Publico.mujeres).length, greaterThanOrEqualTo(3));
      expect(repo.servicios.where((s) => s.publico == Publico.hombres).length, greaterThanOrEqualTo(3));
      expect(repo.servicios.where((s) => s.publico == Publico.unisex).length, greaterThanOrEqualTo(3));
      expect(repo.estilistas.length, greaterThanOrEqualTo(5));
      expect(repo.clientes.where((c) => c.genero == Genero.mujer).length, greaterThanOrEqualTo(5));
      expect(repo.clientes.where((c) => c.genero == Genero.hombre).length, greaterThanOrEqualTo(5));
      expect(repo.turnos.length, greaterThanOrEqualTo(16));
      expect(repo.turnosDelDia(ahora).length, greaterThanOrEqualTo(4));
      expect(repo.turnos.where((t) => t.estado == EstadoTurno.completado).length, greaterThanOrEqualTo(3));
      expect(repo.turnos.where((t) => t.estado == EstadoTurno.cancelado).length, greaterThanOrEqualTo(2));
      expect(repo.turnos.any((t) => t.servicioIds.length >= 3), isTrue);
      expect(repo.turnos.any((t) => !t.tieneNotas), isTrue);
      expect(repo.turnos.any((t) => (t.notas ?? '').length > 300), isTrue);
      expect(repo.turnos.any((t) => repo.finDe(t).hour == 19 && repo.finDe(t).minute == 0), isTrue);
      expect(repo.clientes.any((c) => repo.turnosDeCliente(c.id).isEmpty), isTrue);
      expect(repo.estilistas.any((e) => repo.turnosProgramadosHoy(e.id) == 0), isTrue);
    });

    test('estilistas: uno solo hombres, uno solo mujeres y uno ambos', () {
      bool solo(Publico p, e) => repo.serviciosDe(e.servicioIds).every((s) => s.publico == p);
      bool ambos(e) {
        final pubs = repo.serviciosDe(e.servicioIds).map((s) => s.publico).toSet();
        return pubs.contains(Publico.mujeres) && pubs.contains(Publico.hombres);
      }

      expect(repo.estilistas.any((e) => solo(Publico.hombres, e)), isTrue);
      expect(repo.estilistas.any((e) => solo(Publico.mujeres, e)), isTrue);
      expect(repo.estilistas.any(ambos), isTrue);
    });

    test('pasados completados o cancelados, futuros programados y sin solapes', () {
      for (final t in repo.turnos) {
        if (t.inicio.isBefore(ahora)) {
          expect(t.estado, isNot(EstadoTurno.programado));
        } else {
          expect(t.estado, EstadoTurno.programado);
        }
        expect(repo.estilista(t.estilistaId)!.realizaTodos(t.servicioIds), isTrue);
      }
      final prog = repo.turnos.where((t) => t.esProgramado).toList();
      for (var i = 0; i < prog.length; i++) {
        for (var j = i + 1; j < prog.length; j++) {
          final a = prog[i], b = prog[j];
          final solapan = HorarioSalon.seSolapan(a.inicio, repo.finDe(a), b.inicio, repo.finDe(b));
          if (a.estilistaId == b.estilistaId || a.clienteId == b.clienteId) {
            expect(solapan, isFalse, reason: 'Turnos ${a.id} y ${b.id} se solapan');
          }
        }
      }
    });
  });

  group('Reglas de turnos', () {
    DateTime hoyA(int h, [int m = 0]) => DateTime(2026, 10, 21, h, m);

    test('un turno que termina a las 10:00 no se solapa con otro que empieza a las 10:00', () {
      // Marta (1) tiene a Laura de 09:00 a 10:00. Javier (6) no tiene turnos.
      expect(
        repo.validarTurno(clienteId: 6, estilistaId: 1, servicioIds: [11], inicio: hoyA(10)),
        isNull,
      );
      expect(
        repo.validarTurno(clienteId: 6, estilistaId: 1, servicioIds: [11], inicio: hoyA(9, 30)),
        isNotNull,
      );
    });

    test('rechaza estilista que no realiza el servicio, domingo, pasado y fin después de las 19:00', () {
      expect(repo.validarTurno(clienteId: 6, estilistaId: 1, servicioIds: [7], inicio: hoyA(15)), isNotNull);
      expect(
        repo.validarTurno(clienteId: 6, estilistaId: 2, servicioIds: [7], inicio: DateTime(2026, 10, 25, 10)),
        isNotNull,
      );
      expect(
        repo.validarTurno(clienteId: 6, estilistaId: 2, servicioIds: [7], inicio: DateTime(2026, 10, 20, 10)),
        isNotNull,
      );
      expect(repo.validarTurno(clienteId: 6, estilistaId: 2, servicioIds: [2, 7], inicio: hoyA(18)), isNotNull);
    });

    test('al cancelar un turno su horario vuelve a quedar libre', () {
      final carlos = repo.turnosDelDia(ahora).firstWhere((t) => t.clienteId == 2);
      DateTime franja = carlos.inicio;
      bool libre() => repo
          .franjas(fecha: ahora, duracionMin: 30, estilistaId: carlos.estilistaId)
          .firstWhere((f) => f.inicio == franja)
          .disponible;
      expect(libre(), isFalse);
      repo.cancelarTurno(carlos.id);
      expect(libre(), isTrue);
      expect(() => repo.completarTurno(carlos.id), throwsA(isA<ReglaNegocioException>()));
    });

    test('al editar, el propio turno no cuenta como solape', () {
      final t = repo.turnosDelDia(ahora).firstWhere((x) => x.esProgramado);
      expect(
        repo.validarTurno(
          clienteId: t.clienteId,
          estilistaId: t.estilistaId,
          servicioIds: t.servicioIds,
          inicio: t.inicio,
          excluirTurnoId: t.id,
        ),
        isNull,
      );
    });
  });

  group('Clientes', () {
    test('no se elimina un cliente con turnos programados', () {
      expect(() => repo.eliminarCliente(2), throwsA(isA<ReglaNegocioException>()));
      repo.eliminarCliente(6);
      expect(repo.cliente(6), isNull);
    });

    test('teléfono único de 8 dígitos y correo válido', () {
      bool enUso(String t) => repo.telefonoEnUso(t);
      expect(ValidacionCliente.telefono('5234', enUso: enUso), isNotNull);
      expect(ValidacionCliente.telefono('52345678', enUso: enUso), isNotNull);
      expect(ValidacionCliente.telefono('50000000', enUso: enUso), isNull);
      expect(ValidacionCliente.correo('carlos@correo'), isNotNull);
      expect(ValidacionCliente.correo(''), isNull);
      expect(ValidacionCliente.correo('a.b@correo.com'), isNull);
      expect(ValidacionCliente.nombre('Al'), isNotNull);
    });

    test('la búsqueda ignora mayúsculas y acentos y se combina con el género', () {
      final vm = ClientesViewModel(repo);
      vm.buscar('SOFIA');
      expect(vm.clientesFiltrados.map((c) => c.nombre), contains('Sofía Díaz'));
      vm.filtrar(FiltroGenero.hombres);
      expect(vm.clientesFiltrados, isEmpty);
      vm.dispose();
      expect(TextoBusqueda.normalizar('Núñez Martín'), 'nunez martin');
    });
  });
}
