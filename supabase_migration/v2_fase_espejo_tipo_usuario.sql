-- LINGO — Espejo profesor: marcar el tipo de usuario en 'usuarios'
-- (la tabla 'users' de login es LOCAL del admin SQLite; no vive en Supabase)

ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS tipo_usuario VARCHAR(20) DEFAULT 'estudiante';
