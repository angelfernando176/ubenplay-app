const fs = require('fs');
const path = require('path');
const { headBase, brimShadow, hat, expr, C, O, sw, P } = require('./hirn.js');

const K = { pants: '#5A4426', pantsS: '#3F2F1A', shoe: '#3B2A1A', shoeL: '#5E4630', coatD: '#968262' };
const M = d => d.replace(/(-?\d+\.?\d*) (-?\d+\.?\d*)/g, (m, x, y) => `${(300 - +x).toFixed(1)} ${y}`);
const BLK = d => `<path d="${d}" fill="${O}"/>`;
const shadow = `<ellipse cx="150" cy="588" rx="96" ry="9" fill="#151515" opacity="0.12"/>`;
const headFront = (e = 'investigando') =>
  `<g transform="translate(150 236) scale(0.8) translate(-180 -271)">${headBase()}${brimShadow()}${expr[e]()}${hat(0, 4, 0)}</g>`;

function legsFront() {
  const leg = 'M106 466 L103 562 L141 562 L146 466 Z';
  const shoe = 'M90 588 C84 568 98 556 118 556 L141 556 C148 564 148 578 142 588 Z';
  return [P(leg, K.pants), P(M(leg), K.pants), BLK('M110 520 Q118 528 124 524 Q118 532 110 530 Z'), BLK(M('M110 520 Q118 528 124 524 Q118 532 110 530 Z')),
    P(shoe, K.shoe), P(M(shoe), K.shoe), P('M100 566 Q112 560 124 562', 'none', 0).replace('/>', ` stroke="${K.shoeL}" stroke-width="4" stroke-linecap="round"/>`),
    P(M('M100 566 Q112 560 124 562'), 'none', 0).replace('/>', ` stroke="${K.shoeL}" stroke-width="4" stroke-linecap="round"/>`)].join('');
}

function armsFront(back = false) {
  const sleeve = 'M82 250 C62 272 56 336 60 404 L88 408 C88 344 94 302 102 280 Z';
  const hand = 'M60 404 C56 418 60 432 72 434 C84 434 90 422 88 408 Z';
  return [P(sleeve, C.coat), P(M(sleeve), C.coat),
    P('M60 384 L88 388 L88 398 L60 394 Z', C.coatS), P(M('M60 384 L88 388 L88 398 L60 394 Z'), C.coatS),
    P(hand, C.skin), P(M(hand), C.skin),
    back ? '' : P('M66 420 Q72 424 80 420', 'none', 2) + P(M('M66 420 Q72 424 80 420'), 'none', 2),
    BLK('M70 300 Q78 290 90 292 Q80 298 74 312 Z'), BLK(M('M70 300 Q78 290 90 292 Q80 298 74 312 Z'))].join('');
}

const coatBody = 'M80 248 C66 300 64 400 66 484 L150 492 L234 484 C236 400 234 300 220 248 C200 238 100 238 80 248 Z';

function front() {
  return [shadow, legsFront(),
    P(coatBody, C.coat),
    P('M150 418 L132 492 L168 492 Z', K.pantsS, 0),
    P('M150 418 L132 491', 'none', 3.5), P('M150 418 L168 491', 'none', 3.5),
    P('M120 250 C124 224 176 224 180 250 Z', C.coatS),
    P('M138 205 L138 250 L162 250 L162 205 Z', C.skin),
    P('M138 214 C146 226 154 226 162 214 L162 206 L138 206 Z', C.skinS, 0),
    P('M130 246 L170 246 L159 336 L141 336 Z', C.shirt),
    P('M143 250 L157 250 L159 262 L141 262 Z', C.tie),
    P('M141 262 L159 262 L163 338 L150 352 L137 338 Z', C.tie),
    P('M150 262 L159 262 L163 338 L150 352 Z', C.tieS, 0),
    P('M132 238 L150 252 L138 264 L124 248 Z', C.shirt, 3), P(M('M132 238 L150 252 L138 264 L124 248 Z'), C.shirt, 3),
    P('M131 246 L102 257 L94 288 L112 292 L98 305 L142 400 L147 400 L142 334 Z', C.coat),
    P(M('M131 246 L102 257 L94 288 L112 292 L98 305 L142 400 L147 400 L142 334 Z'), C.coat),
    BLK('M98 307 L138 396 L132 396 Z'), BLK(M('M98 307 L138 396 L132 396 Z')),
    P('M74 360 Q150 372 226 360 L227 378 Q150 390 73 378 Z', C.coatS),
    P('M140 362 L160 362 L160 384 L140 384 Z', '#8C7A5E', 3), P('M146 368 L154 368 L154 378 L146 378 Z', C.coatS, 2),
    ...[[124, 344], [124, 410], [176, 344], [176, 410]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#6E5B40" ${sw(2.5)}/>`),
    BLK('M86 420 Q96 440 92 470 Q100 446 98 420 Z'), BLK(M('M86 420 Q96 440 92 470 Q100 446 98 420 Z')),
    armsFront(), headFront()].join('');
}

function side() {
  const coat = 'M108 246 C94 292 90 380 86 488 L206 488 C202 404 196 322 188 270 C182 252 166 244 150 242 Z';
  return [shadow,
    P('M142 486 L148 562 L172 562 L172 486 Z', K.pantsS),
    P('M140 586 C140 572 146 564 156 564 L172 564 C184 570 196 576 198 584 L198 588 Z', '#2A1E12'),
    P('M122 486 L120 562 L152 562 L156 486 Z', K.pants),
    P('M110 588 C108 570 116 560 128 560 L152 560 C166 566 182 572 186 582 L186 588 Z', K.shoe),
    P('M120 566 Q136 560 150 562', 'none', 0).replace('/>', ` stroke="${K.shoeL}" stroke-width="4" stroke-linecap="round"/>`),
    BLK('M126 520 Q134 528 142 522 Q136 532 126 530 Z'),
    P('M118 254 C118 226 150 220 162 236 L166 256 Z', C.coatS),
    P('M132 205 L132 252 L158 252 L158 205 Z', C.skin),
    P(coat, C.coat),
    P('M166 244 L190 262 L188 300 L174 302 Z', C.shirt),
    P('M178 258 L188 266 L192 330 L182 338 L178 300 Z', C.tie),
    P('M154 244 L178 272 L172 294 L166 286 L170 330 L158 270 Z', C.coat),
    BLK('M94 430 Q104 452 100 482 Q110 454 106 428 Z'), BLK('M182 410 Q190 440 190 480 Q196 444 192 408 Z'),
    P('M92 358 Q146 368 196 356 L197 374 Q146 386 91 376 Z', C.coatS),
    P('M180 359 L196 357 L197 375 L181 377 Z', '#8C7A5E', 2.5),
    P('M126 252 C116 300 120 360 128 410 L156 410 C156 358 158 300 160 262 Z', C.coat),
    P('M128 388 L156 388 L156 398 L128 398 Z', C.coatS),
    P('M128 410 C126 424 132 434 144 434 C156 432 158 420 156 410 Z', C.skin),
    P('M138 420 Q144 426 150 422', 'none', 2),
    BLK('M136 296 Q144 286 156 286 Q146 294 140 308 Z'),
    `<g transform="translate(0 14) translate(150 222) scale(1.02) translate(-150 -222)">`,
    P('M112 124 C104 160 108 196 124 212 C140 224 166 224 178 214 C186 206 188 196 186 186 C194 186 198 182 196 176 L186 160 C186 150 186 140 182 124 Z', C.skin),
    P('M108 128 C102 150 104 176 114 192 L128 186 C124 166 124 146 126 128 Z', C.hair, 0),
    `<ellipse cx="134" cy="168" rx="10" ry="15" fill="${C.skin}" ${sw(4)}/>`, P('M131 162 Q138 168 132 176', 'none', 2.5),
    P('M126 128 L138 128 L136 150 L130 152 Z', C.hair, 0),
    P('M160 159 Q170 153 178 161 Q171 170 160 168 Z', '#fff', 3), `<circle cx="173" cy="163" r="4.2" fill="${O}"/>`,
    BLK('M154 151 L182 158 L182 151 L157 144 Z'),
    P('M174 200 L185 197', 'none', 3.5), P('M184 176 Q188 182 184 184', 'none', 2.5),
    P('M164 210 Q172 214 178 210', 'none', 2.5),
    `<g transform="translate(147 134) scale(0.88) translate(-147 -134)">`,
    P('M98 132 C96 92 110 66 140 60 C168 58 186 68 194 82 C198 98 198 118 196 132 Z', C.hat),
    P('M106 124 C104 96 114 76 132 68 Q120 92 122 122 Z', C.hatL, 0),
    BLK('M176 72 Q184 86 182 104 Q178 88 170 78 Z'),
    P('M98 112 C140 118 170 118 197 112 L197 132 C170 138 140 138 97 132 Z', C.band),
    P('M66 134 C90 124 140 122 196 124 C212 126 224 132 228 140 C204 144 150 144 118 144 C92 144 74 142 66 134 Z', C.hat),
    P('M76 136 C110 130 160 130 216 136 C196 140 150 140 116 140 C96 140 84 140 76 136 Z', C.hatD, 0),
    `</g>`, `</g>`].join('');
}

function back() {
  return [shadow,
    P('M106 466 L103 560 L141 560 L146 466 Z', K.pants), P(M('M106 466 L103 560 L141 560 L146 466 Z'), K.pants),
    P('M100 588 C98 568 106 556 122 556 L141 556 C146 564 146 578 142 588 Z', K.shoe), P(M('M100 588 C98 568 106 556 122 556 L141 556 C146 564 146 578 142 588 Z'), K.shoe),
    P(coatBody, C.coat),
    P('M150 400 L150 492', 'none', 3.5), P('M150 400 L142 492 L158 492 Z', K.pantsS, 0), P('M150 400 L142 491', 'none', 3), P('M150 400 L158 491', 'none', 3),
    P('M76 262 Q150 300 224 262 L222 250 Q150 288 78 250 Z', C.coatS),
    P('M78 290 Q150 316 222 290', 'none', 3),
    P('M90 360 Q150 370 210 360 L211 378 Q150 388 89 378 Z', C.coatS),
    `<circle cx="100" cy="369" r="5" fill="#6E5B40" ${sw(2.5)}/>`, `<circle cx="200" cy="369" r="5" fill="#6E5B40" ${sw(2.5)}/>`,
    BLK('M110 400 Q126 440 120 476 Q134 440 122 398 Z'), BLK(M('M110 400 Q126 440 120 476 Q134 440 122 398 Z')),
    armsFront(true),
    P('M140 205 L140 244 L160 244 L160 205 Z', C.skin),
    P('M114 254 C116 228 184 228 186 254 C170 246 130 246 114 254 Z', C.coatS),
    `<g transform="translate(150 236) scale(0.8) translate(-180 -271)">`,
    `<ellipse cx="124" cy="203" rx="10" ry="16" fill="${C.skin}" ${sw(4)}/>`, `<ellipse cx="236" cy="203" rx="10" ry="16" fill="${C.skin}" ${sw(4)}/>`,
    P('M126 150 C122 214 140 252 180 262 C220 252 238 214 234 150 Z', C.skin),
    P('M126 150 C122 206 134 238 150 248 L164 244 L172 252 L180 246 L188 252 L196 244 L210 248 C226 238 238 206 234 150 Z', C.hair),
    P('M140 196 Q150 214 146 232', 'none', 0).replace('/>', ` stroke="#3A3A3A" stroke-width="3" stroke-linecap="round"/>`),
    P('M220 196 Q210 214 214 232', 'none', 0).replace('/>', ` stroke="#3A3A3A" stroke-width="3" stroke-linecap="round"/>`),
    hat(0, 4, 0).replace(/<path d="M152 92[\s\S]*?\/>|<path d="M208 92[\s\S]*?\/>|<path d="M174 84[\s\S]*?\/>/g, ''),
    `</g>`].join('');
}

const views = [['frente', 'Frente', front], ['perfil', 'Perfil', side], ['espaldas', 'Espaldas', back]];
const svg = body => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 600" width="300" height="600">${body}</svg>`;
const pf = fs.readFileSync(require.resolve('perfect-freehand'), 'utf8');

const ink = `
(function(){
  var module={exports:{}},exports=module.exports;${pf.replace(/^Object\.defineProperties\(exports[^;]*;/, '')}
  ;var gs=typeof getStroke!=='undefined'?getStroke:module.exports.getStroke;
  document.querySelectorAll('svg.ink').forEach(function(svg,si){
    svg.querySelectorAll('path,ellipse,circle,rect').forEach(function(el,ei){
      if(el.getAttribute('stroke')!=='${O}')return;
      var w=parseFloat(el.getAttribute('stroke-width')||'0');if(w<1.9)return;
      var L=el.getTotalLength();if(!L)return;
      var closed=el.tagName!=='path'||/[zZ]\\s*$/.test(el.getAttribute('d'));
      var n=Math.max(10,Math.ceil(L/2.5)),pts=[],seed=(si*97+ei*13)%7;
      for(var i=0;i<=n;i++){var p=el.getPointAtLength(L*i/n);
        var pr=0.62+0.3*Math.sin((i/n)*Math.PI*2*(closed?2:1)+seed);pts.push([p.x,p.y,pr]);}
      var o=gs(pts,{size:w*1.0,thinning:0.5,smoothing:0.6,streamline:0.3,simulatePressure:false,last:true,
        start:{taper:closed?0:Math.min(L*0.35,w*6),cap:true},end:{taper:closed?0:Math.min(L*0.35,w*6),cap:true}});
      if(!o.length)return;
      var d='M'+o.map(function(q){return q[0].toFixed(1)+' '+q[1].toFixed(1)}).join(' L')+' Z';
      var np=document.createElementNS('http://www.w3.org/2000/svg','path');
      np.setAttribute('d',d);np.setAttribute('fill','${O}');
      if(el.getAttribute('transform'))np.setAttribute('transform',el.getAttribute('transform'));
      el.setAttribute('stroke','none');el.parentNode.insertBefore(np,el.nextSibling);
    });
  });
  document.body.dataset.inked='1';
})();`;

const cards = views.map(([k, label, fn]) =>
  `<figure><div class="card"><svg class="ink" id="v-${k}" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 600" width="300" height="600">${fn()}</svg></div><figcaption>${label}</figcaption></figure>`).join('');

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
body{margin:0;background:#fff;font-family:Arial,Helvetica,sans-serif}
h1{margin:28px 32px 0;font-size:26px;color:#151515}p.sub{margin:6px 32px 0;color:#666;font-size:15px}
.wrap{display:flex;gap:28px;padding:28px 32px 24px}figure{margin:0}
.card{background:#F3F1EC;border-radius:18px;width:300px;height:600px;overflow:hidden}
figcaption{text-align:center;margin-top:12px;font-size:20px;font-weight:bold;color:#151515}
</style></head><body><h1>Hirn · vistas de cuerpo completo (boceto)</h1><p class="sub">Contorno entintado de grosor variable · base para caminata, acercamiento y alejamiento</p>
<div class="wrap">${cards}</div><script>${ink}</script></body></html>`;

fs.writeFileSync(path.join(__dirname, 'hirn_vistas.html'), html);
console.log('ok');
