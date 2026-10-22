// Panel de pruebas (solo fuera de OBS): conexión a TikFinity, simulador de
// eventos y registro de lo que llega. Con ?obs=1 no se muestra.

import { GAME } from '../config/game';
import { GIFT_RULES, giftLabel } from '../config/giftRules';
import { SIM_GIFTS } from '../live/SimulatorSource';
import type { SourceStatus } from '../live/types';
import { RT } from '../runtime';

export class DevPanel {
  private log!: HTMLPreElement;
  private lines: string[] = [];
  private showRaw = false;

  constructor(private root: HTMLElement) {
    this.render();
    RT.hub.onStatus((id, s, detail) => this.status(id, s, detail));
    RT.hub.on((e) => {
      if (e.type === 'viewers') return this.push(`viewers ${e.count}`);
      const extra =
        e.type === 'gift' ? `${e.giftName} ×${e.count} (${e.coins} monedas c/u)` : e.type === 'chat' ? `"${e.text}"` : e.type === 'like' ? `+${e.count}` : '';
      this.push(`${e.type.padEnd(6)} ${e.user.nickname} ${extra}`);
    });
    RT.hub.onRaw((id, raw) => {
      if (this.showRaw && id === 'tikfinity') this.push('RAW ' + JSON.stringify(raw).slice(0, 600));
    });
  }

  private h<K extends keyof HTMLElementTagNameMap>(tag: K, props: Partial<HTMLElementTagNameMap[K]> & { cls?: string } = {}, ...kids: (Node | string)[]) {
    const el = document.createElement(tag);
    const { cls, ...rest } = props as any;
    if (cls) el.className = cls;
    Object.assign(el, rest);
    el.append(...kids);
    return el;
  }

  private btn(label: string, onClick: () => void, cls = '') {
    return this.h('button', { cls, onclick: onClick, type: 'button' }, label);
  }

  private render() {
    const sim = RT.simulator;
    const r = this.root;
    r.innerHTML = '';

    // --- TikFinity
    const url = this.h('input', { value: RT.tikfinity.url, placeholder: 'ws://127.0.0.1:21213/' });
    const dot = this.h('span', { cls: 'dot', id: 'tf-dot' });
    const st = this.h('span', { id: 'tf-status' }, 'desconectado');
    r.append(
      this.h('h2', {}, 'TikFinity'),
      this.h('div', { cls: 'hint' }, 'Abre TikFinity Desktop en esta PC y conéctalo a tu live.'),
      this.h('div', { cls: 'row' }, url),
      this.h(
        'div',
        { cls: 'row' },
        this.btn('Conectar', () => {
          RT.tikfinity.stop();
          RT.tikfinity.url = url.value.trim();
          RT.tikfinity.start();
        }, 'primary'),
        this.btn('Desconectar', () => RT.tikfinity.stop()),
        this.h('span', { cls: 'status' }, dot, st),
      ),
    );

    // --- simulador
    const auto = this.btn('Autoplay', () => {
      sim.setAutoplay(!sim.autoplaying);
      auto.classList.toggle('on', sim.autoplaying);
    });
    r.append(
      this.h('h2', {}, 'Simulador'),
      this.h(
        'div',
        { cls: 'row' },
        this.btn('+1 espectador', () => sim.addViewers(1)),
        this.btn('+10', () => sim.addViewers(10)),
        this.btn('+20', () => sim.addViewers(20)),
        auto,
      ),
      this.h(
        'div',
        { cls: 'row' },
        this.btn('Like', () => sim.like()),
        this.btn('Lluvia de likes', () => sim.likeStorm(40)),
        this.btn('Follow', () => sim.follow()),
        this.btn('!mochila', () => sim.chat('!mochila')),
      ),
    );

    const who = this.h('select', {});
    const refreshWho = () => {
      const cur = who.value;
      who.innerHTML = '';
      who.append(this.h('option', { value: '' }, 'Usuario al azar'));
      for (const u of sim.users.slice(-60)) who.append(this.h('option', { value: u.userId }, u.nickname));
      who.value = cur;
    };
    who.onfocus = refreshWho;
    refreshWho();
    const pickUser = () => sim.users.find((u) => u.userId === who.value) ?? sim.randomUser();
    const count = this.h('input', { type: 'number', value: '1', min: '1', max: '99' });
    count.style.flex = '0 0 70px';

    const gifts = this.h('div', { cls: 'row' });
    const ruled = new Set(GIFT_RULES.flatMap((g) => g.names));
    for (const g of SIM_GIFTS) {
      const b = this.h('button', { cls: 'gift', type: 'button' }, giftLabel(g.name, g.id), this.h('small', {}, `${g.coins} 🪙${ruled.has(g.name.toLowerCase()) ? '' : ' · EXP'}`));
      b.onclick = () => sim.gift(g, pickUser(), Math.max(1, Number(count.value) || 1));
      gifts.append(b);
    }
    const chat = this.h('input', { placeholder: 'Mensaje de chat (ej. 3 o !mochila 2)' });
    const sendChat = () => {
      if (chat.value.trim()) sim.chat(chat.value.trim(), pickUser());
      chat.value = '';
    };
    chat.onkeydown = (e) => e.key === 'Enter' && sendChat();
    r.append(
      this.h('h2', {}, 'Regalos'),
      this.h('div', { cls: 'row' }, who, count),
      gifts,
      this.h('h2', {}, 'Chat'),
      this.h('div', { cls: 'row' }, chat, this.btn('Enviar', sendChat)),
    );

    // --- partida
    const sound = this.btn(RT.audio.muted ? 'Sonido: apagado' : 'Sonido: encendido', () => {
      RT.audio.setMuted(!RT.audio.muted);
      sound.textContent = RT.audio.muted ? 'Sonido: apagado' : 'Sonido: encendido';
      sound.classList.toggle('on', !RT.audio.muted);
    }, RT.audio.muted ? '' : 'on');
    const bots = this.btn(`Bots de relleno: ${GAME.bots.enabled ? 'sí' : 'no'}`, () => {
      GAME.bots.enabled = !GAME.bots.enabled;
      bots.textContent = `Bots de relleno: ${GAME.bots.enabled ? 'sí' : 'no'}`;
      bots.classList.toggle('on', GAME.bots.enabled);
    }, GAME.bots.enabled ? 'on' : '');
    r.append(
      this.h('h2', {}, 'Partida'),
      this.h('div', { cls: 'hint' }, `Paquete: ${RT.pack.file.name} (${RT.pack.file.species.length} especies). Cambia con ?pack=tuxemon`),
      this.h('div', { cls: 'row' }, sound, bots),
      this.h(
        'div',
        { cls: 'row' },
        this.btn('Empezar ronda ya', () => RT.director.forceStart(), 'primary'),
        this.btn('Volver a la sala', () => RT.director.skipToLobby()),
        this.btn('Borrar jugadores guardados', async () => {
          if (!confirm('¿Borrar todos los jugadores y sus criaturas guardadas?')) return;
          await RT.store.reset();
          RT.director.roster.clear();
          location.reload();
        }),
      ),
      this.h('div', { cls: 'hint' }, 'Para OBS / TikTok LIVE Studio usa esta misma URL con ?obs=1'),
    );

    // --- registro
    const rawToggle = this.btn('Ver JSON crudo de TikFinity', () => {
      this.showRaw = !this.showRaw;
      rawToggle.classList.toggle('on', this.showRaw);
    });
    this.log = this.h('pre', {});
    r.append(this.h('h2', {}, 'Eventos'), this.h('div', { cls: 'row' }, rawToggle), this.log);
  }

  private status(id: string, s: SourceStatus, detail?: string) {
    if (id !== 'tikfinity') return;
    const dot = document.getElementById('tf-dot');
    const st = document.getElementById('tf-status');
    if (dot) dot.className = `dot ${s}`;
    const label = { disconnected: 'desconectado', connecting: 'conectando…', connected: 'conectado', error: 'error' }[s];
    if (st) st.textContent = detail && s !== 'connected' ? `${label} · ${detail}` : label;
  }

  private push(line: string) {
    const t = new Date().toLocaleTimeString();
    this.lines.unshift(`${t} ${line}`);
    if (this.lines.length > 120) this.lines.length = 120;
    this.log.textContent = this.lines.join('\n');
  }
}
