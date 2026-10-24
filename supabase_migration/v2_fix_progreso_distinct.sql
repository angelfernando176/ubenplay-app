-- LINGO — Fix v_progreso_leccion: contar palabras DISTINTAS (no filas, que duplican por juego).
-- Ejecutar en Supabase → SQL Editor.

CREATE OR REPLACE VIEW v_progreso_leccion AS
SELECT
    id_leccion,
    id_usuario,
    COUNT(DISTINCT id_palabra) AS palabras_revisadas,
    COUNT(DISTINCT id_palabra) FILTER (WHERE aprendida) AS palabras_aprendidas
FROM leccion_palabras
WHERE estado = 1
GROUP BY id_leccion, id_usuario;
