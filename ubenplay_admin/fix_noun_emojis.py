#!/usr/bin/env python3
"""Asigna emojis significativos a los 77 sustantivos (id_categoria=1) que quedaron con '📦'."""
import sqlite3, json, urllib.request, urllib.parse

SS = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

SUSTANTIVOS = {
    'Öl': '🫒', 'Stadtverwaltung': '🏛️', 'Mittagessen': '🍽️', 'Banane': '🍌',
    'Viertel': '🏘️', 'Müll': '🗑️', 'Getränk': '🥤', 'Tüte': '🛍️',
    'Flasche': '🍾', 'Brief': '✉️', 'Abendessen': '🍽️', 'Zentrum': '🏙️',
    'Pilz': '🍄', 'Schokolade': '🍫', 'Mülltonne': '🗑️', 'E-Mail': '📧',
    'Sahne': '🍦', 'Löffel': '🥄', 'Messer': '🔪', 'Frühstück': '🍳',
    'Anschrift': '🏠', 'Schlafzimmer': '🛏️', 'Süßigkeit': '🍬', 'Firma': '🏢',
    'Statue': '🗿', 'Straßenlaterne': '💡', 'Fabrik': '🏭', 'Keks': '🍪',
    'Hamburger': '🍔', 'Eis': '🍦', 'Schinken': '🍖', 'Dose': '🥫',
    'Wäscherei': '🧺', 'Buchhandlung': '📚', 'Reinigung': '🧹', 'Zitrone': '🍋',
    'Butter': '🧈', 'Mais': '🌽', 'Pfirsich': '🍑', 'Marmelade': '🍯',
    'Honig': '🍯', 'Name': '📛', 'Nummer': '🔢', 'Büro': '🏢',
    'Bürgeramt': '🏛️', 'Papierkorb': '🗑️', 'Packung': '🎁', 'Zebrastreifen': '🦓',
    'Nudel': '🍝', 'Kuchen': '🍰', 'Friseursalon': '💇', 'Gurke': '🥒',
    'Birne': '🍐', 'Zeitung': '📰', 'Pfeffer': '🌶️', 'Schwimmbad': '🏊',
    'Stock': '🏢', 'Pizza': '🍕', 'Ananas': '🍍', 'Teller': '🍽️',
    'Nachtisch': '🍮', 'Zeitschrift': '📰', 'Wassermelone': '🍉', 'Schild': '🪧',
    'Suppe': '🍲', 'Sandwich': '🥪', 'Werkstatt': '🔧', 'Tasse': '☕',
    'Gabel': '🍴', 'Turm': '🗼', 'Glas': '🥛', 'Essig': '🫗',
    'Joghurt': '🥣', 'Karotte': '🥕', 'Schuhgeschäft': '👞', 'Fußgängerzone': '🚶',
    'Wohngebiet': '🏘️',
}


def patch_supabase(word, emoji):
    q = urllib.parse.quote(word)
    url = f'{SS}/rest/v1/palabras?palabra_de=eq.{q}&id_categoria=eq.1'
    data = json.dumps({'texto_emoji': emoji}).encode()
    req = urllib.request.Request(url, data=data, method='PATCH', headers=H)
    urllib.request.urlopen(req, timeout=20)


conn = sqlite3.connect('lingo_nouns.db')
c = conn.cursor()
n_sql = 0
fallos = []
for word, emoji in SUSTANTIVOS.items():
    c.execute("UPDATE palabras SET texto_emoji=? WHERE palabra_de=? AND id_categoria=1", (emoji, word))
    n_sql += c.rowcount
    try:
        patch_supabase(word, emoji)
    except Exception as e:
        fallos.append(f'{word}: {e}')
conn.commit()
rest = c.execute("SELECT COUNT(*) FROM palabras WHERE id_categoria=1 AND texto_emoji='📦'").fetchone()[0]
print(f'SQLite filas actualizadas: {n_sql}')
print(f'Fallos Supabase: {len(fallos)}')
for f in fallos[:10]:
    print('  ', f)
print(f'Quedan con 📦 (sustantivos): {rest}')
conn.close()
