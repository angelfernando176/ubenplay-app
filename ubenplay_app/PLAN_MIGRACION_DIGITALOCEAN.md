# Plan de migración — Supabase → DigitalOcean Managed PostgreSQL

> Documento de planificación. NO ejecutar sin revisión de Fernando.
> Fecha: 2026-09-12. Estado: propuesta.

## 1. Objetivo

Migrar la base de datos de Supabase a **DigitalOcean Managed PostgreSQL**, eliminando las
dependencias de servicios Supabase (PostgREST, Edge Functions), **sin perder funcionalidad** y
aprovechando la arquitectura ya existente (admin Flask como gateway).

**Restricción innegociable:** **SQLite NO se elimina.** Su propósito es **caché offline** de la
app. Se conserva el modelo "remoto = fuente de verdad, local = espejo/caché", cambiando Supabase
por DigitalOcean.

## 2. Inventario actual (verificado en código)

### 2.1 Qué se usa de Supabase
| Servicio | Uso | Detalle |
|---|---|---|
| **Postgres (BD)** | ✅ principal | 10 tablas (ver §2.2) |
| **PostgREST** | ✅ solo en la app | `supabase_service.dart` lee vocabulario directo |
| **REST** | ✅ solo en el admin | `pull_supabase.py`, `sync_oraciones.py`, sync de usuarios |
| **Edge Functions** | ✅ 1 función | `smart-api` (`autorizar-lopdp`) para el link LOPDP |
| **Auth** | ❌ | auth propia (Flask + código 6 dígitos) |
| **Storage** | ❌ | imágenes locales + emojis en BD |
| **Realtime** | ❌ | — |

### 2.2 Tablas (10 confirmadas en `models.py` + SQL de migración)
| Grupo | Tablas |
|---|---|
| Vocabulario | `palabras`, `sustantivos`, `verbos`, `adjetivos`, `cat_tematica` |
| Oraciones | `oraciones`, `palabra_oracion` |
| Usuarios | `usuarios`, `registro_usuarios`, `eventos_usuario` |

> La tabla `users` (login del admin) es **local SQLite** y NO se migra.
> ⚠️ El perfil del proyecto menciona "20 tablas"; en el código se confirman **10**. Verificar si
> existen tablas adicionales en Supabase no reflejadas en `models.py`.

### 2.3 Dependencia de la app: SOLO una ruta directa
La app (`lingo_app`) consulta Supabase directo **únicamente** en `supabase_service.dart`
(PostgREST). Todo lo demás (usuarios, registro, eventos) ya pasa por HTTP al Flask
(`SyncService` + `UsuarioService`). Esto acota mucho la migración.

## 3. Arquitectura objetivo

```
APK (Flutter) ──HTTP──► Flask admin (lingo_admin) ──SQLAlchemy──► DigitalOcean PostgreSQL
   │  (sin supabase_flutter)        │                                (fuente de verdad)
   │                                ├── vocabulario (/api/vocabulario)
   │                                ├── usuarios (/api/usuarios/*)
   │                                └── LOPDP (/api/lopdp/autorizar)  ← reemplaza a smart-api
   │
   └── SQLite local (caché offline, PERMANENTE — nunca se elimina)
```

- **DigitalOcean Managed PostgreSQL** = fuente de verdad (remoto).
- **SQLite** = caché offline (local, se conserva exactamente como hoy).
- **Flask** = único gateway de la app (vocabulario + usuarios + LOPDP).
- El admin opera sobre SQLite y sincroniza con DigitalOcean (igual que hoy con Supabase).
- Se eliminan: `supabase_flutter`, PostgREST, Edge Function, RLS. **No** se elimina SQLite.

## 4. Fases de ejecución

### Fase 0 — Provisionar y conectar
1. Crear **Managed PostgreSQL** en DigitalOcean (mismo datacenter que el servidor del admin).
2. Guardar cadena de conexión: `postgresql://user:pass@host:25060/db?sslmode=require`.
3. Probar conexión desde WSL.

### Fase 1 — Migrar esquema + datos
1. `pg_dump` desde Supabase (connection string del dashboard) con las 10 tablas.
2. `pg_restore` en DigitalOcean.
3. Verificar: conteo de filas por tabla idéntico; secuencias/IDs preservados.

### Fase 2 — Endpoint de vocabulario en Flask
El `supabase_service.dart` de la app consume el shape de PostgREST:
`select('*, sustantivos(plural), verbos(*), adjetivos(*)')` filtrado `id_categoria in [1,2,3]`
y `activo=true`. **El endpoint debe reproducir ese shape exacto** para no tocar
`VocabularyNoun.fromMap`:
1. Añadir `GET /api/vocabulario` en `routes.py` que devuelva `palabras` + `sustantivos` +
   `verbos` + `adjetivos` anidados (1:1), con `activo=true` y `id_categoria in (1,2,3)`.
2. Reutilizar/ampliar el `to_dict()` de `Palabra` (hoy `plural` está hardcodeado vacío; hay que
   hacer el join real).

### Fase 3 — Reemplazar la capa de datos de la app
1. `pubspec.yaml`: quitar `supabase_flutter`.
2. `main.dart`: quitar `SupabaseService.init` + `LessonsData.reloadFromSupabase()`; en su lugar
   `SyncService.fetchVocabulary()` (HTTP) → `LessonsData`.
3. `supabase_service.dart`: reescribir sobre `http` hacia `/api/vocabulario`, conservando los
   métodos (`fetchAllGrouped`, `fetchByCategory`, `fetchByLevel`, `getCategoryCounts`,
   `testConnection`) para no tocar el resto de la app.
4. **Mantener el fallback SQLite** (caché offline), pero **eliminar `clearAll()`** del arranque:
   la caché se debe LEER, no borrar (hoy `clearAll()+migrateToDatabase()` borra la caché en cada
   arranque frío — bug de pérdida de datos, ver PROJECT_STATUS).

### Fase 4 — Reemplazar la Edge Function por ruta Flask
1. Nueva ruta `GET /api/lopdp/autorizar?id=<id_usuario>&token=<token>` en `routes_usuarios_api.py`:
   valida `Usuario.token_autorizacion` y marca `lopdp=1`.
2. `email_service.py`: cambiar `FUNC_AUTORIZAR` (URL de Supabase Functions) por la URL del Flask.
3. Borrar `supabase_functions/` (deja de usarse).

### Fase 5 — Reapuntar el sync a DigitalOcean (SQLite se mantiene como caché)
El admin **sigue operando sobre SQLite** (caché local) y sincroniza con DigitalOcean (remoto),
igual que hoy con Supabase. Solo cambia el destino remoto:
1. Adaptar `pull_supabase.py` → pull desde DigitalOcean vía SQLAlchemy (en vez de REST),
   **conservando** la reconciliación por llave natural `(es+de+tema)` y el conteo multiset.
2. Adaptar `sync_oraciones.py` y el push del import al mismo destino (DigitalOcean vía SQLAlchemy).
3. Resolver diferencias de tipos/DDL **solo en el lado remoto** (Postgres); el esquema SQLite
   local NO cambia.
4. RLS: eliminarla en DigitalOcean (la app no conecta directo; el admin usa credenciales).

## 5. Toques de código (resumen)

| Archivo | Cambio |
|---|---|
| `lingo_admin/routes.py` | añadir `/api/vocabulario` (join completo) |
| `lingo_admin/routes_usuarios_api.py` | añadir `/api/lopdp/autorizar` |
| `lingo_admin/email_service.py` | URL LOPDP → Flask |
| `lingo_admin/pull_supabase.py` | destino → DigitalOcean (SQLAlchemy), llave natural intacta |
| `lingo_admin/sync_oraciones.py` | destino → DigitalOcean (SQLAlchemy) |
| `lingo_app/lib/services/supabase_service.dart` | PostgREST → HTTP |
| `lingo_app/lib/main.dart` | quitar init Supabase + reloadFromSupabase; quitar `clearAll()` del fallback |
| `lingo_app/pubspec.yaml` | quitar `supabase_flutter` |

## 6. Verificación por fase

- **Fase 1**: `SELECT count(*)` por tabla idéntico a Supabase; app de prueba lee sin cambios.
- **Fase 2**: `curl /api/vocabulario` devuelve el shape esperado (comparar con el JSON actual de
  PostgREST).
- **Fase 3**: `flutter analyze` 0 errores + `flutter test` + `flutter build apk`; la app carga
  vocabulario online y usa la caché SQLite offline (sin borrarla).
- **Fase 4**: click en el link LOPDP del correo → `lopdp` pasa a 1.
- **Fase 5**: regresión completa del admin (todas las rutas del `url_map`, ver skill
  `lingo-flutter-dev` → "Pruebas de regresión").

## 7. Riesgos y mitigación

1. **Mantener SQLite como caché**: la Fase 3 debe quitar `clearAll()` del arranque o la caché se
   borra en cada arranque frío. Mitigación: verificar que el fallback offline LEER la caché sin
   resetear.
2. **Formato del endpoint** de vocabulario: si no reproduce exactamente el shape de PostgREST,
   `VocabularyNoun.fromMap` falla. Mitigación: snapshot del JSON real de Supabase como fixture de
   prueba.
3. **Pérdida de datos en la migración**: hacer `pg_dump` y verificar conteos antes de apagar
   Supabase. NO borrar el proyecto Supabase hasta que DigitalOcean esté validado en producción.
4. **Credenciales en el APK**: la opción recomendada (todo vía Flask) evita meter credenciales de
   BD en la app — no usar driver Postgres directo en el APK.

## 8. Decisiones

- ✅ **RESUELTO:** SQLite NO se elimina — es caché offline permanente.
- ⏳ **Pendiente:** confirmar si existen tablas adicionales en Supabase (el perfil dice 20, el
  código confirma 10).

---

## 9. Herramientas de software sugeridas (equivalencia y dimensionamiento)

> Propósito: dimensionar **costos** y **dificultad técnica** de reemplazar cada funcionalidad de
> Supabase con DigitalOcean (o self-hosted). Precios **aproximados** (verificar en
> digitalocean.com/pricing).

### 9.1 En uso hoy — reemplazo obligatorio

| Funcionalidad Supabase | Uso | Herramienta sugerida | Coste aprox. | Dificultad |
|---|---|---|---|---|
| **PostgreSQL** (BD) | ✅ | **DigitalOcean Managed Databases → PostgreSQL** (alt.: Droplet + Postgres self-hosted) | $15/mes (básico) · $6–12/mes (Droplet) | Baja |
| **PostgREST** (API REST) | ✅ solo app | **Flask existente** (`lingo_admin`): añadir `/api/vocabulario` | $0 (ya existe) | Baja (solo código) |
| **Edge Functions** | ✅ 1 fn (`smart-api`) | **Ruta Flask** (`/api/lopdp/autorizar`) | $0 (ya existe) | Baja (solo código) |

### 9.2 No usadas hoy — opcionales si se requieren a futuro

| Funcionalidad Supabase | Herramienta sugerida | Coste aprox. | Dificultad |
|---|---|---|---|
| Auth | Mantener auth propia (Flask); gestionada: Auth0 / Clerk / Firebase Auth (tier gratuito) | $0 | — |
| Storage (archivos/imágenes) | DigitalOcean **Spaces** (S3) · Cloudflare R2 | $5/mes | Baja |
| Realtime (websockets) | Pusher / Ably (tier gratuito) · Socket.io self-hosted | $0–5/mes | Media |
| Table Editor (GUI de datos) | **Adminer** / **pgAdmin** / Beekeeper / DBeaver (gratis) | $0 | Baja |
| Backups | Incluido en Managed DB (o cron `pg_dump`) | $0 | Baja |
| Connection pooling (PgBouncer) | Incluido en Managed DB | $0 | Baja |
| Logs / métricas | Incluido en Managed DB | $0 | Baja |

### 9.3 Dimensionamiento (resumen)

- **Coste mínimo para replicar lo que usas hoy: ≈ $15/mes** (Managed PostgreSQL), o **$6–12/mes**
  con un Droplet + Postgres self-hosted (más control, algo más de mantenimiento).
- **Cero herramientas nuevas** para PostgREST y Edge Functions: el admin Flask ya cubre ambos.
- **Dificultad técnica global: BAJA-MEDIA.** La dificultad **no está en la infraestructura** (todo
  es "conectar"), sino en el **código**: reescribir la capa de datos de la app (Fase 3) y
  reapuntar el sync (Fase 5).

### 9.4 Comparativa de costes

| | Supabase (actual) | DigitalOcean (propuesto) |
|---|---|---|
| Plan base | Free o Pro $25/mes *(por verificar)* | Managed PostgreSQL $15/mes |
| API REST | PostgREST (incluido) | Flask (ya existe, $0) |
| Edge Functions | incluido | Flask (ya existe, $0) |
| Auth / Storage / Realtime | incluido (no usado) | solo si se necesitan (§9.2) |
