// Conexión al WebSocket local de TikFinity Desktop.
// TikFinity debe estar abierto en la misma PC y conectado al live del streamer.

import type { LiveSource } from './types';
import type { LiveHub } from './LiveHub';
import { normalizeTikFinity } from './normalize';

export const DEFAULT_TIKFINITY_URL = 'ws://127.0.0.1:21213/';

export class TikFinitySource implements LiveSource {
  readonly id = 'tikfinity';
  private ws?: WebSocket;
  private stopped = true;
  private retry = 0;
  private retryTimer?: ReturnType<typeof setTimeout>;

  constructor(private hub: LiveHub, public url = DEFAULT_TIKFINITY_URL) {}

  start() {
    this.stopped = false;
    this.connect();
  }

  stop() {
    this.stopped = true;
    clearTimeout(this.retryTimer);
    this.ws?.close();
    this.ws = undefined;
    this.hub.status(this.id, 'disconnected');
  }

  private connect() {
    if (this.stopped) return;
    this.hub.status(this.id, 'connecting', this.url);
    let ws: WebSocket;
    try {
      ws = new WebSocket(this.url);
    } catch (err) {
      this.hub.status(this.id, 'error', String(err));
      return this.scheduleRetry();
    }
    this.ws = ws;

    ws.onopen = () => {
      this.retry = 0;
      this.hub.status(this.id, 'connected', this.url);
    };
    ws.onmessage = (ev) => {
      let msg: unknown;
      try {
        msg = JSON.parse(typeof ev.data === 'string' ? ev.data : '');
      } catch {
        return;
      }
      this.hub.raw(this.id, msg);
      this.hub.push(normalizeTikFinity(msg as Record<string, unknown>));
    };
    ws.onerror = () => this.hub.status(this.id, 'error', 'No se pudo conectar. ¿TikFinity Desktop está abierto?');
    ws.onclose = () => {
      if (this.ws === ws) this.ws = undefined;
      if (!this.stopped) this.scheduleRetry();
    };
  }

  private scheduleRetry() {
    if (this.stopped) return;
    const delay = Math.min(10_000, 1000 * 2 ** this.retry++);
    this.hub.status(this.id, 'connecting', `reintento en ${Math.round(delay / 1000)} s`);
    this.retryTimer = setTimeout(() => this.connect(), delay);
  }
}
