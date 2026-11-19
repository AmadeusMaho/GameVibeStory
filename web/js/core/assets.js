// Rutas de imágenes. Si pones los originales en assets/eras/<era>/ con el
// mismo nombre, se pueden mapear aquí sin tocar el resto del código.
const SPRITES = '../assets/sprites/';

const FILES = {
  trabajo: 'trabajo.png', email: 'email.png', mypc: 'mypc.png', recyclebin: 'recyclebin.png',
  explorer: 'explorer.png', winamp: 'winamp.png', notepad: 'notepad.png', staff: 'staff.png',
  achievements: 'achievements.png', coding: 'coding.png', download: 'download1.png', winbatch: 'winbatch.png',
  bios: 'biosiconw95.png', energy: 'energy.png', wallpaper: 'bg.jpg',
};

// Ícono del Taller (dibujado aquí: torre beige con un destornillador)
const DRAWN = {
  taller: 'data:image/svg+xml,' + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" shape-rendering="crispEdges"><rect x="7" y="3" width="14" height="26" fill="#d9d0b8" stroke="#000"/><rect x="9" y="6" width="10" height="3" fill="#7a7262"/><rect x="9" y="11" width="10" height="2" fill="#7a7262"/><rect x="12" y="22" width="4" height="3" fill="#7a7262"/><path d="M18 20l9 9" stroke="#000" stroke-width="4"/><path d="M18 20l9 9" stroke="#c00000" stroke-width="2"/><path d="M15 17l4 4" stroke="#606060" stroke-width="2"/></svg>'),
};

export const img = (name) => DRAWN[name] || SPRITES + (FILES[name] || name + '.png');
