// Estado central del juego: dinero, estadísticas, hardware y eventos.
import { HW, HW_ORDER, PRICE_GROWTH, COMPONENTS } from '../data/hardware.js';

export class Game {
  constructor() {
    this.money = 0;
    this.totalEarned = 0;
    this.stats = {
      tasksCompleted: 0, projectsCompleted: 0, projectsFailed: 0, upgradesPurchased: 0,
      employeesHired: 0, appsPublished: 0, linesTyped: 0, emailsDeleted: 0, malwareDeleted: 0,
      bsods: 0, playTime: 0,
    };
    this.hw = Object.fromEntries(HW_ORDER.map((k) => [k, 0]));
    this.flags = {};          // banderas varias (apps compradas, páginas, etc.)
    this.unlockedIcons = [];  // íconos de escritorio desbloqueados, en orden
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
    this.hw[stat]++;
    this.stats.upgradesPurchased++;
    this.emit('upgrade', stat, this.hw[stat]);
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
    if (this.musicOn) mult *= 1.1;
    return Math.max(1, Math.floor(base * mult));
  }
  jobSlots() { return 1 + (this.hw.ram || 0); }
  circlePowerMult() { return (1 + 0.3 * (this.hw.display || 0)) * (1 + 0.25 * (this.hw.ram || 0)); }
  circleSpeedMult() { return this.hw.cpu ? Math.pow(0.85, this.hw.cpu) : 1; }
  bugChance() { return Math.max(0, 0.08 - 0.02 * (this.hw.cooling || 0)); }
  mbBonus() {
    const l = this.hw.motherboard || 0;
    if (!l) return { interval: 0, power: 0 };
    const t = HW.motherboard.tiers[l - 1];
    return { interval: t.intervalReduction, power: t.powerBonus };
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
