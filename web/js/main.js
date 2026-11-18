// Punto de entrada: crea el juego, registra las apps, conecta los eventos de
// desbloqueo (portados de main.lua) y corre el bucle principal.
import { Game } from './core/game.js';
import { WindowManager } from './core/wm.js';
import { initUI, msgBox, toast } from './core/ui.js';
import { keySound, click } from './core/audio.js';
import { applyCursors } from './core/cursors.js';
import * as Save from './core/save.js';
import { Shell } from './shell.js';
import { TrabajoApp, ProyectoApp } from './apps/trabajo.js';
import { EmailApp } from './apps/email.js';
import { ExplorerApp } from './apps/explorer.js';
import { CodingApp } from './apps/coding.js';
import { MyPCApp, RecycleBinApp } from './apps/system.js';
import { GoalsApp, AchievementsApp, StaffApp } from './apps/progress.js';
import { WinampApp } from './apps/winamp.js';

const $ = (id) => document.getElementById(id);
const el = {
  screen: $('screen'), desktop: $('desktop'), icons: $('desk-icons'), windows: $('windows'),
  taskbar: $('taskbar'), startMenu: $('start-menu'), modals: $('modals'), fullscreen: $('fullscreen'), toasts: $('toasts'),
};

const game = new Game();
window.game = game; // útil para depurar desde la consola
initUI(el.modals, el.toasts);

const wm = new WindowManager(game, el.windows);
game.wm = wm;
game.apps = {};
for (const App of [TrabajoApp, ProyectoApp, EmailApp, ExplorerApp, CodingApp, MyPCApp, RecycleBinApp, GoalsApp, AchievementsApp, StaffApp, WinampApp]) {
  const app = wm.register(new App(game));
  game.apps[app.id] = app;
}

const shell = new Shell(game, el);

// --------------------------------------------------------------- escalado
const crt = document.getElementById('crt');
function fit() {
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

game.on('taskDone', () => game.apps.email.onTaskDone());
game.on('malwareDesktop', () => game.unlockIcon('download'));
game.on('appInstalled', (id) => {
  if (id === 'coding') game.unlockIcon('coding');
  if (id === 'winbatch') game.setFlag('winbatch');
});
game.on('upgrade', () => {
  const proj = game.apps.particular;
  if (proj.project) {
    const timers = proj.components.map((c) => c.timer);
    proj.components = game.projectComponents();
    proj.components.forEach((c, i) => { c.timer = timers[i] || 0; });
  }
});

// Clic del mouse: como en el original, suena en cada clic sobre el escritorio
el.screen.addEventListener('pointerdown', (e) => { if (game.state === 'desktop' && e.button === 0) click(); }, true);

// ------------------------------------------------------------------ teclado
document.addEventListener('keydown', (e) => {
  if (game.state !== 'desktop') return;
  if (!e.repeat) keySound(game.flags.keyboard || '2', e.code);
  if (e.key === 'Escape') shell.closeStart();
  const coding = game.apps.coding;
  if (wm.activeId() === 'coding' && coding.onKey(e)) { e.preventDefault(); wm.renderApp(coding, true); }
  if (new URLSearchParams(location.search).has('debug')) {
    if (e.key === 'F1') { e.preventDefault(); game.earn(1000, 'debug'); }
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
  shell.applyWallpaper();

  requestAnimationFrame(frame);
  await shell.powerScreen();
  await shell.boot();
  if (!data) wm.open('email');
  else toast('Bienvenido de vuelta', `Partida cargada: $${Math.floor(game.money).toLocaleString('es-CL')}`);
}
start();

export { game, msgBox };
