import { describe, expect, it, vi } from 'vitest';
import { LiveHub } from '../src/live/LiveHub';
import { normalizeTikFinity } from '../src/live/normalize';
import type { LiveEvent } from '../src/live/types';

describe('normalizeTikFinity', () => {
  it('lee el formato plano (v1)', () => {
    const e = normalizeTikFinity({
      event: 'chat',
      data: { userId: '123', uniqueId: 'juan', nickname: 'Juan', profilePictureUrl: 'https://p16.tiktokcdn.com/a.jpg', comment: '!mochila' },
    });
    expect(e).toMatchObject({ type: 'chat', text: '!mochila', user: { userId: '123', uniqueId: 'juan', avatarUrl: 'https://p16.tiktokcdn.com/a.jpg' } });
  });

  it('lee el formato anidado (v2)', () => {
    const e = normalizeTikFinity({
      event: 'gift',
      data: {
        user: { userId: '9', uniqueId: 'ana', nickname: 'Ana', profilePicture: { url: ['https://p77.tiktokcdn.com/b.webp'] } },
        giftId: 5655,
        repeatCount: 3,
        repeatEnd: true,
        giftDetails: { giftName: 'Rose', diamondCount: 1, giftType: 1 },
      },
    });
    expect(e).toMatchObject({ type: 'gift-raw', giftName: 'Rose', coins: 1, repeatCount: 3, streaking: false, user: { nickname: 'Ana', avatarUrl: 'https://p77.tiktokcdn.com/b.webp' } });
  });

  it('marca rachas abiertas solo en regalos combinables', () => {
    const open = normalizeTikFinity({ event: 'gift', data: { userId: '1', uniqueId: 'a', giftId: 1, giftName: 'Rose', giftType: 1, repeatEnd: false } });
    const single = normalizeTikFinity({ event: 'gift', data: { userId: '1', uniqueId: 'a', giftId: 2, giftName: 'Money Gun', giftType: 2, repeatEnd: false } });
    expect(open).toMatchObject({ streaking: true });
    expect(single).toMatchObject({ streaking: false });
  });

  it('traduce social a follow/share y roomUser a viewers', () => {
    expect(normalizeTikFinity({ event: 'social', data: { userId: '1', uniqueId: 'a', displayType: 'pm_mt_msg_viewer_follow' } })).toMatchObject({ type: 'follow' });
    expect(normalizeTikFinity({ event: 'roomUser', data: { viewerCount: 321 } })).toMatchObject({ type: 'viewers', count: 321 });
    expect(normalizeTikFinity({ event: 'chat', data: { comment: 'sin usuario' } })).toBeNull();
  });
});

describe('LiveHub', () => {
  const user = { userId: '1', uniqueId: 'a', nickname: 'A' };
  const raw = (repeatCount: number, streaking: boolean, msgId?: string) => ({
    type: 'gift-raw' as const, user, ts: 0, giftId: 5655, giftName: 'Rose', coins: 1, repeatCount, streaking, msgId,
  });

  it('consolida una racha en un solo regalo con el total', () => {
    const hub = new LiveHub();
    const got: LiveEvent[] = [];
    hub.on((e) => got.push(e));
    hub.push(raw(1, true));
    hub.push(raw(2, true));
    hub.push(raw(3, true));
    hub.push(raw(3, false));
    expect(got).toHaveLength(1);
    expect(got[0]).toMatchObject({ type: 'gift', count: 3 });
  });

  it('cierra rachas sin evento final por tiempo', () => {
    vi.useFakeTimers();
    const hub = new LiveHub(1000);
    const got: LiveEvent[] = [];
    hub.on((e) => got.push(e));
    hub.push(raw(1, true));
    hub.push(raw(4, true));
    vi.advanceTimersByTime(1500);
    expect(got).toEqual([expect.objectContaining({ type: 'gift', count: 4 })]);
    vi.useRealTimers();
  });

  it('descarta mensajes duplicados por msgId', () => {
    const hub = new LiveHub();
    const got: LiveEvent[] = [];
    hub.on((e) => got.push(e));
    hub.push(raw(1, false, 'x'));
    hub.push(raw(1, false, 'x'));
    expect(got).toHaveLength(1);
  });
});
