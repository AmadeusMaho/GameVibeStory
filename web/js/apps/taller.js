// Taller (modo 3D): llegan PCs de clientes por correo. Las fallas de hardware
// se arreglan en el banco 3D (sacar la pieza quemada, poner un repuesto); los
// virus, desde aquí, revisando el disco. El cliente solo cuenta los síntomas.
import { App } from '../core/wm.js';
import { h, money, rand, randInt } from '../core/dom.js';
import { play } from '../core/audio.js';
import { msgBox, toast } from '../core/ui.js';
import { img } from '../core/assets.js';
import { HW } from '../data/hardware.js';
import { FAULTS, VIRUS_COMPLAINT, UPGRADES, REPAIR_CLIENTS, CLEAN_FILES, VIRUS_FILES } from '../data/repair.js';

const FAULT_STATS = Object.keys(FAULTS);
export const PART_NAMES = { psu: 'Fuente', cooling: 'Ventilador', ram: 'Memoria', display: 'Tarjeta de video', disk: 'Disco duro', cpu: 'Procesador', motherboard: 'Placa madre' };
export const partName = (stat, lvl) => (lvl === 0 ? HW[stat].tiers[0].from : HW[stat].tiers[Math.min(lvl, HW[stat].tiers.length) - 1].to);
export const partValue = (stat, lvl) => Math.round(HW[stat].basePrice * Math.pow(2.5, Math.max(0, lvl - 1)) * (lvl === 0 ? 0.2 : 0.45));
const shuffle = (a) => a.map((x) => [Math.random(), x]).sort((p, q) => p[0] - q[0]).map((p) => p[1]);
const USED = [['ram', 0], ['ram', 1], ['psu', 0], ['psu', 1], ['cooling', 0], ['cooling', 1], ['display', 0], ['display', 1], ['disk', 0], ['disk', 1]];

export class TallerApp extends App {
  constructor(game) {
    super(game);
    this.job = null;
    this.offerTimer = 20;
    this.tab = 0;
    this.marked = new Set();
  }
  get id() { return 'taller'; }
  get title() { return this.job ? `Taller - ${this.job.client}` : 'Taller'; }
  get icon() { return img('taller'); }
  get size() { return { w: 540, h: 450 }; }

  newJob() {
    const g = this.game;
    const hw = {};
    for (const s of Object.keys(HW)) hw[s] = randInt(0, s === 'motherboard' ? 1 : Math.min(2, HW[s].tiers.length));
    const first = !g.stats.repairs;
    const broken = shuffle(FAULT_STATS).slice(0, first ? 1 : randInt(1, 2));
    const viruses = !first && Math.random() < 0.5 ? shuffle(VIRUS_FILES).slice(0, randInt(2, 4)) : [];
    const ups = UPGRADES.filter(([s, min]) => min > hw[s] && !broken.includes(s));
    const up = !first && ups.length && Math.random() < 0.4 ? rand(ups) : null;
    const lines = [...broken.map((s) => FAULTS[s]), ...(viruses.length ? [VIRUS_COMPLAINT] : []), ...(up ? [up[2]] : [])];
    return {
      client: rand(REPAIR_CLIENTS), complaint: lines, hw, orig: { ...hw },
      broken: Object.fromEntries(broken.map((s) => [s, true])), missing: {},
      viruses: viruses.map((f) => f[0]), files: shuffle([...shuffle(CLEAN_FILES).slice(0, 8), ...viruses]),
      upgrade: up ? { stat: up[0], min: up[1] } : null, systemBroken: false,
      pay: 50 + 45 * broken.length + (viruses.length ? 40 : 0) + (up ? Math.round(partValue(up[0], up[1]) * 1.6) + 30 : 0),
      color: rand([0xd9d0b8, 0xcfc8b4, 0xd8d4c8, 0xc8bfa4]),
    };
  }

  offer() {
    const job = this.newJob();
    const from = job.client.toLowerCase().normalize('NFD').replace(/[^a-z]/g, '').slice(0, 10);
    this.game.apps.email.add({
      type: 'repair', job, from: `${from}@hotmail.com`, subject: '¿Me puede arreglar el PC?',
      body: `Hola,\n\n${job.complaint.join('\n')}\n\nLe pago ${money(job.pay)} si me lo deja funcionando. Se lo paso a dejar si me dice que sí.\n\n${job.client}`,
    });
  }

  accept(job) {
    if (this.job) return 'Ya tiene un equipo en el banco.';
    this.job = job;
    this.marked.clear();
    this.tab = 0;
    play('ding', { volume: 0.3 });
    this.game.emit('repair');
    return null;
  }

  // ---------------------------------------------------- desde el banco 3D
  /** Sacar una pieza. Devuelve 'trash' (estaba mala), 'spare' (la cambias por una mejor) o null (no hace falta). */
  removePart(stat) {
    const j = this.job;
    if (!j || j.missing[stat]) return null;
    if (j.broken[stat]) { delete j.broken[stat]; j.missing[stat] = true; this.game.emit('repair'); return 'trash'; }
    if (j.upgrade?.stat === stat && j.hw[stat] < j.upgrade.min) {
      j.missing[stat] = true;
      this.game.spares.push({ stat, lvl: j.hw[stat] }); // la vieja queda como repuesto
      this.game.emit('repair'); this.game.emit('spares');
      return 'spare';
    }
    return null;
  }
  installSpare(i) {
    const j = this.job;
    const sp = this.game.spares[i];
    if (!j || !sp || !j.missing[sp.stat]) return false;
    j.hw[sp.stat] = sp.lvl;
    delete j.missing[sp.stat];
    (j.loose ||= {})[sp.stat] = true; // queda suelta hasta atornillarla
    this.game.spares.splice(i, 1);
    this.game.emit('repair'); this.game.emit('spares');
    return true;
  }

  works() {
    const j = this.job;
    if (!j) return false;
    if (Object.keys(j.broken).length || Object.keys(j.missing).length || Object.keys(j.loose || {}).length || j.viruses.length) return false;
    if (Object.keys(j.orig).some((s) => j.hw[s] < j.orig[s])) return false;
    return !j.upgrade || j.hw[j.upgrade.stat] >= j.upgrade.min;
  }

  deliver() {
    const g = this.game;
    if (!this.works()) { msgBox({ title: 'Taller', icon: 'error', text: 'Todavía no funciona.' }); return; }
    const j = this.job;
    const pay = Math.round(j.pay * (j.systemBroken ? 0.5 : 1));
    g.earn(pay, 'repair');
    g.addRep(3);
    g.stats.repairs = (g.stats.repairs || 0) + 1;
    toast('Equipo entregado', `+${money(pay)} · +3 rep`);
    play('ding', { volume: 0.5 });
    this.job = null;
    this.offerTimer = randInt(150, 240);
    g.emit('repair');
  }

  deleteMarked() {
    const j = this.job;
    let broke = null;
    for (const name of this.marked) {
      const f = j.files.find((x) => x[0] === name);
      if (!f) continue;
      if (f[3] === 'system') { j.systemBroken = true; broke = name; }
      j.viruses = j.viruses.filter((v) => v !== name);
      j.files = j.files.filter((x) => x !== f);
    }
    this.marked.clear();
    if (broke) msgBox({ title: 'Error', icon: 'error', text: `No se encuentra ${broke}.\nEl sistema no puede iniciarse correctamente.` });
  }

  update(dt) {
    const g = this.game;
    if (!g.flag('taller') || this.job) return;
    if (g.apps.email.inbox.some((e) => e.type === 'repair' && !e.handled)) return;
    this.offerTimer -= dt;
    if (this.offerTimer <= 0) { this.offerTimer = randInt(240, 360); this.offer(); }
  }

  onAction(a, d) {
    const g = this.game;
    switch (a) {
      case 'tab': this.tab = Number(d.i); break;
      case 'mark': this.marked.has(d.f) ? this.marked.delete(d.f) : this.marked.add(d.f); break;
      case 'del': this.deleteMarked(); break;
      case 'deliver': this.deliver(); break;
      case 'bench': g.room?.go('bench'); break;
      case 'buy': {
        const [stat, lvl] = USED[Number(d.i)];
        if (!g.spend(partValue(stat, lvl))) break;
        g.spares.push({ stat, lvl });
        play('buy', { volume: 0.4 });
        g.emit('spares');
        break;
      }
      case 'sell': {
        const sp = g.spares[Number(d.i)];
        if (!sp) break;
        g.earn(Math.round(partValue(sp.stat, sp.lvl) * 0.6), 'sell');
        g.spares.splice(Number(d.i), 1);
        g.emit('spares');
        break;
      }
    }
  }

  render() {
    const g = this.game;
    const j = this.job;
    const tabs = ['Disco', 'Repuestos'];
    return h`<div class="col grow pad8 gap4">
      ${j ? h`<fieldset class="group"><legend>${j.client}</legend>
          ${j.complaint.map((l) => h`<div><i>"${l}"</i></div>`)}
        </fieldset>` : h`<div class="dim">Sin equipos en el taller.</div>`}
      <div class="tabs">${tabs.map((x, i) => h`<button class="tab ${this.tab === i ? 'active' : ''}" data-action="tab" data-i="${i}" data-silent>${x}</button>`)}</div>
      <div class="tab-panel grow col" style="min-height:0">
        ${this.tab === 0 ? this.renderDisk() : this.renderSpares()}
      </div>
      ${j ? h`<div class="flex gap8">
        <button class="btn" data-action="bench">Ver el banco</button><span class="grow"></span>
        <button class="btn default" data-action="deliver">Entregar (${money(j.pay * (j.systemBroken ? 0.5 : 1))})</button></div>` : ''}
    </div>`;
  }

  renderDisk() {
    const j = this.job;
    if (!j) return h`<div class="dim">-</div>`;
    return h`<div class="list grow" style="padding:0">
        <table class="grid">
          <tr><th></th><th>Nombre</th><th>Tamaño</th><th>Fecha</th></tr>
          ${j.files.map(([name, size, date]) => h`<tr class="clickable ${this.marked.has(name) ? 'selected' : ''}" data-action="mark" data-f="${name}" data-silent>
            <td>${this.marked.has(name) ? '☒' : '☐'}</td><td>${name}</td><td class="right">${size}</td><td>${date}</td></tr>`)}
        </table>
      </div>
      <div class="flex mt4"><span class="grow dim">C:\\</span><button class="btn small" data-action="del" ${this.marked.size ? '' : 'disabled'}>Eliminar (${this.marked.size})</button></div>`;
  }

  renderSpares() {
    const g = this.game;
    return h`<div class="flex gap8 grow" style="min-height:0">
      <fieldset class="group grow" style="overflow:auto"><legend>Cajón (${g.spares.length})</legend>
        ${g.spares.length ? g.spares.map((sp, i) => h`<div class="flex gap4" style="align-items:center;margin-bottom:2px">
          <span class="grow nowrap">${partName(sp.stat, sp.lvl)}</span>
          <button class="btn small" data-action="sell" data-i="${i}">${money(partValue(sp.stat, sp.lvl) * 0.6)}</button></div>`) : h`<div class="dim">Vacío</div>`}
      </fieldset>
      <fieldset class="group grow" style="overflow:auto"><legend>Usados</legend>
        ${USED.map(([stat, lvl], i) => h`<div class="flex gap4" style="align-items:center;margin-bottom:2px">
          <span class="grow nowrap">${partName(stat, lvl)}</span>
          <button class="btn small" data-action="buy" data-i="${i}" ${g.money >= partValue(stat, lvl) ? '' : 'disabled'}>${money(partValue(stat, lvl))}</button></div>`)}
      </fieldset>
    </div>`;
  }

  save() { return { job: this.job, offerTimer: this.offerTimer }; }
  load(d) { this.job = d?.job || null; this.offerTimer = d?.offerTimer ?? this.offerTimer; }
}
