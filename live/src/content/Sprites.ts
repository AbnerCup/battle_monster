// Sprites de criaturas con carga bajo demanda.
//
// Un paquete grande (839 especies con hojas de caminar, reposo y variocolor) no
// cabe entero en la memoria de vídeo de una PC modesta. Cada hoja se descarga la
// primera vez que se necesita, se corta en cuadros y, si hay demasiadas, se liberan
// las que llevan más tiempo sin usarse.

import Phaser from 'phaser';
import type { SheetLayout } from '../core/types';
import type { SpeciesPack } from './SpeciesPack';

export type SpriteMode = 'walk' | 'idle' | 'icon';

export interface FrameRef {
  key: string;
  frame: string;
  flipX: boolean;
  w: number;
  h: number;
}

/** Direcciones en el orden de las hojas de 8 direcciones. */
export const DIR = { DOWN: 0, DOWN_RIGHT: 1, RIGHT: 2, UP_RIGHT: 3, UP: 4, UP_LEFT: 5, LEFT: 6, DOWN_LEFT: 7 } as const;
const SECTOR_TO_DIR8 = [2, 1, 0, 7, 6, 5, 4, 3];
const DIR8_TO_DIR4 = [0, 2, 2, 2, 3, 1, 1, 1];

export function dir8FromVector(dx: number, dy: number): number {
  if (!dx && !dy) return DIR.DOWN;
  const sector = ((Math.round(Math.atan2(dy, dx) / (Math.PI / 4)) % 8) + 8) % 8;
  return SECTOR_TO_DIR8[sector];
}
const facesRight = (dir: number) => dir === DIR.DOWN_RIGHT || dir === DIR.RIGHT || dir === DIR.UP_RIGHT;

export const PLACEHOLDER = 'sp-placeholder';

export class Sprites {
  private loader?: Phaser.Loader.LoaderPlugin;
  private queue: { key: string; url: string; layout: SheetLayout; slug: string }[] = [];
  private pending = new Set<string>();
  private failed = new Set<string>();
  private lastUsed = new Map<string, number>();
  private listeners = new Set<(slug: string) => void>();
  private clock = 0;

  constructor(
    private textures: Phaser.Textures.TextureManager,
    readonly pack: SpeciesPack,
    public maxTextures = 240,
  ) {}

  /** La escena que siempre está activa presta su cargador para las descargas. */
  attachLoader(loader: Phaser.Loader.LoaderPlugin) {
    this.loader = loader;
    loader.on('loaderror', (file: Phaser.Loader.File) => {
      if (!this.pending.has(file.key)) return;
      this.pending.delete(file.key);
      this.failed.add(file.key);
    });
    const q = this.queue.splice(0);
    for (const item of q) this.load(item.key, item.url, item.layout, item.slug);
  }

  onReady(cb: (slug: string) => void): () => void {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  /** Pide las hojas de una especie. Devuelve true si la de caminar ya está lista. */
  request(slug: string, shiny = false): boolean {
    const ok = this.ensure(slug, 'walk', false);
    this.ensure(slug, 'idle', false);
    if (shiny && this.pack.hasShiny(slug)) {
      this.ensure(slug, 'walk', true);
      this.ensure(slug, 'idle', true);
    }
    return ok;
  }

  ready(slug: string, shiny = false) {
    return this.textures.exists(this.pack.sheetKey(slug, 'walk', shiny && this.pack.hasShiny(slug)));
  }

  private ensure(slug: string, anim: 'walk' | 'idle', shiny: boolean): boolean {
    const layout = this.pack.sheet(slug, anim, shiny);
    if (!layout) return false;
    const key = this.pack.sheetKey(slug, anim, shiny);
    if (this.textures.exists(key)) {
      this.lastUsed.set(key, ++this.clock);
      return true;
    }
    if (this.pending.has(key) || this.failed.has(key)) return false;
    this.pending.add(key);
    const url = this.pack.url(layout.file);
    if (this.loader) this.load(key, url, layout, slug);
    else this.queue.push({ key, url, layout, slug });
    return false;
  }

  private load(key: string, url: string, layout: SheetLayout, slug: string) {
    const loader = this.loader!;
    loader.once(`filecomplete-image-${key}`, () => {
      this.pending.delete(key);
      if (!this.textures.exists(key)) return;
      this.register(key, layout);
      this.lastUsed.set(key, ++this.clock);
      this.listeners.forEach((cb) => cb(slug));
    });
    loader.image(key, url);
    if (!loader.isLoading()) loader.start();
  }

  private register(key: string, l: SheetLayout) {
    const tex = this.textures.get(key);
    tex.setFilter(Phaser.Textures.FilterMode.NEAREST);
    if (l.kind === 'static') {
      const f = l.front ?? [0, 0, l.fw, l.fh];
      tex.add('front', 0, f[0], f[1], f[2], f[3]);
      (l.menu ?? []).forEach((m, i) => tex.add(`m${i}`, 0, m[0], m[1], m[2], m[3]));
      return;
    }
    const rows = l.kind === 'dir8' ? 8 : 4;
    for (let r = 0; r < rows; r++) for (let c = 0; c < l.frames; c++) tex.add(`${r}_${c}`, 0, c * l.fw, r * l.fh, l.fw, l.fh);
  }

  /**
   * Cuadro que corresponde mostrar ahora.
   *  - walk: ciclo de caminar en la dirección dada
   *  - idle: animación de reposo (o primer cuadro de caminar si no hay)
   *  - icon: miniatura (iconos de menú en paquetes simples; reposo en los animados)
   */
  frame(slug: string, shiny: boolean, mode: SpriteMode, dir: number, timeMs: number): FrameRef {
    const sh = shiny && this.pack.hasShiny(slug);
    let anim: 'walk' | 'idle' = mode === 'walk' ? 'walk' : 'idle';
    let layout = this.pack.sheet(slug, anim, sh);
    let key = this.pack.sheetKey(slug, anim, sh);
    let still = false;

    if (anim === 'idle' && (!layout || !this.textures.exists(key))) {
      if (layout) this.ensure(slug, 'idle', sh);
      anim = 'walk';
      layout = this.pack.sheet(slug, 'walk', sh);
      key = this.pack.sheetKey(slug, 'walk', sh);
      still = true;
    }
    if (!layout || !this.textures.exists(key)) {
      if (layout) this.ensure(slug, anim, sh);
      if (sh) return this.frame(slug, false, mode, dir, timeMs); // mientras llega el shiny
      return { key: PLACEHOLDER, frame: '__BASE', flipX: false, w: 64, h: 64 };
    }
    this.lastUsed.set(key, ++this.clock);

    if (layout.kind === 'static') {
      const menu = mode === 'icon' && layout.menu?.length;
      const frame = menu ? `m${Math.floor(timeMs / 450) % layout.menu!.length}` : 'front';
      const size = menu ? layout.menu![0] : layout.front ?? [0, 0, layout.fw, layout.fh];
      return { key, frame, flipX: mode === 'walk' && facesRight(dir), w: size[2], h: size[3] };
    }
    const row = layout.kind === 'dir8' ? dir : DIR8_TO_DIR4[dir];
    const fps = anim === 'idle' ? 6 : 10;
    const col = still ? 0 : Math.floor((timeMs / 1000) * fps) % layout.frames;
    return { key, frame: `${row}_${col}`, flipX: false, w: layout.fw, h: layout.fh };
  }

  /** Tamaño del cuadro de caminar (para escalar y colocar etiquetas). */
  size(slug: string): { w: number; h: number } {
    const l = this.pack.sheet(slug, 'walk');
    if (!l) return { w: 64, h: 64 };
    if (l.kind === 'static') {
      const f = l.front ?? [0, 0, l.fw, l.fh];
      return { w: f[2], h: f[3] };
    }
    return { w: l.fw, h: l.fh };
  }

  /** Libera las hojas menos usadas si hay demasiadas, sin tocar las que se están mostrando. */
  prune(keep: Iterable<string>): number {
    const loaded = [...this.lastUsed.keys()].filter((k) => this.textures.exists(k));
    if (loaded.length <= this.maxTextures) return 0;
    const keepKeys = new Set<string>();
    for (const slug of keep)
      for (const anim of ['walk', 'idle'] as const)
        for (const sh of [false, true]) keepKeys.add(this.pack.sheetKey(slug, anim, sh));
    loaded.sort((a, b) => (this.lastUsed.get(a) ?? 0) - (this.lastUsed.get(b) ?? 0));
    const target = Math.floor(this.maxTextures * 0.75);
    let removed = 0;
    for (const k of loaded) {
      if (loaded.length - removed <= target) break;
      if (keepKeys.has(k)) continue;
      this.textures.remove(k);
      this.lastUsed.delete(k);
      removed++;
    }
    return removed;
  }

  get loadedCount() {
    return [...this.lastUsed.keys()].filter((k) => this.textures.exists(k)).length;
  }
}
