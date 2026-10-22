#!/usr/bin/env node
// Importa el contenido del juego Essentials de este repositorio (carpeta padre)
// al formato de paquete del juego web: public/packs/essentials/
//
//   - PBS/pokemon.txt y PBS/types.txt  → especies, estadísticas, tipos, evoluciones
//   - Plugins/Pokemon Survivor (Ruby)   → número de cuadros de cada hoja de sprites
//   - Graphics/UI/Survivor Game         → sprites (caminar, reposo, variocolor), VFX, fondos
//   - Audio                             → música, efectos y gritos
//
// No usa dependencias: lee el tamaño de los PNG desde su cabecera y copia
// los archivos. Es incremental: solo copia lo que cambió.
//
// Uso:  node tools/import-essentials.mjs [--root <carpeta del juego>] [--out <salida>] [--force]

import { copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync, openSync, readSync, closeSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const arg = (name, def) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : def;
};
const ROOT = resolve(arg('--root', join(here, '..', '..')));
const OUT = resolve(arg('--out', join(here, '..', 'public', 'packs', 'essentials')));
const FORCE = args.includes('--force');
const QUIET = args.includes('--quiet');

const SG = join(ROOT, 'Graphics', 'UI', 'Survivor Game');
const DIRS = {
  hero: join(SG, 'Pokemon Survivor'),
  heroShiny: join(SG, 'Pokemon Survivor Shiny'),
  wild: join(SG, 'Pokemon Wild'),
  vfx: join(SG, 'VFX'),
  bg: join(SG, 'Background'),
  cries: join(ROOT, 'Audio', 'SE', 'Cries'),
};

const log = (...a) => QUIET || console.log(...a);

if (!existsSync(join(ROOT, 'PBS', 'pokemon.txt')) || !existsSync(DIRS.hero)) {
  console.warn(`[import] No encuentro el juego Essentials en ${ROOT} (falta PBS/pokemon.txt o ${DIRS.hero}).`);
  process.exit(0); // el juego usará el paquete de respaldo (tuxemon)
}

// ----------------------------------------------------------------------------- utilidades
function pngSize(file) {
  const fd = openSync(file, 'r');
  const buf = Buffer.alloc(24);
  readSync(fd, buf, 0, 24, 0);
  closeSync(fd);
  if (buf.readUInt32BE(0) !== 0x89504e47) throw new Error('no es PNG: ' + file);
  return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) };
}

let copied = 0;
function copy(src, rel) {
  const dst = join(OUT, rel);
  mkdirSync(dirname(dst), { recursive: true });
  if (!FORCE && existsSync(dst)) {
    const a = statSync(src);
    const b = statSync(dst);
    if (a.size === b.size && b.mtimeMs >= a.mtimeMs) return rel;
  }
  copyFileSync(src, dst);
  copied++;
  return rel;
}

const listPng = (dir) => (existsSync(dir) ? readdirSync(dir).filter((f) => /\.png$/i.test(f)) : []);

// ----------------------------------------------------------------------------- PBS
function parsePbs(file) {
  const text = readFileSync(file, 'utf8').replace(/^﻿/, '');
  const out = [];
  let cur = null;
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const sec = line.match(/^\[(.+)\]$/);
    if (sec) {
      cur = { id: sec[1].trim() };
      out.push(cur);
      continue;
    }
    const kv = line.match(/^([^=]+?)\s*=\s*(.*)$/);
    if (kv && cur) cur[kv[1].trim()] = kv[2].trim();
  }
  return out;
}

const pbsSpecies = parsePbs(join(ROOT, 'PBS', 'pokemon.txt'));
const pbsTypes = parsePbs(join(ROOT, 'PBS', 'types.txt'));

// ----------------------------------------------------------------------------- tablas Ruby
function rubyFiles(dir) {
  const out = [];
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) out.push(...rubyFiles(p));
    else if (e.name.endsWith('.rb')) out.push(p);
  }
  return out;
}

function hashBlock(src, name) {
  const i = src.indexOf(`${name} = {`);
  if (i < 0) return '';
  let depth = 0;
  for (let j = src.indexOf('{', i); j < src.length; j++) {
    if (src[j] === '{') depth++;
    else if (src[j] === '}' && --depth === 0) return src.slice(i, j + 1);
  }
  return '';
}

const heroFrames = new Map(); // "PIKACHU" / "PIKACHU_IDLE" -> n
const enemyFrames = new Map();
const heroEight = new Set();
const vfxFrames = new Map();
const pluginDir = join(ROOT, 'Plugins');
if (existsSync(pluginDir)) {
  for (const f of rubyFiles(pluginDir)) {
    const src = readFileSync(f, 'utf8');
    for (const [name, map] of [
      ['EIGHT_DIRECTION_ASSET_FRAMES', heroFrames],
      ['EIGHT_DIRECTION_ENEMY_ASSET_FRAMES', enemyFrames],
      ['VFX_FRAME_COUNTS', vfxFrames],
    ]) {
      for (const m of hashBlock(src, name).matchAll(/"([A-Z0-9_]+)"\s*=>\s*(\d+)/g)) map.set(m[1], Number(m[2]));
      for (const m of src.matchAll(new RegExp(`${name}\\["([A-Z0-9_]+)"\\]\\s*=\\s*(\\d+)`, 'g'))) map.set(m[1], Number(m[2]));
    }
    const heroList = src.match(/EIGHT_DIRECTION_HERO_SPRITES\s*=\s*\[([\s\S]*?)\]/);
    if (heroList) for (const m of heroList[1].matchAll(/:([A-Z0-9_]+)/g)) heroEight.add(m[1]);
    const gen9 = hashBlock(src, 'GEN9_ANIMATION_FRAMES');
    for (const m of gen9.matchAll(/([A-Z0-9_]+):\s*\[(\d+)(?:,\s*(\d+))?\]/g)) {
      enemyFrames.set(m[1], Number(m[2]));
      if (m[3]) {
        heroEight.add(m[1]);
        heroFrames.set(m[1], Number(m[2]));
        heroFrames.set(`${m[1]}_IDLE`, Number(m[3]));
      }
    }
  }
}

// Describe cómo cortar una hoja: 8 direcciones (PMD) o charset de RPG Maker (4×4).
function layout(file, frames, eight) {
  const { w, h } = pngSize(file);
  if (eight && h % 8 === 0) {
    let n = frames;
    if (!n || w % n !== 0) {
      // Sin dato en las tablas: cuadros lo más cuadrados posible.
      const fh = h / 8;
      n = 0;
      let best = 9;
      for (let k = 1; k <= 24; k++) {
        if (w % k) continue;
        const r = Math.abs(Math.log((w / k) / fh));
        if (r < best) {
          best = r;
          n = k;
        }
      }
    }
    if (n) return { kind: 'dir8', frames: n, fw: w / n, fh: h / 8 };
  }
  if (w % 4 === 0 && h % 4 === 0) return { kind: 'dir4', frames: 4, fw: w / 4, fh: h / 4 };
  return null;
}

// ----------------------------------------------------------------------------- tipos
const TYPE_ES = {
  NORMAL: 'Normal', FIGHTING: 'Lucha', FLYING: 'Volador', POISON: 'Veneno', GROUND: 'Tierra', ROCK: 'Roca',
  BUG: 'Bicho', GHOST: 'Fantasma', STEEL: 'Acero', QMARKS: '???', FIRE: 'Fuego', WATER: 'Agua', GRASS: 'Planta',
  ELECTRIC: 'Eléctrico', PSYCHIC: 'Psíquico', ICE: 'Hielo', DRAGON: 'Dragón', DARK: 'Siniestro', FAIRY: 'Hada',
  SOUND: 'Sonido', WOOD: 'Madera', STELLAR: 'Astral',
};
const splitList = (v) => (v ? v.split(',').map((s) => s.trim()).filter(Boolean) : []);
const elements = {};
for (const t of pbsTypes) elements[t.id] = { name: TYPE_ES[t.id] ?? t.Name ?? t.id, vs: {} };
// "vs" = multiplicador del atacante contra cada defensor
for (const def of pbsTypes) {
  for (const a of splitList(def.Weaknesses)) if (elements[a]) elements[a].vs[def.id] = 2;
  for (const a of splitList(def.Resistances)) if (elements[a]) elements[a].vs[def.id] = 0.5;
  for (const a of splitList(def.Immunities)) if (elements[a]) elements[a].vs[def.id] = 0;
}

// ----------------------------------------------------------------------------- especies
const byId = new Map(pbsSpecies.map((s) => [s.id, s]));
const prevo = new Map();
for (const s of pbsSpecies) {
  const ev = splitList(s.Evolutions);
  for (let i = 0; i + 2 < ev.length + 1; i += 3) if (ev[i]) prevo.set(ev[i], s.id);
}
const depth = (id) => {
  let d = 0;
  let cur = id;
  while (prevo.has(cur) && d < 5) {
    cur = prevo.get(cur);
    d++;
  }
  return d;
};

const heroFiles = new Set(listPng(DIRS.hero).map((f) => f.replace(/\.png$/i, '')));
const shinyFiles = new Set(listPng(DIRS.heroShiny).map((f) => f.replace(/\.png$/i, '')));
const wildFiles = new Set(listPng(DIRS.wild).map((f) => f.replace(/\.png$/i, '')));
const findIdle = (set, key) => ['_Idle', '_IDLE', '_idle'].map((s) => key + s).find((k) => set.has(k));

const species = [];
const skipped = [];
for (const s of pbsSpecies) {
  const key = s.id;
  let walk = null;
  let idle = null;
  let shiny = null;
  let source = '';

  if (heroFiles.has(key)) {
    const eight = heroEight.has(key) || heroFrames.has(key);
    walk = layout(join(DIRS.hero, `${key}.png`), heroFrames.get(key), eight);
    if (walk) {
      source = 'hero';
      walk.file = copy(join(DIRS.hero, `${key}.png`), `sprites/${key}.png`);
      const idleKey = findIdle(heroFiles, key);
      if (idleKey) {
        idle = layout(join(DIRS.hero, `${idleKey}.png`), heroFrames.get(`${key}_IDLE`), walk.kind === 'dir8');
        if (idle) idle.file = copy(join(DIRS.hero, `${idleKey}.png`), `sprites/${key}_idle.png`);
      }
      if (shinyFiles.has(key)) {
        const sw = layout(join(DIRS.heroShiny, `${key}.png`), heroFrames.get(key), walk.kind === 'dir8');
        if (sw) {
          sw.file = copy(join(DIRS.heroShiny, `${key}.png`), `sprites/shiny/${key}.png`);
          shiny = { walk: sw };
          const sIdleKey = findIdle(shinyFiles, key);
          if (sIdleKey && idle) {
            const si = layout(join(DIRS.heroShiny, `${sIdleKey}.png`), heroFrames.get(`${key}_IDLE`), walk.kind === 'dir8');
            if (si) {
              si.file = copy(join(DIRS.heroShiny, `${sIdleKey}.png`), `sprites/shiny/${key}_idle.png`);
              shiny.idle = si;
            }
          }
        }
      }
    }
  }
  if (!walk && wildFiles.has(key)) {
    walk = layout(join(DIRS.wild, `${key}.png`), enemyFrames.get(key), enemyFrames.has(key));
    if (walk) {
      source = 'wild';
      walk.file = copy(join(DIRS.wild, `${key}.png`), `sprites/${key}.png`);
    }
  }
  if (!walk) {
    skipped.push(key);
    continue;
  }

  const bs = splitList(s.BaseStats).map(Number);
  const [HP, ATK, DEF, SPE, SPA, SPD] = bs.length === 6 ? bs : [50, 50, 50, 50, 50, 50];
  const bst = bs.reduce((a, b) => a + b, 0) || 300;
  const flags = splitList(s.Flags).map((f) => f.toLowerCase());
  const legendary = flags.some((f) => ['legendary', 'mythical', 'ultrabeast', 'paradox'].includes(f));
  const d = depth(key);
  const evs = splitList(s.Evolutions);
  const stage = d === 0 ? (evs.length ? 'basic' : 'single') : d === 1 ? 'stage1' : 'stage2';
  const rarity = legendary || bst >= 525 ? 'especial' : bst >= 405 ? 'raro' : 'comun';
  const cryFile = join(DIRS.cries, `${key}.ogg`);

  species.push({
    slug: key,
    name: s.Name ?? key,
    dexId: species.length + 1,
    types: splitList(s.Types),
    stage,
    rarity,
    bst,
    legendary,
    base: {
      hp: Math.round(70 + HP * 0.9),
      atk: Math.round(12 + Math.max(ATK, SPA) * 0.16),
      def: Math.round(8 + ((DEF + SPD) / 2) * 0.15),
      spd: Math.round(60 + SPE * 0.45),
      dodge: Math.min(12, Math.max(3, Math.round((SPE / 12) * 10) / 10)),
      range: SPA > ATK + 5 ? 240 : 110,
    },
    evolvesTo: null,
    _evo: evs,
    sprite: { walk, idle, shiny, source },
    cry: existsSync(cryFile) ? copy(cryFile, `cries/${key}.ogg`) : null,
    description: s.Category ? `Pokémon ${s.Category}` : '',
    credit: 'Pokémon Survivor Burst (repositorio)',
    creditVerified: false,
  });
}

// Evoluciones: solo hacia especies incluidas; métodos sin nivel → nivel por etapa.
const included = new Set(species.map((s) => s.slug));
for (const s of species) {
  const ev = s._evo;
  delete s._evo;
  for (let i = 0; i + 2 < ev.length + 1; i += 3) {
    const target = ev[i];
    if (!target || !included.has(target)) continue;
    const param = Number(ev[i + 2]);
    const level = Number.isFinite(param) && param > 1 && param <= 100 ? param : s.stage === 'stage1' ? 36 : 30;
    s.evolvesTo = { slug: target, level };
    break;
  }
}

// ----------------------------------------------------------------------------- VFX y fondos
const vfx = {};
for (const f of listPng(DIRS.vfx)) {
  const name = f.replace(/\.png$/i, '');
  const { w, h } = pngSize(join(DIRS.vfx, f));
  let frames = vfxFrames.get(name) ?? 0;
  if (!frames || w % frames) frames = w % h === 0 ? w / h : 4;
  if (w % frames) continue;
  vfx[name] = { file: copy(join(DIRS.vfx, f), `vfx/${f}`), frames, fw: w / frames, fh: h };
}

const backgrounds = [];
const BG_WANTED = ['Forest', 'Forest 2', 'Field', 'Route', 'Cave', 'Cave 2', 'Ice', 'Temple', 'Tower'];
for (const name of BG_WANTED) {
  const src = join(DIRS.bg, `${name}.png`);
  if (!existsSync(src)) continue;
  const { w, h } = pngSize(src);
  backgrounds.push({ name, file: copy(src, `bg/${name.replace(/\s+/g, '_')}.png`), w, h });
}

// ----------------------------------------------------------------------------- audio
const AUDIO = {
  bgm: {
    lobby: 'Audio/BGM/Survivor/Menu.ogg',
    battle: 'Audio/BGM/Survivor/Battle wild.ogg',
    result: 'Audio/BGM/Survivor/Result.ogg',
  },
  sfx: {
    hit: 'Audio/SE/Survivor/Battle damage normal.ogg',
    hitSuper: 'Audio/SE/Survivor/Battle damage super.ogg',
    hitWeak: 'Audio/SE/Survivor/Battle damage weak.ogg',
    faint: 'Audio/SE/Survivor/Pkmn faint.ogg',
    levelUp: 'Audio/SE/Survivor/Pkmn level up.ogg',
    throw: 'Audio/SE/Survivor/Battle throw.ogg',
    shiny: 'Audio/SE/Survivor/Shiny sparkle.ogg',
    item: 'Audio/SE/Survivor/Item get.ogg',
    select: 'Audio/SE/Survivor/GUI sel decision.ogg',
    cursor: 'Audio/SE/Survivor/GUI sel cursor.ogg',
    ballDrop: 'Audio/SE/Battle ball drop.ogg',
    ballShake: 'Audio/SE/Battle ball shake.ogg',
    ballClick: 'Audio/SE/Battle catch click.ogg',
    exclaim: 'Audio/SE/Exclaim.ogg',
    recall: 'Audio/SE/Battle recall.ogg',
    heal: 'Audio/SE/Pkmn healing.ogg',
    capture: 'Audio/ME/Battle capture success.ogg',
    evolution: 'Audio/ME/Evolution success.ogg',
    victory: 'Audio/ME/Badge get.ogg',
    newPokemon: 'Audio/ME/Pkmn get.ogg',
  },
};
const audio = { bgm: {}, sfx: {} };
for (const group of ['bgm', 'sfx']) {
  for (const [k, rel] of Object.entries(AUDIO[group])) {
    const src = join(ROOT, rel);
    if (existsSync(src)) audio[group][k] = copy(src, `audio/${group}-${k}.ogg`);
  }
}

// ----------------------------------------------------------------------------- salida
const counts = species.reduce((a, s) => ((a[s.rarity] = (a[s.rarity] ?? 0) + 1), a), {});
const pack = {
  id: 'essentials',
  name: 'Pokémon Survivor Burst',
  noun: 'Pokémon',
  format: 2,
  license: 'Uso privado: arte, nombres y sonidos de Pokémon (© Nintendo / Creatures / GAME FREAK) y sprites estilo PMD',
  source: 'Repositorio battle_monster (Pokémon Essentials 21.1)',
  sheet: null,
  species,
};
mkdirSync(OUT, { recursive: true });
writeFileSync(join(OUT, 'species.json'), JSON.stringify(pack));
writeFileSync(join(OUT, 'elements.json'), JSON.stringify(elements, null, 1));
writeFileSync(join(OUT, 'assets.json'), JSON.stringify({ vfx, backgrounds, audio }, null, 1));
writeFileSync(
  join(OUT, 'CREDITS.md'),
  `# Paquete "essentials"\n\nGenerado con tools/import-essentials.mjs desde el juego Essentials del repositorio.\n\n` +
    `- Pokémon, sus nombres, música y efectos de sonido: © Nintendo / Creatures Inc. / GAME FREAK inc.\n` +
    `- Sprites de caminar y reposo: estilo PMD (proyecto comunitario de sprites) incluidos en el juego del repositorio.\n` +
    `- Datos (PBS) y motor original: Pokémon Essentials 21.1 y plugin "Pokemon Survivor" (créditos: ClessioTV, Codex).\n\n` +
    `Este paquete es para uso privado/pruebas. Para un producto comercial usa criaturas propias o con licencia.\n`,
);

log(
  `[import] ${species.length} especies (${Object.entries(counts).map(([k, v]) => `${k}: ${v}`).join(', ')}), ` +
    `${species.filter((s) => s.sprite.idle).length} con reposo, ${species.filter((s) => s.sprite.shiny).length} con variocolor, ` +
    `${species.filter((s) => s.cry).length} con grito, ${Object.keys(vfx).length} VFX, ${backgrounds.length} fondos, ` +
    `${Object.keys(audio.bgm).length + Object.keys(audio.sfx).length} audios → ${OUT} (${copied} archivos copiados)`,
);
if (skipped.length && !QUIET) log(`[import] ${skipped.length} especies del PBS sin sprite (se omiten).`);
