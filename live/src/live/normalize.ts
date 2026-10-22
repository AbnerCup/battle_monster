// Traduce los mensajes de TikFinity al formato del juego.
//
// TikFinity reenvía los eventos de TikTok LIVE como JSON {event, data}, con el
// formato de TikTok-Live-Connector. Hay dos variantes en circulación:
//  - plana (v1): data.uniqueId, data.nickname, data.profilePictureUrl, data.giftName...
//  - anidada (v2): data.user.uniqueId, data.user.profilePicture.url[0], data.giftDetails...
// Este módulo acepta ambas. Si TikFinity cambia algo, este es el único archivo a tocar.

import type { LiveEvent, LiveUser, RawGift } from './types';

type Any = Record<string, any>;

const str = (v: unknown): string | undefined =>
  v === undefined || v === null || v === '' ? undefined : String(v);
const num = (v: unknown, def = 0): number => {
  const n = Number(v);
  return Number.isFinite(n) ? n : def;
};

function firstUrl(pic: unknown): string | undefined {
  if (!pic) return undefined;
  if (typeof pic === 'string') return pic;
  const p = pic as Any;
  const list = p.url ?? p.urls ?? p.urlList ?? p.url_list;
  if (Array.isArray(list) && list.length) return String(list[0]);
  return undefined;
}

export function readUser(data: Any): LiveUser | undefined {
  const u: Any = data?.user && typeof data.user === 'object' ? { ...data, ...data.user } : data ?? {};
  const uniqueId = str(u.uniqueId) ?? str(u.unique_id) ?? str(u.displayId);
  const userId = str(u.userId) ?? str(u.user_id) ?? str(u.id) ?? uniqueId;
  if (!userId || !uniqueId) return undefined;
  return {
    userId,
    uniqueId,
    nickname: str(u.nickname) ?? uniqueId,
    avatarUrl:
      str(u.profilePictureUrl) ??
      firstUrl(u.profilePicture) ??
      firstUrl(u.avatarThumb) ??
      firstUrl(u.avatar_thumb) ??
      undefined,
  };
}

export type Normalized = LiveEvent | RawGift | null;

export function normalizeTikFinity(msg: Any, now = Date.now()): Normalized {
  if (!msg || typeof msg !== 'object') return null;
  const event = String(msg.event ?? msg.type ?? '').toLowerCase();
  const data: Any = msg.data ?? {};
  const ts = num(data.createTime ?? data.timestamp ?? data.common?.createTime, now) || now;

  if (event === 'roomuser') {
    const count = num(data.viewerCount ?? data.totalUser, -1);
    return count >= 0 ? { type: 'viewers', count, ts } : null;
  }

  const user = readUser(data);
  if (!user) return null;

  switch (event) {
    case 'member':
      return { type: 'join', user, ts };
    case 'like':
      return { type: 'like', user, count: Math.max(1, num(data.likeCount, 1)), ts };
    case 'chat': {
      const text = str(data.comment) ?? str(data.content) ?? '';
      return text ? { type: 'chat', user, text, ts } : null;
    }
    case 'follow':
      return { type: 'follow', user, ts };
    case 'share':
      return { type: 'share', user, ts };
    case 'social': {
      const t = String(data.displayType ?? data.label ?? '').toLowerCase();
      if (t.includes('follow')) return { type: 'follow', user, ts };
      if (t.includes('share')) return { type: 'share', user, ts };
      return null;
    }
    case 'gift': {
      const g: Any = { ...(data.gift ?? {}), ...(data.giftDetails ?? {}), ...(data.extendedGiftInfo ?? {}) };
      const giftType = num(data.giftType ?? g.giftType ?? g.type, 0);
      const repeatEnd = data.repeatEnd ?? g.repeatEnd;
      const giftId = num(data.giftId ?? g.giftId ?? g.id, 0);
      return {
        type: 'gift-raw',
        user,
        ts,
        giftId,
        giftName: str(data.giftName) ?? str(g.giftName) ?? str(g.name) ?? `Regalo ${giftId}`,
        coins: num(data.diamondCount ?? g.diamondCount ?? g.diamond_count, 1),
        repeatCount: Math.max(1, num(data.repeatCount ?? g.repeatCount, 1)),
        // Solo los regalos combinables (giftType 1) llegan en racha; el último
        // evento trae repeatEnd = true con el total.
        streaking: giftType === 1 && (repeatEnd === false || repeatEnd === 0),
        msgId: str(data.msgId ?? data.common?.msgId),
        giftImageUrl: str(data.giftPictureUrl) ?? firstUrl(g.giftImage ?? g.image ?? g.icon),
      };
    }
    default:
      return null;
  }
}
