// Sprite de criatura que se anima solo (caminar, reposo o icono), cambia de
// dirección y se ajusta al tamaño pedido. Mientras su hoja se descarga muestra
// una silueta.

import Phaser from 'phaser';
import { RT } from '../runtime';
import { PLACEHOLDER, type SpriteMode } from '../content/Sprites';

export interface CreatureOpts {
  shiny?: boolean;
  mode?: SpriteMode;
  dir?: number;
  /** Encaja el cuadro en esta caja (manteniendo proporción). */
  fit?: { w: number; h: number };
  /** Escala fija en píxeles de pantalla por píxel de sprite. */
  scale?: number;
  /** Alto máximo en pantalla (para escala fija). */
  maxHeight?: number;
}

export class CreatureSprite extends Phaser.GameObjects.Sprite {
  slug: string;
  shiny: boolean;
  mode: SpriteMode;
  dir: number;
  fit?: { w: number; h: number };
  px?: number;
  maxHeight?: number;
  /** Multiplicador animable con tweens (0 → 1 para "aparecer"). */
  mul = 1;
  private phase = Math.random() * 1000;
  private base = 1;

  constructor(scene: Phaser.Scene, x: number, y: number, slug: string, o: CreatureOpts = {}) {
    super(scene, x, y, PLACEHOLDER);
    this.slug = slug;
    this.shiny = !!o.shiny;
    this.mode = o.mode ?? 'idle';
    this.dir = o.dir ?? 0;
    this.fit = o.fit;
    this.px = o.scale;
    this.maxHeight = o.maxHeight;
    RT.sprites.request(slug, this.shiny);
    scene.add.existing(this);
    this.refresh(scene.time.now);
  }

  setCreature(slug: string, shiny = false) {
    this.slug = slug;
    this.shiny = shiny;
    RT.sprites.request(slug, shiny);
    this.refresh(this.scene.time.now);
    return this;
  }

  /** Alto aproximado en pantalla del cuadro de caminar (para colocar etiquetas). */
  displayHeightOf() {
    const s = RT.sprites.size(this.slug);
    return s.h * this.scaleFor(s.w, s.h) * this.mul;
  }

  private scaleFor(w: number, h: number) {
    if (this.fit) {
      const s = Math.min(this.fit.w / w, this.fit.h / h);
      return s > 1 ? Math.floor(s * 2) / 2 : s; // múltiplos de 0,5: píxeles parejos
    }
    let s = this.px ?? 1;
    if (this.maxHeight) s = Math.min(s, this.maxHeight / h);
    return s;
  }

  preUpdate(time: number, delta: number) {
    super.preUpdate(time, delta);
    this.refresh(time);
  }

  refresh(time: number) {
    const ref = RT.sprites.frame(this.slug, this.shiny, this.mode, this.dir, time + this.phase);
    if (this.texture.key !== ref.key || this.frame.name !== ref.frame) this.setTexture(ref.key, ref.frame);
    if (this.flipX !== ref.flipX) this.setFlipX(ref.flipX);
    let base: number;
    if (ref.key === PLACEHOLDER) {
      const s = RT.sprites.size(this.slug);
      base = (this.scaleFor(s.w, s.h) * Math.min(s.w, s.h)) / 64;
    } else if (this.mode === 'icon' && !RT.pack.animated) {
      base = this.scaleFor(ref.w, ref.h); // iconos de menú pequeños de los paquetes simples
    } else {
      // Escala según el cuadro de caminar para que reposo y caminar midan igual.
      const s = RT.sprites.size(this.slug);
      base = this.scaleFor(s.w, s.h);
    }
    if (base !== this.base || this.scaleX !== base * this.mul) {
      this.base = base;
      this.setScale(base * this.mul);
    }
  }
}
