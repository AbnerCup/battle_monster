// Servidor local de producción: sirve dist/ y el proxy de avatares.
// Uso: npm run build && npm run preview   →   http://localhost:4173/?obs=1
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createAvatarHandler } from './avatarProxy.mjs';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
const dist = join(root, 'dist');
const port = Number(process.env.PORT ?? 4173);
const avatar = createAvatarHandler({ cacheDir: join(root, '.cache', 'avatars') });

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ogg': 'audio/ogg',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.woff2': 'font/woff2',
  '.woff': 'font/woff',
  '.md': 'text/markdown; charset=utf-8',
};

createServer(async (req, res) => {
  if (req.url?.startsWith('/avatar')) return avatar(req, res);
  const path = decodeURIComponent(new URL(req.url ?? '/', 'http://local').pathname);
  let file = normalize(join(dist, path));
  if (!file.startsWith(dist)) {
    res.statusCode = 403;
    return res.end();
  }
  try {
    if ((await stat(file)).isDirectory()) file = join(file, 'index.html');
    const body = await readFile(file);
    res.setHeader('content-type', TYPES[extname(file)] ?? 'application/octet-stream');
    res.end(body);
  } catch {
    res.statusCode = 404;
    res.end('no encontrado');
  }
}).listen(port, () => {
  console.log(`Vortex Rival en http://localhost:${port}/  (OBS: http://localhost:${port}/?obs=1)`);
});
