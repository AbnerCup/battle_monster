// Niveles, experiencia, estadísticas y evoluciones.

import { GAME } from '../config/game';
import type { SpeciesPack } from '../content/SpeciesPack';
import type { BaseStats, Creature, Player } from './types';

/** XP necesaria para pasar del nivel `level` al siguiente. */
export function xpToNext(level: number): number {
  return Math.round(20 + level * 8 + level * level * 0.6);
}

export function trainerXpToNext(level: number): number {
  return 100 + level * 50;
}

export interface XpResult {
  xp: number;
  levelsGained: number;
  fromLevel: number;
  toLevel: number;
  evolvedFrom?: string;
  evolvedTo?: string;
}

export function addCreatureXp(c: Creature, xp: number, pack: SpeciesPack): XpResult {
  const res: XpResult = { xp, levelsGained: 0, fromLevel: c.level, toLevel: c.level };
  const max = GAME.progression.maxLevel;
  c.xp += Math.max(0, Math.round(xp));
  while (c.level < max && c.xp >= xpToNext(c.level)) {
    c.xp -= xpToNext(c.level);
    c.level++;
    res.levelsGained++;
    const evo = pack.get(c.slug).evolvesTo;
    if (evo && c.level >= evo.level && pack.bySlug.has(evo.slug)) {
      res.evolvedFrom ??= c.slug;
      c.slug = evo.slug;
      res.evolvedTo = evo.slug;
    }
  }
  if (c.level >= max) c.xp = 0;
  res.toLevel = c.level;
  return res;
}

export function addTrainerXp(p: Player, xp: number): number {
  let gained = 0;
  p.trainerXp += Math.max(0, Math.round(xp));
  while (p.trainerXp >= trainerXpToNext(p.trainerLevel)) {
    p.trainerXp -= trainerXpToNext(p.trainerLevel);
    p.trainerLevel++;
    gained++;
  }
  return gained;
}

export function statsFor(c: Creature, pack: SpeciesPack): BaseStats {
  const b = pack.get(c.slug).base;
  const m = 1 + (c.level - 1) * GAME.progression.statPerLevel;
  return {
    hp: Math.round(b.hp * m),
    atk: Math.round(b.atk * m),
    def: Math.round(b.def * m),
    spd: Math.round(b.spd * (1 + (c.level - 1) * 0.004)),
    dodge: b.dodge,
    range: b.range,
  };
}
