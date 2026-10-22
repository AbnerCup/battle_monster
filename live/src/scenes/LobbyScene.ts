import Phaser from 'phaser';
import { GAME } from '../config/game';
import { captureLegend } from '../config/giftRules';
import { xpToNext } from '../core/progression';
import { Rng } from '../core/rng';
import { RARITY_LABEL, type Rarity } from '../core/types';
import { RT } from '../runtime';
import { C, RARITY_COLOR, bar, paper, ribbon, text, truncate } from '../ui/theme';
import { avatar, creature, heart, pill } from '../ui/widgets';
import type { CreatureSprite } from '../ui/CreatureSprite';

const GRID = { x: 42, y: 772, w: 240, h: 232, gap: 12, cols: 4 };

export class LobbyScene extends Phaser.Scene {
  private swirl!: Phaser.GameObjects.Container;
  private cards!: Phaser.GameObjects.Container;
  private status!: Phaser.GameObjects.Text;
  private players!: Phaser.GameObjects.Text;
  private pageText!: Phaser.GameObjects.Text;
  private samples: { img: CreatureSprite; rarity: Rarity }[] = [];
  private page = 0;
  private pageT = 0;
  private dirty = true;
  private cooldown = 0;
  private sampleT = 0;
  private offs: (() => void)[] = [];

  constructor() {
    super('lobby');
  }

  create() {
    this.samples = [];
    this.page = 0;
    this.pageT = 0;
    this.dirty = true;
    this.drawBackground();
    this.drawHeader();
    this.drawInstructions();
    this.drawCapturePanel();
    this.cards = this.add.container(0, 0);
    this.pageText = text(this, 540, 1795, '', { font: 'ui', size: 28, color: '#efe6ff', bold: true });
    const credit = RT.pack.id === 'tuxemon' ? `Criaturas: Tuxemon · CC BY-SA 4.0 · tuxemon.org` : `Contenido: ${RT.pack.file.name}`;
    text(this, 540, 1870, credit, { font: 'ui', size: 20, color: '#9d8fbf' });

    this.offs.push(
      RT.director.on((e) => {
        if (e.type === 'roster') this.dirty = true;
      }),
    );
    this.events.once('shutdown', () => {
      this.offs.forEach((f) => f());
      this.offs = [];
    });
    this.cameras.main.fadeIn(350, 20, 13, 34);
  }

  // ------------------------------------------------------------------ fondo
  private drawBackground() {
    const { width: W, height: H } = this.scale;
    const g = this.add.graphics();
    g.fillGradientStyle(0x2a1550, 0x2a1550, 0x0d0a1a, 0x0d0a1a, 1);
    g.fillRect(0, 0, W, H);
    // estrellas
    const rng = new Phaser.Math.RandomDataGenerator(['vortex']);
    for (let i = 0; i < 90; i++) {
      g.fillStyle(0xffffff, rng.realInRange(0.15, 0.6));
      g.fillCircle(rng.between(0, W), rng.between(0, H), rng.realInRange(1, 3));
    }
    // remolino del vórtice
    this.swirl = this.add.container(W / 2, 960);
    const s = this.add.graphics();
    const cols = [C.violet, C.pink, C.teal];
    for (let i = 0; i < 9; i++) {
      s.lineStyle(26 - i * 2, cols[i % 3], 0.07 + i * 0.008);
      s.beginPath();
      s.arc(0, 0, 160 + i * 95, Phaser.Math.DegToRad(i * 40), Phaser.Math.DegToRad(i * 40 + 220));
      s.strokePath();
    }
    this.swirl.add(s);
  }

  private drawHeader() {
    const live = pill(this, 112, 40, '● EN VIVO', C.red, { size: 22 });
    this.tweens.add({ targets: live, alpha: 0.65, duration: 700, yoyo: true, repeat: -1 });
    this.players = text(this, 1040, 40, '', { font: 'ui', size: 26, bold: true, color: '#ffffff', stroke: 6, align: 'right' });
    text(this, 540, 122, GAME.title, { size: GAME.title.length > 14 ? 84 : 104, color: '#ffcf3f', stroke: 16 });
    text(this, 540, 190, GAME.subtitle, { font: 'ui', size: 32, bold: true, color: '#d9ccff', stroke: 6 });

    const g = this.add.graphics();
    ribbon(g, 540, 262, 780, 82, C.violet);
    this.status = text(this, 540, 262, '', { size: 46, stroke: 8 });
  }

  private drawInstructions() {
    const g = this.add.graphics();
    paper(g, 40, 336, 1000, 150);
    g.lineStyle(4, C.paperLine, 1).lineBetween(540, 356, 540, 466);
    const h = heart(this, 112, 412, 74);
    this.tweens.add({ targets: h, scale: 1.15, duration: 380, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
    text(this, 330, 392, 'TAP TAP', { size: 64, color: '#ff4f6a', stroke: 0 });
    text(this, 330, 446, 'para unirte al juego', { font: 'ui', size: 28, color: '#5a4a6e', bold: true });
    text(this, 790, 392, '!mochila', { size: 60, color: '#7b4dff' });
    text(this, 790, 446, RT.pack.noun === 'Pokémon' ? 'para cambiar tu Pokémon' : 'para cambiar tu criatura', { font: 'ui', size: 28, color: '#5a4a6e', bold: true });
  }

  private drawCapturePanel() {
    const g = this.add.graphics();
    paper(g, 40, 524, 1000, 216, { fill: 0xfff0f5 });
    ribbon(g, 540, 526, 520, 62, C.pink);
    text(this, 540, 526, `¡CAPTURA ${RT.pack.noun.toUpperCase()}!`, { size: 38, stroke: 7 });

    const legend = captureLegend();
    legend.forEach((l, i) => {
      const cx = 205 + i * 335;
      const cy = 652;
      const t = this.add.graphics();
      t.fillStyle(0xffffff, 1).fillRoundedRect(cx - 150, cy - 70, 300, 140, 18);
      t.lineStyle(5, RARITY_COLOR[l.rarity], 1).strokeRoundedRect(cx - 150, cy - 70, 300, 140, 18);
      t.fillStyle(0x000000, 0.12).fillEllipse(cx - 78, cy + 44, 90, 20);
      const sp = RT.pack.random(l.rarity, new Rng());
      const img = creature(this, cx - 78, cy + 2, sp.slug, { fit: { w: 104, h: 104 } });
      this.samples.push({ img, rarity: l.rarity });
      text(this, cx + 60, cy - 22, l.label, { size: l.label.length > 10 ? 30 : 38, color: '#22162f', wrap: 170 });
      pill(this, cx + 60, cy + 34, RARITY_LABEL[l.rarity], RARITY_COLOR[l.rarity], { size: 22 });
    });
  }

  // ------------------------------------------------------------------ tarjetas
  private rebuild() {
    this.cards.removeAll(true);
    const list = RT.director.rosterList();
    const per = GAME.lobby.pageSize;
    const pages = Math.max(1, Math.ceil(list.length / per));
    if (this.page >= pages) this.page = 0;
    const slice = list.slice(this.page * per, this.page * per + per);
    this.pageText.setText(pages > 1 ? `Página ${this.page + 1}/${pages}` : list.length ? '' : 'Da like para aparecer aquí');

    for (let i = 0; i < per; i++) {
      const col = i % GRID.cols;
      const row = Math.floor(i / GRID.cols);
      const x = GRID.x + col * (GRID.w + GRID.gap);
      const y = GRID.y + row * (GRID.h + GRID.gap);
      const entry = slice[i];
      if (!entry) {
        const g = this.add.graphics();
        g.fillStyle(0xffffff, 0.05).fillRoundedRect(x, y, GRID.w, GRID.h, 18);
        g.lineStyle(3, 0xffffff, 0.15).strokeRoundedRect(x, y, GRID.w, GRID.h, 18);
        const t = text(this, x + GRID.w / 2, y + GRID.h / 2, 'TAP TAP', { font: 'ui', size: 26, color: '#ffffff', bold: true });
        t.setAlpha(0.22);
        this.cards.add([g, t]);
        continue;
      }
      const p = RT.store.get(entry.userId);
      if (!p) continue;
      const c = RT.store.active(p);
      const sp = RT.pack.get(c.slug);
      const rarityCol = sp.rarity === 'comun' ? C.ink : RARITY_COLOR[sp.rarity];

      const g = this.add.graphics();
      paper(g, x, y, GRID.w, GRID.h, { r: 18, stroke: rarityCol, line: sp.rarity === 'especial' ? 8 : 5 });
      g.fillStyle(0x000000, 0.12).fillEllipse(x + 174, y + 128, 70, 16);
      g.fillStyle(C.gold, 1).fillCircle(x + 26, y + 26, 22);
      g.lineStyle(4, C.ink, 1).strokeCircle(x + 26, y + 26, 22);
      const seat = text(this, x + 26, y + 26, String(entry.seat), { font: 'ui', size: 24, bold: true, color: '#22162f' });

      const av = avatar(this, x + 76, y + 82, p, 92);
      const lvl = pill(this, x + 76, y + 132, `Nv.${p.trainerLevel}`, C.violet, { size: 18, pad: 16 });
      const icon = creature(this, x + 174, y + 84, c.slug, { shiny: c.shiny, mode: 'icon', fit: { w: 100, h: 96 } });
      const shinyMark = c.shiny ? text(this, x + 214, y + 34, '✦', { font: 'ui', size: 30, bold: true, color: '#ffe36b', stroke: 5 }) : null;

      const name = text(this, x + GRID.w / 2, y + 168, truncate(p.nickname, 12), { size: 30, color: '#22162f' });
      const cname = text(this, x + GRID.w / 2, y + 198, `${truncate(sp.name, 10)} Nv.${c.level}`, { font: 'ui', size: 20, bold: true, color: '#5a4a6e' });
      const xb = this.add.graphics();
      bar(xb, x + 24, y + 214, GRID.w - 48, 8, c.xp / xpToNext(c.level), C.teal);
      this.cards.add([g, seat, av, lvl, icon, name, cname, xb]);
      if (shinyMark) this.cards.add(shinyMark);
    }
  }

  update(_t: number, delta: number) {
    const dt = delta / 1000;
    const d = RT.director;
    this.swirl.rotation += dt * 0.05;

    this.pageT += dt;
    if (this.pageT >= GAME.lobby.pageSec) {
      this.pageT = 0;
      if (d.roster.size > GAME.lobby.pageSize) {
        this.page++;
        this.dirty = true;
      }
    }
    this.cooldown -= dt;
    if (this.dirty && this.cooldown <= 0) {
      this.dirty = false;
      this.cooldown = 0.35;
      this.rebuild();
    }

    this.sampleT += dt;
    if (this.sampleT > 4) {
      this.sampleT = 0;
      for (const s of this.samples) {
        const pool = RT.pack.byRarity[s.rarity];
        s.img.setCreature(pool[Math.floor(Math.random() * pool.length)].slug);
      }
    }

    this.players.setText(`${d.roster.size} JUGADORES`);
    if (d.phase !== 'lobby') this.status.setText('¡A LA ARENA!');
    else if (d.roster.size >= GAME.lobby.minPlayers) this.status.setText(`LA RONDA EMPIEZA EN ${Math.max(0, Math.ceil(d.lobbyCountdown))}s`);
    else this.status.setText(`ESPERANDO JUGADORES (${d.roster.size}/${GAME.lobby.minPlayers})`);
  }
}
