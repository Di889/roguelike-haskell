/* ================================================
   DUNGEON CRAWLER — app.js
   Consome a API Scotty do backend Haskell.

   Rotas usadas:
     POST /nova-partida/:nome  → GameState inicial
     POST /acao                → { gameState, acaoCliente } → novo GameState
     GET  /leaderboard         → lista de pontuações

   Serialização Aeson (defaultOptions, DeriveGeneric):
     Construtores com campo  → { "tag": "...", "contents": ... }
     Construtores nullários  → { "tag": "..." }   (quando tipo NÃO é todo-nullário)
     Maybe Nothing           → null
     Maybe (Just x)          → x  (sem wrapper)
   ================================================ */

'use strict';

let gameState  = null;   // GameState atual
let isBusy     = false;  // evita requisições duplas

/* ================================================
   API
   ================================================ */

async function apiNovaPartida(nome) {
  const r = await fetch(`/nova-partida/${encodeURIComponent(nome)}`, { method: 'POST' });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

async function apiAcao(gs, acaoCliente) {
  const r = await fetch('/acao', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ gameState: gs, acaoCliente })
  });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

async function apiLeaderboard() {
  const r = await fetch('/leaderboard');
  if (!r.ok) return [];
  return r.json();
}

/* ================================================
   GERENCIAMENTO DE TELAS
   ================================================ */

function showScreen(id) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  document.getElementById(id).classList.add('active');
}

async function voltarInicio() {
  gameState = null;
  isBusy    = false;
  clearLog();
  document.getElementById('player-name').value = '';
  showScreen('start-screen');
  await loadLeaderboard('start-leaderboard');
}

/* ================================================
   INÍCIO DE PARTIDA
   ================================================ */

async function startGame() {
  const input = document.getElementById('player-name');
  const nome  = input.value.trim();
  if (!nome) { input.focus(); return; }

  setBusy(true);
  try {
    gameState = await apiNovaPartida(nome);
    clearLog();
    log(`Bem-vindo, ${nome}! Sua aventura começa...`, 'system');
    log('Você está no Andar 1. Explore o dungeon!', 'explore');
    showScreen('game-screen');
    renderUI();
  } catch (e) {
    log(`Erro ao iniciar: ${e.message}`, 'system');
  } finally {
    setBusy(false);
  }
}

/* ================================================
   AÇÕES DO JOGADOR
   Aeson serializa AcaoCliente (tipo misto) como TaggedObject:
     { "tag": "ExplorarC" }
     { "tag": "AtacarC" }
     { "tag": "DefenderC" }
     { "tag": "FugirC" }
     { "tag": "UsarItemC", "contents": <Item> }
   ================================================ */

async function executeAction(acaoCliente) {
  if (isBusy || !gameState) return;

  const prev = structuredClone(gameState);

  setBusy(true);
  try {
    const next = await apiAcao(gameState, acaoCliente);
    gerarLog(prev, next, acaoCliente);
    gameState = next;
    renderUI();

    if (gameState.jogador.health <= 0) {
      setTimeout(showDeathScreen, 900);
    }
  } catch (e) {
    log(`Erro de comunicação: ${e.message}`, 'system');
  } finally {
    setBusy(false);
  }
}

// Funções chamadas pelos botões / HTML onclick
function acaoExplorar()      { executeAction({ tag: 'ExplorarC' }); }
function acaoAtacar()        { executeAction({ tag: 'AtacarC' }); }
function acaoDefender()      { executeAction({ tag: 'DefenderC' }); }
function acaoFugir()         { executeAction({ tag: 'FugirC' }); }
function acaoUsarItem(item)  { executeAction({ tag: 'UsarItemC', contents: item }); }

/* ================================================
   GERAÇÃO DO LOG
   Deduz o que aconteceu comparando estados anterior/posterior.
   ================================================ */

function gerarLog(prev, next, acao) {
  const pp = prev.jogador;   // player anterior
  const np = next.jogador;   // player novo
  const pi = prev.inimigo;   // inimigo anterior (null = nenhum)
  const ni = next.inimigo;   // inimigo novo

  const tag = acao.tag;

  /* ---- EXPLORAR ---- */
  if (tag === 'ExplorarC') {
    if (!pi && ni) {
      // inimigo apareceu
      log('🗺 Você avança para a próxima sala...', 'explore');
      log(`⚠ Um monstro bloqueia seu caminho! HP: ${ni.hp} | ATK: ${ni.ataque}`, 'attack');
    } else if (np.health > pp.health) {
      // curou (fogueira)
      const ganhou = np.health - pp.health;
      log('🗺 Você encontrou uma fogueira na sala.', 'explore');
      log(`🔥 Você descansou e recuperou ${ganhou} HP.`, 'heal');
    } else if (np.itens.length > pp.itens.length) {
      // achou item
      const novoItem = np.itens.find(
        i => !pp.itens.some(p => p.nomeItem === i.nomeItem)
      );
      log('🗺 Você encontrou algo no chão!', 'explore');
      log(`📦 Item obtido: ${novoItem ? novoItem.nomeItem : 'item desconhecido'}.`, 'heal');
    } else if (next.andaratual > prev.andaratual) {
      log(`🗺 Sala vazia. Você avança para o Andar ${next.andaratual}!`, 'victory');
    } else {
      log('🗺 A sala está vazia. Você segue em frente.', 'explore');
    }
  }

  /* ---- ATACAR ---- */
  if (tag === 'AtacarC') {
    if (pi && !ni) {
      // matou o inimigo
      const xpGanho = np.xp - pp.xp;
      log(`⚔ Você desfere o golpe final!`, 'attack');
      log(`💥 Inimigo derrotado! +${xpGanho} XP`, 'victory');
    } else if (pi && ni) {
      const dano = pi.hp - ni.hp;
      log(`⚔ Você atacou causando ${dano} de dano! (HP inimigo: ${ni.hp})`, 'attack');
      resolverTurnoInimigo(pp, np, pi, ni);
    }
  }

  /* ---- DEFENDER ---- */
  if (tag === 'DefenderC') {
    log('🛡 Você se prepara para defender (+5 defesa).', 'defend');
    resolverTurnoInimigo(pp, np, pi, ni);
  }

  /* ---- FUGIR ---- */
  if (tag === 'FugirC') {
    if (!ni && pi) {
      log('🏃 Você correu e fugiu com sucesso!', 'explore');
    } else {
      log('🏃 Tentativa de fuga falhou!', 'enemy-atk');
      resolverTurnoInimigo(pp, np, pi, ni);
    }
  }

  /* ---- USAR ITEM ---- */
  if (tag === 'UsarItemC') {
    const item    = acao.contents;
    const eTag    = typeof item.efeito === 'string' ? item.efeito : item.efeito?.tag;
    log(`📦 Você usou: ${item.nomeItem}`, 'heal');

    if (eTag === 'Curar') {
      const cura = np.health - pp.health;
      if (cura > 0) log(`💚 Você recuperou ${cura} HP.`, 'heal');
    }
    if (eTag === 'FugaGarantida' && !ni && pi) {
      log('✨ Fuga garantida! Você escapou para a próxima sala.', 'explore');
    }
    // turno do inimigo (se ainda estiver em combate)
    if (ni) resolverTurnoInimigo(pp, np, pi, ni);
  }

  /* ---- Mudança de andar ---- */
  if (next.andaratual > prev.andaratual && tag !== 'ExplorarC') {
    log(`🏆 Você avançou para o Andar ${next.andaratual}!`, 'victory');
  }

  /* ---- Morte ---- */
  if (np.health <= 0) {
    log('💀 Você caiu... sua aventura termina aqui.', 'attack');
  }
}

/** Loga o turno do inimigo usando o primeiro caractere do atkpattern ANTERIOR.
 *  Esse char é exatamente o que o backend executou em resolverTurno:
 *    'A' → inimigo atacou (dano pode ser 0 se bloqueado pela defesa)
 *    'B' → inimigo se fortaleceu (+1 ataque)
 *  Inferir pelo delta de HP seria errado quando a defesa absorve tudo.
 */
function resolverTurnoInimigo(pp, np, pi, ni) {
  if (!pi) return; // não havia inimigo antes, turno não ocorreu

  const acaoInimigo = pi.atkpattern?.[0]; // 'A' ou 'B'

  if (acaoInimigo === 'A') {
    const dano = pp.health - np.health;
    if (dano > 0) {
      log(`💀 O inimigo atacou causando ${dano} de dano!`, 'enemy-atk');
    } else {
      // ataque aconteceu mas a defesa absorveu completamente
      log('🛡 O inimigo atacou, mas seu escudo bloqueou tudo! (0 dano)', 'defend');
    }
  } else if (acaoInimigo === 'B') {
    log('💪 O inimigo se fortaleceu! (+1 de ataque)', 'enemy-atk');
  } else {
    // fallback: padrão desconhecido — ainda usa delta de HP
    const dano = pp.health - np.health;
    if (dano > 0) log(`💀 O inimigo causou ${dano} de dano!`, 'enemy-atk');
    else log('👁 O inimigo passou o turno.', 'system');
  }
}

/* ================================================
   RENDERIZAÇÃO DA UI
   ================================================ */

function renderUI() {
  if (!gameState) return;

  const { jogador: p, inimigo: ini, andaratual, salaatual } = gameState;

  /* Header */
  document.getElementById('floor-info').textContent =
    `Andar ${andaratual} | Sala ${salaatual}/5`;

  /* Jogador
     maxHealth pode vir como undefined se a versão do backend ainda não
     incluiu o campo — usamos p.health como fallback (barra cheia). */
  const maxHp = p.maxHealth ?? p.health ?? 100;

  document.getElementById('player-name-display').textContent = `🗡 ${p.nome}`;
  document.getElementById('hp-text').textContent = `${p.health}/${maxHp}`;
  document.getElementById('xp-display').textContent  = p.xp;
  document.getElementById('level-display').textContent = Math.floor(p.xp / 10);
  document.getElementById('defense-display').textContent =
    p.defesa > 0 ? `+${p.defesa} 🛡` : '0';

  /* Barra de HP */
  const hpBar = document.getElementById('hp-bar');
  const pct   = Math.max(0, Math.min(100, (p.health / maxHp) * 100));
  hpBar.style.width = pct + '%';
  hpBar.className = 'bar hp-bar';
  if (pct <= 25) hpBar.classList.add('critical');
  else if (pct <= 50) hpBar.classList.add('low');

  /* Inventário */
  const itemList = document.getElementById('item-list');
  const slots    = 3;
  itemList.innerHTML = '';
  // titulo do inventário com contagem
  document.querySelector('.inv-title').textContent =
    `ITENS (${p.itens.length}/${slots})`;

  if (p.itens.length === 0) {
    itemList.innerHTML = '<span class="muted">Inventário vazio</span>';
  } else {
    p.itens.forEach(item => {
      const btn = document.createElement('button');
      btn.className   = 'item-btn';
      btn.textContent = `${item.nomeItem}\n${efeitoLabel(item.efeito)}`;
      btn.title       = `Usar ${item.nomeItem}`;
      btn.onclick     = () => acaoUsarItem(item);
      itemList.appendChild(btn);
    });
  }

  /* Inimigo */
  const enemyDiv = document.getElementById('enemy-info');
  if (ini) {
    // HP máximo estimado (fórmula do backend: 10 + andar * 5)
    const hpMax   = 10 + andaratual * 5;
    const ePct    = Math.max(0, Math.min(100, (ini.hp / hpMax) * 100));
    enemyDiv.innerHTML = `
      <div class="enemy-name">⚔ Monstro (Andar ${andaratual})</div>
      <div class="enemy-hp-wrap">
        <span class="stat-label">HP</span>
        <div class="bar-wrap" style="flex:1">
          <div class="bar" style="width:${ePct}%; background: var(--danger);"></div>
        </div>
        <span class="stat-val">${ini.hp}</span>
      </div>
      <div class="enemy-stat">ATK: <strong>${ini.ataque}</strong></div>
      <div class="atkpattern-title">Padrão de ataque:</div>
      <div class="pattern-display">${renderPattern(ini.atkpattern)}</div>
      <div class="pat-legend">⚔ Ataque &nbsp;|&nbsp; 💪 Buff</div>
    `;
  } else {
    enemyDiv.innerHTML = '<p class="no-enemy">Nenhum inimigo<br>à vista...</p>';
  }

  /* Botões */
  const hasEnemy = !!ini;
  setBtn('btn-explorar', !hasEnemy);
  setBtn('btn-atacar',    hasEnemy);
  setBtn('btn-defender',  hasEnemy);
  setBtn('btn-fugir',     hasEnemy);
}

/** Habilita/desabilita um botão pelo ID. */
function setBtn(id, enabled) {
  const btn = document.getElementById(id);
  if (btn) btn.disabled = !enabled;
}

/** Rótulo legível do efeito de um item.
    Efeito serializado como: { "tag": "Curar", "contents": 20 } ou { "tag": "FugaGarantida" }
    (Aeson TaggedObject, pois Efeito não é todo-nullário) */
function efeitoLabel(efeito) {
  if (!efeito) return '?';
  // caso venha como string (improvável mas defensivo)
  if (typeof efeito === 'string') {
    return efeito === 'FugaGarantida' ? 'Fuga Garantida' : efeito;
  }
  if (efeito.tag === 'Curar')        return `Cura ${efeito.contents} HP`;
  if (efeito.tag === 'FugaGarantida') return 'Fuga Garantida';
  return efeito.tag;
}

/** Renderiza o padrão de ataque do inimigo (ex: "AAB").
    O primeiro caractere é a próxima ação. */
function renderPattern(pattern) {
  if (!pattern) return '';
  return pattern.split('').map((c, i) => {
    const emoji = c === 'A' ? '⚔' : '💪';
    const cls   = `pat-char ${c}${i === 0 ? ' next' : ''}`;
    const title = c === 'A' ? 'Vai atacar' : 'Vai se fortalecer';
    return `<span class="${cls}" title="${title}">${emoji}</span>`;
  }).join('');
}

/* ================================================
   LOG
   ================================================ */

function log(msg, type = '') {
  const container = document.getElementById('event-log');
  if (!container) return;
  const el = document.createElement('div');
  el.className   = `log-entry${type ? ' ' + type : ''}`;
  el.textContent = msg;
  container.prepend(el); // mais recente no topo
}

function clearLog() {
  const container = document.getElementById('event-log');
  if (container) container.innerHTML = '';
}

/* ================================================
   TELA DE MORTE
   ================================================ */

async function showDeathScreen() {
  const p     = gameState?.jogador;
  const andar = gameState?.andaratual ?? 1;

  document.getElementById('death-stats').innerHTML = `
    <p>Aventureiro: <strong>${escHtml(p?.nome ?? '?')}</strong></p>
    <p>Andar alcançado: <strong>${andar}</strong></p>
    <p>XP acumulado: <strong>${p?.xp ?? 0}</strong></p>
    <p>Nível final: <strong>${Math.floor((p?.xp ?? 0) / 10)}</strong></p>
  `;

  showScreen('death-screen');
  await loadLeaderboard('death-leaderboard');
}

/* ================================================
   LEADERBOARD
   O backend salva com salvarScore(nome, andar).
   O formato exato depende do Game.Database, pode ser:
     [{nome: "...", andar: N}]  ou  [["nome", N]]
   ================================================ */

async function loadLeaderboard(elementId) {
  const el = document.getElementById(elementId);
  if (!el) return;
  el.textContent = 'Carregando...';

  try {
    const data = await apiLeaderboard();

    if (!Array.isArray(data) || data.length === 0) {
      el.textContent = 'Nenhuma pontuação registrada ainda.';
      return;
    }

    // Tenta normalizar independente do formato
    const entries = data.slice(0, 10).map(entry => {
      if (Array.isArray(entry)) {
        // formato: ["nome", andar]
        return { nome: entry[0] ?? '?', andar: entry[1] ?? '?' };
      }
      // formato: { nome, andar } — field names podem variar
      return {
        nome:  entry.nome  ?? entry.name  ?? entry[0] ?? '?',
        andar: entry.andar ?? entry.floor ?? entry[1] ?? '?'
      };
    });

    el.innerHTML = `
      <table class="lb-table">
        <thead>
          <tr><th>#</th><th>Nome</th><th>Andar</th></tr>
        </thead>
        <tbody>
          ${entries.map((e, i) => `
            <tr>
              <td>${i + 1}</td>
              <td>${escHtml(String(e.nome))}</td>
              <td>${escHtml(String(e.andar))}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  } catch (e) {
    el.textContent = 'Erro ao carregar placar.';
  }
}

/* ================================================
   ESTADO DE CARREGAMENTO
   ================================================ */

function setBusy(busy) {
  isBusy = busy;
  // Desabilita/habilita todos os botões globalmente
  document.querySelectorAll('.btn').forEach(btn => {
    if (busy) {
      btn.setAttribute('data-saved-disabled', btn.disabled);
      btn.disabled = true;
    } else {
      const saved = btn.getAttribute('data-saved-disabled');
      btn.disabled = saved === 'true';
    }
  });
  // Deixa o renderUI reajustar os botões de ação após busy=false
  if (!busy && gameState) renderUI();
}

/* ================================================
   UTILIDADES
   ================================================ */

function escHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/* ================================================
   INICIALIZAÇÃO
   ================================================ */

document.addEventListener('DOMContentLoaded', () => {
  // Carrega leaderboard inicial
  loadLeaderboard('start-leaderboard');

  // Botão de iniciar
  document.getElementById('start-btn')
    .addEventListener('click', startGame);

  // Enter no campo de nome
  document.getElementById('player-name')
    .addEventListener('keydown', e => {
      if (e.key === 'Enter') startGame();
    });
});
