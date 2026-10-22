import { describe, expect, it } from 'vitest';
import { GAME } from '../src/config/game';
import { BattleSim, type FighterInit } from '../src/core/battle/BattleSim';
import { GameDirector, type DirectorEvent } from '../src/core/GameDirector';
import { MemoryRepository, PlayerStore } from '../src/core/PlayerStore';
import { addCreatureXp, statsFor, xpToNext } from '../src/core/progression';
import { Rng } from '../src/core/rng';
import { LiveHub } from '../src/live/LiveHub';
import { normalizeTikFinity } from '../src/live/normalize';
import { loadPack } from './helpers';

const pack = loadPack();

function fighters(n: number, rng = new Rng(7)): FighterInit[] {
  return Array.from({ length: n }, (_, i) => {
    const sp = pack.random('comun', rng);
    const c = { id: 'c' + i, slug: sp.slug, level: rng.int(1, 10), xp: 0, caughtAt: 0 };
    return { id: 'u' + i, seat: i + 1, name: 'P' + i, slug: sp.slug, level: c.level, types: sp.types, stats: statsFor(c, pack) };
  });
}

describe('paquete de criaturas', () => {
  it('tiene las tres rarezas y evoluciones válidas', () => {
    expect(pack.byRarity.comun.length).toBeGreaterThan(50);
    expect(pack.byRarity.raro.length).toBeGreaterThan(50);
    expect(pack.byRarity.especial.length).toBeGreaterThan(10);
    for (const s of pack.file.species) if (s.evolvesTo) expect(pack.bySlug.has(s.evolvesTo.slug)).toBe(true);
  });

  it('aplica ventajas de tipo', () => {
    expect(pack.typeMultiplier(['fire'], ['wood'])).toBe(2);
    expect(pack.typeMultiplier(['fire'], ['water'])).toBe(0.5);
    expect(pack.typeMultiplier([], ['water'])).toBe(1);
  });
});

describe('progresión', () => {
  it('sube de nivel y evoluciona', () => {
    const sp = pack.file.species.find((s) => s.evolvesTo)!;
    const c = { id: 'x', slug: sp.slug, level: sp.evolvesTo!.level - 1, xp: 0, caughtAt: 0 };
    const res = addCreatureXp(c, xpToNext(c.level) + 1, pack);
    expect(res.levelsGained).toBe(1);
    expect(res.evolvedTo).toBe(sp.evolvesTo!.slug);
    expect(c.slug).toBe(sp.evolvesTo!.slug);
  });
});

describe('BattleSim', () => {
  it('siempre termina con un único ganador', () => {
    for (let seed = 1; seed <= 25; seed++) {
      const sim = new BattleSim(fighters(20, new Rng(seed)), {
        arena: GAME.battle.arena,
        timeLimit: 30,
        suddenDeath: 12,
        seed,
        typeMult: (a, d) => pack.typeMultiplier(a, d),
      });
      let guard = 0;
      while (!sim.done && guard++ < 5000) sim.step(1 / 30);
      expect(sim.done).toBe(true);
      expect(sim.alive).toHaveLength(1);
      expect(sim.winnerId).toBe(sim.alive[0].id);
      expect(sim.time).toBeLessThan(30 + 12 + 7);
      const order = sim.placements();
      expect(order[0].id).toBe(sim.winnerId);
      expect(new Set(order.map((f) => f.id)).size).toBe(20);
    }
  });

  it('es determinista con la misma semilla', () => {
    const run = () => {
      const sim = new BattleSim(fighters(12), { arena: GAME.battle.arena, timeLimit: 30, suddenDeath: 12, seed: 42 });
      while (!sim.done) sim.step(1 / 30);
      return [sim.winnerId, sim.time.toFixed(3)];
    };
    expect(run()).toEqual(run());
  });

  it('el escudo bloquea el daño', () => {
    const sim = new BattleSim(fighters(2), { arena: GAME.battle.arena, timeLimit: 30, suddenDeath: 12, seed: 3 });
    const [a, b] = sim.fighters;
    sim.shield(b.id, 30);
    const evs = sim.burst(a.id, 0.5);
    expect(evs[0].t).toBe('blocked');
    expect(b.hp).toBe(b.maxHp);
  });
});

describe('GameDirector', () => {
  it('ciclo completo: entrar con likes, capturar, pelear, resultado y volver a la sala', async () => {
    GAME.bots.enabled = false;
    const hub = new LiveHub();
    const store = new PlayerStore(pack, new MemoryRepository(), new Rng(1));
    await store.init();
    const director = new GameDirector(pack, store, hub);
    const events: DirectorEvent[] = [];
    director.on((e) => events.push(e));
    const send = (event: string, data: Record<string, unknown>) => hub.push(normalizeTikFinity({ event, data }));

    for (let i = 0; i < 6; i++) send('like', { userId: 'u' + i, uniqueId: 'user' + i, nickname: 'User ' + i, likeCount: 3 });
    expect(director.roster.size).toBe(6);
    expect(director.rosterList().map((r) => r.seat)).toEqual([1, 2, 3, 4, 5, 6]);

    send('gift', { userId: 'u0', uniqueId: 'user0', nickname: 'User 0', giftId: 7168, giftName: 'Money Gun', diamondCount: 500, giftType: 2, repeatEnd: true, repeatCount: 1 });
    const p0 = store.get('u0')!;
    expect(p0.creatures).toHaveLength(2);
    expect(pack.get(store.active(p0).slug).rarity).toBe('especial');
    expect(events.some((e) => e.type === 'overlay' && e.item.kind === 'capture')).toBe(true);

    send('chat', { userId: 'u1', uniqueId: 'user1', nickname: 'User 1', comment: '!mochila' });
    send('gift', { userId: 'u2', uniqueId: 'user2', nickname: 'User 2', giftId: 1, giftName: 'Coral', diamondCount: 499, giftType: 1, repeatEnd: true, repeatCount: 3 });
    const train = events.find((e) => e.type === 'overlay' && e.item.kind === 'train');
    expect(train && train.type === 'overlay' && train.item.kind === 'train' && train.item.xp).toBe(1497);

    // cuenta regresiva de la sala → intro → batalla
    for (let t = 0; t < GAME.lobby.countdownSec + 1; t += 0.5) director.update(0.5);
    expect(director.phase).toBe('battle-intro');
    for (let t = 0; t < GAME.battle.countdownSec + 0.5; t += 0.5) director.update(0.5);
    expect(director.phase).toBe('battle');

    // apoyo y poderes durante la batalla
    send('chat', { userId: 'v1', uniqueId: 'viewer', nickname: 'Viewer', comment: '3' });
    expect(director.supporters.get('u2')?.has('v1')).toBe(true);
    send('gift', { userId: 'v1', uniqueId: 'viewer', nickname: 'Viewer', giftId: 2, giftName: 'Sunglasses', diamondCount: 199, giftType: 1, repeatEnd: true, repeatCount: 1 });
    expect(director.sim!.byId.get('u2')!.shieldT).toBeGreaterThan(0);

    let guard = 0;
    while (director.phase === 'battle' && guard++ < 3000) director.update(1 / 30);
    expect(director.phase).toBe('result');
    const report = director.lastReport!;
    expect(report.fighters).toBe(6);
    expect(store.get(report.winnerId)!.wins).toBe(1);
    expect(report.podium.map((p) => p.place)).toEqual([2, 3]);

    for (let t = 0; t < GAME.result.seconds + 1; t += 0.5) director.update(0.5);
    expect(director.phase).toBe('lobby');
    GAME.bots.enabled = true;
  });

  it('con un solo espectador completa la ronda con bots y no los guarda', async () => {
    GAME.bots.enabled = true;
    const hub = new LiveHub();
    const store = new PlayerStore(pack, new MemoryRepository(), new Rng(2));
    await store.init();
    const director = new GameDirector(pack, store, hub);
    hub.push(normalizeTikFinity({ event: 'like', data: { userId: 'solo', uniqueId: 'solo', nickname: 'Solo', likeCount: 1 } }));
    for (let t = 0; t < GAME.lobby.countdownSec + GAME.battle.countdownSec + 2; t += 0.5) director.update(0.5);
    expect(director.phase).toBe('battle');
    expect(director.sim!.fighters).toHaveLength(GAME.bots.minFighters);
    expect(director.bots.size).toBe(GAME.bots.minFighters - 1);
    const bot = [...director.bots.values()][0];
    expect(director.person(bot.id)).toMatchObject({ isBot: true, nickname: bot.name });
    let guard = 0;
    while (director.phase !== 'result' && guard++ < 4000) director.update(1 / 30);
    expect(director.phase).toBe('result');
    expect(store.players.size).toBe(1);
    expect(store.get('solo')!.games).toBe(1);
  });
});
