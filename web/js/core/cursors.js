// Cursores de Windows 95 dibujados en píxeles. Se generan al tamaño de la
// pantalla escalada, para que el mouse tenga la misma proporción que el resto.
const ARROW = [
  'B...........',
  'BB..........',
  'BWB.........',
  'BWWB........',
  'BWWWB.......',
  'BWWWWB......',
  'BWWWWWB.....',
  'BWWWWWWB....',
  'BWWWWWWWB...',
  'BWWWWWWWWB..',
  'BWWWWWBBBBB.',
  'BWWBWWB.....',
  'BWB.BWWB....',
  'BB..BWWB....',
  'B....BWWB...',
  '.....BWWB...',
  '......BWWB..',
  '......BWWB..',
  '.......BB...',
];

const HAND = [
  '.....BB..........',
  '....BWWB.........',
  '....BWWB.........',
  '....BWWB.........',
  '....BWWB.........',
  '....BWWBBB.......',
  '....BWWBWWBBB....',
  '....BWWBWWBWWBB..',
  '.BB.BWWBWWBWWBWB.',
  'BWWBBWWWWWWWWBWWB',
  'BWWWBWWWWWWWWWWWB',
  '.BWWBWWWWWWWWWWWB',
  '..BWWWWWWWWWWWWWB',
  '..BWWWWWWWWWWWWB.',
  '...BWWWWWWWWWWWB.',
  '...BWWWWWWWWWWB..',
  '....BWWWWWWWWWB..',
  '....BWWWWWWWWWB..',
  '....BBBBBBBBBBB..',
];

const BUSY = [
  'BBBBBBBBBBB',
  'B.........B',
  '.BWWWWWWWB.',
  '.BWWWWWWWB.',
  '.BWBWBWBWB.',
  '..BWBWBWB..',
  '...BWBWB...',
  '....BWB....',
  '....BWB....',
  '...BWWWB...',
  '..BWWBWWB..',
  '.BWWWWWWWB.',
  '.BWWBWBWWB.',
  '.BWBWBWBWB.',
  'B.........B',
  'BBBBBBBBBBB',
];

function svg(rows, px) {
  const w = rows[0].length, h = rows.length;
  let r = '';
  rows.forEach((row, y) => {
    for (let x = 0; x < w; x++) {
      const c = row[x];
      if (c === 'B') r += `<rect x='${x}' y='${y}' width='1' height='1' fill='black'/>`;
      else if (c === 'W') r += `<rect x='${x}' y='${y}' width='1' height='1' fill='white'/>`;
    }
  });
  const s = `<svg xmlns='http://www.w3.org/2000/svg' width='${Math.round(w * px)}' height='${Math.round(h * px)}' viewBox='0 0 ${w} ${h}' shape-rendering='crispEdges'>${r}</svg>`;
  return `url("data:image/svg+xml,${encodeURIComponent(s)}")`;
}

/** Actualiza las variables CSS de cursor según la escala de la pantalla. */
export function applyCursors(el, scale) {
  const px = Math.max(1, Math.round(scale * 2) / 2); // múltiplos de 0,5 para que no se deformen
  el.style.setProperty('--cur-arrow', `${svg(ARROW, px)} 0 0, default`);
  el.style.setProperty('--cur-hand', `${svg(HAND, px)} ${Math.round(5 * px)} 0, pointer`);
  el.style.setProperty('--cur-busy', `${svg(BUSY, px)} ${Math.round(5 * px)} ${Math.round(8 * px)}, progress`);
}
