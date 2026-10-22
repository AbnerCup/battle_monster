// Referencias compartidas entre escenas, panel de pruebas y consola.

import type { AudioManager } from './audio/AudioManager';
import type { SpeciesPack } from './content/SpeciesPack';
import type { Sprites } from './content/Sprites';
import type { Vfx } from './content/Vfx';
import type { GameDirector } from './core/GameDirector';
import type { PlayerStore } from './core/PlayerStore';
import type { LiveHub } from './live/LiveHub';
import type { SimulatorSource } from './live/SimulatorSource';
import type { TikFinitySource } from './live/TikFinitySource';
import type { AvatarCache } from './ui/avatars';

export interface Runtime {
  hub: LiveHub;
  simulator: SimulatorSource;
  tikfinity: TikFinitySource;
  pack: SpeciesPack;
  store: PlayerStore;
  director: GameDirector;
  avatars: AvatarCache;
  sprites: Sprites;
  vfx: Vfx;
  audio: AudioManager;
}

export const RT = {} as Runtime;
