// Capa siempre visible: mueve el director, cambia de escena según la fase y
// muestra capturas, entrenamientos y avisos encima de todo.

import Phaser from 'phaser';
import type { DirectorEvent, OverlayItem, Phase } from '../core/GameDirector';
import { RARITY_LABEL } from '../core/types';
import { RT } from '../runtime';
import { C, RARITY_COLOR, bar, hex, paper, ribbon, text, truncate } from '../ui/theme';
import { avatar, creature, orb, pill } from '../ui/widgets';

const SCENE_FOR: Record<Phase, string> = {
  lobby: 'lobby',
  'battle-intro': 'battle',
  battle: 'battle',
  result: 'result',
};

interface Toast {
  c: Phaser.GameObjects.Container;
  life: number;
}

export class OverlayScene extends Phaser.Scene {
  private queue: OverlayItem[] = [];
  private playing?: Phaser.GameObjects.Container;
  private toasts: Toast[] = [];
  private current = 'lobby';
  private lastTime = 0;

  constructor() {
    super('overlay');
  }

  create() {
    this.scene.bringToTop();
    RT.sprites.attachLoader(this.load);
    RT.director.on((e) => this.onDirector(e));
    RT.audio.bgmPlay('lobby');
  }

  private onDirector(e: DirectorEvent) {
    switch (e.type) {
      case 'phase': {
        const target = SCENE_FOR[e.phase];
        if (target !== this.current) {
          // launch (no start): start() detendría esta capa.
          this.scene.stop(this.current);
          this.scene.launch(target);
          this.scene.bringToTop();
          this.current = target;
        }
        if (e.phase !== 'lobby') this.cutPlaying();
        RT.audio.bgmPlay(e.phase === 'lobby' ? 'lobby' : e.phase === 'result' ? 'result' : 'battle');
        if (e.phase === 'lobby') RT.sprites.prune(RT.director.visibleSpecies());
        return;
      }
      case 'overlay':
        // Se piden ya los sprites para que estén listos cuando toque mostrarlo.
        RT.sprites.request(e.item.slug, e.item.shiny);
        if (e.item.kind === 'train') RT.sprites.request(e.item.fromSlug, e.item.shiny);
        this.queue.push(e.item);
        return;
      case 'toast':
        return this.toast(e.text, e.userId, e.tone);
      case 'gift':
        RT.audio.sfx('item', { gapMs: 400, volume: 0.5 });
        return this.toast(`${RT.store.get(e.userId)?.nickname ?? '?'} envió ${e.label} ×${e.count}`, e.userId, 'gift');
    }
  }

  update(time: number) {
    // Reloj real (no el delta suavizado de Phaser, que se recorta si bajan los FPS):
    // aunque el render vaya lento, las rondas duran lo que deben.
    const dt = this.lastTime ? Math.min(1, Math.max(0, (time - this.lastTime) / 1000)) : 0;
    this.lastTime = time;
    RT.director.update(dt);

    if (!this.playing && this.queue.length && RT.director.phase === 'lobby') {
      const item = this.queue.shift()!;
      this.playing = item.kind === 'capture' ? this.playCapture(item) : this.playTrain(item);
    }
    this.tweens.timeScale = this.queue.length > 2 ? 1.7 : 1;

    // avisos: suben y caducan
    for (let i = this.toasts.length - 1; i >= 0; i--) {
      const t = this.toasts[i];
      t.life -= dt;
      if (t.life <= 0) {
        this.toasts.splice(i, 1);
        this.tweens.add({ targets: t.c, alpha: 0, x: t.c.x - 40, duration: 220, onComplete: () => t.c.destroy() });
      }
    }
    const baseY = RT.director.phase === 'lobby' ? 330 : 360;
    this.toasts.forEach((t, i) => {
      const y = baseY + (this.toasts.length - 1 - i) * 66;
      t.c.y += (y - t.c.y) * 0.25;
    });
  }

  // ------------------------------------------------------------------ avisos
  private toast(str: string, userId?: string, tone: 'info' | 'good' | 'gift' | 'warn' = 'info') {
    const accent = { info: C.violet, good: C.green, gift: C.pink, warn: C.red }[tone];
    const c = this.add.container(40, 330).setDepth(9000);
    const t = this.add.text(userId ? 76 : 26, 0, truncate(str, 52), {
      fontFamily: '"Pixelify Sans", sans-serif',
      fontSize: '24px',
      fontStyle: 'bold',
      color: '#ffffff',
      padding: { x: 2, y: 2 },
    }).setOrigin(0, 0.5);
    const w = t.x + t.width + 24;
    const g = this.add.graphics();
    g.fillStyle(C.ink, 0.88).fillRoundedRect(0, -27, w, 54, 27);
    g.fillStyle(accent, 1).fillRoundedRect(0, -27, 12, 54, { tl: 27, bl: 27, tr: 0, br: 0 });
    c.add([g, t]);
    const p = userId ? RT.store.get(userId) : undefined;
    if (p) c.add(avatar(this, 42, 0, p, 40));
    c.setAlpha(0);
    this.tweens.add({ targets: c, alpha: 1, duration: 180 });
    this.toasts.push({ c, life: 3.6 });
    if (this.toasts.length > 5) {
      const old = this.toasts.shift()!;
      old.c.destroy();
    }
  }

  // ------------------------------------------------------------------ animaciones
  private cutPlaying() {
    if (!this.playing) return;
    const p = this.playing;
    this.playing = undefined;
    this.tweens.killTweensOf(p);
    this.tweens.add({ targets: p, alpha: 0, duration: 200, onComplete: () => p.destroy() });
  }

  private finish(c: Phaser.GameObjects.Container, delay: number) {
    this.time.delayedCall(delay / this.tweens.timeScale, () => {
      if (this.playing !== c) return;
      this.tweens.add({
        targets: c,
        alpha: 0,
        duration: 260,
        onComplete: () => {
          c.destroy();
          if (this.playing === c) this.playing = undefined;
        },
      });
    });
  }

  private frame(title: string, color: number, userId: string, chip: string) {
    const { width: W, height: H } = this.scale;
    const c = this.add.container(0, 0).setDepth(8000);
    const dim = this.add.rectangle(0, 0, W, H, 0x0b0714, 0.62).setOrigin(0);
    const g = this.add.graphics();
    paper(g, 90, 520, 900, 900, { r: 34 });
    g.fillStyle(0xf6e7c8, 1).fillRoundedRect(130, 600, 820, 560, 26);
    ribbon(g, 540, 528, 660, 96, color);
    c.add([dim, g, text(this, 540, 528, title, { size: 56, stroke: 10 })]);
    const p = RT.store.get(userId);
    if (p) {
      const pillG = this.add.graphics();
      pillG.fillStyle(C.ink, 1).fillRoundedRect(250, 1306, 580, 92, 46);
      pillG.fillStyle(0x3b2a55, 1).fillRoundedRect(256, 1312, 568, 80, 40);
      c.add(pillG);
      c.add(avatar(this, 300, 1352, p, 66, C.gold));
      c.add(text(this, 350, 1352, `de ${truncate(p.nickname, 16)}`, { size: 44, align: 'left' }));
    }
    c.add(pill(this, 540, 1200, chip, C.pink, { size: 28 }));
    c.setAlpha(0);
    this.tweens.add({ targets: c, alpha: 1, duration: 200 });
    return c;
  }

  private playCapture(it: Extract<OverlayItem, { kind: 'capture' }>) {
    const color = it.shiny ? 0xffd84a : RARITY_COLOR[it.rarity];
    const c = this.frame(it.shiny ? '¡CAPTURA SHINY!' : `¡CAPTURA ${RARITY_LABEL[it.rarity]}!`, color, it.userId, it.giftLabel);
    const sp = RT.pack.get(it.slug);
    RT.audio.sfx('throw');

    const o = orb(this, 540, 300, color, 78);
    c.add(o);
    const rays = this.add.graphics({ x: 540, y: 880 }).setAlpha(0);
    for (let i = 0; i < 16; i++) {
      const a = (i / 16) * Math.PI * 2;
      rays.fillStyle(i % 2 ? color : 0xffffff, 0.55);
      rays.slice(0, 0, 520, a, a + Math.PI / 16).fillPath();
    }
    const mon = creature(this, 540, 880, it.slug, { shiny: it.shiny, fit: { w: 380, h: 380 } }).setOrigin(0.5, 0.5);
    mon.mul = 0;
    const shadow = this.add.ellipse(540, 994, 260, 44, 0x000000, 0.15).setAlpha(0);
    const name = text(this, 540, 1090, it.shiny ? `✦ ${sp.name} ✦` : sp.name, { size: 64, color: it.shiny ? '#c98a00' : '#22162f' }).setAlpha(0);
    const lvl = text(this, 540, 650, `Nv. ${it.level}${it.extra ? `  ·  +${it.extra} más` : ''}`, { font: 'ui', size: 34, bold: true, color: hex(color) }).setAlpha(0);
    rays.setMask(this.make.graphics({}, false).fillRoundedRect(130, 600, 820, 560, 26).createGeometryMask());
    c.addAt(rays, 3);
    c.add([shadow, mon, name, lvl]);

    // caída, tres sacudidas y apertura (tiempos absolutos: más robusto que una cadena)
    const ts = () => this.tweens.timeScale;
    this.tweens.add({ targets: o, y: 880, duration: 520, ease: 'Bounce.easeOut', onComplete: () => RT.audio.sfx('ballDrop') });
    [-22, 22, -22].forEach((angle, i) => {
      this.tweens.add({ targets: o, angle, duration: 120, yoyo: true, delay: 760 + i * 480, onStart: () => RT.audio.sfx('ballShake') });
    });
    this.time.delayedCall(2250 / ts(), () => {
      if (this.playing !== c) return;
      this.cameras.main.flash(160, 255, 255, 255);
      this.tweens.add({ targets: o, scale: 1.35, alpha: 0, duration: 200 });
      this.tweens.add({ targets: rays, alpha: 1, duration: 200 });
      this.tweens.add({ targets: rays, angle: 90, duration: 3000 });
      this.tweens.add({ targets: mon, mul: 1, duration: 420, ease: 'Back.easeOut' });
      this.tweens.add({ targets: [shadow, name, lvl], alpha: 1, duration: 300, delay: 150 });
      RT.audio.sfx('ballClick');
      RT.audio.sfx('capture', { volume: 0.8 });
      this.time.delayedCall(350, () => RT.audio.cry(it.slug));
      if (it.shiny) {
        RT.audio.sfx('shiny');
        RT.vfx.play(this, 'VFX_LEVEL_UP_BURST', 540, 840, { scale: 2.6, depth: 8150 });
      }
      const burst = this.add
        .particles(540, 860, 'fx-star', {
          speed: { min: 200, max: 520 },
          lifespan: 900,
          scale: { start: 0.9, end: 0 },
          tint: [color, 0xffffff, 0xffcf3f],
          emitting: false,
        })
        .setDepth(8100);
      burst.explode(36);
      this.time.delayedCall(1200, () => burst.destroy());
    });
    this.finish(c, 4400);
    return c;
  }

  private playTrain(it: Extract<OverlayItem, { kind: 'train' }>) {
    const c = this.frame('¡ENTRENAMIENTO!', C.teal, it.userId, `${it.giftLabel} ×${it.count}`);
    // gimnasio
    const g = this.add.graphics();
    g.fillStyle(0xa8643c, 1).fillRect(130, 600, 820, 290);
    for (let x = 130; x < 950; x += 54) g.fillStyle(0x96552f, 1).fillRect(x, 600, 4, 290);
    g.fillStyle(0xcfe9ff, 1).fillRoundedRect(190, 636, 140, 110, 8).fillRoundedRect(750, 636, 140, 110, 8);
    g.lineStyle(8, 0x5e3620, 1).strokeRoundedRect(190, 636, 140, 110, 8).strokeRoundedRect(750, 636, 140, 110, 8);
    g.fillStyle(0xd99a5b, 1).fillRect(130, 890, 820, 150);
    for (let y = 906; y < 1040; y += 30) g.lineStyle(3, 0xbf7f43, 1).lineBetween(130, y, 950, y);
    g.fillStyle(0x2aa198, 1).fillRoundedRect(210, 930, 660, 90, 18);
    c.add(g);

    const bag = this.add.container(700, 600);
    const bg = this.add.graphics();
    bg.lineStyle(6, 0x3a3a3a, 1).lineBetween(0, 0, 0, 80);
    bg.fillStyle(C.ink, 1).fillRoundedRect(-50, 76, 100, 232, 40);
    bg.fillStyle(0xe0374b, 1).fillRoundedRect(-44, 82, 88, 220, 36);
    bg.fillStyle(0xffffff, 0.8).fillRect(-44, 124, 88, 12).fillRect(-44, 252, 88, 12);
    bag.add(bg);
    c.add(bag);

    const mon = creature(this, 430, 1010, it.fromSlug, { shiny: it.shiny, mode: 'walk', dir: 2, fit: { w: 220, h: 220 } }).setOrigin(0.5, 0.92);
    c.add(mon);

    const lvlText = text(this, 170, 1078, `Nv. ${it.fromLevel}`, { size: 40, color: '#22162f', align: 'left' });
    const plus = text(this, 910, 1078, `+${it.xp} EXP`, { size: 40, color: '#e0475b', align: 'right' });
    const b = this.add.graphics();
    c.add([lvlText, plus, b]);

    // golpes al saco
    const hits = 6;
    for (let i = 0; i < hits; i++) {
      this.time.delayedCall((300 + i * 360) / this.tweens.timeScale, () => {
        if (this.playing !== c) return;
        this.tweens.add({ targets: mon, x: 560, duration: 90, yoyo: true, ease: 'Quad.easeOut' });
        this.tweens.add({ targets: bag, angle: 16, duration: 140, yoyo: true, ease: 'Sine.easeOut', delay: 70 });
        RT.audio.sfx('hit', { gapMs: 100, volume: 0.45 });
        const t = text(this, 640 + Phaser.Math.Between(-30, 30), 780, `+${Math.max(1, Math.round(it.xp / hits))}`, { size: 40, color: '#ffcf3f', stroke: 8 });
        c.add(t);
        this.tweens.add({ targets: t, y: 700, alpha: 0, duration: 600, onComplete: () => t.destroy() });
      });
    }

    // barra de experiencia subiendo de nivel en nivel
    const levels = it.toLevel - it.fromLevel;
    const anim = { v: 0 };
    const total = levels + it.xpNow / it.xpNext;
    this.tweens.add({
      targets: anim,
      v: total,
      delay: 400,
      duration: 1900,
      ease: 'Cubic.easeOut',
      onUpdate: () => {
        const lv = it.fromLevel + Math.floor(anim.v);
        lvlText.setText(`Nv. ${Math.min(lv, it.toLevel)}`);
        b.clear();
        bar(b, 170, 1112, 740, 28, levels > 0 && anim.v >= levels ? it.xpNow / it.xpNext : anim.v % 1, C.teal);
      },
    });
    bar(b, 170, 1112, 740, 28, 0, C.teal);

    if (levels > 0) {
      this.time.delayedCall(2400 / this.tweens.timeScale, () => {
        if (this.playing !== c) return;
        const up = text(this, 540, 700, `¡SUBIÓ A NV. ${it.toLevel}!`, { size: 70, color: '#ffcf3f', stroke: 12 });
        c.add(up);
        up.setScale(0.3);
        this.tweens.add({ targets: up, scale: 1, duration: 320, ease: 'Back.easeOut' });
        RT.audio.sfx('levelUp');
        RT.vfx.play(this, 'VFX_LEVEL_UP_BURST', mon.x, mon.y - 100, { scale: 1.6, depth: 8150 });
        if (it.slug !== it.fromSlug) {
          this.cameras.main.flash(260, 255, 255, 255);
          RT.vfx.play(this, 'VFX_EVOLUTION', mon.x, mon.y - 100, { scale: 2.2, depth: 8150 });
          mon.setCreature(it.slug, it.shiny);
          mon.mode = 'idle';
          mon.dir = 0;
          RT.audio.sfx('evolution', { volume: 0.8 });
          this.time.delayedCall(500, () => RT.audio.cry(it.slug));
          up.setText(`¡EVOLUCIONÓ EN ${RT.pack.get(it.slug).name.toUpperCase()}!`).setFontSize(52);
        }
      });
    }
    this.finish(c, levels > 0 ? 4600 : 3600);
    return c;
  }
}
