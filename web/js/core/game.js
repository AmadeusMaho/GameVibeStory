// Estado central del juego: dinero, estadísticas, hardware y eventos.
import { HW, HW_ORDER, PRICE_GROWTH, COMPONENTS } from '../data/hardware.js';
import { DIFFICULTY_ORDER, CONTRACT_TYPES, REP_LEVELS } from '../data/work.js';

export class Game {
  constructor() {
    this.money = 0;
    this.totalEarned = 0;
    this.stats = {
      tasksCompleted: 0, projectsCompleted: 0, projectsFailed: 0, upgradesPurchased: 0,
      employeesHired: 0, appsPublished: 0, linesTyped: 0, emailsDeleted: 0, malwareDeleted: 0,
      bsods: 0, playTime: 0,
    };
    this.rep = 0;             // reputación: desbloquea dificultades
    this.streak = 0;          // entregas seguidas sin fallar
    this.bestStreak = 0;
    this.hw = Object.fromEntries(HW_ORDER.map((k) => [k, 0]));
    this.spares = [];         // modo 3D: cajón de repuestos [{stat, lvl}]
    this.removed = {};        // modo 3D: piezas sacadas de tu PC (el hueco queda vacío)
    this.loose = {};          // modo 3D: piezas puestas pero sin atornillar
    this.boxed = {};          // modo 3D: piezas compradas que esperan en la caja
    this.mode3d = false;
    this.flags = {};          // banderas varias (apps compradas, páginas, etc.)
    this.unlockedIcons = [];  // íconos de escritorio desbloqueados, en orden
    this.pacing = [];         // registro de ritmo: [minuto, hito] (ver F3 con ?debug)
    this.listeners = {};
    this.scale = 1;
    this.screenW = 1024;
    this.screenH = 768;
    this.state = 'off';       // off | boot | splash | desktop | bsod
  }

  // ---------------- eventos ----------------
  on(evt, fn) { (this.listeners[evt] ||= []).push(fn); }
  emit(evt, ...args) { (this.listeners[evt] || []).forEach((fn) => fn(...args)); }

  // ---------------- dinero ----------------
  earn(amount, source = 'other') {
    amount = Math.floor(amount);
    if (amount <= 0) return 0;
    this.money += amount;
    this.totalEarned += amount;
    this.emit('earn', amount, source);
    return amount;
  }
  spend(amount) {
    amount = Math.floor(amount);
    if (this.money < amount) return false;
    this.money -= amount;
    this.emit('spend', amount);
    return true;
  }
  lose(amount) {
    amount = Math.min(this.money, Math.floor(amount));
    this.money -= amount;
    return amount;
  }

  // ---------------- reputación y racha ----------------
  repLevel() {
    let lvl = 0;
    REP_LEVELS.forEach((r, i) => { if (this.rep >= r.need) lvl = i; });
    return lvl;
  }
  /** Suma (o resta) reputación. Nunca baja del nivel ya alcanzado. Devuelve true si subió de nivel. */
  addRep(n) {
    const before = this.repLevel();
    this.rep = Math.max(REP_LEVELS[before].need, this.rep + n);
    const after = this.repLevel();
    if (after > before) this.emit('repLevel', after);
    return after > before;
  }
  unlockedDifficulties() { return DIFFICULTY_ORDER.slice(0, this.repLevel() + 2); }
  streakMult(streak = this.streak) { return 1 + 0.1 * Math.min(streak, 10); }

  /** Anota un hito con el minuto de juego en que ocurrió (solo la primera vez). */
  milestone(name) {
    if (this.pacing.some(([, n]) => n === name)) return;
    this.pacing.push([+(this.stats.playTime / 60).toFixed(1), name]);
  }

  // ---------------- banderas / desbloqueos ----------------
  flag(name) { return !!this.flags[name]; }
  setFlag(name, v = true) { this.flags[name] = v; this.emit('flag', name, v); }
  unlockIcon(id) {
    if (this.unlockedIcons.includes(id)) return false;
    this.unlockedIcons.push(id);
    this.emit('icons', id);
    return true;
  }
  lockIcon(id) {
    this.unlockedIcons = this.unlockedIcons.filter((x) => x !== id);
    this.emit('icons');
  }
  hasIcon(id) { return this.unlockedIcons.includes(id); }

  // ---------------- hardware ----------------
  hwName(stat) {
    const def = HW[stat];
    const lvl = this.hw[stat] || 0;
    return lvl === 0 ? def.tiers[0].from : def.tiers[lvl - 1].to;
  }
  hwPrice(stat) {
    const def = HW[stat];
    const lvl = this.hw[stat] || 0;
    if (lvl >= def.tiers.length) return null;
    return Math.floor(def.basePrice * Math.pow(PRICE_GROWTH, lvl));
  }
  watts(stat, lvl = this.hw[stat] || 0) {
    const def = HW[stat];
    if (stat === 'psu') return 0;
    return lvl === 0 ? def.baseWatts : def.tiers[lvl - 1].watts;
  }
  totalWatts() { return HW_ORDER.reduce((s, k) => s + this.watts(k), 0); }
  psuCapacity() {
    const lvl = this.hw.psu || 0;
    return lvl === 0 ? HW.psu.baseCapacity : HW.psu.tiers[lvl - 1].capacity;
  }
  /** Devuelve null si se puede comprar, o un texto con el motivo si no. */
  canUpgrade(stat) {
    const price = this.hwPrice(stat);
    if (price == null) return 'Ya tienes el mejor modelo.';
    if (this.boxed[stat]) return 'Ya está en la caja.';
    if (stat !== 'psu') {
      const lvl = this.hw[stat];
      const newTotal = this.totalWatts() - this.watts(stat, lvl) + this.watts(stat, lvl + 1);
      if (newTotal > this.psuCapacity()) return `La fuente no alcanza (${newTotal}W de ${this.psuCapacity()}W).`;
    }
    if (this.money < price) return `Dinero insuficiente. Necesitas $${price.toLocaleString('es-CL')}.`;
    return null;
  }
  upgrade(stat) {
    const why = this.canUpgrade(stat);
    if (why) return why;
    this.spend(this.hwPrice(stat));
    if (this.mode3d) { this.boxed[stat] = (this.hw[stat] || 0) + 1; this.emit('boxed', stat); return null; }
    this.hw[stat]++;
    this.stats.upgradesPurchased++;
    this.emit('upgrade', stat, this.hw[stat]);
    return null;
  }

  /** Nivel de la pieza que espera en la caja (las partidas viejas guardaban true). */
  boxedLevel(stat) { const b = this.boxed[stat]; return b === true ? (this.hw[stat] || 0) + 1 : b || 0; }
  /** Instala la pieza de la caja. En 3D queda suelta hasta atornillarla. */
  install(stat) {
    if (!this.boxed[stat]) return;
    this.hw[stat] = this.boxedLevel(stat);
    delete this.boxed[stat];
    delete this.removed[stat];
    if (this.mode3d) this.loose[stat] = true;
    this.stats.upgradesPurchased++;
    this.emit('upgrade', stat, this.hw[stat]);
  }
  /** Pone en tu PC una pieza del cajón de repuestos (queda suelta). */
  installSpare(stat, lvl) {
    this.hw[stat] = lvl;
    delete this.removed[stat];
    this.loose[stat] = true;
    this.emit('upgrade', stat, lvl);
  }
  /** Por qué no arranca el PC (null si está todo puesto y atornillado). */
  bootFault() {
    const out = (s) => this.removed[s] || this.loose[s];
    if (out('psu')) return 'psu';
    if (out('motherboard') || out('cpu')) return 'dead';
    if (out('ram')) return 'ram';
    if (out('display')) return 'video';
    if (out('cooling')) return 'fan';
    if (out('disk')) return 'disk';
    return null;
  }

  // ---------------- efectos del hardware (fórmulas originales) ----------------
  taskTimeMult() {
    let m = 1.75;
    if (this.hw.cpu) m *= Math.pow(0.7, this.hw.cpu);
    if (this.hw.cooling) m *= 1 - Math.min(0.6, 0.1 + (this.hw.cooling - 1) * 0.2);
    return Math.max(0.5, m);
  }
  taskReward() {
    const base = [1, 2, 4, 8, 16, 24, 32][this.hw.display] || 1;
    let mult = 1;
    if (this.hw.cooling) mult *= 1 + (0.1 + (this.hw.cooling - 1) * 0.2);
    return Math.max(1, Math.floor(base * mult));
  }
  // Cada componente ya rinde según su nivel en sus propios círculos; estos
  // multiplicadores globales quedan suaves para que el progreso no se dispare.
  jobSlots() { return 1 + Math.floor(((this.hw.ram || 0) + 1) / 2); }
  circlePowerMult() { return 1 + 0.04 * (this.hw.display || 0); }
  circleSpeedMult() { return 1 - 0.03 * (this.hw.cpu || 0); }
  /** Cuenta mensual: arriendo + luz (sube con el consumo del PC). */
  get billEvery() { return 300; } // segundos entre cuentas
  bill() { return 40 + Math.round(this.totalWatts() * 0.25); }
  bugChance() { return Math.max(0, 0.08 - 0.02 * (this.hw.cooling || 0)); }
  mbBonus() {
    const l = this.hw.motherboard || 0;
    if (!l) return { interval: 0, power: 0 };
    const t = HW.motherboard.tiers[l - 1];
    return { interval: t.intervalReduction, power: t.powerBonus };
  }
  /** Componentes de un encargo: la potencia se ajusta al perfil de su tipo. */
  contractComponents(type) {
    const prof = CONTRACT_TYPES[type]?.profile || {};
    return this.projectComponents().map((c) => ({ ...c, affinity: prof[c.stat] ?? 1, power: c.power * (prof[c.stat] ?? 1) }));
  }
  /** Progreso por segundo que el PC aporta solo a un encargo de este tipo. */
  passiveRate(type) {
    const b = this.bugChance();
    const perCircle = (p) => p * (1 - b) - p * 0.6 * b;
    return this.contractComponents(type).reduce((s, c) =>
      s + (c.power > 0 ? perCircle(Math.max(1, c.power * this.circlePowerMult())) / (c.interval * this.circleSpeedMult()) : 0), 0);
  }
  /** Lista de componentes que generan círculos en un proyecto. */
  projectComponents(mult = 1) {
    const mb = this.mbBonus();
    return Object.entries(COMPONENTS).map(([stat, c]) => {
      const lvl = this.hw[stat] || 0;
      const [interval, power] = c.tiers[Math.min(lvl, c.tiers.length - 1)];
      return {
        stat, label: c.label, color: c.color, tier: lvl,
        name: this.hwName(stat),
        interval: interval * (1 - mb.interval),
        power: Math.floor(power * (1 + mb.power) * mult),
        timer: 0, shake: 0,
      };
    });
  }
}
