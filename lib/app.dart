import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/app_keys.dart';
import 'core/app_scope.dart';
import 'core/app_theme.dart';
import 'data/salon_repository.dart';
import 'router/app_router.dart';
import 'viewmodels/agenda_view_model.dart';
import 'viewmodels/clientes_view_model.dart';
import 'viewmodels/estilistas_view_model.dart';
import 'viewmodels/servicios_view_model.dart';
import 'viewmodels/tema_view_model.dart';

/// Aplicación Turco · Gestión de turnos de una peluquería mixta.
/// Autora: Amalia Aguiar Pereda.
class TurcoApp extends StatefulWidget {
  const TurcoApp({super.key, this.repositorio});

  /// Permite inyectar un repositorio (pruebas). Por defecto, datos de prueba.
  final SalonRepository? repositorio;

  @override
  State<TurcoApp> createState() => _TurcoAppState();
}

class _TurcoAppState extends State<TurcoApp> {
  late final SalonRepository _repo = widget.repositorio ?? SalonRepository.conDatosDePrueba();
  late final TemaViewModel _tema = TemaViewModel();
  late final AgendaViewModel _agenda = AgendaViewModel(_repo);
  late final ClientesViewModel _clientes = ClientesViewModel(_repo);
  late final ServiciosViewModel _servicios = ServiciosViewModel(_repo);
  late final EstilistasViewModel _estilistas = EstilistasViewModel(_repo);
  late final GoRouter _router = crearRouter();

  @override
  void dispose() {
    _router.dispose();
    _agenda.dispose();
    _clientes.dispose();
    _servicios.dispose();
    _estilistas.dispose();
    _tema.dispose();
    if (widget.repositorio == null) _repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repo: _repo,
      tema: _tema,
      agenda: _agenda,
      clientes: _clientes,
      servicios: _servicios,
      estilistas: _estilistas,
      child: ListenableBuilder(
        listenable: _tema,
        builder: (context, _) => MaterialApp.router(
          title: 'Turco',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro,
          darkTheme: AppTheme.oscuro,
          themeMode: _tema.modo,
          scaffoldMessengerKey: rootMessengerKey,
          routerConfig: _router,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}
