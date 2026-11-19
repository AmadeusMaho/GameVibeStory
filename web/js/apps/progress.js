// Objetivos (desbloqueos), Logros y Personal (empleados). Portado de
// notepad.lua, achievements.lua y personal.lua.
import { App } from '../core/wm.js';
import { h, money, fmt } from '../core/dom.js';
import { play } from '../core/audio.js';
import { toast } from '../core/ui.js';
import { img } from '../core/assets.js';

// ----------------------------------------------------------------- Objetivos
export const GOALS = [
  { id: 'deliver1', text: 'Entrega tu primer encargo', check: (g) => g.stats.tasksCompleted >= 1 },
  { id: 'money100', text: 'Gana $100 en total', check: (g) => g.totalEarned >= 100 },
  { id: 'deliver5', text: 'Entrega 5 encargos', check: (g) => g.stats.tasksCompleted >= 5 },
  { id: 'rep1', text: 'Llega a reputación «Conocido en el barrio»', check: (g) => g.repLevel() >= 1 },
  { id: 'upgrade3', text: 'Compra 3 mejoras de hardware', check: (g) => g.stats.upgradesPurchased >= 3 },
  { id: 'streak5', text: 'Consigue una racha de 5 entregas', check: (g) => g.bestStreak >= 5 },
  { id: 'money1500', text: 'Gana $1.500 en total', check: (g) => g.totalEarned >= 1500 },
  { id: 'rep3', text: 'Llega a reputación «Confiable»', check: (g) => g.repLevel() >= 3 },
  { id: 'rep5', text: 'Llega a reputación «Experto»', check: (g) => g.repLevel() >= 5 },
  { id: 'xpReady', text: 'Cumple los requisitos de Windows XP', check: (g) => g.hw.cpu >= 6 && g.hw.ram >= 3 && g.hw.disk >= 2 && g.totalEarned >= 50000 },
];

export class GoalsApp extends App {
  constructor(game) { super(game); this.done = []; }
  get id() { return 'notepad'; }
  get title() { return 'Objetivos.txt - Bloc de notas'; }
  get icon() { return img('notepad'); }
  get size() { return { w: 380, h: 320 }; }

  update() {
    const g = this.game;
    GOALS.forEach((goal, i) => {
      if (this.done.includes(goal.id)) return;
      if (i > 0 && !this.done.includes(GOALS[i - 1].id)) return; // en orden
      if (goal.check(g)) {
        this.done.push(goal.id);
        toast('¡Objetivo completado!', goal.text);
        play('ding', { volume: 0.4 });
        g.emit('goal', goal.id, i + 1);
      }
    });
  }

  render() {
    const visible = GOALS.filter((goal, i) => i === 0 || this.done.includes(GOALS[i - 1].id));
    const text = `OBJETIVOS\r\n=========\r\n\r\n${visible.map((goal) => `${this.done.includes(goal.id) ? '[X]' : '[ ]'} ${goal.text}`).join('\r\n')}\r\n\r\nCompleta objetivos para desbloquear\r\nnuevas aplicaciones.\r\n`;
    return h`<div class="menubar"><span><u>A</u>rchivo</span><span><u>E</u>dición</span><span><u>B</u>uscar</span><span>Ay<u>u</u>da</span></div>
      <div class="field grow" style="white-space:pre-wrap;font-family:'Fixedsys','Courier New',monospace;font-size:13px;line-height:17px;overflow:auto">${text}</div>`;
  }
  save() { return { done: this.done }; }
  load(d) { this.done = d?.done || []; }
}

// ------------------------------------------------------------------ Logros
export const ACHIEVEMENTS = [
  { id: 'first_task', name: 'Primer Empleo', desc: 'Entrega tu primer encargo', reward: 10, check: (s) => s.tasksCompleted >= 1 },
  { id: 'task_10', name: 'Trabajador', desc: 'Entrega 10 encargos', reward: 25, check: (s) => s.tasksCompleted >= 10 },
  { id: 'task_50', name: 'Veterano', desc: 'Entrega 50 encargos', reward: 50, check: (s) => s.tasksCompleted >= 50 },
  { id: 'task_100', name: 'Maestro del Teclado', desc: 'Entrega 100 encargos', reward: 100, check: (s) => s.tasksCompleted >= 100 },
  { id: 'task_500', name: 'Incansable', desc: 'Entrega 500 encargos', reward: 400, check: (s) => s.tasksCompleted >= 500 },
  { id: 'money_100', name: 'Ahorrista', desc: 'Gana $100 en total', reward: 20, check: (s, g) => g.totalEarned >= 100 },
  { id: 'money_500', name: 'Emprendedor', desc: 'Gana $500 en total', reward: 50, check: (s, g) => g.totalEarned >= 500 },
  { id: 'money_1000', name: 'Magnate', desc: 'Gana $1.000 en total', reward: 100, check: (s, g) => g.totalEarned >= 1000 },
  { id: 'money_5000', name: 'Millonario', desc: 'Gana $5.000 en total', reward: 250, check: (s, g) => g.totalEarned >= 5000 },
  { id: 'first_project', name: 'Constructor', desc: 'Entrega un encargo Normal o superior', reward: 30, check: (s) => s.projectsCompleted >= 1 },
  { id: 'project_5', name: 'Contratista', desc: 'Entrega 5 encargos Normal o superior', reward: 75, check: (s) => s.projectsCompleted >= 5 },
  { id: 'project_10', name: 'Director de Proyectos', desc: 'Entrega 10 encargos Normal o superior', reward: 150, check: (s) => s.projectsCompleted >= 10 },
  { id: 'fail_project', name: 'Fracaso', desc: 'Deja vencer un encargo', reward: 5, check: (s) => s.projectsFailed >= 1 },
  { id: 'first_upgrade', name: 'Mejorando', desc: 'Compra tu primera mejora', reward: 15, check: (s) => s.upgradesPurchased >= 1 },
  { id: 'upgrade_5', name: 'Inversionista', desc: 'Compra 5 mejoras', reward: 50, check: (s) => s.upgradesPurchased >= 5 },
  { id: 'upgrade_10', name: 'Tecnólogo', desc: 'Compra 10 mejoras', reward: 100, check: (s) => s.upgradesPurchased >= 10 },
  { id: 'first_hire', name: 'Jefe', desc: 'Contrata tu primer empleado', reward: 20, check: (s) => s.employeesHired >= 1 },
  { id: 'hire_5', name: 'Empresario', desc: 'Contrata 5 empleados', reward: 100, check: (s) => s.employeesHired >= 5 },
  { id: 'first_app', name: 'Desarrollador', desc: 'Publica tu primera aplicación', reward: 200, check: (s) => s.appsPublished >= 1 },
  { id: 'clean_mail', name: 'Filtro antispam', desc: 'Elimina 5 correos peligrosos', reward: 40, check: (s) => s.malwareDeleted >= 5 },
  { id: 'streak_10', name: 'Imparable', desc: 'Consigue una racha de 10 entregas', reward: 150, check: (s, g) => g.bestStreak >= 10 },
  { id: 'bsod', name: 'Pantallazo azul', desc: 'Sobrevive a un pantallazo azul', reward: 10, check: (s) => s.bsods >= 1 },
];

export class AchievementsApp extends App {
  constructor(game) { super(game); this.unlocked = []; this.tab = 0; this.timer = 0; }
  get id() { return 'achievements'; }
  get title() { return 'Logros y Estadísticas'; }
  get icon() { return img('achievements'); }
  get size() { return { w: 440, h: 420 }; }

  update(dt) {
    const g = this.game;
    g.stats.playTime += dt;
    this.timer += dt;
    if (this.timer < 0.5) return;
    this.timer = 0;
    for (const a of ACHIEVEMENTS) {
      if (!this.unlocked.includes(a.id) && a.check(g.stats, g)) {
        this.unlocked.push(a.id);
        g.earn(a.reward, 'achievement');
        toast('¡LOGRO DESBLOQUEADO!', `${a.name} (+${money(a.reward)})`);
        play('ding', { volume: 0.4 });
      }
    }
  }

  onAction(a, d) { if (a === 'tab') this.tab = Number(d.i); }

  render() {
    const g = this.game;
    const s = g.stats;
    const t = Math.floor(s.playTime);
    return h`<div class="col grow" style="padding:6px">
      <div class="tabs">${['Logros', 'Estadísticas'].map((x, i) => h`<button class="tab ${this.tab === i ? 'active' : ''}" data-action="tab" data-i="${i}" data-silent>${x}</button>`)}</div>
      <div class="tab-panel grow col" style="min-height:0">
        ${this.tab === 0 ? h`
          <div class="mb4">Desbloqueados: <b>${this.unlocked.length}</b> de ${ACHIEVEMENTS.length}</div>
          <div class="list grow mt4">
            ${ACHIEVEMENTS.map((a) => {
              const ok = this.unlocked.includes(a.id);
              return h`<div class="row" style="padding:3px;${ok ? '' : 'color:#808080'}">
                <span style="width:18px">${ok ? '🏆' : '🔒'}</span><span class="grow"><b>${a.name}</b> — ${a.desc}</span><span class="${ok ? 'ok' : ''}">${money(a.reward)}</span></div>`;
            })}
          </div>` : h`
          <table class="grid" style="background:transparent">
            ${[
              ['Dinero actual', money(g.money)], ['Dinero ganado en total', money(g.totalEarned)],
              ['Encargos entregados', fmt(s.tasksCompleted)], ['Encargos Normal o más', fmt(s.projectsCompleted)],
              ['Encargos fracasados', fmt(s.projectsFailed)], ['Reputación', fmt(g.rep)], ['Mejor racha', fmt(g.bestStreak)], ['Mejoras compradas', fmt(s.upgradesPurchased)],
              ['Empleados contratados', fmt(s.employeesHired)], ['Apps publicadas', fmt(s.appsPublished)],
              ['Líneas de código escritas', fmt(s.linesTyped)], ['Correos eliminados', fmt(s.emailsDeleted)],
              ['Pantallazos azules', fmt(s.bsods)], ['Tiempo jugado', `${Math.floor(t / 3600)}h ${Math.floor((t % 3600) / 60)}m ${t % 60}s`],
            ].map(([k, v]) => h`<tr><td>${k}</td><td class="right bold">${v}</td></tr>`)}
          </table>`}
      </div>
    </div>`;
  }
  save() { return { unlocked: this.unlocked }; }
  load(d) { this.unlocked = d?.unlocked || []; }
}

// ----------------------------------------------------------------- Personal
export const STAFF = [
  { id: 'pasante', name: 'Pasante', desc: 'Estudiante universitario. Lento pero barato.', cost: 800, income: 0.2, mult: 1.25 },
  { id: 'tecnico', name: 'Técnico', desc: 'Técnico en computación. Rendimiento medio.', cost: 3000, income: 0.6, mult: 1.3 },
  { id: 'programador', name: 'Programador', desc: 'Programador experimentado. Buen rendimiento.', cost: 12000, income: 2, mult: 1.35 },
  { id: 'gerente', name: 'Gerente', desc: 'Gerente de proyecto. Genera mucho dinero.', cost: 40000, income: 6, mult: 1.4 },
  { id: 'director', name: 'Director', desc: 'Director ejecutivo. La élite del negocio.', cost: 120000, income: 15, mult: 1.45 },
];

export class StaffApp extends App {
  constructor(game) { super(game); this.count = Object.fromEntries(STAFF.map((s) => [s.id, 0])); this.timer = 0; this.msg = ''; }
  get id() { return 'personal'; }
  get title() { return 'Personal - Empleados'; }
  get icon() { return img('staff'); }
  get size() { return { w: 520, h: 330 }; }

  cost(s) { return Math.floor(s.cost * Math.pow(s.mult, this.count[s.id])); }
  income() { return STAFF.reduce((t, s) => t + this.count[s.id] * s.income, 0); }

  update(dt) {
    this.timer += dt;
    if (this.timer >= 1) {
      this.timer -= 1;
      this.acc = (this.acc || 0) + this.income(); // ingresos con decimales: se acumulan
      if (this.acc >= 1) { this.game.earn(Math.floor(this.acc), 'staff'); this.acc -= Math.floor(this.acc); }
    }
  }

  onAction(a, d) {
    if (a !== 'hire') return;
    const s = STAFF.find((x) => x.id === d.id);
    if (!this.game.spend(this.cost(s))) { this.msg = 'Dinero insuficiente.'; return; }
    this.count[s.id]++;
    this.game.stats.employeesHired++;
    this.msg = `${s.name} contratado.`;
    play('buy', { volume: 0.4 });
  }

  render() {
    const g = this.game;
    return h`<div class="col grow pad8 gap4">
      <div class="flex"><span class="grow">Ingreso pasivo: <b class="ok">$${this.income().toFixed(1)}/seg</b></span><span>Dinero: <b>${money(g.money)}</b></span></div>
      <div class="list grow" style="padding:0">
        <table class="grid">
          <tr><th>Empleado</th><th>Cant.</th><th>Genera</th><th>Costo</th><th></th></tr>
          ${STAFF.map((s) => {
            const c = this.cost(s);
            return h`<tr><td><b>${s.name}</b><br><small class="dim">${s.desc}</small></td><td class="mid">${this.count[s.id]}</td>
              <td class="nowrap">$${s.income}/s</td><td class="nowrap">${money(c)}</td>
              <td><button class="btn small" data-action="hire" data-id="${s.id}" ${g.money >= c ? '' : 'disabled'}>Contratar</button></td></tr>`;
          })}
        </table>
      </div>
      <div class="statusbar"><div>${this.msg || 'Contrate empleados para generar ingresos automáticamente.'}</div></div>
    </div>`;
  }
  save() { return { count: this.count }; }
  load(d) { if (d?.count) Object.assign(this.count, d.count); }
}
