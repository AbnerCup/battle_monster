# Análisis y fusión: motor web en vivo + Pokémon Survivor Burst

Rama `live-tiktok` · 22/10/2026

## 1. Punto de partida

### 1.1 Motor web construido antes (Vortex Rival)

Se trataba de un juego en navegador (Phaser 3.90 + TypeScript + Vite) en formato vertical 1080×1920, pensado para ponerse en OBS como fuente de navegador. Ya resolvía el ciclo completo que se ve en los videos de referencia:

- **Conexión a TikFinity** por WebSocket local. Un normalizador acepta los dos formatos de TikTok-Live-Connector, consolida rachas de regalos y descarta duplicados.
- **Simulador** que genera mensajes idénticos a los de TikFinity, para probar sin estar en vivo.
- **Sala**: tarjetas con foto, nivel de entrenador y criatura; se entra con likes y se cambia de criatura con `!mochila`.
- **Captura** por rareza según el regalo, **entrenamiento** (1 EXP por moneda) y **evoluciones**.
- **Batalla** battle royale de hasta 20, con simulación determinista separada del dibujo, zona que se cierra, apoyo por número en el chat y poderes por regalo.
- **Resultado** con campeón, informe, podio y "Fan N.º 1".
- Proxy de fotos de perfil (las URLs de TikTok caducan y no admiten CORS) y 14 pruebas automáticas.

Limitaciones que se detectaron al revisarlo:

| Limitación | Efecto en un live |
|---|---|
| Arte provisional (Tuxemon, un solo cuadro de frente por especie) | No se parecía al juego de los videos; las criaturas no caminaban |
| Sin sonido | Pierde mucho en TikTok, donde el audio retiene al espectador |
| Leyenda de poderes en la franja inferior | TikTok tapa esa zona con comentarios y regalos |
| Hacían falta 2 espectadores para empezar | En lives pequeños el juego se quedaba esperando |
| El reloj de Phaser se recorta con pocos FPS o sin foco | Con la ventana sin foco las rondas iban más lentas |

### 1.2 Repositorio battle_monster

Es un fan game de **Pokémon Essentials 21.1** (RPG Maker XP + mkxp-z, Ruby) con el plugin "Pokemon Survivor" (créditos: ClessioTV, Codex). El juego es un *survivor* con tienda roguelite, pase de batalla, jefes y modos torre, rush y estaciones.

| Contenido | Cantidad | Uso en la fusión |
|---|---|---|
| Datos PBS | 1025 especies, 22 tipos con debilidades, resistencias e inmunidades | Estadísticas, tipos, evoluciones y tabla de efectividad |
| Sprites de jugador (`Pokemon Survivor`) | 230 especies: caminar + reposo + variocolor, hojas de 8 direcciones | Animación en sala, batalla, captura y campeón |
| Sprites salvajes (`Pokemon Wild`) | 839 hojas de 8 direcciones | Completan el catálogo de especies |
| Tablas de cuadros (Ruby) | Número de cuadros por hoja, repartido en varios plugins | El importador las lee para cortar bien cada hoja |
| VFX | 150 tiras de efectos por tipo | Proyectiles, impactos, subida de nivel, evolución |
| Fondos | 23 escenarios (bosque, campo, cueva, hielo, templo, torre…) | Suelo de la arena, distinto en cada ronda |
| Audio | 41 pistas de música (754 MB), 1118 gritos, ~1450 efectos | 3 pistas, 20 efectos y los gritos |
| Modo torneo TikTok (`050_TikTok_Tournament`) | Eliminatorias de 8/16, niveles por regalo, líderes de gimnasio de relleno | Se conserva en Game.exe y ahora funciona con el puente |

Observaciones sobre el repositorio:

- El modo torneo se conectaba por TCP a `127.0.0.1:8081` a un servidor Node.js **que no está en el repositorio**, así que no podía funcionar. Además es horizontal (6 arenas en 3×2), mientras que TikTok es vertical.
- **Tamaño**: el historial pesa 845 MB y la música 754 MB de los 793 MB de audio. Hay dos ejecutables de 14,5 MB, `Scripts.rxdata.backup` y `out.log` versionados.
- En `Data/` hay URL y clave anónima de Supabase. La clave anónima está pensada para ser pública solo si las tablas tienen RLS activo.

## 2. Decisión de arquitectura

Juntarlo todo dentro de RPG Maker tenía tres problemas. Habría que reescribir el modo en vivo en Ruby sobre un motor horizontal de baja resolución. Igual haría falta un servidor puente, porque mkxp-z no habla WebSocket. Y no se puede probar sin Windows. La fusión quedó así:

```
TikTok LIVE ─► TikFinity Desktop ─ ws://127.0.0.1:21213 ─┬─► live/ (juego web vertical)  ─► OBS / LIVE Studio
                                                        │      ▲
                                                        │      └─ tools/import-essentials.mjs
                                                        │           (PBS + sprites + VFX + audio del repo)
                                                        └─► live/bridge ─ TCP 8081 ─► Game.exe (modo torneo)
```

- **El motor web es el juego del live**: vertical nativo, conexión directa a TikFinity, fotos de perfil, simulador y pruebas.
- **El repositorio es la fuente de contenido**. Un importador sin dependencias convierte sus datos y gráficos en un paquete del motor. Si se actualiza un sprite o el PBS, basta con `npm run import`.
- **Game.exe conserva su modo torneo** y ahora tiene el servidor que le faltaba.

## 3. Qué cambió

| Área | Antes | Ahora |
|---|---|---|
| Criaturas | 411 Tuxemon estáticas | 839 Pokémon animados en 8 direcciones (caminar y reposo), 226 con variocolor |
| Datos | Estadísticas inventadas por forma | Estadísticas base del PBS; rareza por total de estadísticas y legendarios; evoluciones del PBS |
| Tipos | 13 tipos Tuxemon | Tabla de efectividad de los 22 tipos del PBS, nombres en español |
| Efectos | Partículas genéricas | VFX del juego por tipo: proyectiles de los atacantes especiales, impactos teñidos, subida de nivel, evolución |
| Arena | Pasto dibujado | Escenario del juego en mosaico, rotando por ronda |
| Sonido | Ninguno | Música por fase, golpes, K.O., captura, variocolor, subida de nivel, evolución y grito de cada Pokémon |
| Poderes | Leyenda abajo (tapada por TikTok) | Botones laterales con contador por ronda, como en los videos |
| Pocos espectadores | Esperaba a 2 jugadores | Basta 1: bots rivales completan hasta 8 luchadores (no se guardan ni ganan EXP) |
| Variocolor | — | 2 % (común), 3 % (raro), 5 % (especial), con animación y sonido propios |
| Game.exe | Modo torneo sin servidor | Puente TikFinity → TCP 8081 con niveles por regalo y fotos de perfil |
| Conexión a TikFinity | Conectado o desconectado | Distingue app abierta sin actividad, LIVE con eventos y LIVE terminado; reconexión automática si TikFinity se abre después o se reinicia |

## 4. Optimización

### 4.1 Rendimiento en la PC del streamer

| Medida | Por qué |
|---|---|
| **Sprites bajo demanda con límite (LRU)** | Cargar las 1517 hojas ocuparía unos **444 MB de memoria de vídeo**. Ahora se descarga solo lo que aparece en pantalla y se liberan las hojas menos usadas por encima de 240 texturas. |
| **Corte de cuadros al cargar** | Cada hoja se corta una vez; cada cuadro solo cambia de índice, sin dibujar nada nuevo. |
| **Música en streaming (`<audio>`)** | Decodificar con Web Audio una pista de 7,6 MB ocupa del orden de 100 MB de RAM. En streaming no. |
| **Efectos con límite** | Máximo de 40 efectos simultáneos y separación mínima entre sonidos iguales, para que una pelea de 20 no sature ni la GPU ni el audio. |
| **Reloj real para la lógica** | Las rondas duran lo configurado aunque bajen los FPS. Se desactivó el recorte de Phaser al perder el foco, que en OBS o con LIVE Studio en primer plano ralentizaba todo. |
| **Importador incremental** | Copia solo los archivos que cambiaron (≈1 s). El paquete generado (41 MB) no se versiona. |

### 4.2 Jugabilidad para TikTok

- La duración media de batalla con 20 jugadores y estadísticas Pokémon es de unos **26 s**, dentro de los 30 s del temporizador. Hay una prueba automática que lo vigila.
- La información clave (cuenta regresiva, capturas, finalistas, poderes) está en la mitad superior y en los laterales, fuera de la zona de comentarios.
- Los bots evitan rondas vacías en lives pequeños. El nivel de los bots sigue la media de los jugadores reales.

### 4.3 Repositorio (recomendado, no aplicado)

- Pasar audio, imágenes y ejecutables a **Git LFS**. La música (754 MB) es la mayor parte del historial y de cada clonación.
- Dejar de versionar `out.log` y `Data/Scripts.rxdata.backup`, y decidir cuál de los dos ejecutables se queda.
- Si las tablas de Supabase no tienen RLS, rotar la clave anónima y activarlo.

## 5. Verificación

- 22 pruebas automáticas: normalizador y rachas de TikFinity, conexión real por WebSocket contra un endpoint que imita a TikFinity (chat, racha de regalos, fin del LIVE y reconexión), ciclo completo de sala → captura → batalla → resultado, ronda con bots, importador sobre el repositorio real (hojas válidas, rarezas, tabla de tipos, audio) y duración de batallas.
- Juego compilado abierto como en OBS (`?obs=1`) frente a ese endpoint simulado: se conecta solo, los espectadores aparecen en la sala con su Pokémon, `!mochila` responde, la racha de 5 rosas entra como un solo entrenamiento, el Donut abre la captura y, si el endpoint se cae, vuelve a conectarse.
- Ronda completa en navegador sin interfaz con capturas de pantalla, sin errores de consola: sala, captura variocolor, entrenamiento con evolución, batalla con poderes, finalistas, campeón y regreso a la sala. También se probó el paquete Tuxemon.
- Puente probado con TikFinity y Game.exe simulados: inscripción por like y por regalo (racha consolidada), niveles 1–4, cuenta regresiva, inicio de torneo, regalos en combate y reinicio.

## 6. Riesgos

- **Propiedad intelectual**: nombres, arte, música y gritos de Pokémon, más sprites comunitarios cuya licencia hay que revisar. Un live con regalos ya es uso con fines de lucro, y Nintendo y The Pokémon Company han pedido retirar otros fan games. Un producto para clientes necesita criaturas propias o con licencia: el motor ya funciona por paquetes (`?pack=tuxemon` es el ejemplo).
- **TikFinity no es oficial**: el formato de sus mensajes puede cambiar. Todo el ajuste está en `src/live/normalize.ts`. Su endpoint lo expone la app de escritorio para Windows, así que juego y TikFinity van en la misma PC.
- **Puente de Game.exe**: falta probarlo con el ejecutable real. Si TikTok entrega fotos en WEBP, el juego muestra iniciales.

## 7. Próximos pasos

1. Probar en un live real con TikFinity y revisar el JSON crudo desde el panel.
2. Ajustar `giftRules.ts` a los regalos que más usa tu audiencia.
3. Guardar el progreso de los espectadores en el Supabase que ya usa el repositorio, para no depender de una sola PC.
4. Llevar el modo torneo por eliminatorias al motor web, como segundo modo vertical.
5. Empaquetar como aplicación de escritorio (Electron) para no depender de Node.
