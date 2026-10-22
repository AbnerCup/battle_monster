import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { SpeciesPack, type ElementsFile, type PackFile } from '../src/content/SpeciesPack';

export function loadPack(id = 'tuxemon'): SpeciesPack {
  const dir = resolve(__dirname, `../public/packs/${id}`);
  const file = JSON.parse(readFileSync(resolve(dir, 'species.json'), 'utf8')) as PackFile;
  const elements = JSON.parse(readFileSync(resolve(dir, 'elements.json'), 'utf8')) as ElementsFile;
  let assets;
  try {
    assets = JSON.parse(readFileSync(resolve(dir, 'assets.json'), 'utf8'));
  } catch {
    assets = undefined;
  }
  return new SpeciesPack(file, elements, assets);
}
