const fs = require('fs');
const path = require('path');
const { headBase, brimShadow, hat, expr, C, O, sw, P } = require('./hirn.js');

const K = { pants: '#5A4426', pantsS: '#3F2F1A', shoe: '#3B2A1A', shoeD: '#2A1E12', shoeL: '#5E4630', coatD: '#B8A483', coatSD: '#968262' };
const M = d => d.replace(/(-?\d+\.?\d*) (-?\d+\.?\d*)/g, (m, x, y) => `${(300 - +x).toFixed(1)} ${y}`);
const BLK = d => `<path d="${d}" fill="${O}"/>`;
const hl = (d, col, w = 4) => `<path d="${d}" fill="none" stroke="${col}" stroke-width="${w}" stroke-linecap="round"/>`;

/* ---------- FRONT RIG (stage A: approach with curiosity) ---------- */
function frontRig() {
  const leg = 'M106 440 L103 562 L141 562 L146 440 Z';
  const shoe = 'M90 588 C84 568 98 556 118 556 L141 556 C148 564 148 578 142 588 Z';
  const legL = `<g id="A-legL">${P(leg, K.pants)}${BLK('M110 520 Q118 528 124 524 Q118 532 110 530 Z')}${P(shoe, K.shoe)}${hl('M100 566 Q112 560 124 562', K.shoeL)}</g>`;
  const legR = `<g id="A-legR">${P(M(leg), K.pants)}${BLK(M('M110 520 Q118 528 124 524 Q118 532 110 530 Z'))}${P(M(shoe), K.shoe)}${hl(M('M100 566 Q112 560 124 562'), K.shoeL)}</g>`;
  const coatBody = 'M80 248 C66 300 64 400 66 484 L150 492 L234 484 C236 400 234 300 220 248 C200 238 100 238 80 248 Z';
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
    P('M74 360 Q150 372 226 360 L227 378 Q150 390 73 378 Z', C.coatS),
    P('M140 362 L160 362 L160 384 L140 384 Z', '#8C7A5E', 3), P('M146 368 L154 368 L154 378 L146 378 Z', C.coatS, 2),
    ...[[124, 344], [124, 410], [176, 344], [176, 410]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#6E5B40" ${sw(2.5)}/>`),
    BLK('M86 420 Q96 440 92 470 Q100 446 98 420 Z'), BLK(M('M86 420 Q96 440 92 470 Q100 446 98 420 Z'))].join('');
  const sleeve = 'M82 250 C62 272 56 336 60 404 L88 408 C88 344 94 302 102 280 Z';
  const hand = 'M60 404 C56 418 60 432 72 434 C84 434 90 422 88 408 Z';
  const arm = (m) => [P(m(sleeve), C.coat), P(m('M60 384 L88 388 L88 398 L60 394 Z'), C.coatS), P(m(hand), C.skin),
    P(m('M66 420 Q72 424 80 420'), 'none', 2), BLK(m('M70 300 Q78 290 90 292 Q80 298 74 312 Z'))].join('');
  const id = x => x;
  const head = `<g id="A-head"><g transform="translate(150 236) scale(0.8) translate(-180 -271)">${headBase()}${brimShadow()}${expr.curiosidad()}${hat(0, 4, 0)}</g></g>`;
  const fx = `<g id="A-q" opacity="0"><text x="0" y="0" text-anchor="middle" font-family="Arial Black, Arial, sans-serif" font-weight="900" font-size="58" fill="${C.tie}" stroke="${O}" stroke-width="3.5" paint-order="stroke">?</text></g>`;
  return `<g id="A-char"><ellipse id="A-shadow" cx="150" cy="590" rx="92" ry="9" fill="${O}" opacity="0.14"/>
    ${legL}${legR}<g id="A-upper">${coat}<g id="A-armL">${arm(id)}</g><g id="A-armR">${arm(M)}</g>${head}</g>
    <g transform="translate(232 70)">${fx}</g></g>`;
}

/* ---------- PROFILE RIG (stage B: reflective walk) ---------- */
function leg(idp, pants, shoe, back) {
  return `<g id="${idp}-thigh">${P('M134 396 L133 504 L167 504 L166 396 Z', pants)}
    <g id="${idp}-shin">${P('M135 496 L136 564 L164 564 L165 496 Z', pants)}${back ? '' : BLK('M140 524 Q148 532 156 526 Q150 536 140 534 Z')}
      <g id="${idp}-foot">${P('M123 588 C121 570 129 560 141 560 L165 560 C179 566 195 572 199 582 L199 588 Z', shoe)}
      ${back ? '' : hl('M133 566 Q149 560 163 562', K.shoeL)}</g></g></g>`;
}
function profileHead() {
  return `<g id="B-head"><g transform="translate(0 14) translate(150 222) scale(1.02) translate(-150 -222)">
    ${P('M112 124 C104 160 108 196 124 212 C140 224 166 224 178 214 C186 206 188 196 186 186 C194 186 198 182 196 176 L186 160 C186 150 186 140 182 124 Z', C.skin)}
    ${P('M108 128 C102 150 104 176 114 192 L128 186 C124 166 124 146 126 128 Z', C.hair, 0)}
    <ellipse cx="134" cy="168" rx="10" ry="15" fill="${C.skin}" ${sw(4)}/>${P('M131 162 Q138 168 132 176', 'none', 2.5)}
    ${P('M126 128 L138 128 L136 150 L130 152 Z', C.hair, 0)}
    ${P('M160 159 Q170 152 178 160 Q171 170 160 168 Z', '#fff', 3)}
    <g class="pupil"><circle cx="172" cy="159" r="4.2" fill="${O}"/></g>
    ${BLK('M152 147 Q167 134 183 148 L182 153 Q167 141 155 152 Z')}
    ${P('M171 203 Q178 199 185 202', 'none', 3.5)}${P('M184 176 Q188 182 184 184', 'none', 2.5)}
    ${P('M164 210 Q172 214 178 210', 'none', 2.5)}
    <g transform="translate(147 134) scale(0.88) translate(-147 -134)">
    ${P('M98 132 C96 92 110 66 140 60 C168 58 186 68 194 82 C198 98 198 118 196 132 Z', C.hat)}
    ${P('M106 124 C104 96 114 76 132 68 Q120 92 122 122 Z', C.hatL, 0)}
    ${BLK('M176 72 Q184 86 182 104 Q178 88 170 78 Z')}
    ${P('M98 112 C140 118 170 118 197 112 L197 132 C170 138 140 138 97 132 Z', C.band)}
    ${P('M66 134 C90 124 140 122 196 124 C212 126 224 132 228 140 C204 144 150 144 118 144 C92 144 74 142 66 134 Z', C.hat)}
    ${P('M76 136 C110 130 160 130 216 136 C196 140 150 140 116 140 C96 140 84 140 76 136 Z', C.hatD, 0)}
    </g></g></g>`;
}
function arm(idp, coatc, coatS, skin) {
  return `<g id="${idp}-up"><ellipse cx="142" cy="264" rx="15" ry="14" fill="${coatc}"/>
    ${P('M128 258 C126 290 128 318 130 340 L156 340 C158 318 158 290 156 262 Z', coatc)}
    <g id="${idp}-lo">${P('M130 330 L130 404 L156 404 L156 330 Z', coatc)}${P('M130 384 L156 384 L156 394 L130 394 Z', coatS)}
      ${P('M131 402 C128 416 134 426 144 426 C155 425 159 414 156 402 Z', skin)}${P('M138 412 Q144 417 151 413', 'none', 2)}</g></g>`;
}
function profileRig() {
  const coat = 'M108 246 C94 292 90 380 86 488 L206 488 C202 404 196 322 188 270 C182 252 166 244 150 242 Z';
  return `<g id="B-char"><ellipse id="B-shadow" cx="150" cy="590" rx="70" ry="8" fill="${O}" opacity="0.14"/>
   <g id="B-body">
    ${leg('B-legF', K.pantsS, K.shoeD, true)}
    <g id="B-armFwrap">${arm('B-armF', K.coatD, K.coatSD, C.skinS)}</g>
    ${leg('B-legN', K.pants, K.shoe, false)}
    <g id="B-torso">
    ${P('M118 254 C118 226 150 220 162 236 L166 256 Z', C.coatS)}
    ${P('M132 225 L132 252 L158 252 L158 225 Z', C.skin)}
    ${P(coat, C.coat)}
    ${P('M166 244 L190 262 L188 300 L174 302 Z', C.shirt)}
    ${P('M178 258 L188 266 L192 330 L182 338 L178 300 Z', C.tie)}
    ${P('M154 244 L178 272 L172 294 L166 286 L170 330 L158 270 Z', C.coat)}
    ${BLK('M94 430 Q104 452 100 482 Q110 454 106 428 Z')}${BLK('M182 410 Q190 440 190 480 Q196 444 192 408 Z')}
    ${P('M92 358 Q146 368 196 356 L197 374 Q146 386 91 376 Z', C.coatS)}
    ${P('M180 359 L196 357 L197 375 L181 377 Z', '#8C7A5E', 2.5)}
    </g>
    ${profileHead()}
    ${arm('B-armN', C.coat, C.coatS, C.skin)}
   </g>
   <g id="B-dots" transform="translate(206 92)">${[0, 1, 2].map(i => `<g class="dot" opacity="0"><circle cx="${i * 20}" cy="${-i * 10}" r="${6 + i * 2}" fill="#fff" ${sw(3)}/></g>`).join('')}</g>
   <g id="B-q" opacity="0" transform="translate(262 74)"><circle cx="0" cy="-18" r="38" fill="#fff" ${sw(3.5)}/>
     <text x="0" y="2" text-anchor="middle" font-family="Arial Black, Arial, sans-serif" font-weight="900" font-size="50" fill="${C.tie}" stroke="${O}" stroke-width="3" paint-order="stroke">?</text></g>
  </g>`;
}

/* ---------- BACKGROUNDS ---------- */
function bgA() {
  const vp = [240, 210];
  let lines = '';
  for (let i = -6; i <= 6; i++) lines += `<line x1="${vp[0]}" y1="${vp[1]}" x2="${240 + i * 95}" y2="560" stroke="#C9B48F" stroke-width="2"/>`;
  [228, 252, 290, 352, 450].forEach(y => lines += `<line x1="0" y1="${y}" x2="480" y2="${y}" stroke="#C9B48F" stroke-width="2"/>`);
  return `<rect width="480" height="560" fill="#E4F1EC"/>
    <rect x="0" y="40" width="480" height="170" fill="#CFE6DD"/>
    <rect x="186" y="96" width="108" height="114" rx="4" fill="#1D9E75"/><rect x="194" y="104" width="92" height="106" fill="#0F6E56"/>
    <circle cx="276" cy="160" r="4" fill="#E9C46A"/>
    <rect x="40" y="70" width="84" height="64" rx="4" fill="#fff" stroke="#9FCDBD" stroke-width="4"/><rect x="356" y="70" width="84" height="64" rx="4" fill="#fff" stroke="#9FCDBD" stroke-width="4"/>
    <rect x="0" y="210" width="480" height="350" fill="#E9DCC6"/>${lines}
    <rect x="0" y="206" width="480" height="6" fill="#B89B6E"/>`;
}
function bgB() {
  const bld = [[0, 150, 90], [80, 110, 70], [140, 170, 110], [240, 120, 80], [310, 90, 120], [420, 140, 90], [500, 100, 80], [570, 160, 70]];
  return `<rect width="640" height="400" fill="#E4F1EC"/>
    ${bld.map(([x, h, w], i) => `<rect x="${x}" y="${330 - h - 40}" width="${w}" height="${h + 40}" fill="${i % 2 ? '#9FD9C4' : '#7CC8AE'}"/>`).join('')}
    ${bld.map(([x, h, w]) => { let r = ''; for (let yy = 330 - h - 24; yy < 310; yy += 30) for (let xx = x + 12; xx < x + w - 14; xx += 24) r += `<rect x="${xx}" y="${yy}" width="10" height="14" fill="#E4F1EC" opacity="0.7"/>`; return r; }).join('')}
    <rect x="0" y="330" width="640" height="70" fill="#D8C7A6"/><rect x="0" y="326" width="640" height="6" fill="#B89B6E"/>
    ${[0, 1, 2, 3, 4, 5, 6].map(i => `<line x1="${i * 110 + 40}" y1="332" x2="${i * 110 + 20}" y2="400" stroke="#C2AD86" stroke-width="2"/>`).join('')}
    <rect x="560" y="150" width="8" height="180" fill="#3F4A45"/><rect x="546" y="138" width="36" height="16" rx="6" fill="#3F4A45"/><rect x="552" y="152" width="24" height="8" fill="#F5DE8A"/>`;
}

/* ---------- RUNTIME ---------- */
const runtime = `
(function(){
const $=id=>document.getElementById(id);
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v)), ease=x=>x<0?0:x>1?1:x*x*(3-2*x), lerp=(a,b,t)=>a+(b-a)*t;
const deg=r=>r*180/Math.PI;
function ik(S,L1,L2,T,pick){let dx=T[0]-S[0],dy=T[1]-S[1],D=Math.hypot(dx,dy);D=clamp(D,Math.abs(L1-L2)+0.5,L1+L2-0.3);
 const b=Math.atan2(dy,dx),a=Math.acos(clamp((L1*L1+D*D-L2*L2)/(2*L1*D),-1,1));
 const e1=[S[0]+L1*Math.cos(b+a),S[1]+L1*Math.sin(b+a)],e2=[S[0]+L1*Math.cos(b-a),S[1]+L1*Math.sin(b-a)];
 const E=pick(e1,e2)?e1:e2; const W=[E[0]+L2*Math.cos(Math.atan2(T[1]-E[1],T[0]-E[0])),E[1]+L2*Math.sin(Math.atan2(T[1]-E[1],T[0]-E[0]))];
 const t1=deg(Math.atan2(-(E[0]-S[0]),E[1]-S[1])), t2=deg(Math.atan2(-(W[0]-E[0]),W[1]-E[1]));return [t1,t2-t1,t2];}
const set=(id,tr)=>{const e=$(id);if(e)e.setAttribute('transform',tr)};

/* Stage A timeline */
const A={idle:0.6,step:0.78,n:3,hold:2.8}; A.total=A.idle+A.step*A.n+A.hold;
const sOf=k=>lerp(0.28,0.84,Math.pow(k/3,1.15));
function renderA(t){
  t=t%A.total; let k=0,p=0,walking=false;
  if(t<A.idle){k=0;p=0}else if(t<A.idle+A.step*A.n){const u=(t-A.idle)/A.step;k=Math.floor(u);p=u-k;walking=true}else{k=3;p=0}
  const s=walking?lerp(sOf(k),sOf(k+1),ease(p)):sOf(k);
  const feetY=214+(s-0.22)*520;
  set('A-char','translate('+(240-150*s).toFixed(2)+' '+(feetY-590*s).toFixed(2)+') scale('+s.toFixed(4)+')');
  const sw=walking?Math.sin(Math.PI*p):0, side=k%2===0?1:-1;
  const lift=sw*26, fs=1-0.16*sw;
  const legSw=side>0?'A-legL':'A-legR', legSt=side>0?'A-legR':'A-legL';
  set(legSw,'translate(0 '+(-lift).toFixed(2)+') translate(0 440) scale(1 '+fs.toFixed(3)+') translate(0 -440)');
  set(legSt,'');
  const bob=-6*sw, sway=walking?side*-2.2*Math.sin(Math.PI*p):0;
  set('A-upper','translate(0 '+bob.toFixed(2)+') rotate('+sway.toFixed(2)+' 150 470)');
  const as=walking?9*sw*side:0;
  set('A-armL','rotate('+(as).toFixed(2)+' 88 262)'); set('A-armR','rotate('+(as).toFixed(2)+' 212 262)');
  const th=t-A.idle-A.step*A.n;
  let tilt=walking?side*5*Math.sin(Math.PI*p):0, hs=1, hy=0, look=0;
  if(walking) look=Math.sin(t*5)*4;
  if(th>0){const q=ease(th/0.5);tilt=lerp(0,-9,q);hs=lerp(1,1.08,q);hy=lerp(0,6,q);
    look= th<0.9?lerp(0,-5,ease((th-0.3)/0.3)):th<1.6?lerp(-5,5,ease((th-0.9)/0.4)):lerp(5,0,ease((th-1.6)/0.3));}
  if(t<A.idle) look=Math.sin(t*4)*3;
  set('A-head','translate(0 '+hy.toFixed(2)+') rotate('+tilt.toFixed(2)+' 150 240) translate(150 240) scale('+hs.toFixed(3)+') translate(-150 -240)');
  document.querySelectorAll('#A-head .pupil').forEach(g=>g.setAttribute('transform','translate('+look.toFixed(2)+' 0)'));
  const q=$('A-q'); if(th>1.0){const v=clamp((th-1.0)/0.35,0,1);const bounce=1+0.25*Math.sin(v*Math.PI);q.setAttribute('opacity',v.toFixed(2));q.setAttribute('transform','scale('+(v*bounce).toFixed(3)+')')}else q.setAttribute('opacity',0);
}

/* Stage B timeline */
const B={idle:0.6,step:1.15,pause:0.65,hold:2.6,SL:150,s:0.6,x0:70,ground:372};
B.total=B.idle+3*B.step+2*B.pause+B.hold;
const steps=[{f:'N',from:0,to:1},{f:'F',from:0,to:2},{f:'N',from:1,to:2}];
function stateB(t){
  let r=t-B.idle; const pos={N:0,F:0}; let cur=-1,p=0,phase='idle',pi=-1;
  if(r>=0){for(let i=0;i<3;i++){ if(r<B.step){cur=i;p=r/B.step;phase='step';break} r-=B.step; pos[steps[i].f]=steps[i].to; if(i<2){ if(r<B.pause){phase='pause';pi=i;p=r/B.pause;break} r-=B.pause}}
   if(cur<0&&phase!=='pause'){phase='hold';p=r}}
  return {cur,p,phase,pos,pi};
}
function renderB(t){
  t=t%B.total; const st=stateB(t); const SL=B.SL, pos={N:st.pos.N*SL,F:st.pos.F*SL}; let lift={N:0,F:0};
  if(st.phase==='step'){const s=steps[st.cur];const e=ease(st.p);pos[s.f]=lerp(s.from*SL,s.to*SL,e);lift[s.f]=Math.sin(Math.PI*st.p)*22;}
  const hipX=(pos.N+pos.F)/2+ (st.phase==='step'?6*Math.sin(Math.PI*st.p):0);
  const dxs=[pos.N-hipX,pos.F-hipX].filter((d,i)=>lift[i?'F':'N']<4).map(Math.abs); const dx=Math.max(0,...dxs);
  const V=Math.min(157,Math.sqrt(160*160-dx*dx)); const bob=162-V;
  set('B-char','translate('+(B.x0+hipX*B.s).toFixed(2)+' '+(B.ground-590*B.s).toFixed(2)+') scale('+B.s+')');
  set('B-body','translate(0 '+bob.toFixed(2)+')');
  const S=[150,400];
  for(const f of ['N','F']){
    const T=[150+pos[f]-hipX, 562-bob-lift[f]];
    const [a1,a2,aw]=ik(S,100,62,T,(e1,e2)=>e1[0]>e2[0]);
    const tip=lift[f]>0?-8*Math.sin(Math.PI*clamp(lift[f]/22,0,1)):0;
    set('B-leg'+f+'-thigh','rotate('+a1.toFixed(2)+' 150 400)');
    set('B-leg'+f+'-shin','rotate('+a2.toFixed(2)+' 150 500)');
    set('B-leg'+f+'-foot','rotate('+(-aw+tip).toFixed(2)+' 150 562)');
  }
  let nod=4, look=[0,0], dots=[0,0,0], qv=0;
  if(st.phase==='step') nod=4+2*Math.sin(Math.PI*st.p*2);
  if(st.phase==='pause'){const q=Math.sin(Math.PI*st.p);nod=lerp(4,-7,q);look=[1.5*q,-2.5*q];dots=[0,1,2].map(i=>clamp((st.p*3-i)*1.2,0,1)*q*1.6>1?1:clamp((st.p*3-i)*1.2,0,1)*q*1.6);}
  if(st.phase==='hold'){const q=ease(st.p/0.5);nod=lerp(4,-9,q);look=[1.5*q,-2.5*q];qv=clamp((st.p-0.4)/0.35,0,1);}
  set('B-head','rotate('+nod.toFixed(2)+' 148 238)');
  document.querySelectorAll('#B-head .pupil').forEach(g=>g.setAttribute('transform','translate('+look[0].toFixed(2)+' '+look[1].toFixed(2)+')'));
  const rad=nod*Math.PI/180, cx=176-148, cy=230-238; const chin=[148+cx*Math.cos(rad)-cy*Math.sin(rad), 238+cx*Math.sin(rad)+cy*Math.cos(rad)];
  const [u1,u2]=ik([142,264],72,76,[chin[0]-4,chin[1]+12],(e1,e2)=>e1[1]>e2[1]);
  set('B-armN-up','rotate('+u1.toFixed(2)+' 142 264)'); set('B-armN-lo','rotate('+u2.toFixed(2)+' 143 334)');
  const fsw=st.phase==='step'?(steps[st.cur].f==='N'?-1:1)*7*Math.sin(Math.PI*st.p):0;
  set('B-armF-up','translate(10 -2) rotate('+(fsw+4).toFixed(2)+' 142 264)'); set('B-armF-lo','rotate(-6 143 334)');
  document.querySelectorAll('#B-dots .dot').forEach((d,i)=>d.setAttribute('opacity',(st.phase==='hold'?0:dots[i]).toFixed(2)));
  const qg=$('B-q'); const b=1+0.2*Math.sin(qv*Math.PI); qg.setAttribute('opacity',qv.toFixed(2)); qg.setAttribute('transform','translate(262 74) scale('+(Math.max(0.01,qv*b)).toFixed(3)+')');
  set('B-dots','translate(206 92)');
}
window.HIRN={renderA,renderB,A,B};
let t0={A:performance.now(),B:performance.now()};
window.replay=k=>{t0[k]=performance.now()};
function loop(now){ if(!window.FREEZE){renderA((now-t0.A)/1000);renderB((now-t0.B)/1000);} requestAnimationFrame(loop);}
requestAnimationFrame(loop);
})();`;

module.exports = { frontRig, profileRig, bgA, bgB, runtime, leg, profileHead };

if (require.main === module) {
  const pf = fs.readFileSync(require.resolve('perfect-freehand'), 'utf8').replace(/^Object\.defineProperties\(exports[^;]*;/, '');
  const ink = `(function(){var module={exports:{}},exports=module.exports;${pf}
;var gs=module.exports.getStroke;
  document.querySelectorAll('svg.ink').forEach(function(svg,si){svg.querySelectorAll('path,ellipse,circle,rect').forEach(function(el,ei){
    if(el.getAttribute('stroke')!=='${O}')return;var w=parseFloat(el.getAttribute('stroke-width')||'0');if(w<1.9)return;
    var L=el.getTotalLength();if(!L)return;var closed=el.tagName!=='path'||/[zZ]\\s*$/.test(el.getAttribute('d'));
    var n=Math.max(10,Math.ceil(L/2.5)),pts=[],seed=(si*97+ei*13)%7;
    for(var i=0;i<=n;i++){var p=el.getPointAtLength(L*i/n);pts.push([p.x,p.y,0.62+0.3*Math.sin((i/n)*Math.PI*2*(closed?2:1)+seed)]);}
    var o=gs(pts,{size:w*1.0,thinning:0.5,smoothing:0.6,streamline:0.3,simulatePressure:false,last:true,
      start:{taper:closed?0:Math.min(L*0.35,w*6),cap:true},end:{taper:closed?0:Math.min(L*0.35,w*6),cap:true}});
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
<h1>Hirn · animaciones de caminata</h1><p class="lead">Boceto animado con esqueleto articulado. Cada escena se repite en bucle.</p>
<div class="grid">
<div class="card"><svg class="ink" viewBox="0 0 480 560" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Hirn se acerca desde el fondo con curiosidad">${bgA()}${frontRig()}</svg>
<div class="meta"><div><b>Acercamiento con curiosidad</b><span>3 pasos desde el fondo hacia la cámara</span></div><button onclick="replay('A')">Repetir</button></div></div>
<div class="card"><svg class="ink" viewBox="0 0 640 400" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Hirn camina de izquierda a derecha reflexionando">${bgB()}${profileRig()}</svg>
<div class="meta"><div><b>Caminata reflexiva</b><span>3 pasos lentos de izquierda a derecha, mano en el mentón</span></div><button onclick="replay('B')">Repetir</button></div></div>
</div></main><script>${ink}</script><script>${runtime}</script></body></html>`;
  fs.writeFileSync(path.join(__dirname, 'hirn_animacion.html'), html);
  console.log('ok', (html.length / 1024).toFixed(0) + ' KB');
}
