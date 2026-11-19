// Punto de entrada: crea el juego, registra las apps, conecta los eventos de
// desbloqueo (portados de main.lua) y corre el bucle principal.
import { Game } from './core/game.js';
import { WindowManager } from './core/wm.js';
import { initUI, msgBox, toast } from './core/ui.js';
import { keySound, click } from './core/audio.js';
import { applyCursors } from './core/cursors.js';
import * as Save from './core/save.js';
import { Shell } from './shell.js';
import { TrabajoApp } from './apps/trabajo.js';
import { EmailApp } from './apps/email.js';
import { ExplorerApp } from './apps/explorer.js';
import { CodingApp } from './apps/coding.js';
import { MyPCApp, RecycleBinApp } from './apps/system.js';
import { GoalsApp, AchievementsApp, StaffApp } from './apps/progress.js';
import { WinampApp } from './apps/winamp.js';
import { TallerApp } from './apps/taller.js';

const $ = (id) => document.getElementById(id);
const el = {
  screen: $('screen'), desktop: $('desktop'), icons: $('desk-icons'), windows: $('windows'),
  taskbar: $('taskbar'), startMenu: $('start-menu'), modals: $('modals'), fullscreen: $('fullscreen'), toasts: $('toasts'),
};

const game = new Game();
window.game = game; // útil para depurar desde la consola
// ?3d: el juego vive dentro de un monitor en una habitación 3D
game.mode3d = new URLSearchParams(location.search).has('3d');
initUI(el.modals, el.toasts);

const wm = new WindowManager(game, el.windows);
game.wm = wm;
game.apps = {};
for (const App of [TrabajoApp, EmailApp, ExplorerApp, CodingApp, MyPCApp, RecycleBinApp, GoalsApp, AchievementsApp, StaffApp, WinampApp, TallerApp]) {
  const app = wm.register(new App(game));
  game.apps[app.id] = app;
}

const shell = new Shell(game, el);
game.shell = shell;

// --------------------------------------------------------------- escalado
const crt = document.getElementById('crt');
function fit() {
  if (game.mode3d && !game.flat) return; // en 3D la escena posiciona la pantalla (salvo sentado frente al PC)
  const s = Math.min(window.innerWidth / game.screenW, window.innerHeight / game.screenH);
  game.scale = s;
  el.screen.style.transform = `translate(-50%, -50%) scale(${s})`;
  applyCursors(el.screen, s);
  const w = game.screenW * s, hh = game.screenH * s;
  Object.assign(crt.style, { left: `${(window.innerWidth - w) / 2}px`, top: `${(window.innerHeight - hh) / 2}px`, width: `${w}px`, height: `${hh}px` });
  crt.style.setProperty('--crt-r', `${18 * s}px`);
}
// textura de ruido para el CRT (se genera una vez)
(() => {
  const c = document.createElement('canvas');
  c.width = c.height = 160;
  const x = c.getContext('2d');
  const d = x.createImageData(160, 160);
  for (let i = 0; i < d.data.length; i += 4) { const v = Math.random() * 255; d.data[i] = d.data[i + 1] = d.data[i + 2] = v; d.data[i + 3] = 255; }
  x.putImageData(d, 0, 0);
  crt.style.setProperty('--crt-noise', `url(${c.toDataURL()})`);
})();
if (localStorage.getItem('gamevibestory_crt') === 'off') document.body.classList.add('crt-off');
window.addEventListener('resize', fit);
fit();

// ------------------------------------------------------ desbloqueos (main.lua)
const UNLOCK_MAIL = {
  1: ['notepad', 'Objetivos - Aplicación desbloqueada', 'admin@empresa.com',
    '¡Ha completado su primer objetivo!\n\nHa desbloqueado la aplicación "Objetivos" para seguir su progreso. El ícono aparecerá en su escritorio.\n\nSiga trabajando para desbloquear más cosas.'],
  2: ['explorer', 'Internet Explorer - Tienda disponible', 'admin@microsoft.com',
    '¡Ha desbloqueado Internet Explorer!\n\nAhora puede acceder a la Tienda de Hardware, al Centro de Software, a la Bolsa de Trabajo y a Windows Update.\n\nDisfrute de su nueva experiencia de navegación.'],
  3: [null, 'Personalice su escritorio', 'admin@microsoft.com',
    'Ahora puede cambiar el fondo de su escritorio.\n\nVisite "Fondos de Escritorio" en los Favoritos de Internet Explorer.', 'page_wallpaper'],
  5: ['personal', 'Personal - Empleados disponibles', 'admin@empresa.com',
    '¡Ha desbloqueado la aplicación "Personal"!\n\nAhora puede contratar empleados que generan ingresos pasivos de forma automática.'],
  6: ['winamp', 'Winamp - Reproductor de música', 'admin@winamp.com',
    '¡Ha desbloqueado Winamp!\n\nEl reproductor de música más popular del momento. Compre su primera canción en la Tienda de Música de Internet Explorer.', 'page_music'],
  7: ['achievements', 'Logros - Aplicación desbloqueada', 'admin@empresa.com',
    '¡Ha desbloqueado "Logros y Estadísticas"!\n\nAhora puede ver todos sus logros y estadísticas de juego.'],
  10: [null, 'Windows XP está en camino', 'windowsupdate@microsoft.com',
    'Su equipo cumple los requisitos de Windows XP.\n\nLa actualización estará disponible en una próxima versión del juego. ¡Gracias por jugar la era de Windows 95!'],
};

game.on('goal', (id, index) => {
  const u = UNLOCK_MAIL[index];
  if (!u) return;
  const [icon, subject, from, body, flag] = u;
  if (icon) game.unlockIcon(icon);
  if (flag) game.setFlag(flag);
  game.apps.email.add({ type: 'news', subject, from, body: `Estimado usuario:\n\n${body}` });
});

game.on('taskDone', () => {
  game.apps.email.onTaskDone();
  const n = game.stats.tasksCompleted;
  if ([1, 5, 10, 20, 30, 50, 100].includes(n)) game.milestone(`${n} encargo${n > 1 ? 's' : ''}`);
});
// registro de ritmo (F3 con ?debug lo muestra en la consola)
game.on('upgrade', (stat, lvl) => {
  game.milestone(`${stat} nv.${lvl}`);
  const n = game.stats.upgradesPurchased;
  if (n % 10 === 0) game.milestone(`${n} mejoras`);
  if (game.hw.cpu >= 6 && game.hw.ram >= 3 && game.hw.disk >= 2) game.milestone('hardware para XP');
});
game.on('repLevel', (lvl) => game.milestone(`reputación ${lvl}`));
game.on('goal', (id) => game.milestone(`objetivo ${id}`));
game.on('malwareDesktop', () => game.unlockIcon('download'));
game.on('appInstalled', (id) => {
  if (id === 'coding') game.unlockIcon('coding');
  if (id === 'winbatch') game.setFlag('winbatch');
});
game.on('upgrade', () => game.apps.trabajo.refreshComponents());
game.on('repLevel', (lvl) => {
  if (lvl !== 1) return;
  if (game.mode3d && !game.flag('taller')) {
    game.setFlag('taller');
    game.unlockIcon('taller');
    game.apps.taller.offerTimer = 20;
  }
  game.apps.email.add({ type: 'news', subject: 'Se corre la voz', from: 'admin@empresa.com',
    body: 'Ya lo conocen en el barrio. Algunos clientes le van a escribir directo con encargos urgentes. Pagan bien, pero no esperan mucho.\n\nSu gerente.' });
});

// Clic del mouse: como en el original, suena en cada clic sobre el escritorio
el.screen.addEventListener('pointerdown', (e) => { if (game.state === 'desktop' && e.button === 0) click(); }, true);

// ------------------------------------------------------------------ teclado
document.addEventListener('keydown', (e) => {
  if (game.state !== 'desktop') return;
  if (!e.repeat) keySound(game.flags.keyboard || '2', e.code);
  if (e.key === 'Escape') shell.closeStart();
  const coding = game.apps.coding, trabajo = game.apps.trabajo;
  if (wm.activeId() === 'coding' && coding.onKey(e)) { e.preventDefault(); wm.renderApp(coding, true); }
  if (wm.activeId() === 'trabajo' && trabajo.onKey(e)) { e.preventDefault(); wm.renderApp(trabajo, true); }
  if (new URLSearchParams(location.search).has('debug')) {
    if (e.key === 'F1') { e.preventDefault(); game.earn(1000, 'debug'); }
    if (e.key === 'F3') { e.preventDefault(); console.table(game.pacing.map(([min, hito]) => ({ min, hito }))); toast('Ritmo', `${game.pacing.length} hitos en la consola (F12)`); }
    if (e.key === 'F2') { e.preventDefault(); ['winbatch', 'coding'].forEach((a) => { game.setFlag('app_' + a); game.emit('appInstalled', a); }); }
  }
});

// -------------------------------------------------------------- bucle
const reported = new Set();
function safe(fn, who) {
  try { fn(); } catch (err) {
    if (!reported.has(who)) { reported.add(who); console.error(`[${who}]`, err); }
  }
}

let last = performance.now();
let autosave = 0;
function frame(now) {
  const dt = Math.min(0.25, (now - last) / 1000);
  last = now;
  requestAnimationFrame(frame); // primero: un error en una app no congela el juego
  if (game.state === 'desktop') {
    for (const app of wm.apps.values()) safe(() => app.update(dt), app.id);
    autosave += dt;
    if (autosave >= 30) { autosave = 0; Save.write('auto', game); }
  }
  if (game.state !== 'off') {
    for (const app of wm.apps.values()) safe(() => wm.renderApp(app), app.id);
    safe(() => shell.renderIcons(), 'icons');
    safe(() => shell.renderTaskbar(), 'taskbar');
  }
}

window.addEventListener('beforeunload', () => { if (game.state === 'desktop' && !game.newGameRequested) Save.write('auto', game); });

// ------------------------------------------------------------- arranque
async function start() {
  const slot = localStorage.getItem('gamevibestory_loadslot');
  localStorage.removeItem('gamevibestory_loadslot');
  const data = slot ? Save.read(Number(slot)) : Save.latest();
  if (data) Save.apply(game, data);
  if (!game.mode3d) { // en 2D no hay caja ni piezas sueltas
    Object.keys(game.boxed).forEach((s) => game.install(s));
    game.removed = {}; game.loose = {};
  }
  shell.applyWallpaper();
  if (game.mode3d) {
    document.body.classList.add('mode3d');
    const { initRoom } = await import('./room3d.js');
    initRoom(game, el, fit);
  }

  requestAnimationFrame(frame);
  shell.powerOn().then(() => {}); // el bucle de encendido sigue vivo (apagar y volver a prender)
  await shell.firstBoot;
  if (!data) wm.open('email');
  else toast('Bienvenido de vuelta', `Partida cargada: $${Math.floor(game.money).toLocaleString('es-CL')}`);
}
start();

export { game, msgBox };
