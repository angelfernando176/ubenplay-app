import sys
from playwright.sync_api import sync_playwright

src, out = sys.argv[1], sys.argv[2]
with sync_playwright() as p:
    b = p.chromium.launch(executable_path='/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell')
    pg = b.new_page(viewport={'width': 1576, 'height': 620}, device_scale_factor=1)
    pg.goto('file://' + src)
    pg.screenshot(path=out, full_page=True)
    b.close()
print('shot', out)
