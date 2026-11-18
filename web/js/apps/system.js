// Mi PC (Propiedades del sistema) y Papelera de reciclaje.
import { App } from '../core/wm.js';
import { h, money } from '../core/dom.js';
import { img } from '../core/assets.js';
import { HW, HW_ORDER } from '../data/hardware.js';

export class MyPCApp extends App {
  constructor(game) { super(game); this.tab = 0; }
  get id() { return 'mypc'; }
  get title() { return 'Propiedades del sistema'; }
  get icon() { return img('mypc'); }
  get size() { return { w: 410, h: 430 }; }
  get canMaximize() { return false; }

  onAction(a, d) {
    if (a === 'tab') this.tab = Number(d.i);
    if (a === 'ok') this.game.wm.close(this.id);
  }

  render() {
    const tabs = ['General', 'Administrador de dispositivos', 'Rendimiento'];
    return h`<div class="col grow" style="padding:6px 6px 0">
      <div class="tabs">${tabs.map((t, i) => h`<button class="tab ${this.tab === i ? 'active' : ''}" data-action="tab" data-i="${i}" data-silent>${t}</button>`)}</div>
      <div class="tab-panel grow col">${[this.general, this.devices, this.performance][this.tab].call(this)}</div>
      <div class="flex gap4" style="justify-content:flex-end;padding:8px 0">
        <button class="btn default" data-action="ok">Aceptar</button><button class="btn" data-action="ok">Cancelar</button>
      </div>
    </div>`;
  }

  general() {
    const g = this.game;
    return h`<div class="flex gap8">
      <div class="center" style="width:110px;height:110px"><img src="${img('mypc')}" width="80" height="80"></div>
      <div class="grow" style="line-height:16px">
        <b>Sistema:</b><div style="padding-left:14px">Microsoft Windows 95<br>4.00.950</div>
        <div class="mt8"><b>Registrado a:</b></div><div style="padding-left:14px">Freelancer<br>Garaje Independiente<br>12345-OEM-0012345-67890</div>
        <div class="mt8"><b>Equipo:</b></div>
        <div style="padding-left:14px">${g.hwName('cpu')}<br>${g.hwName('ram')} de RAM<br>${g.hwName('display')}</div>
      </div>
    </div>
    <fieldset class="group mt8"><legend>Componentes</legend>
      ${HW_ORDER.map((k) => h`<div class="flex"><span style="width:110px">${HW[k].name}:</span><span class="grow">${g.hwName(k)}</span><span class="dim">Nv.${g.hw[k]}</span></div>`)}
    </fieldset>`;
  }

  devices() {
    const g = this.game;
    const tree = [
      ['Dispositivos del sistema', ['PC compatible con Intel', g.hwName('motherboard')]],
      ['Procesadores', [g.hwName('cpu')]],
      ['Unidades de disco', [`IDE DISK DRIVE (${g.hwName('disk')})`, 'Controlador de disquete estándar']],
      ['Adaptadores de pantalla', [g.hwName('display')]],
      ['Memoria', [g.hwName('ram')]],
      ['Refrigeración', [g.hwName('cooling')]],
      ['Fuente de poder', [`${g.hwName('psu')} (${g.totalWatts()}W en uso)`]],
      ['Teclado', ['Teclado estándar de 101/102 teclas']],
      ['Puertos (COM y LPT)', ['Puerto de comunicaciones (COM1)', 'Puerto de impresora (LPT1)']],
    ];
    return h`<div class="list grow" style="padding:4px;line-height:17px">
      <div>🖥 Equipo</div>
      ${tree.map(([cat, items]) => h`<div style="padding-left:12px">⊟ ${cat}</div>${items.map((it) => h`<div style="padding-left:34px">▪ ${it}</div>`)}`)}
    </div>`;
  }

  performance() {
    const g = this.game;
    const ramMB = parseInt(g.hwName('ram'), 10) || 16;
    const used = g.totalWatts(), cap = g.psuCapacity();
    const res = Math.max(20, 100 - Math.round(1200 / ramMB));
    return h`<fieldset class="group"><legend>Estado del rendimiento</legend>
      <div class="flex"><span style="width:150px">Memoria:</span><span>${ramMB} MB de RAM</span></div>
      <div class="flex"><span style="width:150px">Recursos del sistema:</span><span>${res}% libres</span></div>
      <div class="flex"><span style="width:150px">Sistema de archivos:</span><span>32 bits</span></div>
      <div class="flex"><span style="width:150px">Memoria virtual:</span><span>32 bits</span></div>
      <div class="flex"><span style="width:150px">Compresión de disco:</span><span>No instalada</span></div>
    </fieldset>
    <fieldset class="group"><legend>Consumo eléctrico</legend>
      <div class="progress ${used / cap > 0.85 ? 'bad' : used / cap > 0.6 ? 'warn' : 'ok'}"><div class="fill" style="width:${Math.min(100, (used / cap) * 100).toFixed(0)}%"></div></div>
      <div class="mt4">${used}W usados de ${cap}W disponibles</div>
    </fieldset>
    <fieldset class="group"><legend>Productividad</legend>
      <div class="flex"><span style="width:150px">Pago por tarea:</span><span>${money(g.taskReward())}</span></div>
      <div class="flex"><span style="width:150px">Velocidad de tareas:</span><span>x${(1.75 / g.taskTimeMult()).toFixed(2)}</span></div>
      <div class="flex"><span style="width:150px">Probabilidad de bug:</span><span>${(g.bugChance() * 100).toFixed(0)}%</span></div>
    </fieldset>
    <p class="ok">Su sistema está configurado para un rendimiento óptimo.</p>`;
  }
}

export class RecycleBinApp extends App {
  constructor(game) { super(game); this.items = []; this.sel = -1; }
  get id() { return 'recyclebin'; }
  get title() { return 'Papelera de reciclaje'; }
  get icon() { return img('recyclebin'); }
  get size() { return { w: 440, h: 300 }; }

  addItem(it) {
    this.items.unshift({ ...it, date: new Date().toLocaleDateString('es-CL') });
    if (this.items.length > 50) this.items.pop();
  }
  onAction(a, d) {
    if (a === 'sel') this.sel = Number(d.i);
    if (a === 'empty') { this.items = []; this.sel = -1; }
  }
  render() {
    return h`<div class="menubar"><span><u>A</u>rchivo</span><span><u>E</u>dición</span><span><u>V</u>er</span><span>Ay<u>u</u>da</span></div>
      <div class="list grow" style="padding:0">
        ${this.items.length ? h`<table class="grid">
          <tr><th>Nombre</th><th>Ubicación original</th><th>Fecha</th><th>Tipo</th></tr>
          ${this.items.map((it, i) => h`<tr class="${this.sel === i ? 'selected' : ''}" data-action="sel" data-i="${i}" data-silent>
            <td class="nowrap">✉ ${it.name}</td><td class="nowrap">${it.from || 'C:\\WINDOWS'}</td><td>${it.date}</td><td class="nowrap">${it.type}</td></tr>`)}
        </table>` : h`<div class="center grow dim" style="height:100%">La Papelera de reciclaje está vacía</div>`}
      </div>
      <div class="flex" style="padding:4px 2px;justify-content:flex-end"><button class="btn" data-action="empty" ${this.items.length ? '' : 'disabled'}>Vaciar Papelera</button></div>
      <div class="statusbar"><div>${this.items.length} objeto(s)</div></div>`;
  }
  save() { return { items: this.items }; }
  load(d) { this.items = d?.items || []; }
}
