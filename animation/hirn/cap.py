import sys, io, os
from playwright.sync_api import sync_playwright
from PIL import Image
# usage: cap.py file.html "H:0.2,S:1.0" out.png scale   |  cap.py file.html gif H,S name1.gif,name2.gif
f = sys.argv[1]; mode = sys.argv[2]
with sync_playwright() as p:
    b = p.chromium.launch(executable_path='/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell')
    pg = b.new_page(viewport={'width': 1200, 'height': 900})
    errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
    pg.goto('file://' + os.path.abspath(f)); pg.wait_for_timeout(300); pg.evaluate('window.FREEZE=true')
    svgs = pg.query_selector_all('svg.ink')
    def grab(k, t, i, sc):
        pg.evaluate(f"HIRN.render{k}({t})"); im = Image.open(io.BytesIO(svgs[i].screenshot()))
        return im if sc == 1 else im.resize((int(im.width*sc), int(im.height*sc)), Image.LANCZOS)
    if mode != 'gif':
        keys = sys.argv[5] if len(sys.argv) > 5 else 'HS'
        out, sc = sys.argv[3], float(sys.argv[4])
        ims = [grab(it.split(':')[0], it.split(':')[1], keys.index(it.split(':')[0]), sc) for it in mode.split(',')]
        W = sum(i.width for i in ims) + 4*(len(ims)-1); sh = Image.new('RGB', (W, max(i.height for i in ims)), 'white'); x = 0
        for im in ims: sh.paste(im, (x, 0)); x += im.width + 4
        sh.save(out); print('ok', errs)
    else:
        keys = sys.argv[3].split(','); names = sys.argv[4].split(',')
        for i, (k, n) in enumerate(zip(keys, names)):
            tot = pg.evaluate(f"HIRN['{k}'].total"); fps = 20
            fr = [grab(k, j/fps, i, 0.75).convert('P', palette=Image.ADAPTIVE, colors=96) for j in range(int(tot*fps))]
            fr[0].save(n, save_all=True, append_images=fr[1:], duration=50, loop=0, optimize=True)
            print(n, len(fr), os.path.getsize(n)//1024, 'KB')
        print(errs)
    b.close()
