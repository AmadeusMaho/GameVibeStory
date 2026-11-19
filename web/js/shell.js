// Escritorio, barra de tareas, menú Inicio y secuencias de pantalla completa
// (encendido, BIOS, splash, pantallazo azul, apagado).
import { h, raw, patch, money } from './core/dom.js';
import { play, click, initAudio, setMuted, isMuted } from './core/audio.js';
import { msgBox, ICONS } from './core/ui.js';
import { img } from './core/assets.js';
import * as Save from './core/save.js';
import { WALLPAPERS } from './apps/explorer.js';

// Íconos del escritorio: los cuatro base siempre están; el resto se desbloquea.
const BASE_ICONS = ['mypc', 'trabajo', 'email', 'recyclebin'];
export const ICON_DEFS = {
  mypc: { label: 'Mi PC', img: 'mypc', app: 'mypc' },
  trabajo: { label: 'Trabajo', img: 'trabajo', app: 'trabajo' },
  email: { label: 'Correo', img: 'email', app: 'email' },
  recyclebin: { label: 'Papelera de reciclaje', img: 'recyclebin', app: 'recyclebin' },
  notepad: { label: 'Objetivos', img: 'notepad', app: 'notepad' },
  explorer: { label: 'Internet Explorer', img: 'explorer', app: 'explorer' },
  personal: { label: 'Personal', img: 'staff', app: 'personal' },
  winamp: { label: 'Winamp', img: 'winamp', app: 'winamp' },
  achievements: { label: 'Logros', img: 'achievements', app: 'achievements' },
  coding: { label: 'Code Editor', img: 'coding', app: 'coding' },
  taller: { label: 'Taller', img: 'taller', app: 'taller' },
  download: { label: 'WinOptimizer Pro', img: 'download', special: 'malware' },
};

const START_FLAG = `<svg width="20" height="18" viewBox="0 0 20 18" shape-rendering="crispEdges">
  <path d="M3 3h2v1H3zM2 6h2v1H2zM1 9h2v1H1zM0 12h2v1H0z" fill="#000"/>
  <path d="M6 1l5 1v6l-5-1z" fill="#ff2a00"/><path d="M12 2l5-1v6l-5 1z" fill="#00b000"/>
  <path d="M5 8l5 1v6l-5-1z" fill="#0040ff"/><path d="M11 9l5-1v6l-5 1z" fill="#ffd800"/>
</svg>`;

export class Shell {
  constructor(game, el) {
    this.game = game;
    this.el = el;           // {screen, desktop, icons, taskbar, startMenu, fullscreen}
    this.selected = null;
    this.fresh = new Set();
    this.startOpen = false;
    this.crt = !document.body.classList.contains('crt-off');
    this.bindDesktop();
    this.bindTaskbar();
    game.on('icons', (id) => { if (id) { this.fresh.add(id); setTimeout(() => this.fresh.delete(id), 800); } });
    game.on('wallpaper', () => this.applyWallpaper());
  }

  // ------------------------------------------------------------ escritorio
  icons() { return [...BASE_ICONS, ...this.game.unlockedIcons.filter((i) => ICON_DEFS[i])]; }

  bindDesktop() {
    const { icons, desktop } = this.el;
    icons.addEventListener('pointerdown', (e) => {
      const ic = e.target.closest('.desk-icon');
      this.selected = ic ? ic.dataset.id : null;
      this.closeStart();
    });
    desktop.addEventListener('pointerdown', (e) => { if (e.target === desktop || e.target === icons) { this.selected = null; this.closeStart(); } });
    icons.addEventListener('dblclick', (e) => {
      const ic = e.target.closest('.desk-icon');
      if (ic) this.openIcon(ic.dataset.id);
    });
  }

  openIcon(id) {
    const def = ICON_DEFS[id];
    if (!def) return;

    if (def.special === 'malware') { this.game.lockIcon('download'); this.malware(); return; }
    this.game.wm.open(def.app);
  }

  renderIcons() {
    const g = this.game;
    const unread = g.apps.email.unread();
    patch(this.el.icons, h`${this.icons().map((id) => {
      const d = ICON_DEFS[id];
      return h`<div class="desk-icon ${this.selected === id ? 'selected' : ''} ${this.fresh.has(id) ? 'fresh' : ''}" data-id="${id}" data-key="${id}">
        <img src="${img(d.img)}" alt="">
        <div class="label">${d.label}${id === 'email' && unread ? h` <span class="badge">${unread}</span>` : ''}</div>
      </div>`;
    })}`);
  }

  applyWallpaper() {
    const w = WALLPAPERS.find((x) => x.id === (this.game.flags.wallpaper || 'teal')) || WALLPAPERS[0];
    this.el.desktop.style.backgroundColor = w.color;
    this.el.desktop.style.backgroundImage = w.image ? `url(${w.image})` : 'none';
  }

  // ------------------------------------------------------- barra de tareas
  bindTaskbar() {
    this.el.taskbar.addEventListener('pointerdown', (e) => {
      if (e.target.closest('.start-button')) { this.startOpen ? this.closeStart() : this.openStart(); return; }
      const t = e.target.closest('.task-btn');
      if (t) { this.closeStart(); this.game.wm.toggle(t.dataset.id); }
    });
    this.el.startMenu.addEventListener('click', (e) => {
      const it = e.target.closest('[data-start]');
      if (!it) return;

      this.closeStart();
      this.startAction(it.dataset.start);
    });
  }

  renderTaskbar() {
    const g = this.game;
    const act = g.wm.activeId();
    const now = new Date();
    const time = `${now.getHours()}:${String(now.getMinutes()).padStart(2, '0')}`;
    patch(this.el.taskbar, h`
      <button class="start-button ${this.startOpen ? 'open' : ''}">${raw(START_FLAG)}<span class="start-text">Inicio</span></button>
      <div class="vsep"></div>
      <div class="task-buttons">
        ${g.wm.openList().map((a) => h`<button class="task-btn ${a.id === act ? 'active' : ''}" data-id="${a.id}" data-key="${a.id}" title="${a.title}">
          ${a.icon ? h`<img src="${a.icon}" alt="">` : ''}<span>${a.title}</span></button>`)}
      </div>
      <div class="tray">
        ${g.musicOn ? h`<span title="Winamp">♫</span>` : ''}
        <span class="money" title="Dinero">${money(g.money)}</span>
        <span>${time}</span>
      </div>`);
  }

  // ------------------------------------------------------------ menú Inicio
  openStart() { this.startOpen = true; this.renderStart(); this.el.startMenu.classList.remove('hidden'); }
  closeStart() { this.startOpen = false; this.el.startMenu.classList.add('hidden'); }

  renderStart() {
    const g = this.game;
    const apps = this.icons().filter((id) => ICON_DEFS[id].app);
    const item = (action, label, icon, accel) => h`<div class="item clickable" data-start="${action}">
      ${icon ? (icon.startsWith('<') ? raw(icon) : h`<img src="${img(icon)}" alt="">`) : h`<span style="width:24px"></span>`}
      <span>${accel ? raw(label.replace(accel, `<u>${accel}</u>`)) : label}</span></div>`;
    patch(this.el.startMenu, h`
      <div class="banner"><span>Windows<b>95</b></span></div>
      <div class="items">
        ${apps.map((id) => item('app:' + id, ICON_DEFS[id].label, ICON_DEFS[id].img))}
        <div class="msep"></div>
        ${item('save', 'Guardar partida...', SAVE_ICON, 'G')}
        ${item('load', 'Cargar partida...', LOAD_ICON, 'C')}
        ${item('newgame', 'Nueva partida...', NEW_ICON, 'N')}
        <div class="msep"></div>
        ${item('crt', this.crt ? 'Efecto CRT: activado' : 'Efecto CRT: desactivado', CRT_ICON)}
        ${item('mute', isMuted() ? 'Sonido: desactivado' : 'Sonido: activado', SOUND_ICON)}
        <div class="msep"></div>
        ${item('shutdown', 'Apagar el sistema...', POWER_ICON, 'A')}
      </div>`);
  }

  async startAction(a) {
    const g = this.game;
    if (a.startsWith('app:')) { g.wm.open(ICON_DEFS[a.slice(4)].app); return; }
    if (a === 'save' || a === 'load') { this.slotDialog(a); return; }
    if (a === 'crt') { this.crt = !this.crt; document.body.classList.toggle('crt-off', !this.crt); localStorage.setItem('gamevibestory_crt', this.crt ? 'on' : 'off'); return; }
    if (a === 'mute') { setMuted(!isMuted()); return; }
    if (a === 'newgame') {
      const r = await msgBox({ title: 'Nueva partida', icon: 'warning', text: '¿Está seguro de que desea empezar una nueva partida?\n\nSe borrará el autoguardado (las ranuras manuales se conservan).', buttons: ['Sí', 'No'] });
      if (r === 0) { Save.remove('auto'); g.newGameRequested = true; location.reload(); }
      return;
    }
    if (a === 'shutdown') {
      const r = await msgBox({ title: 'Apagar Windows', icon: 'question', text: '¿Está seguro de que desea apagar el equipo?\n\nSu partida se guardará automáticamente.', buttons: ['Sí', 'No'] });
      if (r === 0) this.shutdown();
    }
  }

  // ------------------------------------------------- guardar / cargar
  slotDialog(type) {
    const g = this.game;
    const layer = document.createElement('div');
    layer.className = 'modal-layer block';
    let sel = 1;
    const render = () => {
      layer.innerHTML = String(h`<div class="window dialog active" style="width:380px">
        <div class="title-bar"><span class="title-text">${type === 'save' ? 'Guardar partida' : 'Cargar partida'}</span></div>
        <div class="window-body" style="padding:10px">
          <div>Seleccione una ranura:</div>
          <div class="list mt4" style="height:150px">
            ${Save.SLOTS.map((s) => {
              const d = Save.read(s);
              return h`<div class="row ${sel === s ? 'selected' : ''}" data-slot="${s}" style="padding:5px;display:block">
                <b>Ranura ${s}</b><br>${d ? `${money(d.money)} · ${d.stats.tasksCompleted} tareas · ${new Date(d.timestamp).toLocaleString('es-CL')}` : '[Vacía]'}</div>`;
            })}
          </div>
          <div class="msg-buttons"><button class="btn default" data-ok>${type === 'save' ? 'Guardar' : 'Cargar'}</button><button class="btn" data-cancel>Cancelar</button></div>
        </div></div>`);
    };
    render();
    this.el.modals.appendChild(layer);
    layer.addEventListener('click', async (e) => {
      const row = e.target.closest('[data-slot]');
      if (row) { sel = Number(row.dataset.slot); render(); return; }
      if (e.target.closest('[data-cancel]')) { layer.remove(); return; }
      if (e.target.closest('[data-ok]')) {
        layer.remove();
        if (type === 'save') {
          const ok = Save.write(sel, g);
          msgBox({ title: 'Guardar partida', icon: ok ? 'info' : 'error', text: ok ? `Partida guardada en la ranura ${sel}.` : 'No se pudo guardar la partida.' });
        } else {
          const d = Save.read(sel);
          if (!d) { msgBox({ title: 'Cargar partida', icon: 'warning', text: 'La ranura está vacía.' }); return; }
          Save.write('auto', g); // por si acaso
          localStorage.setItem('gamevibestory_loadslot', String(sel));
          location.reload();
        }
      }
    });
  }

  // ------------------------------------------------- pantallas completas
  full(html, cls) {
    const el = this.el.fullscreen;
    el.className = `fullscreen ${cls}`;
    el.innerHTML = String(html);
    return el;
  }
  clearFull() { this.el.fullscreen.className = ''; this.el.fullscreen.innerHTML = ''; }

  /**
   * Bucle de encendido: pantalla de "apagado", botón, prueba del hardware y
   * arranque. Si falta una pieza, falla y espera que lo apaguen de nuevo.
   */
  async powerOn() {
    let first = true;
    let resolveFirst;
    if (!this.firstBoot) this.firstBoot = new Promise((r) => { resolveFirst = r; });
    for (;;) {
      await this.powerScreen();
      const fault = this.game.bootFault();
      if (fault) { await this.postFail(fault); continue; }
      const ok = await this.boot();
      if (!ok) continue;                      // lo apagaron durante el arranque
      if (first && resolveFirst) { first = false; resolveFirst(); }
      await new Promise((r) => { this.onPowerOff = r; }); // espera hasta que lo apaguen
    }
  }

  /** Botón físico de la torre (modo 3D). */
  pressPower() {
    const g = this.game;
    if (this.pendingPower) { const f = this.pendingPower; this.pendingPower = null; f(); return; }
    // encendido: apagado a la fuerza
    this.bootId = (this.bootId || 0) + 1;
    if (g.state === 'desktop') Save.write('auto', g);
    g.apps.winamp?.stop();
    g.wm.closeAll();
    this.el.taskbar.classList.add('hidden');
    this.el.screen.classList.remove('busy');
    g.state = 'off';
    this.full('', 'boot');
    tube('power-off', 650);
    if (this.onPowerOff) { const f = this.onPowerOff; this.onPowerOff = null; f(); }
    if (this.onFailOff) { const f = this.onFailOff; this.onFailOff = null; f(); }
  }

  /** El PC no arranca: cada pieza faltante falla a su manera. */
  async postFail(fault) {
    const g = this.game;
    if (fault === 'psu') { await new Promise((r) => setTimeout(r, 400)); return; } // ni la luz
    g.state = 'fail';
    tube('power-on', 650);
    if (fault === 'dead' || fault === 'ram') this.full('', 'boot');
    if (fault === 'ram') beeps([0.9, 0.9, 0.9]);
    if (fault === 'video') this.full(h`<div class="no-signal">SIN SEÑAL</div>`, 'boot center');
    if (fault === 'fan' || fault === 'disk') {
      this.full(h`<img class="bios-logo" src="${img('bios')}" alt=""><div class="lines">${`AMIBIOS (C)1994 American Megatrends Inc.\n\n${fault === 'fan' ? 'CPU Fan Error!\nPress F1 to Resume' : 'Non-System disk or disk error\nReplace and press any key when ready'}`}</div>`, 'boot');
      beeps([0.15]);
    }
    await new Promise((r) => { this.onFailOff = r; });
  }

  powerScreen() {
    return new Promise((resolve) => {
      const el = this.full(h`<div class="power-btn">${raw('<svg width="30" height="30" viewBox="0 0 30 30"><path d="M10 7a10 10 0 1 0 10 0" fill="none" stroke="#3c3" stroke-width="3" stroke-linecap="round"/><path d="M15 3v11" stroke="#3c3" stroke-width="3" stroke-linecap="round"/></svg>')}</div>
        <div>Presiona el botón o cualquier tecla para encender el PC</div>`, 'power center');
      const go = () => { this.pendingPower = null; window.removeEventListener('keydown', go); el.removeEventListener('click', go); initAudio(); if (!this.game.bootFault()) tube('power-on', 650); resolve(); };
      this.pendingPower = go;
      el.addEventListener('click', go);
      window.addEventListener('keydown', go);
    });
  }

  /** Arranque normal. Devuelve false si lo apagaron a mitad de camino. */
  async boot() {
    const g = this.game;
    const id = this.bootId = (this.bootId || 0) + 1;
    const alive = () => id === this.bootId;
    g.state = 'boot';
    this.el.taskbar.classList.add('hidden');
    this.el.screen.classList.add('busy');
    play('boot', { volume: 0.6 });
    const ramKB = (parseInt(g.hwName('ram'), 10) || 16) * 1024;
    const lines = [
      'AMIBIOS (C)1994 American Megatrends Inc.',
      'BCN SIT 1989-1994 Special UC612C',
      '',
      `CPU : ${g.hwName('cpu')}`,
      `RAM : %MEM%`,
      `HDD : ${g.hwName('disk')}`,
      `VGA : ${g.hwName('display')}`,
      `FAN : ${g.hwName('cooling')}`,
      `MB  : ${g.hwName('motherboard')}`,
      '',
      'Detecting IDE Primary Master ... OK',
      'Detecting IDE Secondary Master ... CD-ROM',
      '',
      'WAIT...',
    ];
    const el = this.full(h`<img class="bios-logo" src="${img('bios')}" alt=""><img class="energy" src="${img('energy')}" alt="">
      <div class="lines"></div>
      <div class="bottom">Press DEL to enter SETUP, ESC to skip memory test\n12/01/94-i430FX-SIT-GVS-00</div>`, 'boot');
    const out = el.querySelector('.lines');
    let skip = false;
    const sk = (e) => { if (e.type === 'click' || e.key === 'Escape') skip = true; };
    window.addEventListener('keydown', sk); el.addEventListener('click', sk);
    const wait = (ms) => new Promise((r) => setTimeout(r, skip ? 0 : ms));
    let text = '';
    for (const line of lines) {
      if (line.includes('%MEM%')) {
        for (let kb = 0; kb <= ramKB; kb += Math.max(512, ramKB / 24)) {
          out.textContent = text + `RAM : Memory Test ${Math.min(kb, ramKB)}K`;
          await wait(30);
        }
        text += `RAM : Memory Test ${ramKB}K OK\n`;
      } else {
        for (let i = 0; i <= line.length && !skip; i += 3) { out.textContent = text + line.slice(0, i); await wait(12); }
        text += line + '\n';
      }
      out.textContent = text;
      await wait(110);
      if (!alive()) return false;
    }
    await wait(700);
    window.removeEventListener('keydown', sk);
    if (!alive()) return false;
    this.full('Iniciando Windows 95...', 'boot');
    await wait(900);
    if (!alive()) return false;
    this.full(h`<div class="clouds"></div><div class="brand"><div class="ms">Microsoft®</div><div class="win">Windows<sup>95</sup></div></div><div class="bar"></div>`, 'splash center');
    await wait(2200);
    if (!alive()) return false;
    this.clearFull();
    this.el.screen.classList.remove('busy');
    this.el.taskbar.classList.remove('hidden');
    g.state = 'desktop';
    play('startup', { volume: 0.7 });
    g.emit('desktopReady');
    return true;
  }

  async malware() {
    const g = this.game;
    await msgBox({ title: 'WINOPT.EXE', icon: 'error', text: 'WINOPT provocó un error de protección general\nen el módulo KERNEL32.DLL en 0137:BFF9B3D4.\n\nWINOPT se cerrará.', buttons: ['Cerrar'], timeout: 3500 });
    this.bsod();
  }

  async bsod() {
    const g = this.game;
    g.state = 'bsod';
    g.stats.bsods++;
    play('bsod', { volume: 0.6 });
    g.apps.winamp?.stop();
    g.apps.trabajo.failSelected('malware');
    const lost = g.lose(g.money * 0.8);
    this.full(h`<div class="bsod-inner"><span class="bsod-title"> Windows </span>
Se ha producido una excepción grave 0E en 0137:BFF9B3D4 en VxD VMM(01) +
00010E36. Se cerrará la aplicación actual.

*  Presione cualquier tecla para cerrar la aplicación actual.
*  Presione CTRL+ALT+SUPR de nuevo para reiniciar su equipo.
   Perderá toda la información no guardada de todas las aplicaciones.

                 Presione cualquier tecla para continuar _</div>`, 'bsod center');
    await new Promise((resolve) => {
      const done = () => { clearTimeout(t); window.removeEventListener('keydown', done); this.el.fullscreen.removeEventListener('click', done); resolve(); };
      const t = setTimeout(done, 7000);
      setTimeout(() => { window.addEventListener('keydown', done); this.el.fullscreen.addEventListener('click', done); }, 600);
    });
    g.wm.closeAll();
    await this.boot();
    const mail = g.apps.email;
    mail.selected = mail.add({ type: 'news', subject: 'Robo de fondos - Mr. M3ch', from: 'mr.m3ch@darknet.com', read: true,
      body: `Hola...\n\nAcabo de revisar tu cuenta y veo que tuviste un pequeño problema con mi software.\n\nNo te preocupes, tu dinero está a salvo... conmigo.\n\nEl 80% de tus fondos (${money(lost)}) fue transferido a una cuenta más segura.\n\nNos vemos pronto.\n\n- Mr. M3ch` }).id;
    g.wm.open('email');
  }

  async shutdown() {
    const g = this.game;
    Save.write('auto', g);
    g.apps.winamp?.stop();
    g.wm.closeAll();
    this.el.taskbar.classList.add('hidden');
    g.state = 'off';
    this.full('Espere mientras se apaga el equipo...', 'shutdown-screen center');
    await new Promise((r) => setTimeout(r, 1500));
    this.full(h`<div>Ahora puede apagar el equipo.</div>`, 'shutdown-screen center');
    await new Promise((r) => { this.el.fullscreen.addEventListener('click', r, { once: true }); window.addEventListener('keydown', r, { once: true }); });
    await tube('power-off', 650);
    this.full('', 'boot');
    if (this.onPowerOff) { const f = this.onPowerOff; this.onPowerOff = null; f(); }
  }
}

/** Pitidos del parlante del PC (código de error de la BIOS). */
function beeps(durations) {
  try {
    const ctx = beeps.ctx || (beeps.ctx = new AudioContext());
    let t = ctx.currentTime + 0.1;
    for (const d of durations) {
      const o = ctx.createOscillator(), gn = ctx.createGain();
      o.type = 'square'; o.frequency.value = 880; gn.gain.value = 0.05;
      o.connect(gn).connect(ctx.destination);
      o.start(t); o.stop(t + d);
      t += d + 0.25;
    }
  } catch { /* sin audio */ }
}

/** Animación del tubo CRT al encender/apagar. */
function tube(cls, ms) {
  const c = document.getElementById('crt');
  c.classList.remove('power-on', 'power-off');
  void c.offsetWidth;
  c.classList.add(cls);
  return new Promise((r) => setTimeout(() => { if (cls === 'power-on') c.classList.remove(cls); r(); }, ms));
}

const SAVE_ICON = `<svg width="24" height="24" viewBox="0 0 24 24"><rect x="3" y="3" width="18" height="18" fill="#404040" stroke="#000"/><rect x="7" y="3" width="10" height="7" fill="#c0c0c0"/><rect x="13" y="4" width="2" height="5" fill="#404040"/><rect x="6" y="13" width="12" height="8" fill="#fff"/></svg>`;
const LOAD_ICON = `<svg width="24" height="24" viewBox="0 0 24 24"><path d="M2 6h7l2 2h11v13H2z" fill="#ffd94d" stroke="#806000"/><path d="M2 10h20v11H2z" fill="#ffe680" stroke="#806000"/></svg>`;
const NEW_ICON = `<svg width="24" height="24" viewBox="0 0 24 24"><path d="M5 2h10l5 5v15H5z" fill="#fff" stroke="#000"/><path d="M15 2v5h5" fill="#c0c0c0" stroke="#000"/></svg>`;
const CRT_ICON = `<svg width="24" height="24" viewBox="0 0 24 24"><rect x="2" y="3" width="20" height="15" rx="2" fill="#c0c0b0" stroke="#000"/><rect x="5" y="6" width="14" height="9" fill="#008080"/><rect x="8" y="19" width="8" height="3" fill="#a0a090" stroke="#000"/></svg>`;
const SOUND_ICON = `<svg width="24" height="24" viewBox="0 0 24 24"><path d="M3 9h4l6-5v16l-6-5H3z" fill="#ffd94d" stroke="#000"/><path d="M16 8q3 4 0 8M18 5q6 7 0 14" fill="none" stroke="#000" stroke-width="1.5"/></svg>`;
const POWER_ICON = `<svg width="24" height="24" viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="13" fill="#c0c0c0" stroke="#000"/><rect x="5" y="6" width="14" height="9" fill="#000080"/><path d="M12 8v4" stroke="#ff0" stroke-width="2"/><rect x="7" y="18" width="10" height="3" fill="#808080" stroke="#000"/></svg>`;
export { ICONS };
