const fs = require('fs');
const path = require('path');
const { headBase, brimShadow, hat, expr, C, O, sw, P } = require('./hirn.js');
const { bgA, bgB, leg, profileHead } = require('./anim.js');

const K = { pants: '#5A4426', pantsS: '#3F2F1A', shoe: '#3B2A1A', shoeD: '#2A1E12', shoeL: '#5E4630', coatD: '#B8A483', coatSD: '#968262' };
const M = d => d.replace(/(-?\d+\.?\d*) (-?\d+\.?\d*)/g, (m, x, y) => `${(300 - +x).toFixed(1)} ${y}`);
const BLK = d => `<path d="${d}" fill="${O}"/>`;
const F = (d, fill) => `<path d="${d}" fill="${fill}"/>`;
const L = (d, w = 3.5) => `<path d="${d}" fill="none" ${sw(w)}/>`;
const hl = (d, col, w = 4) => `<path d="${d}" fill="none" stroke="${col}" stroke-width="${w}" stroke-linecap="round"/>`;

/* Natural arm: shoulder → elbow (72) → wrist (70) → fist. Local axis points down. */
function arm(id, coat, coatS, skin) {
  return `<g id="${id}-u">
    ${F('M-15 -6 C-16 22 -14 50 -12 76 L12 76 C14 50 15 22 15 -6 Z', coat)}
    <ellipse cx="0" cy="-2" rx="16" ry="15" fill="${coat}"/>
    ${L('M-15 6 C-14 -11 14 -11 15 6')}${L('M-15 4 C-16 26 -14 52 -12 74')}${L('M15 4 C15 26 14 52 12 74')}
    ${BLK('M-7 58 Q1 63 8 56 Q2 67 -7 63 Z')}
    <circle cx="0" cy="72" r="12.6" fill="${coat}"/>
    <g id="${id}-l">
      ${F('M-12.5 -2 C-13 22 -11 46 -10 67 L10 67 C11 46 12.5 22 12.5 -2 Z', coat)}
      ${L('M-12.5 2 C-13 22 -11 46 -10 66')}${L('M12.5 2 C12.5 22 11 46 10 66')}
      ${BLK('M-9 10 Q-1 14 6 8 Q0 17 -9 15 Z')}
      <path d="M-11.6 47 L11.6 47 L11.2 56 L-11.2 56 Z" fill="${coatS}" ${sw(2.5)}/>
      <path d="M-9.5 65 L9.5 65 L8.5 71 L-8.5 71 Z" fill="#fff" ${sw(2.5)}/>
      <g id="${id}-h" transform="translate(0 70)">
        <path d="M-10 -1 C-14 8 -13 21 -5 27 C2 31 11 27 13 18 C14 10 12 3 10 -1 Z" fill="${skin}" ${sw(3)}/>
        ${L('M-9 12 Q1 15 11 11', 2)}${L('M-7 19 Q1 22 10 18', 2)}${L('M10 3 Q16 9 11 16', 2.5)}
      </g>
    </g></g>`;
}

/* ---------- FRONT RIG ---------- */
function frontRig() {
  const legP = 'M106 430 L103 562 L141 562 L146 430 Z';
  const shoe = 'M90 588 C84 568 98 556 118 556 L141 556 C148 564 148 578 142 588 Z';
  const legL = `<g id="A-legL">${P(legP, K.pants)}${BLK('M110 520 Q118 528 124 524 Q118 532 110 530 Z')}${P(shoe, K.shoe)}${hl('M100 566 Q112 560 124 562', K.shoeL)}</g>`;
  const legR = `<g id="A-legR">${P(M(legP), K.pants)}${BLK(M('M110 520 Q118 528 124 524 Q118 532 110 530 Z'))}${P(M(shoe), K.shoe)}${hl(M('M100 566 Q112 560 124 562'), K.shoeL)}</g>`;
  const coatBody = 'M80 248 C68 282 72 332 83 366 C76 402 67 440 64 486 L150 494 L236 486 C233 440 224 402 217 366 C228 332 232 282 220 248 C200 238 100 238 80 248 Z';
  const coat = [P(coatBody, C.coat),
    P('M150 418 L132 492 L168 492 Z', K.pantsS, 0), P('M150 418 L132 491', 'none', 3.5), P('M150 418 L168 491', 'none', 3.5),
    P('M120 250 C124 224 176 224 180 250 Z', C.coatS),
    P('M138 225 L138 250 L162 250 L162 225 Z', C.skin),
    P('M130 246 L170 246 L159 336 L141 336 Z', C.shirt),
    P('M143 250 L157 250 L159 262 L141 262 Z', C.tie),
    P('M141 262 L159 262 L163 338 L150 352 L137 338 Z', C.tie), P('M150 262 L159 262 L163 338 L150 352 Z', C.tieS, 0),
    P('M132 238 L150 252 L138 264 L124 248 Z', C.shirt, 3), P(M('M132 238 L150 252 L138 264 L124 248 Z'), C.shirt, 3),
    P('M131 246 L102 257 L94 288 L112 292 L98 305 L142 400 L147 400 L142 334 Z', C.coat),
    P(M('M131 246 L102 257 L94 288 L112 292 L98 305 L142 400 L147 400 L142 334 Z'), C.coat),
    BLK('M98 307 L138 396 L132 396 Z'), BLK(M('M98 307 L138 396 L132 396 Z')),
    P('M82 358 Q150 370 218 358 L219 377 Q150 389 81 377 Z', C.coatS),
    P('M140 362 L160 362 L160 384 L140 384 Z', '#8C7A5E', 3), P('M146 368 L154 368 L154 378 L146 378 Z', C.coatS, 2),
    ...[[124, 344], [124, 410], [176, 344], [176, 410]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#6E5B40" ${sw(2.5)}/>`),
    BLK('M84 420 Q92 442 86 474 Q98 446 96 420 Z'), BLK(M('M84 420 Q92 442 86 474 Q98 446 96 420 Z')), BLK('M88 344 Q96 352 104 352 Q96 356 88 352 Z'), BLK(M('M88 344 Q96 352 104 352 Q96 356 88 352 Z'))].join('');
  const head = e => `<g transform="translate(150 236) scale(0.8) translate(-180 -271)">${headBase()}${brimShadow()}${expr[e]()}${hat(0, 4, 0)}</g>`;
  return `<g id="A-char"><ellipse id="A-shadow" cx="150" cy="590" rx="92" ry="9" fill="${O}" opacity="0.14"/>
    ${legL}${legR}
    <g id="A-upper">${coat}
      <g id="A-head"><g id="A-headN">${head('normal')}</g><g id="A-headC" opacity="0">${head('curiosidad')}</g></g>
      <g id="A-armRwrap" transform="translate(300 0) scale(-1 1)">${arm('A-armR', C.coat, C.coatS, C.skin)}</g>
      ${arm('A-armL', C.coat, C.coatS, C.skin)}
    </g>
    <g transform="translate(236 66)"><g id="A-q" opacity="0"><text x="0" y="0" text-anchor="middle" font-family="Arial Black, Arial, sans-serif" font-weight="900" font-size="58" fill="${C.tie}" stroke="${O}" stroke-width="3.5" paint-order="stroke">?</text></g></g>
  </g>`;
}

/* ---------- PROFILE RIG ---------- */
function profileRig() {
  const coat = 'M108 246 C96 286 96 336 104 366 C96 404 90 444 86 488 L206 488 C202 444 196 404 191 366 C196 330 194 290 188 270 C182 252 166 244 150 242 Z';
  return `<g id="B-char"><g id="B-flip">
   <ellipse cx="150" cy="590" rx="66" ry="8" fill="${O}" opacity="0.14"/>
   <g id="B-body">
    ${leg('B-legF', K.pantsS, K.shoeD, true)}
    ${arm('B-armF', K.coatD, K.coatSD, C.skinS)}
    ${leg('B-legN', K.pants, K.shoe, false)}
    ${P('M118 254 C118 226 150 220 162 236 L166 256 Z', C.coatS)}
    ${P('M132 225 L132 252 L158 252 L158 225 Z', C.skin)}
    ${P(coat, C.coat)}
    ${P('M166 244 L190 262 L188 300 L174 302 Z', C.shirt)}
    ${P('M178 258 L188 266 L192 330 L182 338 L178 300 Z', C.tie)}
    ${P('M154 244 L178 272 L172 294 L166 286 L170 330 L158 270 Z', C.coat)}
    ${BLK('M94 430 Q104 452 100 482 Q110 454 106 428 Z')}${BLK('M182 410 Q190 440 190 480 Q196 444 192 408 Z')}
    ${P('M102 358 Q146 368 192 356 L193 374 Q146 386 101 376 Z', C.coatS)}
    ${P('M176 359 L192 357 L193 375 L177 377 Z', '#8C7A5E', 2.5)}
    ${profileHead()}
    ${arm('B-armN', C.coat, C.coatS, C.skin)}
   </g></g>
   <g id="B-dots">${[0, 1, 2].map(i => `<g class="dot" opacity="0"><circle cx="${i * 13}" cy="${-i * 9}" r="${4 + i * 1.6}" fill="#fff" ${sw(2.5)}/></g>`).join('')}</g>
   <g id="B-q" opacity="0"><circle cx="0" cy="0" r="24" fill="#fff" ${sw(3)}/>
     <text x="0" y="12" text-anchor="middle" font-family="Arial Black, Arial, sans-serif" font-weight="900" font-size="32" fill="${C.tie}" stroke="${O}" stroke-width="2.5" paint-order="stroke">?</text></g>
  </g>`;
}

const runtime = `
(function(){
const $=id=>document.getElementById(id);
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v)), ease=x=>x<=0?0:x>=1?1:x*x*(3-2*x), lerp=(a,b,t)=>a+(b-a)*t, deg=r=>r*180/Math.PI;
const set=(id,tr)=>{const e=$(id);if(e)e.setAttribute('transform',tr)};
function ik(S,L1,L2,T,pick){let dx=T[0]-S[0],dy=T[1]-S[1],D=Math.hypot(dx,dy);D=clamp(D,Math.abs(L1-L2)+0.5,L1+L2-0.3);
 const b=Math.atan2(dy,dx),a=Math.acos(clamp((L1*L1+D*D-L2*L2)/(2*L1*D),-1,1));
 const e1=[S[0]+L1*Math.cos(b+a),S[1]+L1*Math.sin(b+a)],e2=[S[0]+L1*Math.cos(b-a),S[1]+L1*Math.sin(b-a)];
 const E=pick(e1,e2)?e1:e2; const g=Math.atan2(T[1]-E[1],T[0]-E[0]);
 const t1=deg(Math.atan2(-(E[0]-S[0]),E[1]-S[1])), t2=deg(Math.atan2(-Math.cos(g),Math.sin(g)));return [t1,t2-t1,t2];}
function poseArm(id,S,T,pick,hand,k){k=k||1;const [a,b,w]=ik(S,72*k,70*k,T,pick);set(id+'-u','translate('+S[0]+' '+S[1]+') rotate('+a.toFixed(2)+') scale('+k+')');set(id+'-l','translate(0 72) rotate('+b.toFixed(2)+')');set(id+'-h','translate(0 70) rotate('+(hand||0).toFixed(2)+')');}
function swingArm(id,S,a1,a2){set(id+'-u','translate('+S[0]+' '+S[1]+') rotate('+a1.toFixed(2)+')');set(id+'-l','translate(0 72) rotate('+a2.toFixed(2)+')');set(id+'-h','translate(0 70) rotate('+(a2*0.4).toFixed(2)+')');}

/* ===== A: approach — feet planted, short distance, neutral face, curiosity at the end ===== */
const A={idle:0.5,step:0.62,hold:3.4,z0:1.72,dz:0.15,H:214,k:410}; A.total=A.idle+3*A.step+A.hold;
const Asteps=[{f:'L',from:0,to:1},{f:'R',from:0,to:2},{f:'L',from:1,to:2}];
function renderA(t){
  t=t%A.total; let r=t-A.idle; const z={L:A.z0,R:A.z0}, lift={L:0,R:0}; let cur=-1,p=0;
  if(r>0){for(let i=0;i<3;i++){if(r<A.step){cur=i;p=r/A.step;break}r-=A.step;z[Asteps[i].f]=A.z0-Asteps[i].to*A.dz;}}
  if(cur>=0){const s=Asteps[cur],e=ease(p);z[s.f]=A.z0-lerp(s.from,s.to,e)*A.dz;lift[s.f]=Math.sin(Math.PI*p)*20;}
  const zb=(z.L+z.R)/2, sb=1/zb, X=240-150*sb, Y=A.H+A.k*sb-590*sb;
  set('A-char','translate('+X.toFixed(2)+' '+Y.toFixed(2)+') scale('+sb.toFixed(4)+')');
  for(const f of ['L','R']){const side=f==='L'?-1:1, sf=1/z[f], rx=150+side*25;
    const sx=240+side*25*sf, sy=A.H+A.k*sf-lift[f]*sf;
    const dx=(sx-X)/sb-rx, dy=(sy-Y)/sb-590, q=sf/sb, fs=1-0.012*lift[f];
    set('A-leg'+f,'translate('+dx.toFixed(2)+' '+dy.toFixed(2)+') translate('+rx+' 590) scale('+q.toFixed(4)+' '+(q*fs).toFixed(4)+') translate('+(-rx)+' -590)');}
  const sw=cur>=0?Math.sin(Math.PI*p):0, side=cur>=0?(Asteps[cur].f==='L'?1:-1):0;
  set('A-upper','translate(0 '+(-5*sw).toFixed(2)+') rotate('+(side*1.8*sw).toFixed(2)+' 150 480)');
  const th=t-A.idle-3*A.step, pose=th>0?ease((th-0.15)/0.5):0;
  const swL=cur>=0?(Asteps[cur].f==='L'?-1:1)*sw:0;
  const restL=[80+3*swL,421-12*Math.max(0,swL)], restR=[80-3*swL,421-12*Math.max(0,-swL)];
  const chin=[148,272], elbowSup=[126,344], KA=1.18;
  poseArm('A-armL',[84,258],[lerp(restL[0],chin[0],pose),lerp(restL[1],chin[1],pose)],(a,b)=>(a[1]-a[0]*0.3)>(b[1]-b[0]*0.3),lerp(0,-8,pose),KA);
  poseArm('A-armR',[84,258],[lerp(restR[0],300-elbowSup[0],pose),lerp(restR[1],elbowSup[1],pose)],(a,b)=>(a[1]-a[0]*0.3)>(b[1]-b[0]*0.3),lerp(0,-20,pose),KA);
  const curious=th>0.15; $('A-headN').setAttribute('opacity',curious?0:1); $('A-headC').setAttribute('opacity',curious?1:0);
  let tilt=cur>=0?side*2*sw:0, hs=1, hy=0, look=0;
  if(th>0){const q=ease((th-0.1)/0.5);tilt=lerp(0,-8,q);hs=lerp(1,1.05,q);hy=lerp(0,5,q);
    look=th<1.1?lerp(0,-5,ease((th-0.6)/0.3)):th<1.9?lerp(-5,5,ease((th-1.1)/0.45)):lerp(5,0,ease((th-1.9)/0.3));}
  set('A-head','translate(0 '+hy.toFixed(2)+') rotate('+tilt.toFixed(2)+' 150 240) translate(150 240) scale('+hs.toFixed(3)+') translate(-150 -240)');
  document.querySelectorAll('#A-headC .pupil').forEach(g=>g.setAttribute('transform','translate('+look.toFixed(2)+' 0)'));
  const qv=clamp((th-1.2)/0.35,0,1), qb=1+0.25*Math.sin(qv*Math.PI);
  $('A-q').setAttribute('opacity',qv.toFixed(2)); $('A-q').setAttribute('transform','scale('+Math.max(0.01,qv*qb).toFixed(3)+')');
}

/* ===== B: reflective pacing — 3 short steps right, turn, 3 back ===== */
const B={idle:0.4,step:0.95,pause:0.25,hold:1.2,turn:0.35,SL:78,s:0.62,ground:372,X0:250};
B.seg=B.idle+3*B.step+2*B.pause+B.hold+B.turn; B.total=2*B.seg;
const Bsteps=[{f:'N',from:0,to:1},{f:'F',from:0,to:2},{f:'N',from:1,to:2}];
function renderB(t){
  t=t%B.total; const segI=t<B.seg?0:1, dir=segI===0?1:-1, start=segI===0?0:2*B.SL; let r=t-segI*B.seg-B.idle;
  const pos={N:0,F:0}, lift={N:0,F:0}; let phase='idle',cur=-1,p=0;
  if(r>=0){phase='done';for(let i=0;i<3;i++){if(r<B.step){phase='step';cur=i;p=r/B.step;break}r-=B.step;pos[Bsteps[i].f]=Bsteps[i].to;
     if(i<2){if(r<B.pause){phase='pause';p=r/B.pause;break}r-=B.pause}}
   if(phase==='done'){if(r<B.hold){phase='hold';p=r/B.hold}else{phase='turn';p=(r-B.hold)/B.turn}}}
  if(phase==='step'){const s=Bsteps[cur];pos[s.f]=lerp(s.from,s.to,ease(p));lift[s.f]=Math.sin(Math.PI*p)*11;}
  const W={N:start+dir*pos.N*B.SL,F:start+dir*pos.F*B.SL}; const hipW=(W.N+W.F)/2;
  const lead=phase==='step'?4*Math.sin(Math.PI*p):0;
  const loc={N:(W.N-hipW)*dir-lead,F:(W.F-hipW)*dir-lead};
  const dx=Math.max(Math.abs(loc.N)*(lift.N<3),Math.abs(loc.F)*(lift.F<3)); const V=Math.min(160.5,Math.sqrt(161.2*161.2-dx*dx)), bob=Math.max(0.6,162-V-(phase==='step'?1.2*Math.sin(Math.PI*p):0));
  let flip=dir; if(phase==='turn'){flip=dir*Math.cos(Math.PI*ease(p)); if(Math.abs(flip)<0.06)flip=0.06*Math.sign(flip||dir);}
  const hx=B.X0+(hipW+lead*dir)*B.s;
  set('B-char','translate('+hx.toFixed(2)+' '+(B.ground-590*B.s).toFixed(2)+')');
  set('B-flip','scale('+(flip*B.s).toFixed(4)+' '+B.s+') translate(-150 0)');
  set('B-body','translate(0 '+bob.toFixed(2)+')');
  for(const f of ['N','F']){const T=[150+loc[f],562-bob-lift[f]];const [a1,a2,aw]=ik([150,400],100,62,T,(e1,e2)=>e1[0]>e2[0]);
    const tip=lift[f]>0?-6*Math.sin(Math.PI*clamp(lift[f]/11,0,1)):0;
    set('B-leg'+f+'-thigh','rotate('+a1.toFixed(2)+' 150 400)');set('B-leg'+f+'-shin','rotate('+a2.toFixed(2)+' 150 500)');set('B-leg'+f+'-foot','rotate('+(-aw+tip).toFixed(2)+' 150 562)');}
  let nod=5, look=[0,0], dv=0, qv=0;
  if(phase==='step') nod=5+1.5*Math.sin(Math.PI*p*2);
  if(phase==='pause') nod=5-3*Math.sin(Math.PI*p);
  if(phase==='hold'){const q=Math.sin(Math.PI*clamp(p*1.15,0,1));nod=lerp(5,-8,q);look=[1.5*q,-2.6*q];if(segI===0)dv=p;else qv=clamp(p*2.2,0,1)*(p<0.85?1:clamp((1-p)/0.15,0,1));}
  set('B-head','rotate('+nod.toFixed(2)+' 148 238)');
  document.querySelectorAll('#B-head .pupil').forEach(g=>g.setAttribute('transform','translate('+look[0].toFixed(2)+' '+look[1].toFixed(2)+')'));
  const rad=nod*Math.PI/180, cx=176-148, cy=232-238, chin=[148+cx*Math.cos(rad)-cy*Math.sin(rad),238+cx*Math.sin(rad)+cy*Math.cos(rad)];
  const fs=phase==='step'?(Bsteps[cur].f==='N'?-1:1)*Math.sin(Math.PI*p):0;
  let wc=0; if(phase==='hold') wc=ease(p/0.22)*(1-ease((p-0.86)/0.14));
  const nS=[16*fs+2,-(10+12*Math.max(0,-fs))];
  const [c1,c2]=ik([140,266],72,70,[chin[0]-6,chin[1]+30],(e1,e2)=>e1[1]>e2[1]);
  swingArm('B-armN',[140,266],lerp(nS[0],c1,wc),lerp(nS[1],c2,wc));
  swingArm('B-armF',[154,264],-16*fs+3,-(10+12*Math.max(0,fs)));
  const headScr=[hx+flip*(196-150)*B.s, B.ground-590*B.s+(150+bob)*B.s];
  document.querySelectorAll('#B-dots .dot').forEach((d,i)=>d.setAttribute('opacity',clamp(dv*3.4-i,0,1)*(dv<0.92?1:clamp((1-dv)/0.08,0,1))));
  set('B-dots','translate('+(headScr[0]-hx+dir*6).toFixed(1)+' '+(headScr[1]-(B.ground-590*B.s)-8).toFixed(1)+') scale('+dir+' 1)');
  const qb=1+0.2*Math.sin(qv*Math.PI);
  $('B-q').setAttribute('opacity',qv.toFixed(2));
  set('B-q','translate('+(dir*48).toFixed(1)+' '+(headScr[1]-(B.ground-590*B.s)-26).toFixed(1)+') scale('+Math.max(0.01,qv*qb).toFixed(3)+')');
}
window.HIRN={renderA,renderB,A,B};
const t0={A:performance.now(),B:performance.now()}; window.replay=k=>{t0[k]=performance.now()};
(function loop(now){if(!window.FREEZE&&now){renderA((now-t0.A)/1000);renderB((now-t0.B)/1000);}requestAnimationFrame(loop)})();
})();`;

const pf = fs.readFileSync(require.resolve('perfect-freehand'), 'utf8').replace(/^Object\.defineProperties\(exports[^;]*;/, '');
const ink = `(function(){var module={exports:{}},exports=module.exports;${pf}
;var gs=module.exports.getStroke;
document.querySelectorAll('svg.ink').forEach(function(svg,si){svg.querySelectorAll('path,ellipse,circle,rect').forEach(function(el,ei){
  if(el.getAttribute('stroke')!=='${O}')return;var w=parseFloat(el.getAttribute('stroke-width')||'0');if(w<1.9)return;
  var L=el.getTotalLength();if(!L)return;var closed=el.tagName!=='path'||/[zZ]\\s*$/.test(el.getAttribute('d'));
  var n=Math.max(10,Math.ceil(L/2.5)),pts=[],seed=(si*97+ei*13)%7;
  for(var i=0;i<=n;i++){var p=el.getPointAtLength(L*i/n);pts.push([p.x,p.y,0.62+0.3*Math.sin((i/n)*Math.PI*2*(closed?2:1)+seed)]);}
  var o=gs(pts,{size:w*1.0,thinning:0.5,smoothing:0.6,streamline:0.3,simulatePressure:false,last:true,
    start:{taper:closed?0:Math.min(L*0.3,w*5),cap:true},end:{taper:closed?0:Math.min(L*0.3,w*5),cap:true}});
  if(!o.length)return;var np=document.createElementNS('http://www.w3.org/2000/svg','path');
  np.setAttribute('d','M'+o.map(function(q){return q[0].toFixed(1)+' '+q[1].toFixed(1)}).join(' L')+' Z');np.setAttribute('fill','${O}');
  el.setAttribute('stroke','none');el.parentNode.insertBefore(np,el.nextSibling);});});})();`;

const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Hirn animado</title><style>
:root{--bg:#F7F5F0;--ink:#151515;--muted:#5F5E5A;--card:#fff;--line:#E2DED5;--accent:#0F6E56}
@media (prefers-color-scheme:dark){:root{--bg:#1C1C1B;--ink:#F1EFE8;--muted:#B4B2A9;--card:#262624;--line:#3A3A37;--accent:#5DCAA5}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif}
main{max-width:1180px;margin:0 auto;padding:28px 16px 40px}h1{font-size:24px;font-weight:600;margin:0 0 4px}p.lead{margin:0 0 22px;color:var(--muted)}
.grid{display:grid;grid-template-columns:minmax(0,480fr) minmax(0,640fr);gap:20px;align-items:start}
@media (max-width:820px){.grid{grid-template-columns:minmax(0,1fr)}}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;overflow:hidden}
.card svg{display:block;width:100%;height:auto}.meta{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:12px 14px}
.meta b{font-size:16px}.meta span{display:block;color:var(--muted);font-size:13px;margin-top:2px}
button{font:inherit;font-size:14px;padding:8px 14px;border-radius:8px;border:1px solid var(--line);background:transparent;color:var(--ink);cursor:pointer;white-space:nowrap}
button:hover{border-color:var(--accent);color:var(--accent)}
</style></head><body><main>
<h1>Hirn · animaciones de caminata (v2)</h1><p class="lead">Pies apoyados en el suelo, pasos cortos y brazos articulados. Cada escena se repite en bucle.</p>
<div class="grid">
<div class="card"><svg class="ink" viewBox="0 0 480 560" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Hirn se acerca 3 pasos y muestra curiosidad">${bgA()}${frontRig()}</svg>
<div class="meta"><div><b>Acercamiento y curiosidad</b><span>3 pasos cortos; la curiosidad aparece al llegar</span></div><button onclick="replay('A')">Repetir</button></div></div>
<div class="card"><svg class="ink" viewBox="0 0 640 400" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Hirn camina de un lado a otro reflexionando">${bgB()}${profileRig()}</svg>
<div class="meta"><div><b>Caminata reflexiva de ida y vuelta</b><span>3 pasos a la derecha, se gira y regresa 3 pasos</span></div><button onclick="replay('B')">Repetir</button></div></div>
</div></main><script>${ink}</script><script>${runtime}</script></body></html>`;
fs.writeFileSync(path.join(__dirname, 'hirn_animacion.html'), html);
console.log('ok', (html.length / 1024).toFixed(0) + ' KB');
