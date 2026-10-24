# Estado del proyecto Lingo

> Archivo dinámico. Actualizado con `project-handoff`. Estado de tareas NO va a memoria (session_search si hace falta).

## Completado recientemente

- **Feature "Activar lecciones" — Fases 0-5 (Sep 2026):** flujo completo de carga batch → activación → repaso en la app.
  - **F0** Esquema/vistas: `datos_batch`, `encabezado_leccion`, `leccion_detalle`, `leccion_palabras`, `estadistica_palabra`; vistas `v_tematicas_disponibles`, `v_lecciones` (con `id_nivel` CEFR derivado), `v_progreso_leccion`; `usuarios.id_suscripcion` y `tipo_usuario`; `users.correo`/`id_usuario` (espejo profesor); `juegos` con 13 juegos canónicos.
  - **F1** Import escribe metadatos en `datos_batch` (ya no crea lecciones).
  - **F2** Pantalla "Activar lecciones" (`/activar-lecciones`).
  - **F3** Acciones Activar/Revisar/Inactivar/Borrar (`activacion.py`, `game_config.py` con distribución palabra→juego por slots).
  - **F4** App: bienvenida "nuevos retos"/"cambios", temáticas por CEFR, lecciones con 3 estados, ejecución alineada a la distribución del profesor (`gameTypeFromIdJuego`, `fetchLeccionJuegos`, `LessonScreen.customGameSequence/customWords`).
  - **F5** Pruebas: `flutter analyze` 0 errores, `flutter test` 13/13, admin rutas 200.
- **Correcciones post-diagnóstico (2 críticos + 2 medios):**
  - Registro de avance en `leccion_palabras` (`POST /api/leccion/avance` + `registrar_avance()` + `LessonScreen._enviarAvance()` por juego).
  - `id_usuario` → `current_user.id_usuario` (espejo, no `users.id`).
  - `v_progreso_leccion` → `COUNT(DISTINCT id_palabra)`.
  - `detectarNovedades` detecta desactivaciones.
- **Revisar** filtra `/words` por temática+tipo de la carga. **Dedup §4.2** limpia datos de lección al re-importar palabras con avance.
- **APK debug** generado y copiado a `C:\Users\angel\Desktop\Lingo.apk`.

## Migración de persistencia — DISEÑO CERRADO (Oct 2026)

Directriz raíz: **toda interacción → SQLite local → sincronizar a Supabase** (nada de SharedPreferences/archivos).

Decisiones (ver skill `lingo-persistencia`):
- **Nomenclatura sync unificada** en toda tabla que nace en SQLite móvil: `sincronizado` (0/1) + `fecha_sync` (ISO). Solo local, no en Supabase.
- **Opción A:** el avance por juego (`leccion_palabras`) NACE en SQLite móvil y sube a Supabase por cola (REST directo), NO vía admin.
- **`progreso_usuario`**: tabla materializada de agregados (PK id_usuario), llenada por UPSERT al terminar cada juego.
- **`leccion_completada`**: DESCARTADA → vista normal `v_leccion_completa` (opción B).
- **`estado_leccion`**: se sincroniza; referencia a `leccion_palabras` (avance), no a `leccion_detalle` (plantilla).
- **`sesion_usuario`**: DESCARTADA (caché de `usuarios` + `eventos_usuario`).
- **`ajuste_ui`**: local pura, valor TEXT, incluye `tipo_dispositivo`/`resolucion` (opción A).
- **Nivel 5 `Licenciamiento3`** agregado (5 niveles de acceso).

DDL escritos y aplicados:
- Supabase `v3_persistencia_estudiante.sql` (Escritorio) — **EJECUTADO y verificado** (crea `progreso_usuario`, `estado_leccion`, `v_leccion_completa`).
- SQLite `lib/services/database_schema_v3.sql` — escrito; pendiente aplicar en `onUpgrade`.

## Pendiente (acción de Fernando)

- ~~Ejecutar `v2_fix_progreso_distinct.sql`~~ → **hecho**.
- ~~Ejecutar `v3_persistencia_estudiante.sql`~~ → **hecho** (crea progreso_usuario, estado_leccion, v_leccion_completa).

## Siguiente tarea recomendada — Implementación de persistencia (FASES 1-6 HECHAS)

Plan de implementación (fases, verificar analyze+test por fase):

1. **`DatabaseService`** ✅ — version 1→2 con `onUpgrade`; crea `progreso_usuario`, `leccion_palabras`, `estado_leccion`, `eventos_usuario`, `registro_usuarios`, `ajuste_ui`.
2. **Repositorio** ✅ — `progreso_repository.dart` con `registrarAvance`, `completarLeccion`, `guardarEstadoLeccion`, `registrarEvento`, `ajuste_ui`, `pending()`/`marcarSincronizado`.
3. **`ProgressService`** ✅ — `loadProgress`/`saveProgress`/`completeLesson`/`resetProgress` a SQLite (firmas públicas compatibles, nuevo param `idUsuario`).
4. **`LessonScreen`** ✅ — `_enviarAvance`→INSERT local; `_saveProgress`/`_checkResume`/`_finalizeLesson` usan `estado_leccion`/`progreso_usuario`.
5. **`evento_usuario_service.dart`** ✅ — de SharedPreferences a SQLite `eventos_usuario`.
6. **Cola de sync** ✅ — `sync_progreso_service.dart` sube `sincronizado=0` a Supabase (upsert/insert) y marca `sincronizado=1`+`fecha_sync`.
7. **Tests** ✅ — `progreso_repository_test.dart` (ffi in-memory) + 13 existentes = **14/14**, `flutter analyze` 0 errores.

### PENDIENTE (integración final)
- **Disparar la cola** `SyncProgresoService.sync()` al abrir la app / al terminar lección (no está cableado aún en `main.dart`/`auth_gate.dart`).
- **`id_usuario` real** en `_enviarAvance`/`_finalizeLesson`: hoy `category_screen` pasa `idLeccion`/`idUsuario`; confirmar que `idUsuario` fluye desde la sesión (`UsuarioService.loadSession()`).
- **Verificar el avance contra Supabase**: probar en APK que al jugar crea filas `leccion_palabras` (sincronizado=0) y luego la cola las sube.
- **`UsuarioService.registrarAvance`** (POST /api/leccion/avance) quedó sin uso en la app; el flujo ahora es local→cola. Evaluar si se mantiene como respaldo o se retira.

## Pendientes menores previos (no bloquear)

- Migrar sync del import a llave natural `(es+de+tema)`; 3 duplicados en Supabase; plantillas Excel adjetivos/conectores; Crucigrama pausado; personaje Rive pausado.

## Decisiones recientes

- Modelo de lecciones: `usuarios` = universo de personas; `users` = credenciales de acceso (espejo vía `users.id_usuario`). `id_juego` usa numeración canónica de Fernando 1-13 (6=Opciones inactivo).
- `id_suscripcion` aún hardcodeado `'0'` (dedup completo `(es+de+tema+id_suscripcion)` pendiente de suscripción real).
- Subproyecto `lingo_ui_kit` PAUSADO. Supabase = fuente de verdad; SQLite = espejo/caché offline (nunca se elimina).
- Regla de Fernando: archivos `.sql` y `.apk` van SIEMPRE al Escritorio, no a rutas arbitrarias.