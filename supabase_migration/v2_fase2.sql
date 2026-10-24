

-- ════════════════════════════════════════════════════════════
-- FASE 2: Oraciones, Juegos, Usuarios, Lecciones, Estadísticas
-- ════════════════════════════════════════════════════════════

-- ═══ CAT_DIFICULTAD_ORACION ═══

CREATE TABLE cat_dificultad_oracion (
    id_dificultad     SMALLINT PRIMARY KEY,
    nombre_dificultad VARCHAR(40) NOT NULL,
    descripcion       VARCHAR(250),
    activo            BOOLEAN DEFAULT TRUE
);
INSERT INTO cat_dificultad_oracion VALUES (1,'Muy fácil','Oraciones con vocabulario básico y estructura simple',TRUE);
INSERT INTO cat_dificultad_oracion VALUES (2,'Fácil','Oraciones cotidianas con estructuras comunes',TRUE);
INSERT INTO cat_dificultad_oracion VALUES (3,'Intermedio','Oraciones con estructuras compuestas',TRUE);
INSERT INTO cat_dificultad_oracion VALUES (4,'Avanzado','Oraciones complejas con subordinadas',TRUE);
INSERT INTO cat_dificultad_oracion VALUES (5,'Explicación gramatical','Texto explicativo sobre reglas gramaticales',TRUE);

-- ═══ CAT_NIVEL_DOMINIO ═══

CREATE TABLE cat_nivel_dominio (
    id_nivel_dominio  SMALLINT PRIMARY KEY,
    nombre_nivel      VARCHAR(40) NOT NULL,
    descripcion       VARCHAR(300),
    porcentaje_minimo NUMERIC(5,2)
);
INSERT INTO cat_nivel_dominio VALUES (1,'No conocido','La palabra nunca ha sido presentada',0);
INSERT INTO cat_nivel_dominio VALUES (2,'En aprendizaje','El estudiante ha visto la palabra pero comete errores frecuentes',0);
INSERT INTO cat_nivel_dominio VALUES (3,'Aprendido parcialmente','Responde correctamente entre 50% y 79% de las veces',50.00);
INSERT INTO cat_nivel_dominio VALUES (4,'Dominado','Responde correctamente entre 80% y 94% de las veces',80.00);
INSERT INTO cat_nivel_dominio VALUES (5,'Repaso ocasional','Responde correctamente más del 95% de las veces',95.00);

-- ═══ JUEGOS ═══

CREATE TABLE juegos (
    id_juego              SMALLINT PRIMARY KEY,
    nombre_juego          VARCHAR(80) NOT NULL,
    breve_explicacion     VARCHAR(250),
    descripcion_detallada TEXT
);
INSERT INTO juegos VALUES (1,'Unir columnas','Relaciona la palabra en español con su traducción al alemán','Se presentan 2 columnas: izquierda (español) y derecha (alemán). El estudiante debe seleccionar una palabra del lado izquierdo y escoger su traducción correcta en el lado derecho.');
INSERT INTO juegos VALUES (2,'Artículos','Selecciona el artículo correcto: der, die, das','Aparece la palabra en alemán con su significado en español. El estudiante debe elegir entre las cuatro variantes del artículo: der, die, das, die (plural).');
INSERT INTO juegos VALUES (3,'Dobble','Encuentra la traducción correcta entre varias opciones','Se presenta una palabra en alemán y el estudiante debe escoger entre varias opciones el significado/traducción en español (o viceversa).');
INSERT INTO juegos VALUES (4,'Escribir','Escribe la palabra correcta en alemán','Se muestra una imagen en la parte superior y aparecen espacios para que el estudiante escriba la palabra en alemán. Incluye completar letras faltantes.');
INSERT INTO juegos VALUES (5,'Elegir imagen','Selecciona la palabra correcta para la imagen','Se muestra una imagen en la parte superior central y abajo aparecen opciones de palabras en alemán para elegir.');
INSERT INTO juegos VALUES (6,'Pares','Encuentra los pares entre imágenes y texto','Matriz de 4x4 con 8 imágenes y 8 textos en alemán. El objetivo es emparejar cada imagen con su palabra correspondiente.');

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

ALTER TABLE perfil_usuario ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Usuarios ven su perfil" ON perfil_usuario FOR SELECT USING (auth.uid() = id_usuario);
CREATE POLICY "Usuarios actualizan su perfil" ON perfil_usuario FOR UPDATE USING (auth.uid() = id_usuario);

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

ALTER TABLE encabezado_leccion ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública lecciones" ON encabezado_leccion FOR SELECT USING (true);
CREATE POLICY "Insert público lecciones" ON encabezado_leccion FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público lecciones" ON encabezado_leccion FOR UPDATE USING (true);

-- ═══ LECCION_PALABRAS ═══

CREATE TABLE leccion_palabras (
    id_leccion_palabra  BIGSERIAL PRIMARY KEY,
    id_leccion          BIGINT NOT NULL REFERENCES encabezado_leccion(id_leccion),
    id_palabra          BIGINT NOT NULL REFERENCES palabras(id_palabra),
    orden_presentacion  SMALLINT,
    veces_revisada      SMALLINT DEFAULT 0,
    aprendida           BOOLEAN DEFAULT FALSE
);

ALTER TABLE leccion_palabras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública leccion_palabras" ON leccion_palabras FOR SELECT USING (true);
CREATE POLICY "Insert público leccion_palabras" ON leccion_palabras FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público leccion_palabras" ON leccion_palabras FOR UPDATE USING (true);

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

ALTER TABLE leccion_detalle ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública leccion_detalle" ON leccion_detalle FOR SELECT USING (true);
CREATE POLICY "Insert público leccion_detalle" ON leccion_detalle FOR INSERT WITH CHECK (true);

-- ═══ ORACIONES ═══

CREATE TABLE oraciones (
    id_oracion          BIGSERIAL PRIMARY KEY,
    id_palabra          BIGINT REFERENCES palabras(id_palabra),
    oracion_ejemplo     TEXT NOT NULL,
    oracion_traduccion  TEXT,
    nivel_dificultad    SMALLINT DEFAULT 1 REFERENCES cat_dificultad_oracion(id_dificultad)
);

ALTER TABLE oraciones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública oraciones" ON oraciones FOR SELECT USING (true);
CREATE POLICY "Insert público oraciones" ON oraciones FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público oraciones" ON oraciones FOR UPDATE USING (true);
CREATE POLICY "Delete público oraciones" ON oraciones FOR DELETE USING (true);

-- ═══ PALABRA_ORACION ═══

CREATE TABLE palabra_oracion (
    id_palabra_oracion BIGSERIAL PRIMARY KEY,
    id_oracion         BIGINT NOT NULL REFERENCES oraciones(id_oracion) ON DELETE CASCADE,
    orden              SMALLINT NOT NULL,
    palabra            VARCHAR(50) NOT NULL,
    significado        VARCHAR(50)
);

ALTER TABLE palabra_oracion ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública palabra_oracion" ON palabra_oracion FOR SELECT USING (true);
CREATE POLICY "Insert público palabra_oracion" ON palabra_oracion FOR INSERT WITH CHECK (true);

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

ALTER TABLE estadistica_palabra ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública estadisticas" ON estadistica_palabra FOR SELECT USING (true);
CREATE POLICY "Insert público estadisticas" ON estadistica_palabra FOR INSERT WITH CHECK (true);
CREATE POLICY "Update público estadisticas" ON estadistica_palabra FOR UPDATE USING (true);
