const fs = require('fs');
const path = require('path');
const { headBase, brimShadow, hat, expr, C, O, sw, P } = require('./hirn.js');
const { bgA } = require('./anim.js');

const K = { pants: '#5A4426', pantsS: '#3F2F1A', shoe: '#3B2A1A', shoeL: '#5E4630' };
const M = d => d.replace(/(-?\d+\.?\d*) (-?\d+\.?\d*)/g, (m, x, y) => `${(300 - +x).toFixed(1)} ${y}`);
const BLK = d => `<path d="${d}" fill="${O}"/>`;
const F = (d, fill) => `<path d="${d}" fill="${fill}"/>`;
const L = (d, w = 3.5) => `<path d="${d}" fill="none" ${sw(w)}/>`;
const hl = (d, col, w = 4) => `<path d="${d}" fill="none" stroke="${col}" stroke-width="${w}" stroke-linecap="round"/>`;
const FACE = 'M126 150 C124 214 140 258 180 271 C220 258 236 214 234 150 Z';

function arm(id, extra) {
  return `<g id="${id}-u">
    ${F('M-15 -6 C-16 22 -14 50 -12 76 L12 76 C14 50 15 22 15 -6 Z', C.coat)}<ellipse cx="0" cy="-2" rx="16" ry="15" fill="${C.coat}"/>
    ${L('M-15 6 C-14 -11 14 -11 15 6')}${L('M-15 4 C-16 26 -14 52 -12 74')}${L('M15 4 C15 26 14 52 12 74')}
    ${BLK('M-7 58 Q1 63 8 56 Q2 67 -7 63 Z')}<circle cx="0" cy="72" r="12.6" fill="${C.coat}"/>
    <g id="${id}-l">
      ${F('M-12.5 -2 C-13 22 -11 46 -10 67 L10 67 C11 46 12.5 22 12.5 -2 Z', C.coat)}
      ${L('M-12.5 2 C-13 22 -11 46 -10 66')}${L('M12.5 2 C12.5 22 11 46 10 66')}${BLK('M-9 10 Q-1 14 6 8 Q0 17 -9 15 Z')}
      <path d="M-11.6 47 L11.6 47 L11.2 56 L-11.2 56 Z" fill="${C.coatS}" ${sw(2.5)}/>
      <path d="M-9.5 65 L9.5 65 L8.5 71 L-8.5 71 Z" fill="#fff" ${sw(2.5)}/>
      <g id="${id}-h" transform="translate(0 70)">
        <path d="M-10 -1 C-14 8 -13 21 -5 27 C2 31 11 27 13 18 C14 10 12 3 10 -1 Z" fill="${C.skin}" ${sw(3)}/>
        ${L('M-9 12 Q1 15 11 11', 2)}${L('M-7 19 Q1 22 10 18', 2)}${L('M10 3 Q16 9 11 16', 2.5)}
      </g></g>${extra || ''}</g>`;
}

function rig(X, faces, extras, opts) {
  opts = opts || {};
  const legP = 'M106 430 L103 562 L141 562 L146 430 Z';
  const shoe = 'M90 588 C84 568 98 556 118 556 L141 556 C148 564 148 578 142 588 Z';
  const legL = `<g id="${X}-legL">${P(legP, K.pants)}${BLK('M110 520 Q118 528 124 524 Q118 532 110 530 Z')}${P(shoe, K.shoe)}${hl('M100 566 Q112 560 124 562', K.shoeL)}</g>`;
  const legR = `<g id="${X}-legR">${P(M(legP), K.pants)}${BLK(M('M110 520 Q118 528 124 524 Q118 532 110 530 Z'))}${P(M(shoe), K.shoe)}${hl(M('M100 566 Q112 560 124 562'), K.shoeL)}${opts.legRExtra || ''}</g>`;
  const coatBody = 'M80 248 C68 282 72 332 83 366 C76 402 67 440 64 486 L150 494 L236 486 C233 440 224 402 217 366 C228 332 232 282 220 248 C200 238 100 238 80 248 Z';
  const coat = [P(coatBody, C.coat),
    P('M150 418 L132 492 L168 492 Z', K.pantsS, 0), P('M150 418 L132 491', 'none', 3.5), P('M150 418 L168 491', 'none', 3.5),
    P('M120 250 C124 224 176 224 180 250 Z', C.coatS), P('M138 225 L138 250 L162 250 L162 225 Z', C.skin),
    P('M130 246 L170 246 L159 336 L141 336 Z', C.shirt), P('M143 250 L157 250 L159 262 L141 262 Z', C.tie),
    P('M141 262 L159 262 L163 338 L150 352 L137 338 Z', C.tie), P('M150 262 L159 262 L163 338 L150 352 Z', C.tieS, 0),
    P('M132 238 L150 252 L138 264 L124 248 Z', C.shirt, 3), P(M('M132 238 L150 252 L138 264 L124 248 Z'), C.shirt, 3),
    P('M131 246 L102 257 L94 288 L112 292 L98 305 L142 400 L147 400 L142 334 Z', C.coat),
    P(M('M131 246 L102 257 L94 288 L112 292 L98 305 L142 400 L147 400 L142 334 Z'), C.coat),
    BLK('M98 307 L138 396 L132 396 Z'), BLK(M('M98 307 L138 396 L132 396 Z')),
    P('M82 358 Q150 370 218 358 L219 377 Q150 389 81 377 Z', C.coatS),
    P('M140 362 L160 362 L160 384 L140 384 Z', '#8C7A5E', 3), P('M146 368 L154 368 L154 378 L146 378 Z', C.coatS, 2),
    ...[[124, 344], [124, 410], [176, 344], [176, 410]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#6E5B40" ${sw(2.5)}/>`),
    BLK('M84 420 Q92 442 86 474 Q98 446 96 420 Z'), BLK(M('M84 420 Q92 442 86 474 Q98 446 96 420 Z')),
    BLK('M88 344 Q96 352 104 352 Q96 356 88 352 Z'), BLK(M('M88 344 Q96 352 104 352 Q96 356 88 352 Z'))].join('');
  const heads = faces.map(([key, shadow]) => `<g class="${X}-face" data-face="${key}" opacity="${key === 'normal' ? 1 : 0}">${headBase()}${shadow ? brimShadow() : ''}
      <path class="${X}-shade" d="${FACE}" fill="#24304A" opacity="0"/>${expr[key]()}</g>`).join('');
  return `<g id="${X}-char"><ellipse id="${X}-shadow" cx="150" cy="590" rx="92" ry="9" fill="${O}" opacity="0.14"/>
    <g id="${X}-body">${legL}${legR}
    <g id="${X}-upper">${coat}
      <g id="${X}-head"><g transform="translate(150 236) scale(0.8) translate(-180 -271)">${heads}
        <g id="${X}-tears" opacity="0">${[0, 1, 2, 3].map(i => `<g class="${X}-drop"><path d="M0 -9 Q-6 1 0 6 Q6 1 0 -9 Z" fill="#7FC4EC" ${sw(2)}/></g>`).join('')}</g>
        <g id="${X}-hat">${hat(0, 4, 0)}</g>${opts.headExtra || ''}</g></g>
      <g id="${X}-armRwrap" transform="translate(300 0) scale(-1 1)">${arm(X + '-armR', opts.armRExtra)}</g>${arm(X + '-armL')}${opts.upperExtra || ''}
    </g></g>${extras || ''}</g>`;
}

const confetti = () => {
  const cols = ['#1D9E75', '#EF9F27', '#E24B4A', '#7F77DD', '#5DCAA5', '#D85A30'];
  let s = '<g id="H-confetti">';
  for (let i = 0; i < 34; i++) s += `<rect class="cf" x="-4" y="-7" width="8" height="14" rx="1.5" fill="${cols[i % cols.length]}" opacity="0"/>`;
  return s + '</g>';
};
const happyExtras = `<g transform="translate(286 96)"><g id="H-ja" opacity="0"><text x="0" y="0" text-anchor="middle" font-family="Arial Black, Arial, sans-serif" font-weight="900" font-size="38" fill="#EF9F27" stroke="${O}" stroke-width="3.5" paint-order="stroke" transform="rotate(12)">¡JA JA!</text></g></g>`;
const sadExtras = `<g id="S-cloud" opacity="0" transform="translate(150 70)">
  <g id="S-rain">${[...Array(7)].map((_, i) => `<line class="rd" x1="${-48 + i * 16}" y1="0" x2="${-52 + i * 16}" y2="14" stroke="#378ADD" stroke-width="4" stroke-linecap="round"/>`).join('')}</g>
  <path d="M-70 10 C-92 10 -92 -22 -66 -22 C-66 -48 -28 -54 -16 -34 C-8 -60 36 -58 40 -30 C66 -40 86 -16 70 4 C86 14 70 30 52 22 L-60 22 C-80 26 -86 12 -70 10 Z" fill="#B4B2A9" ${sw(3.5)}/>
  <path d="M-58 4 C-50 -6 -30 -4 -22 4" fill="none" stroke="#D3D1C7" stroke-width="5" stroke-linecap="round"/></g>`;

const runtime = `
(function(){
const $=id=>document.getElementById(id), Q=s=>document.querySelectorAll(s);
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v)), ease=x=>x<=0?0:x>=1?1:x*x*(3-2*x), lerp=(a,b,t)=>a+(b-a)*t, deg=r=>r*180/Math.PI;
const seg=(t,a,b)=>clamp((t-a)/(b-a),0,1), bump=(t,a,b)=>Math.sin(Math.PI*seg(t,a,b));
const set=(id,tr)=>{const e=$(id);if(e)e.setAttribute('transform',tr)};
function ik(S,L1,L2,T,pick){let dx=T[0]-S[0],dy=T[1]-S[1],D=Math.hypot(dx,dy);D=clamp(D,Math.abs(L1-L2)+0.5,L1+L2-0.3);
 const b=Math.atan2(dy,dx),a=Math.acos(clamp((L1*L1+D*D-L2*L2)/(2*L1*D),-1,1));
 const e1=[S[0]+L1*Math.cos(b+a),S[1]+L1*Math.sin(b+a)],e2=[S[0]+L1*Math.cos(b-a),S[1]+L1*Math.sin(b-a)];
 const E=pick(e1,e2)?e1:e2; const g=Math.atan2(T[1]-E[1],T[0]-E[0]);
 const t1=deg(Math.atan2(-(E[0]-S[0]),E[1]-S[1])), t2=deg(Math.atan2(-Math.cos(g),Math.sin(g)));return [t1,t2-t1];}
const KA=1.18, SH=[84,258], pick=(a,b)=>(a[1]-a[0]*0.3)>(b[1]-b[0]*0.3);
function arm(id,T,hand){const [a,b]=ik(SH,72*KA,70*KA,T,pick);set(id+'-u','translate('+SH[0]+' '+SH[1]+') rotate('+a.toFixed(2)+') scale('+KA+')');set(id+'-l','translate(0 72) rotate('+b.toFixed(2)+')');set(id+'-h','translate(0 70) rotate('+(hand||0).toFixed(2)+')');}
const mix=(A,B,w)=>[lerp(A[0],B[0],w),lerp(A[1],B[1],w)];
function face(X,key){Q('.'+X+'-face').forEach(g=>g.setAttribute('opacity',g.dataset.face===key?1:0));}
function place(X,s,ox,oy,sx,sy){set(X+'-char','translate('+(240-150*s+ox).toFixed(2)+' '+(522-590*s+oy).toFixed(2)+') scale('+s+') translate(150 590) scale('+sx.toFixed(4)+' '+sy.toFixed(4)+') translate(-150 -590)');}
function legs(X,cr,liftL,liftR,tuck){
  for(const [f,l] of [['L',liftL],['R',liftR]]){const k=1-0.13*cr-0.004*l-0.1*tuck;
    set(X+'-leg'+f,'translate(0 '+(-l).toFixed(2)+') translate(0 '+(430+cr*14).toFixed(2)+') scale(1 '+k.toFixed(4)+') translate(0 -430)');}
}
const REST=[80,421];

/* ===== FELICIDAD ===== */
const H={total:7.2};
const cf=[...Array(34)].map((_,i)=>({x:(Math.random()*2-1)*190,vx:(Math.random()*2-1)*70,vy:-260-Math.random()*200,r:Math.random()*360,vr:(Math.random()*2-1)*600,ph:Math.random()*6}));
function renderH(t){
  t=t%H.total;
  let jump=0, cr=0, sx=1, sy=1, tuck=0, sway=0, shift=0, lL=0, lR=0, hat=0, upL=0, upR=0, wave=0, nod=0;
  cr+=0.9*bump(t,0.35,0.85)*(t<0.7?1:0);
  if(t>=0.35&&t<0.7)cr=ease(seg(t,0.35,0.7))*0.9;
  if(t>=0.7&&t<1.3){const v=seg(t,0.7,1.3);jump=52*Math.sin(Math.PI*v);sy=1+0.07*Math.sin(Math.PI*v);sx=1-0.04*Math.sin(Math.PI*v);tuck=Math.sin(Math.PI*v);hat=20*Math.sin(Math.PI*clamp(v*1.1-0.05,0,1));}
  if(t>=1.3&&t<1.5){const v=seg(t,1.3,1.5);cr=0.8*Math.sin(Math.PI*v);sy=1-0.05*Math.sin(Math.PI*v);sx=1+0.04*Math.sin(Math.PI*v);}
  const upJ=ease(seg(t,0.62,0.85))*(1-ease(seg(t,1.35,1.6)));
  if(t>=1.5&&t<4.1){const b=(t-1.5)/0.65,k=Math.floor(b),f=b-k,side=k%2?1:-1;
    sway=side*5*Math.sin(Math.PI*f); shift=side*12*Math.sin(Math.PI*f); cr=0.28*Math.abs(Math.cos(Math.PI*f));
    if(side<0) lL=13*Math.sin(Math.PI*f); else lR=13*Math.sin(Math.PI*f);
    const w=0.5+0.5*Math.sin(Math.PI*(b-0.5)); upL=w; upR=1-w; wave=Math.sin(t*13); nod=side*6*Math.sin(Math.PI*f);}
  if(t>=4.1&&t<4.4)cr=ease(seg(t,4.1,4.4));
  if(t>=4.4&&t<5.15){const v=seg(t,4.4,5.15);jump=76*Math.sin(Math.PI*v);sy=1+0.09*Math.sin(Math.PI*v);sx=1-0.05*Math.sin(Math.PI*v);tuck=Math.sin(Math.PI*v);hat=30*Math.sin(Math.PI*clamp(v*1.1-0.05,0,1));}
  if(t>=5.15&&t<5.35){const v=seg(t,5.15,5.35);cr=0.9*Math.sin(Math.PI*v);sy=1-0.06*Math.sin(Math.PI*v);sx=1+0.05*Math.sin(Math.PI*v);}
  const upB=ease(seg(t,4.25,4.5))*(1-ease(seg(t,6.55,6.95)));
  if(t>=5.35&&t<6.6){cr=0.16*Math.abs(Math.sin((t-5.35)*8));nod=4*Math.sin((t-5.35)*8);}
  const big=Math.max(upJ,upB);
  upL=Math.max(upL*(t>=1.5&&t<4.1?1:0),big); upR=Math.max(upR*(t>=1.5&&t<4.1?1:0),big);
  const shake=t>=5.35&&t<6.6?5*Math.sin(t*20):0;
  const UP=[46+(t>=1.5&&t<4.1?wave*8:0),100+shake];
  place('H',0.74,shift,-jump,sx,sy);
  legs('H',cr,lL,lR,tuck);
  set('H-upper','translate(0 '+(cr*14).toFixed(2)+') rotate('+sway.toFixed(2)+' 150 480)');
  set('H-head','rotate('+nod.toFixed(2)+' 150 240)');
  set('H-hat','translate(0 '+(-hat/0.8).toFixed(2)+') rotate('+(-hat*0.4).toFixed(2)+' 180 120)');
  arm('H-armL',mix(REST,UP,ease(upL)),0); arm('H-armR',mix(REST,[UP[0]+(t>=1.5&&t<4.1?-wave*16:0),UP[1]-shake*2],ease(upR)),0);
  let fk='normal'; if(t>=0.42&&t<6.85){fk='alegria'; const laugh=(t>=1.5&&t<4.1)||(t>=5.35&&t<6.6); if(laugh&&Math.floor(t/0.14)%2)fk='risa';}
  face('H',fk);
  const jv=(t>=1.7&&t<4.0)?bump(t,1.7,4.0):(t>=5.4&&t<6.5?bump(t,5.4,6.5):0);
  $('H-ja').setAttribute('opacity',Math.min(1,jv*2.5).toFixed(2)); $('H-ja').setAttribute('transform','scale('+(0.9+0.12*Math.abs(Math.sin(t*9))).toFixed(3)+')');
  const tc=t-4.62; Q('#H-confetti .cf').forEach((r,i)=>{const c=cf[i]; if(tc<0||tc>2.5){r.setAttribute('opacity',0);return;}
    const x=240+c.x+c.vx*0.5*tc+12*Math.sin(tc*5+c.ph), y=40+c.vy*0.35*tc+300*tc*tc;
    r.setAttribute('opacity',(tc>2.1?clamp((2.5-tc)/0.4,0,1):1).toFixed(2));
    r.setAttribute('transform','translate('+x.toFixed(1)+' '+y.toFixed(1)+') rotate('+(c.r+c.vr*tc).toFixed(0)+') scale(1 '+Math.cos(tc*9+c.ph).toFixed(2)+')');});
}

/* ===== TRISTEZA ===== */
const S={total:7.6};
function renderS(t){
  t=t%S.total;
  const q=ease(seg(t,1.0,2.6))*(1-ease(seg(t,6.7,7.4)));
  const sighQ=bump(t,0.6,1.3);
  let sob=0; if(t>=2.7&&t<5.7){const u=((t-2.7)%0.75)/0.75; sob=u<0.3?Math.sin(Math.PI*u/0.3):0;}
  const cr=0.55*q, sink=26*q;
  place('S',0.78,0,0,1-0.03*q,1);
  legs('S',cr,0,0,0);
  set('S-upper','translate(0 '+(cr*14+sink*0.45+4*sighQ-5*sob).toFixed(2)+') translate(150 400) scale('+(1-0.05*q+0.02*sob).toFixed(4)+' '+(1-0.03*q).toFixed(4)+') translate(-150 -400)');
  set('S-head','translate(0 '+(sink*0.55).toFixed(2)+') rotate('+(Math.sin(t*1.3)*2*q).toFixed(2)+' 150 240) translate(150 236) scale(1 '+(1-0.05*q).toFixed(4)+') translate(-150 -236)');
  set('S-hat','translate(0 '+(9*q).toFixed(2)+')');
  const IN=[134,436], H2=[136,410];
  const tgt=sob>0?mix(IN,H2,sob*0.6):IN;
  arm('S-armL',mix(REST,tgt,q),lerp(0,-35,q)); arm('S-armR',mix(REST,tgt,q),lerp(0,-35,q));
  let fk='normal';
  if(t>=0.7&&t<7.1)fk='triste';
  if(t>=2.7&&t<5.7)fk=(Math.floor(t/0.22)%2)?'llanto':'llanto2';
  face('S',fk);
  Q('.S-shade').forEach(p=>p.setAttribute('opacity',(0.42*q).toFixed(3)));
  $('S-dim').setAttribute('opacity',(0.28*q).toFixed(3));
  const cv=ease(seg(t,1.6,2.6))*(1-ease(seg(t,6.4,7.0)));
  $('S-cloud').setAttribute('opacity',cv.toFixed(2));
  $('S-cloud').setAttribute('transform','translate('+(150+3*Math.sin(t*1.7)).toFixed(1)+' '+(64-6*(1-cv)).toFixed(1)+')');
  Q('#S-rain .rd').forEach((l,i)=>{const y=((t*150+i*23)%62); l.setAttribute('transform','translate(0 '+(16+y).toFixed(1)+')'); l.setAttribute('opacity',(y<52?1:clamp((62-y)/10,0,1)).toFixed(2));});
  const tv=(t>=2.6&&t<6.2)?1:0; $('S-tears').setAttribute('opacity',tv);
  Q('.S-drop').forEach((d,i)=>{const side=i%2?1:-1, u=((t+i*0.31)%0.9)/0.9;
    const x=180+side*(30+4*u), y=220+u*72+28*u*u;
    d.setAttribute('transform','translate('+x.toFixed(1)+' '+y.toFixed(1)+') scale('+(1.1-0.3*u).toFixed(2)+')'); d.setAttribute('opacity',(u<0.8?1:(1-u)/0.2).toFixed(2));});
}
window.HIRN={renderH,renderS,H,S};
const t0={H:performance.now(),S:performance.now()}; window.replay=k=>{t0[k]=performance.now()};
(function loop(now){if(!window.FREEZE&&now){renderH((now-t0.H)/1000);renderS((now-t0.S)/1000);}requestAnimationFrame(loop)})();
})();`;

const pf = fs.readFileSync(require.resolve('perfect-freehand'), 'utf8').replace(/^Object\.defineProperties\(exports[^;]*;/, '');
const ink = `(function(){var module={exports:{}},exports=module.exports;${pf}
;var gs=module.exports.getStroke;
document.querySelectorAll('svg.ink').forEach(function(svg,si){svg.querySelectorAll('path,ellipse,circle,rect').forEach(function(el,ei){
  if(el.getAttribute('stroke')!=='${O}')return;var w=parseFloat(el.getAttribute('stroke-width')||'0');if(w<1.9)return;
  var L=el.getTotalLength();if(!L)return;var closed=el.tagName!=='path'||/[zZ]\\s*$/.test(el.getAttribute('d'));
  var n=Math.max(10,Math.ceil(L/2.5)),pts=[],seed=(si*97+ei*13)%7;
  for(var i=0;i<=n;i++){var p=el.getPointAtLength(L*i/n);pts.push([p.x,p.y,0.62+0.3*Math.sin((i/n)*Math.PI*2*(closed?2:1)+seed)]);}
  var o=gs(pts,{size:w,thinning:0.5,smoothing:0.6,streamline:0.3,simulatePressure:false,last:true,
    start:{taper:closed?0:Math.min(L*0.3,w*5),cap:true},end:{taper:closed?0:Math.min(L*0.3,w*5),cap:true}});
  if(!o.length)return;var np=document.createElementNS('http://www.w3.org/2000/svg','path');
  np.setAttribute('d','M'+o.map(function(q){return q[0].toFixed(1)+' '+q[1].toFixed(1)}).join(' L')+' Z');np.setAttribute('fill','${O}');
  el.setAttribute('stroke','none');el.parentNode.insertBefore(np,el.nextSibling);});});})();`;

const happyFaces = [['normal', true], ['alegria', false], ['risa', false]];
const sadFaces = [['normal', true], ['triste', true], ['llanto', true], ['llanto2', true]];

const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Hirn emociones</title><style>
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
<h1>Hirn · felicidad y tristeza</h1><p class="lead">Animación por esqueleto articulado. Cada escena se repite en bucle.</p>
<div class="grid">
<div class="card"><svg class="ink" viewBox="0 0 480 560" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Hirn salta, baila, ríe y festeja">${bgA()}${rig('H', happyFaces, happyExtras)}${confetti()}</svg>
<div class="meta"><div><b>Felicidad</b><span>Salta, baila, se ríe y festeja con los brazos arriba</span></div><button onclick="replay('H')">Repetir</button></div></div>
<div class="card"><svg class="ink" viewBox="0 0 480 560" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Hirn se entristece, se encoge y llora">${bgA()}<rect id="S-dim" width="480" height="560" fill="#1F2A44" opacity="0"/>${rig('S', sadFaces, sadExtras)}</svg>
<div class="meta"><div><b>Tristeza</b><span>Se ensombrece, se encoge y llora</span></div><button onclick="replay('S')">Repetir</button></div></div>
</div></main><script>${ink}</script><script>${runtime}</script></body></html>`;
if (require.main === module) { fs.writeFileSync(path.join(__dirname, 'hirn_emociones.html'), html); console.log('ok', (html.length / 1024).toFixed(0) + ' KB'); }
module.exports = { rig, ink, confetti };
