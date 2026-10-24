const fs = require('fs');
const path = require('path');
const { O, sw } = require('./hirn.js');
const { bgA } = require('./anim.js');
const { rig, ink } = require('./emo.js');

const arrow = (id, cls, stuck) => `<g ${id ? `id="${id}"` : ''} ${cls ? `class="${cls}"` : ''} opacity="0">
  ${stuck ? '' : `<path class="trail" d="M112 -7 L160 -7 M126 6 L178 6" stroke="#B4B2A9" stroke-width="3.5" stroke-linecap="round" fill="none"/>`}
  <rect x="${stuck ? 2 : 10}" y="-3.2" width="${stuck ? 92 : 84}" height="6.4" rx="2" fill="#9A6B3E" ${sw(2.5)}/>
  ${stuck ? `<path d="M-6 -10 L2 -3 M-8 2 L1 2 M-5 12 L2 4" fill="none" ${sw(2.5)}/>` : `<path d="M0 0 L17 -8.5 L12 0 L17 8.5 Z" fill="#C9C7BE" ${sw(2.5)}/>`}
  <path d="M82 -3 L98 -13 L108 -13 L96 -3 Z" fill="#E24B4A" ${sw(2.5)}/><path d="M82 3 L98 13 L108 13 L96 3 Z" fill="#E24B4A" ${sw(2.5)}/>
  <rect x="104" y="-3" width="6" height="6" fill="#3F2F1A"/></g>`;
const burst = id => `<g id="${id}" opacity="0"><path d="M0 -34 L8 -12 L30 -20 L16 -2 L34 10 L12 12 L14 34 L0 18 L-14 34 L-12 12 L-34 10 L-16 -2 L-30 -20 L-8 -12 Z" fill="#FAC775" ${sw(3)}/>
  <path d="M0 -16 L4 -6 L14 -8 L7 1 L15 8 L4 7 L4 17 L0 9 L-4 17 L-4 7 L-15 8 L-7 1 L-14 -8 L-4 -6 Z" fill="#fff"/></g>`;
const word = (id, txt, col, size) => `<g id="${id}" opacity="0"><text x="0" y="0" text-anchor="middle" font-family="Arial Black, Arial, sans-serif" font-weight="900" font-size="${size}" fill="${col}" stroke="${O}" stroke-width="3.5" paint-order="stroke">${txt}</text></g>`;
const star = (cls) => { let d = ''; for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, r = i % 2 ? 5.5 : 13; d += (i ? 'L' : 'M') + (Math.cos(a) * r).toFixed(1) + ' ' + (Math.sin(a) * r).toFixed(1) + ' '; } return `<g class="${cls}"><path d="${d}Z" fill="#F5B82E" ${sw(2.5)}/></g>`; };
const stars = X => `<g id="${X}-stars" opacity="0">${star(X + '-st')}${star(X + '-st')}${star(X + '-st')}</g>`;
const sweat = X => `<g id="${X}-sweat" opacity="0"><path d="M246 168 Q236 188 246 196 Q256 188 246 168 Z" fill="#85B7EB" ${sw(2.5)}/><path d="M112 178 Q104 194 112 200 Q120 194 112 178 Z" fill="#85B7EB" ${sw(2.5)}/></g>`;

const faces = [['normal', true], ['curiosidad', true], ['alivio', true], ['dolor', true], ['agonia', false]];

function scene(X, opts) {
  return `${bgA()}
  ${rig(X, faces, '', { headExtra: stars(X) + sweat(X), ...opts })}
  <g id="${X}-floorArrow">${arrow(X + '-fa', '', false)}</g>
  ${arrow(X + '-a1', '', false)}${arrow(X + '-a2', '', false)}${arrow(X + '-a4', '', false)}
  ${burst(X + '-burst')}${burst(X + '-dust')}
  ${word(X + '-alert', '!', '#E24B4A', 56)}${word(X + '-ay', X === 'P' ? '¡AY!' : '¡AAAY!', '#E24B4A', X === 'P' ? 44 : 52)}`;
}

const runtime = `
(function(){
const $=id=>document.getElementById(id), Q=s=>document.querySelectorAll(s);
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v)), ease=x=>x<=0?0:x>=1?1:x*x*(3-2*x), lerp=(a,b,t)=>a+(b-a)*t, deg=r=>r*180/Math.PI;
const seg=(t,a,b)=>clamp((t-a)/(b-a),0,1), bump=(t,a,b)=>Math.sin(Math.PI*seg(t,a,b)), win=(t,a,b,r)=>ease(seg(t,a,a+r))*(1-ease(seg(t,b-r,b)));
const set=(id,tr)=>{const e=$(id);if(e)e.setAttribute('transform',tr)}, op=(id,v)=>{const e=$(id);if(e)e.setAttribute('opacity',(+v).toFixed(3))};
function ik(S,L1,L2,T,pick){let dx=T[0]-S[0],dy=T[1]-S[1],D=Math.hypot(dx,dy);D=clamp(D,Math.abs(L1-L2)+0.5,L1+L2-0.3);
 const b=Math.atan2(dy,dx),a=Math.acos(clamp((L1*L1+D*D-L2*L2)/(2*L1*D),-1,1));
 const e1=[S[0]+L1*Math.cos(b+a),S[1]+L1*Math.sin(b+a)],e2=[S[0]+L1*Math.cos(b-a),S[1]+L1*Math.sin(b-a)];
 const E=pick(e1,e2)?e1:e2; const g=Math.atan2(T[1]-E[1],T[0]-E[0]);
 const t1=deg(Math.atan2(-(E[0]-S[0]),E[1]-S[1])), t2=deg(Math.atan2(-Math.cos(g),Math.sin(g)));return [t1,t2-t1];}
const KA=1.18, SH=[84,258], pick=(a,b)=>(a[1]-a[0]*0.3)>(b[1]-b[0]*0.3), REST=[80,421], mix=(A,B,w)=>[lerp(A[0],B[0],w),lerp(A[1],B[1],w)];
function arm(id,T,hand){const [a,b]=ik(SH,72*KA,70*KA,T,pick);set(id+'-u','translate('+SH[0]+' '+SH[1]+') rotate('+a.toFixed(2)+') scale('+KA+')');set(id+'-l','translate(0 72) rotate('+b.toFixed(2)+')');set(id+'-h','translate(0 70) rotate('+(hand||0).toFixed(2)+')');}
function face(X,key){Q('.'+X+'-face').forEach(g=>g.setAttribute('opacity',g.dataset.face===key?1:0));}
const S=0.74, CX=240-150*S, CY=522-590*S, stg=(x,y,ox,oy)=>[CX+x*S+(ox||0),CY+y*S+(oy||0)];
function pose(X,o){
  set(X+'-char','translate('+(CX+o.ox).toFixed(2)+' '+(CY-o.jump).toFixed(2)+') scale('+S+') rotate('+(o.rot||0).toFixed(2)+' 150 590)');
  const k=o.k;
  for(const [f,l] of [['L',o.lL||0],['R',o.lR||0]]) set(X+'-leg'+f,'translate(0 '+(-l).toFixed(2)+') translate(0 590) scale(1 '+k.toFixed(4)+') translate(0 -590)');
  set(X+'-upper','translate(0 '+((1-k)*160+(o.drop||0)).toFixed(2)+') rotate('+(o.lean||0).toFixed(2)+' 150 470) translate(150 470) scale('+(o.usx||1).toFixed(4)+' '+(o.usy||1).toFixed(4)+') translate(-150 -470)');
  set(X+'-head','translate(0 '+(o.hy||0).toFixed(2)+') rotate('+(o.nod||0).toFixed(2)+' 150 240)');
  set(X+'-hat','translate(0 '+(o.hat||0).toFixed(2)+')');
}
function fly(id,x,y,ang,o){op(id,o);set(id,'translate('+x.toFixed(1)+' '+y.toFixed(1)+') rotate('+ang.toFixed(1)+') scale(0.8)');}
function horiz(id,y,tHit,t,stopX,o){const v=1150;let x=stopX+v*(tHit-t);if(stopX===null)x=240+v*(tHit-t);
  const vis=t<tHit-0.55?0:(stopX!==null&&t>tHit?0:(x<-160?0:1));fly(id,stopX!==null&&t>tHit?stopX:x,y,0,vis*(o==null?1:o));}
function pop(id,x,y,t,a,dur){const u=seg(t,a,a+(dur||0.3));const v=u>0&&u<1?1:0;op(id,v);set(id,'translate('+x+' '+y+') scale('+(v?(0.3+1.1*Math.sin(Math.PI*u)).toFixed(3):0.01)+') rotate('+(u*40).toFixed(1)+')');}
function word(id,x,y,t,a,b){const v=win(t,a,b,0.12);op(id,v);set(id,'translate('+x+' '+y+') scale('+(0.6+0.4*v+0.06*Math.sin(t*16)*v).toFixed(3)+') rotate(-8)');}
function starsAt(X,t,v){op(X+'-stars',v);Q('.'+X+'-st').forEach((g,i)=>{const a=t*5+i*2.09;g.setAttribute('transform','translate('+(180+Math.cos(a)*78).toFixed(1)+' '+(70+Math.sin(a)*16).toFixed(1)+') rotate('+(t*200).toFixed(0)+')')});}
function floorArrow(X,t,tLand,from,to,fade){const id=X+'-fa';const u=seg(t,tLand-0.45,tLand);const ang=deg(Math.atan2(from[1]-to[1],from[0]-to[0]));
  const x=lerp(from[0],to[0],u),y=lerp(from[1],to[1],u);const vis=(t>tLand-0.45?1:0)*(1-ease(seg(t,fade,fade+0.3)));
  fly(id,x,y,ang,vis); Q('#'+id+' .trail').forEach(p=>p.setAttribute('opacity',t<tLand?1:0)); pop(X+'-dust',to[0],to[1]+4,t,tLand,0.28);}

/* ===== ESCENA 1: herida en el brazo ===== */
const P1={total:6.8};
function render1(t){
  t=t%P1.total; const o={ox:0,jump:0,k:1,lL:0,lR:0,drop:0,lean:0,hy:0,nod:0,hat:0};
  const duck=win(t,0.62,1.22,0.16); o.k-=0.28*duck; o.hy+=26*duck; o.lean-=3*duck;
  const jp=bump(t,1.48,2.02); o.jump+=72*jp; o.lL=o.lR=26*jp; o.k-=0.08*bump(t,1.4,1.52)+0.1*bump(t,2.0,2.14);
  const side=ease(seg(t,2.25,2.52))*(1-ease(seg(t,6.35,6.75))); o.ox=-84*side; o.lean+=6*bump(t,2.25,2.6);
  o.k-=0.05*bump(t,2.25,2.5);
  const hit=4.0, hurt=t>=hit&&t<6.25;
  let LT=REST, RT=REST, lh=0, rh=0;
  const wipe=win(t,3.35,3.85,0.15); LT=mix(LT,[100,196],wipe); lh=lerp(0,160,wipe);
  if(hurt){const g=ease(seg(t,hit+0.05,hit+0.3)); LT=mix(REST,[206,306],g); lh=lerp(0,-40,g); RT=mix(REST,[66,392],g);
    const hp=((t-hit-0.3)%0.4)/0.4, hopOn=t>hit+0.3&&t<5.9; if(hopOn){o.jump+=22*Math.sin(Math.PI*hp); o.lL=30; o.k-=0.06*(1-Math.sin(Math.PI*hp));}
    o.rot=-4*Math.sin(t*9)*(hopOn?1:0); o.nod=6*Math.sin(t*11); o.ox+=-6*bump(t,hit,hit+0.15);}
  const back=ease(seg(t,6.25,6.6)); if(t>=6.25){LT=mix([206,306],REST,back);RT=mix([66,392],REST,back);lh=lerp(-40,0,back);}
  pose('P',o); arm('P-armL',LT,lh); arm('P-armR',RT,rh);
  let fk='normal'; if(t>=0.5&&t<3.35)fk='curiosidad'; if(t>=3.35&&t<hit)fk='alivio'; if(t>=hit&&t<6.35)fk='dolor'; face('P',fk);
  op('P-stars',0); starsAt('P',t,win(t,hit+0.1,6.2,0.15)); op('P-sweat',win(t,0.7,3.3,0.2)+win(t,hit,6.2,0.2));
  const st=stg(150,240,o.ox,-o.jump);
  word('P-alert',st[0]+70,st[1]-140,t,0.3,0.75);
  word('P-ay',st[0]+90,st[1]-120,t,hit+0.05,5.8);
  horiz('P-a1',166,0.92,t,null);
  horiz('P-a2',492,1.75,t,null);
  floorArrow('P',t,2.68,[580,30],[262,520],6.3);
  const armPt=stg(213,300,o.ox,-o.jump);
  horiz('P-a4',armPt[1],hit,t,armPt[0]+6);
  op('P-stuck',t>=hit&&t<6.35?1-ease(seg(t,6.1,6.35)):0);
  pop('P-burst',armPt[0]+10,armPt[1],t,hit,0.3);
}

/* ===== ESCENA 2: herida en el pecho ===== */
const P2={total:8.0};
function render2(t){
  t=t%P2.total; const o={ox:0,jump:0,k:1,lL:0,lR:0,drop:0,lean:0,hy:0,nod:0,hat:0,usx:1,usy:1};
  const jp=bump(t,0.66,1.2); o.jump+=72*jp; o.lL=o.lR=26*jp; o.k-=0.08*bump(t,0.58,0.7)+0.1*bump(t,1.18,1.32);
  const side=ease(seg(t,1.45,1.72))*(1-ease(seg(t,7.45,7.9))); o.ox=82*side; o.lean+=-6*bump(t,1.45,1.8);
  const duck=win(t,2.62,3.22,0.16); o.k-=0.28*duck; o.hy+=26*duck; o.lean-=3*duck;
  const hit=4.05;
  let LT=REST, RT=REST, lh=0, rh=0;
  const wipe=win(t,3.35,3.85,0.15); LT=mix(LT,[100,196],wipe); lh=lerp(0,160,wipe);
  if(t>=hit&&t<7.35){
    const jolt=bump(t,hit,hit+0.35); o.ox+=-16*jolt; o.rot=-7*jolt; o.usy=1+0.04*jolt; o.hy-=10*jolt; o.nod=-8*jolt;
    const g=ease(seg(t,hit+0.12,hit+0.4)); LT=mix(REST,[150,318],g); RT=mix(REST,[118,330],g); lh=lerp(0,-60,g); rh=lerp(0,-50,g);
    const kneel=ease(seg(t,hit+0.7,hit+1.6)); o.k=1-0.52*kneel-0.06*bump(t,hit+0.4,hit+0.7); o.lean+=3*Math.sin(t*3)*kneel;
    o.usy*=1-0.04*kneel; o.hy+=14*kneel; o.nod+=lerp(0,5,kneel)+(t>hit+1.6?2*Math.sin(t*14)*(t<6.8?1:0):0);
    o.rot+=(t>hit+0.4&&t<hit+1.6)?3*Math.sin(t*16):0;}
  if(t>=7.35){const r=ease(seg(t,7.35,7.9)); o.k=lerp(0.48,1,r); LT=mix([150,318],REST,r); RT=mix([118,330],REST,r); lh=lerp(-60,0,r); rh=lerp(-50,0,r);}
  pose('C',o); arm('C-armL',LT,lh); arm('C-armR',RT,rh);
  let fk='normal'; if(t>=0.4&&t<3.35)fk='curiosidad'; if(t>=3.35&&t<hit)fk='alivio'; if(t>=hit&&t<5.85)fk='agonia'; if(t>=5.85&&t<7.45)fk=(Math.floor(t/0.2)%2)?'dolor':'agonia'; face('C',fk);
  starsAt('C',t,win(t,hit+0.3,7.3,0.2)); op('C-sweat',win(t,0.5,3.3,0.2)+win(t,hit,7.3,0.2));
  const st=stg(150,240,o.ox,-o.jump);
  word('C-alert',st[0]+70,st[1]-140,t,0.15,0.6);
  word('C-ay',st[0]+20,st[1]-150,t,hit+0.1,6.4);
  horiz('C-a1',492,0.93,t,null);
  floorArrow('C',t,1.88,[560,40],[186,522],7.4);
  horiz('C-a2',166,2.92,t,null);
  const ch=stg(174,326,o.ox,-o.jump);
  horiz('C-a4',ch[1],hit,t,ch[0]);
  op('C-stuck',t>=hit&&t<7.5?1-ease(seg(t,7.3,7.5)):0);
  pop('C-burst',ch[0]+10,ch[1],t,hit,0.32);
}
window.HIRN={render1,render2,P1,P2,'1':P1,'2':P2};
const t0={1:performance.now(),2:performance.now()}; window.replay=k=>{t0[k]=performance.now()};
(function loop(now){if(!window.FREEZE&&now){render1((now-t0[1])/1000);render2((now-t0[2])/1000);}requestAnimationFrame(loop)})();
})();`;

const armArrow = `<g transform="translate(0 40) scale(-0.78 0.78)">${arrow('P-stuck', '', true).replace('opacity="0"', 'opacity="0"')}</g>`;
const chestArrow = `<g transform="translate(176 326) rotate(-3) scale(1.05)">${arrow('C-stuck', '', true)}</g>`;

const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Hirn esquiva flechas</title><style>
:root{--bg:#F7F5F0;--ink:#151515;--muted:#5F5E5A;--card:#fff;--line:#E2DED5;--accent:#0F6E56}
@media (prefers-color-scheme:dark){:root{--bg:#1C1C1B;--ink:#F1EFE8;--muted:#B4B2A9;--card:#262624;--line:#3A3A37;--accent:#5DCAA5}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif}
main{max-width:1020px;margin:0 auto;padding:28px 16px 40px}h1{font-size:24px;font-weight:600;margin:0 0 4px}p.lead{margin:0 0 22px;color:var(--muted)}
.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px;align-items:start}
@media (max-width:760px){.grid{grid-template-columns:minmax(0,1fr)}}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;overflow:hidden}
.card svg{display:block;width:100%;height:auto}.meta{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:12px 14px}
.meta b{font-size:16px}.meta span{display:block;color:var(--muted);font-size:13px;margin-top:2px}
button{font:inherit;font-size:14px;padding:8px 14px;border-radius:8px;border:1px solid var(--line);background:transparent;color:var(--ink);cursor:pointer;white-space:nowrap}
button:hover{border-color:var(--accent);color:var(--accent)}
</style></head><body><main>
<h1>Hirn · esquiva flechas</h1><p class="lead">Estilo caricatura, sin sangre. Cada escena se repite en bucle.</p>
<div class="grid">
<div class="card"><svg class="ink" viewBox="0 0 480 560" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Hirn esquiva flechas y una le da en el brazo">${scene('P', { armRExtra: armArrow })}</svg>
<div class="meta"><div><b>Herida en el brazo</b><span>Se agacha, salta, se aparta y una flecha le da en el brazo</span></div><button onclick="replay(1)">Repetir</button></div></div>
<div class="card"><svg class="ink" viewBox="0 0 480 560" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Hirn esquiva flechas y una le da en el pecho">${scene('C', { upperExtra: chestArrow })}</svg>
<div class="meta"><div><b>Herida en el pecho</b><span>Salta, se aparta, se agacha y una flecha le da en el pecho</span></div><button onclick="replay(2)">Repetir</button></div></div>
</div></main><script>${ink}</script><script>${runtime}</script></body></html>`;
if (require.main === module) { fs.writeFileSync(path.join(__dirname, 'hirn_flechas.html'), html); console.log('ok', (html.length / 1024).toFixed(0) + ' KB'); }
module.exports = { arrow, burst, word, stars, sweat, helpers: runtime.split('/* ===== ESCENA 1')[0] };
