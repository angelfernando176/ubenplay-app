-- LINGO — Fase 4: v_lecciones ahora deriva el nivel CEFR (id_nivel) de sus palabras.
-- Ejecutar en Supabase → SQL Editor.

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
    el.id_suscripcion,
    MIN(p.id_nivel) AS id_nivel
FROM encabezado_leccion el
JOIN datos_batch db ON db.id_datos_batch = el.id_datos_batch
JOIN cat_tematica ct ON ct.id_tematica = db.id_tematica
LEFT JOIN leccion_detalle ld ON ld.id_leccion = el.id_leccion
LEFT JOIN palabras p ON p.id_palabra = ld.id_palabra
WHERE el.estado = 1
GROUP BY el.id_leccion, db.id_tematica, ct.nombre_tematica, db.id_categoria,
         el.fecha_inicio, el.cantidad_palabras, el.porcentaje_aciertos,
         el.tipo_leccion, el.id_suscripcion;
