# Lingo 🦉

Aplicación Flutter de aprendizaje de vocabulario en **alemán** para hispanohablantes, con una interfaz estilo Duolingo. Practica sustantivos y verbos organizados por niveles CEFR (A1–B2) y por temáticas, mediante juegos interactivos con sistema de XP, racha de días y seguimiento de progreso.

## Características

- Niveles **CEFR**: A1, A2, B1 y B2 (con desbloqueo progresivo).
- Categorías temáticas: familia, casa, comida, transporte, oficios, viajes, salud, tecnología, etc.
- **13 tipos de juego**: unión de palabras, caza del artículo, traduce, ahorcado, opciones, memoria, sopa de letras, ruleta de palabras, puente de cristal, ordena filas, ordenar palabras, crucigrama, etc.
- Sistema de **XP, racha (streak) y precisión**, persistido localmente.
- **Pronunciación** de palabras mediante texto a voz (TTS).
- **Módulo de administración** para importar sustantivos desde Excel y sincronizar con un admin web.
- Sincronización opcional con **Supabase** (backend remoto).

## Arquitectura general

La app sigue una arquitectura por capas en `lib/`:

- **`models/`** — modelos de dominio inmutables (palabra, lección, progreso, perfil).
- **`services/`** — acceso a datos y servicios externos (SQLite, Supabase, TTS, progreso).
- **`data/`** — datos de vocabulario hardcodeados (seed) y lógica de categorías/lecciones.
- **`screens/`** — pantallas de la UI (estado local con `setState`).
- **`games/`** — lógica de los juegos.
- **`widgets/`** y **`theme/`** — componentes reutilizables y tema central.

**Fuentes de datos en cascada:** Supabase (remoto) → SQLite local → datos en memoria. Al iniciar, la app intenta conectar con Supabase y, si no está disponible, usa SQLite (migrando los datos hardcodeados).

## Requisitos

- **Flutter** ≥ 3.44.0 (Dart SDK `^3.12.2`)
- Para Android: Android Studio / SDK y un emulador o dispositivo
- (Opcional) una cuenta de **Supabase** para el backend remoto
- (Opcional) un servidor **admin web Flask** para la sincronización (ver `S012_PROPUESTA_ADMIN_WEB.md`)

## Instalación

```bash
git clone <url-del-repositorio>
cd lingo_app
flutter pub get
```

## Configuración

### Supabase (opcional)

1. Crea un proyecto en [Supabase](https://supabase.com).
2. Copia la URL y la `anon/public key` desde *Dashboard → Settings → API*.
3. Reemplázalas en `lib/main.dart` (constantes `SUPABASE_URL` y `SUPABASE_ANON_KEY`).

> **Nota de seguridad:** las credenciales están hardcodeadas en `main.dart`. En producción conviene externalizarlas.

Si Supabase no está configurado, la app funciona igualmente con SQLite local y los datos incluidos.

### Admin web (opcional)

La app puede sincronizar con un admin web Flask (propuesta en `S012_PROPUESTA_ADMIN_WEB.md`). La URL del servidor se configura desde *Configuración → Administración → Servidor* dentro de la app (por defecto `http://192.168.100.14:9999`).

## Ejecución

```bash
flutter run
```

Para una plataforma concreta:

```bash
flutter run -d android      # Android
flutter run -d chrome       # Web
flutter run -d windows      # Windows (requiere toolchain)
```

## Testing

```bash
flutter test
```

Actualmente solo existe `test/widget_test.dart` (tests de modelos e integridad de datos). También puedes ejecutar el análisis estático:

```bash
flutter analyze
```

## Estructura del proyecto

```
lib/
├── main.dart                 # Arranque y selección de fuente de datos
├── data/lessons_data.dart    # Datos de vocabulario + categorías + migración
├── models/                   # Modelos de dominio
├── services/                 # SQLite, Supabase, TTS, progreso, sync
├── screens/                  # Pantallas
├── widgets/                  # Componentes reutilizables
├── games/                    # Lógica de los juegos
└── theme/app_theme.dart      # Tema (colores, tipografía Nunito)
assets/sounds/                # Efectos de sonido (aún sin incluir)
test/                         # Tests
android/ ios/ web/ linux/ windows/ macos/   # Proyectos por plataforma
```

## Deployment

Proyecto Flutter multi-plataforma. Para generar binarios:

```bash
flutter build apk            # Android (APK)
flutter build web            # Web
flutter build windows        # Windows
```

No hay configuración de Docker ni CI/CD incluida.
