// Administrador de ventanas: crea el marco de cada app, maneja foco, arrastre,
// minimizar/maximizar/cerrar y re-renderiza el contenido de las visibles.
import { h, raw, patch, pixelSvg } from './dom.js';
import { click } from './audio.js';

const GLYPHS = {
  min: pixelSvg(['000000', '000000', '000000', '000000', '000000', '000000', '111111', '111111']),
  max: pixelSvg(['111111111', '111111111', '100000001', '100000001', '100000001', '100000001', '100000001', '100000001', '111111111']),
  restore: pixelSvg(['00111111', '00111111', '00100001', '11111101', '11111101', '10000111', '10000100', '10000100', '11111100']),
  close: pixelSvg(['11000011', '01100110', '00111100', '00011000', '00111100', '01100110', '11000011']),
};

export class App {
  /** @param {import('./game.js').Game} game */
  constructor(game) {
    this.game = game;
    this.win = null; // estado de ventana (lo asigna el WM)
  }
  // Valores por defecto que cada app sobrescribe
  get id() { return 'app'; }
  get title() { return 'Aplicación'; }
  get icon() { return null; }
  get size() { return { w: 400, h: 300 }; }
  get minimizeOnly() { return false; }
  get canMaximize() { return true; }
  render() { return ''; }
  onAction() {}
  update() {}
  afterRender() {}
  onOpen() {}
  onClose() {}
  save() { return null; }
  load() {}
}

export class WindowManager {
  constructor(game, root) {
    this.game = game;
    this.root = root;
    this.apps = new Map();
    this.order = []; // ids de abajo hacia arriba
    this.cascade = 0;
    this.onChange = () => {};
  }

  register(app) {
    const id = app.id;
    const { w, h: hh } = app.size;
    const el = document.createElement('div');
    el.className = 'window hidden';
    el.dataset.win = id;
    el.innerHTML = String(h`
      <div class="title-bar">
        ${app.icon ? h`<img class="title-icon" src="${app.icon}" alt="">` : ''}
        <span class="title-text"></span>
        <div class="title-controls">
          <button data-wm="min" aria-label="Minimizar">${raw(GLYPHS.min)}</button>
          ${app.minimizeOnly ? '' : h`
            ${app.canMaximize ? h`<button data-wm="max" aria-label="Maximizar">${raw(GLYPHS.max)}</button>` : ''}
            <button data-wm="close" aria-label="Cerrar">${raw(GLYPHS.close)}</button>`}
        </div>
      </div>
      <div class="window-body"><div class="app app-${id}"></div></div>`);
    this.root.appendChild(el);

    const state = { id, el, body: el.querySelector('.app'), titleEl: el.querySelector('.title-text'),
      x: 0, y: 0, w, h: hh, open: false, minimized: false, maximized: false, lastHtml: '', lastTitle: '' };
    app.win = state;
    this.apps.set(id, app);
    this.bindWindow(app, state);
    return app;
  }

  get(id) { return this.apps.get(id); }

  bindWindow(app, s) {
    const el = s.el;
    el.addEventListener('pointerdown', () => this.focus(app.id), true);

    // Botones de título
    el.querySelector('.title-controls').addEventListener('click', (e) => {
      const b = e.target.closest('[data-wm]');
      if (!b) return;
      e.stopPropagation();
      const a = b.dataset.wm;
      if (a === 'min') this.minimize(app.id);
      else if (a === 'max') this.toggleMax(app.id);
      else if (a === 'close') this.close(app.id);
    });

    // Arrastrar por la barra de título
    const bar = el.querySelector('.title-bar');
    bar.addEventListener('dblclick', (e) => {
      if (e.target.closest('[data-wm]')) return;
      if (!app.minimizeOnly && app.canMaximize) this.toggleMax(app.id);
    });
    bar.addEventListener('pointerdown', (e) => {
      if (e.button !== 0 || e.target.closest('[data-wm]') || s.maximized) return;
      const scale = this.game.scale;
      const sx = e.clientX, sy = e.clientY, ox = s.x, oy = s.y;
      bar.setPointerCapture(e.pointerId);
      const move = (ev) => {
        s.x = Math.round(ox + (ev.clientX - sx) / scale);
        s.y = Math.round(oy + (ev.clientY - sy) / scale);
        const maxX = this.game.screenW - 40, maxY = this.game.screenH - 28 - 20;
        s.x = Math.max(-s.w + 60, Math.min(maxX, s.x));
        s.y = Math.max(0, Math.min(maxY, s.y));
        this.place(s);
      };
      const up = () => { bar.removeEventListener('pointermove', move); bar.removeEventListener('pointerup', up); };
      bar.addEventListener('pointermove', move);
      bar.addEventListener('pointerup', up);
    });

    // Acciones dentro de la app (delegación de eventos)
    s.body.addEventListener('click', (e) => {
      const t = e.target.closest('[data-action]');
      if (!t || t.disabled || t.classList.contains('disabled')) return;

      app.onAction(t.dataset.action, t.dataset, e);
      this.renderApp(app, true);
      this.game.emit('changed');
    });
    s.body.addEventListener('dblclick', (e) => {
      const t = e.target.closest('[data-dbl]');
      if (!t) return;
      app.onAction(t.dataset.dbl, t.dataset, e);
      this.renderApp(app, true);
    });
    s.body.addEventListener('pointerdown', (e) => {
      const t = e.target.closest('[data-down]');
      if (!t) return;
      app.onAction(t.dataset.down, t.dataset, e);
    });
    s.body.addEventListener('wheel', (e) => { if (app.onWheel) app.onWheel(e); }, { passive: true });
  }

  place(s) {
    s.el.style.left = s.x + 'px';
    s.el.style.top = s.y + 'px';
    s.el.style.width = s.w + 'px';
    s.el.style.height = s.h + 'px';
  }

  isOpen(id) { const a = this.get(id); return !!(a && a.win.open); }
  isVisible(id) { const a = this.get(id); return !!(a && a.win.open && !a.win.minimized); }

  open(id) {
    const app = this.get(id);
    if (!app) return;
    const s = app.win;
    if (!s.open) {
      s.open = true;
      if (!s.placed) {
        const { screenW, screenH } = this.game;
        const off = (this.cascade++ % 8) * 22;
        s.x = Math.max(4, Math.min(screenW - s.w - 4, Math.round((screenW - s.w) / 2) - 90 + off));
        s.y = Math.max(4, Math.min(screenH - 28 - s.h - 4, Math.round((screenH - 28 - s.h) / 2) - 70 + off));
        s.placed = true;
      }
      this.place(s);
      s.el.classList.remove('hidden');
      s.el.classList.add('opening');
      setTimeout(() => s.el.classList.remove('opening'), 150);
      app.onOpen();
    }
    s.minimized = false;
    s.el.classList.remove('minimized');
    this.focus(id);
    this.renderApp(app, true);
    this.onChange();
  }

  close(id) {
    const app = this.get(id);
    if (!app || !app.win.open) return;
    app.win.open = false;
    app.win.minimized = false;
    app.win.el.classList.add('hidden');
    this.order = this.order.filter((x) => x !== id);
    app.onClose();
    this.refreshActive();
    this.onChange();
  }

  minimize(id) {
    const app = this.get(id);
    if (!app) return;
    app.win.minimized = true;
    app.win.el.classList.add('minimized');
    this.refreshActive();
    this.onChange();
  }

  toggle(id) {
    const app = this.get(id);
    if (!app) return;
    if (!app.win.open || app.win.minimized || this.activeId() !== id) this.open(id);
    else this.minimize(id);
  }

  toggleMax(id) {
    const app = this.get(id);
    if (!app) return;
    app.win.maximized = !app.win.maximized;
    app.win.el.classList.toggle('maximized', app.win.maximized);
    const btn = app.win.el.querySelector('[data-wm="max"]');
    if (btn) btn.innerHTML = app.win.maximized ? GLYPHS.restore : GLYPHS.max;
    this.renderApp(app, true);
  }

  focus(id) {
    this.order = this.order.filter((x) => x !== id);
    this.order.push(id);
    this.order.forEach((wid, i) => { this.get(wid).win.el.style.zIndex = 10 + i; });
    this.refreshActive();
  }

  activeId() {
    for (let i = this.order.length - 1; i >= 0; i--) {
      const a = this.get(this.order[i]);
      if (a.win.open && !a.win.minimized) return a.id;
    }
    return null;
  }

  refreshActive() {
    const act = this.activeId();
    for (const app of this.apps.values()) app.win.el.classList.toggle('active', app.id === act);
    this.onChange();
  }

  closeAll() { for (const id of [...this.order]) this.close(id); }

  openList() {
    return [...this.apps.values()].filter((a) => a.win.open);
  }

  renderApp(app, force = false) {
    const s = app.win;
    if (!s.open || s.minimized) return;
    const title = app.title;
    if (title !== s.lastTitle) { s.titleEl.textContent = title; s.lastTitle = title; }
    const html = String(app.render());
    if (force || html !== s.lastHtml) {
      patch(s.body, html);
      s.lastHtml = html;
    }
    app.afterRender(s.body);
  }

  renderAll() { for (const app of this.apps.values()) this.renderApp(app); }
}
