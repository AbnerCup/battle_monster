// Qué hace cada regalo de TikTok en el juego. Es la parte que más va a ajustar
// cada streamer, así que está separada y luego puede venir del backend.
//
// Se compara por nombre (sin mayúsculas, en inglés o español) y, si se conoce,
// por giftId. Un regalo que no esté en la lista usa `fallback`.

import type { Rarity } from '../core/types';

export type GiftAction =
  | { kind: 'capture'; rarity: Rarity }
  /** XP para la criatura activa del que regala: xpPerCoin × monedas × cantidad. */
  | { kind: 'train'; xpPerCoin: number; minXp?: number }
  | { kind: 'shield'; seconds: number }
  /** Golpe inmediato a su objetivo: % de la vida máxima del objetivo. */
  | { kind: 'attack'; pct: number }
  | { kind: 'heal'; pct: number }
  | { kind: 'power'; pct: number; seconds: number };

export interface GiftRule {
  names: string[];
  ids?: number[];
  /** Nombre a mostrar en pantalla. */
  label: string;
  lobby?: GiftAction;
  battle?: GiftAction;
}

export const GIFT_RULES: GiftRule[] = [
  // Capturas por rareza
  { names: ['donut'], label: 'Donut', lobby: { kind: 'capture', rarity: 'comun' }, battle: { kind: 'capture', rarity: 'comun' } },
  { names: ['confetti', 'confeti'], label: 'Confeti', lobby: { kind: 'capture', rarity: 'raro' }, battle: { kind: 'capture', rarity: 'raro' } },
  { names: ['money gun', 'pistola de dinero'], label: 'Pistola de dinero', lobby: { kind: 'capture', rarity: 'especial' }, battle: { kind: 'capture', rarity: 'especial' } },

  // Poderes en batalla (en la sala dan XP)
  { names: ['sunglasses', 'gafas de sol'], label: 'Gafas de sol', lobby: { kind: 'train', xpPerCoin: 1 }, battle: { kind: 'shield', seconds: 5 } },
  { names: ['gg'], label: 'GG', lobby: { kind: 'train', xpPerCoin: 1, minXp: 10 }, battle: { kind: 'attack', pct: 0.12 } },
  { names: ['finger heart', 'corazón con dedos', 'corazon con dedos'], label: 'Corazón', lobby: { kind: 'train', xpPerCoin: 1, minXp: 10 }, battle: { kind: 'heal', pct: 0.2 } },
  { names: ['rose', 'rosa'], label: 'Rosa', lobby: { kind: 'train', xpPerCoin: 1, minXp: 10 }, battle: { kind: 'power', pct: 0.15, seconds: 6 } },
];

/** Cualquier otro regalo: entrena en la sala; en batalla cura y potencia según su valor. */
export const FALLBACK_RULE = {
  lobby: { kind: 'train', xpPerCoin: 1, minXp: 10 } as GiftAction,
  battle: (coins: number): GiftAction =>
    coins >= 30 ? { kind: 'power', pct: Math.min(1, 0.1 + coins / 500), seconds: 8 } : { kind: 'heal', pct: Math.min(0.3, 0.04 + coins * 0.02) },
};

const norm = (s: string) => s.trim().toLowerCase();

export function findRule(giftName: string, giftId?: number): GiftRule | undefined {
  const n = norm(giftName);
  return GIFT_RULES.find((r) => (giftId && r.ids?.includes(giftId)) || r.names.some((x) => norm(x) === n));
}

/** Nombre para mostrar de un regalo de TikTok. */
const DISPLAY: Record<string, string> = {
  'ice cream cone': 'Cono de helado',
  'paper crane': 'Grulla de papel',
  'perfume': 'Perfume',
  'heart me': 'Corazón',
  'tiktok': 'TikTok',
  coral: 'Coral',
};
export function giftLabel(giftName: string, giftId?: number): string {
  return findRule(giftName, giftId)?.label ?? DISPLAY[norm(giftName)] ?? giftName;
}

/** Leyenda de poderes de batalla para mostrar en pantalla. */
export function battleLegend(): { action: GiftAction['kind']; label: string }[] {
  const order: GiftAction['kind'][] = ['shield', 'attack', 'heal', 'power'];
  return order
    .map((k) => {
      const r = GIFT_RULES.find((x) => x.battle?.kind === k);
      return r ? { action: k, label: r.label } : null;
    })
    .filter((x): x is { action: GiftAction['kind']; label: string } => !!x);
}

export function captureLegend(): { rarity: Rarity; label: string }[] {
  return GIFT_RULES.filter((r) => r.lobby?.kind === 'capture').map((r) => ({
    rarity: (r.lobby as { rarity: Rarity }).rarity,
    label: r.label,
  }));
}
