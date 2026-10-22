export type Rarity = 'comun' | 'raro' | 'especial';

export const RARITY_LABEL: Record<Rarity, string> = {
  comun: 'COMÚN',
  raro: 'RARO',
  especial: 'ESPECIAL',
};

export interface BaseStats {
  hp: number;
  atk: number;
  def: number;
  /** píxeles por segundo en la arena */
  spd: number;
  /** % de esquivar */
  dodge: number;
  /** alcance de ataque en píxeles */
  range: number;
}

/**
 * Cómo cortar una hoja de sprites.
 *  - dir8: 8 filas (abajo, abajo-der, der, arriba-der, arriba, arriba-izq, izq, abajo-izq) × N cuadros
 *  - dir4: charset de RPG Maker, 4 filas (abajo, izq, der, arriba) × 4 cuadros
 *  - static: un solo cuadro de frente (paquetes simples, p. ej. Tuxemon)
 */
export interface SheetLayout {
  file: string;
  kind: 'dir8' | 'dir4' | 'static';
  frames: number;
  fw: number;
  fh: number;
  /** solo static: recorte del cuadro de frente y de los iconos de menú */
  front?: [number, number, number, number];
  menu?: [number, number, number, number][];
}

export interface SpriteSet {
  walk: SheetLayout;
  idle?: SheetLayout | null;
  shiny?: { walk: SheetLayout; idle?: SheetLayout | null } | null;
  source?: string;
}

export interface Species {
  slug: string;
  name: string;
  dexId?: number;
  types: string[];
  stage: string;
  rarity: Rarity;
  shape?: string;
  bst?: number;
  legendary?: boolean;
  base: BaseStats;
  evolvesTo: { slug: string; level: number } | null;
  description?: string;
  credit: string;
  creditVerified: boolean;
  sprite: SpriteSet;
  cry?: string | null;
}

export interface Creature {
  id: string;
  slug: string;
  level: number;
  /** XP acumulada dentro del nivel actual */
  xp: number;
  caughtAt: number;
  shiny?: boolean;
}

export interface Player {
  userId: string;
  uniqueId: string;
  nickname: string;
  avatarUrl?: string;
  trainerLevel: number;
  trainerXp: number;
  creatures: Creature[];
  activeId: string;
  wins: number;
  kos: number;
  games: number;
  coins: number;
  firstSeen: number;
  lastSeen: number;
}
