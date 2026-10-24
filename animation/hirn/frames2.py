import sys, io
from playwright.sync_api import sync_playwright
from PIL import Image
spec = sys.argv[1]; outp = sys.argv[2]; sc = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
with sync_playwright() as p:
    b = p.chromium.launch(executable_path='/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell')
    pg = b.new_page(viewport={'width': 1200, 'height': 900})
    errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
    pg.goto('file:///home/claude/hirn/hirn_animacion.html'); pg.wait_for_timeout(300); pg.evaluate('window.FREEZE=true')
    s = pg.query_selector_all('svg.ink'); ims = []
    for item in spec.split(','):
        st, t = item.split(':'); i = 'AB'.index(st)
        pg.evaluate(f"HIRN.render{st}({t})"); im = Image.open(io.BytesIO(s[i].screenshot()))
        ims.append(im.resize((int(im.width*sc), int(im.height*sc))) if sc != 1 else im)
    h = max(i.height for i in ims); W = sum(i.width for i in ims) + 4*(len(ims)-1)
    sh = Image.new('RGB', (W, h), 'white'); x = 0
    for im in ims: sh.paste(im, (x, 0)); x += im.width + 4
    sh.save(outp); print('ok', errs, pg.evaluate('[HIRN.A.total,HIRN.B.total]'))
    b.close()
