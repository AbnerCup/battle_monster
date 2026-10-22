import Phaser from 'phaser';
import { GAME } from '../config/game';
import { GIFT_RULES } from '../config/giftRules';
import type { BattleSim, Fighter, SimEvent } from '../core/battle/BattleSim';
import type { DirectorEvent, PowerAction } from '../core/GameDirector';
import { dir8FromVector } from '../content/Sprites';
import { RT } from '../runtime';
import { CreatureSprite } from '../ui/CreatureSprite';
import { C, FONT_HEAD, FONT_UI, TYPE_COLOR, bar, hpColor, paper, ribbon, text, truncate } from '../ui/theme';
import { avatar } from '../ui/widgets';

interface View {
  f: Fighter;
  root: Phaser.GameObjects.Container;
  body: Phaser.GameObjects.Container;
  sprite: CreatureSprite;
  aura: Phaser.GameObjects.Image;
  shield: Phaser.GameObjects.Graphics;
  hp: Phaser.GameObjects.Graphics;
  tag: Phaser.GameObjects.Container;
  lastHp: number;
  dead: boolean;
  headY: number;
}

interface PowerButton {
  action: PowerAction;
  count: number;
  label: Phaser.GameObjects.Text;
  box: Phaser.GameObjects.Container;
}

const A = GAME.battle.arena;

export class BattleScene extends Phaser.Scene {
  private sim!: BattleSim;
  private views = new Map<string, View>();
  private zone!: Phaser.GameObjects.Graphics;
  private timer!: Phaser.GameObjects.Text;
  private aliveText!: Phaser.GameObjects.Text;
  private finalists?: Phaser.GameObjects.Container;
  private supportTexts = new Map<string, Phaser.GameObjects.Text>();
  private buttons: PowerButton[] = [];
  private puff!: Phaser.GameObjects.Particles.ParticleEmitter;
  private sparks!: Phaser.GameObjects.Particles.ParticleEmitter;
  private offs: (() => void)[] = [];
  private enlarged = false;
  private lastZone = -1;
  private activeVfx = 0;

  constructor() {
    super('battle');
  }

  create() {
    const sim = RT.director.sim;
    if (!sim) return;
    this.sim = sim;
    this.views.clear();
    this.supportTexts.clear();
    this.buttons = [];
    this.finalists = undefined;
    this.enlarged = false;
    this.lastZone = -1;
    this.activeVfx = 0;

    this.drawArena();
    this.zone = this.add.graphics().setDepth(5);
    const mask = this.make.graphics({}, false).fillRoundedRect(A.x, A.y, A.w, A.h, 36).createGeometryMask();
    this.zone.setMask(mask);

    for (const f of sim.fighters) this.views.set(f.id, this.makeView(f));

    this.puff = this.add
      .particles(0, 0, 'fx-dot', {
        speed: { min: 80, max: 260 },
        lifespan: 520,
        scale: { start: 0.9, end: 0 },
        alpha: { start: 0.9, end: 0 },
        tint: [0xffffff, 0xd9ccff, 0xb6a6d9],
        emitting: false,
      })
      .setDepth(4000);
    this.sparks = this.add
      .particles(0, 0, 'fx-star', {
        speed: { min: 120, max: 360 },
        lifespan: 700,
        scale: { start: 0.7, end: 0 },
        rotate: { min: 0, max: 360 },
        tint: [0xffcf3f, 0xffffff, 0xff4fa3],
        emitting: false,
      })
      .setDepth(4000);

    this.drawHud();
    this.drawPowerButtons();

    this.offs.push(RT.director.on((e) => this.onDirector(e)));
    this.events.once('shutdown', () => {
      this.offs.forEach((f) => f());
      this.offs = [];
    });
    this.cameras.main.fadeIn(300, 0, 0, 0);
  }

  // ------------------------------------------------------------------ escenario
  private drawArena() {
    const { width: W, height: H } = this.scale;
    const g = this.add.graphics();
    g.fillGradientStyle(0x1b1230, 0x1b1230, 0x0d0a1a, 0x0d0a1a, 1).fillRect(0, 0, W, H);
    g.fillStyle(0x000000, 0.35).fillRoundedRect(A.x + 8, A.y + 14, A.w, A.h, 36);

    const bgs = RT.pack.assets.backgrounds.filter((b) => this.textures.exists(`bg:${b.name}`));
    if (bgs.length) {
      // Suelo del juego original (en mosaico, píxeles ×2), distinto en cada ronda.
      const bg = bgs[(RT.director.round - 1) % bgs.length];
      this.textures.get(`bg:${bg.name}`).setFilter(Phaser.Textures.FilterMode.NEAREST);
      const floor = this.add.tileSprite(A.x, A.y, A.w, A.h, `bg:${bg.name}`).setOrigin(0).setTileScale(2);
      floor.tilePositionX = (RT.director.round * 137) % bg.w;
      floor.setMask(this.make.graphics({}, false).fillRoundedRect(A.x, A.y, A.w, A.h, 36).createGeometryMask());
      const v = this.add.graphics();
      v.lineStyle(60, 0x000000, 0.16).strokeRoundedRect(A.x + 30, A.y + 30, A.w - 60, A.h - 60, 30);
    } else {
      this.proceduralFloor(g);
    }
    this.add.graphics().lineStyle(10, C.ink, 1).strokeRoundedRect(A.x, A.y, A.w, A.h, 36);
  }

  /** Suelo dibujado (paquetes sin fondos). */
  private proceduralFloor(g: Phaser.GameObjects.Graphics) {
    g.fillStyle(0x5aa84a, 1).fillRoundedRect(A.x, A.y, A.w, A.h, 36);
    const rng = new Phaser.Math.RandomDataGenerator([`arena${RT.director.round}`]);
    for (let i = 0; i < 60; i++) {
      g.fillStyle(rng.pick([0x67b955, 0x4f9a41, 0x72c25f]), 0.55);
      g.fillEllipse(A.x + rng.between(30, A.w - 30), A.y + rng.between(30, A.h - 30), rng.between(60, 180), rng.between(30, 90));
    }
    for (let i = 0; i < 140; i++) {
      const x = A.x + rng.between(20, A.w - 20);
      const y = A.y + rng.between(20, A.h - 20);
      g.fillStyle(rng.pick([0xffffff, 0xffe14f, 0xff8fb8, 0xb9a6ff]), 1).fillCircle(x, y, 5);
    }
  }

  private makeView(f: Fighter): View {
    const person = RT.director.person(f.id);
    const root = this.add.container(f.x, f.y);
    const body = this.add.container(0, 0);
    const shadow = this.add.ellipse(0, 2, 70, 20, 0x000000, 0.28);
    const aura = this.add.image(0, -50, 'fx-dot').setScale(4.2).setTint(0xff8a2a).setAlpha(0).setBlendMode(Phaser.BlendModes.ADD);
    const sprite = new CreatureSprite(this, 0, 0, f.slug, {
      shiny: f.shiny,
      mode: 'idle',
      scale: RT.pack.animated ? GAME.battle.spriteScale : 1.6,
      maxHeight: GAME.battle.spriteMaxHeight,
    }).setOrigin(0.5, 0.86);
    const headY = -Math.max(70, sprite.displayHeightOf() * 0.86) - 8;
    const shield = this.add.graphics();
    const r = Math.max(60, -headY * 0.62);
    shield.fillStyle(0x7fe8ff, 0.18).fillCircle(0, headY / 2, r);
    shield.lineStyle(6, 0x7fe8ff, 0.95).strokeCircle(0, headY / 2, r);
    shield.setVisible(false);
    body.add([aura, sprite, shield]);

    const hp = this.add.graphics();
    const tag = this.add.container(0, headY - 30);
    const badge = this.add.graphics();
    badge.fillStyle(C.ink, 1).fillCircle(-58, 0, 21);
    badge.fillStyle(person.isBot ? 0xb7a8d9 : C.gold, 1).fillCircle(-58, 0, 17);
    const seat = this.add.text(-58, 0, String(f.seat), { fontFamily: FONT_UI, fontSize: '20px', fontStyle: 'bold', color: '#22162f' }).setOrigin(0.5);
    const av = avatar(this, -24, 0, person, 34);
    const name = this.add
      .text(-2, 0, truncate(f.name, 9), { fontFamily: FONT_UI, fontSize: '22px', fontStyle: 'bold', color: f.shiny ? '#ffe36b' : '#ffffff', stroke: C.inkHex, strokeThickness: 6, padding: { x: 2, y: 2 } })
      .setOrigin(0, 0.5);
    tag.add([badge, seat, av, name]);
    root.add([shadow, body, hp, tag]);

    const v: View = { f, root, body, sprite, aura, shield, hp, tag, lastHp: -1, dead: false, headY };
    this.drawHp(v);
    return v;
  }

  private drawHp(v: View) {
    const pct = v.f.hp / v.f.maxHp;
    v.hp.clear();
    bar(v.hp, -46, v.headY - 6, 92, 10, pct, hpColor(pct));
    v.lastHp = v.f.hp;
  }

  private drawHud() {
    const g = this.add.graphics().setDepth(5000);
    paper(g, 40, 36, 190, 130, { fill: 0x2a1d40, stroke: C.ink });
    paper(g, 850, 36, 190, 130, { fill: 0x2a1d40, stroke: C.ink });
    paper(g, 254, 36, 572, 130, { fill: C.paper });
    this.timer = text(this, 135, 88, '30s', { size: 64, color: '#ffffff', stroke: 8 }).setDepth(5001);
    text(this, 135, 140, 'TIEMPO', { font: 'ui', size: 22, bold: true, color: '#b7a8d9' }).setDepth(5001);
    this.aliveText = text(this, 945, 88, '', { size: 58, color: '#ff8a8a', stroke: 8 }).setDepth(5001);
    text(this, 945, 140, 'VIVOS', { font: 'ui', size: 22, bold: true, color: '#b7a8d9' }).setDepth(5001);
    text(this, 540, 82, 'ESCRIBE EL #', { size: 48, color: '#7b4dff' }).setDepth(5001);
    text(this, 540, 132, 'de un luchador para apoyarlo', { font: 'ui', size: 26, bold: true, color: '#5a4a6e' }).setDepth(5001);
    text(this, 540, 1790, `Ronda ${RT.director.round}`, { font: 'ui', size: 26, bold: true, color: '#8c7fa6' }).setDepth(5001);
  }

  /** Botones laterales como en los lives de referencia: qué regalo hace qué, con contador. */
  private drawPowerButtons() {
    const giftOf = (kind: string) => GIFT_RULES.find((r) => r.battle?.kind === kind)?.label ?? '';
    const defs: { action: PowerAction; name: string; gift: string; color: number; x: number; y: number }[] = [
      { action: 'shield', name: 'ESCUDO', gift: giftOf('shield'), color: 0x2ad1c9, x: 75, y: 760 },
      { action: 'attack', name: 'ATAQUE', gift: giftOf('attack'), color: 0xff5a5f, x: 75, y: 930 },
      { action: 'heal', name: 'CURA', gift: giftOf('heal'), color: 0x5bd16b, x: 75, y: 1100 },
      { action: 'likeHeal', name: 'CURA', gift: `${GAME.battle.likesToHeal} TAPs`, color: 0xff6b9a, x: 1005, y: 845 },
      { action: 'power', name: 'POTENCIA', gift: giftOf('power'), color: 0xff9f2a, x: 1005, y: 1015 },
    ];
    for (const d of defs) {
      const c = this.add.container(d.x, d.y).setDepth(5000);
      const g = this.add.graphics();
      g.fillStyle(C.ink, 1).fillRoundedRect(-66, -74, 132, 148, 24);
      g.fillStyle(d.color, 1).fillRoundedRect(-60, -68, 120, 136, 20);
      g.fillStyle(0xffffff, 0.22).fillRoundedRect(-54, -62, 108, 40, 16);
      this.drawPowerIcon(g, d.action, 0, -24);
      const name = this.add.text(0, 22, d.name, { fontFamily: FONT_HEAD, fontSize: d.name.length > 6 ? '20px' : '24px', color: '#ffffff', stroke: C.inkHex, strokeThickness: 5 }).setOrigin(0.5);
      const gift = this.add.text(0, 50, truncate(d.gift, 11), { fontFamily: FONT_UI, fontSize: '17px', fontStyle: 'bold', color: '#22162f' }).setOrigin(0.5);
      const badge = this.add.text(46, -66, '×0', { fontFamily: FONT_UI, fontSize: '20px', fontStyle: 'bold', color: '#ffffff', backgroundColor: '#22162f', padding: { x: 6, y: 2 } }).setOrigin(0.5);
      c.add([g, name, gift, badge]);
      this.buttons.push({ action: d.action, count: 0, label: badge, box: c });
    }
  }

  private drawPowerIcon(g: Phaser.GameObjects.Graphics, action: PowerAction, x: number, y: number) {
    g.fillStyle(0xffffff, 1);
    g.lineStyle(4, C.ink, 1);
    switch (action) {
      case 'shield':
        g.fillPoints([new Phaser.Math.Vector2(x - 20, y - 22), new Phaser.Math.Vector2(x + 20, y - 22), new Phaser.Math.Vector2(x + 20, y), new Phaser.Math.Vector2(x, y + 24), new Phaser.Math.Vector2(x - 20, y)], true);
        break;
      case 'attack':
        g.fillPoints([new Phaser.Math.Vector2(x - 22, y + 20), new Phaser.Math.Vector2(x + 14, y - 22), new Phaser.Math.Vector2(x + 22, y - 14), new Phaser.Math.Vector2(x - 14, y + 26)], true);
        g.fillPoints([new Phaser.Math.Vector2(x + 22, y + 20), new Phaser.Math.Vector2(x - 14, y - 22), new Phaser.Math.Vector2(x - 22, y - 14), new Phaser.Math.Vector2(x + 14, y + 26)], true);
        break;
      case 'heal':
      case 'likeHeal':
        g.fillRect(x - 7, y - 22, 14, 44);
        g.fillRect(x - 22, y - 7, 44, 14);
        break;
      case 'power':
        g.fillPoints([new Phaser.Math.Vector2(x + 6, y - 26), new Phaser.Math.Vector2(x - 16, y + 4), new Phaser.Math.Vector2(x - 2, y + 4), new Phaser.Math.Vector2(x - 8, y + 26), new Phaser.Math.Vector2(x + 16, y - 6), new Phaser.Math.Vector2(x + 2, y - 6)], true);
        break;
    }
  }

  // ------------------------------------------------------------------ eventos
  private onDirector(e: DirectorEvent) {
    switch (e.type) {
      case 'countdown':
        return this.countdown(e.n);
      case 'support': {
        const t = this.supportTexts.get(e.fighterId);
        if (t) {
          t.setText(`♥ ${e.total}`);
          this.tweens.add({ targets: t, scale: 1.35, duration: 90, yoyo: true });
        }
        return;
      }
      case 'power': {
        const b = this.buttons.find((x) => x.action === e.action);
        if (!b) return;
        b.count += e.count;
        b.label.setText(`×${b.count}`);
        this.tweens.add({ targets: b.box, scale: 1.15, duration: 110, yoyo: true, ease: 'Quad.easeOut' });
        return;
      }
      case 'sim':
        return this.onSim(e.ev);
    }
  }

  private typeColor(f: Fighter) {
    return TYPE_COLOR[f.types[0]] ?? 0xffffff;
  }

  private onSim(ev: SimEvent) {
    switch (ev.t) {
      case 'hit': {
        const a = this.views.get(ev.from);
        const b = this.views.get(ev.to);
        if (!a || !b) return;
        const impact = () => {
          this.flash(b);
          this.impact(b, this.typeColor(a.f), ev.crit ? 3 : 2.2);
          RT.audio.sfx(ev.eff > 1 ? 'hitSuper' : ev.eff < 1 ? 'hitWeak' : 'hit', { gapMs: 70, volume: 0.55 });
          const big = ev.crit || ev.eff > 1;
          this.float(b.f.x + Phaser.Math.Between(-16, 16), b.f.y + b.headY - 30, `${ev.dmg}`, ev.crit ? '#ffcf3f' : ev.eff > 1 ? '#ff9f2a' : '#ffffff', big ? 44 : 34);
          if (ev.crit) this.float(b.f.x, b.f.y + b.headY - 80, '¡CRÍTICO!', '#ffcf3f', 28);
          else if (ev.eff >= 2 && Math.random() < 0.5) this.float(b.f.x, b.f.y + b.headY - 80, '¡SÚPER EFICAZ!', '#ff9f2a', 24);
        };
        if (ev.ranged) this.projectile(a, b, impact);
        else {
          this.lunge(a, b);
          this.time.delayedCall(90, impact);
        }
        return;
      }
      case 'miss': {
        const b = this.views.get(ev.to);
        if (b) this.float(b.f.x, b.f.y + b.headY - 30, 'esquivó', '#d9ccff', 24);
        return;
      }
      case 'blocked': {
        const b = this.views.get(ev.to);
        if (!b) return;
        this.float(b.f.x, b.f.y + b.headY - 40, '¡BLOQUEO!', '#7fe8ff', 30);
        this.tweens.add({ targets: b.shield, alpha: 0.3, duration: 70, yoyo: true });
        return;
      }
      case 'ko':
        return this.ko(ev.id, ev.by);
      case 'heal': {
        const v = this.views.get(ev.id);
        if (!v || ev.amount <= 0) return;
        this.float(v.f.x, v.f.y + v.headY - 40, `+${ev.amount}`, '#7dff9a', 34);
        if (!RT.vfx.play(this, 'VFX_LEVEL_UP_BURST', v.f.x, v.f.y + v.headY / 2, { scale: 0.9, tint: 0x7dff9a, depth: 4300 })) this.sparks.explode(6, v.f.x, v.f.y - 60);
        RT.audio.sfx('heal', { gapMs: 2500, volume: 0.35 });
        return;
      }
      case 'shield': {
        const v = this.views.get(ev.id);
        if (v) this.float(v.f.x, v.f.y + v.headY - 60, '¡ESCUDO!', '#7fe8ff', 32);
        RT.audio.sfx('select', { gapMs: 200 });
        return;
      }
      case 'power': {
        const v = this.views.get(ev.id);
        if (v) {
          this.float(v.f.x, v.f.y + v.headY - 60, `¡POTENCIA +${Math.round(ev.pct * 100)}%!`, '#ff9f2a', 30);
          RT.vfx.play(this, 'VFX_BOOST', v.f.x, v.f.y + v.headY / 2, { scale: 0.8, depth: 4300 });
        }
        RT.audio.sfx('levelUp', { gapMs: 900, volume: 0.5 });
        return;
      }
      case 'burst': {
        const a = this.views.get(ev.from);
        const b = this.views.get(ev.to);
        if (!b) return;
        if (a) this.lunge(a, b);
        this.slash(b);
        this.impact(b, a ? this.typeColor(a.f) : 0xff5a5f, 3.4);
        this.float(b.f.x, b.f.y + b.headY - 40, `${ev.dmg}`, '#ff5a5f', 52);
        this.cameras.main.shake(140, 0.006);
        RT.audio.sfx('hitSuper', { gapMs: 40 });
        return;
      }
      case 'finalists':
        this.banner('QUEDAN 3 JUGADORES', C.gold);
        this.showFinalists(ev.ids);
        this.enlarge();
        RT.audio.sfx('exclaim');
        return;
      case 'duel':
        this.banner('DUELO FINAL', C.pink);
        if (!this.finalists) this.showFinalists(ev.ids);
        this.enlarge();
        RT.audio.sfx('exclaim');
        return;
      case 'sudden-death':
        this.banner('¡LA ZONA SE CIERRA!', C.red);
        return;
      case 'winner': {
        const v = this.views.get(ev.id);
        this.banner('¡GANADOR!', C.gold, 2200);
        RT.audio.sfx('victory');
        if (v) {
          this.tweens.add({ targets: v.body, scale: 1.5, duration: 400, ease: 'Back.easeOut' });
          this.sparks.explode(30, v.f.x, v.f.y - 80);
          RT.audio.cry(v.f.slug);
        }
        return;
      }
    }
  }

  // ------------------------------------------------------------------ efectos
  private float(x: number, y: number, str: string, color: string, size: number) {
    const t = this.add
      .text(x, y, str, { fontFamily: /[a-záéíóú]/i.test(str) ? FONT_HEAD : FONT_UI, fontSize: `${size}px`, fontStyle: 'bold', color, stroke: C.inkHex, strokeThickness: 7, padding: { x: 4, y: 4 } })
      .setOrigin(0.5)
      .setDepth(4500);
    t.setScale(0.6);
    this.tweens.add({ targets: t, scale: 1, duration: 120, ease: 'Back.easeOut' });
    this.tweens.add({ targets: t, y: y - 70, alpha: 0, delay: 300, duration: 650, ease: 'Cubic.easeIn', onComplete: () => t.destroy() });
  }

  private impact(v: View, color: number, scale: number) {
    if (this.activeVfx > 40) return;
    const s = RT.vfx.play(this, 'VFX_HIT', v.f.x, v.f.y + v.headY / 2, { scale, tint: color, depth: 4300 });
    if (s) {
      this.activeVfx++;
      s.once('destroy', () => this.activeVfx--);
    }
  }

  private flash(v: View) {
    v.sprite.setTintFill(0xffffff);
    this.time.delayedCall(70, () => v.sprite.clearTint());
    this.tweens.add({ targets: v.body, x: Phaser.Math.Between(-6, 6), duration: 40, yoyo: true, repeat: 1, onComplete: () => (v.body.x = 0) });
  }

  private lunge(a: View, b: View) {
    const dx = b.f.x - a.f.x;
    const dy = b.f.y - a.f.y;
    const d = Math.hypot(dx, dy) || 1;
    this.tweens.add({ targets: a.body, x: (dx / d) * 22, y: (dy / d) * 22, duration: 80, yoyo: true, ease: 'Quad.easeOut', onComplete: () => a.body.setPosition(0, 0) });
  }

  private projectile(a: View, b: View, onHit: () => void) {
    const sx = a.f.x;
    const sy = a.f.y + a.headY / 2;
    const tx = b.f.x;
    const ty = b.f.y + b.headY / 2;
    const name = RT.vfx.projectileFor(a.f.types[0]);
    let objs: Phaser.GameObjects.GameObject[];
    if (name && this.activeVfx < 40) {
      const s = this.add.sprite(sx, sy, RT.vfx.key(name)).setScale(1.8).setDepth(4200);
      s.play({ key: RT.vfx.key(name), repeat: -1 });
      s.setRotation(Math.atan2(ty - sy, tx - sx));
      objs = [s];
    } else {
      const color = this.typeColor(a.f);
      objs = [
        this.add.image(sx, sy, 'fx-dot').setTint(color).setScale(0.9).setDepth(4200).setBlendMode(Phaser.BlendModes.ADD),
        this.add.image(sx, sy, 'fx-dot').setScale(0.45).setDepth(4201),
      ];
    }
    this.activeVfx++;
    this.tweens.add({
      targets: objs,
      x: tx,
      y: ty,
      duration: 190,
      ease: 'Quad.easeIn',
      onComplete: () => {
        objs.forEach((o) => o.destroy());
        this.activeVfx--;
        onHit();
      },
    });
  }

  private slash(v: View) {
    const g = this.add.graphics().setDepth(4300);
    const cy = v.f.y + v.headY / 2;
    g.lineStyle(12, 0xffffff, 1);
    g.lineBetween(v.f.x - 70, cy - 70, v.f.x + 70, cy + 70);
    g.lineStyle(6, 0xff5a5f, 1);
    g.lineBetween(v.f.x + 60, cy - 70, v.f.x - 60, cy + 60);
    this.tweens.add({ targets: g, alpha: 0, duration: 380, onComplete: () => g.destroy() });
    this.flash(v);
  }

  private ko(id: string, by?: string) {
    const v = this.views.get(id);
    if (!v || v.dead) return;
    v.dead = true;
    this.puff.explode(18, v.f.x, v.f.y - 40);
    this.float(v.f.x, v.f.y + v.headY - 20, 'K.O.', '#ff5a5f', 46);
    RT.audio.sfx('faint', { gapMs: 120, volume: 0.6 });
    this.tweens.add({ targets: v.root, alpha: 0, scaleX: 0.4, scaleY: 0.4, duration: 450, ease: 'Back.easeIn', onComplete: () => v.root.setVisible(false) });
    if (by) {
      const k = this.views.get(by);
      if (k) this.float(k.f.x, k.f.y + k.headY - 70, '+1 KO', '#ffcf3f', 26);
    }
    const t = this.supportTexts.get(id);
    if (t) t.setColor('#8c7fa6');
  }

  private enlarge() {
    if (this.enlarged) return;
    this.enlarged = true;
    for (const v of this.views.values()) {
      if (v.dead) continue;
      this.tweens.add({ targets: v.sprite, mul: 1.35, duration: 500, ease: 'Back.easeOut' });
      this.tweens.add({ targets: [v.tag, v.hp], y: `-=${Math.round(-v.headY * 0.33)}`, duration: 500 });
    }
  }

  private banner(str: string, color: number, hold = 1300) {
    const c = this.add.container(540, 900).setDepth(6000);
    const g = this.add.graphics();
    ribbon(g, 0, 0, Math.min(900, 120 + str.length * 34), 110, color);
    const t = text(this, 0, 0, str, { size: 66, stroke: 10 });
    c.add([g, t]);
    c.setScale(0.2).setAlpha(0);
    this.tweens.add({ targets: c, scale: 1, alpha: 1, duration: 260, ease: 'Back.easeOut' });
    this.tweens.add({ targets: c, alpha: 0, y: 860, delay: hold, duration: 300, onComplete: () => c.destroy() });
  }

  private countdown(n: number) {
    const str = n > 0 ? String(n) : '¡A LUCHAR!';
    const t = text(this, 540, 960, str, { size: n > 0 ? 260 : 150, color: n > 0 ? '#ffffff' : '#ffcf3f', stroke: 18 }).setDepth(6000);
    t.setScale(2.2).setAlpha(0);
    this.tweens.add({ targets: t, scale: 1, alpha: 1, duration: 260, ease: 'Back.easeOut' });
    this.tweens.add({ targets: t, alpha: 0, scale: 1.3, delay: n > 0 ? 520 : 800, duration: 260, onComplete: () => t.destroy() });
    RT.audio.sfx(n > 0 ? 'cursor' : 'select');
    if (n === 0) this.cameras.main.flash(180, 255, 255, 255);
  }

  private showFinalists(ids: string[]) {
    this.finalists?.destroy();
    const c = this.add.container(0, 0).setDepth(5100);
    this.finalists = c;
    const w = 320;
    const startX = 540 - (ids.length * w + (ids.length - 1) * 14) / 2;
    ids.forEach((id, i) => {
      const f = this.sim.byId.get(id);
      if (!f) return;
      const person = RT.director.person(id);
      const x = startX + i * (w + 14);
      const y = 184;
      const g = this.add.graphics();
      paper(g, x, y, w, 128, { r: 18, fill: C.paper });
      g.fillStyle(C.gold, 1).fillCircle(x + 26, y + 26, 22);
      g.lineStyle(4, C.ink, 1).strokeCircle(x + 26, y + 26, 22);
      const seat = text(this, x + 26, y + 26, String(f.seat), { font: 'ui', size: 24, bold: true, color: '#22162f' });
      const av = avatar(this, x + 70, y + 70, person, 64);
      const name = text(this, x + 116, y + 44, truncate(f.name, 10), { size: 30, color: '#22162f', align: 'left' });
      const hint = text(this, x + 116, y + 88, `escribe ${f.seat}`, { font: 'ui', size: 22, bold: true, color: '#7b4dff', align: 'left' });
      const sup = text(this, x + w - 20, y + 88, `♥ ${RT.director.supporters.get(id)?.size ?? 0}`, { font: 'ui', size: 26, bold: true, color: '#ff4f6a', align: 'right' });
      this.supportTexts.set(id, sup);
      c.add([g, seat, av, name, hint, sup]);
    });
    c.setAlpha(0);
    this.tweens.add({ targets: c, alpha: 1, duration: 300 });
  }

  /** Zona segura: anillo rojo de cuadriláteros entre el círculo y el borde. */
  private drawZone(cx: number, cy: number, r: number) {
    const g = this.zone;
    g.clear();
    const outer = 1700;
    if (r < outer) {
      g.fillStyle(0xff3355, 0.24);
      const n = 72;
      for (let i = 0; i < n; i++) {
        const a0 = (i / n) * Math.PI * 2;
        const a1 = ((i + 1) / n) * Math.PI * 2;
        g.fillPoints(
          [
            new Phaser.Math.Vector2(cx + Math.cos(a0) * r, cy + Math.sin(a0) * r),
            new Phaser.Math.Vector2(cx + Math.cos(a0) * outer, cy + Math.sin(a0) * outer),
            new Phaser.Math.Vector2(cx + Math.cos(a1) * outer, cy + Math.sin(a1) * outer),
            new Phaser.Math.Vector2(cx + Math.cos(a1) * r, cy + Math.sin(a1) * r),
          ],
          true,
        );
      }
    }
    if (r > 2) g.lineStyle(6, 0xffffff, 0.75).strokeCircle(cx, cy, r);
  }

  // ------------------------------------------------------------------ cuadro a cuadro
  update() {
    if (!this.sim) return;
    const sim = this.sim;

    const r = sim.zoneRadius;
    if (Math.abs(r - this.lastZone) > 0.5) {
      this.lastZone = r;
      this.drawZone(sim.cx, sim.cy, r);
    }

    for (const v of this.views.values()) {
      const f = v.f;
      if (v.dead) continue;
      v.root.setPosition(f.x, f.y);
      v.root.setDepth(10 + f.y);
      // Dirección: hacia donde camina o, quieto, hacia su objetivo.
      const speed = Math.hypot(f.vx, f.vy);
      const moving = speed > 14 && RT.director.phase === 'battle';
      if (moving) v.sprite.dir = dir8FromVector(f.vx, f.vy);
      else if (f.targetId) {
        const t = sim.byId.get(f.targetId);
        if (t?.alive) v.sprite.dir = dir8FromVector(t.x - f.x, t.y - f.y);
      }
      v.sprite.mode = moving ? 'walk' : 'idle';
      if (f.hp !== v.lastHp) this.drawHp(v);
      v.shield.setVisible(f.shieldT > 0);
      v.aura.setAlpha(f.powerT > 0 ? 0.35 + Math.sin(this.time.now / 80) * 0.15 : 0);
    }

    const alive = sim.alive.length;
    this.aliveText.setText(`${alive}/${sim.fighters.length}`);
    const left = Math.ceil(sim.timeLeft);
    this.timer.setText(left > 0 ? `${left}s` : '¡YA!');
    this.timer.setColor(left <= 5 ? '#ff5a5f' : '#ffffff');
  }
}
