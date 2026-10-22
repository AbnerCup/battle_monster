import Phaser from 'phaser';
import type { BattleReport } from '../core/GameDirector';
import { RT } from '../runtime';
import { C, bar, paper, ribbon, text, truncate } from '../ui/theme';
import { avatar, creature, pill, typeChip } from '../ui/widgets';

export class ResultScene extends Phaser.Scene {
  private rays!: Phaser.GameObjects.Graphics;
  private footer!: Phaser.GameObjects.Text;

  constructor() {
    super('result');
  }

  create() {
    const report = RT.director.lastReport;
    const { width: W, height: H } = this.scale;
    const bg = this.add.graphics();
    bg.fillGradientStyle(0x2a1550, 0x2a1550, 0x0d0a1a, 0x0d0a1a, 1).fillRect(0, 0, W, H);
    this.rays = this.add.graphics({ x: W / 2, y: 720 });
    for (let i = 0; i < 18; i++) {
      const a = (i / 18) * Math.PI * 2;
      this.rays.fillStyle(i % 2 ? C.violet : C.gold, 0.1);
      this.rays.slice(0, 0, 1400, a, a + Math.PI / 18).fillPath();
    }
    this.footer = text(this, 540, 1880, '', { font: 'ui', size: 26, bold: true, color: '#b7a8d9' });
    if (!report) return;

    const banner = this.add.container(-600, 150);
    const g = this.add.graphics();
    ribbon(g, 0, 0, 640, 120, C.gold);
    banner.add([g, text(this, 0, 0, '¡GANADOR!', { size: 86, stroke: 12 })]);
    this.tweens.add({ targets: banner, x: 540, duration: 650, ease: 'Back.easeOut' });

    this.time.delayedCall(450, () => this.champion(report));
    this.time.delayedCall(1300, () => this.stats(report));
    this.time.delayedCall(2300, () => this.podium(report));
    this.cameras.main.fadeIn(300, 255, 255, 255);
  }

  private champion(r: BattleReport) {
    const p = RT.director.person(r.winnerId);
    const sp = RT.pack.get(r.slug);
    const c = this.add.container(0, 0);
    const g = this.add.graphics();
    paper(g, 70, 260, 940, 760, { r: 30 });
    g.fillStyle(0xf6e7c8, 1).fillRoundedRect(110, 330, 860, 430, 24);
    g.fillStyle(0x000000, 0.12).fillEllipse(540, 700, 300, 54);
    c.add(g);
    c.add(text(this, 540, 302, '¡NUESTRO CAMPEÓN!', { size: 38, color: '#b0803a' }));

    const mon = creature(this, 540, 560, r.slug, { shiny: r.shiny, fit: { w: 400, h: 330 } }).setOrigin(0.5, 0.5);
    mon.mul = 0.2;
    c.add(mon);
    this.tweens.add({ targets: mon, mul: 1, duration: 600, ease: 'Back.easeOut' });
    this.tweens.add({ targets: mon, y: 540, duration: 700, yoyo: true, repeat: -1, ease: 'Sine.easeInOut', delay: 600 });
    this.time.delayedCall(250, () => RT.audio.cry(r.slug));
    const sparks = this.add.particles(540, 520, 'fx-star', {
      speed: { min: 60, max: 220 },
      lifespan: 1400,
      scale: { start: 0.7, end: 0 },
      tint: [0xffcf3f, 0xffffff],
      frequency: 140,
      quantity: 2,
    });
    sparks.setDepth(10);
    c.add(pill(this, 870, 370, `Nv. ${r.level}`, C.violet, { size: 30 }));
    sp.types.forEach((t, i) => c.add(typeChip(this, 210 + i * 150, 370, t, 24)));

    c.add(avatar(this, 190, 870, p, 150, p.isBot ? 0xb7a8d9 : C.gold));
    c.add(text(this, 290, 850, truncate(p.nickname, 16), { size: 64, color: '#22162f', align: 'left' }));
    const sub = `${r.shiny ? '✦ ' : ''}${sp.name}${r.evolvedTo ? ' · ¡evolucionó!' : ''}${p.isBot ? ' · bot del juego' : ''}`;
    c.add(text(this, 292, 916, sub, { font: 'ui', size: 30, bold: true, color: '#5a4a6e', align: 'left' }));
    c.setScale(0.85).setAlpha(0);
    this.tweens.add({ targets: c, scale: 1, alpha: 1, duration: 380, ease: 'Back.easeOut' });
    this.cameras.main.flash(200, 255, 230, 150);
  }

  private stats(r: BattleReport) {
    const c = this.add.container(0, 0);
    const g = this.add.graphics();
    paper(g, 70, 1050, 940, 520, { r: 26 });
    c.add(g);
    c.add(text(this, 540, 1092, 'INFORME DEL CAMPEÓN', { size: 34, color: '#b0803a' }));
    const rows: [string, string][] = [
      ['K.O.', String(r.kos)],
      ['Daño', String(r.damage)],
      ['Vida restante', `${r.hpPct}%`],
      [`EXP ${RT.pack.noun === 'Pokémon' ? 'Pokémon' : 'criatura'}`, `+${r.creatureXp}`],
    ];
    rows.forEach(([k, v], i) => {
      const y = 1150 + i * 64;
      const lk = text(this, 130, y, k, { size: 40, color: '#22162f', align: 'left' });
      const dots = text(this, 540, y + 4, '·'.repeat(26), { font: 'ui', size: 30, color: '#cdb98f' });
      const lv = text(this, 900, y, v, { size: 44, color: '#22162f', align: 'right' });
      const tick = text(this, 950, y, '✓', { font: 'ui', size: 40, bold: true, color: '#e0475b' });
      [lk, dots, lv, tick].forEach((o) => o.setAlpha(0));
      c.add([lk, dots, lv, tick]);
      this.tweens.add({ targets: [lk, dots, lv], alpha: 1, delay: i * 180, duration: 200 });
      this.tweens.add({ targets: tick, alpha: 1, scale: { from: 2, to: 1 }, delay: i * 180 + 150, duration: 220, ease: 'Back.easeOut' });
    });

    if (r.isBot) {
      c.add(text(this, 540, 1470, '¡Da like y gánale la próxima ronda!', { size: 40, color: '#7b4dff' }));
      return;
    }
    c.add(text(this, 130, 1440, `Entrenador Nv. ${r.trainerLevel}`, { size: 38, color: '#22162f', align: 'left' }));
    c.add(text(this, 950, 1440, `+${r.trainerXp} EXP entrenador`, { font: 'ui', size: 24, bold: true, color: '#5a4a6e', align: 'right' }));
    const b = this.add.graphics();
    c.add(b);
    const target = r.trainerXpNow / r.trainerXpNext;
    const anim = { p: Math.max(0, target - r.trainerXp / r.trainerXpNext) };
    this.tweens.add({
      targets: anim,
      p: target,
      delay: 800,
      duration: 900,
      ease: 'Cubic.easeOut',
      onUpdate: () => {
        b.clear();
        bar(b, 130, 1490, 820, 30, anim.p, C.teal);
      },
    });
    bar(b, 130, 1490, 820, 30, anim.p, C.teal);
  }

  private podium(r: BattleReport) {
    const notes: { userId: string; title: string; sub: string; color: number }[] = r.podium.map((p) => ({
      userId: p.userId,
      title: `${p.place}.º`,
      sub: `+${p.creatureXp} EXP`,
      color: p.place === 2 ? 0xfff19a : 0xa8e4ff,
    }));
    if (r.topFan) notes.push({ userId: r.topFan.userId, title: 'FAN N.º 1', sub: 'apoyó al campeón', color: 0xffc1d6 });
    notes.forEach((n, i) => {
      const p = RT.director.person(n.userId);
      const x = 90 + i * 315;
      const y = 1610;
      const c = this.add.container(x + 140, y + 70);
      const g = this.add.graphics();
      g.fillStyle(0x000000, 0.25).fillRect(-136, -62, 290, 140);
      g.fillStyle(n.color, 1).fillRect(-145, -70, 290, 140);
      g.fillStyle(0xffffff, 0.35).fillRect(-50, -82, 100, 26);
      c.add(g);
      c.add(avatar(this, -88, 0, p, 80));
      c.add(text(this, -32, -30, n.title, { size: 34, color: '#22162f', align: 'left' }));
      c.add(text(this, -32, 8, truncate(p.nickname, 11), { font: 'ui', size: 24, bold: true, color: '#22162f', align: 'left' }));
      c.add(text(this, -32, 40, n.sub, { font: 'ui', size: 20, color: '#5a4a6e', align: 'left' }));
      c.setAngle(Phaser.Math.Between(-4, 4)).setScale(0).setAlpha(0);
      this.tweens.add({ targets: c, scale: 1, alpha: 1, delay: i * 160, duration: 300, ease: 'Back.easeOut' });
    });
  }

  update(_t: number, delta: number) {
    this.rays.rotation += (delta / 1000) * 0.12;
    this.footer.setText(`Siguiente ronda en ${Math.max(0, Math.ceil(RT.director.resultLeft))}s · da like para jugar`);
  }
}
