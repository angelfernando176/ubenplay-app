const O = '#151515';
const C = {
  skin: '#EBA372', skinS: '#C97E52', hair: '#1A1A1A',
  hat: '#8E8E8E', hatL: '#ABABAB', hatD: '#6A6A6A', band: '#262626',
  coat: '#CBB898', coatS: '#AA9676', shirt: '#FFFFFF', shirtS: '#E2E2E2',
  tie: '#E01E26', tieS: '#A8141A', lens: '#BFE3F5', rim: '#9A9A9A',
  mouth: '#7A1E1E', tongue: '#F28C8C', blush: '#F07C60', sweat: '#7FC4EC', star: '#F5B82E'
};
const sw = (w = 4) => `stroke="${O}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round"`;
const P = (d, fill, w) => `<path d="${d}" fill="${fill}" ${w === 0 ? '' : sw(w)}/>`;
const mirror = d => d.replace(/(-?\d+\.?\d*) (-?\d+\.?\d*)/g, (m, x, y) => `${360 - +x} ${y}`);

function body() {
  return [
    P('M28 440 C32 360 70 318 130 298 L150 290 L210 290 L230 298 C290 318 328 360 332 440 Z', C.coat),
    P('M136 300 C140 268 220 268 224 300 Z', C.coatS),
    P('M157 250 L157 300 L203 300 L203 250 Z', C.skin),
    P('M157 262 C170 280 190 280 203 262 L203 252 L157 252 Z', C.skinS, 0),
    P('M146 292 L214 292 L197 440 L163 440 Z', C.shirt),
    P('M170 302 L190 302 L194 318 L166 318 Z', C.tie),
    P('M166 318 L194 318 L205 440 L155 440 Z', C.tie),
    P('M180 318 L194 318 L205 440 L182 440 Z', C.tieS, 0),
    P('M152 279 L180 302 L162 320 L141 296 Z', C.shirt),
    P(mirror('M152 279 L180 302 L162 320 L141 296 Z'), C.shirt),
    P('M151 288 L119 302 L110 330 L133 335 L116 350 L152 440 L172 440 L164 402 Z', C.coat),
    P(mirror('M151 288 L119 302 L110 330 L133 335 L116 350 L152 440 L172 440 L164 402 Z'), C.coat),
    P('M116 352 L150 438 L142 438 Z', O, 0),
    P(mirror('M116 352 L150 438 L142 438 Z'), O, 0),
    P('M60 392 Q84 366 112 354 Q90 372 70 400 Z', O, 0),
    P(mirror('M60 392 Q84 366 112 354 Q90 372 70 400 Z'), O, 0),
    P('M48 430 Q56 410 70 404 Q60 418 56 434 Z', O, 0),
    P(mirror('M48 430 Q56 410 70 404 Q60 418 56 434 Z'), O, 0)
  ].join('');
}

function headBase() {
  return [
    `<ellipse cx="124" cy="203" rx="10" ry="16" fill="${C.skin}" ${sw(4)}/>`,
    `<ellipse cx="236" cy="203" rx="10" ry="16" fill="${C.skin}" ${sw(4)}/>`,
    P('M125 198 Q120 204 126 212', 'none', 2.5), P('M235 198 Q240 204 234 212', 'none', 2.5),
    P('M124 178 C116 122 146 104 180 104 C214 104 244 122 236 178 Z', C.hair),
    P('M150 110 L158 92 L166 108 L176 88 L184 106 L196 90 L200 110 Z', C.hair, 0),
    P('M126 150 C124 214 140 258 180 271 C220 258 236 214 234 150 Z', C.skin),
    P('M126 160 C150 150 160 168 180 156 C200 168 212 150 234 160 L234 150 L126 150 Z', C.hair, 0),
    P('M127 160 L143 160 L138 194 L130 200 Z', C.hair, 0),
    P(mirror('M127 160 L143 160 L138 194 L130 200 Z'), C.hair, 0),
    P('M140 244 Q146 252 152 254', 'none', 2.5), P(mirror('M140 244 Q146 252 152 254'), 'none', 2.5),
    P('M182 220 L185 234', 'none', 2.5),
    P('M171 238 Q175 243 180 239 Q185 243 189 238', 'none', 3)
  ].join('');
}

function brimShadow() {
  return `<clipPath id="fc"><path d="M126 150 C124 214 140 258 180 271 C220 258 236 214 234 150 Z"/></clipPath>
  <path clip-path="url(#fc)" d="M120 160 L240 160 L240 178 C210 190 150 190 120 178 Z" fill="${C.skinS}"/>`;
}

function hat(dx = 0, dy = 0, rot = 0) {
  return `<g transform="translate(${dx} ${dy}) rotate(${rot} 180 150)">
    ${P('M124 152 C118 110 128 80 150 70 Q180 88 210 70 C232 80 242 110 236 152 Z', C.hat)}
    ${P('M130 140 C126 110 134 86 150 76 Q144 104 150 136 Z', C.hatL, 0)}
    ${P('M210 76 C230 88 236 114 232 140 Q222 110 214 92 Z', C.hatD, 0)}
    ${P('M152 92 Q160 86 166 96 Q158 94 152 100 Z', O, 0)}
    ${P(mirror('M152 92 Q160 86 166 96 Q158 94 152 100 Z'), O, 0)}
    ${P('M174 84 Q180 100 186 84 Q182 96 180 108 Q178 96 174 84 Z', O, 0)}
    ${P('M123 128 C150 137 210 137 237 128 L238 152 C210 160 150 160 122 152 Z', C.band)}
    ${P('M86 170 C92 142 140 140 180 140 C220 140 268 142 274 170 C250 182 220 178 180 178 C140 178 110 182 86 170 Z', C.hat)}
    ${P('M96 166 C120 156 150 154 180 154 C210 154 240 156 264 166 C240 172 210 170 180 170 C150 170 120 172 96 166 Z', C.hatD, 0)}
    ${P('M100 162 C120 150 150 147 172 148 C150 152 124 156 104 166 Z', C.hatL, 0)}
  </g>`;
}

const brows = {
  stern: [P('M134 190 L171 201 L169 193 L139 181 Z', O, 2), P(mirror('M134 190 L171 201 L169 193 L139 181 Z'), O, 2)],
  happy: [P('M138 186 Q154 170 170 181 Q154 176 140 192 Z', O, 2), P(mirror('M138 186 Q154 170 170 181 Q154 176 140 192 Z'), O, 2)],
  pain: [P('M136 200 L168 184 L171 191 L139 207 Z', O, 2), P(mirror('M136 200 L168 184 L171 191 L139 207 Z'), O, 2)],
  think: [P('M136 196 L170 197 L170 190 L137 188 Z', O, 2), P('M190 182 Q208 160 226 180 Q208 168 192 190 Z', O, 2)]
};

function eyesOpen(px = 0, py = 0, lidL = 0, lidR = 0) {
  const one = (cx, lid) => `
    <ellipse cx="${cx}" cy="209" rx="14.5" ry="13" fill="#fff" ${sw(3.5)}/>
    <g class="pupil"><circle cx="${cx + px}" cy="${210 + py}" r="7.4" fill="${O}"/>
    <circle cx="${cx + px + 2.5}" cy="${207 + py}" r="1.8" fill="#fff"/></g>
    ${lid ? `<path d="M${cx - 15} ${197 + lid} L${cx + 15} ${197 + lid} L${cx + 15} 194 L${cx - 15} 194 Z" fill="${C.skin}"/><path d="M${cx - 14} ${197 + lid} L${cx + 14} ${197 + lid}" ${sw(4)}/>` : P(`M${cx - 13} 206 Q${cx} 194 ${cx + 13} 206`, 'none', 5)}`;
  return one(155, lidL) + one(205, lidR);
}

const expr = {
  investigando: () => brows.stern.join('') + eyesOpen(1, 1, 7, 7) +
    P('M164 257 Q180 250 196 257', 'none', 4) + P('M174 265 L186 265', 'none', 2.5),
  alegria: () => brows.happy.join('') +
    P('M145 212 Q157 196 169 212', 'none', 5) + P('M191 212 Q203 196 215 212', 'none', 5) +
    P('M150 240 Q180 234 210 240 Q206 280 180 281 Q154 280 150 240 Z', C.mouth, 4) +
    P('M162 268 Q180 256 198 268 Q192 280 180 280 Q168 280 162 268 Z', C.tongue, 0) +
    P('M154 241 Q180 237 206 241 L204 249 Q180 245 156 249 Z', '#fff', 0) +
    `<ellipse cx="141" cy="232" rx="9" ry="5" fill="${C.blush}" opacity="0.55"/><ellipse cx="219" cy="232" rx="9" ry="5" fill="${C.blush}" opacity="0.55"/>`,
  risa: () => brows.happy.join('') +
    P('M145 212 Q157 196 169 212', 'none', 5) + P('M191 212 Q203 196 215 212', 'none', 5) +
    P('M150 242 Q180 236 210 242 Q203 264 180 266 Q157 264 150 242 Z', C.mouth, 4) +
    P('M155 243 Q180 239 205 243 L203 250 Q180 246 157 250 Z', '#fff', 0) +
    `<ellipse cx="141" cy="232" rx="9" ry="5" fill="${C.blush}" opacity="0.55"/><ellipse cx="219" cy="232" rx="9" ry="5" fill="${C.blush}" opacity="0.55"/>`,
  triste: () => P('M136 198 L168 186 L170 192 L139 204 Z', O, 2) + P('M224 198 L192 186 L190 192 L221 204 Z', O, 2) +
    eyesOpen(0, 4, 9, 9) + P('M164 263 Q180 251 196 263', 'none', 4) + P('M174 268 Q180 266 186 268', 'none', 2),
  llanto: () => brows.pain.join('') +
    P('M145 206 Q157 216 169 206', 'none', 5) + P('M191 206 Q203 216 215 206', 'none', 5) +
    P('M150 212 Q146 236 152 262', 'none', 0).replace('/>', ` stroke="#7FC4EC" stroke-width="7" stroke-linecap="round" opacity="0.85"/>`) +
    P('M210 212 Q214 236 208 262', 'none', 0).replace('/>', ` stroke="#7FC4EC" stroke-width="7" stroke-linecap="round" opacity="0.85"/>`) +
    P('M160 252 Q180 244 200 252 Q199 278 180 280 Q161 278 160 252 Z', C.mouth, 4) +
    P('M166 270 Q180 262 194 270 Q188 280 180 280 Q172 280 166 270 Z', C.tongue, 0),
  llanto2: () => brows.pain.join('') +
    P('M145 206 Q157 216 169 206', 'none', 5) + P('M191 206 Q203 216 215 206', 'none', 5) +
    P('M150 212 Q146 236 152 262', 'none', 0).replace('/>', ` stroke="#7FC4EC" stroke-width="7" stroke-linecap="round" opacity="0.85"/>`) +
    P('M210 212 Q214 236 208 262', 'none', 0).replace('/>', ` stroke="#7FC4EC" stroke-width="7" stroke-linecap="round" opacity="0.85"/>`) +
    P('M162 256 Q180 250 198 256 Q194 270 180 271 Q166 270 162 256 Z', C.mouth, 4),
  alivio: () => brows.happy.join('') +
    P('M145 210 Q157 218 169 210', 'none', 5) + P('M191 210 Q203 218 215 210', 'none', 5) + P('M164 254 Q180 264 196 254', 'none', 4),
  agonia: () => brows.pain.join('') +
    P('M145 201 L166 210 L145 219', 'none', 5) + P('M215 201 L194 210 L215 219', 'none', 5) +
    P('M148 214 Q142 240 150 266', 'none', 0).replace('/>', ` stroke="#7FC4EC" stroke-width="6" stroke-linecap="round" opacity="0.85"/>`) +
    P('M212 214 Q218 240 210 266', 'none', 0).replace('/>', ` stroke="#7FC4EC" stroke-width="6" stroke-linecap="round" opacity="0.85"/>`) +
    P('M150 240 Q180 232 210 240 Q207 288 180 290 Q153 288 150 240 Z', C.mouth, 4) +
    P('M154 241 Q180 235 206 241 L204 249 Q180 244 156 249 Z', '#fff', 0) +
    P('M162 276 Q180 264 198 276 Q190 290 180 290 Q170 290 162 276 Z', C.tongue, 0),
  mueca: () => brows.pain[0] + P('M224 190 L192 194 L191 188 L222 182 Z', O, 2) +
    P('M145 201 L166 210 L145 219', 'none', 5) +
    `<ellipse cx="205" cy="210" rx="12" ry="10" fill="#fff" ${sw(3.5)}/><g class="pupil"><circle cx="203" cy="211" r="6.4" fill="${O}"/></g>` +
    P('M160 252 L200 247 L198 262 L163 264 Z', '#fff', 3.5) + P('M161 257 L199 254', 'none', 2) + P('M180 250 L181 263', 'none', 2),
  dolor: () => brows.pain.join('') +
    P('M145 201 L166 210 L145 219', 'none', 5) + P('M215 201 L194 210 L215 219', 'none', 5) +
    P('M150 247 Q180 241 210 247 L206 266 Q180 271 154 266 Z', '#fff', 4) +
    [163, 172, 180, 188, 197].map(x => P(`M${x} 245 L${x} 268`, 'none', 2)).join('') +
    P('M152 256 Q180 252 208 256', 'none', 2),
  normal: () => P('M136 191 L170 195 L170 188 L138 184 Z', O, 2) + P('M224 191 L190 195 L190 188 L222 184 Z', O, 2) +
    eyesOpen(0, 0, 5, 5) + P('M167 256 Q180 259 193 255', 'none', 4),
  curiosidad: () => P('M136 184 Q152 166 170 178 Q152 172 138 190 Z', O, 2) + P('M190 182 Q206 170 222 182 Q206 178 192 188 Z', O, 2) +
    eyesOpen(0, 0, 0, 0) + `<ellipse cx="181" cy="258" rx="6" ry="7.5" fill="${C.mouth}" ${sw(3.5)}/>`,
  reflexion: () => brows.think.join('') + eyesOpen(4, -4, 8, 0) +
    P('M160 258 Q170 260 182 252', 'none', 4) + P('M178 250 Q184 249 186 254', 'none', 3)
};

function magnifier() {
  return [
    P('M28 440 C38 400 68 370 100 356 L120 380 C96 392 74 412 72 440 Z', C.coat),
    
    `<line x1="126" y1="346" x2="108" y2="314" stroke="${O}" stroke-width="13" stroke-linecap="round"/>`,
    `<line x1="126" y1="346" x2="108" y2="314" stroke="${C.rim}" stroke-width="7" stroke-linecap="round"/>`,
    `<circle cx="96" cy="286" r="31" fill="${C.lens}" opacity="0.92"/>`,
    `<circle cx="96" cy="286" r="31" fill="none" stroke="${O}" stroke-width="14"/>`,
    `<circle cx="96" cy="286" r="31" fill="none" stroke="${C.rim}" stroke-width="8"/>`,
    P('M80 280 L100 266', 'none', 0).replace('/>', ` stroke="#fff" stroke-width="5" stroke-linecap="round"/>`),
    `<rect x="100" y="332" width="48" height="46" rx="15" fill="${C.skin}" ${sw(4)}/>`,
    P('M106 350 Q126 346 144 352', 'none', 2.5), P('M107 362 Q126 358 144 364', 'none', 2.5),
    P('M118 338 L117 348', 'none', 2), P('M130 338 L130 347', 'none', 2)
  ].join('');
}

function chinHand() {
  return [
    P('M292 440 C290 392 256 338 222 312 L188 330 C214 360 240 404 246 440 Z', C.coat),
    P('M222 312 L188 330 L184 320 L218 302 Z', C.shirt, 3),
    `<rect x="166" y="270" width="54" height="44" rx="16" fill="${C.skin}" ${sw(4)}/>`,
    P('M204 276 C214 266 222 254 230 236 C233 230 241 232 240 240 C236 256 228 270 218 282 Z', C.skin),
    P('M168 284 Q192 280 214 286', 'none', 2.5), P('M169 297 Q192 293 216 299', 'none', 2.5),
    P('M178 271 L177 282', 'none', 2), P('M191 270 L190 281', 'none', 2)
  ].join('');
}

const fx = {
  investigando: () => '',
  alegria: () => [[78, 120, 12], [290, 110, 14], [276, 210, 9], [86, 220, 8]].map(([x, y, r]) =>
    P(`M${x} ${y - r} Q${x + r * .2} ${y - r * .2} ${x + r} ${y} Q${x + r * .2} ${y + r * .2} ${x} ${y + r} Q${x - r * .2} ${y + r * .2} ${x - r} ${y} Q${x - r * .2} ${y - r * .2} ${x} ${y - r} Z`, C.star, 3)).join(''),
  dolor: () => {
    const star = (x, y, r) => { let d = ''; for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, rr = i % 2 ? r * .45 : r; d += (i ? 'L' : 'M') + (x + Math.cos(a) * rr).toFixed(1) + ' ' + (y + Math.sin(a) * rr).toFixed(1) + ' '; } return P(d + 'Z', C.star, 3); };
    return star(108, 62, 15) + star(180, 40, 13) + star(256, 58, 15) +
      P('M106 64 Q180 20 258 60', 'none', 0).replace('/>', ` stroke="${O}" stroke-width="2" stroke-dasharray="6 7"/>`) +
      P('M244 176 Q236 192 244 198 Q252 192 244 176 Z', C.sweat, 3) + P('M118 188 Q112 200 118 206 Q124 200 118 188 Z', C.sweat, 3) +
      P('M96 196 Q88 210 96 224', 'none', 3.5) + P('M84 190 Q74 210 84 230', 'none', 3.5) +
      P('M264 196 Q272 210 264 224', 'none', 3.5) + P('M276 190 Q286 210 276 230', 'none', 3.5);
  },
  reflexion: () => `<text x="290" y="92" font-family="Arial Black, Arial, sans-serif" font-weight="900" font-size="64" fill="${C.tie}" stroke="${O}" stroke-width="3.5" paint-order="stroke">?</text>` +
    `<circle cx="292" cy="140" r="5" fill="#fff" ${sw(3)}/><circle cx="304" cy="118" r="7" fill="#fff" ${sw(3)}/>`
};

const hatPose = { investigando: [0, 4, 0], alegria: [-4, -22, -10], dolor: [10, 2, 12], reflexion: [-3, 0, -5] };

function panel(name) {
  const [hx, hy, hr] = hatPose[name];
  const extra = name === 'investigando' ? magnifier() : name === 'reflexion' ? chinHand() : '';
  const lift = name === 'alegria' ? -6 : 0;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 440" width="360" height="440">
    <g transform="translate(0 ${lift})">${body()}<g transform="translate(180 268) scale(1.13) translate(-180 -268)">${headBase()}${name === 'alegria' ? '' : brimShadow()}${expr[name]()}${hat(hx, hy, hr)}</g></g>
    ${extra}${fx[name]()}</svg>`;
}

module.exports = { panel, headBase, brimShadow, hat, expr, C, O, sw, P };
