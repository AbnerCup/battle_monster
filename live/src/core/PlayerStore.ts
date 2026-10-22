// Jugadores (espectadores) y su progreso. La persistencia va detrás de una
// interfaz: hoy localStorage, mañana la API del backend sin tocar el juego.

import { GAME } from '../config/game';
import type { SpeciesPack } from '../content/SpeciesPack';
import type { LiveUser } from '../live/types';
import { Rng } from './rng';
import type { Creature, Player, Rarity } from './types';

export interface PlayerRepository {
  load(): Promise<Player[]>;
  save(players: Player[]): Promise<void>;
  clear(): Promise<void>;
}

export class LocalStorageRepository implements PlayerRepository {
  constructor(private key = 'vortex.players.v1') {}
  async load(): Promise<Player[]> {
    try {
      const raw = localStorage.getItem(this.key);
      return raw ? (JSON.parse(raw) as Player[]) : [];
    } catch {
      return [];
    }
  }
  async save(players: Player[]) {
    try {
      localStorage.setItem(this.key, JSON.stringify(players));
    } catch {
      /* almacenamiento lleno o bloqueado: el juego sigue en memoria */
    }
  }
  async clear() {
    try {
      localStorage.removeItem(this.key);
    } catch {
      /* nada */
    }
  }
}

export class MemoryRepository implements PlayerRepository {
  data: Player[] = [];
  async load() {
    return structuredClone(this.data);
  }
  async save(p: Player[]) {
    this.data = structuredClone(p);
  }
  async clear() {
    this.data = [];
  }
}

let idSeq = 0;
const newId = () => `${Date.now().toString(36)}${(idSeq++).toString(36)}${Math.floor(Math.random() * 1e6).toString(36)}`;

export class PlayerStore {
  readonly players = new Map<string, Player>();
  private saveTimer?: ReturnType<typeof setTimeout>;

  constructor(
    private pack: SpeciesPack,
    private repo: PlayerRepository,
    private rng = new Rng(),
  ) {}

  async init() {
    for (const p of await this.repo.load()) {
      // Las especies pueden no existir si cambió el paquete: se reasignan.
      for (const c of p.creatures) if (!this.pack.bySlug.has(c.slug)) c.slug = this.pack.randomStarter(this.rng).slug;
      if (!p.creatures.length) this.giveStarter(p);
      this.players.set(p.userId, p);
    }
  }

  get(userId: string) {
    return this.players.get(userId);
  }

  /** Devuelve el jugador (creándolo con criatura inicial si es nuevo) y refresca sus datos. */
  ensure(u: LiveUser): { player: Player; isNew: boolean } {
    const now = Date.now();
    let p = this.players.get(u.userId);
    const isNew = !p;
    if (!p) {
      p = {
        userId: u.userId,
        uniqueId: u.uniqueId,
        nickname: u.nickname,
        avatarUrl: u.avatarUrl,
        trainerLevel: 1,
        trainerXp: 0,
        creatures: [],
        activeId: '',
        wins: 0,
        kos: 0,
        games: 0,
        coins: 0,
        firstSeen: now,
        lastSeen: now,
      };
      this.giveStarter(p);
      this.players.set(p.userId, p);
    } else {
      p.uniqueId = u.uniqueId || p.uniqueId;
      p.nickname = u.nickname || p.nickname;
      if (u.avatarUrl) p.avatarUrl = u.avatarUrl;
      p.lastSeen = now;
    }
    this.scheduleSave();
    return { player: p, isNew };
  }

  private giveStarter(p: Player) {
    const [a, b] = GAME.progression.starterLevel;
    const c = this.addCreature(p, this.pack.randomStarter(this.rng).slug, this.rng.int(a, b));
    p.activeId = c.id;
  }

  addCreature(p: Player, slug: string, level: number, shiny = false): Creature {
    const c: Creature = { id: newId(), slug, level, xp: 0, caughtAt: Date.now() };
    if (shiny) c.shiny = true;
    p.creatures.push(c);
    this.scheduleSave();
    return c;
  }

  capture(p: Player, rarity: Rarity): Creature {
    const [a, b] = GAME.progression.captureLevel[rarity];
    const sp = this.pack.random(rarity, this.rng);
    const shiny = this.pack.hasShiny(sp.slug) && this.rng.chance(GAME.progression.shinyChance[rarity]);
    const c = this.addCreature(p, sp.slug, this.rng.int(a, b), shiny);
    p.activeId = c.id; // la nueva captura pasa a ser la activa
    return c;
  }

  active(p: Player): Creature {
    return p.creatures.find((c) => c.id === p.activeId) ?? p.creatures[0];
  }

  /** !mochila → siguiente criatura; !mochila 3 → la tercera. */
  switchActive(p: Player, index?: number): Creature {
    if (!p.creatures.length) this.giveStarter(p);
    let i: number;
    if (index !== undefined && index >= 1 && index <= p.creatures.length) i = index - 1;
    else i = (p.creatures.findIndex((c) => c.id === p.activeId) + 1) % p.creatures.length;
    p.activeId = p.creatures[i].id;
    this.scheduleSave();
    return p.creatures[i];
  }

  scheduleSave() {
    clearTimeout(this.saveTimer);
    this.saveTimer = setTimeout(() => this.flush(), 800);
  }

  async flush() {
    clearTimeout(this.saveTimer);
    await this.repo.save([...this.players.values()]);
  }

  async reset() {
    this.players.clear();
    await this.repo.clear();
  }
}
