// Utilidades de DOM: escape, plantillas y un "morph" mínimo para re-renderizar
// el contenido de las ventanas sin destruir los elementos (así los clics y el
// hover no se pierden aunque el contenido se actualice muchas veces por segundo).

const ESC = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
export const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ESC[c]);

class Raw { constructor(v) { this.v = v; } toString() { return this.v; } }
export const raw = (v) => new Raw(v);

function val(v) {
  if (v == null || v === false) return '';
  if (v instanceof Raw) return v.v;
  if (Array.isArray(v)) return v.map(val).join('');
  return esc(v);
}

/** Plantilla con escape automático. Usa raw() para insertar HTML. */
export function h(strings, ...values) {
  let out = strings[0];
  for (let i = 0; i < values.length; i++) out += val(values[i]) + strings[i + 1];
  return raw(out);
}

export const $ = (sel, root = document) => root.querySelector(sel);

/** Reemplaza el contenido de `target` por `html` reutilizando los nodos existentes. */
export function patch(target, html) {
  const tpl = document.createElement('template');
  tpl.innerHTML = String(html);
  morphChildren(target, tpl.content);
}

function morphChildren(from, to) {
  const a = Array.from(from.childNodes);
  const b = Array.from(to.childNodes);
  for (let i = 0; i < b.length; i++) {
    const nb = b[i];
    const na = a[i];
    if (!na) { from.appendChild(nb); continue; }
    if (na.nodeType !== nb.nodeType || na.nodeName !== nb.nodeName ||
        (na.nodeType === 1 && na.getAttribute('data-key') !== nb.getAttribute('data-key'))) {
      from.replaceChild(nb, na);
      continue;
    }
    if (na.nodeType !== 1) {
      if (na.nodeValue !== nb.nodeValue) na.nodeValue = nb.nodeValue;
      continue;
    }
    morphAttrs(na, nb);
    if (na.hasAttribute('data-keep')) continue;
    morphChildren(na, nb);
  }
  for (let i = a.length - 1; i >= b.length; i--) from.removeChild(a[i]);
}

function morphAttrs(a, b) {
  for (const attr of Array.from(a.attributes)) {
    if (!b.hasAttribute(attr.name)) a.removeAttribute(attr.name);
  }
  for (const attr of Array.from(b.attributes)) {
    if (a.getAttribute(attr.name) !== attr.value) a.setAttribute(attr.name, attr.value);
  }
  if (a.disabled !== b.disabled) a.disabled = b.disabled;
}

/** SVG de píxeles a partir de filas de '0'/'1' (para glifos de botones). */
export function pixelSvg(rows, color = '#000') {
  const w = rows[0].length;
  const hgt = rows.length;
  let d = '';
  rows.forEach((row, y) => {
    for (let x = 0; x < w; x++) if (row[x] === '1') d += `M${x} ${y}h1v1h-1z`;
  });
  return `<svg width="${w}" height="${hgt}" viewBox="0 0 ${w} ${hgt}" shape-rendering="crispEdges"><path d="${d}" fill="${color}"/></svg>`;
}

export const fmt = (n) => Math.floor(n).toLocaleString('es-CL');
export const money = (n) => '$' + fmt(n);
export const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
export const rand = (arr) => arr[Math.floor(Math.random() * arr.length)];
export const randInt = (a, b) => a + Math.floor(Math.random() * (b - a + 1));
