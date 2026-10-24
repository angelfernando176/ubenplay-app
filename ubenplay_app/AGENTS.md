# AGENTS.md — Lingo

Guía para agentes y desarrolladores que trabajen en este repositorio. Toda la información fue extraída del código fuente; los puntos no determinables se marcan como **Por verificar**.

## Objetivo del proyecto

**Lingo** es una aplicación móvil Flutter de aprendizaje de vocabulario en **alemán** para hispanohablantes, con una interfaz estilo Duolingo. Permite practicar sustantivos (y en menor medida verbos) organizados por **niveles CEFR** (A1, A2, B1, B2) y por **temáticas** (familia, casa, comida, transporte, etc.), mediante juegos interactivos con sistema de XP, racha de días y seguimiento de progreso.

## Arquitectura

La app sigue una arquitectura por capas dentro de `lib/`:

```
lib/
├── main.dart                 # Arranque + selección de fuente de datos
├── data/lessons_data.dart    # Datos hardcodeados (seed) + categorías + migración
├── models/                   # Modelos de dominio (inmutables)
├── services/                 # Persistencia, backend, audio, progreso
├── screens/                  # Pantallas (UI + estado local con setState)
├── widgets/                  # Componentes reutilizables
├── games/                    # Lógica de los juegos
└── theme/app_theme.dart      # Tema central (colores, tipografía)
```

**Gestión de estado:** se usa `setState` + `StatefulWidget` (sin Provider/Bloc/Riverpod). El progreso viaja entre pantallas vía `Navigator.push` devolviendo el `UserProgress` actualizado.

**Fuentes de datos en cascada (3 niveles):** Supabase (remoto) → SQLite local (`lingo_nouns.db`) → datos hardcodeados en memoria. `main.dart` intenta Supabase primero; si no está configurado o no responde, cae a SQLite (migrando los datos hardcodeados) y finalmente usa los datos en memoria.

## Tecnologías utilizadas

- **Flutter** (≥ 3.44.0) / **Dart** (SDK `^3.12.2`)
- **Material 3** con tipografía **Nunito** (vía `google_fonts`)
- Dependencias principales (`pubspec.yaml`):
  - `sqflite` — base de datos SQLite local
  - `supabase_flutter` — backend remoto (Postgres vía Supabase)
  - `shared_preferences` — persistencia de progreso/perfil
  - `flutter_tts` — pronunciación (texto a voz)
  - `audioplayers` — efectos de sonido
  - `excel` — importación de sustantivos desde `.xlsx`
  - `path_provider` — rutas del sistema
  - `http` — sincronización con el admin web
- **Dev:** `flutter_lints` (^6.0.0), `flutter_test`

## Estructura de directorios

```
lingo_app/
├── lib/
│   ├── main.dart
│   ├── data/lessons_data.dart
│   ├── models/
│   │   ├── vocabulary_noun.dart   # enum CefrLevel + modelo unificado de palabra
│   │   ├── lesson.dart            # lección + dificultad + recompensa XP
│   │   ├── lesson_session.dart    # sesión de lección (fechas, puntuación)
│   │   ├── user_progress.dart     # XP, racha, lecciones completadas
│   │   ├── user_profile.dart      # datos personales del usuario
│   │   └── game_type.dart         # enum GameType (13 tipos)
│   ├── services/
│   │   ├── database_service.dart  # SQLite (esquema + importación)
│   │   ├── supabase_service.dart  # consultas a Supabase
│   │   ├── sync_service.dart      # sync HTTP con admin web (Flask)
│   │   ├── progress_service.dart  # carga/guardado de progreso
│   │   ├── user_profile_service.dart
│   │   └── audio_service.dart     # TTS + efectos de sonido
│   ├── screens/
│   │   ├── home_screen.dart       # tabs A1/A2/B1/B2 + racha
│   │   ├── category_screen.dart   # lista de lecciones por categoría
│   │   ├── lesson_screen.dart     # ejecución de lección/juego
│   │   ├── profile_screen.dart    # datos del usuario
│   │   ├── settings_screen.dart   # ajustes (S001)
│   │   ├── progress_screen.dart   # avances (S002)
│   │   ├── admin_screen.dart      # administración (S011)
│   │   └── game_settings_screen.dart
│   ├── widgets/ (xp_progress_bar, lesson_tile, category_tile, streak_widget)
│   ├── games/  (16 archivos: lógica de juegos + helpers)
│   └── theme/app_theme.dart
├── assets/sounds/                # solo .gitkeep (sonidos aún no incluidos)
├── test/widget_test.dart
├── android/ ios/ web/ linux/ windows/ macos/
├── pubspec.yaml
└── S012_PROPUESTA_ADMIN_WEB.md   # propuesta del admin web Flask
```

## Reglas y convenciones detectadas

- **Idioma:** comentarios y strings de UI en español; identificadores (clases, métodos, variables) en inglés.
- **Nombrado:** archivos en `snake_case`, clases en `PascalCase`, métodos/variables en `camelCase`.
- **Modelos inmutables:** constructores `const`, `factory ... fromJson`/`fromMap` y `toJson`.
- **Servicios estáticos:** `DatabaseService`, `SupabaseService`, `ProgressService`, etc. exponen métodos `static`.
- **Colores centralizados** en `AppTheme` (ej. `primaryGreen`, `xpBlue`, `incorrectRed`); no usar colores "a pelo".
- **Datos seed:** helper `_n(...)` en `lessons_data.dart` construye `VocabularyNoun`; el helper `_ic(cat, idx)` genera `imageCode` de 10 dígitos.
- **Historias de usuario** referenciadas en comentarios con prefijos `S001`…`S012` (ej. `// S001: Configuración`).
- **Logging:** se usa `print()` para mensajes de arranque en `main.dart`; no hay framework de logging.
- **Lints:** `flutter_lints` (configuración por defecto en `analysis_options.yaml`).

## Configuración importante

- **Supabase:** `SUPABASE_URL` y `SUPABASE_ANON_KEY` están hardcodeadas en `lib/main.dart` (líneas 12-13). **Por verificar:** la configuración real debe validarse en el dashboard de Supabase.
- **Admin web:** `SyncService._serverUrl` por defecto `http://192.168.100.14:9999`; configurable en `AdminScreen`. El doc S012 y el hint de UI mencionan el puerto `5000` — **Por verificar** cuál es el correcto.
- **TTS:** `AudioService.init()` configura idioma `es-ES` y velocidad `0.4` (lenta para aprendizaje).
- **Assets:** `assets/sounds/` registrado en `pubspec.yaml`, pero solo contiene `.gitkeep`; los archivos `correct.mp3`, `incorrect.mp3` y `complete.mp3` **no existen** (los métodos `play*` fallan silenciosamente).
- **Niveles desbloqueables:** un nivel CEFR se desbloquea al completar el 95% del anterior (`home_screen.dart`), salvo en modo admin (ver decisiones técnicas).

## Flujo de ejecución

1. `main()` → `WidgetsFlutterBinding.ensureInitialized()`.
2. Si `SUPABASE_URL` está configurado (no contiene `TU_PROYECTO`): inicializa `SupabaseService`, prueba conexión y, si hay conexión, `LessonsData.reloadFromSupabase()`.
3. Fallback local: abre `DatabaseService.database` (crea 3 tablas), `clearAll()` y `LessonsData.migrateToDatabase()` (carga datos hardcodeados a SQLite).
4. `runApp(LingoApp)` → `_HomeLoader` carga `ProgressService.loadProgress()` y muestra `HomeScreen`.

## Base de datos

**SQLite local** (`lingo_nouns.db`, `DatabaseService`), con 3 tablas creadas en `onCreate`:

| Tabla | Propósito |
|-------|-----------|
| `nouns` | sustantivos importados/seed (columnas: `id`, `category_id`, `spanish`, `german`, `article`, `plural`, `cefr_level`, `image`, `image_code`, `example_sentence`, `definition`) |
| `palabras` | esquema genérico de palabras (`id_palabra`, `id_categoria`, `palabra_es`, `palabra_de`, `id_tipo`, `id_nivel`, `id_tematica`, …) |
| `sustantivos` | plural por palabra (`id_palabra`, `plural`) |

> Nota: existe **duplicación de esquemas** (`nouns` vs `palabras`+`sustantivos`). El flujo local usa `nouns`; Supabase usa `palabras`/`sustantivos`. Ver "Problemas".

**Supabase** (remoto): tabla `palabras` relacionada con `sustantivos(plural)`, `verbos(*)` y `cat_tematica(nombre_tematica)`. El esquema exacto está **Por verificar** (se infiere de las queries).

## APIs

**SupabaseService** (consultas a la tabla `palabras`, filtro `id_categoria = 1` y `activo = true`):
- `fetchAll()` — todos los sustantivos
- `fetchByCategory(tematicaId)` — por temática
- `fetchByLevel(nivelId)` — por nivel CEFR
- `fetchAllGrouped()` — agrupado por temática
- `getCategoryCounts()` — conteo por temática
- `testConnection()` — verificación de conexión

**SyncService** (HTTP al admin web Flask, aún no implementado en este repo):
- `GET {serverUrl}/api/words` — descarga palabras, las agrupa por `category_id` y las importa a la BD local.

## Testing

- Framework: `flutter test` (`flutter_test`).
- Único archivo de tests: `test/widget_test.dart` — cubre modelos (`VocabularyNoun`, `Lesson`, `LessonSession`, `UserProgress`) e integridad de datos de `LessonsData` (imageCode de 10 dígitos y wordId únicos).
- **No hay tests de widgets ni de juegos.**

## Deployment

- Proyecto Flutter multi-plataforma estándar (carpetas `android/`, `ios/`, `web/`, `linux/`, `windows/`, `macos/`).
- Existe un build Android de debug (`build/app/outputs/flutter-apk/app-debug.apk`).
- **No hay** Dockerfile, docker-compose, CI/CD ni scripts de despliegue. **Por verificar** cuál es la plataforma objetivo principal (Android parece ser la de desarrollo).

## Decisiones técnicas detectadas

- **Tres fuentes de datos con fallback en cascada** (Supabase → SQLite → memoria), controlado en `main.dart`.
- **Datos hardcodeados como seed** y migración a SQLite (`LessonsData.migrateToDatabase()`).
- **Progreso persistido en `SharedPreferences`** como JSON (`user_progress`), no en la base de datos.
- **Modo admin sin autenticación:** `final bool _isAdmin = true;` hardcodeado en `home_screen.dart` (S005), lo que desbloquea todos los niveles.
- **Formato de importación Excel** de 5 columnas (español, artículo, alemán, plural, nivel) sin encabezados (`admin_screen.dart`).
- **Modelo de datos unificado** `VocabularyNoun` que contempla sustantivos (artículo/plural) y verbos (conjugaciones), aunque el contenido actual es mayoritariamente de sustantivos.

## Problemas o aspectos pendientes

1. **Credenciales Supabase en claro** en `main.dart` (URL + anon key). Riesgo de seguridad; deberían externalizarse.
2. **Pérdida de datos importados:** en el fallback local, `main.dart` ejecuta `clearAll()` + `migrateToDatabase()` en cada arranque frío, lo que borra cualquier importación de Excel previa (los datos importados por `AdminScreen` se escriben en la tabla `nouns`).
3. **Assets de sonido ausentes:** `correct.mp3`, `incorrect.mp3` y `complete.mp3` no están en `assets/sounds/` (los `play*` fallan en silencio).
4. **Contenido B1/B2 vacío:** las categorías B1/B2 están declaradas como listas vacías en `lessons_data.dart` ("empty for phase 2").
5. **Admin web (Flask) no implementado** en este repositorio; solo existe la propuesta `S012_PROPUESTA_ADMIN_WEB.md`.
6. **Duplicación de esquema de BD** (`nouns` vs `palabras`/`sustantivos`) que puede causar inconsistencias entre el flujo local y Supabase.
7. **Sin autenticación real** (roles root/profesor/estudiante descritos en S012 aún no implementados en la app).

## Tareas pendientes identificadas

- Implementar el admin web Flask (S012) y conectar `SyncService` al puerto/URL correcto.
- Completar el vocabulario de niveles B1/B2.
- Añadir los archivos de sonido a `assets/sounds/`.
- Externalizar las credenciales de Supabase a una configuración segura (o variables de entorno).
- Corregir el flujo de arranque para no borrar datos importados (`clearAll()` condicional).
- Unificar el esquema de base de datos (`nouns` / `palabras`).
- Implementar autenticación y roles de usuario.
- Añadir tests de widgets y de juegos.
