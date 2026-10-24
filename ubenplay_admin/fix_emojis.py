#!/usr/bin/env python3
"""Asigna emojis significativos a verbos (id_categoria=2) y adjetivos (id_categoria=3)
que quedaron con el emoji por defecto '📦' tras la carga batch. Actualiza SQLite + Supabase."""
import sqlite3, json, urllib.request, urllib.parse

SS = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

VERBOS = {
    'abbiegen': '↩️', 'abfahren': '🚌', 'abholen': '🧺', 'anbieten': '🤝',
    'anfangen': '▶️', 'ankommen': '🏁', 'anrufen': '📞', 'anschauen': '👀',
    'antworten': '💬', 'arbeiten': '💼', 'aufbewahren': '🗄️', 'aufhören': '⏹️',
    'aufräumen': '🧹', 'aufstehen': '🌅', 'ausräumen': '📤', 'ausschalten': '🔌',
    'aussteigen': '🚶', 'backen': '🍞', 'behalten': '💾', 'benutzen': '🛠️',
    'bestellen': '🛎️', 'besuchen': '🏛️', 'betreten': '🚪', 'bezahlen': '💳',
    'bleiben': '📍', 'braten': '🍳', 'brauchen': '❗', 'bringen': '🎁',
    'dazugeben': '➕', 'decken': '🍽️', 'einladen': '💌', 'einschalten': '💡',
    'einsteigen': '🚌', 'erklären': '📖', 'erwarten': '⏳', 'erwärmen': '🔥',
    'essen': '🍽️', 'fahren': '🚗', 'finden': '🔍', 'folgen': '👣',
    'fotografieren': '📷', 'fragen': '❓', 'frühstücken': '🥐', 'füllen': '🫗',
    'geben': '🎁', 'gehen': '🚶', 'genießen': '😊', 'greifen': '✊',
    'grillen': '🍖', 'hacken': '🔪', 'halten': '✋', 'heißen': '🏷️',
    'helfen': '🤝', 'hinaufgehen': '⬆️', 'hineingehen': '🚪', 'hinuntergehen': '⬇️',
    'hinzufügen': '➕', 'kaufen': '🛒', 'kennen': '🤝', 'kneten': '🥣',
    'kochen': '🍲', 'kommen': '🚶', 'kosten': '💰', 'kühlen': '❄️',
    'laufen': '🏃', 'leeren': '🫙', 'legen': '📍', 'lenken': '🚗',
    'lernen': '📚', 'lesen': '📖', 'mieten': '🔑', 'mischen': '🥄',
    'mitnehmen': '🎒', 'mögen': '❤️', 'nehmen': '✋', 'parken': '🅿️',
    'pressen': '🍋', 'probieren': '👅', 'putzen': '🧹', 'reservieren': '📅',
    'riechen': '👃', 'rühren': '🥣', 'schlagen': '🥚', 'schließen': '🔒',
    'schmecken': '👅', 'schmelzen': '🧊', 'schneiden': '🔪', 'schreiben': '✍️',
    'schälen': '🥔', 'sehen': '👀', 'servieren': '🍽️', 'sich bedienen': '🍽️',
    'sich setzen': '🪑', 'sitzen': '🪑', 'spazieren': '🚶', 'sprechen': '🗣️',
    'spülen': '🧽', 'stellen': '📍', 'suchen': '🔍', 'teilen': '🤝',
    'toasten': '🍞', 'tragen': '🎒', 'trinken': '🥤', 'trocknen': '☀️',
    'tun': '⚙️', 'verkaufen': '🏷️', 'verlieren': '😞', 'verstehen': '💡',
    'vorbereiten': '📋', 'warten': '⏳', 'waschen': '🧼', 'wechseln': '🔁',
    'wegnehmen': '➖', 'wiederfinden': '🔍', 'wiegen': '⚖️', 'wissen': '🧠',
    'wohnen': '🏠', 'wollen': '💭', 'wählen': '✅', 'zahlen': '💵',
    'zeigen': '👉', 'zerkleinern': '🔪', 'zu Abend essen': '🌙', 'zu Mittag essen': '🥪',
    'zurückbringen': '↩️', 'öffnen': '🔓', 'überqueren': '🚸',
}

ADJETIVOS = {
    'abgesagt': '❌', 'alt': '👴', 'angenehm': '😊', 'anstrengend': '😫',
    'aufregend': '🎢', 'ausgeruht': '😌', 'ausländisch': '🌍', 'bequem': '🛋️',
    'bereit': '✅', 'berühmt': '⭐', 'besetzt': '🪑', 'billig': '💸',
    'biologisch': '🌱', 'bitter': '☕', 'breit': '↔️', 'cremig': '🥛',
    'direkt': '➡️', 'dunkel': '🌑', 'durstig': '🥤', 'einfach': '✅',
    'eng': '🚪', 'entspannend': '🧘', 'essbar': '🍽️', 'falsch': '❌',
    'fertig': '✅', 'frei': '🕊️', 'freundlich': '😊', 'frisch': '🌿',
    'früh': '🌅', 'gebacken': '🍞', 'gebraten': '🍳', 'gefährlich': '⚠️',
    'gegrillt': '🍖', 'gekocht': '🍲', 'genug': '✅', 'geschlossen': '🔒',
    'gesund': '🥗', 'groß': '🐘', 'gut': '👍', 'günstig': '💸',
    'hart': '🪨', 'hausgemacht': '🏠', 'heiß': '🔥', 'hell': '💡',
    'hilfsbereit': '🤝', 'hoch': '⬆️', 'hungrig': '😋', 'hässlich': '🙁',
    'indirekt': '🔀', 'interessant': '🤔', 'international': '🌍', 'kalt': '❄️',
    'klein': '🐜', 'knusprig': '🍪', 'komfortabel': '🛋️', 'kostenlos': '🆓',
    'kurz': '✂️', 'lang': '📏', 'langsam': '🐢', 'langweilig': '🥱',
    'laut': '📢', 'lecker': '😋', 'leer': '🫙', 'leicht': '🪶',
    'lokal': '📍', 'mild': '🌤️', 'modern': '✨', 'möglich': '✅',
    'müde': '😴', 'nah': '📍', 'nahrhaft': '🥗', 'national': '🏳️',
    'natürlich': '🌿', 'neu': '✨', 'niedrig': '⬇️', 'notwendig': '❗',
    'offen': '🔓', 'praktisch': '🛠️', 'privat': '🔒', 'pünktlich': '⏰',
    'reichhaltig': '🍽️', 'reserviert': '📅', 'richtig': '✅', 'roh': '🥩',
    'ruhig': '😌', 'saftig': '🍉', 'salzig': '🧂', 'satt': '😋',
    'sauber': '✨', 'sauer': '🍋', 'scharf': '🌶️', 'schlecht': '👎',
    'schmackhaft': '😋', 'schmutzig': '🧹', 'schnell': '⚡', 'schwer': '🏋️',
    'schwierig': '🤔', 'schön': '🌸', 'sicher': '🔒', 'spät': '🌙',
    'stark': '💪', 'süß': '🍬', 'teuer': '💰', 'touristisch': '🗺️',
    'traditionell': '🏛️', 'trocken': '🏜️', 'unangenehm': '🙁', 'unbekannt': '❓',
    'unbequem': '😖', 'ungesund': '🍔', 'unmöglich': '⛔', 'unpünktlich': '⏰',
    'unvergesslich': '🌟', 'vegan': '🥬', 'vegetarisch': '🥗', 'verfügbar': '✅',
    'verloren': '🧭', 'verspätet': '⏰', 'viel': '📈', 'voll': '🫙',
    'vorbereitet': '✅', 'warm': '🌡️', 'weich': '🧸', 'weit': '➡️',
    'wenig': '📉', 'wichtig': '⭐', 'zentral': '🎯', 'öffentlich': '🏛️',
    'überfüllt': '👥',
}


def patch_supabase(word, emoji, cat):
    q = urllib.parse.quote(word)
    url = f'{SS}/rest/v1/palabras?palabra_de=eq.{q}&id_categoria=eq.{cat}'
    data = json.dumps({'texto_emoji': emoji}).encode()
    req = urllib.request.Request(url, data=data, method='PATCH', headers=H)
    urllib.request.urlopen(req, timeout=20)


def main():
    conn = sqlite3.connect('lingo_nouns.db')
    c = conn.cursor()

    n_sqlite = 0
    n_supa = 0
    fallos = []

    for word, emoji in VERBOS.items():
        c.execute("UPDATE palabras SET texto_emoji=? WHERE palabra_de=? AND id_categoria=2",
                  (emoji, word))
        n_sqlite += c.rowcount
        try:
            patch_supabase(word, emoji, 2)
            n_supa += 1
        except Exception as e:
            fallos.append(f'VERBO {word}: {e}')

    for word, emoji in ADJETIVOS.items():
        c.execute("UPDATE palabras SET texto_emoji=? WHERE palabra_de=? AND id_categoria=3",
                  (emoji, word))
        n_sqlite += c.rowcount
        try:
            patch_supabase(word, emoji, 3)
            n_supa += 1
        except Exception as e:
            fallos.append(f'ADJ {word}: {e}')

    conn.commit()

    # Verificación: cuántos quedan con '📦'
    rest = c.execute("SELECT COUNT(*) FROM palabras WHERE id_categoria IN (2,3) AND texto_emoji='📦'").fetchone()[0]
    rest_verbo = c.execute("SELECT COUNT(*) FROM palabras WHERE id_categoria=2 AND texto_emoji='📦'").fetchone()[0]
    rest_adj = c.execute("SELECT COUNT(*) FROM palabras WHERE id_categoria=3 AND texto_emoji='📦'").fetchone()[0]

    print(f'SQLite filas actualizadas: {n_sqlite}')
    print(f'Supabase palabras PATCH: {n_supa}')
    print(f'Fallos: {len(fallos)}')
    for f in fallos[:20]:
        print('  ', f)
    print(f'Quedan con 📦 → verbos: {rest_verbo}, adjetivos: {rest_adj}')
    conn.close()


if __name__ == '__main__':
    main()
