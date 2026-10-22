// Paquete de criaturas intercambiable. El juego no conoce ningún arte en concreto:
// lee public/packs/<id>/species.json + elements.json (+ assets.json opcional).
//
// Formatos admitidos:
//   1  hoja fija por especie (frente/espalda/menú), p. ej. Tuxemon
//   2  hojas animadas por especie (caminar, reposo, variocolor) en 8 o 4 direcciones,
//      generadas desde el juego Essentials con tools/import-essentials.mjs

import type { Rarity, SheetLayout, Species } from '../core/types';
import type { Rng } from '../core/rng';

export interface LegacySheet {
  front: [number, number, number, number];
  back: [number, number, number, number];
  menu: [number, number, number, number][];
}

export interface PackFile {
  id: string;
  name: string;
  license: string;
  source: string;
  format?: number;
  /** Cómo llamar a las criaturas en pantalla ("Pokémon", "criaturas"…). */
  noun?: string;
  sheet: LegacySheet | null;
  species: Species[];
}

export type ElementsFile = Record<string, { name: string; vs: Record<string, number> }>;

export interface VfxDef {
  file: string;
  frames: number;
  fw: number;
  fh: number;
}

export interface AssetsFile {
  vfx: Record<string, VfxDef>;
  backgrounds: { name: string; file: string; w: number; h: number }[];
  audio: { bgm: Record<string, string>; sfx: Record<string, string> };
}

export const EMPTY_ASSETS: AssetsFile = { vfx: {}, backgrounds: [], audio: { bgm: {}, sfx: {} } };

export class SpeciesPack {
  readonly bySlug = new Map<string, Species>();
  readonly byRarity: Record<Rarity, Species[]> = { comun: [], raro: [], especial: [] };
  /** Especies iniciales: comunes y sin preevolución. */
  readonly starters: Species[] = [];
  readonly assets: AssetsFile;

  constructor(
    readonly file: PackFile,
    readonly elements: ElementsFile,
    assets?: AssetsFile,
  ) {
    this.assets = assets ?? EMPTY_ASSETS;
    for (const s of file.species) {
      if (!s.sprite) s.sprite = { walk: legacyLayout(file, s.slug) };
      this.bySlug.set(s.slug, s);
      this.byRarity[s.rarity]?.push(s);
    }
    this.starters.push(...this.byRarity.comun.filter((s) => s.stage === 'basic' || s.stage === 'single'));
    if (!this.starters.length) this.starters.push(...this.byRarity.comun);
  }

  get id() {
    return this.file.id;
  }
  get base() {
    return `packs/${this.file.id}/`;
  }
  get noun() {
    return this.file.noun ?? 'criaturas';
  }
  get animated() {
    return (this.file.format ?? 1) >= 2;
  }

  get(slug: string): Species {
    return this.bySlug.get(slug) ?? this.file.species[0];
  }

  random(rarity: Rarity, rng: Rng): Species {
    const list = this.byRarity[rarity].length ? this.byRarity[rarity] : this.file.species;
    return rng.pick(list);
  }

  randomStarter(rng: Rng): Species {
    return rng.pick(this.starters.length ? this.starters : this.file.species);
  }

  hasShiny(slug: string) {
    return !!this.bySlug.get(slug)?.sprite.shiny;
  }

  typeName(t: string): string {
    return this.elements[t]?.name ?? t;
  }

  /** Multiplicador de daño de un atacante contra un defensor (el mejor tipo del atacante). */
  typeMultiplier(attacker: string[], defender: string[]): number {
    if (!attacker.length) return 1;
    let best = 0;
    for (const a of attacker) {
      let m = 1;
      for (const d of defender) m *= this.elements[a]?.vs?.[d] ?? 1;
      best = Math.max(best, m);
    }
    return Math.min(2, Math.max(0.5, best));
  }

  /** Clave de textura y URL de una hoja. */
  sheetKey(slug: string, anim: 'walk' | 'idle', shiny = false) {
    return `sp:${this.id}:${slug}:${anim}${shiny ? ':s' : ''}`;
  }

  sheet(slug: string, anim: 'walk' | 'idle', shiny = false): SheetLayout | null {
    const s = this.bySlug.get(slug);
    if (!s) return null;
    const set = shiny && s.sprite.shiny ? s.sprite.shiny : s.sprite;
    return anim === 'idle' ? set.idle ?? null : set.walk;
  }

  url(rel: string) {
    return this.base + rel;
  }
}

/** Formato 1: misma hoja para todas las especies, recortes fijos. */
function legacyLayout(file: PackFile, slug: string): SheetLayout {
  const sh = file.sheet ?? { front: [0, 0, 64, 64], back: [64, 0, 64, 64], menu: [] };
  return {
    file: `sprites/${slug}.png`,
    kind: 'static',
    frames: 1,
    fw: sh.front[2],
    fh: sh.front[3],
    front: sh.front,
    menu: sh.menu,
  };
}
