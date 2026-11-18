// Sonido con Web Audio. El contexto se crea con el primer gesto del usuario
// (el botón de encendido), por eso el juego arranca con "encender el PC".

const BASE = '../assets/sounds/';
let ctx = null;
let master = null;
const buffers = new Map();
let muted = false;

export const SFX = {
  boot: 'start.wav',
  startup: 'startupWindows.wav',
  click1: 'click.wav',
  click2: 'click2.wav',
  click3: 'click3.wav',
  error: 'errorw95.wav',
  ding: 'ding95.wav',
  chimes: 'CHIMES.WAV',
  install: 'newbuy.wav',
  bsod: 'BSOD_Sound.wav',
  money1: 'money1.wav',
  money2: 'money2.wav',
  money3: 'money3.wav',
  circle1: 'circlesound.wav',
  circle2: 'circlesound2.wav',
  buy: 'buy.wav',
};

export function initAudio() {
  if (ctx) return;
  ctx = new (window.AudioContext || window.webkitAudioContext)();
  master = ctx.createGain();
  master.gain.value = 0.8;
  master.connect(ctx.destination);
  for (const file of Object.values(SFX)) load(file);
}

export function setMuted(v) { muted = v; if (master) master.gain.value = v ? 0 : 0.8; }
export function isMuted() { return muted; }

function load(file) {
  if (!ctx) return Promise.resolve(null);
  if (!buffers.has(file)) {
    buffers.set(file, fetch(BASE + file)
      .then((r) => (r.ok ? r.arrayBuffer() : Promise.reject(r.status)))
      .then((ab) => ctx.decodeAudioData(ab))
      .catch(() => null));
  }
  return buffers.get(file);
}

/** Reproduce un efecto por nombre (clave de SFX) o por ruta relativa a assets/sounds. */
export async function play(name, { volume = 0.6, offset = 0, duration } = {}) {
  if (!ctx || muted) return;
  const file = SFX[name] || name;
  const buf = await load(file);
  if (!buf) return;
  const src = ctx.createBufferSource();
  src.buffer = buf;
  const g = ctx.createGain();
  g.gain.value = volume;
  src.connect(g).connect(master);
  if (duration) src.start(0, offset, duration);
  else src.start(0, offset);
  return src;
}

export function playRandom(names, opts) {
  return play(names[Math.floor(Math.random() * names.length)], opts);
}

// Los .wav de clic son bajos y traen ~0,14 s de silencio al inicio: se saltan
// y se amplifican para que suenen justo al presionar.
export const click = () => playRandom(['click1', 'click2', 'click3'], { volume: 1.6, offset: 0.125 });

// ---------------------------------------------------------------------------
// Teclados mecánicos (packs con formato Mechvibes que ya venían en el juego)
// ---------------------------------------------------------------------------
const SCAN = {
  Escape: 1, Digit1: 2, Digit2: 3, Digit3: 4, Digit4: 5, Digit5: 6, Digit6: 7, Digit7: 8, Digit8: 9, Digit9: 10, Digit0: 11,
  Minus: 12, Equal: 13, Backspace: 14, Tab: 15,
  KeyQ: 16, KeyW: 17, KeyE: 18, KeyR: 19, KeyT: 20, KeyY: 21, KeyU: 22, KeyI: 23, KeyO: 24, KeyP: 25,
  BracketLeft: 26, BracketRight: 27, Enter: 28, ControlLeft: 29,
  KeyA: 30, KeyS: 31, KeyD: 32, KeyF: 33, KeyG: 34, KeyH: 35, KeyJ: 36, KeyK: 37, KeyL: 38,
  Semicolon: 39, Quote: 40, Backquote: 41, ShiftLeft: 42, Backslash: 43,
  KeyZ: 44, KeyX: 45, KeyC: 46, KeyV: 47, KeyB: 48, KeyN: 49, KeyM: 50,
  Comma: 51, Period: 52, Slash: 53, ShiftRight: 54, Space: 57, CapsLock: 58,
};

const MULTI_NAMES = {
  Space: 'space', Backspace: 'backspace', Enter: 'enter', ShiftLeft: 'shift', ShiftRight: 'shift',
  Tab: 'tab', CapsLock: 'caps lock', BracketLeft: '[', BracketRight: ']',
};

const packs = new Map();

async function loadPack(dir) {
  if (packs.has(dir)) return packs.get(dir);
  const p = (async () => {
    try {
      const cfg = await (await fetch(`${BASE}keyboard/${dir}/config.json`)).json();
      return { dir, cfg };
    } catch { return null; }
  })();
  packs.set(dir, p);
  return p;
}

export async function keySound(dir, code) {
  if (!ctx || muted || !dir) return;
  const pack = await loadPack(dir);
  if (!pack) return;
  const { cfg } = pack;
  if (cfg.key_define_type === 'single') {
    const defs = cfg.defines;
    let d = defs[SCAN[code]];
    if (!d) { const keys = Object.keys(defs).filter((k) => defs[k]); d = defs[keys[Math.floor(Math.random() * keys.length)]]; }
    if (!d) return;
    play(`keyboard/${dir}/${cfg.sound}`, { volume: 0.45, offset: d[0] / 1000, duration: d[1] / 1000 });
  } else {
    let name = MULTI_NAMES[code];
    if (!name && code.startsWith('Key')) name = code.slice(3).toLowerCase();
    if (!name) name = 'abcdefghijklmnopqrstuvwxyz'[Math.floor(Math.random() * 26)];
    play(`keyboard/${dir}/${name}.wav`, { volume: 0.35 });
  }
}

// ---------------------------------------------------------------------------
// Música (Winamp): HTMLAudioElement para poder buscar y leer el tiempo
// ---------------------------------------------------------------------------
export function createMusic(file) {
  const a = new Audio(BASE + file);
  a.preload = 'metadata';
  return a;
}

/** Conecta un <audio> al mezclador y devuelve un analizador para el visualizador. */
export function analyse(el) {
  if (!ctx) return null;
  const src = ctx.createMediaElementSource(el);
  const an = ctx.createAnalyser();
  an.fftSize = 64;
  an.smoothingTimeConstant = 0.7;
  src.connect(an);
  an.connect(master);
  return an;
}
