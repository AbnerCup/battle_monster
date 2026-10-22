// Punto único de entrada de eventos del live: consolida rachas de regalos,
// descarta duplicados y reparte eventos normalizados al juego.

import type { GiftEvent, LiveEvent, RawGift, SourceStatus } from './types';

type Listener = (e: LiveEvent) => void;
type StatusListener = (sourceId: string, s: SourceStatus, detail?: string) => void;
type RawListener = (sourceId: string, raw: unknown) => void;

interface Streak {
  last: RawGift;
  timer: ReturnType<typeof setTimeout>;
}

export class LiveHub {
  private listeners = new Set<Listener>();
  private statusListeners = new Set<StatusListener>();
  private rawListeners = new Set<RawListener>();
  private streaks = new Map<string, Streak>();
  private seen = new Map<string, number>();

  /** Si una racha no recibe su evento final, se cierra sola tras este tiempo. */
  constructor(private streakTimeoutMs = 8000) {}

  on(cb: Listener): () => void {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }
  onStatus(cb: StatusListener): () => void {
    this.statusListeners.add(cb);
    return () => this.statusListeners.delete(cb);
  }
  onRaw(cb: RawListener): () => void {
    this.rawListeners.add(cb);
    return () => this.rawListeners.delete(cb);
  }

  status(sourceId: string, s: SourceStatus, detail?: string) {
    this.statusListeners.forEach((cb) => cb(sourceId, s, detail));
  }
  raw(sourceId: string, raw: unknown) {
    this.rawListeners.forEach((cb) => cb(sourceId, raw));
  }

  /** Entrada desde cualquier fuente. */
  push(e: LiveEvent | RawGift | null) {
    if (!e) return;
    if (e.type !== 'gift-raw') return this.emit(e);
    this.handleGift(e);
  }

  private handleGift(g: RawGift) {
    if (g.msgId) {
      const now = Date.now();
      if (this.seen.has(g.msgId)) return;
      this.seen.set(g.msgId, now);
      if (this.seen.size > 2000) {
        for (const [k, t] of this.seen) if (now - t > 60_000) this.seen.delete(k);
      }
    }

    const key = `${g.user.userId}:${g.giftId}`;
    const open = this.streaks.get(key);

    if (g.streaking) {
      if (open) clearTimeout(open.timer);
      const timer = setTimeout(() => this.closeStreak(key), this.streakTimeoutMs);
      this.streaks.set(key, { last: g, timer });
      return;
    }

    // Evento final de la racha (o regalo no combinable).
    if (open) {
      clearTimeout(open.timer);
      this.streaks.delete(key);
    }
    this.emit(toGift(g, g.repeatCount));
  }

  private closeStreak(key: string) {
    const s = this.streaks.get(key);
    if (!s) return;
    this.streaks.delete(key);
    this.emit(toGift(s.last, s.last.repeatCount));
  }

  private emit(e: LiveEvent) {
    this.listeners.forEach((cb) => {
      try {
        cb(e);
      } catch (err) {
        console.error('[LiveHub] listener falló', err);
      }
    });
  }

  dispose() {
    for (const s of this.streaks.values()) clearTimeout(s.timer);
    this.streaks.clear();
  }
}

function toGift(g: RawGift, count: number): GiftEvent {
  return {
    type: 'gift',
    user: g.user,
    ts: g.ts,
    giftId: g.giftId,
    giftName: g.giftName,
    coins: g.coins,
    count,
    giftImageUrl: g.giftImageUrl,
  };
}
