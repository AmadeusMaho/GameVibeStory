// Code Editor: programa apps escribiendo código y véndelas. Portado de coding.lua.
import { App } from '../core/wm.js';
import { h, raw, money, fmt, rand, clamp } from '../core/dom.js';
import { play } from '../core/audio.js';
import { img } from '../core/assets.js';

export const PROJECT_TYPES = [
  { id: 'calculator', name: 'Calculadora', difficulty: 'normal', cost: 80, hp: 1000, reward: 200, monthly: 8 },
  { id: 'notepad_pro', name: 'Notepad Pro', difficulty: 'normal', cost: 60, hp: 800, reward: 150, monthly: 6 },
  { id: 'file_manager', name: 'Administrador de archivos', difficulty: 'normal', cost: 90, hp: 1200, reward: 220, monthly: 9 },
  { id: 'browser', name: 'Navegador Web', difficulty: 'dificil', cost: 200, hp: 2000, reward: 500, monthly: 20 },
  { id: 'email_client', name: 'Cliente de Email', difficulty: 'dificil', cost: 150, hp: 1600, reward: 400, monthly: 15 },
  { id: 'media_player', name: 'Reproductor multimedia', difficulty: 'dificil', cost: 250, hp: 2400, reward: 600, monthly: 25 },
  { id: 'database', name: 'Base de Datos', difficulty: 'pesadilla', cost: 500, hp: 4000, reward: 1200, monthly: 50 },
  { id: 'office_suite', name: 'Suite de Oficina', difficulty: 'pesadilla', cost: 800, hp: 5000, reward: 1800, monthly: 80 },
  { id: 'game_engine', name: 'Motor de Juegos', difficulty: 'pesadilla', cost: 1200, hp: 6000, reward: 2500, monthly: 120 },
];
const DIFF_CLASS = { normal: 'ok', dificil: 'warn', pesadilla: 'bad' };
const DIFF_LABEL = { normal: 'Normal', dificil: 'Difícil', pesadilla: 'Pesadilla' };

// t = la línea la escribe el jugador; f = se escribe sola al presionar ENTER
export const SNIPPETS = [
  [['def calculate_total(items):', 1], ['    total = 0', 0], ['    for item in items:', 0], ['        total += item.price', 1], ['    return total', 0]],
  [['class Database:', 1], ['    def __init__(self, name):', 0], ['        self.name = name', 0], ['        self.tables = {}', 1], ['    def create_table(self, name, cols):', 0], ['        table = {"name": name}', 1]],
  [['function processData(input) {', 1], ['    const result = [];', 0], ['    for (let i = 0; i < input.length; i++) {', 0], ['        if (input[i].valid) {', 1], ['            result.push(transform(input[i]));', 0], ['        }', 0], ['    }', 0], ['    return result;', 1], ['}', 0]],
  [['#include <stdlib.h>', 1], ['#include <string.h>', 0], ['typedef struct {', 0], ['    char *name;', 1], ['    int id;', 0], ['    float value;', 0], ['} Record;', 1], ['Record* create_record(const char *n) {', 0], ['    Record *r = malloc(sizeof(Record));', 1], ['    return r;', 0], ['}', 0]],
  [['def save_report(data, filename):', 1], ['    with open(filename, "w") as f:', 0], ['        for line in data:', 0], ['            f.write(str(line) + "\\n")', 1], ['    print("Report saved!")', 0]],
  [['Private Sub cmdCalcular_Click()', 1], ['    Dim total As Double', 0], ['    total = Val(txtA.Text) + Val(txtB.Text)', 1], ['    lblResultado.Caption = total', 0], ['End Sub', 1]],
  [['program Inventario;', 1], ['var', 0], ['    stock: integer;', 0], ['begin', 1], ['    stock := 100;', 0], ['    writeln(stock);', 1], ['end.', 0]],
];
const KEYWORDS = /\b(if|else|for|while|return|function|class|def|import|from|const|let|var|int|char|void|struct|typedef|include|with|as|open|print|in|self|Private|Sub|Dim|As|End|Double|program|begin|end|integer|writeln|float|malloc|sizeof)\b/g;
const XP_PER_LEVEL = [100, 250, 500, 1000, 2000];

export class CodingApp extends App {
  constructor(game) {
    super(game);
    this.level = 1; this.xp = 0;
    this.state = 'browse';
    this.offers = [];
    this.refreshLeft = 3; this.refreshCooldown = 0;
    this.active = null; this.hp = 0; this.spent = 0; this.days = 0;
    this.published = [];
    this.resetTyping();
  }
  get id() { return 'coding'; }
  get title() { return this.active ? `Code Editor - ${this.active.name}` : 'Code Editor'; }
  get icon() { return img('coding'); }
  get size() { return { w: 600, h: 460 }; }

  resetTyping() {
    Object.assign(this, { lines: [], snippet: null, idx: 0, done: [], typing: false, target: '', typed: '', error: 0,
      waitingAuto: false, autoOn: false, autoLines: [], autoLine: 0, autoChar: 0, autoTimer: 0,
      snippetDone: false, snippetBonus: 0, combo: 0, maxCombo: 0, linesDone: 0, floaters: [] });
  }

  nextXP() { return XP_PER_LEVEL[this.level - 1] || Infinity; }
  addXP(n) {
    this.xp += n;
    while (this.level < XP_PER_LEVEL.length && this.xp >= XP_PER_LEVEL[this.level - 1]) { this.xp -= XP_PER_LEVEL[this.level - 1]; this.level++; }
  }
  maxSelling() { return this.level >= 5 ? 3 : this.level >= 3 ? 2 : 1; }
  selling() { return this.published.filter((a) => a.selling).length; }

  refreshOffers() {
    const count = Math.min(4, 2 + Math.floor(this.level / 2));
    const pool = [...PROJECT_TYPES];
    this.offers = [];
    while (this.offers.length < count && pool.length) this.offers.push(pool.splice(Math.floor(Math.random() * pool.length), 1)[0]);
  }

  onOpen() { if (!this.offers.length) this.refreshOffers(); }

  start(i) {
    const p = this.offers[i];
    if (!p || this.selling() >= this.maxSelling() || !this.game.spend(p.cost)) return;
    this.active = p; this.hp = 0; this.spent = p.cost; this.days = 14;
    this.state = 'coding';
    this.nextSnippet();
  }

  nextSnippet() {
    const combo = this.combo, maxCombo = this.maxCombo;
    this.resetTyping();
    this.combo = 0; this.maxCombo = Math.max(maxCombo, combo);
    this.snippet = rand(SNIPPETS);
    this.advance();
  }

  advance() {
    if (this.idx >= this.snippet.length) {
      this.snippetDone = true;
      this.snippetBonus = Math.floor(this.active.hp * 0.15);
      this.hp += this.snippetBonus;
      this.addXP(15);
      return;
    }
    const [text, mustType] = this.snippet[this.idx];
    if (mustType) {
      this.typing = true; this.waitingAuto = false; this.autoOn = false;
      this.target = text; this.typed = text.match(/^\s*/)[0]; // la sangría se escribe sola
    } else {
      this.typing = false; this.waitingAuto = true; this.autoOn = false;
      this.autoLines = [];
      let j = this.idx;
      while (j < this.snippet.length && !this.snippet[j][1]) this.autoLines.push(this.snippet[j++][0]);
      this.autoLine = 0; this.autoChar = 0; this.autoTimer = 0;
    }
  }

  finishAuto() {
    for (let i = this.autoLine; i < this.autoLines.length; i++) this.done.push(this.autoLines[i]);
    this.idx += this.autoLines.length;
    this.autoLines = []; this.autoOn = false; this.waitingAuto = false;
    this.advance();
  }

  completeLine() {
    const dmg = Math.floor(Math.floor(this.active.hp * 0.03) * (1 + this.combo * 0.1));
    this.hp += dmg;
    this.combo++; this.maxCombo = Math.max(this.maxCombo, this.combo);
    this.linesDone++;
    this.game.stats.linesTyped++;
    this.addXP(5);
    this.floaters.push({ text: `+${dmg}${this.combo > 1 ? ' x' + this.combo : ''}`, t: 0 });
    this.done.push(this.target);
    this.idx++;
    this.typing = false;
    this.advance();
    if (this.hp >= this.active.hp) { this.state = 'sell'; }
  }

  /** Teclado: lo llama main.js cuando la ventana está activa. Devuelve true si consumió la tecla. */
  onKey(e) {
    if (this.state !== 'coding') return false;
    if (this.snippetDone) {
      if (this.hp >= this.active.hp) this.state = 'sell'; else this.nextSnippet();
      return true;
    }
    if (this.waitingAuto) {
      if (e.key === 'Enter' || e.key === ' ') { this.waitingAuto = false; this.autoOn = true; }
      return true;
    }
    if (this.autoOn) { if (e.key === 'Enter') this.finishAuto(); return true; }
    if (!this.typing || this.error > 0) return true;
    if (e.key === 'Backspace') { this.typed = this.typed.slice(0, -1); return true; }
    if (e.key.length !== 1) return e.key === 'Tab';
    const expected = this.target[this.typed.length];
    if (e.key === expected) {
      this.typed += e.key;
      if (this.typed.length >= this.target.length) this.completeLine();
    } else {
      this.error = 0.3; this.combo = 0;
    }
    return true;
  }

  sell() {
    const p = this.active;
    this.published.push({ name: p.name, rev: p.monthly, months: 12, total: 0, selling: true, upd: 0, success: (5 + Math.floor(Math.random() * 5)) / 10, timer: 0 });
    this.game.stats.appsPublished++;
    this.addXP(Math.floor(p.reward / 5));
    play('ding', { volume: 0.5 });
    this.active = null; this.state = 'browse';
    this.resetTyping();
  }

  cancel() {
    if (!this.active) return;
    this.game.earn(Math.floor(this.spent * 0.3), 'refund');
    this.active = null; this.state = 'browse';
    this.resetTyping();
  }

  update(dt) {
    if (this.refreshCooldown > 0) { this.refreshCooldown -= dt; if (this.refreshCooldown <= 0) this.refreshLeft = 3; }
    if (this.state === 'coding' && this.active) {
      this.days -= dt * 0.05;
      if (this.days <= 0) this.cancel();
    }
    if (this.error > 0) this.error -= dt;
    for (const f of this.floaters) f.t += dt;
    this.floaters = this.floaters.filter((f) => f.t < 1.4);
    for (const a of this.published) {
      if (!a.selling) continue;
      a.timer += dt;
      if (a.timer >= 30) {
        a.timer -= 30;
        const revenue = Math.floor(a.rev * a.success * a.months / 12);
        a.total += revenue;
        this.game.earn(revenue, 'apps');
        a.months--; a.upd++;
        if (a.months <= 0) a.selling = false;
      }
    }
    if (this.autoOn) {
      this.autoTimer += dt;
      while (this.autoTimer >= 0.03 && this.autoOn) {
        this.autoTimer -= 0.03;
        const line = this.autoLines[this.autoLine];
        if (line == null) { this.finishAuto(); break; }
        if (this.autoChar < line.length) this.autoChar++;
        else { this.done.push(line); this.autoLine++; this.autoChar = 0; this.idx++; if (this.autoLine >= this.autoLines.length) { this.autoLines = []; this.autoOn = false; this.advance(); } }
      }
    }
  }

  onAction(action, d) {
    switch (action) {
      case 'start': this.start(Number(d.i)); break;
      case 'refresh': if (this.refreshLeft > 0) { this.refreshOffers(); if (--this.refreshLeft === 0) this.refreshCooldown = 30; } break;
      case 'sell': this.sell(); break;
      case 'manage': this.state = 'manage'; break;
      case 'browse': this.state = this.active ? 'coding' : 'browse'; break;
      case 'cancel': this.cancel(); break;
      case 'update': { const a = this.published[d.i]; if (a && a.upd >= 4) { a.rev = Math.floor(a.rev * 1.3); a.months += 8; a.upd = 0; a.selling = true; } break; }
      case 'retire': this.published.splice(Number(d.i), 1); break;
    }
  }

  render() {
    const xpPct = this.level >= XP_PER_LEVEL.length ? 100 : (this.xp / this.nextXP()) * 100;
    const header = h`<div class="flex gap8" style="align-items:center;padding:4px 6px">
      <b>Nivel ${this.level}</b>
      <div class="progress grow" style="height:12px"><div class="fill" style="width:${xpPct.toFixed(0)}%"></div></div>
      <span class="dim">${this.level >= XP_PER_LEVEL.length ? 'MAX' : `${this.xp}/${this.nextXP()} XP`}</span>
      <button class="btn small" data-action="${this.state === 'manage' ? 'browse' : 'manage'}">${this.state === 'manage' ? 'Volver' : `Mis apps (${this.selling()}/${this.maxSelling()})`}</button>
    </div>`;
    let body;
    if (this.state === 'manage') body = this.renderManage();
    else if (this.state === 'sell') body = this.renderSell();
    else if (this.state === 'coding') body = this.renderEditor();
    else body = this.renderBrowse();
    return h`<div class="menubar"><span><u>A</u>rchivo</span><span><u>E</u>dición</span><span><u>P</u>royecto</span><span><u>C</u>ompilar</span><span>Ay<u>u</u>da</span></div>
      ${header}<div class="col grow" style="min-height:0;padding:0 6px 6px">${body}</div>`;
  }

  renderBrowse() {
    const g = this.game;
    const full = this.selling() >= this.maxSelling();
    return h`
      <fieldset class="group grow" style="overflow:auto"><legend>Encargos de software disponibles</legend>
        ${full ? h`<p class="bad">Tienes el máximo de apps a la venta (${this.maxSelling()}). Sube de nivel o retira una app.</p>` : ''}
        ${this.offers.map((p, i) => h`<div class="flex gap8 raised" style="padding:8px;margin-bottom:6px;align-items:center">
          <div class="grow">
            <b>${p.name}</b> <span class="${DIFF_CLASS[p.difficulty]}">[${DIFF_LABEL[p.difficulty]}]</span><br>
            <span class="dim">Inversión: ${money(p.cost)} · Trabajo: ${fmt(p.hp)} pts · Ingreso: ~${money(p.monthly)}/mes</span>
          </div>
          <button class="btn" data-action="start" data-i="${i}" ${full || g.money < p.cost ? 'disabled' : ''}>Programar</button>
        </div>`)}
      </fieldset>
      <div class="flex gap8 mt4" style="align-items:center">
        <button class="btn" data-action="refresh" ${this.refreshLeft > 0 ? '' : 'disabled'}>Buscar otros (${this.refreshLeft})</button>
        ${this.refreshCooldown > 0 ? h`<span class="dim">Nuevas búsquedas en ${Math.ceil(this.refreshCooldown)}s</span>` : ''}
        <div class="grow"></div><span>Dinero: <b class="ok">${money(g.money)}</b></span>
      </div>`;
  }

  renderEditor() {
    const p = this.active;
    const ratio = clamp(this.hp / p.hp, 0, 1);
    const cls = ratio > 0.5 ? 'ok' : ratio > 0.25 ? 'warn' : 'bad';
    const blink = Math.floor(performance.now() / 450) % 2 === 0;
    const lines = [...this.done];
    let status;
    if (this.snippetDone) status = h`<b class="ok">¡Bloque completado! +${this.snippetBonus} pts</b> — presiona cualquier tecla para continuar`;
    else if (this.waitingAuto) status = h`<b style="color:#060">Presiona ENTER para escribir el código automático</b>`;
    else if (this.autoOn) status = h`<span style="color:#060">Escribiendo... (ENTER para terminar)</span>`;
    else status = h`<b>Escribe la línea resaltada</b>${this.error > 0 ? h` <b class="bad">¡Error!</b>` : ''}`;
    const codeLine = (text) => highlight(text);
    const autoPartial = this.autoOn && this.autoLines[this.autoLine] != null ? this.autoLines[this.autoLine].slice(0, this.autoChar) : null;
    return h`
      <div class="progress smooth ${cls}" style="height:18px"><div class="fill" style="width:${(ratio * 100).toFixed(1)}%"></div><div class="label">${fmt(this.hp)} / ${fmt(p.hp)}</div></div>
      <div class="flex mt4"><span class="grow">${status}</span><span>Combo: <b class="${this.combo >= 10 ? 'bad' : this.combo >= 5 ? 'warn' : this.combo ? 'ok' : 'dim'}">x${this.combo}</b> · Días: ${Math.ceil(this.days)}/14</span></div>
      <div class="field grow mt4 code" style="overflow:hidden;position:relative">
        ${lines.slice(-14).map((l, i) => h`<div class="cl"><span class="ln">${Math.max(0, lines.length - 14) + i + 1}</span>${codeLine(l)}</div>`)}
        ${autoPartial != null ? h`<div class="cl"><span class="ln">${lines.length + 1}</span>${codeLine(autoPartial)}<span class="caret ${blink ? '' : 'off'}">█</span></div>` : ''}
        ${this.typing && !this.snippetDone ? h`<div class="cl current ${this.error > 0 ? 'err' : ''}"><span class="ln">${lines.length + 1}</span><span class="typed">${this.typed}</span><span class="caret ${blink ? '' : 'off'}">▏</span><span class="todo">${this.target.slice(this.typed.length)}</span></div>` : ''}
        ${this.floaters.map((f) => h`<div class="code-float" style="opacity:${(1 - f.t / 1.4).toFixed(2)};transform:translateY(${(-f.t * 40).toFixed(0)}px)">${f.text}</div>`)}
      </div>
      <div class="flex mt4" style="align-items:center"><span class="dim grow">Si cancelas recuperas el 30% de la inversión.</span><button class="btn" data-action="cancel">Cancelar proyecto</button></div>`;
  }

  renderSell() {
    const p = this.active;
    return h`<div class="col center grow gap8 mid">
      <div style="font-size:16px" class="bold ok">¡${p.name} está terminado!</div>
      <div>Combo máximo: x${this.maxCombo} · Líneas escritas: ${this.linesDone}</div>
      <div>Ingreso estimado: <b>${money(p.monthly)}</b> al mes durante 12 meses</div>
      <button class="btn default mt8" data-action="sell">Publicar y vender</button>
    </div>`;
  }

  renderManage() {
    return h`<fieldset class="group grow" style="overflow:auto"><legend>Aplicaciones publicadas</legend>
      ${this.published.length ? '' : h`<p class="dim">Aún no has publicado aplicaciones.</p>`}
      <table class="grid">
        ${this.published.length ? h`<tr><th>App</th><th>Estado</th><th>Ingreso/mes</th><th>Total</th><th></th></tr>` : ''}
        ${this.published.map((a, i) => h`<tr>
          <td>${a.name}</td><td>${a.selling ? h`<span class="ok">Vendiendo (${a.months} meses)</span>` : h`<span class="dim">Retirada</span>`}</td>
          <td>${money(Math.floor(a.rev * a.success))}</td><td>${money(a.total)}</td>
          <td class="nowrap"><button class="btn small" data-action="update" data-i="${i}" ${a.upd >= 4 ? '' : 'disabled'} title="Disponible cada 4 meses">Actualizar</button>
            <button class="btn small" data-action="retire" data-i="${i}">Retirar</button></td></tr>`)}
      </table>
    </fieldset>`;
  }

  save() {
    return { level: this.level, xp: this.xp, published: this.published, active: this.active?.id || null, hp: this.hp, spent: this.spent, days: this.days };
  }
  load(d) {
    if (!d) return;
    this.level = d.level || 1; this.xp = d.xp || 0; this.published = d.published || [];
    if (d.active) {
      this.active = PROJECT_TYPES.find((p) => p.id === d.active) || null;
      if (this.active) { this.hp = d.hp; this.spent = d.spent; this.days = d.days; this.state = 'coding'; this.nextSnippet(); }
    }
  }
}

export function highlight(text) {
  const escd = String(h`${text}`);
  return raw(escd.replace(KEYWORDS, '<span class="kw">$1</span>').replace(/(&quot;[^&]*&quot;)/g, '<span class="str">$1</span>'));
}
