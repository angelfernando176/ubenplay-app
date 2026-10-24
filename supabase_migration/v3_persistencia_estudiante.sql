-- ============================================================
-- LINGO — Persistencia del estudiante (DDL Supabase/PostgreSQL)
-- Crea tablas de progreso/estado + vista + ajuste nivel 5.
-- Ejecutar en Supabase → SQL Editor.
-- Ídem: no es destructivo (solo CREATE IF NOT EXISTS + ALTER).
-- ============================================================

-- ═══ 1. progreso_usuario (tabla materializada de agregados) ═══
-- Una fila por usuario. Se llena con UPSERT al terminar cada juego.
CREATE TABLE IF NOT EXISTS progreso_usuario (
    id_usuario           BIGINT PRIMARY KEY REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    total_xp             INTEGER NOT NULL DEFAULT 0,
    total_correct        INTEGER NOT NULL DEFAULT 0,
    total_attempts       INTEGER NOT NULL DEFAULT 0,
    lessons_completed    INTEGER NOT NULL DEFAULT 0,
    current_streak       INTEGER NOT NULL DEFAULT 0,
    longest_streak       INTEGER NOT NULL DEFAULT 0,
    last_practice_date   DATE,
    ultima_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══ 2. estado_leccion (avance parcial de una lección, se sincroniza) ═══
-- Referencia el AVANCE del estudiante (leccion_palabras), no la plantilla (leccion_detalle).
CREATE TABLE IF NOT EXISTS estado_leccion (
    id_estado_leccion    BIGSERIAL PRIMARY KEY,
    id_leccion           BIGINT NOT NULL REFERENCES encabezado_leccion(id_leccion) ON DELETE CASCADE,
    id_usuario           BIGINT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_leccion_palabra   BIGINT REFERENCES leccion_palabras(id_leccion_palabra) ON DELETE SET NULL,
    id_juego             SMALLINT REFERENCES juegos(id_juego),
    sequence_hash        VARCHAR(255),
    fecha_actualizacion  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_estado_leccion_user ON estado_leccion(id_usuario);
CREATE INDEX IF NOT EXISTS idx_estado_leccion_leccion ON estado_leccion(id_leccion);

-- ═══ 3. v_leccion_completa (resumen por lección, vista NORMAL) ═══
-- Deriva el resumen del detalle por palabra (opción B). No materializa.
CREATE OR REPLACE VIEW v_leccion_completa AS
SELECT
    id_leccion,
    id_usuario,
    COUNT(DISTINCT id_palabra)                         AS palabras_revisadas,
    COUNT(DISTINCT id_palabra) FILTER (WHERE aprendida) AS palabras_aprendidas,
    COUNT(*) FILTER (WHERE respuesta = 1)              AS aciertos,
    COUNT(*) FILTER (WHERE respuesta IS NOT NULL)      AS intentos,
    MAX(fecha_registro)                                AS ultima_revision
FROM leccion_palabras
WHERE estado = 1
GROUP BY id_leccion, id_usuario;

-- ═══ 4. Nivel de acceso 5 (Licenciamiento3) ═══
-- El nivel 5 es nuevo; se refleja en la tabla registro_usuarios (tipo_cambio '4->5').
-- (nivel_acceso es INTEGER sin check en Supabase; no requiere ALTER de tipo.
--  Solo aseguramos que el rango comentado/dict lo contemple en el admin.)
COMMENT ON COLUMN usuarios.nivel_acceso IS '1 Registrado, 2 Funcional, 3 Licenciamiento1, 4 Licenciamiento2, 5 Licenciamiento3';
COMMENT ON COLUMN registro_usuarios.tipo_cambio IS '1->2, 2->3, 3->4, 4->5';

-- ═══ 5. RLS permisivo (patrón del resto del schema) ═══
ALTER TABLE progreso_usuario ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all progreso_usuario" ON progreso_usuario FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE estado_leccion ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all estado_leccion" ON estado_leccion FOR ALL USING (true) WITH CHECK (true);