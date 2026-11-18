// Trabajo Freelance (tareas por clic) y Trabajo Particular (proyectos con
// "círculos" que lanzan los componentes del PC). Portado de trabajo.lua.
import { App } from '../core/wm.js';
import { h, money, fmt, rand, clamp } from '../core/dom.js';
import { play, playRandom } from '../core/audio.js';
import { FREELANCE_TASKS, DIFFICULTIES, DIFFICULTY_ORDER, TASK_UNLOCKS, PROJECT_DAYS } from '../data/work.js';
import { TIER_NAMES, TIER_COLORS, HW } from '../data/hardware.js';
import { img } from '../core/assets.js';

export class TrabajoApp extends App {
  constructor(game) {
    super(game);
    this.jobs = [];            // [{task, progress, auto}]
    this.unlocked = new Set(['muy_facil', 'facil', 'normal']);
    this.winbatchTimer = 0;
  }
  get id() { return 'trabajo'; }
  get title() { return 'Trabajo Freelance'; }
  get icon() { return img('trabajo'); }
  get size() { return { w: 380, h: 300 }; }

  available() { return FREELANCE_TASKS.filter((t) => this.unlocked.has(t.difficulty)); }
  slots() { return this.game.jobSlots(); }

  work(auto = false) {
    const list = this.available();
    let added = 0;
    for (let i = 0; i < this.slots(); i++) {
      if (!this.jobs[i]) {
        this.jobs[i] = { task: rand(list), progress: 0, auto };
        added++;
        if (auto) break; // WinBatch llena de a un espacio por ciclo
      }
    }
    return added;
  }

  update(dt) {
    const g = this.game;
    if (g.flag('winbatch')) {
      this.winbatchTimer += dt;
      if (this.winbatchTimer >= 3) { this.winbatchTimer -= 3; this.work(true); }
    }
    for (const [diff, need] of Object.entries(TASK_UNLOCKS)) {
      if (!this.unlocked.has(diff) && g.stats.tasksCompleted >= need) this.unlocked.add(diff);
    }
    const mult = g.taskTimeMult();
    for (let i = 0; i < this.jobs.length; i++) {
      const job = this.jobs[i];
      if (!job) continue;
      job.progress += dt;
      if (job.progress >= job.task.time * mult) {
        const reward = g.earn(g.taskReward(), 'task');
        g.stats.tasksCompleted++;
        if (!job.auto) playRandom(['money1', 'money2', 'money3'], { volume: 0.45 });
        this.jobs[i] = null;
        g.emit('taskDone', reward);
      }
    }
    // Ajusta el alto de la ventana a la cantidad de espacios
    const wantH = 232 + this.slots() * 34;
    if (this.win.h !== wantH) { this.win.h = wantH; this.game.wm.place(this.win); }
  }

  onAction(action) {
    if (action === 'work') this.work(false);
  }

  render() {
    const g = this.game;
    const n = this.slots();
    const empty = Array.from({ length: n }, (_, i) => !this.jobs[i]).filter(Boolean).length;
    const mult = g.taskTimeMult();
    return h`
      <div class="col pad8 gap4 grow">
        <fieldset class="group"><legend>Resumen</legend>
          <div class="flex"><div class="grow">Tareas completadas:</div><b>${fmt(g.stats.tasksCompleted)}</b></div>
          <div class="flex"><div class="grow">Pago por tarea:</div><b class="ok">${money(g.taskReward())}</b></div>
          <div class="flex"><div class="grow">Tiempo por tarea:</div><span>x${mult.toFixed(2)}</span></div>
          <div class="flex"><div class="grow">Tareas simultáneas:</div><span>${n}</span></div>
          ${g.flag('winbatch') ? h`<div class="flex"><div class="grow">WinBatch:</div><b class="ok">ACTIVO</b></div>` : ''}
        </fieldset>
        <div class="center" style="padding:4px 0">
          <button class="btn default" style="min-width:150px" data-action="work" ${empty ? '' : 'disabled'}>
            ${empty ? `Trabajar (${empty})` : 'Todos ocupados'}</button>
        </div>
        <fieldset class="group grow"><legend>Tareas en curso</legend>
          ${Array.from({ length: n }, (_, i) => {
            const job = this.jobs[i];
            if (!job) return h`<div class="flex gap4" style="height:30px;align-items:center"><span class="dim" style="width:46px">Slot ${i + 1}</span><span class="dim">[Vacío]</span></div>`;
            const p = clamp(job.progress / (job.task.time * mult), 0, 1);
            return h`<div style="height:30px">
              <div class="flex"><span class="dim" style="width:46px">Slot ${i + 1}</span><span class="grow nowrap">${job.task.name}</span>
                <span style="color:${DIFFICULTIES[job.task.difficulty].color}">${DIFFICULTIES[job.task.difficulty].label}</span></div>
              <div class="progress" style="height:13px;margin-left:46px"><div class="fill" style="width:${(p * 100).toFixed(1)}%"></div></div>
            </div>`;
          })}
        </fieldset>
        <div class="statusbar">
          ${['cpu', 'display', 'ram', 'cooling'].map((k) => h`<div>${HW[k].short} Nv.${g.hw[k]}</div>`)}
        </div>
      </div>`;
  }

  save() { return { unlocked: [...this.unlocked] }; }
  load(d) { if (d?.unlocked) this.unlocked = new Set(d.unlocked); }
}

// ---------------------------------------------------------------------------

export class ProyectoApp extends App {
  constructor(game) {
    super(game);
    this.project = null;   // {name, desc, difficulty, hp, maxHp, days, maxDays, reward}
    this.components = [];
    this.circles = [];
    this.floaters = [];
    this.result = null;    // {type:'win'|'fail', text, unlocked}
    this.completed = 0;
    this.shake = 0;
  }
  get id() { return 'particular'; }
  get title() { return this.project ? `Trabajo Particular - ${this.project.name}` : 'Trabajo Particular'; }
  get icon() { return img('trabajo'); }
  get size() { return { w: 420, h: 400 }; }
  get minimizeOnly() { return true; }

  get trabajo() { return this.game.apps.trabajo; }

  start(p) {
    if (this.project) return false;
    this.project = {
      name: p.name, desc: p.desc, difficulty: p.difficulty,
      hp: 0, maxHp: p.hp, days: PROJECT_DAYS, maxDays: PROJECT_DAYS, reward: p.reward,
    };
    this.result = null;
    this.circles = [];
    this.floaters = [];
    this.components = this.game.projectComponents();
    this.game.wm.open(this.id);
    return true;
  }

  complete() {
    const g = this.game;
    const p = this.project;
    g.earn(p.reward, 'project');
    g.stats.projectsCompleted++;
    this.completed++;
    let unlocked = null;
    const idx = DIFFICULTY_ORDER.indexOf(p.difficulty);
    const next = DIFFICULTY_ORDER[idx + 1];
    if (next && !this.trabajo.unlocked.has(next)) { this.trabajo.unlocked.add(next); unlocked = next; }
    this.result = { type: 'win', text: `¡Proyecto exitoso! +${money(p.reward)}`, unlocked };
    play('ding', { volume: 0.5 });
    this.clear();
    g.emit('projectDone', p);
  }

  fail(reason = 'tiempo') {
    const g = this.game;
    const p = this.project;
    if (!p) return;
    const penalty = Math.floor(p.reward * 0.15);
    g.lose(penalty);
    g.stats.projectsFailed++;
    this.result = { type: 'fail', text: `Proyecto fracasado. Penalización: -${money(penalty)}` };
    g.apps.email?.add({
      subject: `Proyecto fracasado - ${p.name}`, from: 'clientes@freelance.com', type: 'news',
      body: `Estimado freelancer:\n\nLamentamos informarle que no pudo completar el proyecto a tiempo${reason === 'malware' ? ' debido a una falla de su equipo' : ''}.\n\nSe le ha cobrado una penalización de ${money(penalty)} por los inconvenientes.\n\nLe recomendamos mejorar sus componentes de PC.`,
    });
    this.clear();
  }

  clear() {
    this.project = null;
    this.circles = [];
    this.components = [];
  }

  update(dt) {
    const p = this.project;
    this.shake = Math.max(0, this.shake - dt);
    for (const f of this.floaters) { f.t += dt; }
    this.floaters = this.floaters.filter((f) => f.t < f.life);
    if (!p) return;
    const g = this.game;
    const speed = 1 / g.circleSpeedMult();
    for (const [i, c] of this.components.entries()) {
      c.shake = Math.max(0, c.shake - dt);
      if (c.power <= 0) continue;
      c.timer += dt * speed;
      if (c.timer >= c.interval) {
        c.timer -= c.interval;
        const bug = Math.random() < g.bugChance();
        const base = bug ? Math.floor(c.power * 0.6) : c.power;
        const power = Math.max(1, Math.floor(base * g.circlePowerMult()));
        this.circles.push({ from: i, power, bug, t: 0, dur: 0.75 + Math.random() * 0.25, color: bug ? '#e02020' : c.color });
        c.shake = 0.2;
        if (this.win.open && !this.win.minimized) playRandom(['circle1', 'circle2'], { volume: 0.25 });
      }
    }
    for (const c of this.circles) {
      c.t += dt;
      if (c.t >= c.dur && !c.done) {
        c.done = true;
        p.hp = c.bug ? Math.max(0, p.hp - c.power) : p.hp + c.power;
        this.floaters.push({ text: (c.bug ? '-' : '+') + c.power, bug: c.bug, t: 0, life: c.bug ? 1.4 : 1, at: p.hp / p.maxHp });
        this.shake = 0.15;
      }
    }
    this.circles = this.circles.filter((c) => !c.done);
    if (p.hp >= p.maxHp) { this.complete(); return; }
    p.days -= dt * 0.3;
    if (p.days <= 0) this.fail();
  }

  onAction(action) {
    if (action === 'dismiss') { this.result = null; this.game.wm.close(this.id); }
  }

  render() {
    const p = this.project;
    if (!p) {
      if (this.result) {
        const r = this.result;
        const d = r.unlocked ? DIFFICULTIES[r.unlocked] : null;
        return h`<div class="col center grow gap8 pad8 mid">
          <div style="font-size:14px" class="bold ${r.type === 'win' ? 'ok' : 'bad'}">${r.text}</div>
          <div>${r.type === 'win' ? '¡Felicidades por completar el proyecto!' : 'Más suerte la próxima vez.'}</div>
          ${d ? h`<div class="group" style="min-width:240px"><span class="legend">Nueva dificultad</span><b style="color:${d.color}">[${d.label}]</b> disponible en la Bolsa de Trabajo</div>` : ''}
          <button class="btn default mt8" data-action="dismiss">Aceptar</button>
        </div>`;
      }
      return h`<div class="col center grow gap4 pad8 mid">
        <b>Sin proyecto activo</b>
        <span class="dim">Acepte un proyecto desde la Bolsa de Trabajo<br>o desde su correo para comenzar.</span>
      </div>`;
    }
    const ratio = clamp(p.hp / p.maxHp, 0, 1);
    const cls = ratio > 0.5 ? 'ok' : ratio > 0.25 ? 'warn' : 'bad';
    const diff = DIFFICULTIES[p.difficulty];
    const sx = this.shake > 0 ? ((Math.random() - 0.5) * 4).toFixed(1) : 0;
    const mb = this.game.mbBonus();
    return h`<div class="col pad8 gap4 grow proj-root" style="position:relative">
      <div class="mid"><b style="font-size:12px">${p.name}</b> <span style="color:${diff.color}">[${diff.label}]</span></div>
      <div class="mid dim">${p.desc}</div>
      <div class="progress smooth ${cls} proj-bar" style="height:20px;transform:translateX(${sx}px)">
        <div class="fill" style="width:${(ratio * 100).toFixed(1)}%"></div>
        <div class="label">${fmt(p.hp)} / ${fmt(p.maxHp)}</div>
      </div>
      <div class="flex"><span class="grow">Días restantes: <b>${Math.ceil(p.days)}</b> / ${p.maxDays}</span><span class="ok bold">${money(p.reward)}</span></div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:6px">
        ${this.components.map((c, i) => {
          const off = c.shake > 0 ? ((Math.random() - 0.5) * 4).toFixed(1) : 0;
          const tc = TIER_COLORS[c.tier] || TIER_COLORS[0];
          return h`<div class="field mid comp" data-comp="${i}" style="height:78px;transform:translateX(${off}px);box-shadow:var(--sunken), inset 0 0 0 4px ${tc}33">
            <b>${c.label}</b>
            <div style="color:${tc}">${TIER_NAMES[c.tier] || TIER_NAMES[0]}</div>
            <div class="dim nowrap" style="overflow:hidden;text-overflow:ellipsis">${c.name}</div>
            ${c.power > 0
              ? h`<div style="color:${c.color}" class="bold">Potencia: ${c.power}</div><div class="dim">cada ${c.interval.toFixed(1)}s</div>`
              : h`<div class="dim">Sin potencia</div><div class="dim">(mejora este componente)</div>`}
          </div>`;
        })}
      </div>
      <div class="statusbar mt4"><div>Placa madre: ${this.game.hwName('motherboard')}</div><div>-${Math.round(mb.interval * 100)}% intervalo · +${Math.round(mb.power * 100)}% potencia</div></div>
      <canvas class="fx-canvas" data-keep></canvas>
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
    if (!bar) return;
    const p = this.project;
    const ratio = p ? clamp(p.hp / p.maxHp, 0, 1) : 0;
    const bx = bar.offsetLeft + 2 + (bar.offsetWidth - 4) * ratio;
    const by = bar.offsetTop + bar.offsetHeight / 2;
    const comps = root.querySelectorAll('.comp');
    for (const c of this.circles) {
      const el = comps[c.from];
      if (!el) continue;
      const ox = el.offsetLeft + el.offsetWidth / 2, oy = el.offsetTop + el.offsetHeight / 2;
      const t = clamp(c.t / c.dur, 0, 1);
      const e = t * t * (3 - 2 * t);
      const x = ox + (bx - ox) * e, y = oy + (by - oy) * e - Math.sin(t * Math.PI) * 30;
      ctx.fillStyle = 'rgba(0,0,0,.3)';
      ctx.beginPath(); ctx.arc(x + 2, y + 2, 11, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = c.color;
      ctx.beginPath(); ctx.arc(x, y, 11, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = '#000'; ctx.lineWidth = 1; ctx.stroke();
      ctx.fillStyle = '#fff';
      ctx.font = 'bold 10px Arial';
      ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText(c.power, x, y + 0.5);
    }
    for (const f of this.floaters) {
      const a = 1 - f.t / f.life;
      const fx = bar.offsetLeft + 2 + (bar.offsetWidth - 4) * f.at;
      ctx.globalAlpha = a;
      ctx.fillStyle = f.bug ? '#e00000' : '#008000';
      ctx.font = 'bold 16px Arial';
      ctx.textAlign = 'center';
      ctx.fillText(f.text, fx, by - 18 - f.t * 40);
      ctx.globalAlpha = 1;
    }
  }

  save() { return { project: this.project, completed: this.completed }; }
  load(d) {
    this.completed = d?.completed || 0;
    if (d?.project) { this.project = d.project; this.components = this.game.projectComponents(); }
  }
}
