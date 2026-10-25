# Turco · Gestión de turnos de una peluquería

Aplicación Flutter para Android que usa el personal de recepción de una peluquería mixta para registrar clientes, programar turnos con un estilista y llevar la agenda diaria.

- **Estudiante:** Amalia Aguiar Pereda
- **Asignatura:** Programación para Dispositivos Móviles · Ingeniería Informática, 3er año
- **Evaluación:** Primer Examen Parcial
- **Application id:** `com.amaliaaguiar.turco`
- **Nombre visible:** Turco

## Versión de Flutter

- Flutter **3.27 o superior** (canal stable), Dart **3.6 o superior**.
- Versión usada para generar el APK: `Flutter <versión>` ← sustituir por la salida de `flutter --version`.

Dependencias: `go_router` (navegación) y `flutter_localizations` (del SDK, para el selector de fecha en español). No se usan gestores de estado externos, almacenamiento local ni bases de datos.

## Cómo inicializar y ejecutar

### Desde Android Studio

1. Instalar los plugins **Flutter** y **Dart** (Settings → Plugins).
2. *File → Open…* y elegir la carpeta del proyecto (la que contiene `pubspec.yaml`).
3. Si lo pide, indicar la ruta del Flutter SDK (Settings → Languages & Frameworks → Flutter).
4. Pulsar **Pub get** en el aviso de `pubspec.yaml` (o ejecutar `flutter pub get`).
5. Elegir un emulador o teléfono Android y pulsar **Run ▶** sobre `lib/main.dart`.

### Desde la terminal

```bash
flutter pub get
flutter run
```

Los archivos `android/local.properties`, `gradlew` y `gradle-wrapper.jar` no se suben al repositorio: Flutter los genera al ejecutar `flutter pub get` / `flutter run`.

Si en algún equipo faltara un archivo generado de la plataforma Android, se puede regenerar sin tocar `lib/` con:

```bash
flutter create . --org com.amaliaaguiar --project-name turco --platforms android
```

## Pruebas

```bash
flutter test
```

`test/reglas_negocio_test.dart` comprueba los datos de prueba (mínimos del enunciado) y las reglas: solapes, franja de 19:00, domingos, fechas pasadas, cancelación que libera horario, edición sin autosolape, teléfono único y búsqueda sin acentos.

## Cómo generar el APK release

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Como `build/` está en `.gitignore`, se copia a `entrega/` y se publica en **GitHub → Releases**. El build release está firmado con la llave de depuración, así no hace falta ninguna llave `.jks` (las llaves nunca se suben).

## Estructura de carpetas

```
turco/
├── android/                 Proyecto Android (Gradle Kotlin DSL)
├── assets/
│   ├── fonts/               Poppins (Regular, Medium, SemiBold, Bold) + licencia OFL
│   └── images/              Logo, imágenes por categoría, avatares e ilustraciones
├── capturas/                Capturas reales de la app corriendo
├── entrega/                 APK release
├── lib/
│   ├── main.dart            Punto de entrada
│   ├── app.dart             MaterialApp.router, tema claro/oscuro/sistema, localización
│   ├── core/                Tema global (app_theme), formateo, AppScope (InheritedWidget), claves
│   ├── data/                SalonRepository (memoria + reglas) y datos de prueba
│   ├── models/              Servicio, Estilista, Cliente, Turno, enums y horario del salón
│   ├── router/              GoRouter con StatefulShellRoute.indexedStack
│   ├── viewmodels/          ViewModels con ChangeNotifier (MVVM)
│   ├── views/               Pantallas: agenda, turno (detalle y formulario), clientes,
│   │                        servicios, estilistas y shell con la barra inferior
│   └── widgets/             Widgets reutilizables (badges, campos, diálogos, avatares…)
├── test/                    Pruebas de las reglas de negocio
├── analysis_options.yaml
└── pubspec.yaml
```

## Arquitectura

- **MVVM:** cada pantalla tiene su ViewModel (`ChangeNotifier`) y la vista se reconstruye con `ListenableBuilder`. Los ViewModels de las pestañas viven en `AppScope` (un `InheritedWidget` de Flutter), así cada pestaña conserva búsqueda, filtros, fecha y scroll.
- **Reglas de negocio** en `SalonRepository` y los ViewModels: duración y precio calculados, horario de lunes a sábado de 9:00 a 19:00, franjas de 30 min, estilista que realiza todos los servicios, sin solapes de estilista ni de cliente (los cancelados no ocupan horario), sin turnos en el pasado, solo los programados se editan/completan/cancelan, teléfono único de 8 dígitos.
- **Datos en memoria:** se cargan al iniciar desde `lib/data/datos_prueba.dart`, con fechas calculadas a partir de `DateTime.now()`.
- **Navegación:** solo `go_router`. Se usan `pathParameters` (`/turno/:id`), `queryParameters` (`/agenda?estilista=3`), `extra` (datos iniciales del formulario) y retorno con `context.pop(turno)`.

| Ruta | Pantalla |
|---|---|
| `/agenda` (inicial) | Agenda (acepta `?estilista=`) |
| `/clientes` | Clientes |
| `/servicios` | Servicios |
| `/estilistas` | Estilistas |
| `/turno/nuevo` | Formulario de turno (crear, datos con `extra`) |
| `/turno/:id` | Detalle de turno |
| `/turno/:id/editar` | Formulario de turno (editar) |

## Tema y recursos

- Material 3, `seedColor 0xFF00695C`, paleta clara y oscura de la guía de estilo del diseño (`Turco Parcial Design.pen`), radios 16 (tarjetas) y 12 (campos), tipografía Poppins. Los colores de pantallas y widgets salen solo del `ColorScheme`.
- Las imágenes (logo, categorías, avatares e ilustraciones) se exportaron del diseño y se tiñen con colores del tema para funcionar en modo claro y oscuro.
- El tema se cambia entre **Sistema**, **Claro** y **Oscuro** desde el botón de la barra superior de la Agenda.
