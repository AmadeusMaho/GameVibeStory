// Correo (estilo Microsoft Exchange de Windows 95). Portado de email.lua.
import { App } from '../core/wm.js';
import { h, money, rand, randInt } from '../core/dom.js';
import { play } from '../core/audio.js';
import { msgBox, toast } from '../core/ui.js';
import { img } from '../core/assets.js';
import { WELCOME, MALWARE_DESKTOP } from '../data/emails.js';

const ACTION_LABEL = { job: 'Enviar CV', malware: 'Descargar', beneficial: 'Cobrar', project: 'Aceptar', repair: 'Aceptar' };

export class EmailApp extends App {
  constructor(game) {
    super(game);
    this.inbox = [];
    this.selected = null;
    this.nextId = 1;
    this.chance = 0.015;
    this.bonus = 0;
    this.sinceLast = 0;
    this.cooldown = 0;
    this.pendingCV = 0;
    this.dayTimer = 0;
    this.malwareSent = false;
    this.add({ ...WELCOME }, { silent: true });
  }
  get id() { return 'email'; }
  get title() { return 'Bandeja de entrada - Microsoft Exchange'; }
  get icon() { return img('email'); }
  get size() { return { w: 620, h: 470 }; }

  unread() { return this.inbox.filter((e) => !e.read).length; }

  add(email, { silent = false } = {}) {
    const e = { read: false, handled: false, ...email, id: this.nextId++, date: this.clock() };
    if (e.type === 'project') e.days ??= 10;
    this.inbox.unshift(e);
    if (!this.selected) this.selected = e.id;
    if (!silent && this.game.state === 'desktop') {
      play('chimes', { volume: 0.5 });
      if (!this.game.wm.isVisible(this.id)) toast('Tiene correo nuevo', e.subject);
    }
    this.game.emit('mail');
    return e;
  }

  clock() {
    const d = new Date();
    return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/95 ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }

  // Los encargos normales salen en Trabajo; por correo llegan los VIP (los
  // manda Trabajo) y el malware a los 15 encargos.
  onTaskDone() {
    if (!this.malwareSent && this.game.stats.tasksCompleted >= 15) {
      this.malwareSent = true;
      this.add({ ...MALWARE_DESKTOP });
    }
  }

  update(dt) {
    if (this.cooldown > 0) this.cooldown -= dt;
    this.dayTimer += dt;
    if (this.dayTimer >= 60) {
      this.dayTimer -= 60;
      for (const e of this.inbox) if (e.type === 'project' && !e.handled) e.days--;
      this.inbox = this.inbox.filter((e) => !(e.type === 'project' && !e.handled && e.days <= 0));
    }
  }

  current() { return this.inbox.find((e) => e.id === this.selected) || null; }

  async onAction(action, d) {
    const g = this.game;
    const e = this.current();
    if (action === 'select') {
      this.selected = Number(d.id);
      const s = this.current();
      if (s) s.read = true;
      return;
    }
    if (!e) return;
    if (action === 'act' && !e.handled) {
      if (e.type === 'job') {
        e.handled = true;
        g.earn(e.reward * g.taskReward(), 'email');
        this.pendingCV++;
        g.stats.cvSent = (g.stats.cvSent || 0) + 1;
      } else if (e.type === 'beneficial') {
        e.handled = true;
        const amount = randInt(e.bonus[0], e.bonus[1]) * g.taskReward();
        g.earn(amount, 'email');
        msgBox({ title: 'Correo', icon: 'info', text: `Se depositaron ${money(amount)} en su cuenta.` });
      } else if (e.type === 'malware' && e.desktop) {
        e.handled = true;
        g.emit('malwareDesktop');
      } else if (e.type === 'malware') {
        e.handled = true;
        const lost = g.lose(g.money * e.loss);
        g.stats.scamsFallen = (g.stats.scamsFallen || 0) + 1;
        msgBox({ title: e.subject.slice(0, 30), icon: 'error', text: `Este programa ha realizado una operación no válida y se cerrará.\n\nSe perdieron ${money(lost)} de su cuenta.` });
      } else if (e.type === 'repair') {
        const why = g.apps.taller.accept(e.job);
        if (why) { msgBox({ title: 'Aviso', icon: 'warning', text: why }); return; }
        e.handled = true;
      } else if (e.type === 'project') {
        const why = g.apps.trabajo.accept(e.project);
        if (why) { msgBox({ title: 'Aviso', icon: 'warning', text: why }); return; }
        e.handled = true;
        g.wm.open('trabajo');
      }
    } else if (action === 'delete') {
      g.stats.emailsDeleted++;
      if (e.type === 'malware' && !e.handled) g.stats.malwareDeleted++;
      g.apps.recyclebin?.addItem({ name: e.subject, type: 'Mensaje de correo', from: e.from });
      const idx = this.inbox.indexOf(e);
      this.inbox.splice(idx, 1);
      const next = this.inbox[Math.min(idx, this.inbox.length - 1)];
      this.selected = next ? next.id : null;
      if (next) next.read = true;
    }
  }

  render() {
    const e = this.current();
    const label = e && ACTION_LABEL[e.type];
    return h`
      <div class="menubar"><span><u>A</u>rchivo</span><span><u>E</u>dición</span><span><u>V</u>er</span><span><u>H</u>erramientas</span><span><u>R</u>edactar</span><span>Ay<u>u</u>da</span></div>
      <div class="toolbar">
        <button class="tool" disabled>✉<br>Nuevo</button>
        <button class="tool" disabled>↩<br>Responder</button>
        <button class="tool" data-action="delete" ${e ? '' : 'disabled'}>✖<br>Eliminar</button>
        <div class="vsep"></div>
        <button class="tool" data-action="act" ${label && !e.handled ? '' : 'disabled'}>★<br>${label || 'Acción'}</button>
      </div>
      <div class="list" style="height:150px;flex:none;padding:0">
        <table class="grid">
          <tr><th style="width:18px">!</th><th style="width:170px">De</th><th>Asunto</th><th style="width:100px">Recibido</th></tr>
          ${this.inbox.map((m) => h`<tr class="${m.id === this.selected ? 'selected' : ''} clickable" data-action="select" data-id="${m.id}" data-silent style="${m.read ? '' : 'font-weight:bold'}">
            <td>${m.type === 'project' || m.type === 'repair' ? '!' : m.read ? '' : '✉'}</td><td class="nowrap">${m.from}</td><td class="nowrap">${m.subject}</td><td class="nowrap">${m.date}</td></tr>`)}
        </table>
      </div>
      ${e ? h`
        <div style="padding:6px 4px 4px">
          <div class="flex"><span style="width:60px">De:</span><b>${e.from}</b></div>
          <div class="flex"><span style="width:60px">Asunto:</span><span>${e.subject}</span></div>
          ${e.type === 'project' && !e.handled ? h`<div class="flex"><span style="width:60px">Vence:</span><span class="${e.days <= 3 ? 'bad' : ''}">en ${e.days} días</span></div>` : ''}
        </div>
        <div class="field grow" style="overflow:auto;white-space:pre-wrap;line-height:15px;font-family:'Courier New',monospace;font-size:12px">${e.body}</div>
        <div class="flex gap8" style="justify-content:flex-end;padding:6px 2px 2px">
          ${label ? h`<button class="btn default" data-action="act" ${e.handled ? 'disabled' : ''}>${e.handled ? 'Hecho' : label}</button>` : ''}
          <button class="btn" data-action="delete">Eliminar</button>
        </div>` : h`<div class="field grow center dim">No hay ningún mensaje seleccionado.</div>`}
      <div class="statusbar"><div>${this.inbox.length} mensajes, ${this.unread()} sin leer</div><div style="flex:0 0 140px">Conectado</div></div>`;
  }

  save() {
    return { inbox: this.inbox, nextId: this.nextId, pendingCV: this.pendingCV, malwareSent: this.malwareSent, selected: this.selected };
  }
  load(d) {
    if (!d) return;
    Object.assign(this, { inbox: d.inbox || [], nextId: d.nextId || 1, pendingCV: d.pendingCV || 0, malwareSent: !!d.malwareSent, selected: d.selected ?? null });
  }
}
