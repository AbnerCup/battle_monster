#!/usr/bin/env node
// Puente TikFinity → modo torneo del juego Essentials (Game.exe).
//
// El plugin "050_TikTok_Tournament" del juego se conecta por TCP a 127.0.0.1:8081
// y espera líneas JSON (spawn_player, registration_tick, start_tournament, comment,
// like, gift). Ese servidor no venía en el repositorio: este archivo lo implementa
// leyendo los eventos del live desde TikFinity Desktop.
//
// Uso (PC del streamer, con TikFinity abierto):
//   npm run bridge            (dentro de la carpeta live)
// y luego abrir Game.exe. Opciones por variables de entorno:
//   TIKFINITY_URL  (ws://127.0.0.1:21213/)   BRIDGE_PORT (8081)
//   REGISTRATION_SEC (60)                     GAME_ROOT (carpeta padre de live/)

import { createWriteStream, existsSync, mkdirSync } from 'node:fs';
import { createServer } from 'node:net';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import WebSocket from 'ws';

const here = dirname(fileURLToPath(import.meta.url));
const TIKFINITY_URL = process.env.TIKFINITY_URL || 'ws://127.0.0.1:21213/';
const PORT = Number(process.env.BRIDGE_PORT || 8081);
const REGISTRATION_SEC = Number(process.env.REGISTRATION_SEC || 60);
const GAME_ROOT = resolve(process.env.GAME_ROOT || join(here, '..', '..'));
const AVATAR_DIR = join(GAME_ROOT, 'Graphics', 'Avatars');

const log = (...a) => console.log(new Date().toLocaleTimeString(), ...a);

// ------------------------------------------------------------------ juego (TCP)
const clients = new Set();
let phase = 'registration'; // registration | tournament
let countdown = REGISTRATION_SEC;
const registered = new Map(); // userId -> { tier, giftValue }

function send(obj) {
  const line = JSON.stringify(obj) + '\n';
  for (const c of clients) c.write(line);
}

function resetTournament(reason) {
  phase = 'registration';
  countdown = REGISTRATION_SEC;
  registered.clear();
  log(`Nueva inscripción (${reason}).`);
}

createServer((sock) => {
  clients.add(sock);
  log(`Juego conectado (${clients.size}).`);
  sock.setEncoding('utf8');
  let buf = '';
  sock.on('data', (d) => {
    buf += d;
    let i;
    while ((i = buf.indexOf('\n')) >= 0) {
      const line = buf.slice(0, i).trim();
      buf = buf.slice(i + 1);
      if (!line) continue;
      try {
        const msg = JSON.parse(line);
        if (msg.event === 'tournament_reset') resetTournament('el juego terminó el torneo');
      } catch {
        /* línea no JSON */
      }
    }
  });
  sock.on('close', () => clients.delete(sock));
  sock.on('error', () => clients.delete(sock));
}).listen(PORT, '127.0.0.1', () => log(`Esperando a Game.exe en 127.0.0.1:${PORT}`));

// Cuenta regresiva de inscripción (el juego muestra el valor que le enviamos).
setInterval(() => {
  if (phase !== 'registration' || !clients.size) return;
  if (registered.size === 0) {
    countdown = REGISTRATION_SEC; // espera al primer inscrito
    send({ event: 'registration_tick', time_left: countdown });
    return;
  }
  countdown = Math.max(0, countdown - 1);
  send({ event: 'registration_tick', time_left: countdown });
  if (countdown === 0 || registered.size >= 16) {
    phase = 'tournament';
    send({ event: 'start_tournament' });
    log(`Torneo iniciado con ${registered.size} inscritos.`);
  }
}, 1000);

// ------------------------------------------------------------------ avatares
mkdirSync(AVATAR_DIR, { recursive: true });
async function saveAvatar(userId, url) {
  const rel = `Graphics/Avatars/${userId}.png`;
  const file = join(GAME_ROOT, rel);
  if (existsSync(file)) return rel;
  if (!url) return null;
  try {
    const r = await fetch(url);
    if (!r.ok) return null;
    const buf = Buffer.from(await r.arrayBuffer());
    // El juego solo abre PNG o JPEG (lo comprueba por la firma del archivo).
    const png = buf[0] === 0x89 && buf[1] === 0x50;
    const jpg = buf[0] === 0xff && buf[1] === 0xd8;
    if (!png && !jpg) return null;
    await new Promise((ok, ko) => createWriteStream(file).on('error', ko).end(buf, ok));
    return rel;
  } catch {
    return null;
  }
}

// ------------------------------------------------------------------ TikFinity
const tierFor = (coins) => (coins >= 500 ? 4 : coins >= 100 ? 3 : coins >= 5 ? 2 : 1);
const pick = (o, ...keys) => keys.map((k) => o?.[k]).find((v) => v !== undefined && v !== null && v !== '');

function userOf(data) {
  const u = data?.user && typeof data.user === 'object' ? { ...data, ...data.user } : data || {};
  const pic = u.profilePictureUrl || u.profilePicture?.url?.[0] || u.profilePicture?.urls?.[0];
  const userId = String(pick(u, 'userId', 'uniqueId') ?? '');
  if (!userId) return null;
  return { userId, nickname: String(pick(u, 'nickname', 'uniqueId') ?? userId), avatarUrl: pic };
}

async function register(user, tier, giftValue) {
  if (phase !== 'registration') return;
  const prev = registered.get(user.userId);
  if (prev && prev.tier >= tier) return;
  registered.set(user.userId, { tier, giftValue: (prev?.giftValue ?? 0) + giftValue });
  const pfp = await saveAvatar(user.userId, user.avatarUrl);
  send({ event: 'spawn_player', user_id: user.userId, user: user.nickname, tier, game_pfp: pfp, gift_value: giftValue, is_host: false });
  log(`${prev ? 'Mejora' : 'Inscrito'}: ${user.nickname} (nivel ${tier}).`);
}

function onTikFinity(msg) {
  const event = String(msg?.event ?? '').toLowerCase();
  const data = msg?.data ?? {};
  const user = userOf(data);
  if (!user) return;
  switch (event) {
    case 'like':
      register(user, 1, 0);
      send({ event: 'like', like_count: Number(data.likeCount ?? 1) });
      break;
    case 'chat': {
      const comment = String(data.comment ?? '');
      if (/^!(jugar|unirme|join|play)\b/i.test(comment)) register(user, 1, 0);
      send({ event: 'comment', user: user.nickname, comment });
      break;
    }
    case 'gift': {
      const g = { ...(data.gift ?? {}), ...(data.giftDetails ?? {}) };
      const giftType = Number(data.giftType ?? g.giftType ?? 0);
      if (giftType === 1 && data.repeatEnd === false) return; // racha abierta: se espera el total
      const coins = Number(data.diamondCount ?? g.diamondCount ?? 1) * Math.max(1, Number(data.repeatCount ?? 1));
      const name = String(data.giftName ?? g.giftName ?? 'Regalo');
      if (phase === 'registration') register(user, tierFor(coins), coins);
      else send({ event: 'gift', user: user.nickname, gift_name: name, gift_value: coins, target_player: user.nickname });
      break;
    }
  }
}

let retry = 0;
function connect() {
  const ws = new WebSocket(TIKFINITY_URL);
  ws.on('open', () => {
    retry = 0;
    log(`Conectado a TikFinity (${TIKFINITY_URL}).`);
  });
  ws.on('message', (raw) => {
    try {
      onTikFinity(JSON.parse(String(raw)));
    } catch {
      /* mensaje no JSON */
    }
  });
  ws.on('close', () => {
    const wait = Math.min(10_000, 1000 * 2 ** retry++);
    log(`Sin conexión con TikFinity; reintento en ${Math.round(wait / 1000)} s. ¿Está abierto TikFinity Desktop?`);
    setTimeout(connect, wait);
  });
  ws.on('error', () => {});
}
connect();
