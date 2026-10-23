// Conexión real por WebSocket contra un servidor que imita el endpoint de
// TikFinity Desktop (ws://127.0.0.1:21213/), con los mensajes tal como llegan.

import { afterEach, describe, expect, it } from 'vitest';
import { WebSocketServer, type WebSocket as WsSocket } from 'ws';
import type { AddressInfo } from 'node:net';
import { LiveHub } from '../src/live/LiveHub';
import { TikFinitySource } from '../src/live/TikFinitySource';
import type { LiveEvent } from '../src/live/types';

const wait = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function until(cond: () => boolean, ms = 4000) {
  const t0 = Date.now();
  while (!cond()) {
    if (Date.now() - t0 > ms) throw new Error('tiempo de espera agotado');
    await wait(20);
  }
}

function serve(port = 0) {
  const wss = new WebSocketServer({ host: '127.0.0.1', port });
  const sockets: WsSocket[] = [];
  wss.on('connection', (s) => sockets.push(s));
  const ready = new Promise<number>((ok) => wss.on('listening', () => ok((wss.address() as AddressInfo).port)));
  const send = (msg: unknown) => sockets.forEach((s) => s.send(JSON.stringify(msg)));
  const close = () => new Promise<void>((ok) => { sockets.forEach((s) => s.terminate()); wss.close(() => ok()); });
  return { wss, sockets, ready, send, close };
}

let cleanup: Array<() => unknown> = [];
afterEach(async () => {
  for (const fn of cleanup.reverse()) await fn();
  cleanup = [];
});

describe('TikFinitySource (endpoint WebSocket)', () => {
  it('recibe chat y rachas de regalos e informa el estado del LIVE', async () => {
    const srv = serve();
    const port = await srv.ready;
    cleanup.push(srv.close);

    const hub = new LiveHub();
    const events: LiveEvent[] = [];
    const statuses: string[] = [];
    hub.on((e) => events.push(e));
    hub.onStatus((_id, s, d) => statuses.push(`${s}:${d ?? ''}`));

    const src = new TikFinitySource(hub, `ws://127.0.0.1:${port}/`);
    cleanup.push(() => src.stop());
    src.start();
    await until(() => srv.sockets.length === 1 && statuses.some((s) => s.includes('esperando')));

    // Chat con el sobre que entrega TikFinity: createTime en milisegundos como texto.
    srv.send({ event: 'chat', data: { comment: '!mochila 2', userId: '7012', uniqueId: 'juan', nickname: 'Juan', createTime: '1761177600000' } });
    // Racha de Rosas: tres parciales y el final con el total.
    const rose = { userId: '7012', uniqueId: 'juan', nickname: 'Juan', giftId: 5655, giftName: 'Rose', diamondCount: 1, giftType: 1 };
    for (let i = 1; i <= 3; i++) srv.send({ event: 'gift', data: { ...rose, repeatCount: i, repeatEnd: false, msgId: `m${i}` } });
    srv.send({ event: 'gift', data: { ...rose, repeatCount: 5, repeatEnd: true, msgId: 'm5' } });
    srv.send({ event: 'streamEnd', data: {} });

    await until(() => events.length >= 2 && statuses.some((s) => s.includes('terminó')));
    expect(events[0]).toMatchObject({ type: 'chat', text: '!mochila 2', ts: 1761177600000, user: { userId: '7012', nickname: 'Juan' } });
    expect(events[1]).toMatchObject({ type: 'gift', giftName: 'Rose', count: 5, coins: 1 });
    expect(events).toHaveLength(2);
    expect(statuses.findIndex((s) => s.includes('recibiendo'))).toBeGreaterThan(statuses.findIndex((s) => s.includes('esperando')));
  });

  it('se reconecta solo si TikFinity se abre después que el juego', async () => {
    const probe = serve();
    const port = await probe.ready;
    await probe.close(); // puerto libre: TikFinity todavía cerrado

    const hub = new LiveHub();
    const statuses: string[] = [];
    hub.onStatus((_id, s, d) => statuses.push(`${s}:${d ?? ''}`));
    const src = new TikFinitySource(hub, `ws://127.0.0.1:${port}/`);
    cleanup.push(() => src.stop());
    src.start();
    await until(() => statuses.some((s) => s.includes('reintento')));

    const srv = serve(port);
    await srv.ready;
    cleanup.push(srv.close);
    await until(() => srv.sockets.length === 1, 6000);
    await until(() => statuses.at(-1)?.startsWith('connected') ?? false);
  }, 10_000);
});
