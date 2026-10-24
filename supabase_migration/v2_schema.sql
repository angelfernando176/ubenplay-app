-- ============================================================
-- LINGO v2 - Nuevo Schema Supabase
-- Diseño: tablas normalizadas por tipo de palabra
-- ============================================================

-- ═══ TABLAS CATÁLOGO ═══

CREATE TABLE cat_palabra (
    id SMALLINT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);
INSERT INTO cat_palabra VALUES (1,'Sustantivo'),(2,'Verbo'),(3,'Adjetivo'),(4,'Conector');

CREATE TABLE cat_tipo (
    id SMALLINT PRIMARY KEY,
    id_categoria SMALLINT NOT NULL REFERENCES cat_palabra(id),
    nombre VARCHAR(30) NOT NULL
);
-- Sustantivos: der/die/das/die(pl)
INSERT INTO cat_tipo VALUES (1,1,'der'),(2,1,'die'),(3,1,'das'),(4,1,'die (plural)');
-- Verbos: regular/irregular
INSERT INTO cat_tipo VALUES (5,2,'Regular'),(6,2,'Irregular');
-- Adjetivos
INSERT INTO cat_tipo VALUES (7,3,'Regular'),(8,3,'Irregular');
-- Conectores
INSERT INTO cat_tipo VALUES (9,4,'Hauptsätze'),(10,4,'Nebensätze'),(11,4,'Konjunktionaladverbien');

CREATE TABLE cat_nivel (
    id SMALLINT PRIMARY KEY,
    nombre VARCHAR(4) NOT NULL
);
INSERT INTO cat_nivel VALUES (1,'A1'),(2,'A2'),(3,'B1'),(4,'B2'),(5,'C1'),(6,'C2');

CREATE TABLE cat_tematica (
    id SMALLINT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);
INSERT INTO cat_tematica VALUES
(1,'Familia'),(2,'Casa'),(3,'Comida'),(4,'Transporte'),(5,'Trabajo-Oficios'),
(6,'Viajes'),(7,'Ciudad'),(8,'Oficina'),(9,'Tecnología'),(10,'Salud y medicina'),
(11,'Compras y servicios'),(12,'Lugares públicos'),(13,'Tiempo y planificación'),
(14,'Deportes'),(15,'Naturaleza'),(16,'Ropa'),(17,'Educación'),(18,'Cultura'),
(19,'Sentimientos'),(20,'Comunicación'),(21,'Medio ambiente'),(22,'Economía'),
(23,'Derecho'),(24,'Sociedad'),(25,'Política'),(99,'General');

-- ═══ TABLA PRINCIPAL: PALABRAS ═══

CREATE TABLE palabras (
    id_palabra       BIGSERIAL PRIMARY KEY,
    id_categoria     SMALLINT NOT NULL REFERENCES cat_palabra(id),
    palabra_es       VARCHAR(50) NOT NULL,
    palabra_de       VARCHAR(50) NOT NULL,
    id_tipo          SMALLINT REFERENCES cat_tipo(id),
    id_nivel         SMALLINT NOT NULL DEFAULT 1 REFERENCES cat_nivel(id),
    id_tematica      SMALLINT REFERENCES cat_tematica(id),
    definicion       VARCHAR(200),
    imagen_path      VARCHAR(250),
    activo           BOOLEAN DEFAULT TRUE,
    fecha_creacion   TIMESTAMPTZ DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ DEFAULT NOW(),
    audio_path       VARCHAR(250),
    oracion_ejemplo  TEXT,
    texto_emoji      VARCHAR(10)  -- emoji fallback
);

CREATE INDEX idx_palabras_categoria ON palabras(id_categoria);
CREATE INDEX idx_palabras_nivel ON palabras(id_nivel);
CREATE INDEX idx_palabras_tematica ON palabras(id_tematica);
CREATE INDEX idx_palabras_es ON palabras(palabra_es);
CREATE INDEX idx_palabras_de ON palabras(palabra_de);

-- ═══ TABLA: SUSTANTIVOS ═══

CREATE TABLE sustantivos (
    id_palabra BIGINT PRIMARY KEY REFERENCES palabras(id_palabra) ON DELETE CASCADE,
    plural     VARCHAR(50) NOT NULL
);

-- ═══ TABLA: VERBOS ═══

CREATE TABLE verbos (
    id_palabra       BIGINT PRIMARY KEY REFERENCES palabras(id_palabra) ON DELETE CASCADE,
    conjuga_ich      VARCHAR(40),
    conjuga_du       VARCHAR(40),
    conjuga_er       VARCHAR(40),
    conjuga_sie      VARCHAR(40),
    conjuga_es       VARCHAR(40),
    conjuga_wir      VARCHAR(40),
    conjuga_ihr      VARCHAR(40),
    conjuga_Sie      VARCHAR(40),
    conjuga_sie_plural VARCHAR(40)
);

-- ═══ TABLA: ADJETIVOS ═══

CREATE TABLE adjetivos (
    id_palabra          BIGINT PRIMARY KEY REFERENCES palabras(id_palabra) ON DELETE CASCADE,
    comparativo_aleman  VARCHAR(50),
    superlativo_aleman  VARCHAR(50)
);

-- ═══ TABLA: CONECTORES (mínima por ahora) ═══

CREATE TABLE conectores (
    id_palabra BIGINT PRIMARY KEY REFERENCES palabras(id_palabra) ON DELETE CASCADE
);

-- ═══ POLÍTICAS RLS ═══

ALTER TABLE palabras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON palabras FOR SELECT USING (true);
CREATE POLICY "Insert público" ON palabras FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público" ON palabras FOR UPDATE USING (true);
CREATE POLICY "Delete público" ON palabras FOR DELETE USING (true);

ALTER TABLE sustantivos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública sustantivos" ON sustantivos FOR SELECT USING (true);
CREATE POLICY "Insert público sustantivos" ON sustantivos FOR INSERT WITH CHECK (true);

ALTER TABLE verbos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública verbos" ON verbos FOR SELECT USING (true);
CREATE POLICY "Insert público verbos" ON verbos FOR INSERT WITH CHECK (true);

ALTER TABLE adjetivos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública adjetivos" ON adjetivos FOR SELECT USING (true);
CREATE POLICY "Insert público adjetivos" ON adjetivos FOR INSERT WITH CHECK (true);

ALTER TABLE conectores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública conectores" ON conectores FOR SELECT USING (true);
CREATE POLICY "Insert público conectores" ON conectores FOR INSERT WITH CHECK (true);
