// Simulación de la batalla, sin nada de Phaser. Determinista con la misma
// semilla: se puede probar en Node, repetir partidas o incluso correrla en un
// servidor más adelante. La escena solo dibuja lo que esta clase decide.

import type { BaseStats } from '../types';
import { Rng } from '../rng';

export interface FighterInit {
  id: string;
  seat: number;
  name: string;
  slug: string;
  shiny?: boolean;
  level: number;
  types: string[];
  stats: BaseStats;
}

export interface Fighter extends FighterInit {
  x: number;
  y: number;
  vx: number;
  vy: number;
  hp: number;
  maxHp: number;
  alive: boolean;
  targetId?: string;
  retargetT: number;
  atkCd: number;
  shieldT: number;
  powerPct: number;
  powerT: number;
  kos: number;
  damage: number;
  /** 0 mientras vive; luego 1, 2, 3… en orden de eliminación. */
  deathOrder: number;
  facing: 1 | -1;
  strafe: 1 | -1;
  lastHitBy?: string;
}

export type SimEvent =
  | { t: 'hit'; from: string; to: string; dmg: number; ranged: boolean; eff: number; crit: boolean }
  | { t: 'miss'; from: string; to: string; ranged: boolean }
  | { t: 'blocked'; from?: string; to: string }
  | { t: 'ko'; id: string; by?: string }
  | { t: 'heal'; id: string; amount: number }
  | { t: 'shield'; id: string; seconds: number }
  | { t: 'power'; id: string; pct: number }
  | { t: 'burst'; from: string; to: string; dmg: number }
  | { t: 'finalists'; ids: string[] }
  | { t: 'duel'; ids: string[] }
  | { t: 'sudden-death' }
  | { t: 'winner'; id: string };

export interface SimOptions {
  arena: { x: number; y: number; w: number; h: number };
  timeLimit: number;
  suddenDeath: number;
  seed?: number;
  typeMult?: (attacker: string[], defender: string[]) => number;
  /** Escala global de daño: más bajo = peleas más largas. */
  damageScale?: number;
}

const DT = 1 / 30;

export class BattleSim {
  readonly fighters: Fighter[];
  readonly byId = new Map<string, Fighter>();
  readonly rng: Rng;
  time = 0;
  done = false;
  winnerId?: string;
  private acc = 0;
  private deaths = 0;
  private announcedFinalists = false;
  private announcedDuel = false;
  private announcedSudden = false;
  readonly cx: number;
  readonly cy: number;
  private r0: number;
  private rMin: number;

  constructor(init: FighterInit[], readonly opts: SimOptions) {
    this.rng = new Rng(opts.seed);
    const { x, y, w, h } = opts.arena;
    this.cx = x + w / 2;
    this.cy = y + h / 2;
    this.r0 = Math.hypot(w, h) / 2 + 40;
    this.rMin = Math.min(w, h) * 0.2;

    const order = this.rng.shuffle([...init]);
    this.fighters = order.map((f, i) => {
      const a = (i / order.length) * Math.PI * 2 + this.rng.range(-0.1, 0.1);
      const ring = order.length > 10 && i % 2 ? 0.24 : 0.38;
      return {
        ...f,
        x: this.cx + Math.cos(a) * w * ring,
        y: this.cy + Math.sin(a) * h * ring * 0.92,
        vx: 0,
        vy: 0,
        hp: f.stats.hp,
        maxHp: f.stats.hp,
        alive: true,
        retargetT: 0,
        atkCd: this.rng.range(0.3, 1.2),
        shieldT: 0,
        powerPct: 0,
        powerT: 0,
        kos: 0,
        damage: 0,
        deathOrder: 0,
        facing: 1,
        strafe: this.rng.chance(0.5) ? 1 : -1,
      };
    });
    for (const f of this.fighters) this.byId.set(f.id, f);
  }

  get alive(): Fighter[] {
    return this.fighters.filter((f) => f.alive);
  }

  get zoneRadius(): number {
    const { timeLimit, suddenDeath } = this.opts;
    const grace = Math.min(8, timeLimit * 0.25);
    if (this.time < grace) return this.r0;
    if (this.time < timeLimit) {
      const k = (this.time - grace) / (timeLimit - grace);
      return this.r0 + (this.rMin - this.r0) * easeInOut(k);
    }
    const k = Math.min(1, (this.time - timeLimit) / suddenDeath);
    return this.rMin * (1 - k);
  }

  get timeLeft(): number {
    return Math.max(0, this.opts.timeLimit - this.time);
  }

  /** Avanza la simulación `dt` segundos (en pasos fijos) y devuelve lo que pasó. */
  step(dt: number): SimEvent[] {
    const out: SimEvent[] = [];
    if (this.done) return out;
    this.acc += Math.min(dt, 1);
    while (this.acc >= DT && !this.done) {
      this.acc -= DT;
      this.tick(out);
    }
    return out;
  }

  private tick(out: SimEvent[]) {
    this.time += DT;
    const { timeLimit, suddenDeath, arena } = this.opts;
    const zone = this.zoneRadius;
    const sudden = this.time >= timeLimit;
    if (sudden && !this.announcedSudden) {
      this.announcedSudden = true;
      out.push({ t: 'sudden-death' });
    }
    const alive = this.alive;

    for (const f of alive) {
      if (!f.alive) continue; // cayó antes en este mismo paso
      f.shieldT = Math.max(0, f.shieldT - DT);
      f.powerT = Math.max(0, f.powerT - DT);
      if (f.powerT === 0) f.powerPct = 0;
      f.atkCd -= DT;
      f.retargetT -= DT;

      let target = f.targetId ? this.byId.get(f.targetId) : undefined;
      if (!target || !target.alive || f.retargetT <= 0) {
        target = this.pickTarget(f, alive.filter((o) => o.alive));
        f.targetId = target?.id;
        f.retargetT = this.rng.range(1.5, 3);
      }

      // --- movimiento
      let dx = 0;
      let dy = 0;
      const toC = Math.hypot(f.x - this.cx, f.y - this.cy);
      if (toC > zone - 30) {
        dx = this.cx - f.x;
        dy = this.cy - f.y;
      } else if (target) {
        const tx = target.x - f.x;
        const ty = target.y - f.y;
        const d = Math.hypot(tx, ty) || 1;
        const range = f.stats.range;
        const ranged = range > 150;
        if (d > range * 0.9) {
          dx = tx / d;
          dy = ty / d;
        } else if (ranged && d < range * 0.5) {
          dx = -tx / d;
          dy = -ty / d;
        } else {
          dx = (-ty / d) * 0.35 * f.strafe;
          dy = (tx / d) * 0.35 * f.strafe;
        }
        f.facing = tx >= 0 ? 1 : -1;
      }
      // separación para que no se apilen
      for (const o of alive) {
        if (o === f || !o.alive) continue;
        const sx = f.x - o.x;
        const sy = f.y - o.y;
        const d2 = sx * sx + sy * sy;
        if (d2 > 0 && d2 < 70 * 70) {
          const d = Math.sqrt(d2);
          dx += (sx / d) * (1 - d / 70) * 1.4;
          dy += (sy / d) * (1 - d / 70) * 1.4;
        }
      }
      const len = Math.hypot(dx, dy);
      const sp = f.stats.spd;
      const wantX = len > 0 ? (dx / Math.max(1, len)) * sp : 0;
      const wantY = len > 0 ? (dy / Math.max(1, len)) * sp : 0;
      f.vx += (wantX - f.vx) * 0.18;
      f.vy += (wantY - f.vy) * 0.18;
      f.x = clamp(f.x + f.vx * DT, arena.x + 30, arena.x + arena.w - 30);
      f.y = clamp(f.y + f.vy * DT, arena.y + 40, arena.y + arena.h - 20);

      // --- ataque
      if (target && target.alive && f.atkCd <= 0) {
        const d = Math.hypot(target.x - f.x, target.y - f.y);
        if (d <= f.stats.range + 12) {
          f.atkCd = 1.55 - Math.min(0.7, f.stats.spd / 260) + this.rng.range(-0.1, 0.15);
          this.attack(f, target, out);
        }
      }

      // --- zona
      if (f.alive && toC > zone) {
        const rate = sudden ? 0.16 : 0.06;
        f.hp -= f.maxHp * rate * DT;
        if (f.hp <= 0) this.kill(f, undefined, out);
      }
    }

    this.checkPhase(out);

    const hardEnd = timeLimit + suddenDeath + 6;
    if (!this.done && this.time >= hardEnd) {
      const best = [...this.alive].sort((a, b) => b.hp / b.maxHp - a.hp / a.maxHp)[0];
      if (best) {
        for (const f of this.alive) if (f !== best) this.kill(f, undefined, out);
        this.finish(best, out);
      }
    }
  }

  private pickTarget(f: Fighter, alive: Fighter[]): Fighter | undefined {
    let best: Fighter | undefined;
    let bestScore = Infinity;
    for (const o of alive) {
      if (o === f) continue;
      const score = Math.hypot(o.x - f.x, o.y - f.y) * this.rng.range(0.75, 1.25);
      if (score < bestScore) {
        bestScore = score;
        best = o;
      }
    }
    return best;
  }

  private attack(f: Fighter, t: Fighter, out: SimEvent[]) {
    const ranged = f.stats.range > 150;
    if (t.shieldT > 0) {
      out.push({ t: 'blocked', from: f.id, to: t.id });
      return;
    }
    if (this.rng.chance(t.stats.dodge / 100)) {
      out.push({ t: 'miss', from: f.id, to: t.id, ranged });
      return;
    }
    const eff = this.opts.typeMult ? this.opts.typeMult(f.types, t.types) : 1;
    const crit = this.rng.chance(0.08);
    const raw = f.stats.atk * (1 + f.powerPct) * eff * this.rng.range(0.85, 1.15) * (crit ? 1.6 : 1);
    const dmg = Math.max(1, Math.round(raw * (50 / (50 + t.stats.def)) * (this.opts.damageScale ?? 0.6)));
    this.damage(f, t, dmg, out);
    out.push({ t: 'hit', from: f.id, to: t.id, dmg, ranged, eff, crit });
    if (t.hp <= 0) this.kill(t, f, out);
  }

  private damage(from: Fighter, to: Fighter, dmg: number, _out: SimEvent[]) {
    const real = Math.min(to.hp, dmg);
    to.hp -= dmg;
    to.lastHitBy = from.id;
    from.damage += real;
  }

  private kill(f: Fighter, by: Fighter | undefined, out: SimEvent[]) {
    if (!f.alive) return;
    f.alive = false;
    f.hp = 0;
    f.deathOrder = ++this.deaths;
    if (by) by.kos++;
    out.push({ t: 'ko', id: f.id, by: by?.id });
  }

  private checkPhase(out: SimEvent[]) {
    const alive = this.alive;
    const n = this.fighters.length;
    if (!this.announcedFinalists && n > 3 && alive.length === 3) {
      this.announcedFinalists = true;
      out.push({ t: 'finalists', ids: alive.map((f) => f.id) });
    }
    if (!this.announcedDuel && n > 2 && alive.length === 2) {
      this.announcedDuel = true;
      out.push({ t: 'duel', ids: alive.map((f) => f.id) });
    }
    if (alive.length === 1) this.finish(alive[0], out);
    else if (alive.length === 0 && !this.done) {
      // Murieron a la vez: gana el último en caer.
      const last = [...this.fighters].sort((a, b) => b.deathOrder - a.deathOrder)[0];
      last.alive = true;
      last.hp = 1;
      last.deathOrder = 0;
      this.deaths--;
      this.finish(last, out);
    }
  }

  private finish(w: Fighter, out: SimEvent[]) {
    if (this.done) return;
    this.done = true;
    this.winnerId = w.id;
    out.push({ t: 'winner', id: w.id });
  }

  // ------------------------------------------------------------ acciones del público
  private usable(id: string) {
    const f = this.byId.get(id);
    return !this.done && f && f.alive ? f : undefined;
  }

  shield(id: string, seconds: number): SimEvent | null {
    const f = this.usable(id);
    if (!f) return null;
    f.shieldT = Math.max(f.shieldT, seconds);
    return { t: 'shield', id, seconds };
  }

  heal(id: string, pct: number): SimEvent | null {
    const f = this.usable(id);
    if (!f) return null;
    const amount = Math.round(Math.min(f.maxHp - f.hp, f.maxHp * pct));
    f.hp += amount;
    return { t: 'heal', id, amount };
  }

  power(id: string, pct: number, seconds: number): SimEvent | null {
    const f = this.usable(id);
    if (!f) return null;
    f.powerPct = Math.min(2, f.powerPct + pct);
    f.powerT = Math.max(f.powerT, seconds);
    return { t: 'power', id, pct: f.powerPct };
  }

  /** Golpe especial regalado: daño directo a su objetivo (o al más cercano). */
  burst(id: string, pct: number): SimEvent[] {
    const f = this.usable(id);
    if (!f) return [];
    let t = f.targetId ? this.byId.get(f.targetId) : undefined;
    if (!t || !t.alive) t = this.pickTarget(f, this.alive);
    if (!t) return [];
    const out: SimEvent[] = [];
    if (t.shieldT > 0) {
      out.push({ t: 'blocked', from: f.id, to: t.id });
      return out;
    }
    const dmg = Math.max(1, Math.round(t.maxHp * pct));
    this.damage(f, t, dmg, out);
    out.push({ t: 'burst', from: f.id, to: t.id, dmg });
    if (t.hp <= 0) this.kill(t, f, out);
    this.checkPhase(out);
    return out;
  }

  /** Clasificación final: ganador primero, luego por orden inverso de eliminación. */
  placements(): Fighter[] {
    return [...this.fighters].sort((a, b) => {
      if (a.id === this.winnerId) return -1;
      if (b.id === this.winnerId) return 1;
      return b.deathOrder - a.deathOrder;
    });
  }
}

const clamp = (v: number, a: number, b: number) => Math.max(a, Math.min(b, v));
const easeInOut = (k: number) => (k < 0.5 ? 2 * k * k : 1 - Math.pow(-2 * k + 2, 2) / 2);
