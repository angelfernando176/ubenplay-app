const fs = require('fs');
const path = require('path');
const { bgA } = require('./anim.js');
const { rig, ink } = require('./emo.js');
const { arrow, burst, word, sweat, helpers } = require('./pain.js');

const X = 'G';
const faces = [['normal', true], ['curiosidad', true], ['alivio', true], ['dolor', true], ['mueca', true]];
const legArrow = `<g transform="translate(193 512) scale(0.9)">${arrow('G-stuck', '', true)}</g>`;
const scene = `${bgA()}
  ${rig(X, faces, '', { headExtra: sweat(X), legRExtra: legArrow })}
  ${arrow('G-fa', '', false)}${arrow('G-a1', '', false)}${arrow('G-a4', '', false)}
  ${burst('G-burst')}${burst('G-dust')}${word('G-alert', '!', '#E24B4A', 56)}${word('G-uy', '¡Uy!', '#EF9F27', 44)}`;

const runtime = helpers + `
const G={total:7.0};
function render3(t){
  t=t%G.total; const o={ox:0,jump:0,k:1,lL:0,lR:0,drop:0,lean:0,hy:0,nod:0,hat:0};
  const duck=win(t,0.62,1.22,0.16); o.k-=0.28*duck; o.hy+=26*duck; o.lean-=3*duck;
  const side=ease(seg(t,1.6,1.86))*(1-ease(seg(t,6.45,6.85))); o.ox=-80*side; o.lean+=6*bump(t,1.6,1.95);
  const hit=3.3;
  let LT=REST, RT=REST, lh=0, rh=0;
  const wipe=win(t,2.3,2.9,0.15); LT=mix(LT,[100,196],wipe); lh=lerp(0,160,wipe);
  if(t>=hit&&t<6.5){
    const jolt=bump(t,hit,hit+0.25); o.rot=3*jolt; o.ox+=-5*jolt;
    const lift=ease(seg(t,hit,hit+0.12))*(1-ease(seg(t,4.15,4.35))); o.lR=30*lift;
    if(t>hit+0.25&&t<4.15){const hp=((t-hit-0.25)%0.3)/0.3; o.jump+=13*Math.sin(Math.PI*hp); o.k-=0.04*(1-Math.sin(Math.PI*hp));}
    const bend=win(t,4.2,5.3,0.3); o.k-=0.24*bend; o.nod+=10*bend; o.hy+=12*bend; o.lean+=4*bend;
    const rub=Math.sin(t*14)*6*bend;
    RT=mix(RT,[104+rub,446],bend); rh=lerp(0,-20,bend); LT=mix(LT,[66,396],bend);
    if(t>=5.3){const lp=((t-5.3)%0.6)/0.6; o.lR+=7*Math.max(0,Math.sin(Math.PI*2*lp)); o.lean-=2.5*Math.sin(Math.PI*2*lp); o.rot=(o.rot||0)-1.5*Math.sin(Math.PI*2*lp);}
  }
  pose('G',o); arm('G-armL',LT,lh); arm('G-armR',RT,rh);
  let fk='normal'; if(t>=0.45&&t<2.3)fk='curiosidad'; if(t>=2.3&&t<hit)fk='alivio';
  if(t>=hit&&t<3.75)fk='dolor'; if(t>=3.75&&t<6.0)fk='mueca'; if(t>=6.0&&t<6.6)fk='alivio'; face('G',fk);
  op('G-sweat',win(t,0.7,2.9,0.2)+win(t,hit,6.1,0.2));
  const st=stg(150,240,o.ox,-o.jump);
  word('G-alert',st[0]+70,st[1]-140,t,0.3,0.75);
  word('G-uy',st[0]+86,st[1]-118,t,hit+0.05,4.7);
  horiz('G-a1',166,0.92,t,null);
  floorArrow('G',t,2.0,[560,40],[262,522],6.45);
  const lp=stg(196,512,o.ox,-o.jump);
  horiz('G-a4',lp[1],hit,t,lp[0]);
  op('G-stuck',t>=hit&&t<6.55?1-ease(seg(t,6.35,6.55)):0);
  pop('G-burst',lp[0]+8,lp[1],t,hit,0.28);
}
window.HIRN={render3,G,'3':G};
const t0=performance.now(); window.replay=()=>{window.__t0=performance.now()}; window.__t0=t0;
(function loop(now){if(!window.FREEZE&&now){render3((now-window.__t0)/1000);}requestAnimationFrame(loop)})();
})();`;

const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Hirn flecha en la pierna</title><style>
:root{--bg:#F7F5F0;--ink:#151515;--muted:#5F5E5A;--card:#fff;--line:#E2DED5;--accent:#0F6E56}
@media (prefers-color-scheme:dark){:root{--bg:#1C1C1B;--ink:#F1EFE8;--muted:#B4B2A9;--card:#262624;--line:#3A3A37;--accent:#5DCAA5}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif}
main{max-width:560px;margin:0 auto;padding:28px 16px 40px}h1{font-size:24px;font-weight:600;margin:0 0 4px}p.lead{margin:0 0 22px;color:var(--muted)}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;overflow:hidden}
.card svg{display:block;width:100%;height:auto}.meta{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:12px 14px}
.meta b{font-size:16px}.meta span{display:block;color:var(--muted);font-size:13px;margin-top:2px}
button{font:inherit;font-size:14px;padding:8px 14px;border-radius:8px;border:1px solid var(--line);background:transparent;color:var(--ink);cursor:pointer;white-space:nowrap}
button:hover{border-color:var(--accent);color:var(--accent)}
</style></head><body><main>
<h1>Hirn · flecha en la pierna</h1><p class="lead">Dolor leve, estilo caricatura. Se repite en bucle.</p>
<div class="card"><svg class="ink" viewBox="0 0 480 560" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Hirn esquiva flechas, una le da en la pierna y se queja un poco">${scene}</svg>
<div class="meta"><div><b>Herida en la pierna (dolor leve)</b><span>Esquiva dos flechas, la tercera le da en la pierna</span></div><button onclick="replay()">Repetir</button></div></div>
</main><script>${ink}</script><script>${runtime}</script></body></html>`;
fs.writeFileSync(path.join(__dirname, 'hirn_flecha_pierna.html'), html);
console.log('ok', (html.length / 1024).toFixed(0) + ' KB');
