// Guardado en localStorage: 3 ranuras manuales + autoguardado.
const KEY = (slot) => `gamevibestory_${slot}`;
export const SLOTS = [1, 2, 3];

export function serialize(game) {
  const apps = {};
  for (const [id, app] of game.wm.apps) {
    const d = app.save();
    if (d != null) apps[id] = d;
  }
  return {
    version: 1,
    timestamp: Date.now(),
    money: game.money,
    totalEarned: game.totalEarned,
    stats: game.stats,
    hw: game.hw,
    flags: game.flags,
    icons: game.unlockedIcons,
    apps,
  };
}

export function apply(game, data) {
  game.money = data.money || 0;
  game.totalEarned = data.totalEarned || 0;
  Object.assign(game.stats, data.stats || {});
  Object.assign(game.hw, data.hw || {});
  game.flags = data.flags || {};
  game.unlockedIcons = data.icons || [];
  for (const [id, d] of Object.entries(data.apps || {})) game.wm.get(id)?.load(d);
}

export function write(slot, game) {
  try { localStorage.setItem(KEY(slot), JSON.stringify(serialize(game))); return true; } catch { return false; }
}

export function read(slot) {
  try { const s = localStorage.getItem(KEY(slot)); return s ? JSON.parse(s) : null; } catch { return null; }
}

export function remove(slot) { try { localStorage.removeItem(KEY(slot)); } catch { /* sin almacenamiento */ } }

/** La partida más reciente entre las ranuras y el autoguardado. */
export function latest() {
  let best = null;
  for (const slot of ['auto', ...SLOTS]) {
    const d = read(slot);
    if (d && (!best || d.timestamp > best.timestamp)) best = d;
  }
  return best;
}
