// Fotos de perfil como texturas circulares de Phaser.
// Al primer uso se crea una textura con las iniciales; cuando la foto real
// termina de cargar (vía /avatar, el proxy local) se dibuja encima y todas las
// imágenes que usan esa textura se actualizan solas.

import Phaser from 'phaser';
import { FONT_HEAD } from './theme';

const SIZE = 160;
const PALETTE = ['#7b4dff', '#ff4fa3', '#2ad1c9', '#ff8a3d', '#3ea6ff', '#5bd16b', '#e05df0', '#f2b134'];

interface Entry {
  url?: string;
  state: 'initials' | 'loading' | 'photo' | 'failed';
}

export interface AvatarUser {
  userId: string;
  nickname: string;
  avatarUrl?: string;
}

export class AvatarCache {
  private entries = new Map<string, Entry>();

  constructor(private textures: Phaser.Textures.TextureManager) {}

  key(u: AvatarUser): string {
    const key = `av:${u.userId}`;
    let e = this.entries.get(u.userId);
    if (!e || !this.textures.exists(key)) {
      e = { state: 'initials' };
      this.entries.set(u.userId, e);
      this.drawInitials(key, u);
    }
    if (u.avatarUrl && (e.state === 'initials' || (e.state === 'failed' && e.url !== u.avatarUrl))) {
      e.url = u.avatarUrl;
      e.state = 'loading';
      this.load(key, u.avatarUrl, e);
    }
    return key;
  }

  private canvas(key: string): Phaser.Textures.CanvasTexture {
    const t = this.textures.get(key);
    if (t && t.key === key && t instanceof Phaser.Textures.CanvasTexture) return t;
    return this.textures.createCanvas(key, SIZE, SIZE)!;
  }

  private drawInitials(key: string, u: AvatarUser) {
    const tex = this.canvas(key);
    const ctx = tex.context;
    let h = 0;
    for (const ch of u.userId) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
    ctx.clearRect(0, 0, SIZE, SIZE);
    ctx.beginPath();
    ctx.arc(SIZE / 2, SIZE / 2, SIZE / 2, 0, Math.PI * 2);
    ctx.fillStyle = PALETTE[h % PALETTE.length];
    ctx.fill();
    const letters = [...(u.nickname || '?').replace(/[^\p{L}\p{N}]/gu, '')].slice(0, 2).join('').toUpperCase() || '?';
    ctx.fillStyle = '#ffffff';
    ctx.font = `${SIZE * 0.42}px ${FONT_HEAD}`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(letters, SIZE / 2, SIZE / 2 + SIZE * 0.03);
    tex.refresh();
  }

  private load(key: string, url: string, e: Entry, direct = false) {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      if (e.url !== url) return;
      const tex = this.canvas(key);
      const ctx = tex.context;
      ctx.clearRect(0, 0, SIZE, SIZE);
      ctx.save();
      ctx.beginPath();
      ctx.arc(SIZE / 2, SIZE / 2, SIZE / 2, 0, Math.PI * 2);
      ctx.clip();
      const s = Math.max(SIZE / img.width, SIZE / img.height);
      ctx.drawImage(img, (SIZE - img.width * s) / 2, (SIZE - img.height * s) / 2, img.width * s, img.height * s);
      ctx.restore();
      tex.refresh();
      e.state = 'photo';
    };
    img.onerror = () => {
      if (!direct) return this.load(key, url, e, true); // sin proxy: intento directo
      e.state = 'failed';
    };
    img.src = direct ? url : `/avatar?u=${encodeURIComponent(url)}`;
  }
}
