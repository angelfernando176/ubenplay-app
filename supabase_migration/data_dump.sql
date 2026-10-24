-- ============================================================
-- LINGO - Datos para Supabase
-- Generado: 2026-07-15 12:14:58.371381
-- Ejecutar en SQL Editor de Supabase DESPUÉS de crear el schema
-- ============================================================

-- Datos exportados de SQLite
-- Fecha: 2026-07-15 12:14:58.372740
-- Tabla: vocabulary

INSERT INTO vocabulary (spanish, german, article, plural, cefr_level, category_id, word_type, image_code, image_url) VALUES
  ('Ciudad','Stadt','die','die Städte','A1','city','noun','',''),
  ('Pueblo','Dorf','das','die Dörfer','A1','city','noun','',''),
  ('Calle','Straße','die','die Straßen','A1','city','noun','',''),
  ('Plaza','Platz','der','die Plätze','A1','city','noun','',''),
  ('Centro','Zentrum','das','die Zentren','A1','city','noun','',''),
  ('Barrio','Viertel','das','die Viertel','A1','city','noun','',''),
  ('Casa','Haus','das','die Häuser','A1','city','noun','',''),
  ('Edificio','Gebäude','das','die Gebäude','A1','city','noun','',''),
  ('Apartamento / Vivienda','Wohnung','die','die Wohnungen','A1','city','noun','',''),
  ('Estación de tren','Bahnhof','der','die Bahnhöfe','A1','city','noun','',''),
  ('Parada (de bus)','Haltestelle','die','die Haltestellen','A1','city','noun','',''),
  ('Autobús','Bus','der','die Busse','A1','city','noun','',''),
  ('Metro','U-Bahn','die','die U-Bahnen','A1','city','noun','',''),
  ('Tranvía','Straßenbahn','die','die Straßenbahnen','A1','city','noun','',''),
  ('Taxi','Taxi','das','die Taxis','A1','city','noun','',''),
  ('Automóvil','Auto','das','die Autos','A1','city','noun','',''),
  ('Bicicleta','Fahrrad','das','die Fahrräder','A1','city','noun','',''),
  ('Tren','Zug','der','die Züge','A1','city','noun','',''),
  ('Semáforo','Ampel','die','die Ampeln','A1','city','noun','',''),
  ('Puente','Brücke','die','die Brücken','A1','city','noun','',''),
  ('Parque','Park','der','die Parks','A1','city','noun','',''),
  ('Jardín','Garten','der','die Gärten','A1','city','noun','',''),
  ('Árbol','Baum','der','die Bäume','A1','city','noun','',''),
  ('Banco (para sentarse)','Bank','die','die Bänke','A1','city','noun','',''),
  ('Río','Fluss','der','die Flüsse','A1','city','noun','',''),
  ('Iglesia','Kirche','die','die Kirchen','A1','city','noun','',''),
  ('Ayuntamiento','Rathaus','das','die Rathäuser','A1','city','noun','',''),
  ('Museo','Museum','das','die Museen','A1','city','noun','',''),
  ('Teatro','Theater','das','die Theater','A1','city','noun','',''),
  ('Cine','Kino','das','die Kinos','A1','city','noun','',''),
  ('Biblioteca','Bibliothek','die','die Bibliotheken','A1','city','noun','',''),
  ('Escuela','Schule','die','die Schulen','A1','city','noun','',''),
  ('Universidad','Universität','die','die Universitäten','A1','city','noun','',''),
  ('Hospital','Krankenhaus','das','die Krankenhäuser','A1','city','noun','',''),
  ('Farmacia','Apotheke','die','die Apotheken','A1','city','noun','',''),
  ('Supermercado','Supermarkt','der','die Supermärkte','A1','city','noun','',''),
  ('Tienda','Geschäft','das','die Geschäfte','A1','city','noun','',''),
  ('Mercado','Markt','der','die Märkte','A1','city','noun','',''),
  ('Panadería','Bäckerei','die','die Bäckereien','A1','city','noun','',''),
  ('Correo / Oficina de correos','Post','die','die Postämter','A1','city','noun','',''),
  ('Banco (entidad financiera)','Bank','die','die Banken','A1','city','noun','',''),
  ('Hotel','Hotel','das','die Hotels','A1','city','noun','',''),
  ('Restaurante','Restaurant','das','die Restaurants','A1','city','noun','',''),
  ('Café','Café','das','die Cafés','A1','city','noun','',''),
  ('Parque infantil','Spielplatz','der','die Spielplätze','A1','city','noun','',''),
  ('Piscina','Schwimmbad','das','die Schwimmbäder','A1','city','noun','',''),
  ('Policía','Polizei','die','die Polizeien*','A1','city','noun','',''),
  ('Bomberos','Feuerwehr','die','die Feuerwehren','A1','city','noun','',''),
  ('Aeropuerto','Flughafen','der','die Flughäfen','A1','city','noun','',''),
  ('Puerto','Hafen','der','die Häfen','A1','city','noun','','');

-- Usuario admin
INSERT INTO admin_users (username, password_hash, role, name)
VALUES ('admin', 'scrypt:32768:8:1$jlIq6q22ZUFhP2Ky$48417ea1800ffa5c0cc6e46ad206e8ecb852caccd5c5ebb2f9b3de22c47cb84e183eb104e662d0a7396fa7ed013c618920b4cc79cf975b96ecde9c9a18912ebf', 'root', 'Administrador')
ON CONFLICT (username) DO UPDATE SET password_hash = EXCLUDED.password_hash;

