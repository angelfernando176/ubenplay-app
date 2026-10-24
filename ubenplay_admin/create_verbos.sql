-- Crear tabla verbos en Supabase
CREATE TABLE IF NOT EXISTS verbos (
  id_palabra INTEGER PRIMARY KEY REFERENCES palabras(id_palabra),
  conjuga_ich VARCHAR(50),
  conjuga_du VARCHAR(50),
  conjuga_er VARCHAR(50),
  conjuga_sie VARCHAR(50),
  conjuga_es VARCHAR(50),
  conjuga_wir VARCHAR(50),
  conjuga_ihr VARCHAR(50),
  "conjuga_Sie" VARCHAR(50),
  conjuga_sie_plural VARCHAR(50),
  ejemplo_oracion1 VARCHAR(200)
);

-- Deshabilitar RLS para permitir escritura anónima
ALTER TABLE verbos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all" ON verbos;
CREATE POLICY "Allow all" ON verbos FOR ALL USING (true) WITH CHECK (true);
