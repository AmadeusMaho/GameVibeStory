// Modo 3D (?3d): una pieza con escritorio, monitor CRT, una torre que se abre
// y un banco de taller para reparar PCs de clientes. El escritorio de Windows
// (#screen) se monta dentro del monitor con CSS3DRenderer; sentado frente al PC
// vuelve a ser la pantalla plana con su filtro CRT.
import * as THREE from 'three';
import { CSS3DRenderer, CSS3DObject } from 'three/addons/renderers/CSS3DRenderer.js';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { applyCursors } from './core/cursors.js';
import { play } from './core/audio.js';
import { toast } from './core/ui.js';
import { HW } from './data/hardware.js';

const SCREEN_W = 0.33, SCREEN_H = SCREEN_W * 0.75;
const PX_W = 1024;
const DESK_Y = 0.77;
const BENCH_Y = 0.86;
const TOWER_POS = new THREE.Vector3(0.52, DESK_Y, -0.06);
const BOX_POS = new THREE.Vector3(0.6, DESK_Y, 0.31);
const BENCH_TOWER_POS = new THREE.Vector3(1.55, BENCH_Y, -0.22);
const CRATE_POS = new THREE.Vector3(1.92, BENCH_Y, -0.02);
const BIN_POS = new THREE.Vector3(1.12, 0, 0.1);
const BX = -0.092;                    // superficie de la placa madre (local de la torre)
const PART_STATS = ['motherboard', 'cpu', 'cooling', 'ram', 'display', 'disk', 'psu'];
const ANCHOR = {                      // dónde va cada pieza (local de la torre)
  motherboard: [BX, 0.18, -0.06], cpu: [BX + 0.01, 0.25, -0.11], cooling: [BX + 0.03, 0.25, -0.11],
  ram: [BX + 0.02, 0.24, 0.025], display: [BX + 0.05, 0.11, -0.12], disk: [0, 0.075, 0.15], psu: [0, 0.37, -0.15],
};

// ------------------------------------------------------------------ texturas
function canvasOf(w, h, draw) {
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  draw(c.getContext('2d'), w, h);
  return c;
}
function texOf(canvas, { repeat = [1, 1], color = true } = {}) {
  const t = new THREE.CanvasTexture(canvas);
  if (color) t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = 8;
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.repeat.set(...repeat);
  return t;
}
const tex = (w, h, draw, opts) => texOf(canvasOf(w, h, draw), opts);
function noise(x, w, h, amount, alpha = 0.08, size = 2) {
  for (let i = 0; i < amount; i++) {
    x.fillStyle = Math.random() < 0.5 ? `rgba(0,0,0,${alpha})` : `rgba(255,255,255,${alpha})`;
    x.fillRect(Math.random() * w, Math.random() * h, 1 + Math.random() * size, 1 + Math.random() * size);
  }
}
// plástico beige con leve textura y amarillento irregular
const plasticCanvas = canvasOf(256, 256, (x, w, h) => {
  x.fillStyle = '#d9d0b8'; x.fillRect(0, 0, w, h);
  for (let i = 0; i < 6; i++) { const g = x.createRadialGradient(Math.random() * w, Math.random() * h, 0, Math.random() * w, Math.random() * h, 120); g.addColorStop(0, 'rgba(190,170,110,.10)'); g.addColorStop(1, 'rgba(190,170,110,0)'); x.fillStyle = g; x.fillRect(0, 0, w, h); }
  noise(x, w, h, 6000, 0.035, 1);
});
const plasticBump = texOf(canvasOf(256, 256, (x, w, h) => { x.fillStyle = '#808080'; x.fillRect(0, 0, w, h); noise(x, w, h, 9000, 0.25, 1); }), { color: false, repeat: [3, 3] });
const brushed = texOf(canvasOf(512, 512, (x, w, h) => {
  x.fillStyle = '#d0d4d8'; x.fillRect(0, 0, w, h);
  for (let i = 0; i < 1500; i++) { x.fillStyle = `rgba(${Math.random() < 0.5 ? '255,255,255' : '0,0,0'},${Math.random() * 0.05})`; x.fillRect(0, Math.random() * h, w, 1); }
}), { repeat: [4, 4] });

// ------------------------------------------------------------------ materiales
const matCache = new Map();
function mat(color, o = {}) {
  const key = color + JSON.stringify(Object.keys(o).map((k) => [k, o[k]?.uuid || o[k]]));
  if (!matCache.has(key)) matCache.set(key, new THREE.MeshStandardMaterial({ color, roughness: 0.7, metalness: 0, ...o }));
  return matCache.get(key);
}
const plasticMap = texOf(plasticCanvas, { repeat: [2, 2] });
const M = {
  beige: mat(0xffffff, { map: plasticMap, bumpMap: plasticBump, bumpScale: 0.0006, roughness: 0.62 }),
  beigeDark: mat(0xb8ae94, { roughness: 0.6 }),
  metal: mat(0xb0b4b8, { map: brushed, metalness: 0.75, roughness: 0.35 }),
  steel: mat(0x7c8085, { map: brushed, metalness: 0.6, roughness: 0.45 }),
  alu: mat(0xd8dce0, { map: brushed, metalness: 0.85, roughness: 0.28 }),
  copper: mat(0xc87533, { metalness: 0.9, roughness: 0.3 }),
  black: mat(0x1c1c1c, { roughness: 0.55 }),
  dark: mat(0x333333),
  white: mat(0xeeeeee),
  gold: mat(0xd4a73a, { metalness: 1, roughness: 0.3 }),
  chip: mat(0x222226, { roughness: 0.45 }),
  ceramic: mat(0x8a8478, { roughness: 0.6 }),
  cable: mat(0x9a9a90),
  inside: mat(0x8a8f94, { map: brushed, metalness: 0.45, roughness: 0.5 }),
};

// ------------------------------------------------------------------ primitivas
function box(w, h, d, m, x = 0, y = 0, z = 0) {
  const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), m);
  mesh.position.set(x, y, z);
  mesh.castShadow = mesh.receiveShadow = true;
  return mesh;
}
function rbox(w, h, d, r, m, x = 0, y = 0, z = 0) {
  const mesh = new THREE.Mesh(new RoundedBoxGeometry(w, h, d, 3, r), m);
  mesh.position.set(x, y, z);
  mesh.castShadow = mesh.receiveShadow = true;
  return mesh;
}
function cyl(rt, rb, h, m, seg = 20) {
  const mesh = new THREE.Mesh(new THREE.CylinderGeometry(rt, rb, h, seg), m);
  mesh.castShadow = mesh.receiveShadow = true;
  return mesh;
}
/** Etiqueta impresa: un plano con texto (mira hacia +z). */
function label(text, w, h, { bg = '#f4f1e6', fg = '#111', font = 'bold 28px Arial', border = null } = {}) {
  const k = 512 / Math.max(w, h);
  const t = tex(Math.round(w * k), Math.round(h * k), (x, cw, ch) => {
    x.fillStyle = bg; x.fillRect(0, 0, cw, ch);
    if (border) { x.strokeStyle = border; x.lineWidth = 6; x.strokeRect(3, 3, cw - 6, ch - 6); }
    x.fillStyle = fg; x.font = font; x.textAlign = 'center'; x.textBaseline = 'middle';
    const lines = String(text).split('\n');
    const lh = parseInt(font.match(/(\d+)px/)[1], 10) * 1.15;
    lines.forEach((l, i) => x.fillText(l, cw / 2, ch / 2 + (i - (lines.length - 1) / 2) * lh));
  });
  return new THREE.Mesh(new THREE.PlaneGeometry(w, h), new THREE.MeshStandardMaterial({ map: t, roughness: 0.8, transparent: bg.length > 7 }));
}
const nameAt = (stat, lvl) => (lvl === 0 ? HW[stat].tiers[0].from : HW[stat].tiers[Math.min(lvl, HW[stat].tiers.length) - 1].to);
const spinners = [];

/** Ventilador que mira hacia +x (gira sobre x). */
function fan(size, { frame = M.black, blade = mat(0x2a2a2a), glow = null } = {}) {
  const g = new THREE.Group();
  const t = size * 0.12;
  g.add(box(t, size, t, frame, 0, 0, size / 2 - t / 2), box(t, size, t, frame, 0, 0, -size / 2 + t / 2));
  g.add(box(t, t, size, frame, 0, size / 2 - t / 2, 0), box(t, t, size, frame, 0, -size / 2 + t / 2, 0));
  const ring = new THREE.Mesh(new THREE.TorusGeometry(size * 0.42, size * 0.03, 6, 24), frame);
  ring.rotation.y = Math.PI / 2;
  g.add(ring);
  const rotor = new THREE.Group();
  const hub = cyl(size * 0.14, size * 0.14, t * 1.1, glow || blade);
  hub.rotation.z = Math.PI / 2;
  rotor.add(hub);
  for (let i = 0; i < 7; i++) {
    const b = box(t * 0.3, size * 0.34, size * 0.13, blade, 0, size * 0.22, 0);
    b.rotation.y = 0.5;
    const arm = new THREE.Group();
    arm.add(b);
    arm.rotation.x = (i / 7) * Math.PI * 2;
    rotor.add(arm);
  }
  g.add(rotor);
  rotor.userData.rotor = true;
  spinners.push(rotor);
  return g;
}
/** Disipador de aletas: base en x=0, crece hacia +x. */
function heatsink(w, d, hgt, n, m) {
  const g = new THREE.Group();
  g.add(box(hgt * 0.15, w, d, m, hgt * 0.075, 0, 0));
  for (let i = 0; i < n; i++) g.add(box(hgt, w, d / (n * 2.2), m, hgt / 2, 0, -d / 2 + (d / (n - 1 || 1)) * i));
  return g;
}
function tube(points, radius, m) {
  const curve = new THREE.CatmullRomCurve3(points.map((p) => new THREE.Vector3(...p)));
  const mesh = new THREE.Mesh(new THREE.TubeGeometry(curve, 32, radius, 8, false), m);
  mesh.castShadow = true;
  return mesh;
}

// --------------------------------------------------------------- circuitos
const pcbCache = new Map();
/** Material de placa de circuito: pistas, vías y serigrafía sobre el color base. */
function pcbMat(color) {
  if (pcbCache.has(color)) return pcbCache.get(color);
  const base = '#' + new THREE.Color(color).getHexString();
  const canvas = canvasOf(512, 512, (x, w, h) => {
    x.fillStyle = base; x.fillRect(0, 0, w, h);
    x.strokeStyle = 'rgba(255,255,200,0.12)'; x.lineWidth = 2;
    for (let i = 0; i < 160; i++) {
      let px = Math.random() * w, py = Math.random() * h;
      x.beginPath(); x.moveTo(px, py);
      for (let k = 0; k < 3; k++) { if (Math.random() < 0.5) px += (Math.random() - 0.5) * 160; else py += (Math.random() - 0.5) * 160; x.lineTo(px, py); }
      x.stroke();
    }
    x.fillStyle = 'rgba(230,200,100,0.6)';
    for (let i = 0; i < 600; i++) { x.beginPath(); x.arc(Math.random() * w, Math.random() * h, 1.6, 0, Math.PI * 2); x.fill(); }
    x.fillStyle = 'rgba(255,255,255,0.6)'; x.font = '11px Arial';
    for (let i = 0; i < 36; i++) x.fillText('CRULJQ'[i % 6] + ((i * 7) % 99), Math.random() * w, Math.random() * h);
    x.strokeStyle = 'rgba(255,255,255,0.35)'; x.lineWidth = 1;
    for (let i = 0; i < 16; i++) x.strokeRect(Math.random() * w, Math.random() * h, 20 + Math.random() * 50, 10 + Math.random() * 30);
  });
  const m = new THREE.MeshStandardMaterial({ map: texOf(canvas), roughness: 0.45, metalness: 0.05 });
  pcbCache.set(color, m);
  return m;
}
const pinsTex = tex(64, 16, (x, w, h) => { x.fillStyle = '#151515'; x.fillRect(0, 0, w, h); x.fillStyle = '#d4a73a'; for (let i = 2; i < w; i += 4) { x.fillRect(i, 3, 2, 3); x.fillRect(i, 10, 2, 3); } });
const headerM = new THREE.MeshStandardMaterial({ map: pinsTex, roughness: 0.5 });

// ------------------------------------------------------------ piezas del PC
// Cada constructor devuelve un grupo en coordenadas locales de la torre.
const PCB_COLORS = [0x1f5f2e, 0x1d6a3a, 0x24543a, 0x5a3a1a, 0x2a2a2a, 0x1e2e5a, 0x3a0d14];

function buildMotherboard(lvl, hw = {}) {
  const g = new THREE.Group();
  {
    const [, y, z] = ANCHOR.cpu;
    if (nameAt('cpu', hw.cpu || 0).includes('II')) g.add(box(0.012, 0.15, 0.02, M.black, BX + 0.006, y, z)); // ranura Slot 1
    else {
      g.add(box(0.005, 0.04, 0.04, M.white, BX + 0.0025, y, z));                                            // zócalo ZIF
      const holes = tex(64, 64, (x, w, h) => { x.fillStyle = '#f0f0ea'; x.fillRect(0, 0, w, h); x.fillStyle = '#9a9a90'; for (let i = 6; i < w - 4; i += 4) for (let j = 6; j < h - 4; j += 4) if (Math.abs(i - w / 2) > 10 || Math.abs(j - h / 2) > 10) x.fillRect(i, j, 2, 2); });
      const top = new THREE.Mesh(new THREE.PlaneGeometry(0.038, 0.038), new THREE.MeshStandardMaterial({ map: holes, roughness: 0.6 }));
      top.rotation.y = Math.PI / 2; top.position.set(BX + 0.0051, y, z); g.add(top);
      g.add(box(0.004, 0.005, 0.005, M.white, BX + 0.004, y - 0.023, z - 0.021));                         // pivote de la palanca
    }
  }
  const col = PCB_COLORS[lvl] ?? PCB_COLORS[0];
  const edge = mat(col, { roughness: 0.5 });
  g.add(box(0.003, 0.28, 0.28, [pcbMat(col), edge, edge, edge, edge, edge], BX - 0.0015, 0.18, -0.06));
  const S = (w, h, d, m, y, z) => g.add(box(w, h, d, m, BX + w / 2, y, z));
  // conector de poder, cabezales IDE y disquetera, puentes, I/O trasero
  S(0.01, 0.012, 0.045, M.white, 0.22, 0.0);
  S(0.008, 0.01, 0.05, [headerM, M.black, M.black, M.black, M.black, M.black], 0.07, 0.02);
  S(0.008, 0.01, 0.05, [headerM, M.black, M.black, M.black, M.black, M.black], 0.09, 0.02);
  S(0.008, 0.008, 0.03, [headerM, M.black, M.black, M.black, M.black, M.black], 0.115, 0.04);
  for (const [y, z] of [[0.2, -0.04], [0.13, 0.0], [0.27, 0.06]]) S(0.004, 0.004, 0.007, mat(0x2050c0), y, z);
  S(0.02, 0.05, 0.014, M.steel, 0.29, -0.193);
  const din = cyl(0.006, 0.006, 0.004, mat(0x6a3a9a), 12); din.rotation.x = Math.PI / 2; din.position.set(BX + 0.01, 0.305, -0.2); g.add(din);
  // bobinas de los reguladores junto al CPU
  for (let i = 0; i < 4; i++) {
    const coil = new THREE.Mesh(new THREE.TorusGeometry(0.0045, 0.0022, 6, 12), M.copper);
    coil.rotation.y = Math.PI / 2; coil.position.set(BX + 0.004, 0.31, -0.16 + i * 0.014); coil.castShadow = true; g.add(coil);
  }
  // agujeros de los tornillos (anillos dorados)
  for (const y of [0.06, 0.3]) for (const z of [-0.19, -0.06, 0.07]) {
    const ring = new THREE.Mesh(new THREE.TorusGeometry(0.004, 0.0012, 6, 16), M.gold);
    ring.rotation.y = Math.PI / 2; ring.position.set(BX + 0.0002, y, z); g.add(ring);
  }
  for (let i = 0; i < 4; i++) S(0.007, 0.13, 0.006, lvl >= 3 ? M.white : M.black, 0.24, 0.025 + i * 0.016);
  S(0.008, 0.008, 0.09, lvl >= 2 ? mat(0x7a4a20) : M.white, 0.11, -0.11);
  S(0.008, 0.008, 0.085, M.white, 0.075, -0.11);
  S(0.008, 0.008, 0.085, M.white, 0.045, -0.11);
  if (lvl < 4) S(0.008, 0.008, 0.11, M.black, 0.165, -0.1);
  S(0.006, 0.035, 0.035, M.chip, 0.17, -0.02);
  if (lvl >= 3) g.add(heatsink(0.03, 0.03, 0.012, 5, M.alu).translateX(BX + 0.006).translateY(0.17).translateZ(-0.02));
  S(0.004, 0.02, 0.012, M.chip, 0.09, 0.03);
  const bat = cyl(0.01, 0.01, 0.003, M.alu);
  bat.rotation.z = Math.PI / 2; bat.position.set(BX + 0.002, 0.15, 0.05); g.add(bat);
  for (let i = 0; i < 10; i++) {
    const c = cyl(0.004, 0.004, 0.012, mat(i % 3 ? 0x1a2a6a : 0x222222));
    c.rotation.z = Math.PI / 2;
    c.position.set(BX + 0.006, 0.29 - (i % 5) * 0.01, -0.16 + Math.floor(i / 5) * 0.01);
    g.add(c);
  }
  const lab = label(nameAt('motherboard', lvl), 0.06, 0.012, { bg: '#ffffff00', fg: '#e8e8d8', font: 'bold 60px Arial' });
  lab.rotation.y = Math.PI / 2; lab.position.set(BX + 0.0005, 0.06, -0.12); g.add(lab);
  return g;
}

function buildCpu(lvl) {
  const g = new THREE.Group();
  const [x, y, z] = ANCHOR.cpu;
  const name = nameAt('cpu', lvl);
  if (name.includes('II')) {
    g.add(box(0.07, 0.14, 0.016, mat(0x202020, { roughness: 0.4 }), BX + 0.047, y, z));
    const l = label(name, 0.05, 0.03, { bg: '#202020', fg: '#d4a73a', font: 'bold 44px Arial' });
    l.position.set(BX + 0.045, y + 0.03, z + 0.0085); g.add(l);
    return g;
  }
  g.add(box(0.003, 0.034, 0.034, M.ceramic, x - 0.0035, y, z));
  const l = label(`${name}\n${['A80502', 'SY022', 'SY062', 'SL22J', 'SL27S'][lvl] || 'MMX'}`, 0.028, 0.028, { bg: '#8a8478', fg: '#f0ead8', font: 'bold 40px Arial' });
  l.rotation.y = Math.PI / 2; l.position.set(x - 0.0019, y, z); g.add(l);
  return g;
}

const COOLER_H = [0.009, 0.011, 0.015, 0.022];
function buildCooling(lvl, cpuLvl) {
  const g = new THREE.Group();
  const [x, y, z] = ANCHOR.cooling;
  const cart = nameAt('cpu', cpuLvl).includes('II');
  const mount = new THREE.Group();
  if (cart) { mount.position.set(BX + 0.045, y, z + 0.008); mount.rotation.y = -Math.PI / 2; }
  else mount.position.set(x - 0.02, y, z);
  g.add(mount);
  if (lvl < 4) {
    const h = COOLER_H[lvl];
    const s = [0.036, 0.038, 0.044, 0.048][lvl];
    mount.add(heatsink(s, s, h, 8 + lvl * 2, lvl === 3 ? M.copper : M.alu));
    if (lvl >= 1) { const f = fan(s * 0.95); f.position.x = h + 0.006; mount.add(f); }
    return g;
  }
  mount.add(box(0.01, 0.038, 0.038, lvl === 6 ? mat(0x111111) : M.copper, 0.005, 0, 0));
  const coolant = lvl === 4 ? mat(0x303030) : lvl === 5
    ? new THREE.MeshStandardMaterial({ color: 0x40a0ff, transparent: true, opacity: 0.75, roughness: 0.1 })
    : new THREE.MeshStandardMaterial({ color: 0x30ff90, emissive: 0x20c070, emissiveIntensity: 0.5, roughness: 0.2 });
  const rx = 0.0, ry = 0.29, rz = -0.205;
  g.add(box(0.13, 0.12, 0.02, M.black, rx, ry, rz));
  const rf = fan(0.11, { glow: lvl === 6 ? coolant : null }); rf.rotation.y = -Math.PI / 2; rf.position.set(rx, ry, rz + 0.016); g.add(rf);
  const bx = cart ? BX + 0.06 : x - 0.005;
  g.add(tube([[bx, y + 0.01, z + (cart ? 0.02 : 0)], [bx + 0.03, y + 0.04, z - 0.02], [rx + 0.04, ry + 0.05, rz + 0.04], [rx + 0.05, ry + 0.04, rz + 0.012]], 0.005, coolant));
  g.add(tube([[bx, y - 0.01, z + (cart ? 0.02 : 0)], [bx + 0.04, y - 0.03, z - 0.03], [rx - 0.04, ry - 0.06, rz + 0.04], [rx - 0.05, ry - 0.04, rz + 0.012]], 0.005, coolant));
  if (lvl === 6) {
    const res = cyl(0.015, 0.015, 0.08, coolant); res.position.set(0.05, 0.2, 0.05); g.add(res);
    const light = new THREE.PointLight(0x30ff90, 0.12, 0.3); light.position.set(0, 0.25, 0); g.add(light);
  }
  return g;
}

function buildRam(lvl) {
  const g = new THREE.Group();
  const count = [1, 2, 2, 2, 3, 3, 4][lvl] ?? 1;
  const dimm = lvl >= 3;
  const [, y, z] = ANCHOR.ram;
  const col = dimm ? 0x1a5a4a : 0x2a6a2a;
  const pcb = mat(col, { roughness: 0.5 });
  const face = pcbMat(col);
  for (let i = 0; i < count; i++) {
    const zz = z + i * 0.016;
    g.add(box(0.03, dimm ? 0.125 : 0.105, 0.0025, [pcb, pcb, pcb, pcb, face, face], BX + 0.022, y, zz));
    const st = label(nameAt('ram', lvl), 0.012, 0.03, { bg: '#f0f0e8', fg: '#222', font: 'bold 90px Arial' });
    st.rotation.z = Math.PI / 2; st.position.set(BX + 0.03, y + 0.035, zz - 0.0014); st.rotation.y = Math.PI; g.add(st);
    const chips = dimm ? 8 : 6;
    for (let c = 0; c < chips; c++) g.add(box(0.012, 0.01, 0.002, M.chip, BX + 0.025, y - 0.05 + c * (0.1 / (chips - 1)), zz + 0.002));
    g.add(box(0.002, dimm ? 0.12 : 0.1, 0.003, M.gold, BX + 0.0075, y, zz));
  }
  return g;
}

function buildGpu(lvl) {
  const g = new THREE.Group();
  const len = [0.12, 0.13, 0.14, 0.16, 0.18, 0.2, 0.22][lvl] ?? 0.12;
  const [, y] = ANCHOR.display;
  const z0 = -0.205;
  const pcb = mat([0x1f5f2e, 0x2a4a8a, 0x2a4a8a, 0x3a3a3a, 0x1a1a1a, 0x2a2a6a, 0x101010][lvl] ?? 0x1f5f2e, { roughness: 0.5 });
  const pcbCol = [0x1f5f2e, 0x2a4a8a, 0x2a4a8a, 0x3a3a3a, 0x1a1a1a, 0x2a2a6a, 0x101010][lvl] ?? 0x1f5f2e;
  g.add(box(0.09, 0.002, len, [pcb, pcb, pcbMat(pcbCol), pcb, pcb, pcb], BX + 0.054, y + 0.004, z0 + len / 2));
  for (let i = 0; i < 6; i++) { const c = cyl(0.002, 0.002, 0.006, mat(0x1a2a6a), 8); c.position.set(BX + 0.015 + (i % 3) * 0.006, y + 0.008, z0 + len - 0.02 - Math.floor(i / 3) * 0.008); g.add(c); }
  g.add(box(0.1, 0.012, 0.002, M.metal, BX + 0.05, y + 0.004, z0 - 0.002));
  g.add(box(0.008, 0.006, 0.07, M.gold, BX + 0.006, y + 0.004, z0 + 0.05));
  g.add(box(0.025, 0.003, 0.025, M.chip, BX + 0.05, y + 0.007, z0 + len * 0.55));
  for (let i = 0; i < 2 + Math.min(lvl, 4); i++) g.add(box(0.012, 0.003, 0.008, M.chip, BX + 0.03 + (i % 2) * 0.04, y + 0.007, z0 + 0.02 + Math.floor(i / 2) * 0.018));
  const top = new THREE.Group();
  top.position.set(BX + 0.05, y + 0.0085, z0 + len * 0.55);
  top.rotation.z = Math.PI / 2;
  if (lvl >= 3 && lvl < 6) top.add(heatsink(0.035, 0.035, 0.012, 7, M.alu));
  if (lvl >= 4 && lvl < 6) { const f = fan(0.032); f.position.x = 0.018; top.add(f); }
  if (lvl >= 6) {
    top.add(heatsink(0.07, 0.11, 0.02, 14, mat(0x1a1a1a, { metalness: 0.6, roughness: 0.4 })));
    g.add(box(0.075, 0.002, 0.05, mat(0x3060c0, { metalness: 0.3 }), BX + 0.05, y + 0.031, z0 + len * 0.55));
  }
  g.add(top);
  return g;
}

function buildDisk(lvl) {
  const g = new THREE.Group();
  const [x, y, z] = ANCHOR.disk;
  g.add(box(0.1, 0.025, 0.14, [M.steel, M.steel, M.steel, pcbMat(0x1f5f2e), M.steel, M.steel], x, y, z));
  g.add(box(0.06, 0.008, 0.004, [M.black, M.black, M.black, M.black, M.black, headerM], x - 0.015, y, z - 0.0715));
  const l = label(`${nameAt('disk', lvl)}\nIDE`, 0.07, 0.09, { bg: '#e8e4d8', fg: '#222', font: 'bold 70px Arial', border: '#333' });
  l.rotation.x = -Math.PI / 2; l.position.set(x, y + 0.0127, z); g.add(l);
  g.add(box(0.06, 0.006, 0.004, M.black, x, y, z - 0.072));
  g.add(tube([[x - 0.02, y, z - 0.075], [x - 0.03, y + 0.02, z - 0.1], [BX + 0.02, 0.06, -0.02], [BX + 0.008, 0.07, 0.02]], 0.004, M.cable));
  return g;
}

function buildPsu(lvl) {
  const g = new THREE.Group();
  const [x, y, z] = ANCHOR.psu;
  const h = 0.085 + lvl * 0.002;
  const grill = tex(128, 128, (c, w, hh) => { c.fillStyle = '#9a9ea2'; c.fillRect(0, 0, w, hh); c.fillStyle = '#222'; c.beginPath(); c.arc(w / 2, hh / 2, 56, 0, Math.PI * 2); c.fill(); c.strokeStyle = '#b0b4b8'; c.lineWidth = 3; for (let r = 12; r < 56; r += 11) { c.beginPath(); c.arc(w / 2, hh / 2, r, 0, Math.PI * 2); c.stroke(); } c.beginPath(); c.moveTo(w / 2 - 56, hh / 2); c.lineTo(w / 2 + 56, hh / 2); c.moveTo(w / 2, hh / 2 - 56); c.lineTo(w / 2, hh / 2 + 56); c.stroke(); });
  g.add(box(0.15, h, 0.14, [M.metal, M.metal, M.metal, new THREE.MeshStandardMaterial({ map: grill, metalness: 0.6, roughness: 0.4 }), M.metal, M.metal], x, y, z));
  [0xc02020, 0xe0c020, 0x202020, 0x202020].forEach((cc, i) => g.add(tube([[x + 0.02 + i * 0.006, y - h / 2, z + 0.05], [x + 0.03, y - 0.09, z + 0.12], [0.02 + i * 0.004, 0.31, 0.12], [0.03 + i * 0.004, 0.3, 0.06]], 0.0018, mat(cc))));
  const l = label(`${nameAt('psu', lvl).replace('Fuente ', '')}\nPOWER SUPPLY`, 0.1, 0.05, { bg: '#f2efe0', fg: '#222', font: 'bold 60px Arial', border: '#c00' });
  l.rotation.y = Math.PI / 2; l.position.set(x + 0.0755, y, z); g.add(l);
  g.add(tube([[x - 0.03, y - h / 2, z + 0.06], [x - 0.05, y - 0.08, z + 0.08], [BX + 0.02, 0.26, -0.02], [BX + 0.006, 0.22, 0.0]], 0.006, mat(0xd8a020)));
  return g;
}

// --------------------------------------------------------------- fijaciones
// Cada pieza está sujeta con tornillos, trabas, cables o palancas. Para sacarla
// hay que soltarlas todas y antes sacar lo que tenga encima; para ponerla, lo
// que va debajo tiene que estar.
const NEEDS_OUT = { cpu: ['cooling'], motherboard: ['cpu', 'cooling', 'ram', 'display'] };
const NEEDS_IN = { cpu: ['motherboard'], ram: ['motherboard'], display: ['motherboard'], cooling: ['cpu'] };

function fastenerSpecs(stat, lvl, hw) {
  const X = [1, 0, 0], Y = [0, 1, 0], Z = [0, 0, 1], NZ = [0, 0, -1];
  const cart = nameAt('cpu', hw.cpu || 0).includes('II');
  switch (stat) {
    case 'psu': {
      const [x, y, z] = ANCHOR.psu;
      return [
        ...[[0.033, -0.06], [-0.033, -0.06], [0.033, 0.06], [-0.033, 0.06]].map(([dy, dz]) => ({ type: 'screw', p: [x + 0.0755, y + dy, z + dz], n: X })),
        { type: 'cable', p: [BX + 0.0105, 0.22, 0.0], n: X, color: 0xffffff },
      ];
    }
    case 'disk': {
      const [x, y, z] = ANCHOR.disk;
      return [
        { type: 'screw', p: [x + 0.0505, y, z - 0.045], n: X }, { type: 'screw', p: [x + 0.0505, y, z + 0.045], n: X },
        { type: 'cable', p: [x - 0.015, y, z - 0.078], n: NZ, color: 0x9a9a90 }, { type: 'cable', p: [x + 0.032, y, z - 0.076], n: NZ, color: 0xffffff },
      ];
    }
    case 'display': return [{ type: 'screw', p: [BX + 0.1, ANCHOR.display[1] + 0.011, -0.207], n: Y }];
    case 'ram': {
      const [, y, z] = ANCHOR.ram;
      const count = [1, 2, 2, 2, 3, 3, 4][lvl] ?? 1;
      return Array.from({ length: count }, (_, i) => ({ type: 'latch', p: [BX + 0.009, y + (lvl >= 3 ? 0.066 : 0.056), z + i * 0.016], n: X }));
    }
    case 'cooling': {
      const [x, y, z] = ANCHOR.cooling;
      const out = [];
      if (lvl < 4) {
        const h = COOLER_H[lvl] + (lvl >= 1 ? 0.01 : 0);
        out.push(cart ? { type: 'clip', p: [BX + 0.045, y, z + 0.01 + h], n: Z } : { type: 'clip', p: [x - 0.02 + h + 0.002, y, z], n: X });
        if (lvl >= 1) out.push({ type: 'cable', p: [BX + 0.0055, y + 0.048, z + 0.04], n: X, color: 0x202020 });
      } else {
        out.push({ type: 'screw', p: [-0.05, 0.335, -0.194], n: Z }, { type: 'screw', p: [0.05, 0.335, -0.194], n: Z });
        out.push(cart ? { type: 'clip', p: [BX + 0.045, y, z + 0.022], n: Z } : { type: 'clip', p: [x - 0.006, y, z], n: X });
      }
      return out;
    }
    case 'cpu': {
      const [, y, z] = ANCHOR.cpu;
      return cart
        ? [{ type: 'latch', p: [BX + 0.02, y + 0.078, z], n: X }, { type: 'latch', p: [BX + 0.02, y - 0.078, z], n: X }]
        : [{ type: 'lever', p: [BX + 0.0055, y - 0.023, z - 0.021], n: X }];
    }
    case 'motherboard': return [0.06, 0.3].flatMap((y) => [-0.19, -0.06, 0.07].map((z) => ({ type: 'screw', p: [BX + 0.0003, y, z], n: X })));
    default: return [];
  }
}

const UP = new THREE.Vector3(0, 1, 0);
function buildFastener(spec, stat, i) {
  const f = new THREE.Group();
  const inner = new THREE.Group();
  f.add(inner);
  const n = new THREE.Vector3(...spec.n);
  f.quaternion.setFromUnitVectors(UP, n);
  f.userData = { kind: 'fastener', stat, i, type: spec.type, base: new THREE.Vector3(...spec.p), n, t: 0 };
  const steel = M.alu;
  if (spec.type === 'screw') {
    const head = cyl(0.0045, 0.0045, 0.0025, steel, 14); head.position.y = 0.00125; inner.add(head);
    inner.add(box(0.0065, 0.001, 0.0012, M.dark, 0, 0.0026, 0), box(0.0012, 0.001, 0.0065, M.dark, 0, 0.0026, 0));
    const shank = cyl(0.0016, 0.0016, 0.008, steel, 8); shank.position.y = -0.004; inner.add(shank);
  } else if (spec.type === 'latch') {
    inner.add(box(0.005, 0.01, 0.006, M.white, 0, 0.005, 0));
  } else if (spec.type === 'clip') {
    inner.add(box(0.003, 0.0025, 0.052, M.steel, 0, 0.0012, 0), box(0.006, 0.008, 0.004, M.steel, 0, 0.004, 0.026));
  } else if (spec.type === 'lever') {
    inner.add(box(0.003, 0.003, 0.042, M.alu, 0, 0.0015, 0.021));
    const knob = cyl(0.003, 0.003, 0.008, mat(0xe8e8e8), 10); knob.position.set(0, 0.005, 0.042); inner.add(knob);
  } else if (spec.type === 'cable') {
    inner.add(box(0.012, 0.008, 0.02, mat(spec.color ?? 0xffffff, { roughness: 0.5 }), 0, 0.004, 0));
    [0xc02020, 0xe0c020, 0x202020].forEach((c, k) => inner.add(box(0.0025, 0.02, 0.0025, mat(c), -0.003 + k * 0.003, 0.018, 0)));
  }
  inner.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.material = o.material.clone(); } });
  const grab = new THREE.Mesh(new THREE.SphereGeometry(0.011, 8, 6), new THREE.MeshBasicMaterial());
  grab.visible = false;                // área de clic generosa (los tornillos son chicos)
  inner.add(grab);
  poseFastener(f, 0);
  return f;
}
/** Brillo amarillo en una fijación (lo que todavía sujeta la pieza). */
function glowFastener(f, on) {
  f.children[0].traverse((o) => { if (o.isMesh && o.material.emissive) { o.material.emissive.setHex(on ? 0xffc020 : 0); o.material.emissiveIntensity = on ? 0.9 : 0; } });
}
/** t = 0 puesto, t = 1 suelto. */
function poseFastener(f, t) {
  const { type, base, n } = f.userData;
  f.userData.t = t;
  f.position.copy(base).addScaledVector(n, type === 'screw' ? 0.012 * t : type === 'cable' ? 0.022 * t : 0);
  const inner = f.children[0];
  if (type === 'screw') inner.rotation.y = t * Math.PI * 6;
  else if (type === 'latch') inner.rotation.x = t * 0.9;
  else if (type === 'clip') inner.rotation.x = t * 1.1;
  else if (type === 'lever') inner.rotation.x = -t * Math.PI / 2;
}

const BUILDERS = { motherboard: buildMotherboard, cpu: buildCpu, cooling: buildCooling, ram: buildRam, display: buildGpu, disk: buildDisk, psu: buildPsu };
const buildPart = (stat, lvl, hw) => (stat === 'cooling' ? buildCooling(lvl, hw.cpu || 0) : stat === 'motherboard' ? buildMotherboard(lvl, hw) : BUILDERS[stat](lvl));

/** Pieza quemada: oscurecida, con hollín, y si tiene ventilador, detenido. */
function burn(part) {
  const soot = mat(0x0a0806, { roughness: 1 });
  const meshes = [];
  part.traverse((o) => {
    if (o.userData.rotor) o.userData.stopped = true;
    if (o.isMesh) {
      const char = (src) => {
        const m = src.clone();
        if (m.color) m.color.multiplyScalar(0.45).lerp(new THREE.Color(0x3a2010), 0.3);
        if (m.map) m.color.multiplyScalar(0.7);
        return m;
      };
      o.material = Array.isArray(o.material) ? o.material.map(char) : char(o.material);
      meshes.push(o);
    }
  });
  const bb = new THREE.Box3().setFromObject(part);
  for (let i = 0; i < 5; i++) {
    const s = new THREE.Mesh(new THREE.SphereGeometry(0.004 + Math.random() * 0.006, 8, 6), soot);
    s.position.set(THREE.MathUtils.lerp(bb.min.x, bb.max.x, Math.random()), THREE.MathUtils.lerp(bb.min.y, bb.max.y, Math.random()), THREE.MathUtils.lerp(bb.min.z, bb.max.z, Math.random()));
    s.scale.set(1, 0.4, 1);
    part.add(s);
  }
  return part;
}

// -------------------------------------------------------------- torres
/**
 * Una torre: la tuya (lee game.hw, con tapa que se abre) o la de un cliente
 * (lee el trabajo del Taller: piezas quemadas y faltantes, sin tapa).
 */
class Tower {
  constructor({ hw, broken = () => ({}), missing = () => ({}), loose = () => ({}), setLoose = () => {}, color = null, dusty = false, panel = true, pos, rotY = 0 }) {
    Object.assign(this, { hw, broken, missing, loose, setLoose });
    this.fast = {};          // stat -> [true = puesto]
    this.anims = [];
    this.powered = false;
    this.group = new THREE.Group();
    this.group.position.copy(pos);
    this.group.rotation.y = rotY;
    this.parts = {};
    const W = 0.2, H = 0.42, D = 0.45;
    const g = this.group;
    const shell = color != null
      ? new THREE.MeshStandardMaterial({ color: new THREE.Color(color).multiplyScalar(dusty ? 0.88 : 1), map: plasticMap, bumpMap: plasticBump, bumpScale: 0.001, roughness: dusty ? 0.9 : 0.62 })
      : M.beige;
    g.add(box(0.004, H, D, [M.inside, shell, shell, shell, shell, shell], -W / 2 + 0.002, H / 2, 0));
    g.add(box(W, 0.004, D, shell, 0, H - 0.002, 0));
    g.add(box(W, 0.004, D, M.inside, 0, 0.002, 0));
    // parte trasera con puertos
    const back = tex(256, 540, (x, w, h) => {
      x.fillStyle = '#6c7075'; x.fillRect(0, 0, w, h); noise(x, w, h, 2000, 0.06);
      x.fillStyle = '#2a2a2a'; x.fillRect(30, 20, 196, 130);                                   // fuente
      x.fillStyle = '#444'; for (let i = 0; i < 9; i++) x.fillRect(50, 30 + i * 13, 156, 5);
      x.fillStyle = '#1a1a1a'; x.fillRect(150, 200, 60, 26); x.fillRect(150, 236, 60, 16);      // puertos
      x.fillStyle = '#3050a0'; x.fillRect(80, 200, 50, 18); x.fillStyle = '#806030'; x.fillRect(80, 228, 50, 18);
      for (let i = 0; i < 5; i++) { x.fillStyle = '#9a9ea2'; x.fillRect(40, 300 + i * 34, 176, 24); x.fillStyle = '#555'; x.fillRect(48, 306 + i * 34, 160, 4); }
    });
    g.add(box(W, H, 0.004, [M.steel, M.steel, M.steel, M.steel, M.inside, new THREE.MeshStandardMaterial({ map: back, metalness: 0.5, roughness: 0.5 })], 0, H / 2, -D / 2 + 0.002));
    const front = tex(256, 540, (x, w, h) => {
      x.drawImage(plasticCanvas, 0, 0, w, h);
      const bay = (y, hh) => { x.fillStyle = '#cfc6ad'; x.fillRect(18, y, w - 36, hh); x.strokeStyle = '#9a917a'; x.lineWidth = 2; x.strokeRect(18, y, w - 36, hh); };
      bay(30, 52); x.fillStyle = '#222'; x.fillRect(40, 52, w - 80, 6); x.fillStyle = '#7a7262'; x.fillRect(w - 64, 66, 26, 10);
      bay(92, 52);
      bay(160, 36); x.fillStyle = '#222'; x.fillRect(70, 176, 110, 5); x.fillStyle = '#9a917a'; x.fillRect(190, 182, 18, 10);
      x.fillStyle = '#b8ae94';
      for (let i = 0; i < 9; i++) x.fillRect(40, 300 + i * 18, w - 80, 7);
      x.fillStyle = '#2a2a6a'; x.font = 'bold 26px Arial'; x.textAlign = 'center'; x.fillText('GVS', w / 2, 490);
      x.font = '12px Arial'; x.fillStyle = '#555'; x.fillText('PENTIUM SYSTEM', w / 2, 508);
      if (dusty) { x.fillStyle = 'rgba(120,110,90,.18)'; x.fillRect(0, 0, w, h); noise(x, w, h, 3000, 0.08, 3); }
    });
    g.add(box(W, H, 0.02, [shell, shell, shell, shell, new THREE.MeshStandardMaterial({ map: front, bumpMap: plasticBump, bumpScale: 0.0006, roughness: 0.65 }), shell], 0, H / 2, D / 2 - 0.01));
    this.powerBtn = rbox(0.03, 0.03, 0.01, 0.004, M.beigeDark, 0, 0.12, D / 2 + 0.003);
    this.powerBtn.userData.kind = 'power';
    g.add(this.powerBtn);
    this.ledPower = box(0.008, 0.004, 0.004, new THREE.MeshStandardMaterial({ color: 0x103010, emissive: 0x20ff40, emissiveIntensity: 0 }), -0.035, 0.08, D / 2 + 0.002);
    this.ledDisk = box(0.008, 0.004, 0.004, new THREE.MeshStandardMaterial({ color: 0x302010, emissive: 0xffa020, emissiveIntensity: 0 }), 0.035, 0.08, D / 2 + 0.002);
    g.add(this.ledPower, this.ledDisk);
    g.add(box(0.13, 0.04, 0.17, M.steel, 0, 0.36, 0.13), box(0.1, 0.025, 0.14, M.steel, 0, 0.3, 0.14));
    for (const [y, z] of [[0.03, -0.2], [0.39, -0.2], [0.03, 0.2], [0.39, 0.2]]) { const s = cyl(0.004, 0.004, 0.003, M.alu, 8); s.rotation.z = Math.PI / 2; s.position.set(W / 2 + 0.001, y, z); g.add(s); }
    if (panel) { this.panel = box(0.004, H, D, shell, W / 2 - 0.002, H / 2, 0); g.add(this.panel); }
    this.open = 0;
    this.rebuildAll();
  }

  rebuild(stat) {
    if (this.parts[stat]) this.group.remove(this.parts[stat]);
    delete this.parts[stat];
    const hw = this.hw();
    if (this.missing()[stat] || (stat === 'cooling' && this.missing().cpu)) { delete this.fast[stat]; if (stat === 'cpu') this.rebuild('cooling'); return; }
    const part = buildPart(stat, hw[stat] || 0, hw);
    if (this.broken()[stat]) burn(part);
    part.traverse((o) => { if (o.userData.rotor) o.userData.tower = this; });
    // fijaciones: se recuerdan entre reconstrucciones (atornillar a medias se mantiene)
    const specs = fastenerSpecs(stat, hw[stat] || 0, hw);
    if (!this.fast[stat] || this.fast[stat].length !== specs.length) this.fast[stat] = specs.map(() => !this.loose()[stat]);
    specs.forEach((sp, i) => { const f = buildFastener(sp, stat, i); poseFastener(f, this.fast[stat][i] ? 0 : 1); part.add(f); });
    part.userData.stat = stat;
    this.parts[stat] = part;
    // área de clic invisible: las piezas delgadas (RAM) son difíciles de acertar.
    // Se mide antes de agregarla a la torre, así la caja queda en coordenadas locales.
    // Los cables (tubos) y las fijaciones no cuentan: si no, la fuente tapaba medio gabinete.
    const bb = new THREE.Box3();
    part.updateMatrixWorld(true);
    part.traverse((o) => {
      if (!o.isMesh || o.geometry.type === 'TubeGeometry' || o.geometry.type === 'PlaneGeometry') return;
      for (let q = o; q && q !== part; q = q.parent) if (q.userData.kind === 'fastener') return;
      o.geometry.computeBoundingBox();
      bb.union(o.geometry.boundingBox.clone().applyMatrix4(o.matrixWorld));
    });
    this.group.add(part);
    const size = bb.getSize(new THREE.Vector3()).max(new THREE.Vector3(0.02, 0.02, 0.02)).addScalar(0.006);
    const hit = new THREE.Mesh(new THREE.BoxGeometry(size.x, size.y, size.z),
      new THREE.MeshBasicMaterial({ color: 0x40ff60, transparent: true, opacity: 0.18, depthWrite: false }));
    hit.visible = false;               // invisible, pero el raycaster la sigue viendo
    hit.userData.hitbox = true;
    bb.getCenter(hit.position);
    part.add(hit);
    part.userData.hitbox = hit;
    if (stat === 'cpu') {
      this.rebuild('cooling');
      const cart = nameAt('cpu', hw.cpu || 0).includes('II');
      if (this.cpuCart !== undefined && this.cpuCart !== cart) this.rebuild('motherboard');
      this.cpuCart = cart;
    }
  }
  rebuildAll() { for (const s of PART_STATS) this.rebuild(s); }

  anchorWorld(stat) { return this.group.localToWorld(new THREE.Vector3(...ANCHOR[stat])); }

  has(stat) { return !!this.parts[stat]; }
  fasteners(stat) { const out = []; this.parts[stat]?.traverse((o) => { if (o.userData.kind === 'fastener') out.push(o); }); return out; }
  /** ¿Están todas sueltas? */
  free(stat) { return (this.fast[stat] || []).every((v) => !v); }
  /** Qué piezas tienen que salir antes (y siguen puestas). */
  blockersOut(stat) { return (NEEDS_OUT[stat] || []).filter((s) => this.has(s)); }
  /** Qué piezas faltan debajo para poder poner esta. */
  blockersIn(stat) { return (NEEDS_IN[stat] || []).filter((s) => !this.has(s)); }

  toggle(stat, i) {
    const arr = this.fast[stat];
    if (!arr) return;
    arr[i] = !arr[i];
    const f = this.fasteners(stat).find((o) => o.userData.i === i);
    if (f) this.anims.push({ f, from: f.userData.t, to: arr[i] ? 0 : 1, t: 0, dur: f.userData.type === 'screw' ? 0.5 : 0.25 });
    this.setLoose(stat, !arr.every(Boolean));
    play(f?.userData.type === 'screw' ? 'circle2' : 'circle1', { volume: 0.25 });
  }
  /** Hace parpadear lo que todavía está puesto (pista de qué falta soltar). */
  hint(stat) {
    this.fasteners(stat).filter((f) => this.fast[stat][f.userData.i]).forEach((f) => this.anims.push({ f, pulse: true, t: 0, dur: 0.6 }));
  }
  update(dt) {
    for (const a of [...this.anims]) {
      a.t = Math.min(1, a.t + dt / a.dur);
      const e = a.t < 0.5 ? 2 * a.t * a.t : 1 - (-2 * a.t + 2) ** 2 / 2;
      if (a.pulse) a.f.scale.setScalar(1 + Math.sin(a.t * Math.PI * 3) ** 2 * 0.8);
      else poseFastener(a.f, a.from + (a.to - a.from) * e);
      if (a.t >= 1) { if (a.pulse) a.f.scale.setScalar(1); this.anims.splice(this.anims.indexOf(a), 1); }
    }
  }

  setOpen(v) {
    if (!this.panel) return;
    this.open = v;
    const a = Math.min(1, v / 0.35), b = Math.max(0, (v - 0.35) / 0.65);
    this.panel.position.set(0.098 + a * 0.06, 0.21, -b * 0.62);
    this.panel.visible = v < 0.999;
  }
}

// -------------------------------------------------------------- la pieza
function buildRoom(scene) {
  // piso de tablas con relieve
  const floorC = canvasOf(1024, 1024, (x, w, h) => {
    for (let i = 0; i < 8; i++) {
      const c = 120 + Math.random() * 30;
      x.fillStyle = `rgb(${c},${c * 0.68},${c * 0.42})`;
      x.fillRect(0, i * h / 8, w, h / 8);
      for (let k = 0; k < 40; k++) { x.strokeStyle = `rgba(60,35,15,${Math.random() * 0.15})`; x.beginPath(); const y = i * h / 8 + Math.random() * h / 8; x.moveTo(0, y); x.lineTo(w, y + (Math.random() - 0.5) * 6); x.stroke(); }
      x.fillStyle = 'rgba(0,0,0,.45)'; x.fillRect(0, i * h / 8, w, 3);
      x.fillRect(((i * 397) % 900) + 60, i * h / 8, 3, h / 8);
    }
    noise(x, w, h, 20000, 0.05);
  });
  const floorM = new THREE.MeshStandardMaterial({ map: texOf(floorC, { repeat: [3, 3] }), bumpMap: texOf(floorC, { repeat: [3, 3], color: false }), bumpScale: 0.002, roughness: 0.55 });
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(7, 7), floorM);
  floor.rotation.x = -Math.PI / 2;
  floor.receiveShadow = true;
  scene.add(floor);
  const rug = new THREE.Mesh(new THREE.CircleGeometry(0.7, 40), new THREE.MeshStandardMaterial({ map: tex(256, 256, (x, w, h) => { x.fillStyle = '#5a2a2a'; x.fillRect(0, 0, w, h); for (let r = 120; r > 0; r -= 14) { x.strokeStyle = r % 28 ? '#8a5a3a' : '#3a1a1a'; x.lineWidth = 6; x.beginPath(); x.arc(w / 2, h / 2, r, 0, Math.PI * 2); x.stroke(); } noise(x, w, h, 8000, 0.08); }), roughness: 1 }));
  rug.rotation.x = -Math.PI / 2; rug.position.set(-0.1, 0.002, 0.75); rug.receiveShadow = true; scene.add(rug);

  // paredes de yeso pintado
  const wallC = canvasOf(512, 512, (x, w, h) => { x.fillStyle = '#8f9a8a'; x.fillRect(0, 0, w, h); noise(x, w, h, 16000, 0.05, 3); });
  const wallM = new THREE.MeshStandardMaterial({ map: texOf(wallC, { repeat: [5, 2.5] }), bumpMap: texOf(wallC, { repeat: [5, 2.5], color: false }), bumpScale: 0.003, roughness: 0.95 });
  const wall = (w, rotY, x, z) => { const m = new THREE.Mesh(new THREE.PlaneGeometry(w, 3), wallM); m.rotation.y = rotY; m.position.set(x, 1.5, z); m.receiveShadow = true; scene.add(m); };
  wall(7, 0, 0.3, -0.62);
  wall(7, Math.PI / 2, -1.6, 0);
  wall(7, -Math.PI / 2, 2.35, 0);
  scene.add(box(4, 0.1, 0.02, mat(0x6a5a48), 0.37, 0.05, -0.61));
  const ceil = new THREE.Mesh(new THREE.PlaneGeometry(7, 7), mat(0xd8d4c8, { roughness: 1 }));
  ceil.rotation.x = Math.PI / 2; ceil.position.y = 2.6; scene.add(ceil);

  // escritorio con cajonera
  const deskC = canvasOf(1024, 512, (x, w, h) => {
    x.fillStyle = '#a07850'; x.fillRect(0, 0, w, h);
    for (let i = 0; i < 90; i++) { x.strokeStyle = `rgba(80,50,25,${0.05 + Math.random() * 0.14})`; x.lineWidth = 1 + Math.random() * 3; x.beginPath(); const y = Math.random() * h; x.moveTo(0, y); x.bezierCurveTo(w * 0.3, y + 10, w * 0.6, y - 10, w, y + 5); x.stroke(); }
    noise(x, w, h, 6000, 0.04);
  });
  const deskM = new THREE.MeshStandardMaterial({ map: texOf(deskC), bumpMap: texOf(deskC, { color: false }), bumpScale: 0.0015, roughness: 0.45 });
  scene.add(box(1.6, 0.035, 0.78, deskM, 0, DESK_Y - 0.0175, 0));
  const legM = mat(0x5a4632, { roughness: 0.6 });
  for (const [x, z] of [[0.76, -0.35], [0.76, 0.35]]) scene.add(box(0.045, DESK_Y - 0.035, 0.045, legM, x, (DESK_Y - 0.035) / 2, z));
  scene.add(box(0.42, DESK_Y - 0.035, 0.74, deskM, -0.58, (DESK_Y - 0.035) / 2, 0));
  for (let i = 0; i < 3; i++) {
    scene.add(box(0.38, 0.2, 0.01, deskM, -0.58, 0.14 + i * 0.235, 0.372));
    scene.add(box(0.08, 0.012, 0.015, M.metal, -0.58, 0.2 + i * 0.235, 0.385));
  }
  scene.add(box(1.5, 0.12, 0.02, mat(0x8a6a48), 0.05, DESK_Y - 0.1, -0.36));

  // teclado con teclas de verdad
  const kb = new THREE.Group();
  kb.position.set(-0.2, DESK_Y, 0.2);
  kb.rotation.x = 0.05;
  kb.add(rbox(0.45, 0.022, 0.165, 0.006, M.beige, 0, 0.011, 0));
  const keyM = mat(0xe9e2cd, { roughness: 0.55 });
  const keyGrayM = mat(0xb9b09a, { roughness: 0.55 });
  const keyGeo = new RoundedBoxGeometry(0.0175, 0.01, 0.0175, 2, 0.002);
  const positions = [];
  for (let r = 0; r < 6; r++) for (let c = 0; c < 18; c++) {
    if (r === 5 && c > 3 && c < 11) continue;
    positions.push([-0.205 + c * 0.0225 + (c > 14 ? 0.01 : 0), 0.026, -0.065 + r * 0.0225, r === 0 || c > 14 || c === 0]);
  }
  for (const gray of [false, true]) {
    const list = positions.filter((p) => p[3] === gray);
    const im = new THREE.InstancedMesh(keyGeo, gray ? keyGrayM : keyM, list.length);
    const m4 = new THREE.Matrix4();
    list.forEach(([x, y, z], i) => im.setMatrixAt(i, m4.makeTranslation(x, y, z)));
    im.castShadow = im.receiveShadow = true;
    kb.add(im);
  }
  kb.add(rbox(0.155, 0.01, 0.0175, 0.002, keyM, -0.11, 0.026, 0.0475));
  scene.add(kb);
  scene.add(box(0.2, 0.003, 0.17, mat(0x203050, { roughness: 0.9 }), 0.08, DESK_Y + 0.0015, 0.22));
  const mouse = new THREE.Mesh(new THREE.SphereGeometry(0.03, 24, 16), M.beige);
  mouse.scale.set(0.95, 0.5, 1.6); mouse.position.set(0.08, DESK_Y + 0.008, 0.22); mouse.castShadow = true; scene.add(mouse);
  scene.add(box(0.002, 0.003, 0.03, M.dark, 0.08, DESK_Y + 0.023, 0.195));
  scene.add(tube([[0.08, DESK_Y + 0.01, 0.17], [0.07, DESK_Y + 0.004, 0.08], [-0.05, DESK_Y + 0.004, 0.0], [-0.2, DESK_Y + 0.004, -0.05]], 0.0025, mat(0xc8c0a8)));

  // parlantes
  for (const x of [-0.52, 0.13]) {
    const sp = rbox(0.09, 0.15, 0.1, 0.008, M.beige, x, DESK_Y + 0.075, -0.17);
    scene.add(sp);
    const grill = new THREE.Mesh(new THREE.CircleGeometry(0.03, 24), mat(0x2a2a2a, { roughness: 0.9 }));
    grill.position.set(x, DESK_Y + 0.09, -0.119); scene.add(grill);
    const tw = new THREE.Mesh(new THREE.CircleGeometry(0.01, 16), mat(0x444444)); tw.position.set(x, DESK_Y + 0.135, -0.119); scene.add(tw);
  }

  // lámpara de escritorio
  const lamp = new THREE.Group();
  lamp.position.set(-0.72, DESK_Y, -0.2);
  const base = cyl(0.07, 0.08, 0.02, mat(0x2a3a2a, { metalness: 0.3, roughness: 0.4 })); base.position.y = 0.01; lamp.add(base);
  const arm1 = cyl(0.008, 0.008, 0.4, M.metal); arm1.position.set(0.04, 0.2, 0); arm1.rotation.z = -0.2; lamp.add(arm1);
  const arm2 = cyl(0.008, 0.008, 0.3, M.metal); arm2.position.set(0.18, 0.42, 0.02); arm2.rotation.z = 1.15; lamp.add(arm2);
  const shade = new THREE.Mesh(new THREE.ConeGeometry(0.07, 0.11, 24, 1, true), new THREE.MeshStandardMaterial({ color: 0x2a3a2a, side: THREE.DoubleSide, roughness: 0.4, metalness: 0.3 }));
  shade.position.set(0.31, 0.47, 0.03); shade.rotation.z = 0.5; shade.castShadow = true; lamp.add(shade);
  const bulb = new THREE.Mesh(new THREE.SphereGeometry(0.02, 12, 12), new THREE.MeshStandardMaterial({ color: 0xfff2c0, emissive: 0xffe0a0, emissiveIntensity: 2 }));
  bulb.position.set(0.33, 0.44, 0.03); lamp.add(bulb);
  scene.add(lamp);
  const spot = new THREE.SpotLight(0xffd9a0, 7, 3, 0.95, 0.6, 1.2);
  spot.position.set(-0.39, DESK_Y + 0.44, -0.17);
  spot.target.position.set(-0.05, DESK_Y, 0.1);
  spot.castShadow = true;
  spot.shadow.mapSize.set(1024, 1024);
  spot.shadow.bias = -0.0005;
  scene.add(spot, spot.target);

  // silla
  const chair = new THREE.Group();
  chair.position.set(-0.42, 0, 0.82);
  chair.rotation.y = 0.45;
  const fabric = mat(0x24304a, { roughness: 0.95 });
  chair.add(rbox(0.46, 0.07, 0.44, 0.03, fabric, 0, 0.47, 0));
  chair.add(rbox(0.42, 0.48, 0.06, 0.03, fabric, 0, 0.8, 0.22));
  chair.add(box(0.04, 0.2, 0.03, M.black, 0, 0.55, 0.2));
  const pole = cyl(0.02, 0.02, 0.36, M.metal); pole.position.y = 0.26; chair.add(pole);
  for (let i = 0; i < 5; i++) {
    const leg = box(0.3, 0.025, 0.04, M.black, 0.15, 0.07, 0);
    const arm = new THREE.Group(); arm.add(leg); arm.rotation.y = (i / 5) * Math.PI * 2; chair.add(arm);
    const wheel = new THREE.Mesh(new THREE.SphereGeometry(0.022, 10, 8), M.black);
    wheel.position.set(Math.cos((i / 5) * Math.PI * 2) * 0.29, 0.025, -Math.sin((i / 5) * Math.PI * 2) * 0.29); chair.add(wheel);
  }
  scene.add(chair);

  // ventana con persiana
  const win = new THREE.Group();
  win.position.set(-1.59, 1.55, -0.1);
  win.rotation.y = Math.PI / 2;
  const sky = tex(256, 256, (x, w, h) => { const gr = x.createLinearGradient(0, 0, 0, h); gr.addColorStop(0, '#3a5a8a'); gr.addColorStop(0.7, '#e8a070'); gr.addColorStop(1, '#f0c890'); x.fillStyle = gr; x.fillRect(0, 0, w, h); x.fillStyle = '#2a3040'; for (let i = 0; i < 9; i++) x.fillRect(i * 30, 190 - (i * 37) % 50, 26, 80); });
  win.add(new THREE.Mesh(new THREE.PlaneGeometry(0.9, 0.7), new THREE.MeshBasicMaterial({ map: sky })));
  for (const [w, h, x, y] of [[0.96, 0.04, 0, 0.36], [0.96, 0.04, 0, -0.36], [0.04, 0.76, 0.46, 0], [0.04, 0.76, -0.46, 0], [0.03, 0.7, 0, 0], [0.9, 0.03, 0, 0]]) win.add(box(w, h, 0.03, mat(0xe8e4dc), x, y, 0.01));
  for (let i = 0; i < 16; i++) { const s = box(0.9, 0.035, 0.002, mat(0xeae6da, { roughness: 0.7 }), 0, 0.33 - i * 0.022, 0.03); s.rotation.x = 1.1; win.add(s); }
  win.add(box(0.96, 0.03, 0.05, mat(0xe8e4dc), 0, 0.39, 0.03));
  scene.add(win);
  const sun = new THREE.DirectionalLight(0xffc89a, 1.3);
  sun.position.set(-2.5, 2.2, 0.4);
  sun.target.position.set(0, DESK_Y, 0);
  sun.castShadow = true;
  sun.shadow.mapSize.set(2048, 2048);
  Object.assign(sun.shadow.camera, { left: -2, right: 2.5, top: 1.8, bottom: -1.5 });
  sun.shadow.bias = -0.0004;
  sun.shadow.normalBias = 0.01;
  scene.add(sun, sun.target);

  // ampolleta del techo
  const cord = cyl(0.003, 0.003, 0.5, M.black, 6); cord.position.set(0.6, 2.35, 0.3); scene.add(cord);
  const bulb2 = new THREE.Mesh(new THREE.SphereGeometry(0.035, 16, 12), new THREE.MeshStandardMaterial({ color: 0xfff4d0, emissive: 0xffe8b0, emissiveIntensity: 1.5 }));
  bulb2.position.set(0.6, 2.08, 0.3); scene.add(bulb2);
  const ceilLight = new THREE.PointLight(0xffe2b0, 2.2, 5, 1.6);
  ceilLight.position.set(0.6, 2.0, 0.3);
  scene.add(ceilLight);

  // póster, calendario, repisa, zapatilla y detalles
  const poster = tex(360, 500, (x, w, h) => {
    const gr = x.createLinearGradient(0, 0, 0, h); gr.addColorStop(0, '#101040'); gr.addColorStop(1, '#802060'); x.fillStyle = gr; x.fillRect(0, 0, w, h);
    x.strokeStyle = '#30ffe0'; x.lineWidth = 2;
    for (let i = 0; i < 12; i++) { x.beginPath(); x.moveTo(0, 300 + i * i * 2); x.lineTo(w, 300 + i * i * 2); x.stroke(); }
    for (let i = -6; i <= 6; i++) { x.beginPath(); x.moveTo(w / 2, 300); x.lineTo(w / 2 + i * 60, h); x.stroke(); }
    x.fillStyle = '#ffd040'; x.beginPath(); x.arc(w / 2, 240, 70, Math.PI, 0); x.fill();
    x.fillStyle = '#fff'; x.font = 'bold 54px Arial Black, Arial'; x.textAlign = 'center'; x.fillText('CYBER', w / 2, 90); x.fillText('SPACE', w / 2, 150);
    noise(x, w, h, 4000, 0.06);
  });
  const p = new THREE.Mesh(new THREE.PlaneGeometry(0.36, 0.5), new THREE.MeshStandardMaterial({ map: poster, roughness: 0.4 }));
  p.position.set(0.05, 1.55, -0.615); scene.add(p);
  const cal = label('NOVIEMBRE\n1995', 0.22, 0.28, { bg: '#fbf8ef', fg: '#a01010', font: 'bold 64px Arial', border: '#a01010' });
  cal.position.set(0.62, 1.45, -0.615); scene.add(cal);
  scene.add(box(0.6, 0.02, 0.18, mat(0x7a5a3a), -0.95, 1.25, -0.52));
  const colors = ['#2050a0', '#a03020', '#208040', '#c0a020', '#603090'];
  for (let i = 0; i < 6; i++) {
    const t = tex(64, 256, (x, w, h) => { x.fillStyle = colors[i % 5]; x.fillRect(0, 0, w, h); x.fillStyle = '#fff'; x.fillRect(8, 20, w - 16, 40); x.fillRect(8, 200, w - 16, 10); });
    scene.add(box(0.05, 0.22, 0.15, [M.white, M.white, M.white, M.white, new THREE.MeshStandardMaterial({ map: t, roughness: 0.5 }), M.white], -1.2 + i * 0.055, 1.37, -0.52));
  }
  for (let i = 0; i < 5; i++) {
    const d = box(0.09, 0.003, 0.094, mat([0x202020, 0x1a3a8a, 0x8a1a1a][i % 3], { roughness: 0.4 }), -0.47, DESK_Y + 0.0015 + i * 0.0032, 0.08 + i * 0.004);
    d.rotation.y = i * 0.15; scene.add(d);
  }
  const mug = cyl(0.035, 0.032, 0.09, mat(0xe8e0d0, { roughness: 0.3 })); mug.position.set(-0.6, DESK_Y + 0.045, 0.24); scene.add(mug);
  const handle = new THREE.Mesh(new THREE.TorusGeometry(0.022, 0.006, 8, 16), mat(0xe8e0d0, { roughness: 0.3 })); handle.position.set(-0.635, DESK_Y + 0.05, 0.24); handle.rotation.y = Math.PI / 2; scene.add(handle);
  const coffee = cyl(0.031, 0.031, 0.002, mat(0x3a2010, { roughness: 0.1 })); coffee.position.set(-0.6, DESK_Y + 0.08, 0.24); scene.add(coffee);
  scene.add(box(0.3, 0.04, 0.06, M.white, 0.35, 0.02, -0.45));
  for (let i = 0; i < 3; i++) scene.add(box(0.025, 0.02, 0.03, M.black, 0.27 + i * 0.07, 0.045, -0.45));
  scene.add(tube([[0.52, DESK_Y + 0.1, -0.29], [0.6, DESK_Y - 0.1, -0.4], [0.45, 0.1, -0.5], [0.35, 0.05, -0.45]], 0.004, M.black));
}

function buildBench(scene) {
  const g = new THREE.Group();
  const top = mat(0x6a5038, { roughness: 0.6 });
  g.add(box(1.0, 0.04, 0.62, top, 1.62, BENCH_Y - 0.02, -0.28));
  for (const [x, z] of [[1.15, -0.56], [2.09, -0.56], [1.15, 0.0], [2.09, 0.0]]) g.add(box(0.04, BENCH_Y - 0.04, 0.04, M.steel, x, (BENCH_Y - 0.04) / 2, z));
  g.add(box(0.95, 0.02, 0.55, top, 1.62, 0.18, -0.28));
  g.add(box(0.7, 0.003, 0.45, mat(0x506070, { roughness: 0.95 }), 1.55, BENCH_Y + 0.0015, -0.25)); // alfombra antiestática
  // panel perforado con herramientas
  const peg = tex(512, 340, (x, w, h) => { x.fillStyle = '#b89a70'; x.fillRect(0, 0, w, h); x.fillStyle = '#5a4a30'; for (let i = 10; i < w; i += 20) for (let j = 10; j < h; j += 20) { x.beginPath(); x.arc(i, j, 3, 0, Math.PI * 2); x.fill(); } });
  const pegM = new THREE.MeshStandardMaterial({ map: peg, roughness: 0.8 });
  g.add(box(0.9, 0.6, 0.015, [pegM, pegM, pegM, pegM, pegM, pegM], 1.62, 1.45, -0.6));
  const tool = (x, y, len, colr) => {
    const handle = cyl(0.011, 0.013, 0.09, mat(colr, { roughness: 0.4 }), 12); handle.position.set(x, y, -0.575); g.add(handle);
    const shaft = cyl(0.003, 0.003, len, M.metal, 8); shaft.position.set(x, y - 0.045 - len / 2, -0.575); g.add(shaft);
  };
  tool(1.3, 1.6, 0.1, 0xc02020); tool(1.36, 1.6, 0.13, 0xe0b020); tool(1.42, 1.6, 0.08, 0x2050c0);
  const pl = new THREE.Group(); pl.position.set(1.62, 1.55, -0.575);
  pl.add(box(0.012, 0.11, 0.008, mat(0xc02020), -0.012, -0.03, 0), box(0.012, 0.11, 0.008, mat(0xc02020), 0.012, -0.03, 0), box(0.02, 0.05, 0.01, M.metal, 0, 0.045, 0));
  pl.children[0].rotation.z = 0.15; pl.children[1].rotation.z = -0.15; g.add(pl);
  const coil = new THREE.Mesh(new THREE.TorusGeometry(0.06, 0.008, 8, 24), M.black); coil.position.set(1.85, 1.5, -0.575); g.add(coil);
  // lámpara de banco
  g.add(box(0.5, 0.03, 0.08, M.white, 1.62, 1.9, -0.5));
  const benchLight = new THREE.SpotLight(0xf0f4ff, 6, 2.5, 0.9, 0.5, 1.2);
  benchLight.position.set(1.62, 1.88, -0.45);
  benchLight.target.position.set(1.6, BENCH_Y, -0.2);
  benchLight.castShadow = true;
  benchLight.shadow.mapSize.set(1024, 1024);
  benchLight.shadow.bias = -0.0005;
  g.add(benchLight, benchLight.target);
  // cajón de repuestos y basurero
  const crate = mat(0x2a5aa0, { roughness: 0.5 });
  const C = CRATE_POS;
  g.add(box(0.22, 0.006, 0.16, crate, C.x, C.y + 0.003, C.z));
  g.add(box(0.006, 0.045, 0.16, crate, C.x - 0.11, C.y + 0.0225, C.z), box(0.006, 0.045, 0.16, crate, C.x + 0.11, C.y + 0.0225, C.z));
  g.add(box(0.22, 0.045, 0.006, crate, C.x, C.y + 0.0225, C.z - 0.08), box(0.22, 0.035, 0.006, crate, C.x, C.y + 0.0175, C.z + 0.08));
  const bin = new THREE.Mesh(new THREE.CylinderGeometry(0.13, 0.11, 0.32, 24, 1, true), new THREE.MeshStandardMaterial({ color: 0x5a5a5a, metalness: 0.5, roughness: 0.5, side: THREE.DoubleSide }));
  bin.position.set(BIN_POS.x, 0.16, BIN_POS.z); bin.castShadow = true; g.add(bin);
  const binBottom = cyl(0.11, 0.11, 0.01, mat(0x444444)); binBottom.position.set(BIN_POS.x, 0.005, BIN_POS.z); g.add(binBottom);
  scene.add(g);
}

function buildMonitor(scene) {
  const g = new THREE.Group();
  g.position.set(-0.2, DESK_Y, -0.12);
  g.add(cyl(0.12, 0.14, 0.02, M.beige).translateY(0.01));
  g.add(box(0.12, 0.03, 0.12, M.beige, 0, 0.035, -0.02));
  const cy = 0.26;
  const bw = 0.43, bh = 0.37, fz = 0.13;
  const side = SCREEN_H + 0.006;
  g.add(rbox(bw, (bh - side) / 2 + 0.01, 0.04, 0.01, M.beige, 0, cy + side / 2 + (bh - side) / 4 - 0.005, fz));
  g.add(rbox(bw, (bh - side) / 2 + 0.01, 0.04, 0.01, M.beige, 0, cy - side / 2 - (bh - side) / 4 + 0.005, fz));
  g.add(rbox((bw - SCREEN_W - 0.006) / 2 + 0.01, side + 0.01, 0.04, 0.008, M.beige, SCREEN_W / 2 + (bw - SCREEN_W) / 4 + 0.001, cy, fz));
  g.add(rbox((bw - SCREEN_W - 0.006) / 2 + 0.01, side + 0.01, 0.04, 0.008, M.beige, -SCREEN_W / 2 - (bw - SCREEN_W) / 4 - 0.001, cy, fz));
  g.add(box(SCREEN_W + 0.01, SCREEN_H + 0.01, 0.01, M.black, 0, cy, fz - 0.02));
  g.add(rbox(0.42, 0.36, 0.08, 0.025, M.beige, 0, cy, fz - 0.055));
  // tubo trasero ahusado (pirámide truncada de 4 lados)
  const rear = new THREE.Mesh(new THREE.CylinderGeometry(0.15, 0.27, 0.24, 4, 1), M.beige);
  rear.rotation.x = -Math.PI / 2; rear.rotation.y = Math.PI / 4; rear.scale.set(1, 1, 0.85);
  rear.position.set(0, cy + 0.005, fz - 0.21); rear.castShadow = rear.receiveShadow = true;
  g.add(rear);
  const vents = tex(256, 128, (x, w, h) => { x.drawImage(plasticCanvas, 0, 0, w, h); x.fillStyle = '#8a836e'; for (let i = 0; i < 14; i++) x.fillRect(20 + i * 16, 20, 7, 88); });
  const vm = new THREE.Mesh(new THREE.PlaneGeometry(0.2, 0.1), new THREE.MeshStandardMaterial({ map: vents, roughness: 0.7 }));
  vm.rotation.x = -Math.PI / 2 + 0.25; vm.position.set(0, cy + 0.16, fz - 0.2); g.add(vm);
  g.add(rbox(0.02, 0.012, 0.006, 0.002, M.beigeDark, 0.17, cy - 0.165, fz + 0.021));
  g.add(box(0.006, 0.004, 0.003, new THREE.MeshStandardMaterial({ color: 0x103010, emissive: 0x30ff40, emissiveIntensity: 1.5 }), 0.14, cy - 0.165, fz + 0.021));
  const brand = label('GVS  SyncView 14"', 0.12, 0.012, { bg: '#d9d0b8', fg: '#555', font: 'bold 44px Arial' });
  brand.position.set(0, cy - 0.165, fz + 0.0205); g.add(brand);
  scene.add(g);
  // Hueco transparente donde va la pantalla: la capa HTML está detrás del 3D, así
  // que todo lo que quede delante del monitor (la torre, la cámara girada) la tapa.
  const hole = new THREE.Mesh(new THREE.PlaneGeometry(SCREEN_W, SCREEN_H),
    new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0, blending: THREE.NoBlending, toneMapped: false }));
  hole.position.set(0, cy, fz - 0.011);
  g.add(hole);
  const screenPos = g.localToWorld(new THREE.Vector3(0, cy, fz - 0.012));
  const glow = new THREE.PointLight(0x9ab8ff, 0.6, 1.2, 1.5);
  glow.position.copy(screenPos).add(new THREE.Vector3(0, 0, 0.08));
  scene.add(glow);
  return { group: g, screenPos, glow };
}

/** Reflejos del ambiente más suaves en todo lo que no los pidió. */
function softenEnv(root) {
  root.traverse((o) => {
    for (const m of [].concat(o.material || [])) if (m.isMeshStandardMaterial && m.envMapIntensity === 1 && m.metalness < 0.4) m.envMapIntensity = 0.35; // los metales necesitan reflejos
  });
}

/** Pieza suelta lista para mostrar en una caja: centrada y escalada. */
function looseItem(stat, lvl, hw, maxSize = 0.075) {
  const raw = buildPart(stat, lvl, hw);
  const bb = new THREE.Box3().setFromObject(raw);
  const c = bb.getCenter(new THREE.Vector3()), size = bb.getSize(new THREE.Vector3());
  raw.position.sub(c);
  const pivot = new THREE.Group();
  pivot.add(raw);
  pivot.userData = { stat, lvl, scale: Math.min(1, maxSize / Math.max(size.x, size.y, size.z)) };
  pivot.scale.setScalar(pivot.userData.scale);
  return pivot;
}

// ------------------------------------------------------------- caja de envíos
class ParcelBox {
  constructor(game, scene) {
    this.game = game;
    this.group = new THREE.Group();
    this.group.position.copy(BOX_POS);
    const card = mat(0xb08850, { map: tex(128, 128, (x, w, h) => { x.fillStyle = '#b08850'; x.fillRect(0, 0, w, h); x.fillStyle = 'rgba(80,50,20,.15)'; for (let i = 0; i < w; i += 4) x.fillRect(i, 0, 2, h); noise(x, w, h, 1500, 0.06); }), roughness: 0.95 });
    const W = 0.18, H = 0.07, D = 0.14;
    this.group.add(box(W, 0.004, D, card, 0, 0.002, 0));
    this.group.add(box(0.004, H, D, card, -W / 2, H / 2, 0), box(0.004, H, D, card, W / 2, H / 2, 0));
    this.group.add(box(W, H, 0.004, card, 0, H / 2, -D / 2), box(W, H, 0.004, card, 0, H / 2, D / 2));
    const flap = box(W, 0.003, D / 2, card, 0, H + 0.03, D / 2 + 0.03); flap.rotation.x = 0.9; this.group.add(flap);
    const tape = label('PC SHOP', 0.1, 0.025, { bg: '#d8c060', fg: '#5a3a10', font: 'bold 80px Arial' });
    tape.position.set(0, H / 2, D / 2 + 0.003); this.group.add(tape);
    scene.add(this.group);
    this.items = new Map();
    this.flying = 0;
    this.sync();
  }
  sync() {
    const g = this.game;
    const boxed = Object.keys(g.boxed).filter((s) => g.boxed[s]);
    for (const [s, item] of this.items) if (!boxed.includes(s)) { this.group.remove(item); this.items.delete(s); }
    boxed.forEach((s) => {
      if (this.items.has(s)) return;
      const it = looseItem(s, g.boxedLevel(s), g.hw);
      it.userData.kind = 'parcel';
      this.group.add(it);
      this.items.set(s, it);
    });
    this.group.visible = boxed.length > 0 || this.flying > 0;
    [...this.items.values()].forEach((it, i) => {
      const row = Math.floor(i / 3), col = i % 3;
      it.position.set(-0.055 + col * 0.055, 0.075 + row * 0.05, -0.025 + row * 0.03);
      it.rotation.set(-0.5, 0.6, 0);
    });
  }
}

// -------------------------------------------------------- cajón de repuestos
class SpareCrate {
  constructor(game, scene) {
    this.game = game;
    this.group = new THREE.Group();
    this.group.position.copy(CRATE_POS);
    scene.add(this.group);
    this.items = [];
    this.sync();
  }
  sync() {
    for (const it of this.items) this.group.remove(it);
    this.items = this.game.spares.slice(0, 12).map((sp, i) => {
      const it = looseItem(sp.stat, sp.lvl, this.game.hw, 0.075);
      it.userData.kind = 'spare';
      it.userData.spare = sp;
      it.position.set(-0.075 + (i % 4) * 0.05, 0.04 + Math.floor(i / 4) * 0.035, -0.04 + Math.floor(i / 4) * 0.035);
      it.rotation.set(-0.6, 0.4, 0);
      this.group.add(it);
      return it;
    });
  }
}

// ------------------------------------------------------------- arranque
export function initRoom(game, el, fit) {
  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(2, window.devicePixelRatio || 1));
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.0;
  renderer.domElement.id = 'room-gl';
  document.body.prepend(renderer.domElement);

  const css = new CSS3DRenderer();
  css.setSize(window.innerWidth, window.innerHeight);
  css.domElement.id = 'room-css';
  document.body.appendChild(css.domElement);

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x15120f);
  scene.fog = new THREE.Fog(0x15120f, 4, 9);
  const pmrem = new THREE.PMREMGenerator(renderer);
  scene.environment = pmrem.fromScene(new RoomEnvironment(renderer), 0.04).texture;
  scene.add(new THREE.HemisphereLight(0xc8d0e0, 0x3a2a1a, 0.25));

  const cssScene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(40, window.innerWidth / window.innerHeight, 0.02, 20);

  buildRoom(scene);
  buildBench(scene);
  const monitor = buildMonitor(scene);
  const tower = new Tower({
    hw: () => game.hw, missing: () => game.removed, loose: () => game.loose, pos: TOWER_POS,
    setLoose: (s, v) => { if (v) game.loose[s] = true; else delete game.loose[s]; },
  });
  scene.add(tower.group);
  const parcel = new ParcelBox(game, scene);
  const crate = new SpareCrate(game, scene);

  // torre del cliente en el banco, con el costado abierto hacia la cámara
  const benchView = { pos: new THREE.Vector3(1.28, 1.42, 0.78), target: new THREE.Vector3(1.68, 0.98, -0.14) };
  const toCam = benchView.pos.clone().sub(BENCH_TOWER_POS).setY(0).normalize();
  let customer = null;
  function syncCustomer() {
    const job = game.apps.taller?.job;
    if (customer && (!job || customer.job !== job)) { scene.remove(customer.group); customer = null; }
    if (!job) return;
    if (!customer) {
      job.loose ||= {};
      customer = new Tower({ hw: () => job.hw, broken: () => job.broken, missing: () => job.missing, loose: () => job.loose,
        setLoose: (s, v) => { if (v) job.loose[s] = true; else delete job.loose[s]; }, color: job.color, dusty: true, panel: false, pos: BENCH_TOWER_POS, rotY: Math.atan2(-toCam.z, toCam.x) });
      customer.job = job;
      scene.add(customer.group);
    } else customer.rebuildAll();
    softenEnv(customer.group);
  }
  syncCustomer();

  softenEnv(scene);

  // la pantalla HTML dentro del monitor
  const screenObj = new CSS3DObject(el.screen);
  screenObj.position.copy(monitor.screenPos);
  screenObj.scale.setScalar(SCREEN_W / PX_W);
  cssScene.add(screenObj);

  // --------------------------------------------------------- cámara
  const controls = new OrbitControls(camera, renderer.domElement);
  controls.enabled = false;
  controls.enablePan = false;
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;
  controls.rotateSpeed = 0.6;
  let lastScale = 0;
  const views = {
    room: { pos: new THREE.Vector3(0.55, 1.45, 1.95), target: new THREE.Vector3(0.45, 0.98, -0.15), dist: [0.9, 2.6], az: 0.9 },
    case: { pos: new THREE.Vector3(1.05, 1.18, 0.5), target: new THREE.Vector3(0.5, 0.93, 0.0), dist: [0.35, 1.2], az: 1.1 },
    bench: { ...benchView, dist: [0.3, 1.1], az: 1.1 },
  };
  function pcView() {
    const t = Math.tan(THREE.MathUtils.degToRad(camera.fov / 2)) * 2;
    const d = Math.max(SCREEN_H / t, SCREEN_W / (t * camera.aspect));
    return { pos: monitor.screenPos.clone().add(new THREE.Vector3(0, 0, d)), target: monitor.screenPos.clone() };
  }
  const cam = { pos: new THREE.Vector3(), target: new THREE.Vector3(), from: null, to: null, t: 1 };
  let view = 'pc';
  const viewOf = (v) => (v === 'pc' ? pcView() : views[v]);

  let flat = false;
  let css3dTransform = '';
  const crtEl = document.getElementById('crt');
  function setFlat(on) {
    if (on === flat) return;
    flat = on;
    game.flat = on;
    document.body.classList.toggle('flat', on);
    // CSS3DRenderer no vuelve a escribir una transformación que ya tiene en caché:
    // se guarda la suya al entrar y se restaura al salir
    if (on) { css3dTransform = el.screen.style.transform; document.body.insertBefore(el.screen, crtEl); fit(); }
    else { el.screen.style.transform = css3dTransform; lastScale = 0; }
  }
  function limitControls(v) {
    const cfg = views[v];
    controls.target.copy(cfg.target);
    controls.minDistance = cfg.dist[0];
    controls.maxDistance = cfg.dist[1];
    const base = Math.atan2(cfg.pos.x - cfg.target.x, cfg.pos.z - cfg.target.z);
    controls.minAzimuthAngle = base - cfg.az;
    controls.maxAzimuthAngle = base + cfg.az;
    controls.minPolarAngle = 0.35;
    controls.maxPolarAngle = 1.5;
  }
  function go(v, instant = false) {
    if (v === 'bench' && !game.flag('taller')) return;
    view = v;
    controls.enabled = false;
    if (v !== 'pc') setFlat(false);
    const to = viewOf(v);
    if (instant) { cam.pos.copy(to.pos); cam.target.copy(to.target); cam.t = 1; }
    else { cam.from = { pos: cam.pos.clone(), target: cam.target.clone() }; cam.to = to; cam.t = 0; }
    hud.querySelectorAll('button').forEach((b) => b.classList.toggle('on', b.dataset.view === v));
    tweens.push({ t: 0, dur: 0.7, from: tower.open, to: v === 'case' ? 1 : 0, step(e) { tower.setOpen(this.from + (this.to - this.from) * e); } });
  }

  // ------------------------------------------------------------ HUD
  const icons = {
    pc: '<svg width="22" height="22" viewBox="0 0 22 22"><rect x="2" y="2" width="18" height="13" fill="#d9d0b8" stroke="#000"/><rect x="4" y="4" width="14" height="9" fill="#008080"/><rect x="7" y="16" width="8" height="2" fill="#808080"/><rect x="5" y="18" width="12" height="2" fill="#d9d0b8" stroke="#000" stroke-width=".5"/></svg>',
    room: '<svg width="22" height="22" viewBox="0 0 22 22"><path d="M2 8h18v2H2z" fill="#a07850" stroke="#000" stroke-width=".6"/><path d="M3 10v9M19 10v9" stroke="#5a4632" stroke-width="2"/><rect x="5" y="2" width="7" height="6" fill="#d9d0b8" stroke="#000" stroke-width=".6"/><rect x="14" y="1" width="4" height="7" fill="#d9d0b8" stroke="#000" stroke-width=".6"/></svg>',
    case: '<svg width="22" height="22" viewBox="0 0 22 22"><rect x="5" y="2" width="12" height="18" fill="#d9d0b8" stroke="#000"/><rect x="7" y="4" width="8" height="2" fill="#555"/><rect x="7" y="8" width="8" height="1" fill="#555"/><path d="M15 15l5 5" stroke="#c00" stroke-width="2.4"/><path d="M13 13l3 3" stroke="#333" stroke-width="1.6"/></svg>',
    bench: '<svg width="22" height="22" viewBox="0 0 22 22"><path d="M1 12h20v2H1z" fill="#6a5038" stroke="#000" stroke-width=".6"/><path d="M3 14v6M19 14v6" stroke="#555" stroke-width="2"/><rect x="5" y="3" width="6" height="9" fill="#cfc8b4" stroke="#000" stroke-width=".6"/><rect x="13" y="8" width="6" height="4" fill="#2a5aa0" stroke="#000" stroke-width=".6"/></svg>',
  };
  const hud = document.createElement('div');
  hud.className = 'room-hud';
  hud.innerHTML = ['pc', 'room', 'case', 'bench'].map((v) => `<button data-view="${v}" title="${{ pc: 'Usar el PC', room: 'Mirar', case: 'Abrir el PC', bench: 'Taller' }[v]}">${icons[v]}</button>`).join('');
  document.body.appendChild(hud);
  const badge = document.createElement('span');
  badge.className = 'badge';
  hud.querySelector('[data-view=case]').appendChild(badge);
  hud.addEventListener('click', (e) => { const b = e.target.closest('button'); if (b) go(b.dataset.view); });
  const syncHud = () => {
    const n = Object.values(game.boxed).filter(Boolean).length;
    badge.textContent = n; badge.style.display = n ? '' : 'none';
    hud.querySelector('[data-view=bench]').style.display = game.flag('taller') ? '' : 'none';
  };

  // ------------------------------------------------------- interacción
  const tweens = [];
  const ray = new THREE.Raycaster();
  const ptr = new THREE.Vector2();
  function pick(e) {
    ptr.set((e.clientX / window.innerWidth) * 2 - 1, -(e.clientY / window.innerHeight) * 2 + 1);
    ray.setFromCamera(ptr, camera);
    const targets = [tower.group, monitor.group, ...parcel.items.values(), ...crate.items];
    if (customer) targets.push(customer.group);
    // los cables (tubos) cruzan por delante de todo: no interceptan clics
    const hits = ray.intersectObjects(targets, true).filter((h) => h.object.geometry?.type !== 'TubeGeometry');
    if (!hits.length) return null;
    // los tornillos quedan dentro del área de clic de su pieza: tienen prioridad si están casi igual de cerca
    const fastenerOf = (o) => { for (let p = o; p; p = p.parent) if (p.userData.kind === 'fastener') return p; return null; };
    let hit = hits.find((h) => { const f = fastenerOf(h.object); return f && f.userData.t < 0.5 && h.distance <= hits[0].distance + 0.04; });
    if (!hit) {
      // Las áreas de clic se superponen (la de la placa madre cubre al CPU). Entre las que
      // quedan delante de lo primero que el clic toca de verdad, gana la pieza más chica.
      const partOf = (o) => { for (let p = o; p; p = p.parent) if (p.userData.stat && p.userData.hitbox) return p; return null; };
      const vol = (part) => { const q = part.userData.hitbox.geometry.parameters; return q.width * q.height * q.depth; };
      // Lo primero que el clic toca de verdad decide; las áreas de clic que quedan delante
      // solo ganan si son de una pieza que va encima de esa (el disipador sobre el CPU, la
      // RAM sobre la placa). Si no toca ninguna pieza, gana el área más chica.
      const firstReal = hits.findIndex((h) => !h.object.userData.hitbox && !fastenerOf(h.object));
      const real = firstReal < 0 ? null : partOf(hits[firstReal].object);
      const before = hits.slice(0, firstReal < 0 ? hits.length : firstReal).filter((h) => !fastenerOf(h.object) && partOf(h.object));
      if (real) {
        const over = before.find((h) => (NEEDS_OUT[real.userData.stat] || []).includes(partOf(h.object).userData.stat));
        hit = over || hits[firstReal];
      } else {
        hit = before.reduce((b, h) => (!b || vol(partOf(h.object)) < vol(partOf(b.object)) ? h : b), null) || hits[0];
      }
    }
    const towerOf = (o) => { for (let p = o; p; p = p.parent) { if (p === tower.group) return tower; if (customer && p === customer.group) return customer; } return null; };
    for (let o = hit.object; o; o = o.parent) {
      if (o.userData.kind === 'fastener') return { type: 'fastener', obj: o, tower: towerOf(o) };
      if (o.userData.kind === 'power') return { type: 'power' };
      if (o.parent === tower.group && o.userData.stat) return { type: 'ownpart', obj: o };
      if (o.userData.kind === 'parcel') return { type: 'parcel', obj: o };
      if (o.userData.kind === 'spare') return { type: 'spare', obj: o };
      if (customer && o.parent === customer.group && o.userData.stat) return { type: 'part', obj: o };
      if (customer && o === customer.group) return { type: 'customer' };
      if (o === tower.group) return { type: 'tower' };
      if (o === monitor.group) return { type: 'monitor' };
    }
    return null;
  }
  let hovered = null;
  const canvas = renderer.domElement;
  // Resaltado: la pieza bajo el mouse se tiñe (verde = sale, naranjo = no todavía)
  // y brilla en amarillo lo que todavía la sujeta, o la pieza que está encima.
  let lit = [];
  function clearLit() {
    for (const o of lit) { if (o.userData.hitbox) o.visible = false; else glowFastener(o, false); }
    lit = [];
  }
  function showPart(t, stat) {
    const part = t.parts[stat];
    const over = t.blockersOut(stat);
    const ok = !over.length && t.free(stat) && (t !== tower || pcOff());
    const hb = part?.userData.hitbox;
    if (hb) { hb.material.color.setHex(ok ? 0x40ff60 : 0xff9020); hb.visible = true; lit.push(hb); }
    if (over.length) {
      for (const s of over) { const b = t.parts[s]?.userData.hitbox; if (b) { b.material.color.setHex(0xff3020); b.visible = true; lit.push(b); } }
    } else {
      for (const f of t.fasteners(stat)) if (t.fast[stat][f.userData.i]) { glowFastener(f, true); lit.push(f); }
    }
    return ok;
  }
  canvas.addEventListener('pointermove', (e) => {
    const p = pick(e);
    const target = p?.type === 'parcel' || p?.type === 'spare' ? p.obj : null;
    if (hovered !== target) {
      if (hovered) hovered.scale.setScalar(hovered.userData.scale);
      hovered = target;
      if (hovered) hovered.scale.setScalar(hovered.userData.scale * 1.15);
    }
    clearLit();
    let cursor = p ? 'pointer' : controls.enabled ? 'grab' : 'default';
    const inside = (p?.type === 'ownpart' && view === 'case') || (p?.type === 'part' && view === 'bench');
    if (inside) {
      const t = p.type === 'part' ? customer : tower;
      cursor = showPart(t, p.obj.userData.stat) ? 'grab' : 'not-allowed';
    } else if (p?.type === 'fastener' && ((p.tower === tower && view === 'case') || (p.tower === customer && view === 'bench'))) {
      glowFastener(p.obj, true); lit.push(p.obj);
      if (p.tower.blockersOut(p.obj.userData.stat).length || (p.tower === tower && !pcOff())) cursor = 'not-allowed';
    } else if (p?.type === 'tower' && view === 'case') cursor = controls.enabled ? 'grab' : 'default';
    else if (p?.type === 'customer') cursor = 'default';
    canvas.style.cursor = cursor;
  });
  canvas.addEventListener('pointerleave', clearLit);
  let downAt = null;
  canvas.addEventListener('pointerdown', (e) => { downAt = [e.clientX, e.clientY]; });
  canvas.addEventListener('pointerup', (e) => {
    if (!downAt || Math.hypot(e.clientX - downAt[0], e.clientY - downAt[1]) > 5) return; // fue un arrastre de cámara
    downAt = null;
    const p = pick(e);
    if (!p) return;
    if (p.type === 'power') game.shell?.pressPower();
    else if (p.type === 'monitor' && view !== 'pc') go('pc');
    else if ((p.type === 'tower' || p.type === 'ownpart' || (p.type === 'fastener' && p.tower === tower)) && view !== 'case') go('case');
    else if (p.type === 'fastener') clickFastener(p.tower, p.obj);
    else if (p.type === 'ownpart') removeOwnPart(p.obj);
    else if (p.type === 'parcel') { if (view !== 'case') go('case'); else installOwn(p.obj); }
    else if ((p.type === 'spare' || p.type === 'part' || p.type === 'customer') && view !== 'bench') go('bench');
    else if (p.type === 'part') removeCustomerPart(p.obj);
    else if (p.type === 'spare') installSpare(p.obj);
  });
  // al tocar la pantalla desde lejos, la cámara se acerca
  el.screen.addEventListener('pointerdown', () => { if (view !== 'pc') go('pc'); }, true);

  /** Lleva un objeto en arco hasta un punto del mundo y llama a done al llegar. */
  function fly(item, to, done, { endScale = 1, dur = 0.9 } = {}) {
    item.userData.flying = true;
    scene.attach(item);
    const from = item.position.clone(), q0 = item.quaternion.clone(), s0 = item.scale.x;
    const q1 = new THREE.Quaternion();
    tweens.push({
      t: 0, dur,
      step(e) {
        item.position.lerpVectors(from, to, e);
        item.position.y += Math.sin(e * Math.PI) * 0.12;
        item.quaternion.slerpQuaternions(q0, q1, e);
        item.scale.setScalar(s0 + (endScale - s0) * e);
      },
      done() { scene.remove(item); done(); },
    });
  }
  function shake(obj) {
    const p0 = obj.position.clone();
    tweens.push({ t: 0, dur: 0.35, step(e) { obj.position.copy(p0); obj.position.x += Math.sin(e * Math.PI * 6) * 0.004 * (1 - e); }, done() { obj.position.copy(p0); } });
  }

  // ---- reglas del desarme
  const pcOff = () => game.state === 'off';
  function mayTouch(t) {
    if (t === tower && !pcOff()) { toast('Apague el PC primero.'); return false; }
    return true;
  }
  function clickFastener(t, f) {
    if (!t || !mayTouch(t)) return;
    const { stat, i } = f.userData;
    const over = t.blockersOut(stat);
    if (over.length) { shake(t.parts[over[0]]); t.hint(over[0]); return; } // hay algo encima
    t.toggle(stat, i);
  }
  /** ¿Se puede sacar la pieza? Si no, tiembla y parpadea lo que falta soltar. */
  function canPull(t, part) {
    const stat = part.userData.stat;
    const over = t.blockersOut(stat);
    if (over.length) { shake(part); t.hint(over[0]); clearLit(); showPart(t, stat); return false; }
    if (!t.free(stat)) { shake(part); t.hint(stat); clearLit(); showPart(t, stat); return false; }
    return true;
  }
  function removeOwnPart(part) {
    if (!mayTouch(tower) || !canPull(tower, part)) return;
    const stat = part.userData.stat;
    const lvl = game.hw[stat] || 0;
    const loose = looseItem(stat, lvl, game.hw, 0.08);
    loose.position.copy(tower.anchorWorld(stat));
    scene.add(loose);
    game.removed[stat] = true;
    delete game.loose[stat];
    tower.rebuild(stat);
    fly(loose, CRATE_POS.clone().add(new THREE.Vector3(0, 0.06, 0)), () => {
      game.spares.push({ stat, lvl });       // va al cajón de repuestos
      game.emit('spares');
      play('circle1', { volume: 0.4 });
    }, { endScale: 0.6, dur: 1.2 });
  }
  function installOwn(item) {
    const stat = item.userData.stat;
    if (item.userData.flying || !mayTouch(tower)) return;
    if (tower.has(stat)) { shake(item); tower.hint(stat); return; }        // primero hay que sacar la vieja
    const under = tower.blockersIn(stat);
    if (under.length) { shake(item); return; }
    parcel.items.delete(stat);
    parcel.flying++;
    fly(item, tower.anchorWorld(stat), () => {
      parcel.flying--;
      game.install(stat);                     // queda suelta: hay que atornillarla
      play('circle1', { volume: 0.5 });
      parcel.sync();
      syncHud();
    });
  }
  function removeCustomerPart(part) {
    if (!canPull(customer, part)) return;
    const stat = part.userData.stat;
    const taller = game.apps.taller;
    const was = customer.job.hw[stat];
    const r = taller.removePart(stat);
    if (!r) { shake(part); return; }
    const loose = looseItem(stat, was, customer.job.hw, 0.08);
    if (r === 'trash') burn(loose);
    loose.position.copy(customer.anchorWorld(stat));
    scene.add(loose);
    fly(loose, r === 'trash' ? new THREE.Vector3(BIN_POS.x, 0.2, BIN_POS.z) : CRATE_POS.clone().add(new THREE.Vector3(0, 0.06, 0)), () => {
      play(r === 'trash' ? 'circle2' : 'circle1', { volume: 0.4 });
    }, { endScale: 0.6 });
  }
  function installSpare(item) {
    const sp = item.userData.spare;
    const job = game.apps.taller.job;
    if (job && customer && job.missing[sp.stat] && !customer.blockersIn(sp.stat).length) {
      fly(item, customer.anchorWorld(sp.stat), () => {
        game.apps.taller.installSpare(game.spares.indexOf(sp));
        play('circle1', { volume: 0.5 });
      });
    } else if (game.removed[sp.stat] && pcOff() && !tower.blockersIn(sp.stat).length) {
      fly(item, tower.anchorWorld(sp.stat), () => {
        game.spares.splice(game.spares.indexOf(sp), 1);
        game.installSpare(sp.stat, sp.lvl);
        game.emit('spares');
        play('circle1', { volume: 0.5 });
      }, { dur: 1.3 });
    } else shake(item);
  }

  game.on('upgrade', (stat) => tower.rebuild(stat));
  game.on('boxed', () => { parcel.sync(); syncHud(); play('ding', { volume: 0.3 }); });
  game.on('spares', () => crate.sync());
  game.on('repair', () => { syncCustomer(); crate.sync(); });
  game.on('flag', (name) => { if (name === 'taller') syncHud(); });
  syncHud();
  game.room = { go };

  // --------------------------------------------------------- bucle
  function resize() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    css.setSize(window.innerWidth, window.innerHeight);
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    if (view === 'pc') go('pc', true);
    if (flat) fit();
  }
  window.addEventListener('resize', resize);
  go('pc', true);
  tower.setOpen(0);
  const work = new THREE.PointLight(0xfff0dd, 0, 1.2, 1.5); // luz para ver dentro de la torre
  work.position.set(0.8, 1.12, 0.05);
  scene.add(work);
  if (new URLSearchParams(location.search).has('debug')) window.room3d = { go, installOwn, parcel, crate, tower, camera, controls, get customer() { return customer; } };

  const clock = new THREE.Clock();
  const tmpA = new THREE.Vector3(), tmpB = new THREE.Vector3();
  function frame() {
    requestAnimationFrame(frame);
    const dt = Math.min(0.05, clock.getDelta());
    for (const tw of [...tweens]) {
      tw.t = Math.min(1, tw.t + dt / tw.dur);
      const e = tw.t < 0.5 ? 4 * tw.t ** 3 : 1 - (-2 * tw.t + 2) ** 3 / 2;
      tw.step(e);
      if (tw.t >= 1) { tweens.splice(tweens.indexOf(tw), 1); tw.done?.(); }
    }
    if (cam.t < 1) {
      cam.t = Math.min(1, cam.t + dt / 0.8);
      const e = 1 - (1 - cam.t) ** 3;
      cam.pos.lerpVectors(cam.from.pos, cam.to.pos, e);
      cam.target.lerpVectors(cam.from.target, cam.to.target, e);
      if (cam.t >= 1 && view !== 'pc') {           // al llegar, la cámara se puede girar
        camera.position.copy(cam.pos);
        limitControls(view);
        controls.enabled = true;
      }
    }
    if (view === 'pc' && cam.t >= 1) setFlat(true);
    if (flat) return; // la escena no se ve: no hace falta dibujarla
    if (controls.enabled) {
      controls.update();
      cam.pos.copy(camera.position);
      cam.target.copy(controls.target);
    } else {
      camera.position.copy(cam.pos);
      camera.lookAt(cam.target);
    }
    if (spinners.length > 150) { // descarta ventiladores de piezas que ya no están en la escena
      const alive = new Set(); scene.traverse((o) => { if (o.userData.rotor) alive.add(o); });
      spinners.splice(0, spinners.length, ...spinners.filter((r) => alive.has(r)));
    }
    tower.update(dt);
    customer?.update(dt);
    const on = game.state !== 'off';
    tower.powered = on;
    for (const s of spinners) if (!s.userData.stopped && s.userData.tower?.powered) s.rotation.x += dt * 25;
    tower.ledPower.material.emissiveIntensity = on ? 2 : 0;
    tower.ledDisk.material.emissiveIntensity = on && Math.random() < (game.apps.trabajo?.active.length ? 0.35 : 0.04) ? 2.5 : 0;
    monitor.glow.intensity = on ? 0.6 : 0.05;
    work.intensity = tower.open * 1.6;

    renderer.render(scene, camera);
    css.render(cssScene, camera);

    // escala efectiva de la pantalla (para arrastrar ventanas y los cursores)
    camera.updateMatrixWorld();
    tmpA.copy(monitor.screenPos).add(new THREE.Vector3(-SCREEN_W / 2, 0, 0)).project(camera);
    tmpB.copy(monitor.screenPos).add(new THREE.Vector3(SCREEN_W / 2, 0, 0)).project(camera);
    const s = Math.abs(tmpB.x - tmpA.x) / 2 * window.innerWidth / PX_W;
    game.scale = s;
    if (Math.abs(s - lastScale) / (lastScale || 1) > 0.05) { lastScale = s; applyCursors(el.screen, s); }
  }
  frame();
  return { go };
}
