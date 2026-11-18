// Internet Explorer 3: tienda de hardware, software, bolsa de trabajo, música
// y fondos de escritorio. Portado de explorer.lua con páginas "web de los 90".
import { App } from '../core/wm.js';
import { h, raw, money, fmt, rand } from '../core/dom.js';
import { play } from '../core/audio.js';
import { msgBox, progressDialog } from '../core/ui.js';
import { img } from '../core/assets.js';
import { HW, HW_ORDER } from '../data/hardware.js';
import { PROJECTS, DIFFICULTIES } from '../data/work.js';

const PAGES = {
  home: { title: 'Página de inicio', url: 'http://www.home.msn.com/' },
  upgrades: { title: 'PC Shop - Tienda de Hardware', url: 'http://www.pcshop.com/' },
  apps: { title: 'Centro de Software', url: 'http://www.softwarecenter.com/descargas/' },
  jobs: { title: 'Bolsa de Trabajo', url: 'http://www.bolsadetrabajo.com/proyectos.html' },
  update: { title: 'Windows Update', url: 'http://windowsupdate.microsoft.com/' },
  music: { title: 'Tienda de Música', url: 'http://www.musicstore.com/top.html' },
  wallpaper: { title: 'Fondos de Escritorio', url: 'http://www.fondos.com/' },
};

const FAVORITES = [
  { page: 'upgrades', label: 'PC Shop' },
  { page: 'apps', label: 'Centro de Software' },
  { page: 'jobs', label: 'Bolsa de Trabajo' },
  { page: 'update', label: 'Windows Update' },
  { page: 'music', label: 'Tienda de Música', flag: 'page_music' },
  { page: 'wallpaper', label: 'Fondos de Escritorio', flag: 'page_wallpaper' },
];

export const SOFTWARE = [
  { id: 'winbatch', name: 'WinBatch', price: 500, icon: 'winbatch',
    desc: 'Automatiza el trabajo freelance: toma una tarea nueva cada 3 segundos sin que hagas clic.' },
  { id: 'coding', name: 'Code Editor', price: 5000, icon: 'coding', needTasks: 250,
    desc: 'Programa tus propias aplicaciones y véndelas. Ingresos mensuales mientras estén a la venta.' },
  { id: 'soon1', name: 'Próximamente...', soon: true, desc: 'Nueva aplicación disponible pronto.' },
  { id: 'soon2', name: 'Próximamente...', soon: true, desc: 'Nueva aplicación disponible pronto.' },
];

export const SONGS = [
  { name: 'Nirvana - Smells Like Teen Spirit', price: 35, file: 'songw95_1.wav', cat: 'Tendencias' },
  { name: 'RHCP - Aeroplane', price: 45, file: 'songw95_2.wav', cat: 'Tendencias' },
  { name: 'Backstreet Boys - I Want It That Way', price: 60, file: 'songw95_3.wav', cat: 'Tendencias' },
  { name: 'Las Ketchup - Aserejé', price: 75, file: 'songw95_4.wav', cat: 'Tendencias' },
  { name: 'Nobuo Uematsu - Corridors of Time', price: 50, file: 'songGame_w95.wav', cat: 'Música de videojuegos' },
];

export const WALLPAPERS = [
  { id: 'teal', name: 'Verde azulado (predeterminado)', price: 0, color: '#008080' },
  { id: 'navy', name: 'Azul clásico', price: 0, color: '#000080' },
  { id: 'forest', name: 'Verde bosque', price: 10, color: '#004d00' },
  { id: 'red', name: 'Rojo pasión', price: 10, color: '#800000' },
  { id: 'purple', name: 'Púrpura real', price: 15, color: '#4d0080' },
  { id: 'orange', name: 'Naranja atardecer', price: 15, color: '#cc6600' },
  { id: 'image', name: 'Imagen: Paisaje', price: 40, image: img('wallpaper'), color: '#000' },
];

// Íconos de componentes dibujados con SVG (no había sprites en el original)
const CHIP = (label, color) => `<svg width="40" height="40" viewBox="0 0 40 40"><rect x="6" y="6" width="28" height="28" fill="${color}" stroke="#000"/>${[10, 16, 22, 28].map((p) => `<rect x="${p}" y="1" width="2" height="5" fill="#c0a000"/><rect x="${p}" y="34" width="2" height="5" fill="#c0a000"/><rect x="1" y="${p}" width="5" height="2" fill="#c0a000"/><rect x="34" y="${p}" width="5" height="2" fill="#c0a000"/>`).join('')}<text x="20" y="24" text-anchor="middle" font-family="Arial" font-weight="bold" font-size="9" fill="#fff">${label}</text></svg>`;
const HW_ICON = {
  cpu: CHIP('CPU', '#404040'), ram: CHIP('RAM', '#106010'), disk: CHIP('HDD', '#505070'), display: CHIP('VGA', '#103080'),
  cooling: CHIP('FAN', '#207070'), psu: CHIP('PSU', '#806020'), motherboard: CHIP('MB', '#205020'),
};

export class ExplorerApp extends App {
  constructor(game) {
    super(game);
    this.page = 'home';
    this.sub = null;          // componente seleccionado en la tienda
    this.history = [{ page: 'home', sub: null }];
    this.hIndex = 0;
    this.loading = 0;         // tiempo restante de carga
    this.loadTotal = 1;
    this.pending = null;
    this.board = [];
    this.selectedJob = -1;
    this.refreshLeft = 3;
    this.refreshCooldown = 0;
    this.message = '';
    this.messageTimer = 0;
  }
  get id() { return 'explorer'; }
  get title() { return `${PAGES[this.page].title} - Microsoft Internet Explorer`; }
  get icon() { return img('explorer'); }
  get size() { return { w: 680, h: 500 }; }

  onOpen() { if (!this.board.length) this.refreshBoard(); }

  refreshBoard() {
    const unlocked = this.game.apps.trabajo.unlocked;
    const pool = PROJECTS.filter((p) => unlocked.has(p.difficulty));
    const size = 5 + (this.game.hw.disk || 0);
    this.board = [];
    const copy = [...pool];
    while (this.board.length < size && copy.length) this.board.push(copy.splice(Math.floor(Math.random() * copy.length), 1)[0]);
    this.selectedJob = -1;
  }

  say(msg) { this.message = msg; this.messageTimer = 3; }

  navigate(page, sub = null, push = true) {
    if (!PAGES[page]) return;
    this.pending = { page, sub };
    this.loadTotal = Math.max(0.35, 1.1 - 0.15 * (this.game.hw.disk || 0));
    this.loading = this.loadTotal;
    if (push) {
      this.history = this.history.slice(0, this.hIndex + 1);
      this.history.push({ page, sub });
      this.hIndex = this.history.length - 1;
    }
  }

  update(dt) {
    if (this.loading > 0) {
      this.loading -= dt;
      if (this.loading <= 0) { this.page = this.pending.page; this.sub = this.pending.sub; this.pending = null; }
    }
    if (this.messageTimer > 0) this.messageTimer -= dt;
    if (this.refreshCooldown > 0) {
      this.refreshCooldown -= dt;
      if (this.refreshCooldown <= 0) this.refreshLeft = 3;
    }
  }

  async onAction(action, d) {
    const g = this.game;
    switch (action) {
      case 'go': this.navigate(d.page, d.sub || null); break;
      case 'back': if (this.hIndex > 0) { this.hIndex--; const e = this.history[this.hIndex]; this.navigate(e.page, e.sub, false); } break;
      case 'forward': if (this.hIndex < this.history.length - 1) { this.hIndex++; const e = this.history[this.hIndex]; this.navigate(e.page, e.sub, false); } break;
      case 'stop': this.loading = 0; this.pending = null; break;
      case 'refresh': this.navigate(this.page, this.sub, false); break;
      case 'home': this.navigate('home'); break;
      case 'buyhw': {
        const why = g.upgrade(d.stat);
        if (why) { this.say(why); msgBox({ title: 'PC Shop', icon: 'warning', text: why }); break; }
        play('install', { volume: 0.5 });
        this.say(`${HW[d.stat].name} mejorado a ${g.hwName(d.stat)}.`);
        await progressDialog({ title: 'Asistente para agregar nuevo hardware', text: `Instalando ${g.hwName(d.stat)}...\nWindows está configurando el controlador.`, duration: 1800 });
        break;
      }
      case 'buyapp': {
        const s = SOFTWARE.find((x) => x.id === d.id);
        if (!s || g.flag('app_' + s.id)) break;
        if (s.needTasks && g.stats.tasksCompleted < s.needTasks) { this.say(`Requiere ${s.needTasks} tareas completadas.`); break; }
        if (!g.spend(s.price)) { this.say('Dinero insuficiente.'); break; }
        play('install', { volume: 0.5 });
        await progressDialog({ title: `Instalación de ${s.name}`, text: `Copiando archivos de ${s.name}...`, duration: 2000 });
        g.setFlag('app_' + s.id);
        g.emit('appInstalled', s.id);
        this.say(`${s.name} instalado.`);
        break;
      }
      case 'selectjob': this.selectedJob = Number(d.i); break;
      case 'acceptjob': {
        const job = this.board[Number(d.i)];
        if (!job) break;
        const proj = g.apps.particular;
        if (proj.project) { msgBox({ title: 'Aviso', icon: 'warning', text: 'Ya tiene un proyecto en curso.\nComplete o cancele el proyecto actual antes de aceptar uno nuevo.' }); break; }
        proj.start(job);
        this.board.splice(Number(d.i), 1);
        this.selectedJob = -1;
        break;
      }
      case 'refreshjobs':
        if (this.refreshLeft > 0) {
          this.refreshBoard();
          this.refreshLeft--;
          if (this.refreshLeft === 0) this.refreshCooldown = 30;
        }
        break;
      case 'buysong': {
        const s = SONGS[d.i];
        const owned = g.flags.songs || (g.flags.songs = []);
        if (owned.includes(s.file)) break;
        if (!g.spend(s.price)) { this.say('Dinero insuficiente.'); break; }
        owned.push(s.file);
        play('buy', { volume: 0.5 });
        g.apps.winamp?.addSong(s);
        this.say(`${s.name} comprado. Ya está en Winamp.`);
        break;
      }
      case 'wallpaper': {
        const w = WALLPAPERS[d.i];
        const owned = g.flags.wallpapers || (g.flags.wallpapers = ['teal', 'navy']);
        if (!owned.includes(w.id)) {
          if (!g.spend(w.price)) { this.say('Dinero insuficiente.'); break; }
          owned.push(w.id);
        }
        g.flags.wallpaper = w.id;
        g.emit('wallpaper');
        this.say(`Fondo aplicado: ${w.name}`);
        break;
      }
    }
  }

  // ------------------------------------------------------------------ render
  render() {
    const g = this.game;
    const page = this.loading > 0 ? this.pending.page : this.page;
    const url = PAGES[page].url + (this.pending?.sub || this.sub ? (this.pending?.sub || this.sub) + '.html' : '');
    const pct = this.loading > 0 ? 1 - this.loading / this.loadTotal : 1;
    return h`
      <div class="menubar"><span><u>A</u>rchivo</span><span><u>E</u>dición</span><span><u>V</u>er</span><span><u>I</u>r</span><span>F<u>a</u>voritos</span><span>Ay<u>u</u>da</span></div>
      <div class="toolbar">
        <button class="tool" data-action="back" ${this.hIndex > 0 ? '' : 'disabled'}>${raw(arrow('◄'))}Atrás</button>
        <button class="tool" data-action="forward" ${this.hIndex < this.history.length - 1 ? '' : 'disabled'}>${raw(arrow('►'))}Adelante</button>
        <button class="tool" data-action="stop" ${this.loading > 0 ? '' : 'disabled'}>${raw(arrow('■', '#c00'))}Detener</button>
        <button class="tool" data-action="refresh">${raw(arrow('↻', '#080'))}Actualizar</button>
        <button class="tool" data-action="home">${raw(arrow('⌂', '#008'))}Inicio</button>
        <div class="grow"></div>
        <div class="sunken center" style="width:44px;height:38px;background:#000">${raw(ieLogo(this.loading > 0))}</div>
      </div>
      <div class="flex gap4" style="align-items:center;padding:3px 2px">
        <span>Dirección:</span><div class="field grow nowrap" style="padding:2px 4px">${url}</div>
      </div>
      <div class="flex grow" style="min-height:0;gap:2px">
        <div class="list" style="width:150px;flex:none">
          <div class="row bold" style="padding:3px">Favoritos</div>
          ${FAVORITES.filter((f) => !f.flag || g.flag(f.flag)).map((f) => h`
            <div class="row clickable ${page === f.page ? 'selected' : ''}" data-action="go" data-page="${f.page}">★ ${f.label}</div>`)}
        </div>
        <div class="field grow web" style="overflow:auto;padding:0;background:#fff">
          ${this.loading > 0 ? h`<div class="web-page"><p class="dim">Abriendo la página ${url}...</p></div>` : this.renderPage()}
        </div>
      </div>
      <div class="statusbar">
        <div class="grow">${this.loading > 0 ? `Abriendo página ${url}...` : (this.messageTimer > 0 ? this.message : 'Listo')}</div>
        <div style="flex:0 0 120px;padding:2px"><div class="progress" style="height:12px;padding:1px;box-shadow:none"><div class="fill" style="width:${(pct * 100).toFixed(0)}%"></div></div></div>
        <div style="flex:0 0 110px">${money(g.money)}</div>
      </div>`;
  }

  renderPage() {
    switch (this.page) {
      case 'home': return this.pageHome();
      case 'upgrades': return this.sub ? this.pageComponent(this.sub) : this.pageShop();
      case 'apps': return this.pageApps();
      case 'jobs': return this.pageJobs();
      case 'update': return this.pageUpdate();
      case 'music': return this.pageMusic();
      case 'wallpaper': return this.pageWallpaper();
      default: return '';
    }
  }

  pageHome() {
    return h`<div class="web-page">
      <center><h1>Bienvenido a Internet</h1><hr>
      <p>Microsoft Internet Explorer 3.0 &mdash; <i>¡La forma más fácil de navegar!</i></p></center>
      <table class="web-table" width="100%"><tr>
        ${FAVORITES.filter((f) => !f.flag || this.game.flag(f.flag)).map((f) => h`<td class="mid"><a data-action="go" data-page="${f.page}">${f.label}</a></td>`)}
      </tr></table>
      <p>Seleccione una página de <b>Favoritos</b> para comenzar.</p>
      <p class="blink-text">¡NUEVO! Visite la Bolsa de Trabajo y gane dinero con proyectos particulares.</p>
      <hr><small>Esta página se ve mejor con Internet Explorer a 800x600. Visitante número 000${fmt(1337 + this.game.stats.tasksCompleted)}</small>
    </div>`;
  }

  pageShop() {
    const g = this.game;
    return h`<div class="web-page">
      <center><h2>PC Shop</h2><i>Los mejores componentes al mejor precio</i></center>
      <p>Su dinero: <b>${money(g.money)}</b> &nbsp;|&nbsp; Consumo: <b>${g.totalWatts()}W</b> de <b>${g.psuCapacity()}W</b></p>
      <table class="web-table" width="100%" cellpadding="4">
        <tr><th></th><th>Componente</th><th>Actual</th><th>Siguiente</th><th>Precio</th></tr>
        ${HW_ORDER.map((stat) => {
          const def = HW[stat];
          const lvl = g.hw[stat];
          const next = def.tiers[lvl];
          const price = g.hwPrice(stat);
          return h`<tr>
            <td class="mid">${raw(HW_ICON[stat])}</td>
            <td><a data-action="go" data-page="upgrades" data-sub="${stat}">${def.name}</a><br><small class="dim">Nivel ${lvl}/${def.tiers.length}</small></td>
            <td>${g.hwName(stat)}</td>
            <td>${next ? next.to : h`<i>Máximo</i>`}</td>
            <td class="${price != null && g.money >= price ? 'ok' : 'bad'} bold">${price != null ? money(price) : '-'}</td>
          </tr>`;
        })}
      </table>
    </div>`;
  }

  pageComponent(stat) {
    const g = this.game;
    const def = HW[stat];
    const lvl = g.hw[stat];
    const price = g.hwPrice(stat);
    const why = g.canUpgrade(stat);
    return h`<div class="web-page">
      <p><a data-action="go" data-page="upgrades">&lt;&lt; Volver a PC Shop</a></p>
      <table><tr><td>${raw(HW_ICON[stat])}</td><td><h2 style="margin:0">${def.name}</h2><i>${def.effect}</i></td></tr></table>
      <p>Instalado: <b>${g.hwName(stat)}</b>${stat === 'psu' ? h` &mdash; capacidad <b>${g.psuCapacity()}W</b>` : h` &mdash; consumo <b>${g.watts(stat)}W</b>`}</p>
      <table class="web-table" width="100%" cellpadding="4">
        <tr><th>Modelo</th><th>${stat === 'psu' ? 'Capacidad' : 'Consumo'}</th><th>Estado</th></tr>
        ${def.tiers.map((t, i) => h`<tr class="${i < lvl ? 'dim' : ''}">
          <td>${t.to}</td><td>${stat === 'psu' ? t.capacity + 'W' : t.watts + 'W'}</td>
          <td>${i < lvl ? 'Comprado' : i === lvl ? h`<button class="btn small" data-action="buyhw" data-stat="${stat}" ${why ? 'disabled' : ''}>Comprar ${money(price)}</button>` : 'Bloqueado'}</td>
        </tr>`)}
      </table>
      ${why && price != null ? h`<p class="bad">${why}</p>` : ''}
    </div>`;
  }

  pageApps() {
    const g = this.game;
    return h`<div class="web-page">
      <center><h2>Centro de Software</h2><i>Descargas para su PC con Windows 95</i></center>
      <table class="web-table" width="100%" cellpadding="6">
        ${SOFTWARE.map((s) => {
          const owned = g.flag('app_' + s.id);
          const locked = s.needTasks && g.stats.tasksCompleted < s.needTasks;
          return h`<tr>
            <td class="mid" width="56">${s.icon ? h`<img src="${img(s.icon)}" width="40" height="40">` : '?'}</td>
            <td><b>${s.name}</b><br><small>${s.desc}</small>${locked ? h`<br><small class="bad">Requiere ${s.needTasks} tareas completadas (${g.stats.tasksCompleted}/${s.needTasks}).</small>` : ''}</td>
            <td class="mid" width="110">${s.soon ? h`<i class="dim">Pronto</i>` : owned ? h`<b class="ok">Instalado</b>` : h`
              <b>${money(s.price)}</b><br><button class="btn small" data-action="buyapp" data-id="${s.id}" ${locked || g.money < s.price ? 'disabled' : ''}>Descargar</button>`}</td>
          </tr>`;
        })}
      </table>
    </div>`;
  }

  pageJobs() {
    const busy = !!this.game.apps.particular.project;
    return h`<div class="web-page">
      <center><h2>Bolsa de Trabajo</h2><i>Proyectos particulares para freelancers</i></center>
      <p>Proyectos disponibles: <b>${this.board.length}</b> &nbsp;
        <button class="btn small" data-action="refreshjobs" ${this.refreshLeft > 0 ? '' : 'disabled'}>Buscar otros (${this.refreshLeft})</button>
        ${this.refreshCooldown > 0 ? h` <small class="dim">Nuevas búsquedas en ${Math.ceil(this.refreshCooldown)}s</small>` : ''}</p>
      ${busy ? h`<p class="bad">Ya tiene un proyecto en curso. Termínelo antes de aceptar otro.</p>` : ''}
      <table class="web-table" width="100%" cellpadding="4">
        <tr><th>Proyecto</th><th>Dificultad</th><th>Trabajo</th><th>Pago</th><th></th></tr>
        ${this.board.map((p, i) => h`<tr class="${this.selectedJob === i ? 'sel' : ''}" data-action="selectjob" data-i="${i}" data-silent>
          <td><b>${p.name}</b><br><small>${p.desc}</small></td>
          <td style="color:${DIFFICULTIES[p.difficulty].color}" class="bold nowrap">${DIFFICULTIES[p.difficulty].label}</td>
          <td class="nowrap">${p.hp} pts</td>
          <td class="ok bold">${money(p.reward)}</td>
          <td><button class="btn small" data-action="acceptjob" data-i="${i}" ${busy ? 'disabled' : ''}>Aceptar</button></td>
        </tr>`)}
      </table>
      <p><small>Sus componentes trabajan solos en el proyecto: mejore su PC para terminar a tiempo.</small></p>
    </div>`;
  }

  pageUpdate() {
    const g = this.game;
    return h`<div class="web-page">
      <center><h2>Windows Update</h2></center>
      <p>Su sistema: <b>Microsoft Windows 95 4.00.950</b></p>
      <p class="ok"><b>Su equipo está actualizado.</b></p>
      <hr>
      <h3>Próximamente: Windows XP</h3>
      <p>La próxima generación de Windows llegará pronto. Requisitos mínimos previstos:</p>
      <table class="web-table" cellpadding="4">
        <tr><th>Requisito</th><th>Necesario</th><th>Su equipo</th></tr>
        <tr><td>Procesador</td><td>Pentium II 233</td><td>${g.hwName('cpu')}</td></tr>
        <tr><td>Memoria</td><td>64 MB</td><td>${g.hwName('ram')}</td></tr>
        <tr><td>Disco duro</td><td>2.1 GB</td><td>${g.hwName('disk')}</td></tr>
        <tr><td>Dinero ganado</td><td>$50.000</td><td>${money(g.totalEarned)}</td></tr>
      </table>
    </div>`;
  }

  pageMusic() {
    const g = this.game;
    const owned = g.flags.songs || [];
    const cats = [...new Set(SONGS.map((s) => s.cat))];
    return h`<div class="web-page">
      <center><h2>♫ Tienda de Música ♫</h2><i>Descargue la mejor música para su PC</i></center>
      <p>Su dinero: <b>${money(g.money)}</b></p>
      ${cats.map((c) => h`<h3>${c}</h3><table class="web-table" width="100%" cellpadding="4">
        <tr><th>Canción</th><th>Precio</th><th></th></tr>
        ${SONGS.map((s, i) => s.cat !== c ? '' : h`<tr><td>${s.name}</td><td>${money(s.price)}</td>
          <td>${owned.includes(s.file) ? h`<b class="ok">Comprada</b>` : h`<button class="btn small" data-action="buysong" data-i="${i}" ${g.money < s.price ? 'disabled' : ''}>Comprar</button>`}</td></tr>`)}
      </table>`)}
      <p><small>Las canciones se agregan a Winamp después de comprarlas.</small></p>
    </div>`;
  }

  pageWallpaper() {
    const g = this.game;
    const owned = g.flags.wallpapers || ['teal', 'navy'];
    const cur = g.flags.wallpaper || 'teal';
    return h`<div class="web-page">
      <center><h2>Fondos de Escritorio</h2><i>Personalice su escritorio</i></center>
      <table class="web-table" width="100%" cellpadding="4">
        <tr><th></th><th>Fondo</th><th>Precio</th><th></th></tr>
        ${WALLPAPERS.map((w, i) => h`<tr>
          <td><div style="width:40px;height:28px;border:1px solid #000;background:${w.color} ${w.image ? `url(${w.image}) center/cover` : ''}"></div></td>
          <td>${w.name}</td><td>${owned.includes(w.id) || !w.price ? 'Gratis' : money(w.price)}</td>
          <td><button class="btn small" data-action="wallpaper" data-i="${i}" ${cur === w.id ? 'disabled' : ''}>${cur === w.id ? 'Aplicado' : 'Aplicar'}</button></td>
        </tr>`)}
      </table>
    </div>`;
  }

  save() { return { board: this.board.map((p) => p.name) }; }
  load(d) {
    if (d?.board) this.board = d.board.map((n) => PROJECTS.find((p) => p.name === n)).filter(Boolean);
  }
}

function arrow(ch, color = '#000') {
  return `<span style="font-size:14px;line-height:16px;color:${color}">${ch}</span>`;
}
function ieLogo(spinning) {
  return `<svg width="30" height="30" viewBox="0 0 30 30" style="${spinning ? 'animation:ie-spin 1s linear infinite' : ''}"><ellipse cx="15" cy="15" rx="13" ry="6" fill="none" stroke="#e0b000" stroke-width="2" transform="rotate(-25 15 15)"/><text x="15" y="21" text-anchor="middle" font-family="Times New Roman" font-style="italic" font-weight="bold" font-size="20" fill="#3a8cff">e</text></svg>`;
}
