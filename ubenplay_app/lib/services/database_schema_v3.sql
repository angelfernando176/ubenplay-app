-- ============================================================
-- UBENPLAY — Persistencia del estudiante (DDL SQLite local, app móvil)
-- Tablas que NACEN en SQLite y suben a Supabase, más ajuste_ui local.
-- Incluye columnas de sync: sincronizado + fecha_sync (solo en SQLite).
-- Aplicar vía DatabaseService.onUpgrade (version 1 → 2), NO destructivo.
-- ============================================================

-- ═══ 1. progreso_usuario (materializada; se sincroniza) ═══
CREATE TABLE IF NOT EXISTS progreso_usuario (
    id_usuario           INTEGER PRIMARY KEY,
    total_xp             INTEGER NOT NULL DEFAULT 0,
    total_correct        INTEGER NOT NULL DEFAULT 0,
    total_attempts       INTEGER NOT NULL DEFAULT 0,
    lessons_completed    INTEGER NOT NULL DEFAULT 0,
    current_streak       INTEGER NOT NULL DEFAULT 0,
    longest_streak       INTEGER NOT NULL DEFAULT 0,
    last_practice_date   TEXT,
    ultima_actualizacion TEXT NOT NULL DEFAULT (datetime('now')),
    sincronizado         INTEGER NOT NULL DEFAULT 0,
    fecha_sync           TEXT
);

-- ═══ 2. leccion_palabras (avance del estudiante; nace aquí y sube) ═══
-- Espejo de la tabla homónima de Supabase + columnas de sync.
CREATE TABLE IF NOT EXISTS leccion_palabras (
    id_leccion_palabra INTEGER PRIMARY KEY AUTOINCREMENT,
    id_leccion         INTEGER NOT NULL,
    id_palabra         INTEGER NOT NULL,
    id_detalle         INTEGER,
    id_juego           INTEGER,
    veces_revisada     INTEGER NOT NULL DEFAULT 0,
    aprendida          INTEGER NOT NULL DEFAULT 0,      -- 0/1 (mismo nombre que Supabase)
    respuesta          INTEGER,
    id_usuario         INTEGER NOT NULL,
    fecha_registro     TEXT NOT NULL DEFAULT (datetime('now')),
    estado             INTEGER NOT NULL DEFAULT 1,
    id_datos_batch     INTEGER,
    sincronizado       INTEGER NOT NULL DEFAULT 0,
    fecha_sync         TEXT
);
CREATE INDEX IF NOT EXISTS idx_lp_leccion_user ON leccion_palabras(id_leccion, id_usuario);
CREATE INDEX IF NOT EXISTS idx_lp_user_fecha ON leccion_palabras(id_usuario, fecha_registro);

-- ═══ 3. estado_leccion (avance parcial; se sincroniza) ═══
CREATE TABLE IF NOT EXISTS estado_leccion (
    id_estado_leccion    INTEGER PRIMARY KEY AUTOINCREMENT,
    id_leccion           INTEGER NOT NULL,
    id_usuario           INTEGER NOT NULL,
    id_leccion_palabra   INTEGER,
    id_juego             INTEGER,
    sequence_hash        TEXT,
    fecha_actualizacion  TEXT NOT NULL DEFAULT (datetime('now')),
    sincronizado         INTEGER NOT NULL DEFAULT 0,
    fecha_sync           TEXT
);
CREATE INDEX IF NOT EXISTS idx_estado_leccion_user ON estado_leccion(id_usuario);
CREATE INDEX IF NOT EXISTS idx_estado_leccion_leccion ON estado_leccion(id_leccion);

-- ═══ 4. eventos_usuario (ya existe lógica; asegura esquema local + sync) ═══
CREATE TABLE IF NOT EXISTS eventos_usuario (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario   INTEGER NOT NULL,
    tipo_evento  TEXT NOT NULL,          -- login, logout, apertura
    fecha_hora   TEXT NOT NULL DEFAULT (datetime('now')),
    dispositivo  TEXT,
    sincronizado INTEGER NOT NULL DEFAULT 0,
    fecha_sync   TEXT
);
CREATE INDEX IF NOT EXISTS idx_eventos_user ON eventos_usuario(id_usuario);

-- ═══ 5. registro_usuarios (historial de cambio de nivel; código encriptado) ═══
CREATE TABLE IF NOT EXISTS registro_usuarios (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha_hora     TEXT NOT NULL DEFAULT (datetime('now')),
    id_usuario     INTEGER NOT NULL,
    codigo_enviado TEXT,                 -- hash encriptado del código de 6 dígitos
    tipo_cambio    TEXT,                 -- '1->2', '2->3', '3->4', '4->5'
    sincronizado   INTEGER NOT NULL DEFAULT 0,
    fecha_sync     TEXT
);
CREATE INDEX IF NOT EXISTS idx_registro_user ON registro_usuarios(id_usuario);

-- ═══ 6. ajuste_ui (preferencias UI + contexto dispositivo; LOCAL, no sincroniza) ═══
CREATE TABLE IF NOT EXISTS ajuste_ui (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    clave      TEXT UNIQUE NOT NULL,
    valor      TEXT,                     -- texto; se interpreta según clave
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);