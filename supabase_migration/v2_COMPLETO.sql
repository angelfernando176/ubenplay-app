-- ============================================================
-- LINGO v2 — Schema Completo (20 tablas)
-- ============================================================

-- ⚠️ PRIMERO: Eliminar tablas viejas (si existen)
DROP TABLE IF EXISTS vocabulary CASCADE;
DROP TABLE IF EXISTS admin_users CASCADE;
DROP TABLE IF EXISTS import_logs CASCADE;
DROP TABLE IF EXISTS user_progress CASCADE;

-- ═══ CATÁLOGOS ═══

CREATE TABLE cat_palabra (
    id_categoria SMALLINT PRIMARY KEY,
    nombre_categoria VARCHAR(30) NOT NULL,
    descripcion VARCHAR(200),
    activo BOOLEAN DEFAULT TRUE
);
INSERT INTO cat_palabra VALUES (1,'Sustantivo','Nombres de personas, objetos, lugares, conceptos',TRUE);
INSERT INTO cat_palabra VALUES (2,'Verbo','Acciones, estados o procesos',TRUE);
INSERT INTO cat_palabra VALUES (3,'Adjetivo','Cualidades o características',TRUE);
INSERT INTO cat_palabra VALUES (4,'Conector','Palabras que unen oraciones o ideas',TRUE);

CREATE TABLE cat_tipo (
    id_tipo SMALLINT PRIMARY KEY,
    id_categoria SMALLINT NOT NULL REFERENCES cat_palabra(id_categoria),
    nombre_tipo VARCHAR(40) NOT NULL,
    descripcion VARCHAR(250),
    activo BOOLEAN DEFAULT TRUE
);
INSERT INTO cat_tipo VALUES (1,1,'der','Artículo masculino',TRUE);
INSERT INTO cat_tipo VALUES (2,1,'die','Artículo femenino',TRUE);
INSERT INTO cat_tipo VALUES (3,1,'das','Artículo neutro',TRUE);
INSERT INTO cat_tipo VALUES (4,1,'die (plural)','Plural',TRUE);
INSERT INTO cat_tipo VALUES (5,2,'Regular','Verbos regulares',TRUE);
INSERT INTO cat_tipo VALUES (6,2,'Irregular','Verbos irregulares',TRUE);
INSERT INTO cat_tipo VALUES (7,2,'Separable','Verbos separables',TRUE);
INSERT INTO cat_tipo VALUES (8,2,'Modal','Verbos modales',TRUE);
INSERT INTO cat_tipo VALUES (9,3,'Regular','Adjetivos regulares',TRUE);
INSERT INTO cat_tipo VALUES (10,3,'Irregular','Adjetivos irregulares',TRUE);
INSERT INTO cat_tipo VALUES (11,4,'Hauptsatz','Conectores de oración principal',TRUE);
INSERT INTO cat_tipo VALUES (12,4,'Nebensatz','Conectores de oración subordinada',TRUE);
INSERT INTO cat_tipo VALUES (13,4,'Konjunktionaladverb','Adverbios conjuncionales',TRUE);

CREATE TABLE cat_nivel (
    id_nivel SMALLINT PRIMARY KEY,
    codigo_nivel VARCHAR(5) NOT NULL,
    descripcion VARCHAR(250),
    orden_nivel SMALLINT
);
INSERT INTO cat_nivel VALUES (1,'A1','Principiante: frases básicas y vocabulario elemental',1);
INSERT INTO cat_nivel VALUES (2,'A2','Básico: situaciones cotidianas y expresiones frecuentes',2);
INSERT INTO cat_nivel VALUES (3,'B1','Intermedio: temas familiares y experiencias personales',3);
INSERT INTO cat_nivel VALUES (4,'B2','Intermedio alto: textos complejos y discusiones técnicas',4);
INSERT INTO cat_nivel VALUES (5,'C1','Avanzado: expresión fluida y espontánea',5);
INSERT INTO cat_nivel VALUES (6,'C2','Maestría: comprensión y expresión sin esfuerzo',6);

CREATE TABLE cat_tematica (
    id_tematica SMALLINT PRIMARY KEY,
    nombre_tematica VARCHAR(60) NOT NULL,
    descripcion VARCHAR(250),
    activo BOOLEAN DEFAULT TRUE
);
INSERT INTO cat_tematica VALUES
(1,'Familia','Parentesco y relaciones familiares',TRUE),
(2,'Casa','Hogar, muebles y objetos domésticos',TRUE),
(3,'Comida','Alimentos, bebidas y cocina',TRUE),
(4,'Transporte','Vehículos y movilidad',TRUE),
(5,'Trabajo-Oficios','Profesiones y empleos',TRUE),
(6,'Viajes','Turismo y desplazamientos',TRUE),
(7,'Ciudad','Lugares urbanos y servicios',TRUE),
(8,'Oficina','Entorno laboral y equipamiento',TRUE),
(9,'Tecnología','Dispositivos y mundo digital',TRUE),
(10,'Salud y medicina','Cuerpo, enfermedades y tratamientos',TRUE),
(11,'Compras y servicios','Consumo, tiendas y transacciones',TRUE),
(12,'Lugares públicos','Espacios comunitarios e instituciones',TRUE),
(13,'Tiempo y planificación','Calendario, horarios y organización',TRUE),
(14,'Deportes','Actividades físicas y competiciones',TRUE),
(15,'Naturaleza','Medio natural, clima y animales',TRUE),
(16,'Ropa','Vestimenta y accesorios',TRUE),
(17,'Educación','Escuela, universidad y formación',TRUE),
(18,'Cultura','Arte, música y entretenimiento',TRUE),
(19,'Sentimientos','Emociones y estados de ánimo',TRUE),
(20,'Comunicación','Medios, idiomas y expresión',TRUE),
(21,'Medio ambiente','Ecología y sostenibilidad',TRUE),
(22,'Economía','Finanzas, mercado y negocios',TRUE),
(23,'Derecho','Leyes, justicia y normativas',TRUE),
(24,'Sociedad','Grupos, relaciones y estructuras sociales',TRUE),
(25,'Política','Gobierno, instituciones y procesos políticos',TRUE),
(99,'General','Vocabulario sin clasificación temática específica',TRUE);

CREATE TABLE cat_rol_usuario (
    id_rol SMALLINT PRIMARY KEY,
    nombre_rol VARCHAR(40) NOT NULL,
    descripcion VARCHAR(250),
    activo BOOLEAN DEFAULT TRUE
);
INSERT INTO cat_rol_usuario VALUES (1,'Administrador','Acceso total al sistema',TRUE);
INSERT INTO cat_rol_usuario VALUES (2,'Profesor','Puede crear contenido y ver progreso de estudiantes',TRUE);
INSERT INTO cat_rol_usuario VALUES (3,'Estudiante','Acceso a lecciones y juegos',TRUE);

CREATE TABLE cat_dificultad_oracion (
    id_dificultad SMALLINT PRIMARY KEY,
    nombre_dificultad VARCHAR(40) NOT NULL,
    descripcion VARCHAR(250),
    activo BOOLEAN DEFAULT TRUE
);
INSERT INTO cat_dificultad_oracion VALUES (1,'Muy fácil','Oraciones con vocabulario básico',TRUE);
INSERT INTO cat_dificultad_oracion VALUES (2,'Fácil','Oraciones cotidianas',TRUE);
INSERT INTO cat_dificultad_oracion VALUES (3,'Intermedio','Oraciones compuestas',TRUE);
INSERT INTO cat_dificultad_oracion VALUES (4,'Avanzado','Oraciones con subordinadas',TRUE);
INSERT INTO cat_dificultad_oracion VALUES (5,'Explicación gramatical','Texto explicativo',TRUE);

CREATE TABLE cat_nivel_dominio (
    id_nivel_dominio SMALLINT PRIMARY KEY,
    nombre_nivel VARCHAR(40) NOT NULL,
    descripcion VARCHAR(300),
    porcentaje_minimo NUMERIC(5,2)
);
INSERT INTO cat_nivel_dominio VALUES (1,'No conocido','Nunca presentada',0);
INSERT INTO cat_nivel_dominio VALUES (2,'En aprendizaje','Errores frecuentes',0);
INSERT INTO cat_nivel_dominio VALUES (3,'Aprendido parcialmente','50-79% aciertos',50.00);
INSERT INTO cat_nivel_dominio VALUES (4,'Dominado','80-94% aciertos',80.00);
INSERT INTO cat_nivel_dominio VALUES (5,'Repaso ocasional','95%+ aciertos',95.00);

-- ═══ TABLA PRINCIPAL: PALABRAS ═══

CREATE TABLE palabras (
    id_palabra       BIGSERIAL PRIMARY KEY,
    id_categoria     SMALLINT NOT NULL DEFAULT 1 REFERENCES cat_palabra(id_categoria),
    palabra_es       VARCHAR(50) NOT NULL,
    palabra_de       VARCHAR(50) NOT NULL,
    id_tipo          SMALLINT REFERENCES cat_tipo(id_tipo),
    id_nivel         SMALLINT NOT NULL DEFAULT 1 REFERENCES cat_nivel(id_nivel),
    id_tematica      SMALLINT REFERENCES cat_tematica(id_tematica),
    definicion       VARCHAR(200),
    imagen_path      VARCHAR(250),
    activo           BOOLEAN DEFAULT TRUE,
    fecha_creacion   TIMESTAMPTZ DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ DEFAULT NOW(),
    audio_path       VARCHAR(250),
    texto_emoji      VARCHAR(10)
);
CREATE INDEX idx_palabras_categoria ON palabras(id_categoria);
CREATE INDEX idx_palabras_nivel ON palabras(id_nivel);
CREATE INDEX idx_palabras_tematica ON palabras(id_tematica);
CREATE INDEX idx_palabras_es ON palabras(palabra_es);
CREATE INDEX idx_palabras_de ON palabras(palabra_de);

-- ═══ TABLAS ESPECÍFICAS ═══

CREATE TABLE sustantivos (
    id_palabra BIGINT PRIMARY KEY REFERENCES palabras(id_palabra) ON DELETE CASCADE,
    plural     VARCHAR(50) NOT NULL
);

CREATE TABLE verbos (
    id_palabra          BIGINT PRIMARY KEY REFERENCES palabras(id_palabra) ON DELETE CASCADE,
    conjuga_ich         VARCHAR(40),
    conjuga_du          VARCHAR(40),
    conjuga_er          VARCHAR(40),
    conjuga_ella        VARCHAR(40),
    conjuga_es          VARCHAR(40),
    conjuga_wir         VARCHAR(40),
    conjuga_ihr         VARCHAR(40),
    conjuga_usted       VARCHAR(40),
    conjuga_ellos       VARCHAR(40)
);

CREATE TABLE adjetivos (
    id_palabra          BIGINT PRIMARY KEY REFERENCES palabras(id_palabra) ON DELETE CASCADE,
    comparativo_aleman  VARCHAR(50),
    superlativo_aleman  VARCHAR(50)
);

CREATE TABLE conectores (
    id_palabra BIGINT PRIMARY KEY REFERENCES palabras(id_palabra) ON DELETE CASCADE
);

-- ═══ JUEGOS ═══

CREATE TABLE juegos (
    id_juego              SMALLINT PRIMARY KEY,
    nombre_juego          VARCHAR(80) NOT NULL,
    breve_explicacion     VARCHAR(250),
    descripcion_detallada TEXT
);
INSERT INTO juegos VALUES (1,'Unir columnas','Relaciona español con alemán','2 columnas: izquierda español, derecha alemán.');
INSERT INTO juegos VALUES (2,'Artículos','Elige der, die, das','Palabra en alemán + 4 opciones de artículo.');
INSERT INTO juegos VALUES (3,'Dobble','Traducción múltiple choice','Palabra en alemán, elegir significado en español (o viceversa).');
INSERT INTO juegos VALUES (4,'Escribir','Escribe la palabra en alemán','Imagen + espacios para escribir la palabra completa o letras faltantes.');
INSERT INTO juegos VALUES (5,'Elegir imagen','Selecciona la palabra correcta','Imagen + opciones de palabras en alemán.');
INSERT INTO juegos VALUES (6,'Pares','Memory 4x4','8 imágenes + 8 textos. Encontrar los pares.');

-- ═══ PERFIL_USUARIO ═══

CREATE TABLE perfil_usuario (
    id_usuario       UUID PRIMARY KEY,
    nombre           VARCHAR(80),
    apellido         VARCHAR(80),
    id_rol           SMALLINT DEFAULT 3 REFERENCES cat_rol_usuario(id_rol),
    idioma_interfaz  VARCHAR(10) DEFAULT 'es',
    nivel_actual     SMALLINT DEFAULT 1 REFERENCES cat_nivel(id_nivel),
    fecha_registro   TIMESTAMPTZ DEFAULT NOW(),
    ultimo_acceso    TIMESTAMPTZ,
    activo           BOOLEAN DEFAULT TRUE
);

-- ═══ ENCABEZADO_LECCION ═══

CREATE TABLE encabezado_leccion (
    id_leccion           BIGSERIAL PRIMARY KEY,
    id_usuario           UUID REFERENCES perfil_usuario(id_usuario),
    fecha_inicio         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_fin            TIMESTAMPTZ,
    nivel                SMALLINT DEFAULT 1 REFERENCES cat_nivel(id_nivel),
    cantidad_palabras    SMALLINT DEFAULT 10,
    porcentaje_aciertos  NUMERIC(5,2),
    estado               VARCHAR(20) DEFAULT 'En proceso'
);

-- ═══ LECCION_PALABRAS ═══

CREATE TABLE leccion_palabras (
    id_leccion_palabra  BIGSERIAL PRIMARY KEY,
    id_leccion          BIGINT NOT NULL REFERENCES encabezado_leccion(id_leccion),
    id_palabra          BIGINT NOT NULL REFERENCES palabras(id_palabra),
    orden_presentacion  SMALLINT,
    veces_revisada      SMALLINT DEFAULT 0,
    aprendida           BOOLEAN DEFAULT FALSE
);

-- ═══ LECCION_DETALLE ═══

CREATE TABLE leccion_detalle (
    id_detalle         BIGSERIAL PRIMARY KEY,
    id_leccion         BIGINT NOT NULL REFERENCES encabezado_leccion(id_leccion),
    id_palabra         BIGINT NOT NULL REFERENCES palabras(id_palabra),
    id_juego           SMALLINT REFERENCES juegos(id_juego),
    respuesta_correcta BOOLEAN NOT NULL,
    tiempo_respuesta   NUMERIC(6,2),
    detalle_error      VARCHAR(300),
    fecha_registro     TIMESTAMPTZ DEFAULT NOW()
);

-- ═══ ORACIONES ═══

CREATE TABLE oraciones (
    id_oracion          BIGSERIAL PRIMARY KEY,
    id_palabra          BIGINT REFERENCES palabras(id_palabra),
    oracion_ejemplo     TEXT NOT NULL,
    oracion_traduccion  TEXT,
    nivel_dificultad    SMALLINT DEFAULT 1 REFERENCES cat_dificultad_oracion(id_dificultad)
);

-- ═══ PALABRA_ORACION ═══

CREATE TABLE palabra_oracion (
    id_palabra_oracion BIGSERIAL PRIMARY KEY,
    id_oracion         BIGINT NOT NULL REFERENCES oraciones(id_oracion) ON DELETE CASCADE,
    orden              SMALLINT NOT NULL,
    palabra            VARCHAR(50) NOT NULL,
    significado        VARCHAR(50)
);

-- ═══ ESTADISTICA_PALABRA ═══

CREATE TABLE estadistica_palabra (
    id_estadistica   BIGSERIAL PRIMARY KEY,
    id_usuario       UUID NOT NULL REFERENCES perfil_usuario(id_usuario),
    id_palabra       BIGINT NOT NULL REFERENCES palabras(id_palabra),
    veces_presentada INTEGER DEFAULT 0,
    aciertos         INTEGER DEFAULT 0,
    errores          INTEGER DEFAULT 0,
    ultima_revision  TIMESTAMPTZ,
    nivel_dominio    SMALLINT DEFAULT 1 REFERENCES cat_nivel_dominio(id_nivel_dominio),
    racha_aciertos   SMALLINT DEFAULT 0,
    racha_errores    SMALLINT DEFAULT 0
);

-- ═══ RLS (Row Level Security) ═══

ALTER TABLE palabras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON palabras FOR SELECT USING (true);
CREATE POLICY "Insert público" ON palabras FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público" ON palabras FOR UPDATE USING (true);
CREATE POLICY "Delete público" ON palabras FOR DELETE USING (true);

ALTER TABLE sustantivos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON sustantivos FOR SELECT USING (true);
CREATE POLICY "Insert público" ON sustantivos FOR INSERT WITH CHECK (true);

ALTER TABLE verbos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON verbos FOR SELECT USING (true);
CREATE POLICY "Insert público" ON verbos FOR INSERT WITH CHECK (true);

ALTER TABLE adjetivos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON adjetivos FOR SELECT USING (true);
CREATE POLICY "Insert público" ON adjetivos FOR INSERT WITH CHECK (true);

ALTER TABLE conectores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON conectores FOR SELECT USING (true);
CREATE POLICY "Insert público" ON conectores FOR INSERT WITH CHECK (true);

ALTER TABLE perfil_usuario ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON perfil_usuario FOR SELECT USING (true);

ALTER TABLE encabezado_leccion ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON encabezado_leccion FOR SELECT USING (true);
CREATE POLICY "Insert público" ON encabezado_leccion FOR INSERT WITH CHECK (true);

ALTER TABLE leccion_palabras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON leccion_palabras FOR SELECT USING (true);
CREATE POLICY "Insert público" ON leccion_palabras FOR INSERT WITH CHECK (true);

ALTER TABLE leccion_detalle ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON leccion_detalle FOR SELECT USING (true);
CREATE POLICY "Insert público" ON leccion_detalle FOR INSERT WITH CHECK (true);

ALTER TABLE oraciones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON oraciones FOR SELECT USING (true);
CREATE POLICY "Insert público" ON oraciones FOR INSERT WITH CHECK (true);

ALTER TABLE palabra_oracion ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON palabra_oracion FOR SELECT USING (true);
CREATE POLICY "Insert público" ON palabra_oracion FOR INSERT WITH CHECK (true);

ALTER TABLE estadistica_palabra ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública" ON estadistica_palabra FOR SELECT USING (true);
CREATE POLICY "Insert público" ON estadistica_palabra FOR INSERT WITH CHECK (true);
