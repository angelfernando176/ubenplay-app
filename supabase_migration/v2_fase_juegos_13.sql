-- LINGO — Catálogo de juegos (13, numeración canónica de Fernando)
-- Ejecutar en Supabase → SQL Editor (reemplaza los 6 juegos legacy).
DELETE FROM juegos;
INSERT INTO juegos (id_juego, nombre_juego, breve_explicacion) VALUES
 (1,  'Unión de Palabras',           'Relaciona español con alemán'),
 (2,  'Caza del Artículo',           'Elige der, die, das'),
 (3,  'Traduce',                     'Traducción múltiple choice'),
 (4,  'Ahorcado',                    'Completa la palabra'),
 (5,  'Memoria',                     'Encuentra los pares'),
 (6,  'Opciones',                    'Inactivo'),
 (7,  'Sopa de Letras',              'Busca las palabras'),
 (8,  'Ruleta de Palabras',          'Gira y responde'),
 (9,  'Puerta Verde',                'Elige la puerta correcta'),
 (10, 'Puente de Cristal - Palabra', 'Ordena las letras'),
 (11, 'Ordena Filas',                'Conjuga el verbo'),
 (12, 'Puente de cristal - oración', 'Ordena la frase'),
 (13, 'Crucigrama',                  'Inactivo');
