// Rutas de imágenes. Si pones los originales en assets/eras/<era>/ con el
// mismo nombre, se pueden mapear aquí sin tocar el resto del código.
const SPRITES = '../assets/sprites/';

const FILES = {
  trabajo: 'trabajo.png', email: 'email.png', mypc: 'mypc.png', recyclebin: 'recyclebin.png',
  explorer: 'explorer.png', winamp: 'winamp.png', notepad: 'notepad.png', staff: 'staff.png',
  achievements: 'achievements.png', coding: 'coding.png', download: 'download1.png', winbatch: 'winbatch.png',
  bios: 'biosiconw95.png', energy: 'energy.png', wallpaper: 'bg.jpg',
};

export const img = (name) => SPRITES + (FILES[name] || name + '.png');
