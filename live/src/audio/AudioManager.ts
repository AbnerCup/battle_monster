// Música, efectos y gritos.
//  - Música: <audio> del navegador (se reproduce en streaming, no ocupa decenas de MB
//    decodificados como haría Web Audio con pistas largas).
//  - Efectos: Web Audio de Phaser, precargados (son pocos y cortos), con límite de
//    repetición para que una pelea de 20 no sea ruido.
//  - Gritos: <audio> bajo demanda.
//
// En OBS hay que activar "Controlar audio a través de OBS" en la fuente de navegador.

import Phaser from 'phaser';
import { GAME } from '../config/game';
import type { SpeciesPack } from '../content/SpeciesPack';

export class AudioManager {
  muted = false;
  private game?: Phaser.Game;
  private bgmName = '';
  private bgm?: HTMLAudioElement;
  private fadeTimer?: ReturnType<typeof setInterval>;
  private last = new Map<string, number>();
  private wantPlay = false;

  constructor(readonly pack: SpeciesPack) {
    // Si el navegador bloquea el audio hasta que haya un clic, se reintenta entonces.
    const retry = () => {
      if (this.wantPlay && this.bgm && this.bgm.paused) this.bgm.play().catch(() => {});
    };
    window.addEventListener('pointerdown', retry);
    window.addEventListener('keydown', retry);
  }

  attach(game: Phaser.Game) {
    this.game = game;
    game.sound.mute = this.muted;
  }

  sfxKey(name: string) {
    return `sfx:${name}`;
  }

  preload(load: Phaser.Loader.LoaderPlugin) {
    for (const [name, rel] of Object.entries(this.pack.assets.audio.sfx)) load.audio(this.sfxKey(name), this.pack.url(rel));
  }

  setMuted(m: boolean) {
    this.muted = m;
    if (this.game) this.game.sound.mute = m;
    if (this.bgm) this.bgm.muted = m;
  }

  private musicVolume() {
    return GAME.audio.master * GAME.audio.music;
  }

  /** Cambia la música con fundido. Nombres: lobby, battle, result. */
  bgmPlay(name: string) {
    if (name === this.bgmName) return;
    this.bgmName = name;
    const rel = this.pack.assets.audio.bgm[name];
    const old = this.bgm;
    this.bgm = undefined;
    clearInterval(this.fadeTimer);
    if (old) this.fade(old, 0, 500, () => old.pause());
    if (!rel) return;
    const a = new Audio(this.pack.url(rel));
    a.loop = true;
    a.volume = 0;
    a.muted = this.muted;
    this.bgm = a;
    this.wantPlay = true;
    a.play().catch(() => {});
    this.fade(a, this.musicVolume(), 800);
  }

  private fade(a: HTMLAudioElement, to: number, ms: number, done?: () => void) {
    const from = a.volume;
    const t0 = performance.now();
    const timer = setInterval(() => {
      const k = Math.min(1, (performance.now() - t0) / ms);
      a.volume = Math.max(0, Math.min(1, from + (to - from) * k));
      if (k >= 1) {
        clearInterval(timer);
        done?.();
      }
    }, 50);
    if (a === this.bgm) this.fadeTimer = timer;
  }

  /** Efecto corto. `gapMs` evita repetirlo demasiado seguido. */
  sfx(name: string, o: { volume?: number; rate?: number; gapMs?: number } = {}) {
    const game = this.game;
    if (!game || this.muted) return;
    const key = this.sfxKey(name);
    if (!game.cache.audio.exists(key)) return;
    const now = performance.now();
    if (now - (this.last.get(name) ?? -1e9) < (o.gapMs ?? 60)) return;
    this.last.set(name, now);
    try {
      game.sound.play(key, { volume: GAME.audio.master * GAME.audio.sfx * (o.volume ?? 1), rate: o.rate ?? 1 });
    } catch {
      /* contexto de audio aún bloqueado */
    }
  }

  cry(slug: string, volume = 1) {
    if (this.muted) return;
    const rel = this.pack.get(slug)?.cry;
    if (!rel) return;
    const now = performance.now();
    if (now - (this.last.get('cry') ?? -1e9) < 250) return;
    this.last.set('cry', now);
    const a = new Audio(this.pack.url(rel));
    a.volume = Math.min(1, GAME.audio.master * GAME.audio.cries * volume);
    a.play().catch(() => {});
  }
}
