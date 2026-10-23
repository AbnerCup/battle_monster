// Conexión al endpoint WebSocket de TikFinity Desktop (Event API).
// TikFinity debe estar abierto en la misma PC (Windows) y conectado al live del
// streamer. Que el socket abra solo indica que la app está abierta: los eventos
// empiezan a llegar cuando TikFinity está enganchado a un LIVE en curso.

import type { LiveSource } from './types';
import type { LiveHub } from './LiveHub';
import { normalizeTikFinity } from './normalize';

export const DEFAULT_TIKFINITY_URL = 'ws://127.0.0.1:21213/';

export class TikFinitySource implements LiveSource {
  readonly id = 'tikfinity';
  /** Mensajes recibidos desde la última conexión. */
  events = 0;
  private ws?: WebSocket;
  private stopped = true;
  private retry = 0;
  private retryTimer?: ReturnType<typeof setTimeout>;
  /** Cambia en cada conexión: los avisos de sockets viejos se ignoran. */
  private gen = 0;

  constructor(private hub: LiveHub, public url = DEFAULT_TIKFINITY_URL) {}

  start() {
    this.stop(false);
    this.stopped = false;
    this.retry = 0;
    this.connect();
  }

  stop(report = true) {
    this.stopped = true;
    this.gen++;
    clearTimeout(this.retryTimer);
    const ws = this.ws;
    this.ws = undefined;
    try {
      ws?.close();
    } catch {
      /* ya estaba cerrado */
    }
    if (report) this.hub.status(this.id, 'disconnected');
  }

  private connect() {
    if (this.stopped) return;
    const gen = ++this.gen;
    this.hub.status(this.id, 'connecting', this.url);
    let ws: WebSocket;
    try {
      ws = new WebSocket(this.url);
    } catch {
      this.hub.status(this.id, 'error', `dirección no válida: ${this.url}`);
      return this.scheduleRetry();
    }
    this.ws = ws;

    // Los navegadores avisan error y luego cierre; otros entornos solo error.
    // Ambos caminos terminan aquí una sola vez.
    let lost = false;
    const onLost = () => {
      if (lost || gen !== this.gen) return;
      lost = true;
      this.ws = undefined;
      try {
        ws.close();
      } catch {
        /* ya estaba cerrado */
      }
      this.scheduleRetry();
    };

    ws.onopen = () => {
      if (gen !== this.gen) return;
      this.retry = 0;
      this.events = 0;
      this.hub.status(this.id, 'connected', 'TikFinity abierto, esperando eventos del LIVE');
    };
    ws.onmessage = (ev) => {
      if (gen !== this.gen) return;
      let msg: unknown;
      try {
        msg = JSON.parse(typeof ev.data === 'string' ? ev.data : '');
      } catch {
        return;
      }
      this.hub.raw(this.id, msg);
      const name = String((msg as { event?: unknown })?.event ?? '').toLowerCase();
      if (name === 'streamend') {
        this.events = 0;
        this.hub.status(this.id, 'connected', 'el LIVE terminó');
        return;
      }
      if (this.events++ === 0) this.hub.status(this.id, 'connected', 'recibiendo eventos del LIVE');
      this.hub.push(normalizeTikFinity(msg as Record<string, unknown>));
    };
    ws.onerror = onLost;
    ws.onclose = onLost;
  }

  private scheduleRetry() {
    if (this.stopped) return;
    clearTimeout(this.retryTimer);
    const delay = Math.min(10_000, 1000 * 2 ** this.retry++);
    this.hub.status(this.id, 'error', `sin conexión, ¿TikFinity Desktop está abierto? · reintento en ${Math.round(delay / 1000)} s`);
    this.retryTimer = setTimeout(() => this.connect(), delay);
  }
}
