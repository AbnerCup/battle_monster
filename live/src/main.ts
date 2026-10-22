import '@fontsource/lilita-one/400.css';
import '@fontsource/pixelify-sans/400.css';
import '@fontsource/pixelify-sans/700.css';
import Phaser from 'phaser';
import { AudioManager } from './audio/AudioManager';
import { GAME } from './config/game';
import { SpeciesPack, type AssetsFile, type ElementsFile, type PackFile } from './content/SpeciesPack';
import { Vfx } from './content/Vfx';
import { DevPanel } from './dev/DevPanel';
import { LiveHub } from './live/LiveHub';
import { SimulatorSource } from './live/SimulatorSource';
import { DEFAULT_TIKFINITY_URL, TikFinitySource } from './live/TikFinitySource';
import { RT } from './runtime';
import { BattleScene } from './scenes/BattleScene';
import { BootScene } from './scenes/BootScene';
import { LobbyScene } from './scenes/LobbyScene';
import { OverlayScene } from './scenes/OverlayScene';
import { ResultScene } from './scenes/ResultScene';

async function getJson<T>(url: string): Promise<T | null> {
  try {
    const r = await fetch(url, { cache: 'no-cache' });
    return r.ok ? ((await r.json()) as T) : null;
  } catch {
    return null;
  }
}

/** Carga el paquete pedido (o el de respaldo si no existe). */
async function loadPack(wanted: string): Promise<SpeciesPack> {
  for (const id of [wanted, GAME.pack, GAME.fallbackPack]) {
    const file = await getJson<PackFile>(`packs/${id}/species.json`);
    if (!file) continue;
    const elements = (await getJson<ElementsFile>(`packs/${id}/elements.json`)) ?? {};
    const assets = (await getJson<AssetsFile>(`packs/${id}/assets.json`)) ?? undefined;
    return new SpeciesPack(file, elements, assets);
  }
  throw new Error('No hay ningún paquete de criaturas en public/packs/');
}

async function start() {
  const params = new URLSearchParams(location.search);
  const obs = params.has('obs');
  if (obs) document.body.classList.add('obs');

  // Las fuentes deben estar listas antes de que Phaser dibuje texto.
  const fonts = Promise.race([
    Promise.all([
      document.fonts.load('64px "Lilita One"'),
      document.fonts.load('32px "Pixelify Sans"'),
      document.fonts.load('bold 32px "Pixelify Sans"'),
    ]),
    new Promise((r) => setTimeout(r, 2500)),
  ]);
  const [pack] = await Promise.all([loadPack(params.get('pack') ?? GAME.pack), fonts]);

  RT.pack = pack;
  RT.vfx = new Vfx(pack);
  RT.audio = new AudioManager(pack);
  if (params.get('mute') === '1') RT.audio.setMuted(true);
  RT.hub = new LiveHub();
  RT.simulator = new SimulatorSource(RT.hub);
  RT.simulator.start();
  RT.tikfinity = new TikFinitySource(RT.hub, params.get('tikfinity') || DEFAULT_TIKFINITY_URL);
  if (params.has('tikfinity') || params.get('autoconnect') === '1' || obs) RT.tikfinity.start();

  const game = new Phaser.Game({
    // ?renderer=canvas fuerza Canvas 2D (útil en PCs sin aceleración gráfica).
    type: params.get('renderer') === 'canvas' ? Phaser.CANVAS : Phaser.AUTO,
    parent: 'game',
    width: GAME.width,
    height: GAME.height,
    backgroundColor: '#140d22',
    scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
    render: { antialias: true, powerPreference: 'high-performance' },
    audio: { disableWebAudio: false },
    scene: [BootScene, LobbyScene, BattleScene, ResultScene, OverlayScene],
  });
  RT.audio.attach(game);

  // Phaser recorta el tiempo de animación cuando la ventana pierde el foco. En OBS
  // o con TikTok LIVE Studio en primer plano eso ralentizaría todo: se desactiva.
  game.loop.blur = () => {};

  game.events.once('vortex-ready', () => {
    if (!obs) new DevPanel(document.getElementById('dev')!);
    if (params.get('sim') === 'autoplay') {
      RT.simulator.addViewers(10);
      RT.simulator.setAutoplay(true);
    }
  });

  // Acceso desde la consola del navegador y para pruebas automáticas.
  (window as any).vortex = { game, RT, GAME };
}

start();
