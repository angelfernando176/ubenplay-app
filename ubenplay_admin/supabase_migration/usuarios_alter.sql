-- ============================================================
-- Lingo — ALTER tabla usuarios: columna token_autorizacion
-- Ejecutar en Supabase SQL Editor (después del script principal)
-- ============================================================
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS token_autorizacion VARCHAR(100);
