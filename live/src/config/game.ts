// Ajustes de juego. Todo lo que un streamer querría cambiar vive aquí
// (más adelante se puede cargar desde el backend por streamer).

import type { Rarity } from '../core/types';

export const GAME = {
  width: 1080,
  height: 1920,

  /** Textos de cabecera. */
  title: 'VORTEX RIVAL',
  subtitle: 'BATALLA EN VIVO',

  /**
   * Paquete de criaturas en public/packs/<id>/. "essentials" se genera desde el
   * juego del repositorio (npm run import); si no existe se usa "tuxemon".
   * También se puede forzar con ?pack=tuxemon en la URL.
   */
  pack: 'essentials',
  fallbackPack: 'tuxemon',

  lobby: {
    /** Segundos de cuenta regresiva antes de cada ronda. */
    countdownSec: 25,
    /** Jugadores reales mínimos para iniciar la cuenta (con bots basta 1). */
    minPlayers: 1,
    /** Tarjetas por página y segundos por página. */
    pageSize: 16,
    pageSec: 6,
    /** Máximo de jugadores en la sala (los inactivos salen primero). */
    maxRoster: 64,
    /** Minutos sin interactuar para salir de la sala. */
    idleMinutes: 10,
  },

  /** Qué acciones meten a un espectador en la sala. */
  joinOn: { enter: true, like: true, chat: true, gift: true, follow: true, share: true },

  /** Rivales controlados por el juego para que haya pelea aunque entren pocos. */
  bots: {
    enabled: true,
    /** La batalla se completa con bots hasta este número de luchadores. */
    minFighters: 8,
    names: ['Rival Bosque', 'Rival Volcán', 'Rival Marea', 'Rival Trueno', 'Rival Roca', 'Rival Sombra', 'Rival Hielo', 'Rival Cielo', 'Rival Acero', 'Rival Hada'],
    /** Nivel de los bots respecto a la media de los jugadores reales. */
    levelFactor: 0.9,
  },

  battle: {
    maxFighters: 20,
    countdownSec: 3,
    timeLimitSec: 30,
    /** Tras el tiempo límite la zona se cierra del todo en estos segundos. */
    suddenDeathSec: 12,
    /** Segundos que se mantiene la arena tras el último K.O. */
    endHoldSec: 2.5,
    arena: { x: 150, y: 330, w: 780, h: 1400 },
    /** Likes de un usuario que curan a su criatura (o a la que apoya). */
    likesToHeal: 25,
    likeHealPct: 0.12,
    /** Apoyo por chat: cada mensaje con el número cura un poco. */
    supportHealPct: 0.02,
    /** Escala de los sprites animados en la arena (y alto máximo en píxeles). */
    spriteScale: 2.8,
    spriteMaxHeight: 210,
  },

  result: { seconds: 12 },

  progression: {
    /** Multiplicador de estadísticas por nivel por encima de 1. */
    statPerLevel: 0.02,
    maxLevel: 100,
    starterLevel: [1, 5] as [number, number],
    captureLevel: { comun: [3, 8], raro: [8, 16], especial: [16, 28] } as Record<Rarity, [number, number]>,
    /** Probabilidad de que una captura salga variocolor (si la especie tiene sprite shiny). */
    shinyChance: { comun: 0.02, raro: 0.03, especial: 0.05 } as Record<Rarity, number>,
    /** XP de criatura y de entrenador al terminar una ronda. */
    battleXp: { participate: 15, perKo: 20, win: 60, perPlace: 3 },
    trainerXp: { participate: 10, perKo: 10, win: 40 },
    followXp: 30,
    shareXp: 20,
  },

  audio: {
    master: 0.9,
    music: 0.35,
    sfx: 0.6,
    cries: 0.7,
  },

  /** Texturas de sprites cargadas a la vez antes de liberar las que no se usan. */
  maxSpriteTextures: 240,
};

export type GameConfig = typeof GAME;
