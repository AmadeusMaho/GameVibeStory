// Winamp: reproduce las canciones compradas. Mientras suena música, el
// freelancer trabaja más concentrado (+10% de pago por tarea).
import { App } from '../core/wm.js';
import { h } from '../core/dom.js';
import { createMusic, analyse } from '../core/audio.js';
import { img } from '../core/assets.js';

const fmtTime = (s) => (isFinite(s) ? `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}` : '0:00');

export class WinampApp extends App {
  constructor(game) {
    super(game);
    this.playlist = [];   // [{name, file}]
    this.track = 0;
    this.audio = null;
    this.analyser = null;
    this.volume = 0.7;
    this.shuffle = false;
    this.scroll = 0;
  }
  get id() { return 'winamp'; }
  get title() { return 'Winamp'; }
  get icon() { return img('winamp'); }
  get size() { return { w: 300, h: 300 }; }
  get canMaximize() { return false; }

  get playing() { return !!(this.audio && !this.audio.paused); }

  addSong(s) {
    if (this.playlist.some((p) => p.file === s.file)) return;
    this.playlist.push({ name: s.name, file: s.file });
  }

  ensureAudio() {
    if (this.audio) return;
    this.audio = createMusic(this.playlist[this.track].file);
    this.audio.volume = this.volume;
    this.audio.addEventListener('ended', () => this.next(true));
    this.analyser = analyse(this.audio);
  }

  loadTrack(i, autoplay) {
    if (!this.playlist.length) return;
    this.track = (i + this.playlist.length) % this.playlist.length;
    this.ensureAudio();
    this.audio.src = '../assets/sounds/' + this.playlist[this.track].file;
    if (autoplay) this.audio.play().catch(() => {});
  }

  next(auto = false) {
    if (!this.playlist.length) return;
    const n = this.shuffle ? Math.floor(Math.random() * this.playlist.length) : this.track + 1;
    this.loadTrack(n, auto || this.playing);
  }

  stop() { if (this.audio) { this.audio.pause(); this.audio.currentTime = 0; } }

  onClose() { this.stop(); }

  update() { this.game.musicOn = this.playing; this.scroll += 0.5; }

  onAction(a, d, e) {
    if (!this.playlist.length && a !== 'shuffle') return;
    switch (a) {
      case 'play':
        if (!this.audio) this.loadTrack(this.track, true);
        else if (this.audio.paused) this.audio.play().catch(() => {});
        else this.audio.pause();
        break;
      case 'stop': this.stop(); break;
      case 'prev':
        if (this.audio && this.audio.currentTime > 3) this.audio.currentTime = 0;
        else this.loadTrack(this.track - 1, this.playing);
        break;
      case 'next': this.next(); break;
      case 'shuffle': this.shuffle = !this.shuffle; break;
      case 'pick': this.loadTrack(Number(d.i), true); break;
      case 'seek': case 'vol': {
        const el = e.target.closest('[data-down]');
        const rect = el.getBoundingClientRect();
        const p = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
        if (a === 'seek' && this.audio && isFinite(this.audio.duration)) this.audio.currentTime = p * this.audio.duration;
        if (a === 'vol') { this.volume = p; if (this.audio) this.audio.volume = p; }
        break;
      }
    }
  }

  render() {
    const t = this.playlist[this.track];
    const name = t ? `${this.track + 1}. ${t.name}` : 'Winamp 1.0 - No hay canciones. Compra música en Internet Explorer.';
    const cur = this.audio ? this.audio.currentTime : 0;
    const dur = this.audio ? this.audio.duration : 0;
    const marquee = `${name}  ***  `;
    const off = Math.floor(this.scroll / 6) % marquee.length;
    const shown = (marquee + marquee).slice(off, off + 34);
    const btn = (a, label) => h`<button class="wa-btn" data-action="${a}" data-silent>${label}</button>`;
    return h`<div class="winamp grow col">
      <div class="wa-display">
        <div class="wa-left">
          <div class="wa-time">${this.playing ? '▶' : this.audio && cur > 0 ? '❚❚' : '■'} ${fmtTime(cur)}</div>
          <canvas class="wa-vis" width="76" height="20" data-keep></canvas>
        </div>
        <div class="wa-right">
          <div class="wa-title">${shown}</div>
          <div class="wa-info"><span>128</span> kbps <span>44</span> kHz ${this.game.musicOn ? h`<span class="wa-buff">+10% CONCENTRACIÓN</span>` : ''}</div>
        </div>
      </div>
      <div class="wa-seek" data-down="seek"><div style="width:${dur ? ((cur / dur) * 100).toFixed(1) : 0}%"></div></div>
      <div class="flex" style="align-items:center;gap:2px;padding:4px 0">
        ${btn('prev', '⏮')}${btn('play', this.playing ? '❚❚' : '▶')}${btn('stop', '■')}${btn('next', '⏭')}
        <button class="wa-btn ${this.shuffle ? 'on' : ''}" data-action="shuffle" data-silent style="width:52px;font-size:9px">SHUFFLE</button>
        <div class="wa-vol grow" data-down="vol"><div style="width:${(this.volume * 100).toFixed(0)}%"></div></div>
      </div>
      <div class="wa-playlist grow">
        ${this.playlist.length ? this.playlist.map((p, i) => h`<div class="${i === this.track ? 'cur' : ''}" data-dbl="pick" data-i="${i}">${i + 1}. ${p.name}</div>`) : h`<div class="dim">(lista vacía)</div>`}
      </div>
    </div>`;
  }

  afterRender(body) {
    const cv = body.querySelector('.wa-vis');
    if (!cv) return;
    const ctx = cv.getContext('2d');
    ctx.fillStyle = '#000'; ctx.fillRect(0, 0, 76, 20);
    if (!this.analyser || !this.playing) return;
    const data = new Uint8Array(this.analyser.frequencyBinCount);
    this.analyser.getByteFrequencyData(data);
    for (let i = 0; i < 19; i++) {
      const v = data[i] / 255;
      const hgt = Math.round(v * 19);
      for (let y = 0; y < hgt; y++) {
        ctx.fillStyle = y > 14 ? '#e03000' : y > 9 ? '#d0c000' : '#20c020';
        ctx.fillRect(i * 4, 19 - y, 3, 1);
      }
    }
  }

  save() { return { playlist: this.playlist, volume: this.volume, shuffle: this.shuffle }; }
  load(d) { if (!d) return; this.playlist = d.playlist || []; this.volume = d.volume ?? 0.7; this.shuffle = !!d.shuffle; }
}
