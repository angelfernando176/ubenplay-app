-- ============================================================
-- LINGO — Reestructuración (VERSIÓN SQLite)
-- Espejo local del script de Supabase. Sintaxis SQLite.
-- NO usa RLS (no existe en SQLite) ni trigger PL/pgSQL.
-- ============================================================

-- 0. (No hay perfil_usuario ni tablas de lecciones en SQLite hoy;
--    los DROP son no-op por seguridad.)
DROP TABLE IF EXISTS leccion_palabras;
DROP TABLE IF EXISTS leccion_detalle;
DROP TABLE IF EXISTS estadistica_palabra;
DROP TABLE IF EXISTS encabezado_leccion;
DROP TABLE IF EXISTS perfil_usuario;

-- 1. Tablas de catálogo faltantes (necesarias como destino de FK)
CREATE TABLE IF NOT EXISTS juegos (
    id_juego              INTEGER PRIMARY KEY,
    nombre_juego          TEXT NOT NULL,
    breve_explicacion     TEXT,
    descripcion_detallada TEXT
);
INSERT OR IGNORE INTO juegos VALUES (1,'Unir columnas','Relaciona español con alemán','2 columnas: izquierda español, derecha alemán.');
INSERT OR IGNORE INTO juegos VALUES (2,'Artículos','Elige der, die, das','Palabra en alemán + 4 opciones de artículo.');
INSERT OR IGNORE INTO juegos VALUES (3,'Dobble','Traducción múltiple choice','Palabra en alemán, elegir significado en español (o viceversa).');
INSERT OR IGNORE INTO juegos VALUES (4,'Escribir','Escribe la palabra en alemán','Imagen + espacios para escribir la palabra completa o letras faltantes.');
INSERT OR IGNORE INTO juegos VALUES (5,'Elegir imagen','Selecciona la palabra correcta','Imagen + opciones de palabras en alemán.');
INSERT OR IGNORE INTO juegos VALUES (6,'Pares','Memory 4x4','8 imágenes + 8 textos. Encontrar los pares.');

CREATE TABLE IF NOT EXISTS cat_nivel_dominio (
    id_nivel_dominio INTEGER PRIMARY KEY,
    nombre_nivel     TEXT,
    descripcion      TEXT,
    porcentaje_minimo NUMERIC
);
INSERT OR IGNORE INTO cat_nivel_dominio VALUES (1,'No conocido','Nunca presentada',0);
INSERT OR IGNORE INTO cat_nivel_dominio VALUES (2,'En aprendizaje','Errores frecuentes',0);
INSERT OR IGNORE INTO cat_nivel_dominio VALUES (3,'Aprendido parcialmente','50-79% aciertos',50.00);
INSERT OR IGNORE INTO cat_nivel_dominio VALUES (4,'Dominado','80-94% aciertos',80.00);
INSERT OR IGNORE INTO cat_nivel_dominio VALUES (5,'Repaso ocasional','95%+ aciertos',95.00);

-- 2. datos_batch
CREATE TABLE datos_batch (
    id_datos_batch  INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha_carga     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    numero_palabras INTEGER,
    id_tematica     INTEGER REFERENCES cat_tematica(id_tematica),
    id_categoria    INTEGER REFERENCES cat_palabra(id_categoria),
    id_usuario      INTEGER REFERENCES usuarios(id_usuario),
    observaciones   TEXT,
    nombre_archivo  TEXT,
    estado          INTEGER DEFAULT 0
);

-- 3. encabezado_leccion
CREATE TABLE encabezado_leccion (
    id_leccion          INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario          INTEGER REFERENCES usuarios(id_usuario),
    fecha_inicio        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cantidad_palabras   INTEGER NOT NULL DEFAULT 10,
    porcentaje_aciertos INTEGER,
    estado              INTEGER DEFAULT 1,
    tipo_leccion        INTEGER DEFAULT 1,
    id_suscripcion      TEXT DEFAULT '0',
    icono               TEXT,
    id_datos_batch      INTEGER REFERENCES datos_batch(id_datos_batch)
);

-- 4. leccion_detalle
CREATE TABLE leccion_detalle (
    id_detalle      INTEGER PRIMARY KEY AUTOINCREMENT,
    id_leccion      INTEGER NOT NULL REFERENCES encabezado_leccion(id_leccion),
    id_palabra      INTEGER NOT NULL REFERENCES palabras(id_palabra),
    id_juego        INTEGER REFERENCES juegos(id_juego),
    estado          INTEGER DEFAULT 1,
    fecha_registro  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_datos_batch  INTEGER REFERENCES datos_batch(id_datos_batch)
);

-- 5. leccion_palabras
CREATE TABLE leccion_palabras (
    id_leccion_palabra INTEGER PRIMARY KEY AUTOINCREMENT,
    id_leccion         INTEGER NOT NULL REFERENCES encabezado_leccion(id_leccion),
    id_palabra         INTEGER NOT NULL REFERENCES palabras(id_palabra),
    veces_revisada     INTEGER DEFAULT 0,
    aprendida          INTEGER DEFAULT 0,
    id_detalle         INTEGER REFERENCES leccion_detalle(id_detalle),
    id_juego           INTEGER REFERENCES juegos(id_juego),
    respuesta          INTEGER,
    id_usuario         INTEGER REFERENCES usuarios(id_usuario),
    fecha_registro     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado             INTEGER DEFAULT 1,
    id_datos_batch     INTEGER REFERENCES datos_batch(id_datos_batch)
);

-- 6. estadistica_palabra (conserva estructura; id_usuario → usuarios)
CREATE TABLE estadistica_palabra (
    id_estadistica    INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario        INTEGER NOT NULL REFERENCES usuarios(id_usuario),
    id_palabra        INTEGER NOT NULL REFERENCES palabras(id_palabra),
    veces_presentada  INTEGER DEFAULT 0,
    aciertos          INTEGER DEFAULT 0,
    errores           INTEGER DEFAULT 0,
    ultima_revision   TIMESTAMP,
    nivel_dominio     INTEGER DEFAULT 1 REFERENCES cat_nivel_dominio(id_nivel_dominio),
    racha_aciertos    INTEGER DEFAULT 0,
    racha_errores     INTEGER DEFAULT 0
);
