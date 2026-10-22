// Pruebas del importador y del paquete "essentials". Se saltan si el juego
// Essentials no está en la carpeta padre (p. ej. si se copia solo live/).
import { execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { GAME } from '../src/config/game';
import { BattleSim, type FighterInit } from '../src/core/battle/BattleSim';
import { statsFor } from '../src/core/progression';
import { Rng } from '../src/core/rng';
import { SpeciesPack, type AssetsFile, type ElementsFile, type PackFile } from '../src/content/SpeciesPack';

const root = resolve(__dirname, '../..');
const hasGame = existsSync(join(root, 'PBS', 'pokemon.txt'));
let out = '';
let pack: SpeciesPack;

describe.skipIf(!hasGame)('importador Essentials', () => {
  beforeAll(() => {
    out = mkdtempSync(join(tmpdir(), 'pack-'));
    execFileSync(process.execPath, [resolve(__dirname, '../tools/import-essentials.mjs'), '--out', out, '--quiet'], { stdio: 'pipe' });
    const read = <T,>(f: string) => JSON.parse(readFileSync(join(out, f), 'utf8')) as T;
    pack = new SpeciesPack(read<PackFile>('species.json'), read<ElementsFile>('elements.json'), read<AssetsFile>('assets.json'));
  });
  afterAll(() => out && rmSync(out, { recursive: true, force: true }));

  it('genera especies con hojas válidas y archivos existentes', () => {
    expect(pack.file.format).toBe(2);
    expect(pack.file.species.length).toBeGreaterThan(200);
    for (const s of pack.file.species) {
      const w = s.sprite.walk;
      expect(['dir8', 'dir4']).toContain(w.kind);
      expect(Number.isInteger(w.fw) && Number.isInteger(w.fh) && w.frames > 0).toBe(true);
      expect(existsSync(join(out, w.file))).toBe(true);
      if (s.sprite.idle) expect(existsSync(join(out, s.sprite.idle.file))).toBe(true);
      if (s.evolvesTo) expect(pack.bySlug.has(s.evolvesTo.slug)).toBe(true);
    }
  });

  it('reparte rarezas y tiene iniciales', () => {
    expect(pack.byRarity.comun.length).toBeGreaterThan(50);
    expect(pack.byRarity.raro.length).toBeGreaterThan(50);
    expect(pack.byRarity.especial.length).toBeGreaterThan(10);
    expect(pack.starters.length).toBeGreaterThan(30);
    expect(pack.starters.every((s) => s.rarity === 'comun')).toBe(true);
  });

  it('usa la tabla de tipos del PBS', () => {
    expect(pack.typeMultiplier(['FIRE'], ['GRASS'])).toBe(2);
    expect(pack.typeMultiplier(['WATER'], ['FIRE'])).toBe(2);
    expect(pack.typeMultiplier(['FIRE'], ['WATER'])).toBe(0.5);
    expect(pack.typeName('ELECTRIC')).toBe('Eléctrico');
  });

  it('copia efectos, fondos y audio', () => {
    expect(pack.assets.vfx.VFX_HIT?.frames).toBeGreaterThan(1);
    expect(pack.assets.backgrounds.length).toBeGreaterThan(0);
    expect(pack.assets.audio.sfx.hit).toBeTruthy();
  });

  it('las batallas con estadísticas Pokémon duran lo previsto', () => {
    const times: number[] = [];
    for (let seed = 1; seed <= 12; seed++) {
      const rng = new Rng(seed * 7);
      const init: FighterInit[] = Array.from({ length: 20 }, (_, i) => {
        const sp = pack.random(rng.chance(0.7) ? 'comun' : 'raro', rng);
        const c = { id: 'c' + i, slug: sp.slug, level: rng.int(1, 12), xp: 0, caughtAt: 0 };
        return { id: 'u' + i, seat: i + 1, name: 'P' + i, slug: sp.slug, level: c.level, types: sp.types, stats: statsFor(c, pack) };
      });
      const sim = new BattleSim(init, { arena: GAME.battle.arena, timeLimit: 30, suddenDeath: 12, seed, typeMult: (a, d) => pack.typeMultiplier(a, d) });
      while (!sim.done) sim.step(1 / 30);
      times.push(sim.time);
    }
    times.sort((a, b) => a - b);
    const median = times[Math.floor(times.length / 2)];
    expect(median).toBeGreaterThan(15);
    expect(median).toBeLessThan(40);
  });
});
