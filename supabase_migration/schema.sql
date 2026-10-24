-- ============================================================
-- LINGO - Schema para Supabase (PostgreSQL)
-- Ejecutar en SQL Editor de Supabase después de crear el proyecto
-- ============================================================

-- Tabla de vocabulario (flexible: sustantivos, verbos, adjetivos, conectores)
CREATE TABLE vocabulary (
    id          BIGSERIAL PRIMARY KEY,
    spanish     TEXT NOT NULL,
    german      TEXT NOT NULL,
    article     TEXT DEFAULT '',
    plural      TEXT DEFAULT '',
    cefr_level  TEXT NOT NULL DEFAULT 'A1' CHECK (cefr_level IN ('A1','A2','B1','B2')),
    category_id TEXT NOT NULL DEFAULT 'general',
    word_type   TEXT NOT NULL DEFAULT 'noun' CHECK (word_type IN ('noun','verb','adjective','connector')),
    image_code  TEXT,
    image_url   TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para búsquedas rápidas
CREATE INDEX idx_vocabulary_category ON vocabulary(category_id);
CREATE INDEX idx_vocabulary_level ON vocabulary(cefr_level);
CREATE INDEX idx_vocabulary_type ON vocabulary(word_type);
CREATE INDEX idx_vocabulary_spanish ON vocabulary(spanish);
CREATE INDEX idx_vocabulary_german ON vocabulary(german);

-- Tabla de usuarios del admin
CREATE TABLE admin_users (
    id            BIGSERIAL PRIMARY KEY,
    username      TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role          TEXT DEFAULT 'profesor' CHECK (role IN ('root','profesor')),
    name          TEXT,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de progreso de estudiantes (sincronización multi-dispositivo)
CREATE TABLE user_progress (
    id                BIGSERIAL PRIMARY KEY,
    user_id           TEXT NOT NULL,
    device_id         TEXT,
    total_xp          INTEGER DEFAULT 0,
    current_streak    INTEGER DEFAULT 0,
    longest_streak    INTEGER DEFAULT 0,
    lessons_completed INTEGER DEFAULT 0,
    total_attempts    INTEGER DEFAULT 0,
    total_correct     INTEGER DEFAULT 0,
    completed_lessons TEXT DEFAULT '[]', -- JSON array de IDs
    practiced_today   BOOLEAN DEFAULT FALSE,
    last_practice     DATE,
    updated_at        TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, device_id)
);

-- Tabla de registro de importaciones
CREATE TABLE import_logs (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT REFERENCES admin_users(id),
    filename      TEXT,
    word_type     TEXT DEFAULT 'noun',
    category_id   TEXT,
    total_rows    INTEGER DEFAULT 0,
    imported      INTEGER DEFAULT 0,
    duplicates    INTEGER DEFAULT 0,
    errors        INTEGER DEFAULT 0,
    error_details TEXT,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Datos iniciales: usuario admin
INSERT INTO admin_users (username, password_hash, role, name)
VALUES ('admin', 'scrypt:32768:8:1$PE3yXcHQJb7Ko3K8$86d8f9a6b...', 'root', 'Administrador')
ON CONFLICT (username) DO NOTHING;
-- NOTA: La contraseña se generará desde Python al migrar

-- Políticas de seguridad (Row Level Security)
ALTER TABLE vocabulary ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Política: lectura pública de vocabulario (para la app)
CREATE POLICY "Vocabulario visible para todos" ON vocabulary
    FOR SELECT USING (true);

-- Política: solo admin puede modificar vocabulario
CREATE POLICY "Solo admin modifica vocabulario" ON vocabulary
    FOR ALL USING (
        auth.role() = 'authenticated' 
        AND EXISTS (SELECT 1 FROM admin_users WHERE username = auth.email() AND role = 'root')
    );
