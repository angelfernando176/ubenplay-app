# CLAUDE.md — Lingo

Aplicación móvil Flutter de aprendizaje de vocabulario en **alemán** para hispanohablantes (estilo Duolingo). Sustantivos y verbos organizados por niveles CEFR (A1–B2) y temáticas, con juegos, XP, racha y seguimiento de progreso.

## Directriz de persistencia (PERMANENTE — no violar)

TODA interacción del usuario se registra en la base de datos. **NO** guardar en SharedPreferences ni en archivos. Flujo: acción del usuario → INSERT/UPDATE en **SQLite local del dispositivo** → sincronizar a **Supabase** (fuente de verdad). El SQLite del móvil actúa como caché/cola offline; cada write local marca `dirty=1` para la cola de sync.

Esto reemplaza el sistema viejo de `ProgressService` (SharedPreferences `user_progress`) y las claves `progress_*`, `total_*`, `errors_*`, `last_*`, `ultimas_lecciones`. Cualquier uso NUEVO de SharedPreferences debe migrarse a tablas SQLite locales con flag `dirty` + cola de sync.

## Arquitectura (capas en lib/)

- `main.dart` — arranque + selección de fuente de datos (Supabase → SQLite → memoria hardcodeada).
- `models/` — modelos inmutables (`const`, `fromJson`/`fromMap`/`toJson`).
- `services/` — servicios **estáticos**: `database_service.dart` (SQLite local), `supabase_service.dart` (remoto), `progress_service.dart` (progreso), `usuario_service.dart` (auth/avance vía admin), `lecciones_service.dart` (lecciones activadas).
- `screens/` — UI con `setState` (sin Provider/Bloc/Riverpod).
- `games/` — lógica de juegos.

## Base de datos SQLite local (`lingo_nouns.db`, en `database_service.dart`)

Tablas actuales (onCreate, version 1): `nouns`, `palabras`, `sustantivos`. El flujo local usa `nouns`; Supabase usa `palabras`/`sustantivos`.

## Supabase (fuente de verdad)

URL `https://jtrrqbnxhxxqjcpizjuy.supabase.co`. La app consulta las vistas `v_lecciones` (solo trae `estado=1`) y `v_progreso_leccion` (progreso por lección/usuario). El avance por juego se envía vía admin web Flask (`POST http://192.168.100.14:9999/api/leccion/avance`), que escribe `leccion_palabras` y sincroniza a Supabase. **No tocar** ese flujo de avance por juego.

## Convenciones

- Comentarios y strings de UI en **español**; identificadores (clases/métodos/variables) en **inglés**.
- Archivos `snake_case`, clases `PascalCase`, métodos/variables `camelCase`.
- Servicios con métodos `static`.
- Colores centralizados en `AppTheme` (no colores "a pelo").

## Build / test

Flutter está en `/home/angel/flutter/bin/flutter` (no está en PATH por defecto). Exportar antes de usar:

```
export PATH="$PATH:/home/angel/flutter/bin"
```

- `flutter analyze` — debe dar 0 errores.
- `flutter test` — actualmente 13/13 pasan (test/widget_test.dart).

## Estado del repo

Hay cambios **sin commitear** (fase 4/5: lecciones activadas, avance por juego, espejo de usuario). Trabajar encima de ellos; **no hacer `git commit` ni `git push`** salvo que se pida explícitamente.
