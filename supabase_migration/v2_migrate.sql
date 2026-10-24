-- Migrar datos existentes de vocabulary → nuevo schema
-- Ejecutar DESPUÉS de v2_schema.sql

-- 1. Migrar categorías a cat_tematica (si no existen)
INSERT INTO cat_tematica (id, nombre) VALUES 
(30,'Animales'),(31,'Escuela'),(32,'Clima'),(33,'Personalidad'),
(34,'Verbos sust.'),(35,'Populares')
ON CONFLICT (id) DO NOTHING;

-- 2. Migrar palabras principales
INSERT INTO palabras (id_palabra, id_categoria, palabra_es, palabra_de, id_tipo, id_nivel, id_tematica, definicion, imagen_path, texto_emoji, oracion_ejemplo)
SELECT 
    v.id,
    1, -- Sustantivo
    v.spanish,
    v.german,
    CASE v.article
        WHEN 'der' THEN 1
        WHEN 'die' THEN 2
        WHEN 'das' THEN 3
        ELSE 4
    END,
    CASE v.cefr_level
        WHEN 'A1' THEN 1 WHEN 'A2' THEN 2
        WHEN 'B1' THEN 3 WHEN 'B2' THEN 4
        ELSE 1
    END,
    CASE v.category_id
        WHEN 'family' THEN 1 WHEN 'house' THEN 2 WHEN 'food' THEN 3
        WHEN 'transport' THEN 4 WHEN 'jobs' THEN 5 WHEN 'travel' THEN 6
        WHEN 'city' THEN 7 WHEN 'office' THEN 8 WHEN 'tech' THEN 9
        WHEN 'health' THEN 10 WHEN 'shopping' THEN 11 WHEN 'city2' THEN 12
        WHEN 'timeplan' THEN 13 WHEN 'animals' THEN 30 WHEN 'school' THEN 31
        WHEN 'weather' THEN 32 WHEN 'personality' THEN 33
        WHEN 'verbsnoun' THEN 34 WHEN 'popular' THEN 35
        ELSE 99
    END,
    v.definition,
    v.image_url,
    v.image,
    v.example_sentence
FROM vocabulary v
WHERE v.word_type = 'noun' OR v.word_type IS NULL;

-- 3. Migrar sustantivos (plural)
INSERT INTO sustantivos (id_palabra, plural)
SELECT v.id, COALESCE(v.plural, '')
FROM vocabulary v
WHERE v.word_type = 'noun' OR v.word_type IS NULL;

-- 4. Actualizar secuencia
SELECT setval('palabras_id_palabra_seq', (SELECT MAX(id_palabra) FROM palabras));
