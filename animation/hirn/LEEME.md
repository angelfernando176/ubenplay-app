# Hirn · proyecto de animación (ÜBENPLAY)

Personaje y animaciones generados por código (SVG + JavaScript). Para retomar el trabajo con Claude,
adjunta este .zip y pide: "Descomprime el proyecto de Hirn y continuemos con las animaciones".

## Requisitos
- Node.js 18+ y Python 3.10+
- `npm install` (instala perfect-freehand, svgo, @resvg/resvg-js, lottie-web)
- `pip install playwright pillow lottie` y `python -m playwright install chromium`

## Código fuente
| Archivo | Contenido |
|---|---|
| hirn.js | Personaje base: cabeza, sombrero, colores y todas las expresiones faciales |
| turnaround.js | Hoja de vistas: frente, perfil, espaldas |
| anim.js / anim2.js | Caminatas: acercamiento con curiosidad y caminata reflexiva ida y vuelta |
| emo.js | Rig frontal reutilizable + felicidad y tristeza |
| pain.js | Esquive de flechas: herida en el brazo y en el pecho |
| pain2.js | Esquive de flechas: herida en la pierna (dolor leve) |
| render.js | Hoja de expresiones (boceto) |
| cap.py, frames.py, frames2.py, shot.py, shot2.py | Capturas de fotogramas y exportación a GIF con Chromium |

## Regenerar
    node render.js        # hirn_expresiones.html + SVG
    node turnaround.js    # hirn_vistas.html
    node anim2.js         # hirn_animacion.html (caminatas)
    node emo.js           # hirn_emociones.html
    node pain.js          # hirn_flechas.html
    node pain2.js         # hirn_flecha_pierna.html
    python3 cap.py hirn_emociones.html gif H,S felicidad.gif,tristeza.gif

Nota: los scripts de captura apuntan a /home/claude/hirn y a un Chromium en /opt/pw-browsers;
en otro equipo hay que ajustar esas rutas.

## Pendiente
- Hoja de vistas con la gabardina entallada (las animaciones ya la tienen)
- Caminata de espaldas alejándose
- Vista de tres cuartos (giros más suaves) y vuelo de la gabardina al caminar
- Exportar al formato final de la app (Lottie, sprites o código) según el framework
