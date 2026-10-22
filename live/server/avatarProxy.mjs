// Proxy + caché en disco para las fotos de perfil de TikTok.
//
// Por qué existe: las URLs del CDN de TikTok son firmadas (caducan) y no envían
// cabeceras CORS, así que WebGL no puede usarlas como textura. El juego pide
// /avatar?u=<url> y este módulo descarga la imagen una vez, la guarda y la sirve
// con CORS abierto. Se usa en desarrollo (plugin de Vite) y en producción
// (server/serve.mjs). En la app de escritorio (Electron) iría en el proceso main.

import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const ALLOWED_HOSTS = [
  /\.tiktokcdn\.com$/i,
  /\.tiktokcdn-us\.com$/i,
  /\.tiktokcdn-eu\.com$/i,
  /\.ibyteimg\.com$/i,
  /\.byteimg\.com$/i,
  /\.muscdn\.com$/i,
];
const MAX_BYTES = 2 * 1024 * 1024;

export function createAvatarHandler({ cacheDir }) {
  const ready = mkdir(cacheDir, { recursive: true });

  return async function handle(req, res) {
    const reqUrl = new URL(req.url, 'http://local');
    const target = reqUrl.searchParams.get('u');
    let parsed;
    try {
      parsed = new URL(target ?? '');
    } catch {
      return send(res, 400, 'url inválida');
    }
    if (parsed.protocol !== 'https:' || !ALLOWED_HOSTS.some((r) => r.test(parsed.hostname))) {
      return send(res, 403, 'host no permitido');
    }

    // La firma (query) cambia; la ruta identifica la imagen.
    const key = createHash('sha1').update(parsed.hostname + parsed.pathname).digest('hex');
    const file = join(cacheDir, key);
    await ready;

    try {
      const [body, meta] = await Promise.all([readFile(file), readFile(file + '.type', 'utf8')]);
      return sendImage(res, body, meta || 'image/jpeg');
    } catch {
      /* no está en caché */
    }

    try {
      const r = await fetch(parsed, { headers: { 'user-agent': 'Mozilla/5.0' } });
      if (!r.ok) return send(res, 502, `origen respondió ${r.status}`);
      const type = r.headers.get('content-type') ?? 'image/jpeg';
      if (!type.startsWith('image/')) return send(res, 502, 'no es imagen');
      const body = Buffer.from(await r.arrayBuffer());
      if (body.length > MAX_BYTES) return send(res, 502, 'imagen demasiado grande');
      await Promise.all([writeFile(file, body), writeFile(file + '.type', type)]);
      return sendImage(res, body, type);
    } catch (err) {
      return send(res, 502, 'no se pudo descargar: ' + (err?.message ?? err));
    }
  };
}

function sendImage(res, body, type) {
  res.statusCode = 200;
  res.setHeader('content-type', type);
  res.setHeader('access-control-allow-origin', '*');
  res.setHeader('cache-control', 'public, max-age=86400');
  res.end(body);
}

function send(res, status, msg) {
  res.statusCode = status;
  res.setHeader('content-type', 'text/plain; charset=utf-8');
  res.setHeader('access-control-allow-origin', '*');
  res.end(msg);
}
