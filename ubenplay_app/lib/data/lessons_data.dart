import '../models/lesson.dart';
import '../models/vocabulary_noun.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';

class VocabularyCategory {
  final String id, title, icon, description;
  final List<String> lessonIds;
  final CefrLevel level;
  const VocabularyCategory({required this.id, required this.title, required this.icon, required this.description, required this.lessonIds, this.level = CefrLevel.a1});
}

String _ic(int cat, int idx) => '${cat.toString().padLeft(3,"0")}${idx.toString().padLeft(7,"0")}';
int _w = 1;
CefrLevel _cl(String l) => l=="A1"?CefrLevel.a1:l=="A2"?CefrLevel.a2:l=="B1"?CefrLevel.b1:CefrLevel.b2;
VocabularyNoun _n(String es,String de,String art,String pl,String lv,String img,int cat,int idx)=>VocabularyNoun(wordId:_w++,spanish:es,german:de,article:art,plural:pl,cefrLevel:_cl(lv),image:img,imageCode:_ic(cat,idx));

class LessonsData {

  static int _typeFilterFor(String filterType) {
    return filterType == 'Sustantivos' ? 1
        : filterType == 'Verbos' ? 2
        : filterType == 'Adjetivos' ? 3
        : filterType == 'Conectores' ? 4
        : 0;
  }

  /// Icono de temática/lección según el tipo de palabra.
  /// Sustantivos conserva su icono (🍎…); verbos → acción, adjetivos → antónimo,
  /// conectores → enlace.
  static String _typeIcon(String filterType, String defaultIcon) {
    switch (filterType) {
      case 'Verbos': return '🤸';
      case 'Adjetivos': return '🎭';
      case 'Conectores': return '🔗';
      default: return defaultIcon; // Sustantivos
    }
  }

  /// Selecciona hasta `capacity` palabras de una lección según la posición `seqIndex`
  /// del juego dentro de la secuencia.
  /// - Juegos 1 y 2 (seq 0,1): misma primera tanda (complementario: el 2º repite el 1º
  ///   para recordar el artículo que acompaña al sustantivo).
  /// - Juegos 3+: rotan la ventana (con wrap) para cubrir TODAS las palabras.
  static List<VocabularyNoun> wordsForGame(List<VocabularyNoun> nouns, int seqIndex, int capacity) {
    final n = nouns.length;
    if (n == 0) return const [];
    if (capacity >= n) return List.of(nouns);
    if (seqIndex <= 1) return nouns.take(capacity).toList();
    final half = (n / 2).ceil();
    final start = seqIndex.isEven ? (n - capacity < half ? half : n - capacity) : 0;
    final selected = <VocabularyNoun>[];
    for (var i = 0; i < capacity; i++) {
      selected.add(nouns[(start + i) % n]);
    }
    return selected;
  }

  static List<VocabularyCategory> getCategories({CefrLevel? level, String filterType = 'Sustantivos'}) {
    final all = <VocabularyCategory>[];
    final typeFilter = _typeFilterFor(filterType);
    final meta = {
      'family': ['Familia','👨‍👩‍👧‍👦','Parentesco',CefrLevel.a1],
      'house': ['Casa','🏠','Hogar',CefrLevel.a1],
      'food': ['Comida','🍎','Alimentos',CefrLevel.a1],
      'transport': ['Transporte','🚗','Vehículos',CefrLevel.a1],
      'jobs': ['Oficios','👷','Profesiones',CefrLevel.a1],
      'travel': ['Viajes','✈️','Turismo',CefrLevel.a1],
      'city': ['Ciudad','🏙️','Lugares urbanos',CefrLevel.a1],
      'office': ['Oficina','🏢','Trabajo',CefrLevel.a2],
      'tech': ['Tecnología','💻','Digital',CefrLevel.a2],
      'health': ['Salud','💊','Medicina',CefrLevel.a2],
      'shopping': ['Compras','🛍️','Consumo',CefrLevel.a2],
      'city2': ['Lugares públicos','🏛️','Servicios',CefrLevel.a2],
      'timeplan': ['Tiempo','📅','Planificación',CefrLevel.a2],
      'animals': ['Animales','🐾','Fauna',CefrLevel.a1],
      'school': ['Educación','📚','Formación',CefrLevel.b1],
      'popular': ['General','📦','Vocabulario general',CefrLevel.b1],
    };
    for (final e in meta.entries) {
      // Buscar por ambas claves (inglés del meta, español de Supabase)
      var nouns = _nouns[e.key] ?? [];
      if (nouns.isEmpty) nouns = _nouns[e.value[0]] ?? [];
      if (nouns.isEmpty) continue;
      // Filtrar por tipo de palabra (sustantivo/verbo)
      if (typeFilter != 0) nouns = nouns.where((n) => n.wordType == typeFilter).toList();
      if (nouns.isEmpty) continue;
      final nl = nouns.length ~/ 10;
      final ids = List.generate(nl, (i) => '${e.key}-${i+1}');
      final lv = e.value[3] as CefrLevel;
      if (level == null || lv == level) {
        all.add(VocabularyCategory(id: e.key, title: e.value[0] as String, icon: _typeIcon(filterType, e.value[1] as String), description: e.value[2] as String, lessonIds: ids, level: lv));
      }
    }
    return all;
  }
  
  static CefrLevel _categoryLevel(String cat) {
    final words = _nouns[cat] ?? [];
    if (words.isEmpty) return CefrLevel.a1;
    final levels = words.map((w) => w.cefrLevel).toSet();
    if (levels.length == 1) return levels.first;
    return CefrLevel.a1;
  }
  static final Map<String, List<VocabularyNoun>> _nouns = {
    // A1 categories (110 each target)
    'family': [
      _n('madre','Mutter','die','Mütter','A1','👩',1,1),
      _n('padre','Vater','der','Väter','A1','👨',1,2),
      _n('hijo','Sohn','der','Söhne','A1','👦',1,3),
      _n('hija','Tochter','die','Töchter','A1','👧',1,4),
      _n('hermano','Bruder','der','Brüder','A1','👨',1,5),
      _n('hermana','Schwester','die','Schwestern','A1','👩',1,6),
      _n('abuelo','Großvater','der','Großväter','A1','👴',1,7),
      _n('abuela','Großmutter','die','Großmütter','A1','👵',1,8),
      _n('nieto','Enkel','der','Enkel','A1','👶',1,9),
      _n('tío','Onkel','der','Onkel','A1','👨',1,10),
      _n('tía','Tante','die','Tanten','A1','👩',1,100),
      _n('primo','Cousin','der','Cousins','A1','👦',1,101),
      _n('sobrino','Neffe','der','Neffen','A1','👦',1,102),
      _n('esposo','Ehemann','der','Ehemänner','A1','🤵',1,103),
      _n('esposa','Ehefrau','die','Ehefrauen','A1','👰',1,104),
      _n('pareja','Partner','der','Partner','A1','💑',1,105),
      _n('novio','Freund','der','Freunde','A1','💏',1,106),
      _n('bebé','Baby','das','Babys','A1','👶',1,107),
      _n('niño','Kind','das','Kinder','A1','🧒',1,108),
      _n('adulto','Erwachsener','der','Erwachsene','A1','🧑',1,109),
      _n('gemelos','Zwillinge','die','Zwillinge','A1','👯',1,110),
      _n('suegro','Schwiegervater','der','Schwiegerväter','A1','👴',1,111),
      _n('suegra','Schwiegermutter','die','Schwiegermütter','A1','👵',1,112),
      _n('cuñado','Schwager','der','Schwäger','A1','👨',1,113),
      _n('cuñada','Schwägerin','die','Schwägerinnen','A1','👩',1,114),
      _n('familia','Familie','die','Familien','A1','👨‍👩‍👧‍👦',1,115),
      _n('soltero','Single','der','Singles','A1','💔',1,116),
      _n('casado','Verheirateter','der','Verheiratete','A1','💍',1,117),
      _n('compromiso','Verlobung','die','Verlobungen','A1','💍',1,118),
      _n('boda','Hochzeit','die','Hochzeiten','A1','💒',1,119),
      _n('reloj','Uhr','die','Uhren','A1','🕐',2,100),
      _n('libro','Buch','das','Bücher','A1','📖',2,101),
      _n('alfombra','Teppich','der','Teppiche','A1','🟫',2,102),
      _n('armario','Schrank','der','Schränke','A1','🗄️',2,103),
      _n('ducha','Dusche','die','Duschen','A1','🚿',2,104),
      _n('techo','Decke','die','Decken','A1','⬜',2,105),
      _n('pared','Wand','die','Wände','A1','🧱',2,106),
      _n('tejado','Dach','das','Dächer','A1','🏠',2,107),
      _n('escalera','Treppe','die','Treppen','A1','🪜',2,108),
      _n('jardín','Garten','der','Gärten','A1','🏡',2,109),
      _n('garaje','Garage','die','Garagen','A1','🚗',2,110),
      _n('cortina','Vorhang','der','Vorhänge','A1','🪟',2,111),
      _n('almohada','Kissen','das','Kissen','A1','🛏️',2,112),
      _n('manta','Decke','die','Decken','A1','🛌',2,113),
      _n('toalla','Handtuch','das','Handtücher','A1','🛀',2,114),
      _n('nevera','Kühlschrank','der','Kühlschränke','A1','🧊',2,115),
      _n('horno','Ofen','der','Öfen','A1','🔥',2,116),
      _n('lavadora','Waschmaschine','die','Waschmaschinen','A1','🧺',2,117),
      _n('estantería','Regal','das','Regale','A1','📚',2,118),
      _n('llave','Schlüssel','der','Schlüssel','A1','🔑',2,119),
      _n('naranja','Orange','die','Orangen','A1','🍊',3,100),
      _n('uva','Traube','die','Trauben','A1','🍇',3,101),
      _n('fresa','Erdbeere','die','Erdbeeren','A1','🍓',3,102),
      _n('zanahoria','Karotte','die','Karotten','A1','🥕',3,103),
      _n('pastel','Kuchen','der','Kuchen','A1','🎂',3,104),
      _n('cerveza','Bier','das','Biere','A1','🍺',3,105),
      _n('carne','Fleisch','das','Fleischsorten','A1','🥩',3,106),
      _n('tomate','Tomate','die','Tomaten','A1','🍅',3,107),
      _n('cebolla','Zwiebel','die','Zwiebeln','A1','🧅',3,108),
      _n('papa','Kartoffel','die','Kartoffeln','A1','🥔',3,109),
      _n('sandía','Wassermelone','die','Wassermelonen','A1','🍉',3,110),
      _n('piña','Ananas','die','Ananas','A1','🍍',3,111),
      _n('cereza','Kirsche','die','Kirschen','A1','🍒',3,112),
      _n('limón','Zitrone','die','Zitronen','A1','🍋',3,113),
      _n('chocolate','Schokolade','die','Schokoladen','A1','🍫',3,114),
      _n('yogur','Joghurt','der','Joghurts','A1','🥛',3,115),
      _n('sopa','Suppe','die','Suppen','A1','🍜',3,116),
      _n('ensalada','Salat','der','Salate','A1','🥗',3,117),
      _n('pizza','Pizza','die','Pizzen','A1','🍕',3,118),
      _n('té','Tee','der','Tees','A1','🍵',3,119),
      _n('helicóptero','Hubschrauber','der','Hubschrauber','A1','🚁',4,100),
      _n('tranvía','Straßenbahn','die','Straßenbahnen','A1','🚋',4,101),
      _n('ferry','Fähre','die','Fähren','A1','⛴️',4,102),
      _n('ambulancia','Krankenwagen','der','Krankenwagen','A1','🚑',4,103),
      _n('semáforo','Ampel','die','Ampeln','A1','🚦',4,104),
      _n('gasolina','Benzin','das','Benzine','A1','⛽',4,105),
      _n('rueda','Rad','das','Räder','A1','🛞',4,106),
      _n('motor','Motor','der','Motoren','A1','⚙️',4,107),
      _n('aeropuerto','Flughafen','der','Flughäfen','A1','🛫',4,108),
      _n('estación','Bahnhof','der','Bahnhöfe','A1','🚉',4,109),
      _n('pasajero','Passagier','der','Passagiere','A1','🧳',4,110),
      _n('conductor','Fahrer','der','Fahrer','A1','🕴️',4,111),
      _n('casco','Helm','der','Helme','A1','🪖',4,112),
      _n('billete','Fahrkarte','die','Fahrkarten','A1','🎫',4,113),
      _n('equipaje','Gepäck','das','Gepäckstücke','A1','🧳',4,114),
      _n('autopista','Autobahn','die','Autobahnen','A1','🛣️',4,115),
      _n('tractor','Traktor','der','Traktoren','A1','🚜',4,116),
      _n('velero','Segelboot','das','Segelboote','A1','⛵',4,117),
      _n('patinete','Roller','der','Roller','A1','🛴',4,118),
      _n('monopatín','Skateboard','das','Skateboards','A1','🛹',4,119),
      _n('ingeniero','Ingenieur','der','Ingenieure','A1','👷',5,100),
      _n('mecánico','Mechaniker','der','Mechaniker','A1','🔧',5,101),
      _n('carpintero','Tischler','der','Tischler','A1','🪚',5,102),
      _n('pintor','Maler','der','Maler','A1','🎨',5,103),
      _n('pescador','Fischer','der','Fischer','A1','🎣',5,104),
      _n('piloto','Pilot','der','Piloten','A1','✈️',5,105),
      _n('periodista','Journalist','der','Journalisten','A1','📰',5,106),
      _n('escritor','Schriftsteller','der','Schriftsteller','A1','✍️',5,107),
      _n('músico','Musiker','der','Musiker','A1','🎵',5,108),
      _n('cantante','Sänger','der','Sänger','A1','🎤',5,109),
      _n('actor','Schauspieler','der','Schauspieler','A1','🎭',5,110),
      _n('científico','Wissenschaftler','der','Wissenschaftler','A1','🔬',5,111),
      _n('programador','Programmierer','der','Programmierer','A1','👨‍💻',5,112),
      _n('fotógrafo','Fotograf','der','Fotografen','A1','📷',5,113),
      _n('cajero','Kassierer','der','Kassierer','A1','💰',5,114),
      _n('secretario','Sekretär','der','Sekretäre','A1','💼',5,115),
      _n('director','Direktor','der','Direktoren','A1','👨‍💼',5,116),
      _n('soldado','Soldat','der','Soldaten','A1','🪖',5,117),
      _n('dentista','Zahnarzt','der','Zahnärzte','A1','🦷',5,118),
      _n('veterinario','Tierarzt','der','Tierärzte','A1','🐾',5,119),
      _n('reserva','Reservierung','die','Reservierungen','A1','📋',6,100),
      _n('visado','Visum','das','Visa','A1','📄',6,101),
      _n('aduana','Zoll','der','Zollämter','A1','🛃',6,102),
      _n('mapa','Landkarte','die','Landkarten','A1','🗺️',6,103),
      _n('recuerdo','Souvenir','das','Souvenirs','A1','🎁',6,104),
      _n('postal','Postkarte','die','Postkarten','A1','💌',6,105),
      _n('excursión','Ausflug','der','Ausflüge','A1','🚶',6,106),
      _n('senderismo','Wandern','das','Wanderungen','A1','🥾',6,107),
      _n('camping','Camping','das','Campingplätze','A1','🏕️',6,108),
      _n('albergue','Herberge','die','Herbergen','A1','🏚️',6,109),
      _n('itinerario','Reiseplan','der','Reisepläne','A1','📋',6,110),
      _n('mostrador','Schalter','der','Schalter','A1','🛫',6,111),
      _n('azafata','Flugbegleiterin','die','Flugbegleiterinnen','A1','👩‍✈️',6,112),
      _n('aventura','Abenteuer','das','Abenteuer','A1','🗺️',6,113),
      _n('folleto','Prospekt','der','Prospekte','A1','📃',6,114),
      _n('hostal','Pension','die','Pensionen','A1','🏨',6,115),
      _n('retraso','Verspätung','die','Verspätungen','A1','⏰',6,116),
      _n('guía turístico','Reiseführer','der','Reiseführer','A1','📖',6,117),
      _n('esquí','Ski','der','Skier','A1','⛷️',6,118),
      _n('mochila','Rucksack','der','Rucksäcke','A1','🎒',6,119),
      _n('farmacia','Apotheke','die','Apotheken','A1','💊',7,100),
      _n('correos','Post','die','Postämter','A1','📮',7,101),
      _n('ayuntamiento','Rathaus','das','Rathäuser','A1','🏛️',7,102),
      _n('teatro','Theater','das','Theater','A1','🎭',7,103),
      _n('museo','Museum','das','Museen','A1','🏛️',7,104),
      _n('plaza','Platz','der','Plätze','A1','⛲',7,105),
      _n('fuente','Brunnen','der','Brunnen','A1','⛲',7,106),
      _n('estatua','Statue','die','Statuen','A1','🗽',7,107),
      _n('apartamento','Wohnung','die','Wohnungen','A1','🏢',7,108),
      _n('fábrica','Fabrik','die','Fabriken','A1','🏭',7,109),
      _n('mercado','Markt','der','Märkte','A1','🏪',7,110),
      _n('cementerio','Friedhof','der','Friedhöfe','A1','🪦',7,111),
      _n('estadio','Stadion','das','Stadien','A1','🏟️',7,112),
      _n('zoo','Zoo','der','Zoos','A1','🦁',7,113),
      _n('gasolinera','Tankstelle','die','Tankstellen','A1','⛽',7,114),
      _n('aparcamiento','Parkplatz','der','Parkplätze','A1','🅿️',7,115),
      _n('monumento','Denkmal','das','Denkmäler','A1','🏛️',7,116),
      _n('barrio','Viertel','das','Viertel','A1','🏘️',7,117),
      _n('centro','Zentrum','das','Zentren','A1','🎯',7,118),
      _n('pueblo','Dorf','das','Dörfer','A1','🏘️',7,119),
      _n('grapadora','Heftgerät','das','Heftgeräte','A2','📎',8,100),
      _n('documento','Dokument','das','Dokumente','A2','📋',8,101),
      _n('fotocopiadora','Kopierer','der','Kopierer','A2','🖨️',8,102),
      _n('agenda','Terminplaner','der','Terminplaner','A2','📒',8,103),
      _n('marcador','Marker','der','Marker','A2','🖍️',8,104),
      _n('proyector','Projektor','der','Projektoren','A2','📽️',8,105),
      _n('portátil','Laptop','der','Laptops','A2','💻',8,106),
      _n('auriculares','Headset','das','Headsets','A2','🎧',8,107),
      _n('taza','Tasse','die','Tassen','A2','☕',8,108),
      _n('papelera','Papierkorb','der','Papierkörbe','A2','🗑️',8,109),
      _n('sobre','Umschlag','der','Umschläge','A2','✉️',8,110),
      _n('sello','Stempel','der','Stempel','A2','🕹️',8,111),
      _n('contrato','Vertrag','der','Verträge','A2','📝',8,112),
      _n('factura','Rechnung','die','Rechnungen','A2','🧾',8,113),
      _n('cliente','Kunde','der','Kunden','A2','🤝',8,114),
      _n('colega','Kollege','der','Kollegen','A2','👥',8,115),
      _n('jefe','Chef','der','Chefs','A2','👨‍💼',8,116),
      _n('becario','Praktikant','der','Praktikanten','A2','🧑‍🎓',8,117),
      _n('currículum','Lebenslauf','der','Lebensläufe','A2','📄',8,118),
      _n('carta','Brief','der','Briefe','A2','✉️',8,119),
      _n('tableta','Tablet','das','Tablets','A2','📱',9,100),
      _n('robot','Roboter','der','Roboter','A2','🤖',9,101),
      _n('satélite','Satellit','der','Satelliten','A2','🛰️',9,102),
      _n('cable','Kabel','das','Kabel','A2','🔌',9,103),
      _n('archivo','Datei','die','Dateien','A2','📄',9,104),
      _n('software','Software','die','Softwares','A2','💿',9,105),
      _n('servidor','Server','der','Server','A2','🖧',9,106),
      _n('red','Netzwerk','das','Netzwerke','A2','🌐',9,107),
      _n('videojuego','Videospiel','das','Videospiele','A2','🎮',9,108),
      _n('dron','Drohne','die','Drohnen','A2','🛸',9,109),
      _n('USB','USB-Stick','der','USB-Sticks','A2','💾',9,110),
      _n('disco duro','Festplatte','die','Festplatten','A2','💽',9,111),
      _n('escáner','Scanner','der','Scanner','A2','📡',9,112),
      _n('antena','Antenne','die','Antennen','A2','📡',9,113),
      _n('virus','Virus','der','Viren','A2','🦠',9,114),
      _n('consola','Konsole','die','Konsolen','A2','🕹️',9,115),
      _n('cargador','Ladegerät','das','Ladegeräte','A2','🔌',9,116),
      _n('pantalla','Bildschirm','der','Bildschirme','A2','🖥️',9,117),
      _n('altavoz','Lautsprecher','der','Lautsprecher','A2','🔊',9,118),
      _n('micrófono','Mikrofon','das','Mikrofone','A2','🎤',9,119),
      _n('cirugía','Operation','die','Operationen','A2','🏥',10,100),
      _n('receta','Rezept','das','Rezepte','A2','📋',10,101),
      _n('síntoma','Symptom','das','Symptome','A2','🤒',10,102),
      _n('alergia','Allergie','die','Allergien','A2','🤧',10,103),
      _n('herida','Wunde','die','Wunden','A2','🩹',10,104),
      _n('vendaje','Verband','der','Verbände','A2','🩹',10,105),
      _n('ambulancia','Krankenwagen','der','Krankenwagen','A2','🚑',10,106),
      _n('termómetro','Thermometer','das','Thermometer','A2','🌡️',10,107),
      _n('análisis','Test','der','Tests','A2','🧪',10,108),
      _n('tratamiento','Behandlung','die','Behandlungen','A2','🩺',10,109),
      _n('fractura','Bruch','der','Brüche','A2','🦴',10,110),
      _n('emergencia','Notfall','der','Notfälle','A2','🆘',10,111),
      _n('clínica','Klinik','die','Kliniken','A2','🏥',10,112),
      _n('prevención','Vorbeugung','die','Vorbeugungen','A2','🛡️',10,113),
      _n('recuperación','Genesung','die','Genesungen','A2','💪',10,114),
      _n('estrés','Stress','der','Stresse','A2','😫',10,115),
      _n('nutrición','Ernährung','die','Ernährungen','A2','🥗',10,116),
      _n('ejercicio','Bewegung','die','Bewegungen','A2','🏃',10,117),
      _n('presión arterial','Blutdruck','der','Blutdrücke','A2','🩺',10,118),
      _n('primeros auxilios','Erste Hilfe','die','Erste Hilfen','A2','🩹',10,119),
      _n('oferta','Angebot','das','Angebote','A2','📢',11,100),
      _n('devolución','Rückgabe','die','Rückgaben','A2','↩️',11,101),
      _n('calidad','Qualität','die','Qualitäten','A2','⭐',11,102),
      _n('probador','Umkleidekabine','die','Umkleidekabinen','A2','👚',11,103),
      _n('catálogo','Katalog','der','Kataloge','A2','📖',11,104),
      _n('pedido','Bestellung','die','Bestellungen','A2','📦',11,105),
      _n('envío','Lieferung','die','Lieferungen','A2','🚚',11,106),
      _n('publicidad','Werbung','die','Werbungen','A2','📢',11,107),
      _n('cesta','Korb','der','Körbe','A2','🧺',11,108),
      _n('escaparate','Schaufenster','das','Schaufenster','A2','🪟',11,109),
      _n('vendedor','Verkäufer','der','Verkäufer','A2','🛍️',11,110),
      _n('consumidor','Verbraucher','der','Verbraucher','A2','🙋',11,111),
      _n('suscripción','Abonnement','das','Abonnements','A2','🔄',11,112),
      _n('IVA','Mehrwertsteuer','die','Mehrwertsteuern','A2','🧾',11,113),
      _n('compras online','Online-Shopping','das','Online-Shoppings','A2','💻',11,114),
      _n('mercado','Markt','der','Märkte','A2','🏪',11,115),
      _n('feria','Messe','die','Messen','A2','🎪',11,116),
      _n('catálogo','Katalog','der','Kataloge','A2','📖',11,117),
      _n('escaparate','Schaufenster','das','Schaufenster','A2','🪟',11,118),
      _n('probador','Umkleidekabine','die','Umkleidekabinen','A2','👚',11,119),
      _n('fuente','Brunnen','der','Brunnen','A2','⛲',12,100),
      _n('estatua','Statue','die','Statuen','A2','🗽',12,101),
      _n('rascacielos','Wolkenkratzer','der','Wolkenkratzer','A2','🏢',12,102),
      _n('embajada','Botschaft','die','Botschaften','A2','🏢',12,103),
      _n('capital','Hauptstadt','die','Hauptstädte','A2','🏙️',12,104),
      _n('edificio','Gebäude','das','Gebäude','A2','🏢',12,105),
      _n('librería','Buchhandlung','die','Buchhandlungen','A2','📚',12,106),
      _n('panadería','Bäckerei','die','Bäckereien','A2','🥖',12,107),
      _n('carnicería','Metzgerei','die','Metzgereien','A2','🥩',12,108),
      _n('aduana','Zoll','der','Zollämter','A2','🛃',12,109),
      _n('paso cebra','Zebrastreifen','der','Zebrastreifen','A2','🦓',12,110),
      _n('distrito','Bezirk','der','Bezirke','A2','🗺️',12,111),
      _n('afueras','Vorort','der','Vororte','A2','🏡',12,112),
      _n('comercio','Geschäft','das','Geschäfte','A2','🛍️',12,113),
      _n('juguetería','Spielzeugladen','der','Spielzeugläden','A2','🧸',12,114),
      _n('gasolinera','Tankstelle','die','Tankstellen','A2','⛽',12,115),
      _n('aparcamiento','Parkplatz','der','Parkplätze','A2','🅿️',12,116),
      _n('zoo','Zoo','der','Zoos','A2','🦁',12,117),
      _n('oficina correos','Postamt','das','Postämter','A2','🏤',12,118),
      _n('centro comercial','Einkaufszentrum','das','Einkaufszentren','A2','🏬',12,119),
      _n('recordatorio','Erinnerung','die','Erinnerungen','A2','🔔',13,100),
      _n('rutina','Routine','die','Routinen','A2','🔄',13,101),
      _n('hábito','Gewohnheit','die','Gewohnheiten','A2','🔁',13,102),
      _n('puntualidad','Pünktlichkeit','die','Pünktlichkeiten','A2','⏰',13,103),
      _n('retraso','Verspätung','die','Verspätungen','A2','😰',13,104),
      _n('año','Jahr','das','Jahre','A2','📅',13,105),
      _n('década','Jahrzehnt','das','Jahrzehnte','A2','📅',13,106),
      _n('siglo','Jahrhundert','das','Jahrhunderte','A2','📅',13,107),
      _n('madrugada','Morgen','der','Morgen','A2','🌅',13,108),
      _n('mediodía','Mittag','der','Mittage','A2','☀️',13,109),
      _n('tarde','Nachmittag','der','Nachmittage','A2','🌤️',13,110),
      _n('noche','Nacht','die','Nächte','A2','🌙',13,111),
      _n('lista','Liste','die','Listen','A2','📝',13,112),
      _n('horario','Zeitplan','der','Zeitpläne','A2','🕐',13,113),
      _n('rutina','Routine','die','Routinen','A2','🔄',13,114),
      _n('recordatorio','Erinnerung','die','Erinnerungen','A2','🔔',13,115),
      _n('hábito','Gewohnheit','die','Gewohnheiten','A2','🔁',13,116),
      _n('mediodía','Mittag','der','Mittage','A2','☀️',13,117),
      _n('tarde','Nachmittag','der','Nachmittage','A2','🌤️',13,118),
      _n('noche','Nacht','die','Nächte','A2','🌙',13,119),
    ],
    'house': [
      _n('puerta','Tür','die','Türen','A1','🚪',2,1),
      _n('ventana','Fenster','das','Fenster','A1','🪟',2,2),
      _n('mesa','Tisch','der','Tische','A1','🪑',2,3),
      _n('silla','Stuhl','der','Stühle','A1','🪑',2,4),
      _n('cama','Bett','das','Betten','A1','🛏️',2,5),
      _n('cocina','Küche','die','Küchen','A1','🍳',2,6),
      _n('baño','Badezimmer','das','Badezimmer','A1','🛁',2,7),
      _n('lámpara','Lampe','die','Lampen','A1','💡',2,8),
      _n('sofá','Sofa','das','Sofas','A1','🛋️',2,9),
      _n('espejo','Spiegel','der','Spiegel','A1','🪞',2,10),
    ],
    'food': [
      _n('manzana','Apfel','der','Äpfel','A1','🍎',3,1),
      _n('plátano','Banane','die','Bananen','A1','🍌',3,2),
      _n('pan','Brot','das','Brote','A1','🍞',3,3),
      _n('queso','Käse','der','Käse','A1','🧀',3,4),
      _n('huevo','Ei','das','Eier','A1','🥚',3,5),
      _n('arroz','Reis','der','Reissorten','A1','🍚',3,6),
      _n('pollo','Hähnchen','das','Hähnchen','A1','🍗',3,7),
      _n('agua','Wasser','das','Wasser','A1','💧',3,8),
      _n('leche','Milch','die','Milche','A1','🥛',3,9),
      _n('café','Kaffee','der','Kaffees','A1','☕',3,10),
    ],
    'transport': [
      _n('coche','Auto','das','Autos','A1','🚗',4,1),
      _n('autobús','Bus','der','Busse','A1','🚌',4,2),
      _n('tren','Zug','der','Züge','A1','🚂',4,3),
      _n('avión','Flugzeug','das','Flugzeuge','A1','✈️',4,4),
      _n('bicicleta','Fahrrad','das','Fahrräder','A1','🚲',4,5),
      _n('barco','Schiff','das','Schiffe','A1','🚢',4,6),
      _n('moto','Motorrad','das','Motorräder','A1','🏍️',4,7),
      _n('taxi','Taxi','das','Taxis','A1','🚕',4,8),
      _n('metro','U-Bahn','die','U-Bahnen','A1','🚇',4,9),
      _n('camión','Lastwagen','der','Lastwagen','A1','🚛',4,10),
    ],
    'jobs': [
      _n('médico','Arzt','der','Ärzte','A1','👨‍⚕️',5,1),
      _n('enfermera','Krankenschwester','die','Krankenschwestern','A1','👩‍⚕️',5,2),
      _n('profesor','Lehrer','der','Lehrer','A1','👨‍🏫',5,3),
      _n('policía','Polizist','der','Polizisten','A1','👮',5,4),
      _n('bombero','Feuerwehrmann','der','Feuerwehrmänner','A1','👨‍🚒',5,5),
      _n('cocinero','Koch','der','Köche','A1','👨‍🍳',5,6),
      _n('camarero','Kellner','der','Kellner','A1','🤵',5,7),
      _n('agricultor','Bauer','der','Bauern','A1','👨‍🌾',5,8),
      _n('conductor','Fahrer','der','Fahrer','A1','🚗',5,9),
      _n('vendedor','Verkäufer','der','Verkäufer','A1','🛍️',5,10),
    ],
    'travel': [
      _n('viaje','Reise','die','Reisen','A1','🧳',6,1),
      _n('hotel','Hotel','das','Hotels','A1','🏨',6,2),
      _n('pasaporte','Reisepass','der','Reisepässe','A1','🛂',6,3),
      _n('maleta','Koffer','der','Koffer','A1','🧳',6,4),
      _n('playa','Strand','der','Strände','A1','🏖️',6,5),
      _n('aeropuerto','Flughafen','der','Flughäfen','A1','🛫',6,6),
      _n('vuelo','Flug','der','Flüge','A1','✈️',6,7),
      _n('turista','Tourist','der','Touristen','A1','📸',6,8),
      _n('piscina','Pool','der','Pools','A1','🏊',6,9),
      _n('habitación','Zimmer','das','Zimmer','A1','🛏️',6,10),
    ],
    'city': [
      _n('hospital','Krankenhaus','das','Krankenhäuser','A1','🏥',7,1),
      _n('restaurante','Restaurant','das','Restaurants','A1','🍽️',7,2),
      _n('tienda','Laden','der','Läden','A1','🏪',7,3),
      _n('banco','Bank','die','Banken','A1','🏦',7,4),
      _n('parque','Park','der','Parks','A1','🏞️',7,5),
      _n('calle','Straße','die','Straßen','A1','🛣️',7,6),
      _n('iglesia','Kirche','die','Kirchen','A1','⛪',7,7),
      _n('supermercado','Supermarkt','der','Supermärkte','A1','🛒',7,8),
      _n('cine','Kino','das','Kinos','A1','🎬',7,9),
      _n('hotel','Hotel','das','Hotels','A1','🏨',7,10),
    ],
    // A2 categories (110 each target)
    'office': [
      _n('oficina','Büro','das','Büros','A2','🏢',8,1),
      _n('escritorio','Schreibtisch','der','Schreibtische','A2','🪑',8,2),
      _n('ordenador','Rechner','der','Rechner','A2','💻',8,3),
      _n('impresora','Drucker','der','Drucker','A2','🖨️',8,4),
      _n('papel','Papier','das','Papiere','A2','📄',8,5),
      _n('carpeta','Ordner','der','Ordner','A2','📁',8,6),
      _n('reunión','Besprechung','die','Besprechungen','A2','👥',8,7),
      _n('informe','Bericht','der','Berichte','A2','📊',8,8),
      _n('calendario','Kalender','der','Kalender','A2','📅',8,9),
      _n('tijeras','Schere','die','Scheren','A2','✂️',8,10),
    ],
    'tech': [
      _n('teléfono','Telefon','das','Telefone','A2','📱',9,1),
      _n('computadora','Computer','der','Computer','A2','💻',9,2),
      _n('cámara','Kamera','die','Kameras','A2','📷',9,3),
      _n('televisor','Fernseher','der','Fernseher','A2','📺',9,4),
      _n('internet','Internet','das','Internets','A2','🌐',9,5),
      _n('wifi','WLAN','das','WLANs','A2','📶',9,6),
      _n('aplicación','App','die','Apps','A2','📲',9,7),
      _n('correo','E-Mail','die','E-Mails','A2','📧',9,8),
      _n('mensaje','Nachricht','die','Nachrichten','A2','💬',9,9),
      _n('contraseña','Passwort','das','Passwörter','A2','🔑',9,10),
    ],
    'health': [
      _n('hospital','Krankenhaus','das','Krankenhäuser','A2','🏥',10,1),
      _n('medicina','Medizin','die','Medizinen','A2','💊',10,2),
      _n('pastilla','Tablette','die','Tabletten','A2','💊',10,3),
      _n('farmacia','Apotheke','die','Apotheken','A2','💊',10,4),
      _n('dolor','Schmerz','der','Schmerzen','A2','😣',10,5),
      _n('fiebre','Fieber','das','Fieber','A2','🌡️',10,6),
      _n('gripe','Grippe','die','Grippen','A2','🤧',10,7),
      _n('resfriado','Erkältung','die','Erkältungen','A2','🤒',10,8),
      _n('paciente','Patient','der','Patienten','A2','🛌',10,9),
      _n('vacuna','Impfstoff','der','Impfstoffe','A2','💉',10,10),
    ],
    'shopping': [
      _n('precio','Preis','der','Preise','A2','🏷️',11,1),
      _n('descuento','Rabatt','der','Rabatte','A2','🔖',11,2),
      _n('recibo','Quittung','die','Quittungen','A2','🧾',11,3),
      _n('cliente','Kunde','der','Kunden','A2','🤝',11,4),
      _n('producto','Produkt','das','Produkte','A2','📦',11,5),
      _n('talla','Größe','die','Größen','A2','📏',11,6),
      _n('carrito','Einkaufswagen','der','Einkaufswagen','A2','🛒',11,7),
      _n('bolsa','Tüte','die','Tüten','A2','🛍️',11,8),
      _n('marca','Marke','die','Marken','A2','™️',11,9),
      _n('garantía','Garantie','die','Garantien','A2','🛡️',11,10),
    ],
    'city2': [
      _n('museo','Museum','das','Museen','A2','🏛️',12,1),
      _n('teatro','Theater','das','Theater','A2','🎭',12,2),
      _n('biblioteca','Bibliothek','die','Bibliotheken','A2','📚',12,3),
      _n('correos','Post','die','Postämter','A2','📮',12,4),
      _n('comisaría','Polizeiwache','die','Polizeiwachen','A2','🚔',12,5),
      _n('ayuntamiento','Rathaus','das','Rathäuser','A2','🏛️',12,6),
      _n('estadio','Stadion','das','Stadien','A2','🏟️',12,7),
      _n('cementerio','Friedhof','der','Friedhöfe','A2','🪦',12,8),
      _n('monumento','Denkmal','das','Denkmäler','A2','🏛️',12,9),
      _n('plaza','Platz','der','Plätze','A2','⛲',12,10),
    ],
    'timeplan': [
      _n('calendario','Kalender','der','Kalender','A2','📅',13,1),
      _n('agenda','Terminplaner','der','Terminplaner','A2','📒',13,2),
      _n('cita','Termin','der','Termine','A2','📌',13,3),
      _n('plazo','Frist','die','Fristen','A2','⏰',13,4),
      _n('alarma','Wecker','der','Wecker','A2','⏰',13,5),
      _n('plan','Plan','der','Pläne','A2','📋',13,6),
      _n('objetivo','Ziel','das','Ziele','A2','🎯',13,7),
      _n('tarea','Aufgabe','die','Aufgaben','A2','✅',13,8),
      _n('semana','Woche','die','Wochen','A2','📅',13,9),
      _n('mes','Monat','der','Monate','A2','📅',13,10),
    ],
    // B1/B2 (empty for phase 2)
    'work': [],
    'finance': [],
    'government': [],
    'media': [],
    'culture': [],
    'feelings': [],
    'personality': [],
    'communication': [],
    'verbsnoun': [],
    'popular': [],
    'school': [],
    'society2': [],
    'govservices': [],
    'environment': [],
    'society': [],
    'economy': [],
    'law': [],
    'taet': [],
  };

  static List<Lesson> getLessons({CefrLevel? level, String filterType = ''}) {
    final lessons = <Lesson>[];
    final typeFilter = _typeFilterFor(filterType);
    final cats = getCategories(level: level, filterType: filterType);
    for (final cat in cats) {
      var nouns = _nouns[cat.id] ?? [];
      if (nouns.isEmpty) nouns = _nouns[cat.title] ?? [];
      if (nouns.isEmpty) continue;
      // Filtrar por tipo
      if (typeFilter != 0) nouns = nouns.where((n) => n.wordType == typeFilter).toList();
      if (nouns.isEmpty) continue;
      const wpl = 10;
      final total = nouns.length;
      final nl = total ~/ wpl; // lecciones completas de 10; resto queda pendiente
      int start = 0;
      for (int i = 0; i < nl; i++) {
        final chunk = nouns.sublist(start, start + wpl);
        start += wpl;
        final suffix = nl > 1 ? ' ${i+1}/$nl' : '';
        lessons.add(Lesson(id: '${cat.id}-${i+1}', title: '${cat.title}$suffix', description: chunk.map((n) => n.spanish).join(', '), difficulty: LessonDifficulty.beginner, icon: chunk.first.image, nouns: chunk));
      }
    }
    return lessons;
  }
  
  static const _nameMap = {'family':'Familia','house':'Casa','food':'Comida','transport':'Transporte',
    'jobs':'Oficios','travel':'Viajes','city':'Ciudad','office':'Oficina','tech':'Tecnología',
    'health':'Salud','shopping':'Compras','city2':'Lugares','timeplan':'Tiempo',
    'animals':'Animales','school':'Educación','weather':'Clima','personality':'Personalidad'};

  static Lesson? getLessonById(String id) {
    try { return getLessons().firstWhere((l) => l.id == id); } catch (_) { return null; }
  }

  static double levelProgress(CefrLevel level, Set<String> completed) {
    final cats = getCategories(level: level);
    if (cats.isEmpty) return 0;
    int t = 0, d = 0;
    for (final c in cats) { for (final lid in c.lessonIds) { t++; if (completed.contains(lid)) d++; } }
    return t > 0 ? d / t : 0;
  }

  /// Acceso a los datos para migración
  static Map<String, List<VocabularyNoun>> get allNouns => Map.unmodifiable(_nouns);

  /// Migrar datos hardcoded a la base de datos SQLite
  static Future<void> migrateToDatabase() async {
    for (final entry in _nouns.entries) {
      if (entry.value.isNotEmpty) {
        final rows = entry.value.map((n) => {
          'category_id': entry.key,
          'spanish': n.spanish, 'german': n.german,
          'article': n.article, 'plural': n.plural,
          'cefr_level': n.cefrLevel.name, 'image': n.image,
          'image_code': n.imageCode,
        }).toList();
        await DatabaseService.importFromExcel(
          rows.map((r) => r.map((k, v) => MapEntry(k, v.toString())).cast<String, String>()).toList(),
          entry.key,
        );
      }
    }
  }

  /// Recargar _nouns desde la base de datos local
  static Future<void> reloadFromDatabase() async {
    final dbData = await DatabaseService.getAllGrouped();
    _nouns.clear();
    _nouns.addAll(dbData);
  }

  /// Recargar _nouns desde Supabase
  static Future<void> reloadFromSupabase() async {
    final dbData = await SupabaseService.fetchAllGrouped();
    _nouns.clear();
    _nouns.addAll(dbData);
  }
}