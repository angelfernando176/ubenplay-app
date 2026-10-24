import sys, os, io
from playwright.sync_api import sync_playwright
from PIL import Image

src = '/home/claude/hirn/hirn_animacion.html'
mode = sys.argv[1] if len(sys.argv) > 1 else 'sheet'
out = '/home/claude/hirn'

with sync_playwright() as p:
    b = p.chromium.launch(executable_path='/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell')
    pg = b.new_page(viewport={'width': 1200, 'height': 900}, device_scale_factor=1)
    errs = []
    pg.on('pageerror', lambda e: errs.append(str(e)))
    pg.goto('file://' + src)
    pg.wait_for_timeout(300)
    pg.evaluate('window.FREEZE=true')
    svgs = pg.query_selector_all('svg.ink')
    totals = pg.evaluate('[HIRN.A.total, HIRN.B.total]')

    def grab(i, t, scale=1.0):
        pg.evaluate(f"HIRN.{'renderA' if i == 0 else 'renderB'}({t})")
        im = Image.open(io.BytesIO(svgs[i].screenshot()))
        return im if scale == 1 else im.resize((int(im.width * scale), int(im.height * scale)), Image.LANCZOS)

    if mode == 'sheet':
        for i, times in enumerate([[0.3, 0.99, 1.38, 1.77, 2.16, 2.55, 3.4, 4.2, 5.0],
                                   [0.3, 1.18, 1.75, 2.3, 3.3, 4.3, 5.4, 6.2, 7.6]]):
            ims = [grab(i, t, 0.5) for t in times]
            w, h = ims[0].size
            sheet = Image.new('RGB', (w * len(ims) + 4 * (len(ims) - 1), h), 'white')
            for k, im in enumerate(ims):
                sheet.paste(im, (k * (w + 4), 0))
            sheet.save(f'{out}/sheet_{"AB"[i]}.png')
        print('sheets ok', totals, errs)
    else:
        fps = 20
        for i in range(2):
            frames = [grab(i, k / fps, 0.75).convert('P', palette=Image.ADAPTIVE, colors=96)
                      for k in range(int(totals[i] * fps))]
            name = ['hirn_acercamiento_curiosidad.gif', 'hirn_caminata_reflexion.gif'][i]
            frames[0].save(f'{out}/{name}', save_all=True, append_images=frames[1:], duration=int(1000 / fps), loop=0, optimize=True)
            print(name, len(frames), 'frames', os.path.getsize(f'{out}/{name}') // 1024, 'KB')
        print(errs)
    b.close()
