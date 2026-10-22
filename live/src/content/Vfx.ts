// Efectos visuales en tiras de cuadros (carpeta VFX del juego Essentials).
// Si el paquete no trae efectos, todo cae a partículas dibujadas por el juego.

import Phaser from 'phaser';
import type { SpeciesPack } from './SpeciesPack';

/** Proyectil por tipo (el primero que exista en el paquete). */
const PROJECTILE: Record<string, string[]> = {
  NORMAL: ['VFX_NORMAL2_SHOT', 'VFX_NORMAL2'],
  FIRE: ['VFX_FIRE5', 'VFX_FIRE'],
  WATER: ['VFX_WATER2', 'VFX_WATER'],
  ELECTRIC: ['VFX_ELECTRIC_SHOT', 'VFX_ELECTRIC2_SHOT'],
  GRASS: ['VFX_GRASS', 'VFX_GRASS2'],
  ICE: ['VFX_ICE', 'VFX_ICE2'],
  FIGHTING: ['VFX_FIGHTING', 'VFX_FIGHTING2'],
  POISON: ['VFX_POISON'],
  GROUND: ['VFX_ROCK2', 'VFX_ROCK'],
  FLYING: ['VFX_FLYING'],
  PSYCHIC: ['VFX_PSYCHIC', 'VFX_PSYCHIC2'],
  BUG: ['VFX_BUG2', 'VFX_BUG'],
  ROCK: ['VFX_ROCK'],
  GHOST: ['VFX_GHOST'],
  DRAGON: ['VFX_DRAGON'],
  DARK: ['VFX_DARK'],
  STEEL: ['VFX_STEEL'],
  FAIRY: ['VFX_FAIRY2', 'VFX_FAIRY'],
};

export class Vfx {
  constructor(readonly pack: SpeciesPack) {}

  key(name: string) {
    return `vfx:${name}`;
  }

  has(name: string) {
    return !!this.pack.assets.vfx[name];
  }

  preload(load: Phaser.Loader.LoaderPlugin) {
    for (const [name, v] of Object.entries(this.pack.assets.vfx)) {
      load.spritesheet(this.key(name), this.pack.url(v.file), { frameWidth: v.fw, frameHeight: v.fh });
    }
  }

  createAnims(anims: Phaser.Animations.AnimationManager, textures: Phaser.Textures.TextureManager) {
    for (const [name, v] of Object.entries(this.pack.assets.vfx)) {
      const key = this.key(name);
      if (!textures.exists(key) || anims.exists(key)) continue;
      textures.get(key).setFilter(Phaser.Textures.FilterMode.NEAREST);
      anims.create({ key, frames: anims.generateFrameNumbers(key, { start: 0, end: v.frames - 1 }), frameRate: 16, repeat: 0 });
    }
  }

  projectileFor(type: string): string | null {
    return (PROJECTILE[type] ?? PROJECTILE.NORMAL).find((n) => this.has(n)) ?? null;
  }

  /** Reproduce un efecto una vez y lo destruye al terminar. */
  play(
    scene: Phaser.Scene,
    name: string,
    x: number,
    y: number,
    o: { scale?: number; tint?: number; depth?: number; rate?: number; repeat?: number; blend?: boolean } = {},
  ): Phaser.GameObjects.Sprite | null {
    if (!this.has(name) || !scene.anims.exists(this.key(name))) return null;
    const s = scene.add.sprite(x, y, this.key(name)).setScale(o.scale ?? 2).setDepth(o.depth ?? 4400);
    if (o.tint !== undefined) s.setTint(o.tint);
    if (o.blend) s.setBlendMode(Phaser.BlendModes.ADD);
    s.play({ key: this.key(name), frameRate: 16 * (o.rate ?? 1), repeat: o.repeat ?? 0 });
    s.once(Phaser.Animations.Events.ANIMATION_COMPLETE, () => s.destroy());
    return s;
  }
}
