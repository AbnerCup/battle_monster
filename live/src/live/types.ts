// Eventos normalizados del live. El juego solo conoce estos tipos; cada fuente
// (TikFinity, simulador, en el futuro otra API) traduce sus mensajes a esto.

export interface LiveUser {
  /** Identificador numérico estable de TikTok (como texto). */
  userId: string;
  /** @usuario */
  uniqueId: string;
  /** Nombre visible */
  nickname: string;
  /** Foto de perfil (URL firmada del CDN de TikTok; caduca). */
  avatarUrl?: string;
}

interface Base {
  user: LiveUser;
  ts: number;
}

export interface JoinEvent extends Base { type: 'join' }
export interface LikeEvent extends Base { type: 'like'; count: number }
export interface ChatEvent extends Base { type: 'chat'; text: string }
export interface FollowEvent extends Base { type: 'follow' }
export interface ShareEvent extends Base { type: 'share' }
export interface GiftEvent extends Base {
  type: 'gift';
  giftId: number;
  giftName: string;
  /** Valor unitario en monedas (diamondCount). */
  coins: number;
  /** Cantidad total (ya consolidada si fue una racha). */
  count: number;
  giftImageUrl?: string;
}
export interface ViewersEvent { type: 'viewers'; count: number; ts: number }

export type LiveEvent =
  | JoinEvent
  | LikeEvent
  | ChatEvent
  | GiftEvent
  | FollowEvent
  | ShareEvent
  | ViewersEvent;

export type UserEvent = Exclude<LiveEvent, ViewersEvent>;

/** Regalo tal como llega, antes de consolidar rachas. */
export interface RawGift extends Omit<GiftEvent, 'type' | 'count'> {
  type: 'gift-raw';
  repeatCount: number;
  /** true si es un regalo combinable (giftType 1) y la racha sigue abierta. */
  streaking: boolean;
  msgId?: string;
}

export type SourceStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

export interface LiveSource {
  readonly id: string;
  start(): void;
  stop(): void;
}
