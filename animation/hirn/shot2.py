import sys, os
from playwright.sync_api import sync_playwright
src, out = sys.argv[1], sys.argv[2]
with sync_playwright() as p:
    b = p.chromium.launch(executable_path='/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell')
    pg = b.new_page(viewport={'width': 1040, 'height': 760}, device_scale_factor=1.5)
    msgs=[]; pg.on('console', lambda m: msgs.append(m.text)); pg.on('pageerror', lambda e: msgs.append('ERR '+str(e)))
    pg.goto('file://' + src)
    pg.wait_for_function("document.body.dataset.inked==='1'", timeout=10000)
    pg.screenshot(path=out, full_page=True)
    for k in ['frente','perfil','espaldas']:
        svg = pg.eval_on_selector('#v-'+k, 'e=>e.outerHTML')
        open(os.path.join(os.path.dirname(src), f'hirn_vista_{k}.svg'),'w').write(svg)
    b.close()
print('shot', out, msgs)
