import Phaser from 'phaser';
import type { Rarity } from '../core/types';

export const FONT_HEAD = '"Lilita One", "Arial Black", sans-serif';
export const FONT_UI = '"Pixelify Sans", "Trebuchet MS", sans-serif';

export const C = {
  ink: 0x22162f,
  inkHex: '#22162f',
  paper: 0xfff6e3,
  paper2: 0xf1e1c1,
  paperLine: 0xe2cfa6,
  night: 0x140d22,
  violet: 0x7b4dff,
  pink: 0xff4fa3,
  gold: 0xffcf3f,
  goldHex: '#ffcf3f',
  teal: 0x2ad1c9,
  red: 0xff5a5f,
  green: 0x5bd16b,
  white: 0xffffff,
  muted: 0x8c7fa6,
};

export const RARITY_COLOR: Record<Rarity, number> = {
  comun: 0x6cc24a,
  raro: 0x3ea6ff,
  especial: 0xffb300,
};

export const TYPE_COLOR: Record<string, number> = {
  fire: 0xff7a2f,
  water: 0x3ea6ff,
  wood: 0x52c25a,
  earth: 0xc58b4b,
  metal: 0xa9b4c2,
  sky: 0x8fd3ff,
  frost: 0xb6f0ff,
  lightning: 0xffd93d,
  venom: 0xb15cff,
  shadow: 0x6b4f8f,
  cosmic: 0xff6bd6,
  heroic: 0xffb84d,
  normal: 0xd8cfc0,
  // Tipos de Pokémon (paquete essentials)
  NORMAL: 0xc8c4b8,
  FIRE: 0xff7a2f,
  WATER: 0x3ea6ff,
  GRASS: 0x52c25a,
  ELECTRIC: 0xffd23f,
  ICE: 0x8fe3f2,
  FIGHTING: 0xd9483b,
  POISON: 0xb15cff,
  GROUND: 0xd8a24a,
  FLYING: 0x9db4ff,
  PSYCHIC: 0xff5d9e,
  BUG: 0x9bc23a,
  ROCK: 0xb8a038,
  GHOST: 0x7058a8,
  DRAGON: 0x7a5cff,
  DARK: 0x5b4a44,
  STEEL: 0xa9b4c2,
  FAIRY: 0xf4a7d6,
  SOUND: 0x6fd6c4,
  WOOD: 0x8f6b3e,
  STELLAR: 0x66c9ff,
  QMARKS: 0x68a090,
};

export const hex = (n: number) => '#' + n.toString(16).padStart(6, '0');

type TextOpts = {
  size?: number;
  color?: string;
  font?: 'head' | 'ui';
  stroke?: number;
  strokeColor?: string;
  align?: 'left' | 'center' | 'right';
  bold?: boolean;
  wrap?: number;
};

export function text(scene: Phaser.Scene, x: number, y: number, str: string, o: TextOpts = {}) {
  const t = scene.add.text(x, y, str, {
    fontFamily: o.font === 'ui' ? FONT_UI : FONT_HEAD,
    fontSize: `${o.size ?? 32}px`,
    fontStyle: o.bold ? 'bold' : 'normal',
    color: o.color ?? '#ffffff',
    stroke: o.strokeColor ?? C.inkHex,
    strokeThickness: o.stroke ?? 0,
    align: o.align ?? 'center',
    padding: { x: 6, y: 6 },
    wordWrap: o.wrap ? { width: o.wrap } : undefined,
  });
  t.setOrigin(o.align === 'left' ? 0 : o.align === 'right' ? 1 : 0.5, 0.5);
  return t;
}

/** Panel de papel con borde de tinta y sombra. */
export function paper(
  g: Phaser.GameObjects.Graphics,
  x: number,
  y: number,
  w: number,
  h: number,
  o: { r?: number; fill?: number; stroke?: number; line?: number; shadow?: number } = {},
) {
  const r = o.r ?? 22;
  if (o.shadow !== 0) {
    g.fillStyle(0x000000, 0.28);
    g.fillRoundedRect(x + 6, y + 10, w, h, r);
  }
  g.fillStyle(o.fill ?? C.paper, 1);
  g.fillRoundedRect(x, y, w, h, r);
  g.lineStyle(o.line ?? 6, o.stroke ?? C.ink, 1);
  g.strokeRoundedRect(x, y, w, h, r);
}

/** Cinta de título con puntas. */
export function ribbon(g: Phaser.GameObjects.Graphics, cx: number, cy: number, w: number, h: number, color: number) {
  const x = cx - w / 2;
  const y = cy - h / 2;
  const tail = h * 0.55;
  g.fillStyle(Phaser.Display.Color.ValueToColor(color).darken(25).color, 1);
  g.fillTriangle(x - tail, y + 10, x + 10, y + 10, x + 10, y + h + 10);
  g.fillTriangle(x - tail, y + h + 10, x + 10, y + 10, x + 10, y + h + 10);
  g.fillTriangle(x + w + tail, y + 10, x + w - 10, y + 10, x + w - 10, y + h + 10);
  g.fillTriangle(x + w + tail, y + h + 10, x + w - 10, y + 10, x + w - 10, y + h + 10);
  g.fillStyle(color, 1);
  g.fillRoundedRect(x, y, w, h, 12);
  g.lineStyle(6, C.ink, 1);
  g.strokeRoundedRect(x, y, w, h, 12);
}

export function bar(
  g: Phaser.GameObjects.Graphics,
  x: number,
  y: number,
  w: number,
  h: number,
  pct: number,
  color: number,
  bg = 0x3b2f4f,
) {
  const p = Phaser.Math.Clamp(pct, 0, 1);
  g.fillStyle(C.ink, 1);
  g.fillRoundedRect(x - 3, y - 3, w + 6, h + 6, (h + 6) / 2);
  g.fillStyle(bg, 1);
  g.fillRoundedRect(x, y, w, h, h / 2);
  if (p > 0) {
    g.fillStyle(color, 1);
    g.fillRoundedRect(x, y, Math.max(h, w * p), h, h / 2);
    g.fillStyle(0xffffff, 0.25);
    g.fillRoundedRect(x + 4, y + 2, Math.max(0, w * p - 8), h * 0.3, h * 0.15);
  }
}

export function truncate(s: string, n: number) {
  const chars = [...s];
  return chars.length > n ? chars.slice(0, n - 1).join('') + '…' : s;
}

export function hpColor(pct: number) {
  return pct > 0.5 ? 0x5bd16b : pct > 0.25 ? 0xffc93f : 0xff5a5f;
}
