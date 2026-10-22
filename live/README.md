# Battle Monster LIVE (juego para TikTok LIVE)

Versión en vivo de **Pokémon Survivor Burst** para transmisiones de TikTok. Los espectadores entran con likes, capturan y entrenan Pokémon con regalos y pelean en una arena battle royale. El juego se conecta al live por **TikFinity Desktop**.

Se ejecuta en el navegador, en vertical (1080×1920), y se pone en OBS o TikTok LIVE Studio. El contenido (sprites animados, tipos, estadísticas, efectos, música y gritos) se importa del juego Essentials que está en la carpeta superior del repositorio.

Análisis completo y decisiones: [docs/ANALISIS.md](docs/ANALISIS.md).

## Arranque rápido

Necesitas **Node.js 20 o superior** y **TikFinity Desktop** en la PC del streamer.

**Opción fácil:** doble clic en `iniciar.bat`. Instala, importa, compila y abre `http://localhost:4173/`.

**Por consola**, en PC1 (Windows), dentro de `live`:

```bash
npm install
npm run dev
```

El modo desarrollo queda en `http://localhost:5173/`. A la derecha está el panel de pruebas: simula espectadores, regalos y chat, activa o desactiva el sonido y los bots, y fuerza una ronda.

`npm run dev` y `npm run build` ejecutan antes el importador (`npm run import`). Este genera `public/packs/essentials/` desde `../PBS` y `../Graphics/UI/Survivor Game`. Ese paquete no se sube al repositorio porque se genera solo.

## En el live

1. Abre TikFinity Desktop y conéctalo a tu cuenta.
2. En OBS: **Fuente → Navegador**, URL `http://localhost:4173/?obs=1`, ancho **1080**, alto **1920**. Marca **Controlar audio a través de OBS** para que se escuche la música.
3. En TikTok LIVE Studio: añade la URL como fuente web si tu versión lo permite, o captura la ventana del navegador.

Con `?obs=1` se oculta el panel y se conecta solo a TikFinity (`ws://127.0.0.1:21213/`). Otros parámetros de la URL:

| Parámetro | Efecto |
|---|---|
| `pack=tuxemon` | Usa el paquete de criaturas con licencia libre en lugar de Pokémon |
| `mute=1` | Sin sonido |
| `renderer=canvas` | Dibujo sin aceleración gráfica (PCs muy modestas) |
| `tikfinity=ws://…` | Otra dirección de TikFinity |
| `sim=autoplay` | Actividad simulada continua (demostraciones) |

La primera vez, revisa en el panel ("Ver JSON crudo de TikFinity") que lleguen nombre y foto de los espectadores. Si TikFinity usa otros nombres de campo, solo hay que tocar `src/live/normalize.ts`.

## Cómo se juega

| Espectador | Efecto |
|---|---|
| Entra al live, da like o comenta | Aparece en la sala con su foto y un Pokémon inicial |
| `!mochila` / `!mochila 3` | Cambia de Pokémon |
| Donut / Confeti / Pistola de dinero | Captura común / rara / especial (2–5 % sale variocolor) |
| Otros regalos en la sala | EXP: 1 por moneda (Coral ×3 = +1497). Suben de nivel y evolucionan |
| Número de un luchador en el chat | Lo apoya (cura un poco y cuenta para "Fan N.º 1") |
| Gafas de sol / GG / Corazón / Rosa | Escudo / ataque / cura / potencia en batalla |
| 25 likes en batalla | Cura |

Una ronda tiene estas fases: sala (25 s) → 3, 2, 1 → batalla de hasta 20 jugadores (30 s, luego la zona se cierra) → campeón e informe → sala. Si entran menos de 8, **bots rivales** completan la pelea; así funciona aunque solo haya un espectador. El progreso de cada espectador se guarda en esa PC.

## Configuración

- `src/config/game.ts`: título, tiempos, bots, escala de sprites, probabilidades de variocolor, volúmenes.
- `src/config/giftRules.ts`: qué hace cada regalo.

## Modo torneo de Game.exe

El juego Essentials trae un modo torneo para TikTok (eliminatorias de 8 o 16), pero esperaba un servidor en el puerto 8081 que no estaba en el repositorio. `bridge/tiktok-bridge.mjs` hace ese papel: lee TikFinity y le envía los eventos a Game.exe.

PC1 (Windows), dentro de `live`:

```bash
npm run bridge
```

También puedes hacer doble clic en `iniciar-puente-exe.bat` y luego abrir `Game.exe`. Las fotos de perfil se guardan en `Graphics/Avatars/`. El juego solo abre PNG y JPEG; si TikTok entrega WEBP, se muestran las iniciales. El puente está probado con TikFinity y el juego simulados, todavía no con Game.exe real.

## Estructura

```
live/
  src/live/      TikFinity, simulador, normalizador, LiveHub (rachas y duplicados)
  src/core/      lógica sin gráficos: GameDirector, BattleSim, progresión, jugadores
  src/content/   paquete de especies, sprites bajo demanda (LRU), VFX
  src/audio/     música en streaming, efectos y gritos
  src/scenes/    Boot, Sala, Batalla, Resultado y capa de capturas/avisos
  src/ui/        tema, avatares, CreatureSprite (animación en 8 direcciones)
  tools/         import-essentials.mjs (repo → paquete) y build_pack_tuxemon.py
  bridge/        puente TikFinity → Game.exe
  server/        servidor local + proxy de fotos de perfil
  tests/         npm test (20 pruebas)
```

## Pruebas

PC1 (Windows):

```bash
npm test
```

## Licencias

El paquete "essentials" usa nombres, arte, música y sonidos de Pokémon (© Nintendo / Creatures / GAME FREAK), además de sprites comunitarios estilo PMD cuya licencia también hay que revisar. Sirve para uso propio en tus lives. Un producto para vender necesita criaturas propias o con licencia comercial. Como el juego funciona por paquetes, basta con generar otro con el mismo formato. `?pack=tuxemon` muestra un ejemplo con criaturas de licencia libre (CC BY-SA 4.0).
