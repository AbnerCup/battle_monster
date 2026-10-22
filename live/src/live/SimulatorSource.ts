// Simulador de un live para desarrollar sin estar en vivo.
// Genera mensajes con el MISMO formato que TikFinity y los pasa por el mismo
// normalizador, así se prueba la ruta real de punta a punta.

import type { LiveSource } from './types';
import type { LiveHub } from './LiveHub';
import { normalizeTikFinity } from './normalize';

export interface SimGift {
  id: number;
  name: string;
  coins: number;
  /** Regalos combinables (giftType 1) llegan en racha. */
  streakable: boolean;
}

/** Catálogo de prueba. Los nombres coinciden con los que envía TikTok. */
export const SIM_GIFTS: SimGift[] = [
  { id: 5655, name: 'Rose', coins: 1, streakable: true },
  { id: 5269, name: 'TikTok', coins: 1, streakable: true },
  { id: 6064, name: 'GG', coins: 1, streakable: true },
  { id: 5827, name: 'Ice Cream Cone', coins: 1, streakable: true },
  { id: 5487, name: 'Finger Heart', coins: 5, streakable: true },
  { id: 5879, name: 'Donut', coins: 30, streakable: true },
  { id: 5659, name: 'Paper Crane', coins: 99, streakable: true },
  { id: 5585, name: 'Confetti', coins: 100, streakable: true },
  { id: 8843, name: 'Sunglasses', coins: 199, streakable: true },
  { id: 5731, name: 'Coral', coins: 499, streakable: true },
  { id: 7168, name: 'Money Gun', coins: 500, streakable: false },
];

const NAMES = [
  'Juanan', 'Daisy_G', 'FossilFan', 'lascosas', 'Gargalok', 'JavierP', 'alan_u', 'rayito', 'Marisol',
  'JosueRF', 'Zelaya', 'By_wiwi', 'riki', 'Lorkham', 'ZedQue', 'Josuebml', 'CantaLuna', 'kevvv',
  'Nicols', 'Raul', 'Paquito', 'thiago08', 'sid', 'Asier17', 'Flayqo', 'C.Alt', 'Gook', 'Agacle',
  'rvuyewr', 'soulzk', 'RubenB', 'pola', 'sanabw', 'Mauricio', 'Miquefo', 'SebasRM', 'Jony Lopez',
  'Zlaiz', 'Fix Your Mind', 'Valeria', 'Camila.r', 'Diego_pe', 'Lucia★', 'Mateo99', 'Renata',
];

export interface SimUser {
  userId: string;
  uniqueId: string;
  nickname: string;
}

export class SimulatorSource implements LiveSource {
  readonly id = 'simulador';
  users: SimUser[] = [];
  private seq = 0;
  private auto?: ReturnType<typeof setInterval>;

  constructor(private hub: LiveHub) {}

  start() {
    this.hub.status(this.id, 'connected');
  }
  stop() {
    this.setAutoplay(false);
    this.hub.status(this.id, 'disconnected');
  }

  private send(event: string, data: Record<string, unknown>) {
    const msg = { event, data: { ...data, createTime: Date.now() } };
    this.hub.raw(this.id, msg);
    this.hub.push(normalizeTikFinity(msg));
  }

  private userData(u: SimUser) {
    return { userId: u.userId, uniqueId: u.uniqueId, nickname: u.nickname, profilePictureUrl: '' };
  }

  newUser(): SimUser {
    const n = this.seq++;
    const base = NAMES[n % NAMES.length];
    const nickname = n < NAMES.length ? base : `${base}${Math.floor(n / NAMES.length) + 1}`;
    const u = { userId: `sim-${n}`, uniqueId: nickname.toLowerCase().replace(/[^a-z0-9_.]/g, ''), nickname };
    this.users.push(u);
    return u;
  }

  randomUser(): SimUser {
    if (!this.users.length) return this.newUser();
    return this.users[Math.floor(Math.random() * this.users.length)];
  }

  /** Nuevos espectadores que entran y dan like (se unen al juego). */
  addViewers(n: number) {
    for (let i = 0; i < n; i++) {
      const u = this.newUser();
      this.send('member', this.userData(u));
      this.send('like', { ...this.userData(u), likeCount: 1 + Math.floor(Math.random() * 5) });
    }
  }

  like(u = this.randomUser(), count = 1 + Math.floor(Math.random() * 10)) {
    this.send('like', { ...this.userData(u), likeCount: count });
  }

  likeStorm(n = 30) {
    for (let i = 0; i < n; i++) this.like();
  }

  chat(text: string, u = this.randomUser()) {
    this.send('chat', { ...this.userData(u), comment: text });
  }

  follow(u = this.randomUser()) {
    this.send('social', { ...this.userData(u), displayType: 'pm_mt_msg_viewer_follow' });
  }

  /** Envía un regalo; si es combinable, simula la racha completa. */
  gift(g: SimGift, u = this.randomUser(), count = 1) {
    const base = {
      ...this.userData(u),
      giftId: g.id,
      giftName: g.name,
      diamondCount: g.coins,
      giftType: g.streakable ? 1 : 2,
    };
    const msgBase = `${u.userId}-${g.id}-${Date.now()}`;
    if (!g.streakable) {
      this.send('gift', { ...base, repeatCount: count, repeatEnd: true, msgId: msgBase });
      return;
    }
    for (let i = 1; i <= count; i++) {
      this.send('gift', { ...base, repeatCount: i, repeatEnd: false, msgId: `${msgBase}-${i}` });
    }
    this.send('gift', { ...base, repeatCount: count, repeatEnd: true, msgId: `${msgBase}-end` });
  }

  viewers(count: number) {
    this.send('roomUser', { viewerCount: count });
  }

  get autoplaying() {
    return !!this.auto;
  }

  /** Actividad aleatoria continua, útil para dejar el juego corriendo. */
  setAutoplay(on: boolean) {
    clearInterval(this.auto);
    this.auto = undefined;
    if (!on) return;
    this.auto = setInterval(() => {
      const r = Math.random();
      if (this.users.length < 24 && r < 0.25) this.addViewers(1);
      else if (r < 0.7) this.like();
      else if (r < 0.8) this.chat(String(1 + Math.floor(Math.random() * Math.max(1, this.users.length))));
      else if (r < 0.83) this.chat('!mochila');
      else {
        const cheap = SIM_GIFTS.filter((g) => g.coins <= 5);
        const pool = Math.random() < 0.85 ? cheap : SIM_GIFTS;
        this.gift(pool[Math.floor(Math.random() * pool.length)], undefined, 1 + Math.floor(Math.random() * 3));
      }
    }, 450);
  }
}
