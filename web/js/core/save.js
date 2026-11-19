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
    version: 2,
    timestamp: Date.now(),
    money: game.money,
    totalEarned: game.totalEarned,
    stats: game.stats,
    rep: game.rep,
    streak: game.streak,
    bestStreak: game.bestStreak,
    hw: game.hw,
    boxed: game.boxed,
    spares: game.spares,
    removed: game.removed,
    loose: game.loose,
    flags: game.flags,
    icons: game.unlockedIcons,
    pacing: game.pacing,
    apps,
  };
}

export function apply(game, data) {
  game.money = data.money || 0;
  game.totalEarned = data.totalEarned || 0;
  Object.assign(game.stats, data.stats || {});
  game.rep = data.rep || 0;
  game.streak = data.streak || 0;
  game.bestStreak = data.bestStreak || 0;
  Object.assign(game.hw, data.hw || {});
  game.boxed = data.boxed || {};
  game.spares = data.spares || [];
  game.removed = data.removed || {};
  game.loose = data.loose || {};
  game.flags = data.flags || {};
  game.unlockedIcons = data.icons || [];
  game.pacing = data.pacing || [];
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
