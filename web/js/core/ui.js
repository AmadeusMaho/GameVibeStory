// Cuadros de mensaje, notificaciones y diálogos de progreso al estilo de la era.
import { h, raw, esc } from './dom.js';
import { play } from './audio.js';

export const ICONS = {
  error: `<svg width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="#e00000" stroke="#600" stroke-width="1.5"/><path d="M10 10l12 12M22 10L10 22" stroke="#fff" stroke-width="3.6" stroke-linecap="square"/></svg>`,
  warning: `<svg width="32" height="32" viewBox="0 0 32 32"><path d="M16 2L31 29H1z" fill="#ffff00" stroke="#000" stroke-width="1.5" stroke-linejoin="round"/><rect x="14.2" y="10" width="3.6" height="11" fill="#000"/><rect x="14.2" y="23" width="3.6" height="3.4" fill="#000"/></svg>`,
  info: `<svg width="32" height="32" viewBox="0 0 32 32"><path d="M16 2a13 12 0 1 1-7 22l-6 6 2-8A13 12 0 0 1 16 2z" fill="#fff" stroke="#000" stroke-width="1.2"/><circle cx="16" cy="8.5" r="2.2" fill="#0000c0"/><path d="M13 12h5v9h2v2h-7v-2h2v-7h-2z" fill="#0000c0"/></svg>`,
  question: `<svg width="32" height="32" viewBox="0 0 32 32"><path d="M16 2a13 12 0 1 1-7 22l-6 6 2-8A13 12 0 0 1 16 2z" fill="#fff" stroke="#000" stroke-width="1.2"/><text x="16" y="21" font-family="Arial" font-weight="bold" font-size="16" text-anchor="middle" fill="#0000c0">?</text></svg>`,
};

const SOUND_FOR = { error: 'error', warning: 'ding', info: 'ding', question: 'ding' };

let modalRoot = null;
let toastRoot = null;
export function initUI(modals, toasts) { modalRoot = modals; toastRoot = toasts; }

/**
 * Cuadro de mensaje modal. Devuelve una promesa con el índice del botón.
 * opts: { title, icon, text, buttons, timeout, sound }
 */
export function msgBox({ title = 'Windows', icon = 'info', text = '', buttons = ['Aceptar'], timeout = 0, sound = true } = {}) {
  return new Promise((resolve) => {
    const layer = document.createElement('div');
    layer.className = 'modal-layer block';
    layer.innerHTML = String(h`
      <div class="window dialog active">
        <div class="title-bar"><span class="title-text">${title}</span>
          <div class="title-controls"><button data-i="${buttons.length - 1}" aria-label="Cerrar">${raw(closeGlyph)}</button></div>
        </div>
        <div class="window-body">
          <div class="msg-body">${icon ? raw(ICONS[icon]) : ''}<div class="msg-text">${text}</div></div>
          <div class="msg-buttons">${buttons.map((b, i) => h`<button class="btn ${i === 0 ? 'default' : ''}" data-i="${i}">${b}</button>`)}</div>
        </div>
      </div>`);
    modalRoot.appendChild(layer);
    if (sound && icon) play(SOUND_FOR[icon] || 'ding', { volume: 0.5 });
    let done = false;
    const finish = (i) => {
      if (done) return;
      done = true;
      layer.remove();
      resolve(i);
    };
    layer.addEventListener('click', (e) => {
      const b = e.target.closest('[data-i]');
      if (b) finish(Number(b.dataset.i));
    });
    layer.querySelector('.btn')?.focus();
    if (timeout) setTimeout(() => finish(-1), timeout);
  });
}

/** Diálogo con barra de progreso que se completa sola (p. ej. instalar hardware). */
export function progressDialog({ title, text, duration = 2500, icon = null }) {
  return new Promise((resolve) => {
    const layer = document.createElement('div');
    layer.className = 'modal-layer block';
    layer.innerHTML = String(h`
      <div class="window dialog active" style="width:360px">
        <div class="title-bar"><span class="title-text">${title}</span></div>
        <div class="window-body" style="padding:12px 12px 14px">
          <div class="flex gap8" style="align-items:center">${icon ? raw(icon) : ''}<div class="msg-text" style="padding:0">${text}</div></div>
          <div class="progress mt8"><div class="fill" style="width:0%"></div></div>
          <div class="dim mt4 pct">0% completado</div>
        </div>
      </div>`);
    modalRoot.appendChild(layer);
    const fill = layer.querySelector('.fill');
    const pct = layer.querySelector('.pct');
    const t0 = performance.now();
    const step = () => {
      const p = Math.min(1, (performance.now() - t0) / duration);
      const shown = Math.floor(Math.min(1, p * 1.08) * 100); // los instaladores nunca fueron lineales
      fill.style.width = Math.min(100, shown) + '%';
      pct.textContent = Math.min(100, shown) + '% completado';
      if (p < 1) requestAnimationFrame(step);
      else setTimeout(() => { layer.remove(); resolve(); }, 250);
    };
    requestAnimationFrame(step);
  });
}

/** Globo de notificación en la esquina (logros, objetivos, correo nuevo). */
export function toast(title, text, { timeout = 4000, icon = null } = {}) {
  const el = document.createElement('div');
  el.className = 'toast';
  el.innerHTML = `${icon ? `<div style="float:left;margin-right:6px">${icon}</div>` : ''}<div class="t-title">${esc(title)}</div><div>${esc(text)}</div>`;
  toastRoot.appendChild(el);
  setTimeout(() => el.remove(), timeout);
}

const closeGlyph = `<svg width="8" height="7" viewBox="0 0 8 7" shape-rendering="crispEdges"><path d="M0 0h2v1h-2zM6 0h2v1h-2zM1 1h2v1h-2zM5 1h2v1h-2zM2 2h4v1h-4zM3 3h2v1h-2zM2 4h4v1h-4zM1 5h2v1h-2zM5 5h2v1h-2zM0 6h2v1h-2zM6 6h2v1h-2z"/></svg>`;

export function isModalOpen() { return modalRoot && modalRoot.children.length > 0; }
