import Phaser from 'phaser';
import { GAME } from '../config/game';
import { Sprites, PLACEHOLDER } from '../content/Sprites';
import { GameDirector } from '../core/GameDirector';
import { LocalStorageRepository, PlayerStore } from '../core/PlayerStore';
import { RT } from '../runtime';
import { AvatarCache } from '../ui/avatars';
import { C, FONT_HEAD } from '../ui/theme';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('boot');
  }

  preload() {
    const { width, height } = this.scale;
    const g = this.add.graphics();
    const label = this.add
      .text(width / 2, height / 2 - 80, GAME.title, { fontFamily: FONT_HEAD, fontSize: '96px', color: '#ffcf3f', stroke: '#22162f', strokeThickness: 12 })
      .setOrigin(0.5);
    this.load.on('progress', (p: number) => {
      g.clear();
      g.fillStyle(C.ink, 1).fillRoundedRect(width / 2 - 360, height / 2 + 20, 720, 44, 22);
      g.fillStyle(C.gold, 1).fillRoundedRect(width / 2 - 354, height / 2 + 26, Math.max(32, 708 * p), 32, 16);
    });
    this.load.on('complete', () => label.destroy());

    // Solo lo pequeño y común: efectos, fondos y sonidos cortos. Los sprites de
    // criaturas se descargan bajo demanda (ver content/Sprites.ts).
    const pack = RT.pack;
    RT.vfx.preload(this.load);
    for (const bg of pack.assets.backgrounds) this.load.image(`bg:${bg.name}`, pack.url(bg.file));
    RT.audio.preload(this.load);
  }

  async create() {
    const pack = RT.pack;
    RT.vfx.createAnims(this.anims, this.textures);
    this.makeFxTextures();

    RT.sprites = new Sprites(this.textures, pack, GAME.maxSpriteTextures);
    const store = new PlayerStore(pack, new LocalStorageRepository(`vortex.players.${pack.id}.v1`));
    await store.init();
    RT.store = store;
    RT.avatars = new AvatarCache(this.textures);
    RT.director = new GameDirector(pack, store, RT.hub);

    this.scene.launch('overlay');
    this.scene.start('lobby');
    this.game.events.emit('vortex-ready');
  }

  private makeFxTextures() {
    const g = this.make.graphics({ x: 0, y: 0 }, false);
    g.fillStyle(0xffffff, 1).fillCircle(16, 16, 16);
    g.generateTexture('fx-dot', 32, 32);
    g.clear();
    g.fillStyle(0xffffff, 1);
    g.fillPoints(
      [
        { x: 24, y: 0 },
        { x: 29, y: 19 },
        { x: 48, y: 24 },
        { x: 29, y: 29 },
        { x: 24, y: 48 },
        { x: 19, y: 29 },
        { x: 0, y: 24 },
        { x: 19, y: 19 },
      ] as Phaser.Math.Vector2[],
      true,
    );
    g.generateTexture('fx-star', 48, 48);
    g.clear();
    g.fillStyle(0xffffff, 1).fillRect(0, 0, 14, 22);
    g.generateTexture('fx-confetti', 14, 22);
    // Silueta mientras se descarga una criatura
    g.clear();
    g.fillStyle(0x000000, 0.22).fillEllipse(32, 56, 40, 10);
    g.fillStyle(0xd9ccff, 0.55).fillEllipse(32, 34, 34, 42);
    g.fillStyle(0xffffff, 0.5).fillEllipse(25, 24, 9, 12);
    g.generateTexture(PLACEHOLDER, 64, 64);
    g.destroy();
  }
}
