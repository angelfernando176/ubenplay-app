"""Distribución de palabras por juego — definida por Fernando (Sep 2026).

Numeración canónica de id_juego (1-13):
  1 Unión de Palabras · 2 Caza del Artículo · 3 Traduce · 4 Ahorcado · 5 Memoria
  6 Juego Inactivo · 7 Sopa de Letras · 8 Ruleta de Palabras · 9 Puerta Verde
  10 Puente de Cristal - Palabra · 11 Ordena Filas · 12 Puente de cristal - oración
  13 Crucigrama (inactivo)

`slots` = posiciones (1-10) de la lección que usa cada juego.
`tipos` = id_categoria a los que aplica (1 sustantivo, 2 verbo, 3 adjetivo, 4 conector).
"""

GAMES = {
    1:  {'nombre': 'Unión de Palabras',          'slots': [1, 2, 3, 4, 5],          'tipos': [1, 2, 3]},
    2:  {'nombre': 'Caza del Artículo',          'slots': [1, 2, 3, 4, 5],          'tipos': [1]},          # solo sustantivos
    3:  {'nombre': 'Traduce',                    'slots': [6, 7, 8, 9, 10],         'tipos': [1, 2, 3]},
    4:  {'nombre': 'Ahorcado',                   'slots': [6, 7, 8, 9, 10],         'tipos': [1, 2, 3]},
    5:  {'nombre': 'Memoria',                    'slots': [1, 2, 3, 4, 5, 6, 7, 8], 'tipos': [1, 2, 3]},
    6:  {'nombre': 'Juego Inactivo',             'slots': [],                       'tipos': []},           # imageOptions desactivado
    7:  {'nombre': 'Sopa de Letras',             'slots': [3, 4, 5, 6, 7, 8, 9, 10], 'tipos': [1, 2, 3]},
    8:  {'nombre': 'Ruleta de Palabras',         'slots': [1, 2, 9, 10],            'tipos': [1, 2, 3]},
    9:  {'nombre': 'Puerta Verde',               'slots': [3, 4, 5, 6],             'tipos': [1, 2, 3]},
    10: {'nombre': 'Puente de Cristal - Palabra', 'slots': [2, 7, 8, 9, 10],        'tipos': [1, 2, 3]},
    11: {'nombre': 'Ordena Filas',               'slots': [1, 6, 7, 8, 9, 10],      'tipos': [2]},          # solo verbos
    12: {'nombre': 'Puente de cristal - oración', 'slots': [1, 2, 3, 4, 5],         'tipos': [1, 2, 3]},
    13: {'nombre': 'Crucigrama',                 'slots': [],                       'tipos': []},           # inactivo
}


def juegos_aplicables(id_categoria):
    """Juegos disponibles para un tipo de palabra (excluye inactivos y los que no aplican)."""
    return [gid for gid, g in GAMES.items()
            if id_categoria in g['tipos'] and g['slots']]
