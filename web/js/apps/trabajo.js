// Trabajo: el bucle principal. Aceptas encargos (espacios = RAM), tus
// componentes lanzan círculos solos y tú los aceleras escribiendo. Entregar
// da dinero, reputación (desbloquea dificultades) y racha (multiplica el pago).
import { App } from '../core/wm.js';
import { h, money, fmt, rand, clamp } from '../core/dom.js';
import { play, playRandom } from '../core/audio.js';
import { msgBox, toast } from '../core/ui.js';
import { img } from '../core/assets.js';
import {
  PROJECTS, DIFFICULTIES, DIFFICULTY_ORDER, CONTRACT_TYPES, CLIENTS, REP_LEVELS, REP_GAIN, LINES, contractDays,
} from '../data/work.js';
import { TIER_NAMES, TIER_COLORS } from '../data/hardware.js';
import { SNIPPETS, highlight } from './coding.js';

const DAY_RATE = 0.1;           // días que pasan por segundo
const FOCUS_GAIN = 0.045;       // enfoque por tecla correcta
const FOCUS_DECAY = 0.12;       // enfoque que se pierde por segundo
const FOCUS_ERROR = 0.25;       // enfoque que se pierde al equivocarse
const FOCUS_BONUS = 2;          // enfoque al 100 % = círculos x3
const WINBATCH_FLOOR = 0.35;    // WinBatch mantiene un enfoque mínimo
const OFFER_TTL = 120;          // segundos que dura una oferta
const OFFER_EVERY = 15;         // cada cuánto llega una oferta nueva
const VIP_EVERY = [150, 240];   // rango de segundos entre correos VIP

const SOFTWARE_LINES = SNIPPETS.flat().map(([t]) => t).filter((t) => t.trim().length >= 6);
const between = ([a, b]) => a + Math.random() * (b - a);

let nextId = 1;

/** Crea un encargo a partir de una plantilla de PROJECTS. */
export function makeContract(tpl, { vip = false } = {}) {
  const v = 0.9 + Math.random() * 0.25;
  const days = Math.round(contractDays(tpl.difficulty) * (vip ? 0.75 : 1));
  return {
    id: nextId++, name: tpl.name, desc: tpl.desc, type: tpl.type, difficulty: tpl.difficulty, client: rand(CLIENTS),
    hp: 0, maxHp: Math.round(tpl.hp * v), reward: Math.round(tpl.reward * v * (vip ? 4 : 1)),
    rep: REP_GAIN[DIFFICULTY_ORDER.indexOf(tpl.difficulty)] * (vip ? 2 : 1),
    days, maxDays: days, vip, ttl: OFFER_TTL,
  };
}

export class TrabajoApp extends App {
  constructor(game) {
    super(game);
    this.active = [];        // encargos en curso
    this.board = [];         // ofertas disponibles
    this.sel = null;         // id del encargo en el que estás escribiendo
    this.offerTimer = 0;
    this.billTimer = 0;
    this.vipTimer = between(VIP_EVERY);
    this.refreshLeft = 3;
    this.refreshCooldown = 0;
    this.focus = 0;
    this.typing = null;      // { target, typed }
    this.lastLines = [];
    this.error = 0;
    this.combo = 0;
    this.floaters = [];
    this.shake = 0;
  }
  get id() { return 'trabajo'; }
  get title() { return 'Trabajo - Encargos'; }
  get icon() { return img('trabajo'); }
  get size() { return { w: 740, h: 560 }; }

  slots() { return this.game.jobSlots(); }
  selected() { return this.active.find((c) => c.id === this.sel) || null; }
  focusMult() { return 1 + FOCUS_BONUS * this.focus; }

  // ------------------------------------------------------------ ofertas
  boardSize() { return 3 + (this.game.hw.disk || 0); }

  addOffer() {
    const ok = this.game.unlockedDifficulties();
    const taken = new Set([...this.board, ...this.active].map((c) => c.name));
    let pool = PROJECTS.filter((p) => ok.includes(p.difficulty) && !taken.has(p.name));
    if (!pool.length) pool = PROJECTS.filter((p) => ok.includes(p.difficulty));
    // los primeros encargos son siempre muy fáciles: el PC solo casi alcanza y escribir lo asegura
    if (this.game.stats.tasksCompleted < 3) { this.board.push(makeContract(rand(PROJECTS.filter((p) => p.difficulty === 'muy_facil')))); return; }
    // 60 % de las veces, una de las dos dificultades más altas que tienes
    const top = pool.filter((p) => ok.slice(-2).includes(p.difficulty));
    this.board.push(makeContract(rand(top.length && Math.random() < 0.6 ? top : pool)));
  }
  fillBoard() { while (this.board.length < this.boardSize()) this.addOffer(); }
  refresh() {
    if (this.refreshLeft <= 0) return;
    this.board = [];
    this.fillBoard();
    if (--this.refreshLeft === 0) this.refreshCooldown = 30;
  }

  /** Devuelve null si se aceptó, o el motivo si no. */
  accept(c) {
    if (this.active.length >= this.slots()) return 'No tiene espacios libres.';
    c.id = nextId++; // los VIP vienen del correo guardado: id nuevo para no chocar
    c.components = this.game.contractComponents(c.type);
    c.circles = [];
    this.active.push(c);
    if (!this.selected()) this.select(c.id);
    play('ding', { volume: 0.25 });
    return null;
  }
  acceptOffer(id) {
    const i = this.board.findIndex((o) => o.id === id);
    if (i < 0) return;
    const why = this.accept(this.board[i]);
    if (why) { msgBox({ title: 'Trabajo', icon: 'warning', text: why }); return; }
    this.board.splice(i, 1);
    this.game.wm.open(this.id);
  }

  sendVip() {
    const ok = this.game.unlockedDifficulties();
    const tpl = rand(PROJECTS.filter((p) => p.difficulty === ok[ok.length - 1]));
    const c = makeContract(tpl, { vip: true });
    const from = c.client.toLowerCase().normalize('NFD').replace(/[^a-z]/g, '').slice(0, 12);
    this.game.apps.email.add({
      type: 'project', days: 3, project: c, from: `gerencia@${from}.cl`,
      subject: `URGENTE: ${c.name} (pago x4)`,
      body: `Hola,\n\nNecesitamos esto lo antes posible:\n${c.name} - ${c.desc}\n\nPagamos ${money(c.reward)}. Plazo: ${c.maxDays} días.\n\n${c.client}`,
    });
  }

  refreshComponents() {
    for (const c of this.active) {
      const timers = (c.components || []).map((x) => x.timer);
      c.components = this.game.contractComponents(c.type);
      c.components.forEach((x, i) => { x.timer = timers[i] || 0; });
    }
  }

  // ------------------------------------------------------------ escritura
  select(id) {
    this.sel = id;
    this.combo = 0;
    this.lastLines = [];
    this.newLine();
  }
  newLine() {
    const c = this.selected();
    if (!c) { this.typing = null; return; }
    const pool = c.type === 'software' ? SOFTWARE_LINES : LINES[c.type];
    let t = rand(pool);
    if (pool.length > 1) while (t === this.typing?.target) t = rand(pool);
    this.typing = { target: t, typed: t.match(/^\s*/)[0] }; // la sangría se escribe sola
  }
  linePower() {
    const c = this.selected();
    return Math.max(3, this.game.passiveRate(c.type) * 2.5) * (1 + this.combo * 0.1);
  }

  /** Teclado: lo llama main.js con la ventana activa. Devuelve true si consumió la tecla. */
  onKey(e) {
    const c = this.selected();
    if (!c || !this.typing || c.done || e.ctrlKey || e.altKey || e.metaKey) return false;
    if (e.key === 'Backspace') return true;
    if (e.key.length !== 1) return false;
    if (this.error > 0) return true;
    const t = this.typing;
    if (e.key === t.target[t.typed.length]) {
      t.typed += e.key;
      this.focus = Math.min(1, this.focus + FOCUS_GAIN);
      if (t.typed.length >= t.target.length) this.completeLine(c);
    } else {
      this.error = 0.25;
      this.combo = 0;
      this.focus = Math.max(0, this.focus - FOCUS_ERROR);
    }
    return true;
  }
  completeLine(c) {
    const dmg = Math.round(this.linePower());
    c.hp += dmg;
    this.combo++;
    this.game.stats.linesTyped++;
    this.floaters.push({ text: `+${dmg}${this.combo > 1 ? ' x' + this.combo : ''}`, t: 0, life: 1.2, at: clamp(c.hp / c.maxHp, 0, 1), kind: 'line' });
    this.shake = 0.15;
    this.lastLines = [...this.lastLines, this.typing.target].slice(-3);
    this.newLine();
  }

  // ------------------------------------------------------------ resultado
  finish(c) {
    if (c.type === 'software' && !c.vip && this.game.flag('app_coding')) {
      c.done = true; // espera que elijas: entregar o quedarte con los derechos
      play('ding', { volume: 0.5 });
      if (this.sel !== c.id) this.select(c.id);
      return;
    }
    this.deliver(c);
  }

  deliver(c, rights = false) {
    const g = this.game;
    const early = c.days / c.maxDays >= 0.5;
    const pay = rights ? 0 : Math.round(c.reward * g.streakMult());
    const rep = Math.ceil(c.rep * (early ? 1.5 : 1) * (rights ? 0.5 : 1));
    g.streak++;
    g.bestStreak = Math.max(g.bestStreak, g.streak);
    if (pay) g.earn(pay, 'project');
    const leveled = g.addRep(rep);
    g.stats.tasksCompleted++;
    if (DIFFICULTY_ORDER.indexOf(c.difficulty) >= 2) g.stats.projectsCompleted++;
    if (rights) {
      g.apps.coding.published.push({ name: c.name, rev: Math.round(c.reward * 0.15), months: 12, total: 0, selling: true, upd: 0,
        success: (6 + Math.floor(Math.random() * 4)) / 10, timer: 0 });
      g.stats.appsPublished++;
    }
    play('ding', { volume: 0.5 });
    toast(rights ? 'Programa publicado' : 'Encargo entregado', `${rights ? c.name : '+' + money(pay)} · +${rep} rep`);
    if (leveled) {
      const lvl = g.repLevel();
      const diff = DIFFICULTY_ORDER[lvl + 1];
      toast(`Reputación: ${REP_LEVELS[lvl].name}`, diff ? `Nuevos encargos: ${DIFFICULTIES[diff].label}` : '');
      play('chimes', { volume: 0.4 });
    }
    this.remove(c);
    g.emit('taskDone');
    g.emit('projectDone', c);
  }

  fail(c, reason = 'tiempo') {
    const g = this.game;
    const penalty = Math.floor(c.reward * 0.15);
    g.lose(penalty);
    g.addRep(-c.rep * 2);
    const lostStreak = g.streak;
    g.streak = 0;
    g.stats.projectsFailed++;
    g.apps.email?.add({
      subject: `Encargo fracasado - ${c.name}`, from: 'clientes@freelance.com', type: 'news',
      body: `No entregó "${c.name}" a tiempo.\n\nMulta: ${money(penalty)}\nReputación: -${c.rep * 2}${lostStreak ? `\nRacha perdida: ${lostStreak}` : ''}\n\n${c.client}`,
    });
    this.remove(c);
  }
  failSelected(reason) { const c = this.selected(); if (c) this.fail(c, reason); }

  remove(c) {
    this.active = this.active.filter((x) => x !== c);
    if (this.sel === c.id) this.select(this.active[0]?.id ?? null);
  }

  // ------------------------------------------------------------ bucle
  update(dt) {
    const g = this.game;
    if (!this.board.length) this.fillBoard();
    for (const o of this.board) o.ttl -= dt;
    this.board = this.board.filter((o) => o.ttl > 0);
    this.offerTimer += dt;
    if (this.offerTimer >= OFFER_EVERY) { this.offerTimer = 0; if (this.board.length < this.boardSize()) this.addOffer(); }
    if (this.refreshCooldown > 0) { this.refreshCooldown -= dt; if (this.refreshCooldown <= 0) this.refreshLeft = 3; }
    this.billTimer += dt;
    if (this.billTimer >= g.billEvery) {
      this.billTimer = 0;
      const paid = g.lose(g.bill());
      toast('Cuentas del mes', `Arriendo y luz: -${money(paid)}`);
    }
    if (g.repLevel() >= 1) {
      this.vipTimer -= dt;
      if (this.vipTimer <= 0) { this.vipTimer = between(VIP_EVERY); this.sendVip(); }
    }

    const floor = g.flag('winbatch') ? WINBATCH_FLOOR : 0;
    this.focus = Math.max(floor, this.focus - FOCUS_DECAY * dt);
    if (this.error > 0) this.error -= dt;
    this.shake = Math.max(0, this.shake - dt);
    for (const f of this.floaters) f.t += dt;
    this.floaters = this.floaters.filter((f) => f.t < f.life);

    const speed = 1 / g.circleSpeedMult();
    const visible = g.wm.isVisible(this.id);
    for (const c of [...this.active]) {
      if (c.done) continue;
      const focused = c.id === this.sel;
      const animate = focused && visible;
      for (const [i, comp] of c.components.entries()) {
        comp.shake = Math.max(0, comp.shake - dt);
        if (comp.power <= 0) continue;
        comp.timer += dt * speed;
        if (comp.timer < comp.interval) continue;
        comp.timer -= comp.interval;
        const bug = Math.random() < g.bugChance();
        const base = comp.power * g.circlePowerMult() * (focused ? this.focusMult() : 1);
        const power = Math.max(1, Math.floor(bug ? base * 0.6 : base));
        if (animate) {
          c.circles.push({ from: i, power, bug, t: 0, dur: 0.75 + Math.random() * 0.25, color: bug ? '#e02020' : comp.color });
          comp.shake = 0.2;
          playRandom(['circle1', 'circle2'], { volume: 0.2 });
        } else {
          c.hp = bug ? Math.max(0, c.hp - power) : c.hp + power;
        }
      }
      for (const ci of c.circles) {
        ci.t += dt;
        if (ci.t >= ci.dur && !ci.done) {
          ci.done = true;
          c.hp = ci.bug ? Math.max(0, c.hp - ci.power) : c.hp + ci.power;
          this.floaters.push({ text: (ci.bug ? '-' : '+') + ci.power, bug: ci.bug, t: 0, life: ci.bug ? 1.4 : 1, at: clamp(c.hp / c.maxHp, 0, 1) });
        }
      }
      c.circles = c.circles.filter((ci) => !ci.done);
      if (c.hp >= c.maxHp) { this.finish(c); continue; }
      c.days -= dt * DAY_RATE;
      if (c.days <= 0) this.fail(c);
    }
  }

  onAction(action, d) {
    const c = this.selected();
    switch (action) {
      case 'accept': this.acceptOffer(Number(d.id)); break;
      case 'select': this.select(Number(d.id)); break;
      case 'refresh': this.refresh(); break;
      case 'deliver': if (c?.done) this.deliver(c); break;
      case 'rights': if (c?.done) this.deliver(c, true); break;
      case 'abandon': if (c && !c.done) this.fail(c, 'abandono'); break;
    }
  }

  // ------------------------------------------------------------ vista
  render() {
    const g = this.game;
    const lvl = g.repLevel();
    const cur = REP_LEVELS[lvl], next = REP_LEVELS[lvl + 1];
    const repPct = next ? ((g.rep - cur.need) / (next.need - cur.need)) * 100 : 100;
    return h`<div class="col grow enc">
      <div class="flex gap8 enc-head">
        <span>Reputación: <b>${cur.name}</b></span>
        <div class="progress" style="width:110px;height:12px"><div class="fill" style="width:${repPct.toFixed(0)}%"></div></div>
        <span class="dim">${next ? `${fmt(g.rep)}/${next.need}` : fmt(g.rep)}</span>
        <span class="grow"></span>
        <span>Racha: <b class="${g.streak >= 5 ? 'warn' : g.streak ? 'ok' : 'dim'}">${g.streak}</b>${g.streak ? h` <span class="ok">+${Math.round((g.streakMult() - 1) * 100)}%</span>` : ''}</span>
        <span>Dinero: <b class="ok">${money(g.money)}</b></span>
      </div>
      <div class="flex grow gap8" style="min-height:0">
        <div class="col gap4" style="width:300px;min-height:0">
          ${this.renderSlots()}
          ${this.renderBoard()}
        </div>
        <div class="col grow enc-work" style="position:relative;min-width:0">${this.renderWork()}<canvas class="fx-canvas" data-keep></canvas></div>
      </div>
    </div>`;
  }

  renderSlots() {
    const n = this.slots();
    return h`<fieldset class="group" style="flex:none"><legend>En curso (${this.active.length}/${n})</legend>
      ${Array.from({ length: n }, (_, i) => {
        const c = this.active[i];
        if (!c) return h`<div class="enc-slot dim">Espacio ${i + 1}: [Libre]</div>`;
        const p = clamp(c.hp / c.maxHp, 0, 1);
        const late = c.days / c.maxDays < 0.25;
        return h`<div class="enc-slot clickable ${c.id === this.sel ? 'sel' : ''}" data-action="select" data-id="${c.id}" data-silent>
          <div class="flex"><span class="grow nowrap bold">${c.vip ? '★ ' : ''}${c.name}</span><span class="${late ? 'bad' : 'dim'}">${c.done ? '¡Listo!' : `${Math.ceil(c.days)} d`}</span></div>
          <div class="progress" style="height:9px"><div class="fill" style="width:${(p * 100).toFixed(1)}%"></div></div>
        </div>`;
      })}
    </fieldset>`;
  }

  renderBoard() {
    const g = this.game;
    const full = this.active.length >= this.slots();
    return h`<fieldset class="group grow col" style="min-height:0"><legend>Ofertas (${this.board.length})</legend>
      <div class="grow" style="overflow:auto;min-height:0">
      ${this.board.map((o) => {
        const t = CONTRACT_TYPES[o.type], d = DIFFICULTIES[o.difficulty];
        return h`<div class="enc-offer raised">
          <div class="flex"><b class="grow nowrap">${o.name}</b><span style="color:${d.color}" class="bold">${d.label}</span></div>
          <div class="flex gap4"><span class="tag" style="background:${t.color}">${t.label}</span><span class="dim grow nowrap">${o.client}</span>${o.ttl < 30 ? h`<span class="bad">vence ${Math.ceil(o.ttl)}s</span>` : ''}</div>
          <div class="flex gap4"><span class="grow">${fmt(o.maxHp)} pts · ${o.maxDays} d · <b class="ok">${money(o.reward)}</b> · +${o.rep} rep</span>
            <button class="btn small" data-action="accept" data-id="${o.id}" ${full ? 'disabled' : ''}>Aceptar</button></div>
        </div>`;
      })}
      <div class="flex gap4 mt4" style="align-items:center">
        <button class="btn small" data-action="refresh" ${this.refreshLeft > 0 ? '' : 'disabled'}>Buscar otros (${this.refreshLeft})</button>
        ${this.refreshCooldown > 0 ? h`<span class="dim">en ${Math.ceil(this.refreshCooldown)}s</span>` : ''}
      </div>
      </div>
    </fieldset>`;
  }

  renderWork() {
    const g = this.game;
    const c = this.selected();
    if (!c) {
      return h`<div class="col center grow mid dim">Sin encargos</div>`;
    }
    const t = CONTRACT_TYPES[c.type], d = DIFFICULTIES[c.difficulty];
    if (c.done) {
      const monthly = Math.round(c.reward * 0.15);
      return h`<div class="col center grow gap8 mid pad8">
        <div style="font-size:14px" class="bold">${c.name} - terminado</div>
        <div class="flex gap8 mt8">
          <button class="btn default" data-action="deliver">Entregar (${money(Math.round(c.reward * g.streakMult()))})</button>
          <button class="btn" data-action="rights">Vender yo (~${money(monthly)}/mes)</button>
        </div>
      </div>`;
    }
    const ratio = clamp(c.hp / c.maxHp, 0, 1);
    const cls = ratio > 0.5 ? 'ok' : ratio > 0.25 ? 'warn' : 'bad';
    const sx = this.shake > 0 ? ((Math.random() - 0.5) * 4).toFixed(1) : 0;
    const blink = Math.floor(performance.now() / 450) % 2 === 0;
    const code = c.type === 'software';
    const line = (s) => (code ? highlight(s) : s);
    const ty = this.typing;
    return h`<div class="col gap4 pad8 grow" style="min-height:0">
      <div class="flex gap4"><b class="grow nowrap" style="font-size:12px">${c.vip ? '★ ' : ''}${c.name}</b><span class="tag" style="background:${t.color}">${t.label}</span><span style="color:${d.color}" class="bold">${d.label}</span></div>
      <div class="dim nowrap">${c.client} — ${c.desc}</div>
      <div class="progress smooth ${cls} proj-bar" style="height:20px;transform:translateX(${sx}px)">
        <div class="fill" style="width:${(ratio * 100).toFixed(1)}%"></div><div class="label">${fmt(c.hp)} / ${fmt(c.maxHp)}</div>
      </div>
      <div class="flex"><span class="grow">Días: <b class="${c.days / c.maxDays < 0.25 ? 'bad' : ''}">${Math.ceil(c.days)}</b> / ${c.maxDays}</span>
        <b class="ok">${money(Math.round(c.reward * g.streakMult(g.streak)))}</b></div>
      <div class="enc-comps">
        ${c.components.map((comp, i) => {
          const off = comp.shake > 0 ? ((Math.random() - 0.5) * 4).toFixed(1) : 0;
          const tc = TIER_COLORS[comp.tier] || TIER_COLORS[0];
          const aff = comp.affinity;
          return h`<div class="field mid comp" style="transform:translateX(${off}px);box-shadow:var(--sunken), inset 0 0 0 3px ${tc}33">
            <b>${comp.label}</b> <span style="color:${tc}">${TIER_NAMES[comp.tier] || TIER_NAMES[0]}</span>
            ${comp.power > 0
              ? h`<div class="bold ${aff > 1.05 ? 'ok' : aff < 0.95 ? 'bad' : ''}">+${Math.round(comp.power * g.circlePowerMult())} <span class="dim">/ ${comp.interval.toFixed(1)}s</span></div>`
              : h`<div class="dim">-</div>`}
          </div>`;
        })}
      </div>
      <div class="flex gap8" style="align-items:center">
        <span>Enfoque:</span>
        <div class="progress grow enc-focus" style="height:12px"><div class="fill" style="width:${(this.focus * 100).toFixed(0)}%"></div></div>
        <b class="${this.focus > 0.66 ? 'bad' : this.focus > 0.33 ? 'warn' : 'dim'}">x${this.focusMult().toFixed(1)}</b>
        <span>Combo: <b class="${this.combo >= 5 ? 'warn' : this.combo ? 'ok' : 'dim'}">x${this.combo}</b></span>
      </div>
      <div class="field code grow enc-type" style="position:relative;overflow:hidden">
        ${this.lastLines.map((l) => h`<div class="cl dim-line">${line(l)}</div>`)}
        ${ty ? h`<div class="cl current ${this.error > 0 ? 'err' : ''}"><span class="typed">${ty.typed}</span><span class="caret ${blink ? '' : 'off'}">▏</span><span class="todo">${ty.target.slice(ty.typed.length)}</span></div>` : ''}
        ${this.floaters.filter((f) => f.kind === 'line').map((f) => h`<div class="code-float" style="opacity:${(1 - f.t / f.life).toFixed(2)};transform:translateY(${(-f.t * 40).toFixed(0)}px)">${f.text}</div>`)}
      </div>
      <div class="flex" style="align-items:center"><span class="grow"></span>
        <button class="btn small" data-action="abandon">Abandonar</button></div>
    </div>`;
  }

  afterRender(body) {
    const cv = body.querySelector('.fx-canvas');
    if (!cv) return;
    const root = cv.parentElement;
    const W = root.clientWidth, H = root.clientHeight;
    const k = this.game.scale * (window.devicePixelRatio || 1);
    if (cv.width !== Math.round(W * k) || cv.height !== Math.round(H * k)) { cv.width = Math.round(W * k); cv.height = Math.round(H * k); }
    const ctx = cv.getContext('2d');
    ctx.setTransform(k, 0, 0, k, 0, 0);
    ctx.clearRect(0, 0, W, H);
    const bar = root.querySelector('.proj-bar');
    const c = this.selected();
    if (!bar || !c) return;
    const rel = (el) => { const r = el.getBoundingClientRect(), o = root.getBoundingClientRect(), s = this.game.scale; return { x: (r.left - o.left) / s, y: (r.top - o.top) / s, w: r.width / s, h: r.height / s }; };
    const b = rel(bar);
    const ratio = clamp(c.hp / c.maxHp, 0, 1);
    const bx = b.x + 2 + (b.w - 4) * ratio, by = b.y + b.h / 2;
    const comps = root.querySelectorAll('.comp');
    for (const ci of c.circles) {
      const el = comps[ci.from];
      if (!el) continue;
      const r = rel(el);
      const ox = r.x + r.w / 2, oy = r.y + r.h / 2;
      const t = clamp(ci.t / ci.dur, 0, 1);
      const e = t * t * (3 - 2 * t);
      const x = ox + (bx - ox) * e, y = oy + (by - oy) * e - Math.sin(t * Math.PI) * 30;
      ctx.fillStyle = 'rgba(0,0,0,.3)';
      ctx.beginPath(); ctx.arc(x + 2, y + 2, 11, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = ci.color;
      ctx.beginPath(); ctx.arc(x, y, 11, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = '#000'; ctx.lineWidth = 1; ctx.stroke();
      ctx.fillStyle = '#fff';
      ctx.font = 'bold 10px Arial';
      ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText(ci.power, x, y + 0.5);
    }
    for (const f of this.floaters) {
      if (f.kind === 'line') continue;
      const fx = b.x + 2 + (b.w - 4) * f.at;
      ctx.globalAlpha = 1 - f.t / f.life;
      ctx.fillStyle = f.bug ? '#e00000' : '#008000';
      ctx.font = 'bold 16px Arial';
      ctx.textAlign = 'center';
      ctx.fillText(f.text, fx, by - 18 - f.t * 40);
      ctx.globalAlpha = 1;
    }
  }

  save() {
    const strip = ({ components, circles, ...c }) => c;
    return { active: this.active.map(strip), board: this.board, sel: this.sel, vipTimer: this.vipTimer, billTimer: this.billTimer };
  }
  load(d) {
    if (!d?.active) return; // partidas de antes de los encargos: empiezan sin encargos
    this.board = d.board || [];
    this.active = d.active.map((c) => ({ ...c, components: this.game.contractComponents(c.type), circles: [] }));
    this.vipTimer = d.vipTimer ?? this.vipTimer;
    this.billTimer = d.billTimer || 0;
    nextId = Math.max(nextId, ...[...this.active, ...this.board].map((c) => c.id + 1));
    this.select(this.active.some((c) => c.id === d.sel) ? d.sel : this.active[0]?.id ?? null);
  }
}
