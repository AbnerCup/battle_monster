/* Vortex Rival: juego de batalla para TikTok LIVE.
   Se dibuja en un lienzo de 1080×1920 y se carga en OBS como fuente de navegador.
   Recibe likes, regalos y chat desde server.js; el servidor guarda los cambios de cada jugador. */
(function () {
  'use strict';

  // ---------------------------------------------------------------------------
  // Lienzo
  // ---------------------------------------------------------------------------
  var W = 1080, H = 1920, TAU = Math.PI * 2;
  var lienzo = document.getElementById('juego');
  var ctx = lienzo.getContext('2d');
  var PARAMS = new URLSearchParams(location.search || '');
  var DEBUG = PARAMS.get('debug') === '1';
  var PRUEBA = window.__PRUEBA || null;

  function ajustarLienzo() {
    var s = Math.min((window.innerWidth || W) / W, (window.innerHeight || H) / H);
    lienzo.style.width = Math.floor(W * s) + 'px';
    lienzo.style.height = Math.floor(H * s) + 'px';
  }
  if (window.addEventListener) window.addEventListener('resize', ajustarLienzo);
  ajustarLienzo();

  // ---------------------------------------------------------------------------
  // Diseño: colores de bosque y ruta, letra gruesa con borde para leer en el celular
  // ---------------------------------------------------------------------------
  var C = {
    bosque: '#10291B', bosque2: '#1B4630', hoja: '#A8E063', sol: '#FFC93C',
    cielo: '#4CC3FF', baya: '#FF4D6D', nube: '#F7FBF4', tinta: '#071A0F', musgo: '#A9C4B0'
  };
  var FT = '"Lilita One", "Arial Black", Impact, sans-serif';
  var FX = '"Nunito", "Segoe UI", Arial, sans-serif';
  var RAREZA = {
    normal: { color: '#DCEBD2', nombre: 'Normal', titulo: '¡Nueva captura!' },
    rara: { color: C.cielo, nombre: 'Rara', titulo: '¡Captura rara!' },
    especial: { color: C.sol, nombre: 'Especial', titulo: '¡Captura especial!' }
  };
  var TIPOS = {
    NORMAL: ['Normal', '#C9C5A8'], FIRE: ['Fuego', '#FF8A3D'], WATER: ['Agua', '#4CA8FF'], GRASS: ['Planta', '#5ED16A'],
    ELECTRIC: ['Eléctrico', '#FFD93D'], ICE: ['Hielo', '#8EEAF2'], FIGHTING: ['Lucha', '#E0534A'], POISON: ['Veneno', '#B65FD6'],
    GROUND: ['Tierra', '#E3B860'], FLYING: ['Volador', '#A9B8FF'], PSYCHIC: ['Psíquico', '#FF6FA8'], BUG: ['Bicho', '#A8C83A'],
    ROCK: ['Roca', '#C4A95A'], GHOST: ['Fantasma', '#9A7FDA'], DRAGON: ['Dragón', '#8A7BFF'], DARK: ['Siniestro', '#9A8474'],
    STEEL: ['Acero', '#B8C4D6'], FAIRY: ['Hada', '#F7A8E0']
  };
  // Tabla de efectividad (las inmunidades se suavizan a 0,35 para que ningún duelo quede trabado)
  var EFECTIVIDAD = {
    NORMAL: { ROCK: 0.5, GHOST: 0, STEEL: 0.5 },
    FIRE: { FIRE: 0.5, WATER: 0.5, GRASS: 2, ICE: 2, BUG: 2, ROCK: 0.5, DRAGON: 0.5, STEEL: 2 },
    WATER: { FIRE: 2, WATER: 0.5, GRASS: 0.5, GROUND: 2, ROCK: 2, DRAGON: 0.5 },
    ELECTRIC: { WATER: 2, ELECTRIC: 0.5, GRASS: 0.5, GROUND: 0, FLYING: 2, DRAGON: 0.5 },
    GRASS: { FIRE: 0.5, WATER: 2, GRASS: 0.5, POISON: 0.5, GROUND: 2, FLYING: 0.5, BUG: 0.5, ROCK: 2, DRAGON: 0.5, STEEL: 0.5 },
    ICE: { FIRE: 0.5, WATER: 0.5, GRASS: 2, ICE: 0.5, GROUND: 2, FLYING: 2, DRAGON: 2, STEEL: 0.5 },
    FIGHTING: { NORMAL: 2, ICE: 2, POISON: 0.5, FLYING: 0.5, PSYCHIC: 0.5, BUG: 0.5, ROCK: 2, GHOST: 0, DARK: 2, STEEL: 2, FAIRY: 0.5 },
    POISON: { GRASS: 2, POISON: 0.5, GROUND: 0.5, ROCK: 0.5, GHOST: 0.5, STEEL: 0, FAIRY: 2 },
    GROUND: { FIRE: 2, ELECTRIC: 2, GRASS: 0.5, POISON: 2, FLYING: 0, BUG: 0.5, ROCK: 2, STEEL: 2 },
    FLYING: { ELECTRIC: 0.5, GRASS: 2, FIGHTING: 2, BUG: 2, ROCK: 0.5, STEEL: 0.5 },
    PSYCHIC: { FIGHTING: 2, POISON: 2, PSYCHIC: 0.5, DARK: 0, STEEL: 0.5 },
    BUG: { FIRE: 0.5, GRASS: 2, FIGHTING: 0.5, POISON: 0.5, FLYING: 0.5, PSYCHIC: 2, GHOST: 0.5, DARK: 2, STEEL: 0.5, FAIRY: 0.5 },
    ROCK: { FIRE: 2, ICE: 2, FIGHTING: 0.5, GROUND: 0.5, FLYING: 2, BUG: 2, STEEL: 0.5 },
    GHOST: { NORMAL: 0, PSYCHIC: 2, GHOST: 2, DARK: 0.5 },
    DRAGON: { DRAGON: 2, STEEL: 0.5, FAIRY: 0 },
    DARK: { FIGHTING: 0.5, PSYCHIC: 2, GHOST: 2, DARK: 0.5, FAIRY: 0.5 },
    STEEL: { FIRE: 0.5, WATER: 0.5, ELECTRIC: 0.5, ICE: 2, ROCK: 2, STEEL: 0.5, FAIRY: 2 },
    FAIRY: { FIRE: 0.5, FIGHTING: 2, POISON: 0.5, DRAGON: 2, DARK: 2, STEEL: 0.5 }
  };
  var MUSICA = { sala: '/repo/Audio/BGM/Survivor/Route.ogg', batalla: '/repo/Audio/BGM/Survivor/Battle wild.ogg' };
  var SFX = {
    entrar: '/repo/Audio/SE/BW2MenuSelect.WAV', tic: '/repo/Audio/SE/BW2MenuChoose.WAV',
    agitar: '/repo/Audio/SE/Battle ball shake.ogg', captura: '/repo/Audio/ME/Battle capture success.ogg',
    golpe: '/repo/Audio/SE/Battle damage normal.ogg', golpeSuper: '/repo/Audio/SE/Battle damage super.ogg',
    golpeDebil: '/repo/Audio/SE/Battle damage weak.ogg', derrota: '/repo/Audio/SE/Pkmn faint.ogg',
    curar: '/repo/Audio/SE/Pkmn healing.ogg', poder: '/repo/Audio/SE/Battle recall.ogg',
    victoria: '/repo/Audio/ME/Badge get.ogg', nivel: '/repo/Audio/SE/Pkmn level up.ogg'
  };
  var CLASES_BOT = ['Montañera', 'Campista', 'Nadador', 'Pescadora', 'Karateka', 'Ornitólogo', 'Exploradora', 'Domador', 'Mecánica', 'Científico', 'Patinadora', 'Montañero'];

  // Zonas de la pantalla: arriba y abajo quedan franjas que TikTok tapa con su propia interfaz
  var ARENA = { x0: 90, x1: 990, y0: 470, y1: 1450 };
  var CENTRO = { x: 540, y: 900 }; // la pelea se mantiene arriba del chat de TikTok
  var COLS = 4, CUPOS_PAGINA = 20, GX = 48, GY = 536, GW = 235, GH = 172, GAP = 12;

  // ---------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------
  function limitar(v, a, b) { return v < a ? a : v > b ? b : v; }
  function azar(a, b) { return a + Math.random() * (b - a); }
  function elegir(lista) { return lista[Math.floor(Math.random() * lista.length)]; }
  function rebote(k) { var s = 1.70158; k = k - 1; return k * k * ((s + 1) * k + s) + 1; }
  function rgb(hex) {
    var h = String(hex).replace('#', '');
    return [parseInt(h.substr(0, 2), 16), parseInt(h.substr(2, 2), 16), parseInt(h.substr(4, 2), 16)];
  }
  function rgba(hex, a) { var c = rgb(hex); return 'rgba(' + c[0] + ',' + c[1] + ',' + c[2] + ',' + a + ')'; }
  function oscurecer(hex, k) { var c = rgb(hex); k = k || 0.5; return 'rgb(' + Math.round(c[0] * k) + ',' + Math.round(c[1] * k) + ',' + Math.round(c[2] * k) + ')'; }
  function colorDeNombre(s) {
    var h = 0; s = String(s || '?');
    for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0;
    return 'hsl(' + (h % 360) + ',48%,42%)';
  }
  function inicial(s) { var letras = Array.from(String(s || '?').trim()); return (letras[0] || '?').toUpperCase(); }
  function colorTipo(t) { return (TIPOS[t] || TIPOS.NORMAL)[1]; }
  function nombreTipo(t) { return (TIPOS[t] || [t])[0]; }
  function multiplicador(tipoAtaque, tiposDefensa) {
    var fila = EFECTIVIDAD[tipoAtaque] || {}, m = 1;
    for (var i = 0; i < tiposDefensa.length; i++) {
      var v = fila[tiposDefensa[i]];
      if (v === 0) v = 0.35;
      if (v) m *= v;
    }
    return m;
  }

  var imagenes = {};
  function imagen(url) {
    if (!url) return null;
    var im = imagenes[url];
    if (!im) { im = new Image(); im.src = url; imagenes[url] = im; }
    return im;
  }
  function cargada(im) { return !!(im && im.complete && im.naturalWidth > 0); }

  var cacheRecorte = {}, totalRecortes = 0;
  function recortar(s, max) {
    var clave = ctx.font + '|' + max + '|' + s;
    var r = cacheRecorte[clave];
    if (r !== undefined) return r;
    r = s;
    if (ctx.measureText(r).width > max) {
      while (r.length > 1 && ctx.measureText(r + '…').width > max) r = r.slice(0, -1);
      r += '…';
    }
    if (++totalRecortes > 3000) { cacheRecorte = {}; totalRecortes = 0; }
    cacheRecorte[clave] = r;
    return r;
  }
  function escribir(s, x, y, o) {
    o = o || {};
    ctx.font = o.f || '800 32px ' + FX;
    ctx.textAlign = o.al || 'left';
    ctx.textBaseline = o.base || 'alphabetic';
    s = String(s);
    if (o.max) s = recortar(s, o.max);
    if (o.borde) {
      ctx.lineJoin = 'round';
      ctx.miterLimit = 2;
      ctx.lineWidth = o.borde;
      ctx.strokeStyle = o.cb || C.tinta;
      ctx.strokeText(s, x, y);
    }
    ctx.fillStyle = o.c || C.nube;
    ctx.fillText(s, x, y);
    return s;
  }
  function rect(x, y, w, h, r) {
    r = Math.min(r, w / 2, h / 2);
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }
  function panel(x, y, w, h, r, fondo, borde) {
    rect(x, y, w, h, r);
    ctx.fillStyle = fondo || 'rgba(7,26,15,0.86)';
    ctx.fill();
    if (borde) { ctx.lineWidth = 3; ctx.strokeStyle = borde; ctx.stroke(); }
  }
  function circulo(x, y, r, color) { ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fillStyle = color; ctx.fill(); }
  function corazon(x, y, s, color) {
    ctx.beginPath();
    ctx.moveTo(x, y + s * 0.35);
    ctx.bezierCurveTo(x - s * 1.1, y - s * 0.35, x - s * 0.45, y - s * 1.05, x, y - s * 0.45);
    ctx.bezierCurveTo(x + s * 0.45, y - s * 1.05, x + s * 1.1, y - s * 0.35, x, y + s * 0.35);
    ctx.closePath();
    ctx.fillStyle = color;
    ctx.fill();
  }
  function sombra(x, y, rx, ry) {
    ctx.beginPath();
    ctx.ellipse(x, y, Math.max(1, rx), Math.max(1, ry), 0, 0, TAU);
    ctx.fillStyle = 'rgba(0,0,0,0.28)';
    ctx.fill();
  }

  // Sprites del repo: hojas de 8 direcciones (orden de PMD) o de 4 (orden de RPG Maker)
  var FILA_4 = [0, 2, 2, 2, 3, 1, 1, 1];
  var DIR_DE_OCTANTE = { '0': 2, '1': 1, '2': 0, '3': 7, '4': 6, '-4': 6, '-3': 5, '-2': 4, '-1': 3 };
  function direccionDe(dx, dy) { return DIR_DE_OCTANTE[Math.round(Math.atan2(dy, dx) / (Math.PI / 4))]; }
  function hojaDe(esp, reposo) { return reposo && esp.reposo ? esp.reposo : esp.hoja; }
  function tamCuadro(esp, reposo) { var h = hojaDe(esp, reposo); return { w: h.w / h.cuadros, h: h.h / h.dirs }; }
  // Caja visible del primer cuadro de cada hoja: apoya los pies en el suelo y mide el cuerpo real
  function medidas(hoja) {
    if (hoja._med) return hoja._med;
    var im = imagen(hoja.url);
    if (!cargada(im)) return null;
    var fw = Math.round(hoja.w / hoja.cuadros), fh = Math.round(hoja.h / hoja.dirs);
    var m = { arriba: 0, abajo: 0, ancho: fw, alto: fh };
    try {
      var c = document.createElement('canvas');
      c.width = fw;
      c.height = fh;
      var g = c.getContext('2d');
      g.drawImage(im, 0, 0, fw, fh, 0, 0, fw, fh);
      var datos = g.getImageData(0, 0, fw, fh).data, x0 = fw, x1 = -1, y0 = fh, y1 = -1;
      for (var y = 0; y < fh; y++) {
        for (var x = 0; x < fw; x++) {
          if (datos[(y * fw + x) * 4 + 3] > 20) {
            if (x < x0) x0 = x;
            if (x > x1) x1 = x;
            if (y < y0) y0 = y;
            y1 = y;
          }
        }
      }
      if (x1 >= 0) m = { arriba: y0, abajo: fh - 1 - y1, ancho: x1 - x0 + 1, alto: y1 - y0 + 1 };
    } catch (e) {
      // Si el navegador no deja leer los píxeles, se usa el cuadro completo
    }
    hoja._med = m;
    return m;
  }
  function rellenoInferior(hoja) { var m = medidas(hoja); return m ? m.abajo : 0; }
  function precargar(esp) {
    if (!esp) return;
    imagen(esp.hoja.url);
    if (esp.reposo) imagen(esp.reposo.url);
  }
  function dibujarEspecie(esp, dir, cuadro, x, y, escala, reposo) {
    if (!esp) return;
    var hoja = hojaDe(esp, reposo);
    var im = imagen(hoja.url);
    if (!cargada(im)) return;
    var fw = hoja.w / hoja.cuadros, fh = hoja.h / hoja.dirs;
    var fila = hoja.dirs === 8 ? dir : FILA_4[dir];
    var col = Math.floor(cuadro) % hoja.cuadros;
    var dw = Math.round(fw * escala), dh = Math.round(fh * escala);
    var pies = Math.round(rellenoInferior(hoja) * escala);
    ctx.drawImage(im, col * fw, fila * fh, fw, fh, Math.round(x - dw / 2), Math.round(y - dh + pies), dw, dh);
  }
  function escalaQueCabe(esp, ancho, alto, maxima) {
    var m = medidas(hojaDe(esp, true)), c = tamCuadro(esp, true);
    var w = m ? m.ancho : c.w, h = m ? m.alto : c.h;
    return Math.max(1, Math.min(maxima, Math.floor(Math.min(ancho / w, alto / h) * 2) / 2));
  }
  function dibujarAvatar(nombre, url, x, y, r, aro) {
    ctx.save();
    ctx.beginPath();
    ctx.arc(x, y, r, 0, TAU);
    ctx.closePath();
    var im = imagen(url);
    if (cargada(im)) {
      ctx.clip();
      ctx.imageSmoothingEnabled = true;
      ctx.drawImage(im, x - r, y - r, r * 2, r * 2);
    } else {
      ctx.fillStyle = colorDeNombre(nombre);
      ctx.fill();
      escribir(inicial(nombre), x, y + r * 0.36, { f: Math.round(r * 1.05) + 'px ' + FT, al: 'center' });
    }
    ctx.restore();
    if (aro) {
      ctx.lineWidth = Math.max(3, r * 0.1);
      ctx.strokeStyle = aro;
      ctx.beginPath();
      ctx.arc(x, y, r, 0, TAU);
      ctx.stroke();
    }
  }
  function chipsTipos(tipos, cx, y, tam) {
    ctx.font = '900 ' + tam + 'px ' + FX;
    var anchos = tipos.map(function (tp) { return ctx.measureText(nombreTipo(tp)).width + tam * 1.3; });
    var total = anchos.reduce(function (a, b) { return a + b; }, 0) + (tipos.length - 1) * 12;
    var x = cx - total / 2;
    tipos.forEach(function (tp, i) {
      panel(x, y, anchos[i], tam * 1.55, tam * 0.78, colorTipo(tp));
      escribir(nombreTipo(tp), x + anchos[i] / 2, y + tam * 1.12, { f: '900 ' + tam + 'px ' + FX, al: 'center', c: C.tinta });
      x += anchos[i] + 12;
    });
  }

  // ---------------------------------------------------------------------------
  // Estado del juego
  // ---------------------------------------------------------------------------
  var CFG = null, ESPECIES = [], POR_ID = {}, MODO = '', TIKTOK = null, PRINCIPAL = false;
  var perfiles = {};      // id -> perfil del jugador (el servidor lo manda con cada evento)
  var sala = [];          // jugadores esperando: [{id, desde, activo}]
  var taps = {};          // likes acumulados de quien todavía no entra
  var avisos = [], avisoTap = null, capturas = [];
  var fase = 'carga', t = 0, ronda = 0;
  var cuentaSala = null, pagina = 0, paginaT = 0;
  var batalla = null, campeon = null, fondos = {};

  // ---------------------------------------------------------------------------
  // Conexión con server.js
  // ---------------------------------------------------------------------------
  var ws = null, conectado = false;
  function conectar() {
    var url = (location.protocol === 'https:' ? 'wss://' : 'ws://') + location.host + '/ws?rol=juego';
    try { ws = new WebSocket(url); } catch (e) { setTimeout(conectar, 2000); return; }
    ws.onopen = function () { conectado = true; };
    ws.onclose = function () { conectado = false; PRINCIPAL = false; setTimeout(conectar, 1500); };
    ws.onerror = function () {};
    ws.onmessage = function (m) {
      var d;
      try { d = JSON.parse(m.data); } catch (e) { return; }
      recibir(d);
    };
  }
  function enviar(o) { if (ws && ws.readyState === 1) ws.send(JSON.stringify(o)); }
  function recibir(d) {
    if (d.t === 'hola') {
      CFG = d.config;
      ESPECIES = d.especies || [];
      POR_ID = {};
      ESPECIES.forEach(function (e) { POR_ID[e.id] = e; });
      MODO = d.modo;
      TIKTOK = d.tiktok;
      PRINCIPAL = !!d.principal;
      fondos = {};
      if (fase === 'carga') irASala();
    } else if (d.t === 'principal') {
      PRINCIPAL = !!d.valor;
    } else if (d.t === 'tiktok') {
      TIKTOK = d.tiktok;
    } else if (d.t === 'evento' && CFG) {
      procesarEvento(d.evento);
    }
  }
  function guardar(lista) {
    if (!PRINCIPAL) return;
    enviar({ t: 'guardar_perfiles', perfiles: Array.isArray(lista) ? lista : [lista] });
  }

  // ---------------------------------------------------------------------------
  // Jugadores: entrar, capturar, mochila y poderes
  // ---------------------------------------------------------------------------
  function perfilDesdeServidor(p) {
    var local = perfiles[p.id];
    if (!local) { perfiles[p.id] = p; return p; }
    // El juego es dueño de niveles y mochila; del servidor solo se toman nombre y foto
    local.nombre = p.nombre;
    local.usuario = p.usuario;
    if (p.avatar) local.avatar = p.avatar;
    return local;
  }
  function entradaActiva(p) {
    if (!p.mochila || !p.mochila.length) {
      var e0 = ESPECIES[0];
      p.mochila = [{ especie: e0.id, nivel: 1, exp: 0, rareza: e0.rareza }];
    }
    for (var i = 0; i < p.mochila.length; i++) if (p.mochila[i].especie === p.activo && POR_ID[p.activo]) return p.mochila[i];
    for (var j = 0; j < p.mochila.length; j++) if (POR_ID[p.mochila[j].especie]) { p.activo = p.mochila[j].especie; return p.mochila[j]; }
    p.activo = p.mochila[0].especie;
    return p.mochila[0];
  }
  function enSala(id) { for (var i = 0; i < sala.length; i++) if (sala[i].id === id) return sala[i]; return null; }
  function luchadorDe(id) {
    if (!batalla) return null;
    for (var i = 0; i < batalla.luchadores.length; i++) if (batalla.luchadores[i].id === id) return batalla.luchadores[i];
    return null;
  }
  function avisar(texto, color) {
    avisos.push({ texto: texto, color: color || C.nube, t0: t });
    if (avisos.length > 8) avisos.shift();
  }

  function procesarEvento(e) {
    if (!e || !e.perfil || !e.perfil.id) return;
    var p = perfilDesdeServidor(e.perfil);
    precargar(POR_ID[p.activo]);
    var s = enSala(p.id);
    if (s) s.activo = t;
    if (e.tipo === 'like') alLike(p, Number(e.cantidad) || 1);
    else if (e.tipo === 'regalo') alRegalo(p, e.regalo || {});
    else if (e.tipo === 'chat') alChat(p, String(e.texto || ''));
  }
  function alLike(p, n) {
    var l = batalla && fase === 'batalla' && batalla.sub === 'lucha' ? luchadorDe(p.id) : null;
    if (l && l.vivo) { curar(l, n * (CFG.batalla.curacionPorLike || 3), true); return; }
    if (enSala(p.id)) return;
    var meta = CFG.sala.likesParaEntrar || 25;
    taps[p.id] = (taps[p.id] || 0) + n;
    avisoTap = { nombre: p.nombre, taps: Math.min(taps[p.id], meta), meta: meta, t0: t };
    if (taps[p.id] >= meta) { delete taps[p.id]; unirse(p); }
  }
  function alRegalo(p, r) {
    var diamantes = Math.max(1, Number(r.diamantes) || 1) * Math.max(1, Number(r.cantidad) || 1);
    var l = batalla && fase === 'batalla' && batalla.sub !== 'fin' ? luchadorDe(p.id) : null;
    if (l && l.vivo) { aplicarPoder(l, poderDe(r, diamantes), diamantes); return; }
    unirse(p);
    var rareza = rarezaDeRegalo(diamantes);
    if (rareza) capturar(p, rareza);
    else avisar(p.nombre + ' regaló ' + (r.nombre || 'un regalo') + (r.cantidad > 1 ? ' ×' + r.cantidad : ''), C.hoja);
  }
  function alChat(p, texto) {
    var s = texto.trim().toLowerCase(), cm = CFG.comandos || {};
    if (cm.mochila && s.indexOf(String(cm.mochila).toLowerCase()) === 0) cambiarMochila(p);
    else if (cm.jugar && s.indexOf(String(cm.jugar).toLowerCase()) === 0) unirse(p);
  }
  function unirse(p) {
    if (enSala(p.id)) return;
    sala.push({ id: p.id, desde: t, activo: t });
    delete taps[p.id];
    avisar(p.nombre + ' entró a la arena', C.hoja);
    sonido(SFX.entrar, 0.45);
  }
  function rarezaDeRegalo(d) {
    var c = CFG.captura;
    if (d >= c.especial.desdeDiamantes) return 'especial';
    if (d >= c.rara.desdeDiamantes) return 'rara';
    if (d >= c.normal.desdeDiamantes) return 'normal';
    return null;
  }
  function poderDe(r, d) {
    var mapa = CFG.regalosPorNombre || {}, nombre = String(r.nombre || '').toLowerCase();
    for (var k in mapa) {
      if (Object.prototype.hasOwnProperty.call(mapa, k) && k.toLowerCase() === nombre && /^(escudo|ataque|potencia)$/.test(mapa[k])) return mapa[k];
    }
    var pd = CFG.poderes;
    if (d >= pd.potencia.desdeDiamantes) return 'potencia';
    if (d >= pd.ataque.desdeDiamantes) return 'ataque';
    return 'escudo';
  }
  function capturar(p, rareza) {
    var tiene = {};
    p.mochila.forEach(function (m) { tiene[m.especie] = true; });
    var opciones = ESPECIES.filter(function (e) { return e.rareza === rareza && !tiene[e.id]; });
    if (!opciones.length) opciones = ESPECIES.filter(function (e) { return e.rareza === rareza; });
    if (!opciones.length) opciones = ESPECIES;
    var esp = elegir(opciones);
    precargar(esp);
    p.mochila.push({ especie: esp.id, nivel: 1, exp: 0, rareza: rareza });
    p.activo = esp.id;
    guardar(p);
    avisar(p.nombre + ' capturó a ' + esp.nombre, RAREZA[rareza].color);
    if (fase === 'batalla') return; // en batalla basta el aviso; la animación grande es para la sala
    capturas.push({ perfil: p, esp: esp, rareza: rareza, t: 0 });
  }
  function cambiarMochila(p) {
    unirse(p);
    if (!p.mochila || p.mochila.length < 2) {
      avisar(p.nombre + ': regala para capturar más Pokémon', C.musgo);
      return;
    }
    var i = 0;
    for (; i < p.mochila.length; i++) if (p.mochila[i].especie === p.activo) break;
    var sig = p.mochila[(i + 1) % p.mochila.length];
    p.activo = sig.especie;
    guardar(p);
    var esp = POR_ID[sig.especie];
    avisar(p.nombre + ' eligió a ' + (esp ? esp.nombre : sig.especie) + (luchadorDe(p.id) ? ' para la próxima ronda' : ''), C.cielo);
  }

  // ---------------------------------------------------------------------------
  // Fase: sala de espera
  // ---------------------------------------------------------------------------
  function irASala() {
    fase = 'sala';
    cuentaSala = null;
    pagina = 0;
    paginaT = 0;
    var limite = t - (CFG.sala.minutosInactividad || 15) * 60;
    sala = sala.filter(function (s) { return s.activo >= limite; });
    musica(MUSICA.sala);
  }
  function botsNecesarios(humanos) {
    return humanos > 0 ? Math.max(0, (CFG.sala.rellenarConBotsHasta || 0) - humanos) : 0;
  }
  function faltanParaEmpezar() {
    var total = sala.length + botsNecesarios(sala.length);
    return Math.max(0, Math.max(2, CFG.sala.minimoJugadores || 2) - total);
  }
  function actualizarSala(dt) {
    var listos = sala.length > 0 && faltanParaEmpezar() === 0;
    if (!listos) {
      cuentaSala = null;
    } else {
      if (cuentaSala === null) cuentaSala = CFG.sala.segundos || 40;
      if (sala.length >= (CFG.sala.cupos || 20)) cuentaSala = Math.min(cuentaSala, 8);
      cuentaSala = Math.max(0, cuentaSala - dt);
      if (cuentaSala === 0 && !capturas.length) iniciarBatalla();
    }
    var paginas = Math.max(1, Math.ceil(sala.length / CUPOS_PAGINA));
    paginaT += dt;
    if (paginaT > 6) { paginaT = 0; pagina = (pagina + 1) % paginas; }
    if (pagina >= paginas) pagina = 0;
    if (capturas.length) {
      capturas[0].t += dt * (capturas.length > 2 ? 1.7 : 1);
      if (capturas[0].t > 3.7) capturas.shift();
    }
  }

  // ---------------------------------------------------------------------------
  // Fase: batalla todos contra todos
  // ---------------------------------------------------------------------------
  function crearBot(i, nivel) {
    var r = Math.random(), rareza = r < 0.6 ? 'normal' : r < 0.9 ? 'rara' : 'especial';
    var opciones = ESPECIES.filter(function (e) { return e.rareza === rareza; });
    var esp = elegir(opciones.length ? opciones : ESPECIES);
    return { id: 'bot_' + i, nombre: CLASES_BOT[(ronda + i) % CLASES_BOT.length] + ' bot', avatar: null, especie: esp.id, nivel: Math.max(1, nivel + Math.round(azar(-1, 1))), bot: true };
  }
  function crearLuchador(q, i, total) {
    var esp = POR_ID[q.especie] || ESPECIES[0], b = esp.base, nv = q.nivel || 1;
    var cx = (ARENA.x0 + ARENA.x1) / 2, cy = (ARENA.y0 + ARENA.y1) / 2;
    var ang = (i / total) * TAU + azar(-0.15, 0.15);
    var x = cx + Math.cos(ang) * ((ARENA.x1 - ARENA.x0) / 2 - 70) * azar(0.7, 1);
    var y = cy + Math.sin(ang) * ((ARENA.y1 - ARENA.y0) / 2 - 90) * azar(0.7, 1);
    var hp = Math.round(140 + b.hp * 1.4 + nv * 6);
    return {
      id: q.id, nombre: q.nombre, avatar: q.avatar, bot: q.bot, esp: esp, nivel: nv, tipos: esp.tipos.length ? esp.tipos : ['NORMAL'],
      x: x, y: y, vx: 0, vy: 0, hp: hp, hpMax: hp,
      atk: 9 + Math.max(b.atk, b.spa) * 0.085 + nv * 0.6,
      red: limitar((b.def + b.spd) / 2 / 400, 0.05, 0.4),
      vel: 90 + b.spe * 0.8,
      cdBase: limitar(1.25 - b.spe * 0.004, 0.65, 1.25), cd: azar(0.3, 1.2),
      obj: null, objT: 0, dir: direccionDe(cx - x, cy - y), cuadro: azar(0, 4), mov: false,
      escudo: 0, furia: 0, gigante: 0, flash: 0, curaAcum: 0, curaT: 0,
      derrotas: 0, vivo: true, muerteT: 0, orbita: Math.random() < 0.5 ? 1 : -1
    };
  }
  function iniciarBatalla() {
    ronda++;
    var cupos = CFG.sala.cupos || 20;
    var elegidos = sala.slice(0, cupos);
    if (sala.length > cupos) sala = sala.slice(cupos).concat(elegidos); // quien no entró tiene prioridad la próxima ronda
    var participantes = elegidos.map(function (s) {
      var p = perfiles[s.id], ent = entradaActiva(p);
      return { id: p.id, nombre: p.nombre, avatar: p.avatar, especie: ent.especie, nivel: ent.nivel, bot: false };
    });
    var suma = participantes.reduce(function (a, q) { return a + q.nivel; }, 0);
    var nivelMedio = participantes.length ? Math.round(suma / participantes.length) : 1;
    var faltan = botsNecesarios(participantes.length);
    for (var i = 0; i < faltan; i++) participantes.push(crearBot(i, nivelMedio));
    batalla = {
      luchadores: participantes.map(function (q, j) { return crearLuchador(q, j, participantes.length); }),
      proyectiles: [], particulas: [], textos: [], anillos: [], derrotas: [],
      resto: CFG.batalla.segundos || 45, sub: 'cuenta', subT: 0, cuentaMostrada: 0, escala: participantes.length <= 10 ? 3 : 2,
      banner: null, duelo: false, quedanAvisado: {}, total: participantes.length, ganador: null, ultimoEnCaer: null
    };
    fase = 'batalla';
    musica(MUSICA.batalla);
  }
  function mostrarBanner(texto, color, dur) { batalla.banner = { texto: texto, color: color, dur: dur || 1.2, t: 0 }; }
  function escalaDe(e) { return batalla.escala * (e.gigante > 0 ? 1.45 : 1); }
  function alturaVisual(e) { var h = e.esp.hoja, m = medidas(h); return (m ? m.alto : h.h / h.dirs) * escalaDe(e); }
  function vivos() { return batalla.luchadores.filter(function (e) { return e.vivo; }); }

  function elegirObjetivo(e) {
    var cand = [];
    batalla.luchadores.forEach(function (o) {
      if (o !== e && o.vivo) cand.push({ o: o, d: (o.x - e.x) * (o.x - e.x) + (o.y - e.y) * (o.y - e.y) });
    });
    if (!cand.length) return null;
    cand.sort(function (a, b) { return a.d - b.d; });
    return cand[Math.random() < 0.7 || cand.length === 1 ? 0 : 1].o;
  }
  function actualizarLuchador(e, dt) {
    if (!e.vivo) { e.muerteT += dt; return; }
    e.escudo = Math.max(0, e.escudo - dt);
    e.furia = Math.max(0, e.furia - dt);
    e.gigante = Math.max(0, e.gigante - dt);
    e.flash = Math.max(0, e.flash - dt);
    e.curaT -= dt;
    if (e.curaAcum >= 1 && e.curaT <= 0) {
      textoFlotante('+' + Math.round(e.curaAcum), e.x + 34, e.y - alturaVisual(e) - 24, C.hoja, 36);
      e.curaAcum = 0;
      e.curaT = 0.45;
    }
    e.objT -= dt;
    if (!e.obj || !e.obj.vivo || e.objT <= 0) { e.obj = elegirObjetivo(e); e.objT = azar(1, 2); }
    var ax = 0, ay = 0, d = 0, dx = 0, dy = 0;
    if (e.obj) {
      dx = e.obj.x - e.x; dy = e.obj.y - e.y;
      d = Math.sqrt(dx * dx + dy * dy) || 1;
      if (d > 270) { ax += dx / d; ay += dy / d; }
      else if (d < 150) { ax -= dx / d; ay -= dy / d; }
      else { ax += (-dy / d) * 0.7 * e.orbita; ay += (dx / d) * 0.7 * e.orbita; }
    }
    var L = batalla.luchadores, sep = 30 * batalla.escala + 30;
    for (var i = 0; i < L.length; i++) {
      var o = L[i];
      if (o === e || !o.vivo) continue;
      var sx = e.x - o.x, sy = e.y - o.y, sd = sx * sx + sy * sy;
      if (sd < sep * sep && sd > 0.01) { var k = Math.sqrt(sd); ax += (sx / k) * (1 - k / sep) * 1.6; ay += (sy / k) * (1 - k / sep) * 1.6; }
    }
    var m = 70;
    if (e.x < ARENA.x0 + m) ax += (ARENA.x0 + m - e.x) / m;
    if (e.x > ARENA.x1 - m) ax -= (e.x - ARENA.x1 + m) / m;
    if (e.y < ARENA.y0 + m) ay += (ARENA.y0 + m - e.y) / m;
    if (e.y > ARENA.y1 - m) ay -= (e.y - ARENA.y1 + m) / m;
    // Empuje suave hacia el centro para que el grupo no se amontone en un borde
    ax += (CENTRO.x - e.x) / ((ARENA.x1 - ARENA.x0) / 2) * 0.3;
    ay += (CENTRO.y - e.y) / ((ARENA.y1 - ARENA.y0) / 2) * 0.4;
    var mag = Math.sqrt(ax * ax + ay * ay), vel = e.vel * (e.gigante > 0 ? 1.1 : 1), tvx = 0, tvy = 0;
    if (mag > 0.05) { var s = Math.min(1, mag) * vel / mag; tvx = ax * s; tvy = ay * s; }
    var f = Math.min(1, dt * 5);
    e.vx += (tvx - e.vx) * f;
    e.vy += (tvy - e.vy) * f;
    e.x = limitar(e.x + e.vx * dt, ARENA.x0, ARENA.x1);
    e.y = limitar(e.y + e.vy * dt, ARENA.y0, ARENA.y1);
    var rapidez = Math.sqrt(e.vx * e.vx + e.vy * e.vy);
    e.mov = rapidez > 25;
    if (e.mov) e.dir = direccionDe(e.vx, e.vy);
    else if (e.obj) e.dir = direccionDe(dx, dy);
    e.cuadro += dt * (e.mov ? 6 + rapidez / 45 : 6);
    e.cd -= dt;
    if (e.obj && e.cd <= 0 && d < 560) {
      disparar(e, e.obj);
      e.cd = e.cdBase * azar(0.9, 1.1);
    }
  }
  function disparar(e, obj) {
    var tipo = e.tipos[Math.random() < 0.75 ? 0 : e.tipos.length - 1];
    batalla.proyectiles.push({ x: e.x, y: e.y - alturaVisual(e) * 0.5, de: e, a: obj, tipo: tipo, color: colorTipo(tipo), vel: 880, vida: 1.4, estela: [] });
  }
  function actualizarProyectiles(dt) {
    var P = batalla.proyectiles;
    for (var i = P.length - 1; i >= 0; i--) {
      var p = P[i];
      p.vida -= dt;
      if (!p.a.vivo || p.vida <= 0) { P.splice(i, 1); continue; }
      var tx = p.a.x, ty = p.a.y - alturaVisual(p.a) * 0.45;
      var dx = tx - p.x, dy = ty - p.y, d = Math.sqrt(dx * dx + dy * dy) || 1, paso = p.vel * dt;
      p.estela.push(p.x, p.y);
      if (p.estela.length > 10) p.estela.splice(0, 2);
      if (d <= paso + 18) { golpear(p.de, p.a, p.tipo); P.splice(i, 1); continue; }
      p.x += dx / d * paso;
      p.y += dy / d * paso;
    }
  }
  function golpear(src, dst, tipo) {
    if (!dst.vivo) return;
    var m = multiplicador(tipo, dst.tipos);
    var dano = src.atk * m * azar(0.85, 1.15) * (1 - dst.red);
    if (src.furia > 0) dano *= 1.6;
    if (src.gigante > 0) dano *= 1.25;
    aplicarDano(src, dst, dano, m >= 2 ? C.sol : m < 1 ? C.musgo : C.nube, m >= 2 ? 46 : 38);
    chispas(dst.x, dst.y - alturaVisual(dst) * 0.45, colorTipo(tipo), 6, false);
    sonidoGolpe(m);
  }
  function aplicarDano(src, dst, dano, color, tam) {
    if (dst.escudo > 0) dano *= 0.2;
    dano = Math.max(1, Math.round(dano));
    dst.hp -= dano;
    dst.flash = 0.12;
    textoFlotante('-' + dano, dst.x + (Math.random() < 0.5 ? -1 : 1) * azar(40, 70), dst.y - alturaVisual(dst) * 0.55, color, tam);
    if (dst.hp <= 0) derrotar(src, dst);
  }
  function derrotar(src, dst) {
    dst.hp = 0;
    dst.vivo = false;
    dst.muerteT = 0;
    batalla.ultimoEnCaer = dst;
    if (src && src !== dst) src.derrotas++;
    batalla.derrotas.unshift({ texto: (src ? src.nombre : '¿?') + ' derrotó a ' + dst.nombre, t: 0 });
    if (batalla.derrotas.length > 4) batalla.derrotas.pop();
    chispas(dst.x, dst.y - 30, colorTipo(dst.tipos[0]), 26, true);
    sonido(SFX.derrota, 0.55);
  }
  function curar(e, cant, desdeLike) {
    if (!e.vivo) return;
    var antes = e.hp;
    e.hp = Math.min(e.hpMax, e.hp + cant);
    e.curaAcum += e.hp - antes;
    if (desdeLike && batalla.particulas.length < 220) {
      for (var i = 0; i < 2; i++) batalla.particulas.push({ x: e.x + azar(-30, 30), y: e.y - alturaVisual(e) * 0.6, vx: azar(-30, 30), vy: azar(-170, -110), g: -40, vida: 1.1, max: 1.1, c: C.baya, tam: 18, forma: 'corazon' });
    }
  }
  function aplicarPoder(e, poder, diamantes) {
    var pd = CFG.poderes, y = e.y - alturaVisual(e) - 60;
    if (poder === 'escudo') {
      e.escudo = Math.min(20, e.escudo + (pd.escudo.segundos || 5));
      curar(e, e.hpMax * 0.08, false);
      textoFlotante('Escudo', e.x, y, C.cielo, 40);
    } else if (poder === 'ataque') {
      e.furia = Math.min(25, e.furia + (pd.ataque.segundos || 8));
      textoFlotante('Ataque ×1,6', e.x, y, C.sol, 40);
    } else {
      var dano = limitar(25 + diamantes * 0.35, 25, 400);
      e.gigante = Math.min(20, e.gigante + 6);
      batalla.anillos.push({ x: e.x, y: e.y - 30, r: 0, max: 320, t: 0, color: C.sol });
      batalla.luchadores.forEach(function (o) {
        if (o === e || !o.vivo) return;
        var dx = o.x - e.x, dy = o.y - e.y;
        if (dx * dx + dy * dy < 320 * 320) aplicarDano(e, o, dano * (1 - o.red * 0.5), C.sol, 48);
      });
      mostrarBanner('¡Potencia de ' + e.nombre + '!', C.sol, 1.3);
    }
    sonido(SFX.poder, 0.6);
  }
  function revisarFinal() {
    var b = batalla, v = vivos();
    if (v.length === 2 && !b.duelo && b.total > 2) {
      b.duelo = true;
      mostrarBanner('Duelo final', C.sol, 1.6);
    } else if ((v.length === 3 || v.length === 5) && b.total > v.length + 1 && !b.quedanAvisado[v.length]) {
      b.quedanAvisado[v.length] = true;
      mostrarBanner('Quedan ' + v.length, C.nube, 1.3);
    }
    if (v.length <= 1 || b.resto <= 0) {
      var ganador = v.length ? v.slice().sort(function (a, c) { return c.hp / c.hpMax - a.hp / a.hpMax; })[0] : b.ultimoEnCaer;
      b.ganador = ganador || b.luchadores[0];
      b.sub = 'fin';
      b.subT = 0;
      b.proyectiles = [];
      if (b.resto <= 0 && v.length > 1) mostrarBanner('¡Tiempo!', C.baya, 1.6);
      else mostrarBanner('¡Ganó ' + b.ganador.nombre + '!', C.sol, 2);
      musica(null);
    }
  }
  function actualizarBatalla(dt) {
    var b = batalla;
    b.subT += dt;
    if (b.sub === 'cuenta') {
      var n = 3 - Math.floor(b.subT);
      if (n >= 1 && b.cuentaMostrada !== n) { b.cuentaMostrada = n; mostrarBanner(String(n), C.nube, 0.9); sonido(SFX.tic, 0.4); }
      if (b.subT >= 3) { b.sub = 'lucha'; b.subT = 0; mostrarBanner('¡A luchar!', C.sol, 1.1); }
      b.luchadores.forEach(function (e) { e.cuadro += dt * 6; });
    } else if (b.sub === 'lucha') {
      b.resto -= dt;
      b.luchadores.forEach(function (e) { actualizarLuchador(e, dt); });
      actualizarProyectiles(dt);
      revisarFinal();
    } else {
      b.luchadores.forEach(function (e) { if (e.vivo) { e.cuadro += dt * 6; e.mov = false; } else e.muerteT += dt; });
      if (b.subT > 2.4) irACampeon();
    }
    actualizarEfectos(dt);
  }

  // ---------------------------------------------------------------------------
  // Efectos visuales
  // ---------------------------------------------------------------------------
  function textoFlotante(texto, x, y, color, tam) {
    if (batalla.textos.length > 60) batalla.textos.shift();
    batalla.textos.push({ texto: texto, x: x, y: y, vy: -95, vida: 1, c: color, tam: tam || 38 });
  }
  function chispas(x, y, color, n, grandes) {
    for (var i = 0; i < n && batalla.particulas.length < 260; i++) {
      var a = azar(0, TAU), v = azar(grandes ? 160 : 90, grandes ? 420 : 220);
      batalla.particulas.push({ x: x, y: y, vx: Math.cos(a) * v, vy: Math.sin(a) * v - (grandes ? 160 : 60), g: 900, vida: grandes ? 0.9 : 0.4, max: grandes ? 0.9 : 0.4, c: color, tam: grandes ? azar(8, 14) : azar(5, 8), forma: 'cuadro' });
    }
  }
  function actualizarEfectos(dt) {
    var b = batalla;
    b.particulas = b.particulas.filter(function (p) {
      p.vida -= dt; p.vy += p.g * dt; p.x += p.vx * dt; p.y += p.vy * dt;
      return p.vida > 0;
    });
    b.textos = b.textos.filter(function (x) { x.vida -= dt; x.y += x.vy * dt; return x.vida > 0; });
    b.anillos = b.anillos.filter(function (a) { a.t += dt; a.r = a.max * Math.min(1, a.t / 0.4); return a.t < 0.7; });
    b.derrotas.forEach(function (d) { d.t += dt; });
    b.derrotas = b.derrotas.filter(function (d) { return d.t < 6; });
    if (b.banner) { b.banner.t += dt; if (b.banner.t >= b.banner.dur) b.banner = null; }
  }

  // ---------------------------------------------------------------------------
  // Fase: campeón y experiencia
  // ---------------------------------------------------------------------------
  function expPara(nivel) { return 30 + nivel * 15; }
  function expEntrenadorPara(nivel) { return 50 + nivel * 25; }
  function repartirExp(ganador) {
    var cambios = [], resumen = null, ex = CFG.exp || {};
    batalla.luchadores.forEach(function (e) {
      if (e.bot) return;
      var p = perfiles[e.id];
      if (!p) return;
      var ent = entradaActiva(p);
      var ganado = (ex.participar || 10) + e.derrotas * (ex.porDerrota || 15) + (e === ganador ? ex.ganar || 60 : 0);
      var subio = 0;
      ent.exp += ganado;
      while (ent.exp >= expPara(ent.nivel)) { ent.exp -= expPara(ent.nivel); ent.nivel++; subio++; }
      p.expEntrenador = (p.expEntrenador || 0) + ganado;
      p.nivelEntrenador = p.nivelEntrenador || 1;
      while (p.expEntrenador >= expEntrenadorPara(p.nivelEntrenador)) { p.expEntrenador -= expEntrenadorPara(p.nivelEntrenador); p.nivelEntrenador++; }
      p.batallas = (p.batallas || 0) + 1;
      if (e === ganador) p.victorias = (p.victorias || 0) + 1;
      cambios.push(p);
      if (e === ganador) resumen = { perfil: p, entrada: ent, ganado: ganado, subio: subio };
    });
    if (cambios.length) guardar(cambios);
    return resumen;
  }
  function crearConfeti() {
    var lista = [], colores = [C.sol, C.cielo, C.baya, C.hoja, C.nube];
    for (var i = 0; i < 150; i++) {
      lista.push({ x: azar(0, W), y: azar(-H * 0.9, -20), vx: azar(-60, 60), vy: azar(240, 460), r: azar(0, TAU), vr: azar(-6, 6), w: azar(14, 26), h: azar(8, 14), c: elegir(colores) });
    }
    return lista;
  }
  function irACampeon() {
    var g = batalla.ganador;
    campeon = { e: g, resumen: repartirExp(g), t: 0, confeti: crearConfeti() };
    fase = 'campeon';
    sonido(SFX.victoria, 0.7);
    if (campeon.resumen && campeon.resumen.subio) sonido(SFX.nivel, 0.5);
  }
  function actualizarCampeon(dt) {
    campeon.t += dt;
    campeon.confeti.forEach(function (c) {
      c.x += c.vx * dt; c.y += c.vy * dt; c.r += c.vr * dt;
      if (c.y > H + 30 && campeon.t < 5) { c.y = -20; c.x = azar(0, W); }
    });
    if (campeon.t > 8) { batalla = null; campeon = null; irASala(); }
  }

  // ---------------------------------------------------------------------------
  // Dibujo: fondos
  // ---------------------------------------------------------------------------
  function urlFondo() {
    return '/repo/Graphics/UI/Survivor Game/Background/' + (CFG.batalla.fondo || 'Field') + '.png';
  }
  function prepararFondo(nombre) {
    if (fondos[nombre]) return fondos[nombre];
    var im = imagen(urlFondo());
    if (!cargada(im)) return null;
    var c = document.createElement('canvas');
    c.width = W; c.height = H;
    var g = c.getContext('2d');
    g.imageSmoothingEnabled = false;
    var tw = im.width * 2, th = im.height * 2;
    for (var y = 0, fila = 0; y < H; y += th, fila++) {
      for (var x = 0, col = 0; x < W; x += tw, col++) {
        g.save();
        // Los mosaicos se reflejan en espejo para que la repetición no se note
        var espejoX = col % 2 === 1, espejoY = fila % 2 === 1;
        g.translate(x + (espejoX ? tw : 0), y + (espejoY ? th : 0));
        g.scale(espejoX ? -1 : 1, espejoY ? -1 : 1);
        g.drawImage(im, 0, 0, tw, th);
        g.restore();
      }
    }
    if (nombre === 'sala') {
      g.fillStyle = 'rgba(5,20,11,0.66)';
      g.fillRect(0, 0, W, H);
    }
    var v = g.createRadialGradient(W / 2, H / 2, H * 0.3, W / 2, H / 2, H * 0.75);
    v.addColorStop(0, 'rgba(0,0,0,0)');
    v.addColorStop(1, 'rgba(0,0,0,0.45)');
    g.fillStyle = v;
    g.fillRect(0, 0, W, H);
    fondos[nombre] = c;
    return c;
  }
  function fondo(nombre) {
    var f = prepararFondo(nombre);
    if (f) ctx.drawImage(f, 0, 0);
    else { ctx.fillStyle = C.bosque; ctx.fillRect(0, 0, W, H); }
  }
  function rayos(cx, cy, color, edad, alcance) {
    ctx.save();
    ctx.translate(cx, cy);
    ctx.rotate(edad * 0.25);
    ctx.fillStyle = rgba(color, 0.08);
    for (var i = 0; i < 14; i++) {
      ctx.rotate(TAU / 14);
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.lineTo(alcance || 1300, -90);
      ctx.lineTo(alcance || 1300, 90);
      ctx.closePath();
      ctx.fill();
    }
    ctx.restore();
  }

  // ---------------------------------------------------------------------------
  // Dibujo: sala
  // ---------------------------------------------------------------------------
  function dibujarSala() {
    fondo('sala');
    cabeceraSala();
    instrucciones();
    rejilla();
    panelCaptura();
    dibujarAvisos(60, 1860, 3);
    if (capturas.length) dibujarCaptura(capturas[0]);
  }
  function cabeceraSala() {
    escribir(CFG.titulo || 'Vortex Rival', 58, 268, { f: '104px ' + FT, borde: 18, max: 740 });
    var linea, color = C.hoja, faltan = faltanParaEmpezar();
    if (cuentaSala !== null) linea = 'La batalla empieza en ' + Math.ceil(cuentaSala) + ' s';
    else if (!sala.length) linea = 'Toca la pantalla para entrar';
    else { linea = faltan === 1 ? 'Falta 1 jugador para empezar' : 'Faltan ' + faltan + ' jugadores para empezar'; color = C.sol; }
    escribir(linea, 62, 336, { f: '900 40px ' + FX, borde: 9, c: color, max: 740 });

    var cx = 928, cy = 238, r = 96;
    circulo(cx, cy, r + 10, 'rgba(7,26,15,0.88)');
    ctx.lineWidth = 12;
    ctx.strokeStyle = C.bosque2;
    ctx.beginPath(); ctx.arc(cx, cy, r - 6, 0, TAU); ctx.stroke();
    if (cuentaSala !== null) {
      var k = cuentaSala / (CFG.sala.segundos || 40);
      ctx.strokeStyle = cuentaSala <= 5 ? C.baya : C.sol;
      ctx.lineCap = 'round';
      ctx.beginPath(); ctx.arc(cx, cy, r - 6, -Math.PI / 2, -Math.PI / 2 + TAU * limitar(k, 0, 1)); ctx.stroke();
      ctx.lineCap = 'butt';
      escribir(Math.ceil(cuentaSala), cx, cy + 34, { f: '96px ' + FT, al: 'center', c: cuentaSala <= 5 ? C.baya : C.sol });
    } else {
      escribir(sala.length + '/' + (CFG.sala.cupos || 20), cx, cy + 14, { f: '56px ' + FT, al: 'center' });
      escribir('jugadores', cx, cy + 52, { f: '800 26px ' + FX, al: 'center', c: C.musgo });
    }
  }
  function instrucciones() {
    var y = 380, h = 92, ancho;
    panel(48, y, 430, h, 46, 'rgba(7,26,15,0.88)', 'rgba(255,77,109,0.55)');
    var latido = 1 + Math.sin(t * 7) * 0.08;
    ctx.save(); ctx.translate(104, y + 50); ctx.scale(latido, latido); corazon(0, 0, 30, C.baya); ctx.restore();
    ancho = ctx.measureText(escribir((CFG.sala.likesParaEntrar || 25) + ' taps', 146, y + 58, { f: '46px ' + FT })).width;
    escribir('para entrar', 146 + ancho + 14, y + 56, { f: '900 30px ' + FX, c: C.musgo, max: 478 - 146 - ancho - 40 });
    panel(494, y, 538, h, 46, 'rgba(7,26,15,0.88)', 'rgba(76,195,255,0.55)');
    ancho = ctx.measureText(escribir((CFG.comandos && CFG.comandos.mochila) || '!mochila', 530, y + 58, { f: '46px ' + FT, c: C.cielo })).width;
    escribir('cambia tu Pokémon', 530 + ancho + 16, y + 56, { f: '900 30px ' + FX, c: C.musgo, max: 1032 - 530 - ancho - 46 });
    if (avisoTap && t - avisoTap.t0 < 2.5) {
      escribir(avisoTap.nombre + ' lleva ' + avisoTap.taps + ' de ' + avisoTap.meta + ' taps', 62, 514, { f: '900 30px ' + FX, c: C.baya, borde: 7, max: 960 });
    }
  }
  function rejilla() {
    var inicio = pagina * CUPOS_PAGINA;
    for (var i = 0; i < CUPOS_PAGINA; i++) {
      var x = GX + (i % COLS) * (GW + GAP), y = GY + Math.floor(i / COLS) * (GH + GAP);
      var s = sala[inicio + i];
      if (s && perfiles[s.id]) tarjeta(perfiles[s.id], x, y, inicio + i);
      else cupoLibre(x, y);
    }
    var paginas = Math.ceil(sala.length / CUPOS_PAGINA);
    if (paginas > 1) escribir('Página ' + (pagina + 1) + ' de ' + paginas, 1032, GY - 14, { f: '900 26px ' + FX, al: 'right', c: C.musgo, borde: 6 });
  }
  function tarjeta(p, x, y, n) {
    var ent = entradaActiva(p), esp = POR_ID[ent.especie], rz = RAREZA[ent.rareza] || RAREZA.normal;
    panel(x, y, GW, GH, 22, 'rgba(10,33,19,0.9)', rgba(rz.color, 0.45));
    ctx.save();
    rect(x, y, GW, GH, 22);
    ctx.clip();
    ctx.fillStyle = rz.color;
    ctx.fillRect(x, y + GH - 8, GW, 8);
    ctx.restore();
    if (esp) {
      var esc = escalaQueCabe(esp, 124, 90, 3);
      dibujarEspecie(esp, 0, t * 6 + n * 0.7, x + GW - 68, y + 104, esc, !!esp.reposo);
    }
    dibujarAvatar(p.nombre, p.avatar, x + 46, y + 48, 30, 'rgba(247,251,244,0.9)');
    panel(x + 16, y + 74, 62, 30, 15, C.sol);
    escribir('Nv ' + ent.nivel, x + 47, y + 97, { f: '900 22px ' + FX, al: 'center', c: C.tinta, max: 58 });
    escribir(p.nombre, x + 16, y + 134, { f: '900 30px ' + FX, max: GW - 30 });
    escribir(esp ? esp.nombre : ent.especie, x + 16, y + 160, { f: '800 22px ' + FX, c: C.musgo, max: GW - 30 });
  }
  function cupoLibre(x, y) {
    ctx.save();
    ctx.setLineDash([10, 10]);
    ctx.lineWidth = 3;
    ctx.strokeStyle = 'rgba(169,196,176,0.32)';
    rect(x + 2, y + 2, GW - 4, GH - 4, 22);
    ctx.stroke();
    ctx.restore();
    escribir('Libre', x + GW / 2, y + GH / 2 + 10, { f: '800 28px ' + FX, al: 'center', c: 'rgba(169,196,176,0.5)' });
  }
  function panelCaptura() {
    var x = 48, y = 1462, w = 984, h = 166;
    panel(x, y, w, h, 30, 'rgba(7,26,15,0.88)', 'rgba(255,201,60,0.35)');
    escribir('Regala y captura un Pokémon', x + 32, y + 54, { f: '900 36px ' + FX });
    var claves = ['normal', 'rara', 'especial'], cw = (w - 64 - 32) / 3;
    claves.forEach(function (k, i) {
      var cx = x + 32 + i * (cw + 16), cy = y + 78, rz = RAREZA[k], c = CFG.captura[k];
      panel(cx, cy, cw, 66, 20, 'rgba(255,255,255,0.06)');
      circulo(cx + 30, cy + 33, 12, rz.color);
      escribir(rz.nombre, cx + 52, cy + 31, { f: '30px ' + FT, c: rz.color });
      escribir(c.ejemplo + ' o más', cx + 52, cy + 57, { f: '800 22px ' + FX, c: C.musgo, max: cw - 62 });
    });
  }
  function dibujarAvisos(x, yBase, cuantos) {
    var visibles = avisos.filter(function (a) { return t - a.t0 < 7; }).slice(-cuantos);
    visibles.forEach(function (a, i) {
      var edad = t - a.t0;
      ctx.globalAlpha = limitar(Math.min(edad * 5, (7 - edad) * 1.5), 0, 1);
      escribir(a.texto, x, yBase - (visibles.length - 1 - i) * 54, { f: '900 34px ' + FX, c: a.color, borde: 8, max: 960 });
    });
    ctx.globalAlpha = 1;
  }

  // Animación de captura: un orbe cae, tiembla y se abre con el Pokémon nuevo
  function orbe(x, y, r, color, giro) {
    ctx.save();
    ctx.translate(x, y);
    var halo = ctx.createRadialGradient(0, 0, r * 0.3, 0, 0, r * 2.2);
    halo.addColorStop(0, rgba(color, 0.55));
    halo.addColorStop(1, rgba(color, 0));
    ctx.fillStyle = halo;
    ctx.beginPath(); ctx.arc(0, 0, r * 2.2, 0, TAU); ctx.fill();
    ctx.rotate(giro);
    var cuerpo = ctx.createRadialGradient(-r * 0.35, -r * 0.4, r * 0.1, 0, 0, r);
    cuerpo.addColorStop(0, '#FFFFFF');
    cuerpo.addColorStop(0.35, color);
    cuerpo.addColorStop(1, oscurecer(color, 0.45));
    ctx.fillStyle = cuerpo;
    ctx.beginPath(); ctx.arc(0, 0, r, 0, TAU); ctx.fill();
    ctx.strokeStyle = 'rgba(255,255,255,0.45)';
    ctx.lineWidth = 4;
    for (var i = 0; i < 6; i++) {
      var a = i * TAU / 6;
      ctx.beginPath(); ctx.moveTo(Math.cos(a) * r * 0.25, Math.sin(a) * r * 0.25); ctx.lineTo(Math.cos(a) * r * 0.92, Math.sin(a) * r * 0.92); ctx.stroke();
    }
    ctx.beginPath(); ctx.arc(0, 0, r * 0.25, 0, TAU); ctx.fillStyle = 'rgba(255,255,255,0.85)'; ctx.fill();
    ctx.restore();
  }
  function dibujarCaptura(c) {
    var k = c.t, rz = RAREZA[c.rareza], cx = 540, cy = 930;
    var entrada = Math.min(1, k / 0.25), salida = k > 3.35 ? Math.max(0, 1 - (k - 3.35) / 0.35) : 1;
    ctx.globalAlpha = entrada * salida;
    ctx.fillStyle = 'rgba(4,14,8,0.8)';
    ctx.fillRect(0, 0, W, H);
    if (k > 1.7) rayos(cx, cy - 120, rz.color, k - 1.7, 1300);
    escribir(rz.titulo, 540, 560, { f: '100px ' + FT, al: 'center', c: rz.color, borde: 18, max: 1000 });
    if (k < 1.7) {
      var y = k < 0.6 ? -150 + (cy - 60 + 150) * rebote(k / 0.6) : cy - 60;
      var giro = k < 0.6 ? 0 : Math.sin((k - 0.6) * TAU * 2.2) * 0.45 * (1 - (k - 0.6) / 1.1);
      if (k > 0.6 && !c.sonoAgitar) { c.sonoAgitar = true; sonido(SFX.agitar, 0.6); }
      orbe(cx, y, 90, rz.color, giro);
    } else {
      if (!c.sonoCaptura) { c.sonoCaptura = true; sonido(SFX.captura, 0.65); if (c.esp.grito) sonido(c.esp.grito, 0.55); }
      var pop = Math.min(1, (k - 1.7) / 0.35), esc = 5 * (0.55 + 0.45 * rebote(pop));
      sombra(cx, cy + 4, 110 * pop, 26 * pop);
      dibujarEspecie(c.esp, 0, (k - 1.7) * 6, cx, cy + 10, esc, !!c.esp.reposo);
      if (k < 2.0) { ctx.fillStyle = 'rgba(255,255,255,' + ((2.0 - k) / 0.3 * 0.8) + ')'; ctx.fillRect(0, 0, W, H); }
      escribir(c.esp.nombre, 540, cy + 130, { f: '88px ' + FT, al: 'center', borde: 16, max: 1000 });
      chipsTipos(c.esp.tipos, 540, cy + 168, 32);
    }
    panel(170, 1280, 740, 120, 60, 'rgba(7,26,15,0.92)', rgba(rz.color, 0.6));
    dibujarAvatar(c.perfil.nombre, c.perfil.avatar, 234, 1340, 44, rz.color);
    escribir('Capturado por', 300, 1326, { f: '800 26px ' + FX, c: C.musgo });
    escribir(c.perfil.nombre, 300, 1370, { f: '900 40px ' + FX, max: 580 });
    ctx.globalAlpha = 1;
  }

  // ---------------------------------------------------------------------------
  // Dibujo: batalla
  // ---------------------------------------------------------------------------
  function dibujarBatalla() {
    var b = batalla;
    fondo('campo');
    b.anillos.forEach(function (a) {
      ctx.lineWidth = 14 * (1 - a.t / 0.7) + 2;
      ctx.strokeStyle = rgba(a.color, Math.max(0, 0.9 - a.t));
      ctx.beginPath(); ctx.arc(a.x, a.y, a.r, 0, TAU); ctx.stroke();
    });
    var orden = b.luchadores.slice().sort(function (a, c) { return a.y - c.y; });
    orden.forEach(dibujarLuchador);
    b.proyectiles.forEach(dibujarProyectil);
    b.particulas.forEach(function (p) {
      ctx.globalAlpha = limitar(p.vida / p.max, 0, 1);
      if (p.forma === 'corazon') corazon(p.x, p.y, p.tam, p.c);
      else { ctx.fillStyle = p.c; ctx.fillRect(Math.round(p.x - p.tam / 2), Math.round(p.y - p.tam / 2), Math.round(p.tam), Math.round(p.tam)); }
    });
    ctx.globalAlpha = 1;
    orden.forEach(etiqueta);
    b.textos.forEach(function (x) {
      ctx.globalAlpha = limitar(x.vida * 2, 0, 1);
      escribir(x.texto, x.x, x.y, { f: x.tam + 'px ' + FT, al: 'center', c: x.c, borde: 9 });
    });
    ctx.globalAlpha = 1;
    hudBatalla();
    leyendaBatalla();
    dibujarAvisos(60, 1874, 2);
    dibujarBanner();
  }
  function dibujarLuchador(e) {
    if (!e.vivo && e.muerteT > 0.6) return;
    var reposo = !e.mov && !!e.esp.reposo, esc = escalaDe(e), c = tamCuadro(e.esp, reposo);
    ctx.globalAlpha = e.vivo ? 1 : 1 - e.muerteT / 0.6;
    sombra(e.x, e.y, c.w * esc * 0.36, 7 * esc);
    if (e.furia > 0) {
      ctx.lineWidth = 6;
      ctx.strokeStyle = rgba(C.sol, 0.55 + Math.sin(t * 12) * 0.25);
      ctx.beginPath(); ctx.ellipse(e.x, e.y, c.w * esc * 0.5, 12 * esc, 0, 0, TAU); ctx.stroke();
    }
    if (e.flash > 0) ctx.filter = 'brightness(2.6)';
    dibujarEspecie(e.esp, e.dir, e.cuadro, e.x, e.y + 6, esc, reposo);
    if (e.flash > 0) ctx.filter = 'none';
    if (e.escudo > 0) {
      var alto = alturaVisual(e), r = Math.max(c.w * esc, alto) * 0.62;
      ctx.fillStyle = rgba(C.cielo, 0.16);
      ctx.strokeStyle = rgba(C.cielo, 0.75 + Math.sin(t * 9) * 0.2);
      ctx.lineWidth = 5;
      ctx.beginPath(); ctx.arc(e.x, e.y - alto * 0.5, r, 0, TAU); ctx.fill(); ctx.stroke();
    }
    ctx.globalAlpha = 1;
  }
  function dibujarProyectil(p) {
    for (var i = 0; i < p.estela.length; i += 2) {
      ctx.globalAlpha = (i / p.estela.length) * 0.5;
      circulo(p.estela[i], p.estela[i + 1], 6 + i, p.color);
    }
    ctx.globalAlpha = 1;
    circulo(p.x, p.y, 15, rgba(p.color, 0.45));
    circulo(p.x, p.y, 10, p.color);
    circulo(p.x, p.y, 4.5, '#FFFFFF');
  }
  function etiqueta(e) {
    if (!e.vivo) return;
    var w = 112, h = 12, x = e.x - w / 2, y = e.y - alturaVisual(e) - 2;
    panel(x - 3, y - 3, w + 6, h + 6, 9, 'rgba(7,26,15,0.78)');
    var pct = limitar(e.hp / e.hpMax, 0, 1);
    panel(x, y, Math.max(h, w * pct), h, 6, pct > 0.5 ? C.hoja : pct > 0.25 ? C.sol : C.baya);
    escribir(e.nombre, e.x, y - 10, { f: '900 26px ' + FX, al: 'center', borde: 7, c: e.bot ? C.musgo : C.nube, max: 220 });
  }
  function hudBatalla() {
    var b = batalla, resto = Math.max(0, Math.ceil(b.resto));
    panel(48, 168, 214, 100, 50, 'rgba(7,26,15,0.88)');
    escribir(resto + ' s', 155, 240, { f: '66px ' + FT, al: 'center', c: resto <= 10 ? C.baya : C.sol });
    escribir('Quedan ' + vivos().length, 540, 242, { f: '76px ' + FT, al: 'center', borde: 16 });
    panel(818, 168, 214, 100, 50, 'rgba(7,26,15,0.88)');
    escribir('Ronda ' + ronda, 925, 232, { f: '900 38px ' + FX, al: 'center', max: 190 });
    b.derrotas.forEach(function (d, i) {
      ctx.globalAlpha = limitar((6 - d.t) * 1.5, 0, 1);
      escribir(d.texto, 1032, 326 + i * 44, { f: '900 30px ' + FX, al: 'right', borde: 7, c: C.nube, max: 760 });
    });
    ctx.globalAlpha = 1;
  }
  function leyendaBatalla() {
    var x = 48, y = 1536, w = 984, h = 222, pd = CFG.poderes;
    panel(x, y, w, h, 30, 'rgba(7,26,15,0.88)', 'rgba(168,224,99,0.3)');
    escribir('Ayuda a tu Pokémon', x + 32, y + 52, { f: '900 36px ' + FX });
    var items = [
      { c: C.baya, a: 'Likes', b: 'curan', corazon: true },
      { c: C.cielo, a: pd.escudo.ejemplo, b: 'escudo' },
      { c: C.sol, a: pd.ataque.ejemplo, b: 'ataque ×1,6' },
      { c: C.baya, a: pd.potencia.ejemplo + ' o más', b: 'potencia' }
    ];
    var cw = (w - 64 - 16) / 2;
    items.forEach(function (it, i) {
      var cx = x + 32 + (i % 2) * (cw + 16), cy = y + 72 + Math.floor(i / 2) * 70;
      panel(cx, cy, cw, 58, 20, 'rgba(255,255,255,0.06)');
      if (it.corazon) corazon(cx + 30, cy + 33, 15, it.c); else circulo(cx + 30, cy + 29, 11, it.c);
      ctx.font = '900 28px ' + FX;
      var a = recortar(it.a, cw - 200);
      escribir(a, cx + 52, cy + 39, { f: '900 28px ' + FX });
      escribir(it.b, cx + 52 + ctx.measureText(a).width + 12, cy + 39, { f: '800 26px ' + FX, c: it.c });
    });
  }
  function dibujarBanner() {
    var bn = batalla.banner;
    if (!bn) return;
    var k = bn.t / bn.dur, esc = k < 0.15 ? 1.4 - 0.4 * (k / 0.15) : 1, alfa = k > 0.75 ? 1 - (k - 0.75) / 0.25 : 1;
    ctx.save();
    ctx.globalAlpha = limitar(alfa, 0, 1);
    ctx.translate(540, 900);
    ctx.scale(esc, esc);
    escribir(bn.texto, 0, 0, { f: '140px ' + FT, al: 'center', base: 'middle', c: bn.color, borde: 24, max: 980 });
    ctx.restore();
  }

  // ---------------------------------------------------------------------------
  // Dibujo: campeón
  // ---------------------------------------------------------------------------
  function dibujarCampeon() {
    var c = campeon, e = c.e, k = c.t;
    fondo('campo');
    ctx.fillStyle = 'rgba(4,14,8,0.62)';
    ctx.fillRect(0, 0, W, H);
    rayos(540, 760, C.sol, k, 1400);
    escribir('Campeón de la ronda ' + ronda, 540, 440, { f: '76px ' + FT, al: 'center', c: C.sol, borde: 16, max: 1000 });
    var pop = Math.min(1, k / 0.5);
    sombra(540, 905, 130 * pop, 30 * pop);
    dibujarEspecie(e.esp, 0, k * 6, 540, 910, 5.5 * (0.6 + 0.4 * rebote(pop)), !!e.esp.reposo);
    tarjetaCampeon(c, Math.min(1, Math.max(0, (k - 0.4) / 0.5)));
    c.confeti.forEach(function (p) {
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.r);
      ctx.fillStyle = p.c;
      ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
      ctx.restore();
    });
  }
  function tarjetaCampeon(c, aparicion) {
    var e = c.e, x = 90, y = 1010 + (1 - aparicion) * 60, w = 900, h = 400, res = c.resumen;
    ctx.globalAlpha = aparicion;
    panel(x, y, w, h, 40, 'rgba(7,26,15,0.94)', C.sol);
    dibujarAvatar(e.nombre, e.avatar, x + 124, y + 126, 84, C.sol);
    escribir(e.nombre, x + 232, y + 116, { f: '72px ' + FT, max: w - 262 });
    var nivel = res ? res.entrada.nivel : e.nivel;
    escribir(e.esp.nombre + ', nivel ' + nivel, x + 234, y + 166, { f: '900 36px ' + FX, c: C.musgo, max: w - 262 });
    escribir(e.derrotas === 1 ? 'Derrotó a 1 rival' : 'Derrotó a ' + e.derrotas + ' rivales', x + 234, y + 212, { f: '800 30px ' + FX, c: C.nube, max: w - 262 });
    if (res) {
      var bx = x + 60, bw = w - 120, by = y + 300;
      var meta = res.entrada.exp / expPara(res.entrada.nivel);
      var llenado = meta * Math.min(1, Math.max(0, (c.t - 0.9) / 1.2));
      escribir('+' + res.ganado + ' EXP', bx + bw, by - 22, { f: '52px ' + FT, al: 'right', c: C.sol });
      escribir(res.subio ? '¡Subió a nivel ' + res.entrada.nivel + '!' : 'Entrenador nivel ' + res.perfil.nivelEntrenador, bx, by - 24, { f: '900 32px ' + FX, c: res.subio ? C.hoja : C.musgo, max: bw - 260 });
      panel(bx, by, bw, 30, 15, 'rgba(255,255,255,0.1)');
      if (llenado > 0.01) panel(bx, by, Math.max(30, bw * llenado), 30, 15, C.sol);
      escribir(res.perfil.victorias === 1 ? '1 victoria en total' : res.perfil.victorias + ' victorias en total', bx, by + 74, { f: '800 28px ' + FX, c: C.musgo });
    } else {
      escribir('Los bots no suben de nivel. ¡Entra y gánale!', x + 60, y + 320, { f: '900 32px ' + FX, c: C.musgo, max: w - 120 });
    }
    ctx.globalAlpha = 1;
  }

  // ---------------------------------------------------------------------------
  // Indicadores para quien transmite (arriba a la izquierda, bajo la barra de TikTok)
  // ---------------------------------------------------------------------------
  function indicadores() {
    var texto = null, color = C.sol;
    if (!conectado) { texto = 'Sin conexión con el servidor'; color = C.baya; }
    else if (MODO === 'simulacion') texto = 'Simulación';
    else if (TIKTOK && TIKTOK.estado !== 'conectado') { texto = TIKTOK.detalle || 'TikTok sin conectar'; color = C.baya; }
    if (DEBUG) texto = (texto ? texto + ' · ' : '') + 'fase ' + fase + ' · sala ' + sala.length + (PRINCIPAL ? ' · guarda' : ' · solo mira');
    if (!texto) return;
    ctx.font = '800 24px ' + FX;
    var ancho = Math.min(1000, ctx.measureText(texto).width + 36);
    panel(24, 24, ancho, 44, 22, 'rgba(7,26,15,0.85)', rgba(color, 0.7));
    escribir(texto, 42, 54, { f: '800 24px ' + FX, c: color, max: ancho - 36 });
  }
  function pantallaCarga() {
    ctx.fillStyle = C.bosque;
    ctx.fillRect(0, 0, W, H);
    escribir('Conectando con el servidor…', 540, 960, { f: '900 44px ' + FX, al: 'center', c: C.musgo });
  }

  // ---------------------------------------------------------------------------
  // Sonido (música y efectos del repo)
  // ---------------------------------------------------------------------------
  var musicaActual = null, audioBloqueado = false, ultimoGolpe = -1;
  function sonidoActivo() { return !!(CFG && CFG.sonido && CFG.sonido.activado && typeof Audio !== 'undefined'); }
  function volumen() { return limitar(Number(CFG.sonido.volumen), 0, 1); }
  function musica(url) {
    if (!sonidoActivo()) return;
    if (musicaActual && musicaActual._url === url) return;
    if (musicaActual) { musicaActual.pause(); musicaActual = null; }
    if (!url) return;
    var a = new Audio(url);
    a._url = url;
    a.loop = true;
    a.volume = volumen() * 0.55;
    musicaActual = a;
    var p = a.play();
    if (p && p.catch) p.catch(function () { audioBloqueado = true; });
  }
  function sonido(url, v) {
    if (!sonidoActivo() || !url || audioBloqueado) return;
    var a = new Audio(url);
    a.volume = limitar(volumen() * (v || 1), 0, 1);
    var p = a.play();
    if (p && p.catch) p.catch(function () {});
  }
  function sonidoGolpe(m) {
    if (t - ultimoGolpe < 0.12) return;
    ultimoGolpe = t;
    sonido(m >= 2 ? SFX.golpeSuper : m < 1 ? SFX.golpeDebil : SFX.golpe, 0.35);
  }
  function desbloquearAudio() {
    if (!audioBloqueado) return;
    audioBloqueado = false;
    if (musicaActual) {
      var p = musicaActual.play();
      if (p && p.catch) p.catch(function () { audioBloqueado = true; });
    }
  }
  if (window.addEventListener) {
    window.addEventListener('pointerdown', desbloquearAudio);
    window.addEventListener('keydown', desbloquearAudio);
  }

  // ---------------------------------------------------------------------------
  // Bucle principal
  // ---------------------------------------------------------------------------
  function actualizar(dt) {
    t += dt;
    if (!CFG) return;
    if (fase === 'sala') actualizarSala(dt);
    else if (fase === 'batalla') actualizarBatalla(dt);
    else if (fase === 'campeon') actualizarCampeon(dt);
  }
  function dibujar() {
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.globalAlpha = 1;
    ctx.imageSmoothingEnabled = false;
    if (!CFG || fase === 'carga') pantallaCarga();
    else if (fase === 'sala') dibujarSala();
    else if (fase === 'batalla') dibujarBatalla();
    else if (fase === 'campeon') dibujarCampeon();
    indicadores();
  }
  var ultimoCuadro = 0;
  function bucle(ahora) {
    var dt = ultimoCuadro ? Math.min(0.05, (ahora - ultimoCuadro) / 1000) : 1 / 60;
    ultimoCuadro = ahora;
    actualizar(dt);
    dibujar();
    requestAnimationFrame(bucle);
  }
  function iniciar() {
    if (iniciar.hecho) return;
    iniciar.hecho = true;
    conectar();
    if (PRUEBA) {
      PRUEBA.paso = function (dt) { actualizar(dt); dibujar(); };
      PRUEBA.actualizar = actualizar;
      PRUEBA.dibujar = dibujar;
      PRUEBA.estado = function () { return { fase: fase, sala: sala, batalla: batalla, campeon: campeon, cuentaSala: cuentaSala, capturas: capturas, perfiles: perfiles }; };
      PRUEBA.forzarCuenta = function (s) { cuentaSala = s; };
    } else {
      requestAnimationFrame(bucle);
    }
  }
  var fuentes = document.fonts && document.fonts.load
    ? Promise.all([document.fonts.load('96px "Lilita One"'), document.fonts.load('900 32px "Nunito"'), document.fonts.load('800 32px "Nunito"')])
    : Promise.resolve();
  Promise.race([fuentes, new Promise(function (r) { setTimeout(r, 2500); })]).then(iniciar, iniciar);
})();
