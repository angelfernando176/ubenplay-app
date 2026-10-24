-- ============================================================
-- LINGO — Reestructuración de tablas de usuarios/lecciones
-- Objetivo: ELIMINAR perfil_usuario (deja solo usuarios) y
--   redefinir encabezado_leccion / leccion_detalle /
--   leccion_palabras / estadistica_palabra para depender de
--   usuarios (BIGINT) en lugar de perfil_usuario (UUID).
--   Además crea la nueva tabla datos_batch.
--
-- Ejecutar en Supabase → SQL Editor.
-- ⚠️ DESTRUCTIVO: DROP de perfil_usuario y recreación de las
--    tablas de lecciones (pierde datos previos de esas tablas,
--    que hoy están vacías / no usadas por la app).
-- ============================================================

-- ══════════════════════════════════════════════════════════
-- 1. DROP en orden de dependencia inversa (CASCADE por si hay
--    referencias no conocidas en el Supabase vivo).
-- ══════════════════════════════════════════════════════════
DROP TABLE IF EXISTS leccion_palabras  CASCADE;
DROP TABLE IF EXISTS leccion_detalle   CASCADE;
DROP TABLE IF EXISTS estadistica_palabra CASCADE;
DROP TABLE IF EXISTS encabezado_leccion CASCADE;
DROP TABLE IF EXISTS perfil_usuario    CASCADE;

-- ══════════════════════════════════════════════════════════
-- 2. NUEVA: datos_batch  (trazabilidad de cargas masivas)
-- ══════════════════════════════════════════════════════════
CREATE TABLE datos_batch (
    id_datos_batch   BIGSERIAL PRIMARY KEY,          -- secuencial
    fecha_carga      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    numero_palabras  INTEGER,
    id_tematica      SMALLINT REFERENCES cat_tematica(id_tematica),
    id_categoria     SMALLINT REFERENCES cat_palabra(id_categoria),
    id_usuario       BIGINT   REFERENCES usuarios(id_usuario),
    observaciones    TEXT,
    nombre_archivo   TEXT,
    estado           SMALLINT DEFAULT 0               -- 0=cargada/procesada, 1=disponible, 2=inactiva
);

-- ══════════════════════════════════════════════════════════
-- 3. encabezado_leccion (redefinida)
--    Eliminados: fecha_fin, nivel
-- ══════════════════════════════════════════════════════════
CREATE TABLE encabezado_leccion (
    id_leccion           BIGSERIAL PRIMARY KEY,
    id_usuario           BIGINT REFERENCES usuarios(id_usuario),
    fecha_inicio         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    cantidad_palabras    INTEGER NOT NULL DEFAULT 10,
    porcentaje_aciertos  INTEGER,                     -- por defecto = cantidad_palabras (trigger)
    estado               SMALLINT DEFAULT 1,          -- 1=activa, 0=inactiva
    tipo_leccion         SMALLINT DEFAULT 1,          -- 1=pública, 2=privada
    id_suscripcion       VARCHAR(10) DEFAULT '0',     -- '0' = sin suscripción / acceso general
    icono                VARCHAR(100),
    id_datos_batch       BIGINT REFERENCES datos_batch(id_datos_batch)
);

-- porcentaje_aciertos por defecto = cantidad_palabras
CREATE OR REPLACE FUNCTION fn_encabezado_default_aciertos() RETURNS trigger AS $$
BEGIN
    IF NEW.porcentaje_aciertos IS NULL THEN
        NEW.porcentaje_aciertos := NEW.cantidad_palabras;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_encabezado_default_aciertos
    BEFORE INSERT ON encabezado_leccion
    FOR EACH ROW EXECUTE FUNCTION fn_encabezado_default_aciertos();

-- ══════════════════════════════════════════════════════════
-- 4. leccion_detalle (redefinida — elementos que componen la lección)
--    Eliminados: respuesta_correcta, tiempo_respuesta, detalle_error
--    Se conserva: fecha_registro
-- ══════════════════════════════════════════════════════════
CREATE TABLE leccion_detalle (
    id_detalle      BIGSERIAL PRIMARY KEY,
    id_leccion      BIGINT NOT NULL REFERENCES encabezado_leccion(id_leccion),
    id_palabra      BIGINT NOT NULL REFERENCES palabras(id_palabra),
    id_juego        SMALLINT REFERENCES juegos(id_juego),
    estado          SMALLINT DEFAULT 1,               -- 1=activo, 0=inactivo
    fecha_registro  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    id_datos_batch  BIGINT REFERENCES datos_batch(id_datos_batch)
);

-- ══════════════════════════════════════════════════════════
-- 5. leccion_palabras (redefinida — seguimiento de ejecución/repaso)
--    Eliminado: orden_presentacion
-- ══════════════════════════════════════════════════════════
CREATE TABLE leccion_palabras (
    id_leccion_palabra  BIGSERIAL PRIMARY KEY,
    id_leccion          BIGINT NOT NULL REFERENCES encabezado_leccion(id_leccion),
    id_palabra          BIGINT NOT NULL REFERENCES palabras(id_palabra),
    veces_revisada      INTEGER DEFAULT 0,
    aprendida           BOOLEAN DEFAULT FALSE,
    id_detalle          BIGINT REFERENCES leccion_detalle(id_detalle),
    id_juego            SMALLINT REFERENCES juegos(id_juego),
    respuesta           SMALLINT,                     -- 0=incorrecta, 1=correcta
    id_usuario          BIGINT REFERENCES usuarios(id_usuario),
    fecha_registro      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estado              SMALLINT DEFAULT 1,           -- 1=activo, 0=inactivo
    id_datos_batch      BIGINT REFERENCES datos_batch(id_datos_batch)
);

-- ══════════════════════════════════════════════════════════
-- 6. estadistica_palabra
--    NOTA: Fernando solo pidió cambiar su dependencia a usuarios.
--    Se conserva su estructura; únicamente cambia
--    id_usuario UUID → BIGINT (FK a usuarios).
-- ══════════════════════════════════════════════════════════
CREATE TABLE estadistica_palabra (
    id_estadistica    BIGSERIAL PRIMARY KEY,
    id_usuario        BIGINT NOT NULL REFERENCES usuarios(id_usuario),
    id_palabra        BIGINT NOT NULL REFERENCES palabras(id_palabra),
    veces_presentada  INTEGER DEFAULT 0,
    aciertos          INTEGER DEFAULT 0,
    errores           INTEGER DEFAULT 0,
    ultima_revision   TIMESTAMPTZ,
    nivel_dominio     SMALLINT DEFAULT 1 REFERENCES cat_nivel_dominio(id_nivel_dominio),
    racha_aciertos    SMALLINT DEFAULT 0,
    racha_errores     SMALLINT DEFAULT 0
);

-- ══════════════════════════════════════════════════════════
-- 7. RLS permisivo (mismo patrón que el resto del schema)
-- ══════════════════════════════════════════════════════════
ALTER TABLE datos_batch ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON datos_batch FOR SELECT USING (true);
CREATE POLICY "Insert público"  ON datos_batch FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público"  ON datos_batch FOR UPDATE USING (true);

ALTER TABLE encabezado_leccion ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON encabezado_leccion FOR SELECT USING (true);
CREATE POLICY "Insert público"  ON encabezado_leccion FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público"  ON encabezado_leccion FOR UPDATE USING (true);

ALTER TABLE leccion_detalle ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON leccion_detalle FOR SELECT USING (true);
CREATE POLICY "Insert público"  ON leccion_detalle FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público"  ON leccion_detalle FOR UPDATE USING (true);

ALTER TABLE leccion_palabras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON leccion_palabras FOR SELECT USING (true);
CREATE POLICY "Insert público"  ON leccion_palabras FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público"  ON leccion_palabras FOR UPDATE USING (true);

ALTER TABLE estadistica_palabra ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON estadistica_palabra FOR SELECT USING (true);
CREATE POLICY "Insert público"  ON estadistica_palabra FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público"  ON estadistica_palabra FOR UPDATE USING (true);
