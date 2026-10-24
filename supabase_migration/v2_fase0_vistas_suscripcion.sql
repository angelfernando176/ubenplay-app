-- LINGO — Fase 0 (adicional a la reestructuración ya ejecutada)
-- 1) id_suscripcion en usuarios · 2) vistas para Pantallas 1 y 2 · 3) índices
-- Ejecutar en Supabase → SQL Editor.

-- 1. id_suscripcion en usuarios
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS id_suscripcion VARCHAR(10) DEFAULT '0';

-- 2. Vistas
CREATE OR REPLACE VIEW v_tematicas_disponibles AS
SELECT
    ct.id_tematica,
    ct.nombre_tematica,
    COUNT(el.id_leccion) AS lecciones_disponibles
FROM cat_tematica ct
JOIN datos_batch        db ON db.id_tematica = ct.id_tematica
JOIN encabezado_leccion el ON el.id_datos_batch = db.id_datos_batch
WHERE el.estado = 1
GROUP BY ct.id_tematica, ct.nombre_tematica;

CREATE OR REPLACE VIEW v_lecciones AS
SELECT
    el.id_leccion,
    db.id_tematica,
    ct.nombre_tematica,
    db.id_categoria,
    el.fecha_inicio,
    el.cantidad_palabras,
    el.porcentaje_aciertos,
    el.tipo_leccion,
    el.id_suscripcion
FROM encabezado_leccion el
JOIN datos_batch db ON db.id_datos_batch = el.id_datos_batch
JOIN cat_tematica ct ON ct.id_tematica = db.id_tematica
WHERE el.estado = 1;

CREATE OR REPLACE VIEW v_progreso_leccion AS
SELECT
    id_leccion,
    id_usuario,
    COUNT(*) AS palabras_revisadas,
    COUNT(*) FILTER (WHERE aprendida) AS palabras_aprendidas
FROM leccion_palabras
WHERE estado = 1
GROUP BY id_leccion, id_usuario;

-- 3. Índices
CREATE INDEX IF NOT EXISTS idx_datos_batch_tematica          ON datos_batch(id_tematica);
CREATE INDEX IF NOT EXISTS idx_encabezado_leccion_batch      ON encabezado_leccion(id_datos_batch);
CREATE INDEX IF NOT EXISTS idx_encabezado_leccion_estado     ON encabezado_leccion(estado);
CREATE INDEX IF NOT EXISTS idx_leccion_palabras_leccion_user ON leccion_palabras(id_leccion, id_usuario);
