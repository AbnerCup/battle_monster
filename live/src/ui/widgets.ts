import Phaser from 'phaser';
import { RT } from '../runtime';
import { CreatureSprite, type CreatureOpts } from './CreatureSprite';
import type { AvatarUser } from './avatars';
import { C, FONT_UI, TYPE_COLOR, hex } from './theme';

/** Foto de perfil circular con aro. */
export function avatar(scene: Phaser.Scene, x: number, y: number, user: AvatarUser, size: number, ring = C.white) {
  const c = scene.add.container(x, y);
  const g = scene.add.graphics();
  g.fillStyle(C.ink, 1).fillCircle(0, 0, size / 2 + 6);
  g.fillStyle(ring, 1).fillCircle(0, 0, size / 2 + 3);
  const img = scene.add.image(0, 0, RT.avatars.key(user)).setDisplaySize(size, size);
  c.add([g, img]);
  return c;
}

/** Criatura animada que encaja en una caja (reposo mirando a cámara por defecto). */
export function creature(scene: Phaser.Scene, x: number, y: number, slug: string, o: CreatureOpts = {}) {
  return new CreatureSprite(scene, x, y, slug, { mode: 'idle', ...o });
}

/** Etiqueta de tipo elemental. */
export function typeChip(scene: Phaser.Scene, x: number, y: number, type: string, size = 22) {
  const label = RT.pack.typeName(type).toUpperCase();
  const t = scene.add.text(0, 0, label, { fontFamily: FONT_UI, fontSize: `${size}px`, fontStyle: 'bold', color: '#ffffff', stroke: C.inkHex, strokeThickness: 4, padding: { x: 4, y: 2 } }).setOrigin(0.5);
  const w = t.width + 24;
  const h = size + 18;
  const g = scene.add.graphics();
  g.fillStyle(C.ink, 1).fillRoundedRect(-w / 2 - 3, -h / 2 - 3, w + 6, h + 6, (h + 6) / 2);
  g.fillStyle(TYPE_COLOR[type] ?? 0x999999, 1).fillRoundedRect(-w / 2, -h / 2, w, h, h / 2);
  const c = scene.add.container(x, y, [g, t]);
  c.setSize(w, h);
  return c;
}

/** Pastilla de texto con fondo. */
export function pill(scene: Phaser.Scene, x: number, y: number, label: string, fill: number, o: { size?: number; color?: string; pad?: number } = {}) {
  const size = o.size ?? 26;
  const t = scene.add.text(0, 0, label, { fontFamily: FONT_UI, fontSize: `${size}px`, fontStyle: 'bold', color: o.color ?? '#ffffff', padding: { x: 4, y: 2 } }).setOrigin(0.5);
  const w = t.width + (o.pad ?? 28);
  const h = size + 20;
  const g = scene.add.graphics();
  g.fillStyle(C.ink, 1).fillRoundedRect(-w / 2 - 4, -h / 2 - 4, w + 8, h + 8, (h + 8) / 2);
  g.fillStyle(fill, 1).fillRoundedRect(-w / 2, -h / 2, w, h, h / 2);
  const c = scene.add.container(x, y, [g, t]);
  c.setSize(w, h);
  return c;
}

/** Orbe Vórtice: el objeto de captura propio del juego. */
export function orb(scene: Phaser.Scene, x: number, y: number, color: number, r = 64) {
  const c = scene.add.container(x, y);
  const g = scene.add.graphics();
  // cuerpo
  g.fillStyle(C.ink, 1).fillCircle(0, 0, r + 6);
  g.fillStyle(color, 1).fillCircle(0, 0, r);
  g.fillStyle(C.paper, 1);
  g.slice(0, 0, r, Phaser.Math.DegToRad(200), Phaser.Math.DegToRad(340), true).fillPath();
  // espiral del vórtice
  g.lineStyle(r * 0.09, 0xffffff, 0.55);
  for (let i = 0; i < 3; i++) {
    g.beginPath();
    g.arc(0, 0, r * (0.35 + i * 0.18), Phaser.Math.DegToRad(i * 120), Phaser.Math.DegToRad(i * 120 + 150));
    g.strokePath();
  }
  // anillo central
  g.lineStyle(r * 0.12, C.ink, 1).strokeCircle(0, 0, r * 0.26);
  g.fillStyle(0xffffff, 1).fillCircle(0, 0, r * 0.2);
  g.fillStyle(color, 1).fillCircle(0, 0, r * 0.1);
  // brillo
  g.fillStyle(0xffffff, 0.45).fillEllipse(-r * 0.4, -r * 0.45, r * 0.45, r * 0.25);
  c.add(g);
  return c;
}

/** Corazón dibujado (para "TAP TAP"). */
export function heart(scene: Phaser.Scene, x: number, y: number, s: number, color = C.red) {
  const g = scene.add.graphics({ x, y });
  const draw = (col: number, k: number) => {
    g.fillStyle(col, 1);
    g.fillCircle(-s * 0.25 * k, -s * 0.1 * k, s * 0.28 * k);
    g.fillCircle(s * 0.25 * k, -s * 0.1 * k, s * 0.28 * k);
    g.fillTriangle(-s * 0.52 * k, -s * 0.02 * k, s * 0.52 * k, -s * 0.02 * k, 0, s * 0.5 * k);
  };
  draw(C.ink, 1.18);
  draw(color, 1);
  g.fillStyle(0xffffff, 0.5).fillCircle(-s * 0.3, -s * 0.18, s * 0.08);
  return g;
}

export const colorHex = hex;
