const fs = require('fs');
const path = require('path');
delete require.cache[require.resolve('./hirn.js')];
const { panel } = require('./hirn.js');

const names = [['investigando', 'Investigando'], ['alegria', 'Alegría'], ['dolor', 'Dolor'], ['reflexion', 'Reflexión']];
const cards = names.map(([k, label]) => `
  <figure><div class="card">${panel(k)}</div><figcaption>${label}</figcaption></figure>`).join('');

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
body{margin:0;background:#fff;font-family:Arial,Helvetica,sans-serif}
.wrap{display:flex;gap:24px;padding:32px 32px 24px}
h1{margin:28px 32px 0;font-size:26px;color:#151515}
p.sub{margin:6px 32px 0;color:#666;font-size:15px}
figure{margin:0}
.card{background:#F3F1EC;border-radius:18px;width:360px;height:440px;overflow:hidden}
figcaption{text-align:center;margin-top:12px;font-size:20px;font-weight:bold;color:#151515}
</style></head><body><h1>Hirn · hoja de expresiones (boceto)</h1><p class="sub">ÜBENPLAY · estilo cartoon con contorno · vista frontal, plano medio</p>
<div class="wrap">${cards}</div></body></html>`;

const out = process.argv[2] || __dirname;
fs.writeFileSync(path.join(out, 'hirn_expresiones.html'), html);
for (const [k] of names) fs.writeFileSync(path.join(out, `hirn_${k}.svg`), panel(k));
console.log('ok');
