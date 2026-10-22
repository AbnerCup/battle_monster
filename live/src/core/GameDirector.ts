// Director del juego: máquina de estados (sala → batalla → resultado → sala),
// reparto de eventos del live a acciones y cálculo de recompensas.
// No dibuja nada: las escenas leen su estado y escuchan sus eventos.

import { GAME } from '../config/game';
import { FALLBACK_RULE, findRule, giftLabel, type GiftAction } from '../config/giftRules';
import type { SpeciesPack } from '../content/SpeciesPack';
import type { LiveHub } from '../live/LiveHub';
import type { GiftEvent, LiveEvent, LiveUser } from '../live/types';
import { BattleSim, type FighterInit, type SimEvent } from './battle/BattleSim';
import { addCreatureXp, addTrainerXp, statsFor, trainerXpToNext, xpToNext } from './progression';
import type { PlayerStore } from './PlayerStore';
import { Rng } from './rng';
import type { Rarity } from './types';

export type Phase = 'lobby' | 'battle-intro' | 'battle' | 'result';

export interface RosterEntry {
  userId: string;
  seat: number;
  joinedAt: number;
  lastActive: number;
  /** Puntuación de interacción: likes, chat, monedas. Decide prioridad para pelear. */
  engaged: number;
  lastRound: number;
  likes: number;
}

export type OverlayItem =
  | {
      kind: 'capture';
      userId: string;
      slug: string;
      level: number;
      rarity: Rarity;
      shiny: boolean;
      giftLabel: string;
      extra: number;
    }
  | {
      kind: 'train';
      userId: string;
      slug: string;
      fromSlug: string;
      shiny: boolean;
      xp: number;
      fromLevel: number;
      toLevel: number;
      xpNow: number;
      xpNext: number;
      giftLabel: string;
      count: number;
    };

export interface PodiumEntry {
  userId: string;
  place: number;
  slug: string;
  shiny: boolean;
  creatureXp: number;
}

/** Rival controlado por el juego (no se guarda ni gana experiencia). */
export interface BotInfo {
  id: string;
  name: string;
  slug: string;
  level: number;
  shiny: boolean;
  seat: number;
}

/** Lo necesario para mostrar a alguien en pantalla, sea jugador o bot. */
export interface Person {
  userId: string;
  nickname: string;
  avatarUrl?: string;
  isBot: boolean;
}

export type PowerAction = 'shield' | 'attack' | 'heal' | 'power' | 'likeHeal';

export interface BattleReport {
  round: number;
  winnerId: string;
  slug: string;
  shiny: boolean;
  isBot: boolean;
  level: number;
  kos: number;
  damage: number;
  hpPct: number;
  creatureXp: number;
  trainerXp: number;
  trainerLevel: number;
  trainerXpNow: number;
  trainerXpNext: number;
  evolvedTo?: string;
  podium: PodiumEntry[];
  topFan?: { userId: string; score: number };
  fighters: number;
}

export type DirectorEvent =
  | { type: 'phase'; phase: Phase }
  | { type: 'roster' }
  | { type: 'overlay'; item: OverlayItem }
  | { type: 'toast'; text: string; userId?: string; tone?: 'info' | 'good' | 'gift' | 'warn' }
  | { type: 'gift'; userId: string; label: string; count: number; coins: number }
  | { type: 'sim'; ev: SimEvent }
  | { type: 'support'; fighterId: string; userId: string; total: number }
  | { type: 'power'; action: PowerAction; fighterId: string; userId: string; count: number }
  | { type: 'countdown'; n: number }
  | { type: 'result'; report: BattleReport };

type Listener = (e: DirectorEvent) => void;

export class GameDirector {
  phase: Phase = 'lobby';
  round = 0;
  viewers = 0;
  readonly roster = new Map<string, RosterEntry>();
  lobbyCountdown: number = GAME.lobby.countdownSec;
  sim?: BattleSim;
  introLeft = 0;
  resultLeft = 0;
  lastReport?: BattleReport;
  /** Pausa tras el último K.O. antes de pasar al resultado. */
  holdLeft = 0;
  private pendingResult?: BattleReport;
  /** fighterId → creatureId con la que entró a pelear */
  readonly fighterCreature = new Map<string, string>();
  /** fighterId → userIds que lo apoyan */
  readonly supporters = new Map<string, Set<string>>();
  private supportOf = new Map<string, string>();
  private contributions = new Map<string, Map<string, number>>();
  private battleLikes = new Map<string, number>();
  private supportCooldown = new Map<string, number>();
  private pendingOverlays: OverlayItem[] = [];
  private listeners = new Set<Listener>();
  private pruneT = 0;
  private lastIntroTick = -1;
  /** Bots de la ronda en curso. */
  readonly bots = new Map<string, BotInfo>();
  private rng = new Rng();

  constructor(
    readonly pack: SpeciesPack,
    readonly store: PlayerStore,
    hub?: LiveHub,
  ) {
    hub?.on((e) => this.handle(e));
  }

  on(cb: Listener): () => void {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }
  private emit(e: DirectorEvent) {
    this.listeners.forEach((cb) => cb(e));
  }

  /** Datos para mostrar a un jugador o bot. */
  person(id: string): Person {
    const p = this.store.get(id);
    if (p) return { userId: p.userId, nickname: p.nickname, avatarUrl: p.avatarUrl, isBot: false };
    const b = this.bots.get(id);
    return { userId: id, nickname: b?.name ?? '?', isBot: true };
  }

  /** Especies que se están mostrando (para no liberar sus sprites). */
  visibleSpecies(): Set<string> {
    const out = new Set<string>();
    for (const r of this.roster.values()) {
      const p = this.store.get(r.userId);
      if (p) out.add(this.store.active(p).slug);
    }
    for (const f of this.sim?.fighters ?? []) out.add(f.slug);
    for (const o of this.pendingOverlays) {
      out.add(o.slug);
      if (o.kind === 'train') out.add(o.fromSlug);
    }
    return out;
  }

  private canStart() {
    const n = this.roster.size;
    return n >= GAME.lobby.minPlayers && (n >= 2 || GAME.bots.enabled);
  }

  // ================================================================ ciclo
  update(dt: number) {
    this.pruneT -= dt;
    if (this.pruneT <= 0) {
      this.pruneT = 5;
      this.pruneIdle();
    }

    switch (this.phase) {
      case 'lobby':
        if (this.canStart()) {
          this.lobbyCountdown -= dt;
          if (this.lobbyCountdown <= 0) this.startBattle();
        } else {
          this.lobbyCountdown = GAME.lobby.countdownSec;
        }
        break;

      case 'battle-intro': {
        this.introLeft -= dt;
        const n = Math.ceil(this.introLeft);
        if (n !== this.lastIntroTick && n > 0) {
          this.lastIntroTick = n;
          this.emit({ type: 'countdown', n });
        }
        if (this.introLeft <= 0) {
          this.setPhase('battle');
          this.emit({ type: 'countdown', n: 0 });
        }
        break;
      }

      case 'battle': {
        if (!this.sim) return this.setPhase('lobby');
        if (this.pendingResult) {
          this.holdLeft -= dt;
          if (this.holdLeft <= 0) this.showResult();
          break;
        }
        for (const ev of this.sim.step(dt)) {
          this.emit({ type: 'sim', ev });
          if (ev.t === 'winner') this.finishBattle();
        }
        break;
      }

      case 'result':
        this.resultLeft -= dt;
        if (this.resultLeft <= 0) this.backToLobby();
        break;
    }
  }

  private setPhase(p: Phase) {
    this.phase = p;
    this.emit({ type: 'phase', phase: p });
  }

  /** Empieza la ronda ya (botón del panel de pruebas). */
  forceStart() {
    if (this.phase === 'lobby' && (this.roster.size >= 2 || (GAME.bots.enabled && this.roster.size >= 1))) this.startBattle();
  }

  /** Corta la batalla o el resultado y vuelve a la sala (panel de pruebas). */
  skipToLobby() {
    this.pendingResult = undefined;
    this.backToLobby();
  }

  backToLobby() {
    this.sim = undefined;
    this.lobbyCountdown = GAME.lobby.countdownSec;
    this.setPhase('lobby');
    const pending = this.pendingOverlays.splice(0);
    pending.forEach((item) => this.emit({ type: 'overlay', item }));
  }

  // ================================================================ sala
  rosterList(): RosterEntry[] {
    return [...this.roster.values()].sort((a, b) => a.seat - b.seat);
  }

  private join(userId: string, engaged = 0): RosterEntry {
    const now = Date.now();
    let r = this.roster.get(userId);
    if (r) {
      r.lastActive = now;
      r.engaged += engaged;
      return r;
    }
    if (this.roster.size >= GAME.lobby.maxRoster) this.evictOne();
    r = { userId, seat: this.freeSeat(), joinedAt: now, lastActive: now, engaged, lastRound: -1, likes: 0 };
    this.roster.set(userId, r);
    this.emit({ type: 'roster' });
    return r;
  }

  private freeSeat(): number {
    const used = new Set([...this.roster.values()].map((r) => r.seat));
    let s = 1;
    while (used.has(s)) s++;
    return s;
  }

  private evictOne() {
    const fighting = new Set(this.sim?.fighters.map((f) => f.id) ?? []);
    const victim = [...this.roster.values()]
      .filter((r) => !fighting.has(r.userId))
      .sort((a, b) => a.engaged - b.engaged || a.lastActive - b.lastActive)[0];
    if (victim) this.roster.delete(victim.userId);
  }

  private pruneIdle() {
    const limit = Date.now() - GAME.lobby.idleMinutes * 60_000;
    const fighting = new Set(this.sim?.fighters.map((f) => f.id) ?? []);
    let changed = false;
    for (const r of this.roster.values()) {
      if (r.lastActive < limit && !fighting.has(r.userId)) {
        this.roster.delete(r.userId);
        changed = true;
      }
    }
    if (changed) this.emit({ type: 'roster' });
  }

  seatOf(userId: string) {
    return this.roster.get(userId)?.seat ?? 0;
  }

  // ================================================================ eventos del live
  handle(e: LiveEvent) {
    if (e.type === 'viewers') {
      this.viewers = e.count;
      return;
    }
    const join = GAME.joinOn;
    const known = this.store.get(e.user.userId);
    const touch = (u: LiveUser) => this.store.ensure(u).player;

    switch (e.type) {
      case 'join':
        if (join.enter) {
          touch(e.user);
          this.join(e.user.userId);
        } else if (known) touch(e.user);
        return;

      case 'like': {
        touch(e.user);
        if (!join.like && !this.roster.has(e.user.userId)) return;
        const r = this.join(e.user.userId, e.count * 0.2);
        r.likes += e.count;
        if (this.inBattle) this.likeHeal(e.user.userId, e.count);
        return;
      }

      case 'chat':
        touch(e.user);
        return this.chat(e.user.userId, e.text.trim());

      case 'gift':
        touch(e.user);
        this.join(e.user.userId, e.coins * e.count);
        return this.gift(e);

      case 'follow':
      case 'share': {
        const p = touch(e.user);
        if (!(e.type === 'follow' ? join.follow : join.share)) return;
        this.join(e.user.userId, 5);
        const xp = e.type === 'follow' ? GAME.progression.followXp : GAME.progression.shareXp;
        addCreatureXp(this.store.active(p), xp, this.pack);
        this.store.scheduleSave();
        this.emit({
          type: 'toast',
          text: `${p.nickname} ${e.type === 'follow' ? 'te sigue' : 'compartió el live'} · +${xp} EXP`,
          userId: p.userId,
          tone: 'good',
        });
        return;
      }
    }
  }

  get inBattle() {
    return this.phase === 'battle' || this.phase === 'battle-intro';
  }

  private chat(userId: string, text: string) {
    const p = this.store.get(userId)!;
    const lower = text.toLowerCase();

    const mochila = lower.match(/^!(mochila|bag|cambiar)\s*(\d+)?/);
    if (mochila) {
      this.join(userId, 1);
      const c = this.store.switchActive(p, mochila[2] ? Number(mochila[2]) : undefined);
      const sp = this.pack.get(c.slug);
      const fighting = this.inBattle && this.sim?.byId.has(userId);
      this.emit({
        type: 'toast',
        text: `${p.nickname} eligió a ${sp.name} (Nv. ${c.level})${fighting ? ' · desde la próxima ronda' : ''}`,
        userId,
        tone: 'info',
      });
      this.emit({ type: 'roster' });
      return;
    }

    if (/^!(jugar|unirme|unir|play|join)\b/.test(lower)) {
      this.join(userId, 1);
      return;
    }

    const num = lower.match(/^#?\s*(\d{1,2})$/);
    if (num && this.inBattle && this.sim) {
      this.support(userId, Number(num[1]));
      return;
    }

    if (GAME.joinOn.chat) this.join(userId, 0.5);
    else this.roster.get(userId) && (this.roster.get(userId)!.lastActive = Date.now());
  }

  private support(userId: string, seat: number) {
    const sim = this.sim!;
    const target = sim.fighters.find((f) => f.alive && f.seat === seat);
    if (!target) return;
    this.setSupport(userId, target.id);
    this.contribute(target.id, userId, 1);
    const now = performance.now();
    if ((this.supportCooldown.get(userId) ?? 0) < now && this.phase === 'battle') {
      this.supportCooldown.set(userId, now + 2000);
      const ev = sim.heal(target.id, GAME.battle.supportHealPct);
      if (ev && ev.t === 'heal' && ev.amount > 0) this.emit({ type: 'sim', ev });
    }
  }

  private setSupport(userId: string, fighterId: string) {
    const prev = this.supportOf.get(userId);
    if (prev === fighterId) return;
    if (prev) this.supporters.get(prev)?.delete(userId);
    this.supportOf.set(userId, fighterId);
    let set = this.supporters.get(fighterId);
    if (!set) this.supporters.set(fighterId, (set = new Set()));
    set.add(userId);
    this.emit({ type: 'support', fighterId, userId, total: set.size });
  }

  private contribute(fighterId: string, userId: string, score: number) {
    let m = this.contributions.get(fighterId);
    if (!m) this.contributions.set(fighterId, (m = new Map()));
    m.set(userId, (m.get(userId) ?? 0) + score);
  }

  /** A quién afectan los poderes de este usuario: su criatura, la que apoya o una al azar. */
  private fighterFor(userId: string): string | undefined {
    const sim = this.sim;
    if (!sim) return undefined;
    const own = sim.byId.get(userId);
    if (own?.alive) return own.id;
    const sup = this.supportOf.get(userId);
    if (sup && sim.byId.get(sup)?.alive) return sup;
    const alive = sim.alive;
    if (!alive.length) return undefined;
    const pick = alive[Math.floor(Math.random() * alive.length)];
    this.setSupport(userId, pick.id);
    return pick.id;
  }

  private likeHeal(userId: string, count: number) {
    const total = (this.battleLikes.get(userId) ?? 0) + count;
    const per = GAME.battle.likesToHeal;
    const heals = Math.floor(total / per);
    this.battleLikes.set(userId, total % per);
    if (!heals || this.phase !== 'battle') return;
    const fid = this.fighterFor(userId);
    if (!fid) return;
    this.contribute(fid, userId, heals);
    const ev = this.sim!.heal(fid, GAME.battle.likeHealPct * heals);
    this.emit({ type: 'power', action: 'likeHeal', fighterId: fid, userId, count: heals });
    if (ev) this.emit({ type: 'sim', ev });
  }

  private gift(e: GiftEvent) {
    const p = this.store.get(e.user.userId)!;
    p.coins += e.coins * e.count;
    const rule = findRule(e.giftName, e.giftId);
    const label = giftLabel(e.giftName, e.giftId);
    this.emit({ type: 'gift', userId: p.userId, label, count: e.count, coins: e.coins });

    const action: GiftAction = this.inBattle
      ? rule?.battle ?? FALLBACK_RULE.battle(e.coins)
      : rule?.lobby ?? FALLBACK_RULE.lobby;

    switch (action.kind) {
      case 'capture':
        return this.capture(p.userId, action.rarity, label, e.count);
      case 'train':
        return this.train(p.userId, Math.max(action.minXp ?? 0, action.xpPerCoin * e.coins * e.count), label, e.count);
      default:
        return this.battlePower(p.userId, action, label, e.count, e.coins);
    }
  }

  private capture(userId: string, rarity: Rarity, label: string, count: number) {
    const p = this.store.get(userId)!;
    const n = Math.min(count, 10);
    const shown = Math.min(n, 3);
    for (let i = 0; i < n; i++) {
      const c = this.store.capture(p, rarity);
      if (i < shown) {
        const item: OverlayItem = {
          kind: 'capture',
          userId,
          slug: c.slug,
          level: c.level,
          rarity,
          shiny: !!c.shiny,
          giftLabel: label,
          extra: i === shown - 1 ? n - shown : 0,
        };
        if (this.phase === 'lobby') this.emit({ type: 'overlay', item });
        else this.pendingOverlays.push(item);
      }
    }
    if (this.phase !== 'lobby') {
      const poke = this.pack.noun === 'Pokémon';
      const what = n > 1 ? `${n} ${poke ? 'Pokémon' : 'criaturas'}` : poke ? 'un Pokémon' : 'una criatura';
      this.emit({ type: 'toast', text: `¡${p.nickname} capturó ${what}! Se verá al volver a la sala`, userId, tone: 'gift' });
    }
    this.emit({ type: 'roster' });
  }

  private train(userId: string, xp: number, label: string, count: number) {
    const p = this.store.get(userId)!;
    const c = this.store.active(p);
    const fromSlug = c.slug;
    const res = addCreatureXp(c, xp, this.pack);
    this.store.scheduleSave();
    const item: OverlayItem = {
      kind: 'train',
      userId,
      slug: c.slug,
      fromSlug,
      shiny: !!c.shiny,
      xp: Math.round(xp),
      fromLevel: res.fromLevel,
      toLevel: res.toLevel,
      xpNow: c.xp,
      xpNext: xpToNext(c.level),
      giftLabel: label,
      count,
    };
    if (this.phase === 'lobby') this.emit({ type: 'overlay', item });
    else this.emit({ type: 'toast', text: `${label} ×${count} · +${Math.round(xp)} EXP para ${p.nickname}`, userId, tone: 'gift' });
    this.emit({ type: 'roster' });
  }

  private battlePower(userId: string, a: GiftAction, label: string, count: number, coins: number) {
    if (!this.sim) {
      // Regla de batalla recibida fuera de batalla: se convierte en entrenamiento.
      return this.train(userId, Math.max(10, coins * count), label, count);
    }
    const fid = this.fighterFor(userId);
    if (!fid) return;
    this.contribute(fid, userId, coins * count + 1);
    const sim = this.sim;
    const evs: SimEvent[] = [];
    const push = (ev: SimEvent | null) => ev && evs.push(ev);
    switch (a.kind) {
      case 'shield':
        push(sim.shield(fid, Math.min(15, a.seconds + (count - 1))));
        break;
      case 'heal':
        push(sim.heal(fid, Math.min(1, a.pct * count)));
        break;
      case 'power':
        push(sim.power(fid, a.pct * count, a.seconds));
        break;
      case 'attack':
        if (this.phase !== 'battle') push(sim.power(fid, a.pct * count, 6)); // aún en cuenta regresiva
        else for (let i = 0; i < Math.min(count, 5); i++) evs.push(...sim.burst(fid, a.pct));
        break;
    }
    const seat = sim.byId.get(fid)?.seat ?? 0;
    const p = this.store.get(userId)!;
    const verb = { shield: 'Escudo', heal: 'Cura', power: 'Potencia', attack: 'Ataque' }[a.kind as 'shield'];
    this.emit({ type: 'power', action: a.kind as PowerAction, fighterId: fid, userId, count });
    this.emit({ type: 'toast', text: `${verb} para #${seat} · ${label} ×${count} de ${p.nickname}`, userId, tone: 'gift' });
    for (const ev of evs) {
      this.emit({ type: 'sim', ev });
      if (ev.t === 'winner') this.finishBattle();
    }
  }

  // ================================================================ batalla
  private startBattle() {
    const entries = [...this.roster.values()].sort(
      (a, b) =>
        Number(b.engaged > 0) - Number(a.engaged > 0) ||
        a.lastRound - b.lastRound ||
        b.engaged - a.engaged ||
        a.joinedAt - b.joinedAt,
    );
    const chosen = entries.slice(0, GAME.battle.maxFighters);
    const bots = GAME.bots.enabled ? Math.max(0, Math.min(GAME.battle.maxFighters, GAME.bots.minFighters) - chosen.length) : 0;
    if (chosen.length + bots < 2 || !chosen.length) return;
    this.round++;
    this.bots.clear();
    this.fighterCreature.clear();
    this.supporters.clear();
    this.supportOf.clear();
    this.contributions.clear();
    this.battleLikes.clear();

    const inits: FighterInit[] = chosen.map((r) => {
      r.lastRound = this.round;
      const p = this.store.get(r.userId)!;
      const c = this.store.active(p);
      this.fighterCreature.set(p.userId, c.id);
      const sp = this.pack.get(c.slug);
      return {
        id: p.userId,
        seat: r.seat,
        name: p.nickname,
        slug: c.slug,
        shiny: !!c.shiny,
        level: c.level,
        types: sp.types,
        stats: statsFor(c, this.pack),
      };
    });

    // Bots de relleno: nivel parecido al de los jugadores, asientos después del último.
    if (bots) {
      const avg = inits.reduce((a, f) => a + f.level, 0) / inits.length;
      let seat = Math.max(0, ...[...this.roster.values()].map((r) => r.seat));
      const names = this.rng.shuffle([...GAME.bots.names]);
      for (let i = 0; i < bots; i++) {
        const sp = this.rng.chance(0.75) ? this.pack.random('comun', this.rng) : this.pack.random('raro', this.rng);
        const level = Math.max(1, Math.round(avg * GAME.bots.levelFactor + this.rng.int(-2, 2)));
        const bot: BotInfo = { id: `bot:${this.round}:${i}`, name: names[i % names.length], slug: sp.slug, level, shiny: false, seat: ++seat };
        this.bots.set(bot.id, bot);
        const c = { id: bot.id, slug: sp.slug, level, xp: 0, caughtAt: 0 };
        inits.push({ id: bot.id, seat: bot.seat, name: bot.name, slug: sp.slug, shiny: false, level, types: sp.types, stats: statsFor(c, this.pack) });
      }
    }

    this.sim = new BattleSim(inits, {
      arena: GAME.battle.arena,
      timeLimit: GAME.battle.timeLimitSec,
      suddenDeath: GAME.battle.suddenDeathSec,
      typeMult: (a, d) => this.pack.typeMultiplier(a, d),
    });
    this.introLeft = GAME.battle.countdownSec;
    this.lastIntroTick = -1;
    this.setPhase('battle-intro');
  }

  private finishBattle() {
    const sim = this.sim;
    if (!sim || this.phase === 'result' || this.pendingResult || !sim.winnerId) return;
    const prog = GAME.progression;
    const placements = sim.placements();
    const n = placements.length;
    let report: BattleReport | undefined;
    const podium: PodiumEntry[] = [];

    placements.forEach((f, i) => {
      const place = i + 1;
      const p = this.store.get(f.id);
      const win = place === 1;
      if (!p) {
        // Bot: sin experiencia ni guardado, pero sí aparece en el resultado.
        if (win)
          report = {
            round: this.round, winnerId: f.id, slug: f.slug, shiny: false, isBot: true, level: f.level, kos: f.kos,
            damage: Math.round(f.damage), hpPct: Math.max(1, Math.round((f.hp / f.maxHp) * 100)), creatureXp: 0, trainerXp: 0,
            trainerLevel: 0, trainerXpNow: 0, trainerXpNext: 1, podium, fighters: n,
            topFan: this.topFan(f.id),
          };
        else if (place <= 3) podium.push({ userId: f.id, place, slug: f.slug, shiny: false, creatureXp: 0 });
        return;
      }
      const c = p.creatures.find((x) => x.id === this.fighterCreature.get(f.id)) ?? this.store.active(p);
      const cxp = prog.battleXp.participate + prog.battleXp.perKo * f.kos + (win ? prog.battleXp.win : 0) + prog.battleXp.perPlace * (n - place);
      const txp = prog.trainerXp.participate + prog.trainerXp.perKo * f.kos + (win ? prog.trainerXp.win : 0);
      const res = addCreatureXp(c, cxp, this.pack);
      addTrainerXp(p, txp);
      p.games++;
      p.kos += f.kos;
      if (win) p.wins++;

      if (win) {
        report = {
          round: this.round,
          winnerId: f.id,
          slug: c.slug,
          shiny: !!c.shiny,
          isBot: false,
          level: c.level,
          kos: f.kos,
          damage: Math.round(f.damage),
          hpPct: Math.max(1, Math.round((f.hp / f.maxHp) * 100)),
          creatureXp: cxp,
          trainerXp: txp,
          trainerLevel: p.trainerLevel,
          trainerXpNow: p.trainerXp,
          trainerXpNext: trainerXpToNext(p.trainerLevel),
          evolvedTo: res.evolvedTo,
          podium,
          topFan: this.topFan(f.id),
          fighters: n,
        };
      } else if (place <= 3) {
        podium.push({ userId: f.id, place, slug: c.slug, shiny: !!c.shiny, creatureXp: cxp });
      }
    });

    this.store.flush();
    if (!report) return this.backToLobby();
    this.lastReport = report;
    this.pendingResult = report;
    this.holdLeft = GAME.battle.endHoldSec;
  }

  private topFan(fighterId: string) {
    const fans = [...(this.contributions.get(fighterId) ?? new Map<string, number>()).entries()]
      .filter(([uid]) => uid !== fighterId && this.store.get(uid))
      .sort((a, b) => b[1] - a[1]);
    return fans[0] ? { userId: fans[0][0], score: fans[0][1] } : undefined;
  }

  private showResult() {
    const report = this.pendingResult;
    this.pendingResult = undefined;
    if (!report) return this.backToLobby();
    this.resultLeft = GAME.result.seconds;
    this.setPhase('result');
    this.emit({ type: 'result', report });
    this.emit({ type: 'roster' });
  }
}
