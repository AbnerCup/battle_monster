// Vortex Rival - servidor del MVP para TikTok LIVE.
// Escucha tu live (o el simulador), guarda a los jugadores y le sirve el juego a OBS.
// Uso: npm start (con tu usuario en config.json) o npm run sim (solo simulador).

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import WebSocket, { WebSocketServer } from 'ws';
import dns from 'node:dns';

// --- Bypass de DNS filtrado/bloqueado por router (Movistar sinkhole 127.248.x.x) ---
const originalLookup = dns.lookup;
const dohCache = new Map();

async function resolverDoH(hostname) {
  if (dohCache.has(hostname)) {
    const item = dohCache.get(hostname);
    if (Date.now() - item.time < 300000) return item.ips;
  }
  const urls = [
    `https://1.1.1.1/dns-query?name=${encodeURIComponent(hostname)}&type=A`,
    `https://8.8.8.8/resolve?name=${encodeURIComponent(hostname)}&type=A`
  ];
  for (const url of urls) {
    try {
      const res = await fetch(url, { headers: { 'accept': 'application/dns-json' } });
      const data = await res.json();
      if (data && Array.isArray(data.Answer)) {
        const ips = data.Answer.filter((a) => a.type === 1).map((a) => a.data);
        if (ips.length > 0) {
          dohCache.set(hostname, { ips, time: Date.now() });
          return ips;
        }
      }
    } catch {}
  }
  return null;
}

dns.lookup = function (hostname, options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }
  const isAll = options && options.all;

  if (typeof hostname === 'string' && /(tiktok|tiktokv|byteoversea|ibytedtos|cloudflare-dns|eulerstream)/i.test(hostname)) {
    resolverDoH(hostname).then((ips) => {
      if (ips && ips.length > 0) {
        if (isAll) return callback(null, ips.map((ip) => ({ address: ip, family: 4 })));
        return callback(null, ips[0], 4);
      }
      return originalLookup(hostname, options, callback);
    }).catch(() => originalLookup(hostname, options, callback));
    return;
  }

  originalLookup(hostname, options, (err, address, family) => {
    if (!err) {
      const isSinkhole = isAll
        ? Array.isArray(address) && address.some((a) => String(a.address || a).startsWith('127.248.'))
        : String(address).startsWith('127.248.');
      if (isSinkhole) {
        resolverDoH(hostname).then((ips) => {
          if (ips && ips.length > 0) {
            if (isAll) return callback(null, ips.map((ip) => ({ address: ip, family: 4 })));
            return callback(null, ips[0], 4);
          }
          return callback(err, address, family);
        }).catch(() => callback(err, address, family));
        return;
      }
    }
    callback(err, address, family);
  });
};

const RAIZ = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(RAIZ, '..');
const PUBLICO = fs.existsSync(path.join(RAIZ, 'public')) ? path.join(RAIZ, 'public') : RAIZ;
const DATOS = path.join(RAIZ, 'data');

const config = JSON.parse(fs.readFileSync(path.join(RAIZ, 'config.json'), 'utf8'));
const usuarioTikTok = String(config.tiktok?.usuario || '').trim().replace(/^@/, '');
const MODO_SIM = process.argv.includes('--sim') || (!usuarioTikTok && config.tikfinity?.activo === false);
const HOST = config.servidor?.host || '127.0.0.1';
const PUERTO = Number(config.servidor?.puerto) || 3000;

// ---------------------------------------------------------------------------
// Especies: se arman con los sprites, las tablas de animación y PBS/pokemon.txt del repo
// ---------------------------------------------------------------------------
const DIR_HEROES = path.join(REPO, 'Graphics', 'UI', 'Survivor Game', 'Pokemon Survivor');
const URL_HEROES = '/repo/Graphics/UI/Survivor Game/Pokemon Survivor/';

function tamanoPng(archivo) {
  const fd = fs.openSync(archivo, 'r');
  const b = Buffer.alloc(24);
  fs.readSync(fd, b, 0, 24, 0);
  fs.closeSync(fd);
  if (b.readUInt32BE(12) !== 0x49484452) return null; // falta el bloque IHDR
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
}

function leerPbs() {
  const texto = fs.readFileSync(path.join(REPO, 'PBS', 'pokemon.txt'), 'utf8').replace(/^\uFEFF/, '');
  const datos = {};
  let actual = null;
  for (const linea of texto.split(/\r?\n/)) {
    const seccion = linea.match(/^\[([A-Za-z0-9_]+)\]/);
    if (seccion) { actual = datos[seccion[1]] = {}; continue; }
    const kv = linea.match(/^\s*(\w+)\s*=\s*(.*?)\s*$/);
    if (kv && actual) actual[kv[1]] = kv[2];
  }
  return datos;
}

function leerTablasDeAnimacion() {
  const archivo = path.join(REPO, 'Plugins', 'Pokemon Survivor', '001_Module', '002_Animation_Frames.rb');
  const rb = fs.readFileSync(archivo, 'utf8');
  const ochoDirecciones = new Set();
  const lista = rb.match(/EIGHT_DIRECTION_HERO_SPRITES\s*=\s*\[([\s\S]*?)\]/);
  if (lista) for (const m of lista[1].matchAll(/:([A-Za-z0-9_]+)/g)) ochoDirecciones.add(m[1].toUpperCase());
  const cuadros = {};
  const tabla = rb.match(/EIGHT_DIRECTION_ASSET_FRAMES\s*=\s*\{([\s\S]*?)\n\s*\}/);
  if (tabla) for (const m of tabla[1].matchAll(/"([A-Za-z0-9_]+)"\s*=>\s*(\d+)/g)) cuadros[m[1].toUpperCase()] = Number(m[2]);
  // En la tabla de la generación 9, los pares son [caminar, quieto] de los personajes jugables
  const gen9 = rb.match(/GEN9_ANIMATION_FRAMES\s*=\s*\{([\s\S]*?)\n\s*\}/);
  if (gen9) {
    for (const m of gen9[1].matchAll(/([A-Za-z0-9_]+):\s*\[(\d+)\s*,\s*(\d+)\]/g)) {
      const clave = m[1].toUpperCase();
      ochoDirecciones.add(clave);
      cuadros[clave] = Number(m[2]);
      cuadros[clave + '_IDLE'] = Number(m[3]);
    }
  }
  return { ochoDirecciones, cuadros };
}

function rarezaPorTotal(total) {
  const r = config.rarezaPorTotalDeStats || {};
  if (total >= (r.especialDesde ?? 535)) return 'especial';
  if (total >= (r.raraDesde ?? 430)) return 'rara';
  return 'normal';
}

function hojaDeSprites(archivo, cuadros, direcciones) {
  const tam = tamanoPng(path.join(DIR_HEROES, archivo));
  if (!tam || !cuadros || tam.h % direcciones !== 0 || tam.w % cuadros !== 0) return null;
  return { url: URL_HEROES + archivo, w: tam.w, h: tam.h, cuadros, dirs: direcciones };
}

function construirEspecies() {
  const pbs = leerPbs();
  const { ochoDirecciones, cuadros } = leerTablasDeAnimacion();
  const lista = [];
  for (const archivo of fs.readdirSync(DIR_HEROES).sort()) {
    if (!archivo.toLowerCase().endsWith('.png')) continue;
    const id = archivo.slice(0, -4);
    if (/_idle$/i.test(id) || /_\d+$/.test(id)) continue; // se omiten las hojas de reposo y las formas alternativas
    const datos = pbs[id];
    if (!datos || !datos.BaseStats || !datos.Types) continue;
    const clave = id.toUpperCase();
    const ocho = ochoDirecciones.has(clave);
    const hoja = ocho ? hojaDeSprites(archivo, cuadros[clave], 8) : hojaDeSprites(archivo, 4, 4);
    if (!hoja) continue;
    let reposo = null;
    const archivoReposo = id + '_Idle.png';
    if (ocho && cuadros[clave + '_IDLE'] && fs.existsSync(path.join(DIR_HEROES, archivoReposo))) {
      reposo = hojaDeSprites(archivoReposo, cuadros[clave + '_IDLE'], 8);
    }
    const [hp, atk, def, spe, spa, spd] = datos.BaseStats.split(',').map(Number);
    const total = hp + atk + def + spe + spa + spd;
    const grito = fs.existsSync(path.join(REPO, 'Audio', 'SE', 'Cries', clave + '.ogg')) ? '/repo/Audio/SE/Cries/' + clave + '.ogg' : null;
    lista.push({
      id,
      nombre: datos.Name || id,
      tipos: datos.Types.split(',').map((t) => t.trim().toUpperCase()).filter(Boolean),
      base: { hp, atk, def, spe, spa, spd },
      total,
      rareza: rarezaPorTotal(total),
      hoja,
      reposo,
      grito
    });
  }
  return lista;
}

const ESPECIES = construirEspecies();
const ESPECIES_POR_ID = Object.fromEntries(ESPECIES.map((e) => [e.id, e]));
if (!ESPECIES.length) {
  console.error('No encontré sprites de Pokémon. Revisa que la carpeta tiktok-live esté dentro del repo battle_monster.');
  process.exit(1);
}

function especieAlAzar(rareza) {
  const opciones = ESPECIES.filter((e) => e.rareza === rareza);
  const fuente = opciones.length ? opciones : ESPECIES;
  return fuente[Math.floor(Math.random() * fuente.length)].id;
}

// ---------------------------------------------------------------------------
// Jugadores: perfiles guardados en data/
// ---------------------------------------------------------------------------
fs.mkdirSync(DATOS, { recursive: true });
const ARCHIVO_JUGADORES = path.join(DATOS, MODO_SIM ? 'jugadores-simulacion.json' : 'jugadores.json');
let perfiles = {};
try {
  perfiles = JSON.parse(fs.readFileSync(ARCHIVO_JUGADORES, 'utf8'));
} catch {
  perfiles = {};
}

let temporizadorGuardado = null;
function guardarPronto() {
  if (!temporizadorGuardado) temporizadorGuardado = setTimeout(guardarYa, 1500);
}
function guardarYa() {
  clearTimeout(temporizadorGuardado);
  temporizadorGuardado = null;
  const salida = {};
  for (const [id, p] of Object.entries(perfiles)) {
    if (!MODO_SIM && id.startsWith('sim_')) continue; // los espectadores de prueba no ensucian tus datos reales
    salida[id] = p;
  }
  const temporal = ARCHIVO_JUGADORES + '.tmp';
  fs.writeFileSync(temporal, JSON.stringify(salida, null, 1));
  fs.renameSync(temporal, ARCHIVO_JUGADORES);
}

function entradaNueva(especie, rareza) {
  return { especie, nivel: 1, exp: 0, rareza };
}

function perfilDe(usuario) {
  let p = perfiles[usuario.id];
  if (!p) {
    const especie = especieAlAzar('normal');
    p = perfiles[usuario.id] = {
      id: usuario.id,
      usuario: usuario.usuario,
      nombre: usuario.nombre,
      avatar: usuario.avatar || null,
      nivelEntrenador: 1,
      expEntrenador: 0,
      activo: especie,
      mochila: [entradaNueva(especie, 'normal')],
      victorias: 0,
      batallas: 0,
      creado: Date.now(),
      visto: Date.now()
    };
  } else {
    p.nombre = usuario.nombre || p.nombre;
    p.usuario = usuario.usuario || p.usuario;
    if (usuario.avatar) p.avatar = usuario.avatar;
    p.visto = Date.now();
    // Si una especie ya no existe en el repo, se reemplaza para que el juego no falle
    p.mochila = (p.mochila || []).filter((m) => ESPECIES_POR_ID[m.especie]);
    if (!p.mochila.length) p.mochila.push(entradaNueva(especieAlAzar('normal'), 'normal'));
    if (!p.mochila.some((m) => m.especie === p.activo)) p.activo = p.mochila[0].especie;
  }
  guardarPronto();
  return p;
}

function aplicarPerfilDelJuego(nuevo) {
  const p = perfiles[nuevo?.id];
  if (!p) return;
  const numero = (v, d) => (Number.isFinite(Number(v)) ? Number(v) : d);
  if (Array.isArray(nuevo.mochila)) {
    const mochila = nuevo.mochila
      .filter((m) => m && ESPECIES_POR_ID[m.especie])
      .map((m) => ({
        especie: m.especie,
        nivel: Math.max(1, numero(m.nivel, 1)),
        exp: Math.max(0, numero(m.exp, 0)),
        rareza: ['normal', 'rara', 'especial'].includes(m.rareza) ? m.rareza : ESPECIES_POR_ID[m.especie].rareza
      }));
    if (mochila.length) p.mochila = mochila;
  }
  if (p.mochila.some((m) => m.especie === nuevo.activo)) p.activo = nuevo.activo;
  p.nivelEntrenador = Math.max(1, numero(nuevo.nivelEntrenador, p.nivelEntrenador));
  p.expEntrenador = Math.max(0, numero(nuevo.expEntrenador, p.expEntrenador));
  p.victorias = Math.max(0, numero(nuevo.victorias, p.victorias));
  p.batallas = Math.max(0, numero(nuevo.batallas, p.batallas));
  guardarPronto();
}

// ---------------------------------------------------------------------------
// Conexiones con el juego (OBS) y con el simulador
// ---------------------------------------------------------------------------
const clientes = new Set();
let principal = null; // solo un juego guarda cambios, para que dos ventanas abiertas no se pisen
let estadoTikTok = MODO_SIM
  ? { estado: 'simulacion', detalle: 'Modo simulación: usa el simulador para probar' }
  : { estado: 'conectando', detalle: 'Conectando con @' + usuarioTikTok };

function enviar(cliente, mensaje) {
  if (cliente.ws.readyState === 1) cliente.ws.send(JSON.stringify(mensaje));
}
function difundir(mensaje, rol) {
  const texto = JSON.stringify(mensaje);
  for (const c of clientes) if ((!rol || c.rol === rol) && c.ws.readyState === 1) c.ws.send(texto);
}
function contarJuegos() {
  return [...clientes].filter((c) => c.rol === 'juego').length;
}
function avisarSimuladores() {
  difundir({ t: 'estado', modo: MODO_SIM ? 'simulacion' : 'tiktok', tiktok: estadoTikTok, juegos: contarJuegos() }, 'simulador');
}
function elegirPrincipal() {
  if (principal && clientes.has(principal)) return;
  principal = [...clientes].filter((c) => c.rol === 'juego').sort((a, b) => a.desde - b.desde)[0] || null;
  if (principal) enviar(principal, { t: 'principal', valor: true });
}
function cambiarEstadoTikTok(estado, detalle) {
  estadoTikTok = { estado, detalle };
  console.log(`[TikTok] ${detalle}`);
  difundir({ t: 'tiktok', tiktok: estadoTikTok }, 'juego');
  avisarSimuladores();
}

function configPublica() {
  const copia = JSON.parse(JSON.stringify(config));
  copia.tiktok = { usuario: usuarioTikTok };
  return copia;
}

function emitir(tipo, usuario, extra = {}) {
  const perfil = perfilDe(usuario);
  difundir({ t: 'evento', evento: { tipo, usuario, perfil, ...extra } }, 'juego');
}

function manejarMensaje(cliente, m) {
  if (m.t === 'sim' && cliente.rol === 'simulador') {
    simular(m);
  } else if (m.t === 'guardar_perfiles' && cliente === principal && Array.isArray(m.perfiles)) {
    m.perfiles.forEach(aplicarPerfilDelJuego);
  }
}

function simular(m) {
  const nombre = String(m.usuario?.nombre || 'Espectador').slice(0, 24);
  const clave = nombre.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '') || 'espectador';
  const usuario = { id: 'sim_' + clave, usuario: clave, nombre, avatar: null };
  if (m.tipo === 'like') {
    emitir('like', usuario, { cantidad: Math.max(1, Math.min(500, Number(m.cantidad) || 1)) });
  } else if (m.tipo === 'regalo') {
    emitir('regalo', usuario, {
      regalo: {
        nombre: String(m.regalo?.nombre || 'Regalo').slice(0, 40),
        diamantes: Math.max(1, Number(m.regalo?.diamantes) || 1),
        cantidad: Math.max(1, Math.min(99, Number(m.cantidad) || 1))
      }
    });
  } else if (m.tipo === 'chat') {
    emitir('chat', usuario, { texto: String(m.texto || '').slice(0, 200) });
  }
}

// ---------------------------------------------------------------------------
// Conexión real con TikTok LIVE (tiktok-live-connector 2.5.0)
// ---------------------------------------------------------------------------
function primeraUrl(imagen) {
  if (!imagen) return null;
  const lista = imagen.urlList || imagen.url || imagen.urls;
  return Array.isArray(lista) && lista.length ? lista[0] : null;
}

function usuarioDe(datos) {
  const u = datos?.user || datos || {};
  const usuario = u.uniqueId || u.displayId || u.nickname || 'espectador';
  const id = String(u.userId || u.idStr || u.id || usuario);
  return {
    id,
    usuario,
    nombre: String(u.nickname || usuario).slice(0, 24),
    avatar: u.profilePictureUrl || primeraUrl(u.avatarThumb) || primeraUrl(u.avatarMedium) || primeraUrl(u.avatarLarge) || primeraUrl(u.profilePicture) || null
  };
}

const rachas = new Map(); // cuenta lo ya procesado de cada racha de regalos

function procesarRegalo(datos) {
  const detalle = datos.giftDetails || datos.gift || {};
  const extra = datos.extendedGiftInfo || {};
  const tipo = Number(datos.giftType ?? detalle.giftType ?? detalle.type ?? extra.type ?? 0);
  const repeticiones = Math.max(1, Number(datos.repeatCount) || 1);
  const terminada = datos.repeatEnd === true || Number(datos.repeatEnd) === 1;
  const usuario = usuarioDe(datos);
  let cantidad = repeticiones;
  if (tipo === 1) {
    // Los regalos en racha llegan varias veces: se procesa solo lo nuevo de cada aviso
    const clave = `${usuario.id}:${datos.giftId}:${datos.groupId || ''}`;
    const previo = rachas.get(clave)?.cuenta || 0;
    cantidad = repeticiones - previo;
    if (terminada) rachas.delete(clave);
    else rachas.set(clave, { cuenta: repeticiones, hora: Date.now() });
    if (cantidad <= 0) return;
  }
  emitir('regalo', usuario, {
    regalo: {
      nombre: String(datos.giftName || detalle.giftName || detalle.name || extra.name || `Regalo ${datos.giftId}`).slice(0, 40),
      diamantes: Math.max(1, Number(datos.diamondCount || detalle.diamondCount || extra.diamond_count || extra.diamondCount) || 1),
      cantidad
    }
  });
}

setInterval(() => {
  const limite = Date.now() - 120000;
  for (const [clave, r] of rachas) if (r.hora < limite) rachas.delete(clave);
}, 60000);

// ---------------------------------------------------------------------------
// Conexión a eventos del Live: TikFinity (local ws://127.0.0.1:21213) o TikTok Directo
// ---------------------------------------------------------------------------
let wsTikFinity = null;
let tikFinityConectado = false;
let tikFinityReintento = null;
const TIKFINITY_ACTIVO = config.tikfinity?.activo !== false;
const TIKFINITY_URL = config.tikfinity?.url || 'ws://127.0.0.1:21213';

function normalizarTikFinity(msg) {
  const d = msg.data || msg;
  const evento = String(msg.event || msg.type || d.event || d.type || '').toLowerCase();
  const u = d.user || msg.user || d;
  const usuario = u.uniqueId || u.username || u.displayId || u.nickname || d.username || d.uniqueId || 'espectador';
  const id = String(u.userId || u.id || d.userId || usuario);
  const nombre = String(u.nickname || d.nickname || usuario).slice(0, 24);
  const avatar = u.profilePictureUrl || d.profilePictureUrl || primeraUrl(u.avatarThumb) || primeraUrl(u.avatarMedium) || null;
  const userObj = { id, usuario, nombre, avatar };
  return { evento, d, userObj };
}

function manejarMensajeTikFinity(msg) {
  if (!msg || typeof msg !== 'object') return;
  if (msg.event === 'state_update' || msg.event === 'config') return;

  const { evento, d, userObj } = normalizarTikFinity(msg);

  if (evento === 'chat' || evento === 'comment') {
    const texto = String(d.comment || d.content || d.commentParams || d.text || d.message || '').slice(0, 200);
    emitir('chat', userObj, { texto });
  } else if (evento === 'like') {
    const cantidad = Math.max(1, Number(d.likeCount || d.count || d.likes) || 1);
    emitir('like', userObj, { cantidad });
  } else if (evento === 'gift') {
    const giftName = String(d.giftName || d.name || `Regalo ${d.giftId || ''}`).slice(0, 40);
    const diamantes = Math.max(1, Number(d.diamondCount || d.coins || d.diamonds) || 1);
    const repeatCount = Math.max(1, Number(d.repeatCount || d.count) || 1);
    procesarRegalo({
      ...d,
      giftName,
      diamondCount: diamantes,
      repeatCount,
      user: userObj
    });
  }
}

function conectarTikFinity() {
  if (!TIKFINITY_ACTIVO) return;
  if (tikFinityReintento) {
    clearTimeout(tikFinityReintento);
    tikFinityReintento = null;
  }
  try {
    const ws = new WebSocket(TIKFINITY_URL);
    wsTikFinity = ws;

    ws.on('open', () => {
      tikFinityConectado = true;
      console.log(`[TikFinity] Conectado exitosamente en ${TIKFINITY_URL}`);
      cambiarEstadoTikTok('conectado', `Conectado mediante TikFinity (${TIKFINITY_URL})`);
      desconectarTikTokDirecto();
    });

    ws.on('message', (datos) => {
      try {
        const msg = JSON.parse(datos.toString());
        manejarMensajeTikFinity(msg);
      } catch (e) {
        console.error('[TikFinity] Error parseando mensaje:', e.message);
      }
    });

    ws.on('close', () => {
      const eraConectado = tikFinityConectado;
      tikFinityConectado = false;
      wsTikFinity = null;
      if (eraConectado) {
        console.log('[TikFinity] Conexión perdida. Activando respaldo directo de TikTok...');
        cambiarEstadoTikTok('desconectado', 'Se desconectó TikFinity. Reconectando...');
      }
      programarReintentoTikFinity();
      if (!conexionTikTokDirecta && usuarioTikTok) {
        conectarTikTokDirecto().catch(() => {});
      }
    });

    ws.on('error', (e) => {
      if (!tikFinityConectado) {
        if (!conexionTikTokDirecta && usuarioTikTok) {
          conectarTikTokDirecto().catch(() => {});
        }
      }
      try { ws.close(); } catch {}
    });
  } catch (e) {
    programarReintentoTikFinity();
  }
}

function programarReintentoTikFinity() {
  if (tikFinityReintento || !TIKFINITY_ACTIVO) return;
  tikFinityReintento = setTimeout(() => {
    tikFinityReintento = null;
    conectarTikFinity();
  }, 5000);
}

let conexionTikTokDirecta = null;
let reintentoSegundos = 10;
let reintentoPendiente = null;

function desconectarTikTokDirecto() {
  if (reintentoPendiente) {
    clearTimeout(reintentoPendiente);
    reintentoPendiente = null;
  }
  if (conexionTikTokDirecta) {
    try { conexionTikTokDirecta.disconnect(); } catch {}
    conexionTikTokDirecta = null;
  }
}

async function conectarTikTokDirecto() {
  if (tikFinityConectado) return;
  const { TikTokLiveConnection, WebcastEvent, ControlEvent } = await import('tiktok-live-connector');
  const tieneApiKey = Boolean(config.tiktok?.apiKeyEulerStream);
  const opciones = {
    enableExtendedGiftInfo: tieneApiKey,
    processInitialData: false,
    fetchRoomInfoOnConnect: tieneApiKey
  };
  if (tieneApiKey) opciones.signApiKey = config.tiktok.apiKeyEulerStream;
  const conexion = new TikTokLiveConnection(usuarioTikTok, opciones);
  conexionTikTokDirecta = conexion;

  conexion.on(WebcastEvent.CHAT, (d) => {
    if (tikFinityConectado) return;
    emitir('chat', usuarioDe(d), { texto: String(d.comment || d.content || '').slice(0, 200) });
  });
  conexion.on(WebcastEvent.LIKE, (d) => {
    if (tikFinityConectado) return;
    emitir('like', usuarioDe(d), { cantidad: Math.max(1, Number(d.likeCount || d.count) || 1) });
  });
  conexion.on(WebcastEvent.GIFT, (d) => {
    if (tikFinityConectado) return;
    try { procesarRegalo(d); } catch (e) { console.error('[TikTok] No pude leer un regalo:', e.message); }
  });
  conexion.on(ControlEvent.DISCONNECTED, () => {
    if (tikFinityConectado) return;
    cambiarEstadoTikTok('desconectado', `Se cortó la conexión con @${usuarioTikTok}. Reintento en ${reintentoSegundos} s`);
    programarReintentoDirecto();
  });
  conexion.on(ControlEvent.ERROR, (e) => {
    if (tikFinityConectado) return;
    console.error('[TikTok] Error:', e?.message || e);
  });

  try {
    const estado = await conexion.connect();
    if (tikFinityConectado) {
      conexion.disconnect();
      return;
    }
    reintentoSegundos = 10;
    cambiarEstadoTikTok('conectado', `Conectado al live de @${usuarioTikTok} (sala ${estado?.roomId || '?'})`);
  } catch (e) {
    if (tikFinityConectado) return;
    const mensaje = String(e?.message || e);
    const fueraDeLinea = /offline|not live|isn't online|UserOffline/i.test(mensaje + ' ' + (e?.constructor?.name || ''));
    cambiarEstadoTikTok(
      fueraDeLinea ? 'esperando' : 'error',
      fueraDeLinea
        ? `@${usuarioTikTok} no está en vivo todavía. Reintento en ${reintentoSegundos} s`
        : `No pude conectar con @${usuarioTikTok}: ${mensaje}. Reintento en ${reintentoSegundos} s`
    );
    programarReintentoDirecto();
  }
}

function programarReintentoDirecto() {
  if (tikFinityConectado || reintentoPendiente) return;
  const espera = reintentoSegundos;
  reintentoSegundos = Math.min(60, reintentoSegundos + 10);
  reintentoPendiente = setTimeout(() => {
    reintentoPendiente = null;
    conectarTikTokDirecto().catch((e) => {
      cambiarEstadoTikTok('error', `Falló la conexión: ${e.message}`);
      programarReintentoDirecto();
    });
  }, espera * 1000);
}

function iniciarConexionLive() {
  if (TIKFINITY_ACTIVO) {
    conectarTikFinity();
  } else {
    conectarTikTokDirecto().catch(() => {});
  }
}

// ---------------------------------------------------------------------------
// Servidor web: juego, simulador y recursos del repo (solo Graphics y Audio)
// ---------------------------------------------------------------------------
const TIPOS_MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.ogg': 'audio/ogg',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.ttf': 'font/ttf'
};

function servirArchivo(res, raiz, relativo, cache) {
  const destino = path.resolve(raiz, '.' + path.sep + relativo);
  if (destino !== raiz && !destino.startsWith(raiz + path.sep)) return responder(res, 403, 'Acceso denegado');
  fs.stat(destino, (err, info) => {
    if (err || !info.isFile()) return responder(res, 404, 'No encontrado');
    res.writeHead(200, {
      'Content-Type': TIPOS_MIME[path.extname(destino).toLowerCase()] || 'application/octet-stream',
      'Content-Length': info.size,
      'Cache-Control': cache ? 'public, max-age=3600' : 'no-cache'
    });
    fs.createReadStream(destino).pipe(res);
  });
}

function responder(res, codigo, texto) {
  res.writeHead(codigo, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end(texto);
}

const servidor = http.createServer((req, res) => {
  let ruta;
  try {
    ruta = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  } catch {
    return responder(res, 400, 'Ruta inválida');
  }
  if (ruta === '/' || ruta === '/index.html') return servirArchivo(res, PUBLICO, 'index.html', false);
  if (ruta === '/simulador' || ruta === '/simulador.html') return servirArchivo(res, PUBLICO, 'simulador.html', false);
  if (ruta === '/api/estado') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify({ modo: MODO_SIM ? 'simulacion' : 'tiktok', tiktok: estadoTikTok, juegos: contarJuegos(), especies: ESPECIES.length, jugadores: Object.keys(perfiles).length }));
  }
  if (ruta.startsWith('/repo/Graphics/') || ruta.startsWith('/repo/Audio/')) return servirArchivo(res, REPO, ruta.slice('/repo/'.length), true);
  return servirArchivo(res, PUBLICO, ruta.slice(1), false);
});

const wss = new WebSocketServer({ server: servidor, path: '/ws' });
wss.on('connection', (ws, req) => {
  const rol = new URL(req.url, 'http://localhost').searchParams.get('rol') === 'simulador' ? 'simulador' : 'juego';
  const cliente = { ws, rol, desde: Date.now() };
  clientes.add(cliente);
  if (rol === 'juego') {
    elegirPrincipal();
    enviar(cliente, {
      t: 'hola',
      config: configPublica(),
      especies: ESPECIES,
      modo: MODO_SIM ? 'simulacion' : 'tiktok',
      tiktok: estadoTikTok,
      principal: cliente === principal
    });
  }
  avisarSimuladores();
  ws.on('message', (datos) => {
    let m;
    try { m = JSON.parse(datos); } catch { return; }
    manejarMensaje(cliente, m);
  });
  ws.on('close', () => {
    clientes.delete(cliente);
    if (cliente === principal) {
      principal = null;
      elegirPrincipal();
    }
    avisarSimuladores();
  });
});

servidor.on('error', (e) => {
  if (e.code === 'EADDRINUSE') console.error(`El puerto ${PUERTO} ya está en uso. Cierra la otra ventana del servidor o cambia "puerto" en config.json.`);
  else console.error(e);
  process.exit(1);
});

servidor.listen(PUERTO, HOST, () => {
  const base = `http://${HOST}:${PUERTO}`;
  const porRareza = ESPECIES.reduce((a, e) => ((a[e.rareza] = (a[e.rareza] || 0) + 1), a), {});
  console.log(`\n${config.titulo || 'Vortex Rival'}: servidor listo`);
  console.log(`  Juego para OBS (1080×1920): ${base}/`);
  console.log(`  Simulador:                  ${base}/simulador`);
  console.log(`  Modo: ${MODO_SIM ? 'simulación (sin TikTok)' : 'TikTok @' + usuarioTikTok}`);
  console.log(`  Especies: ${ESPECIES.length} (normales ${porRareza.normal || 0}, raras ${porRareza.rara || 0}, especiales ${porRareza.especial || 0})`);
  console.log(`  Jugadores guardados: ${Object.keys(perfiles).length}\n`);
  if (!MODO_SIM) iniciarConexionLive();
});

function cerrar() {
  try { guardarYa(); } catch (e) { console.error('No pude guardar a los jugadores:', e.message); }
  process.exit(0);
}
process.on('SIGINT', cerrar);
process.on('SIGTERM', cerrar);
