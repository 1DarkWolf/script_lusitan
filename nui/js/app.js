const app = document.getElementById('scratch-app');
const canvas = document.getElementById('scratch-canvas');
const context = canvas.getContext('2d', { willReadFrequently: true });
const status = document.getElementById('status');
const prize = document.getElementById('prize');
const finish = document.getElementById('finish');
const scratchTicket = document.getElementById('scratch-ticket');
const scratchTicketImage = document.getElementById('scratch-ticket-image');
const scratchArea = document.getElementById('scratch-area');
const ticketCard = document.getElementById('ticket-card');
const ticketTitle = document.getElementById('ticket-title');
const ticketId = document.getElementById('ticket-id');
const ticketDetails = document.getElementById('ticket-details');
const ownerDashboard = document.getElementById('owner-dashboard');
const ownerContent = document.getElementById('owner-content');
let drawing = false;
let completed = false;
let activeScratchLayout;

const scratchLayouts = Object.freeze({
  bronze: { image: 'img/scratch_bronze.png', left: '27.5%', top: '62.8%', width: '44.7%', height: '16.3%', cover: '#a58958' },
  silver: { image: 'img/scratch_silver.png', left: '32.1%', top: '55.1%', width: '35.0%', height: '15.4%', cover: '#aeb6c0' },
  gold: { image: 'img/scratch_gold.png', left: '32.2%', top: '79.7%', width: '35.2%', height: '7.4%', cover: '#b5b4ad' },
  diamond: { image: 'img/scratch_diamond.png', left: '28.3%', top: '65.6%', width: '43.5%', height: '15.5%', cover: '#b8bec5' }
});

const post = (name, data = {}) => fetch(`https://${GetParentResourceName()}/${name}`, {
  method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(data)
});

const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[character]));
const values = (items, className = '') => `<div class="ticket-values">${(items || []).map(value => `<span class="ticket-value ${className}">${escapeHtml(value)}</span>`).join('')}</div>`;
const ticketRow = (label, content) => `<article class="ticket-row"><strong>${escapeHtml(label)}</strong>${content}</article>`;

function showTicketCard(ticket) {
  const payload = ticket.payload || {};
  const game = payload.game;
  const rows = [];
  ticketTitle.textContent = ticket.label || 'Bilhete de lotaria';
  ticketId.textContent = `Bilhete #${String(ticket.ticketId || '').slice(0, 8)}`;

  if (game === 'euromillions') {
    rows.push(ticketRow('Números', values(payload.numbers)));
    rows.push(ticketRow('Estrelas', values(payload.stars, 'star')));
  } else if (game === 'totoloto') {
    rows.push(ticketRow('Números', values(payload.numbers)));
    rows.push(ticketRow('Número da sorte', values([payload.luckyNumber], 'star')));
  } else if (game === 'eurodreams') {
    rows.push(ticketRow('Números', values(payload.numbers)));
    rows.push(ticketRow('Número Dream', values([payload.dreamNumber], 'dream')));
  } else if (game === 'joker') {
    rows.push(ticketRow('Código Joker', `<span class="ticket-code">${escapeHtml(payload.code)}</span>`));
  } else if (game === 'classic' || game === 'popular') {
    rows.push(ticketRow('Número do bilhete', `<span class="ticket-code">${escapeHtml(payload.number)}</span>`));
  } else if (game === 'instant') {
    rows.push(ticketRow('Validação', '<span>Apresenta este bilhete no balcão para validação.</span>'));
  }

  if (payload.drawKey) rows.push(ticketRow('Sorteio', `<span>${escapeHtml(payload.drawKey)}</span>`));
  ticketDetails.innerHTML = rows.join('');
  document.body.classList.add('cj-visible');
  app.classList.add('hidden');
  dashboard.classList.add('hidden');
  ownerDashboard.classList.add('hidden');
  ticketCard.classList.remove('hidden');
}

function paintCover() {
  const bounds = canvas.getBoundingClientRect();
  canvas.width = Math.floor(bounds.width);
  canvas.height = Math.floor(bounds.height);
  context.globalCompositeOperation = 'source-over';
  context.fillStyle = activeScratchLayout?.cover || '#b5b4ad';
  context.fillRect(0, 0, canvas.width, canvas.height);
  context.fillStyle = 'rgba(255,255,255,.26)';
  for (let x = -canvas.height; x < canvas.width; x += 14) context.fillRect(x, 0, 5, canvas.height);
  context.globalCompositeOperation = 'destination-out';
}

function setScratchLayout(card = {}) {
  const cardId = scratchLayouts[card.id] ? card.id : 'bronze';
  activeScratchLayout = scratchLayouts[cardId];
  scratchTicket.dataset.card = cardId;
  scratchTicketImage.src = activeScratchLayout.image;
  scratchTicketImage.alt = card.label || 'Raspadinha';
  Object.assign(scratchArea.style, {
    left: activeScratchLayout.left,
    top: activeScratchLayout.top,
    width: activeScratchLayout.width,
    height: activeScratchLayout.height
  });
}

function requestScratchResult() {
  if (completed) return;
  completed = true;
  drawing = false;
  status.textContent = 'A validar o bilhete…';
  post('scratchComplete');
}

function scratch(event) {
  if (!drawing || completed) return;
  const bounds = canvas.getBoundingClientRect();
  const x = (event.clientX - bounds.left) * (canvas.width / bounds.width);
  const y = (event.clientY - bounds.top) * (canvas.height / bounds.height);
  context.beginPath();
  context.arc(x, y, 18, 0, Math.PI * 2);
  context.fill();
  const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
  let clearedOpacity = 0;
  for (let index = 3; index < pixels.length; index += 4) {
    clearedOpacity += 1 - (pixels[index] / 255);
  }
  if (clearedOpacity / (canvas.width * canvas.height) >= .5) {
    requestScratchResult();
  }
}

canvas.addEventListener('pointerdown', event => { drawing = true; canvas.setPointerCapture(event.pointerId); scratch(event); });
canvas.addEventListener('pointermove', scratch);
canvas.addEventListener('pointerup', requestScratchResult);
canvas.addEventListener('pointercancel', requestScratchResult);
document.getElementById('close').addEventListener('click', () => { app.classList.add('hidden'); document.body.classList.remove('cj-visible'); post('closeScratch'); });
finish.addEventListener('click', () => { app.classList.add('hidden'); document.body.classList.remove('cj-visible'); post('closeScratch'); });
document.getElementById('ticket-close').addEventListener('click', () => { ticketCard.classList.add('hidden'); document.body.classList.remove('cj-visible'); post('closeTicketCard'); });

window.addEventListener('message', ({ data }) => {
  if (data.action === 'openDashboard') {
    document.body.classList.add('cj-visible');
    app.classList.add('hidden');
    ticketCard.classList.add('hidden');
    ownerDashboard.classList.add('hidden');
    document.getElementById('dashboard').classList.remove('hidden');
    showTab('buy');
  }
  if (data.action === 'closeDashboard') {
    dashboard.classList.add('hidden');
    document.body.classList.remove('cj-visible');
  }
  if (data.action === 'closeAll') {
    app.classList.add('hidden');
    dashboard.classList.add('hidden');
    ticketCard.classList.add('hidden');
    ownerDashboard.classList.add('hidden');
    document.body.classList.remove('cj-visible');
  }
  if (data.action === 'openTicketCard') showTicketCard(data.ticket || {});
  if (data.action === 'openOwnerDashboard') {
    document.body.classList.add('cj-visible');
    app.classList.add('hidden');
    dashboard.classList.add('hidden');
    ticketCard.classList.add('hidden');
    ownerDashboard.classList.remove('hidden');
    loadOwnerAnalytics();
  }
  if (data.action === 'openScratch') {
    document.body.classList.add('cj-visible');
    setScratchLayout(data.card || {});
    prize.textContent = '?';
    status.textContent = 'Mantém premido e raspa.';
    finish.classList.add('hidden');
    completed = false;
    app.classList.remove('hidden');
    const paintWhenReady = () => requestAnimationFrame(paintCover);
    if (scratchTicketImage.complete && scratchTicketImage.naturalWidth) paintWhenReady();
    else scratchTicketImage.addEventListener('load', paintWhenReady, { once: true });
  }
  if (data.action === 'scratchResult') {
    prize.textContent = data.prize > 0 ? `€${data.prize}` : 'Sem prémio';
    context.clearRect(0, 0, canvas.width, canvas.height);
    status.textContent = data.prize > 0 ? 'Parabéns! O prémio foi pago.' : 'Mais sorte na próxima.';
    finish.classList.remove('hidden');
  }
});

const dashboard = document.getElementById('dashboard');
const content = document.getElementById('dashboard-content');
const games = [['scratch', 'Raspadinhas'], ['euromillions', 'Euromilhões'], ['totoloto', 'Totoloto'], ['eurodreams', 'EuroDreams'], ['joker', 'Joker'], ['lotteries', 'Lotarias']];
const esc = value => String(value ?? '').replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

const money = value => `€${Number(value || 0).toLocaleString('pt-PT')}`;

const gameSaleLabels = Object.freeze({
  scratch: 'Raspadinhas',
  euromillions: 'Euromilhões',
  totoloto: 'Totoloto',
  eurodreams: 'EuroDreams',
  joker: 'Joker',
  classic: 'Lotaria Clássica',
  popular: 'Lotaria Popular',
  instant: 'Lotaria Instantânea'
});

const transactionLabels = Object.freeze({
  scratch_purchase: 'Compra de raspadinha',
  scratch_prize: 'Prémio de raspadinha',
  scratch_issue_reversal: 'Reversão de emissão de raspadinha',
  scratch_prize_reversal: 'Reversão de prémio de raspadinha',
  euromillions_purchase: 'Compra de Euromilhões',
  euromillions_issue_reversal: 'Reversão de emissão de Euromilhões',
  totoloto_purchase: 'Compra de Totoloto',
  totoloto_issue_reversal: 'Reversão de emissão de Totoloto',
  eurodreams_purchase: 'Compra de EuroDreams',
  eurodreams_issue_reversal: 'Reversão de emissão de EuroDreams',
  joker_purchase: 'Compra de Joker',
  joker_issue_reversal: 'Reversão de emissão de Joker',
  classic_purchase: 'Compra de Lotaria Clássica',
  classic_issue_reversal: 'Reversão de emissão de Lotaria Clássica',
  popular_purchase: 'Compra de Lotaria Popular',
  popular_issue_reversal: 'Reversão de emissão de Lotaria Popular',
  instant_purchase: 'Compra de Lotaria Instantânea',
  instant_issue_reversal: 'Reversão de emissão de Lotaria Instantânea',
  scratch_restock: 'Reposição de stock de raspadinhas',
  boss_deposit: 'Depósito do patrão',
  boss_withdrawal: 'Levantamento do patrão',
  withdrawal_reversal: 'Reversão de levantamento',
  admin_credit: 'Crédito administrativo',
  prize_claim_payout: 'Pagamento de prémio validado',
  prize_claim_reversal: 'Reversão de prémio validado'
});

const translatedGameSale = type => gameSaleLabels[String(type || '').replace(/_purchase$/, '')] || String(type || '').replace(/_/g, ' ');
const translatedTransaction = type => transactionLabels[type] || String(type || '').replace(/_/g, ' ');

const shopProducts = [
  { id: 'scratch', category: 'JOGO INSTANTÂNEO', title: 'Raspadinhas', text: 'Revela o prémio no momento. Há quatro categorias disponíveis.', icon: '✦', tone: 'gold' },
  { id: 'euromillions', category: 'SORTEIOS', title: 'Euromilhões', text: 'Escolhe a chave ou deixa a sorte decidir por ti.', icon: '★', tone: 'blue' },
  { id: 'totoloto', category: 'SORTEIOS', title: 'Totoloto', text: 'Regista a tua chave para o próximo sorteio.', icon: '●', tone: 'violet' },
  { id: 'eurodreams', category: 'SORTEIOS', title: 'EuroDreams', text: 'Seis números e um Dream Number para ganhar.', icon: '☾', tone: 'purple' },
  { id: 'joker', category: 'SORTEIOS', title: 'Joker', text: 'Recebe o teu código de seis dígitos.', icon: '#', tone: 'red' },
  { id: 'lotteries', category: 'BILHETES', title: 'Lotarias', text: 'Clássica, Popular e Instantânea num só balcão.', icon: '♣', tone: 'green' }
];

function analyticsRows(rows, emptyText, format) {
  if (!rows || !rows.length) return `<p class="status">${emptyText}</p>`;
  return rows.map(format).join('');
}

function renderOwnerAnalytics(data) {
  if (!data) {
    ownerContent.innerHTML = '<p class="status">Não tens permissão para consultar a gestão.</p>';
    return;
  }

  const stock = analyticsRows(data.scratch?.stock, 'Sem stock registado.', row => `
    <div class="analytics-row"><span>${esc(row.label)}</span><strong>${Number(row.quantity || 0)}</strong></div>`);
  const jackpots = analyticsRows(data.jackpots, 'Sem jackpots registados.', row => `
    <div class="analytics-row"><span>${esc(row.name)}</span><strong>${money(row.amount)}</strong></div>`);
  const games = analyticsRows(data.gameSales, 'Ainda não existem vendas.', row => `
    <div class="analytics-row"><span>${esc(translatedGameSale(row.type))}</span><strong>${Number(row.sales || 0)} / ${money(row.revenue)}</strong></div>`);
  const daily = analyticsRows(data.dailySales, 'Sem vendas nos últimos sete dias.', row => `
    <div class="analytics-row"><span>${esc(row.day)}</span><strong>${Number(row.sales || 0)} / ${money(row.revenue)}</strong></div>`);
  const sellers = analyticsRows(data.sellerSales, 'Sem pontos de venda configurados.', row => `
    <div class="analytics-row"><span>${esc(row.label)}</span><strong>${Number(row.sales || 0)} / ${money(row.revenue)}</strong></div>`);
  const transactions = analyticsRows(data.recentTransactions, 'Ainda não existem movimentos.', row => `
    <div class="analytics-row"><span>${esc(translatedTransaction(row.type))}</span><strong>${money(row.amount)}</strong></div>`);
  const stockOptions = (data.scratch?.stock || []).map(row => `<option value="${esc(row.cardId)}">${esc(row.label)} — stock atual: ${Number(row.quantity || 0)}</option>`).join('');

  ownerContent.innerHTML = `
    <nav class="owner-tabs" aria-label="Secções de gestão">
      <button class="active" data-owner-tab="overview" type="button">Visão geral</button>
      <button data-owner-tab="stock" type="button">Stock</button>
      <button data-owner-tab="sales" type="button">Vendas</button>
      <button data-owner-tab="stores" type="button">Lojas</button>
    </nav>
    <section class="owner-view active" data-owner-view="overview">
      <div class="metric-grid owner-metrics">
        <article class="metric-card"><span>Saldo da empresa</span><strong>${money(data.balance)}</strong><small>Disponível na conta</small></article>
        <article class="metric-card"><span>Raspadinhas vendidas</span><strong>${Number(data.scratch?.sold || 0)}</strong><small>Desde o início</small></article>
        <article class="metric-card"><span>Receita de raspadinhas</span><strong>${money(data.scratch?.revenue)}</strong><small>Total acumulado</small></article>
        <article class="metric-card"><span>Vendas totais</span><strong>${Number(data.totals?.sales || 0)}</strong><small>Todos os jogos</small></article>
      </div>
      <div class="owner-grid">
        <section class="analytics-panel"><h3>Últimos 7 dias</h3>${daily}</section>
        <section class="analytics-panel"><h3>Jackpots por sorteio</h3>${jackpots}</section>
        <section class="analytics-panel owner-action-panel analytics-wide">
          <p class="owner-label">CONTA DA EMPRESA</p>
          <h3>Operações rápidas</h3>
          <p class="owner-description">Deposita ou levanta dinheiro sem sair da central de gestão.</p>
          <label for="owner-finance-amount">Valor</label>
          <input id="owner-finance-amount" type="number" min="1" step="1" placeholder="Ex.: 500">
          <div class="owner-action-buttons">
            <button class="owner-secondary" data-owner-finance="deposit" type="button">Depositar</button>
            <button class="owner-primary" data-owner-finance="withdraw" type="button">Levantar</button>
          </div>
          <p id="owner-finance-feedback" class="owner-feedback"></p>
        </section>
      </div>
    </section>
    <section class="owner-view" data-owner-view="stock">
      <div class="owner-grid">
        <section class="analytics-panel owner-action-panel">
          <p class="owner-label">REPOSIÇÃO DE STOCK</p>
          <h3>Usar raspadinhas em branco</h3>
          <p class="owner-description">Escolhe qual tipo de raspadinha queres produzir. Cada unidade usa uma raspadinha em branco do teu inventário.</p>
          <label for="owner-restock-card">Tipo de raspadinha</label>
          <select id="owner-restock-card">${stockOptions}</select>
          <label for="owner-restock-amount">Quantidade</label>
          <input id="owner-restock-amount" type="number" min="1" step="1" placeholder="Ex.: 10">
          <button id="owner-restock" class="owner-primary" type="button">Repor stock</button>
          <p id="owner-feedback" class="owner-feedback"></p>
        </section>
        <section class="analytics-panel"><p class="owner-label">STOCK ATUAL</p><h3>Raspadinhas disponíveis</h3>${stock}</section>
      </div>
    </section>
    <section class="owner-view" data-owner-view="sales">
      <div class="owner-grid">
        <section class="analytics-panel"><h3>Vendas por jogo</h3>${games}</section>
        <section class="analytics-panel"><h3>Movimentos recentes</h3>${transactions}</section>
      </div>
    </section>
    <section class="owner-view" data-owner-view="stores">
      <div class="owner-grid">
        <section class="analytics-panel analytics-wide"><p class="owner-label">ÚLTIMOS 7 DIAS</p><h3>Faturação por estabelecimento</h3>${sellers}</section>
      </div>
    </section>`;

  ownerContent.querySelectorAll('[data-owner-tab]').forEach(button => {
    button.onclick = () => {
      ownerContent.querySelectorAll('[data-owner-tab]').forEach(item => item.classList.toggle('active', item === button));
      ownerContent.querySelectorAll('[data-owner-view]').forEach(view => view.classList.toggle('active', view.dataset.ownerView === button.dataset.ownerTab));
    };
  });

  const restockButton = ownerContent.querySelector('#owner-restock');
  if (restockButton) {
    restockButton.onclick = async () => {
      const cardId = ownerContent.querySelector('#owner-restock-card').value;
      const amount = Number(ownerContent.querySelector('#owner-restock-amount').value);
      const feedback = ownerContent.querySelector('#owner-feedback');
      if (!Number.isInteger(amount) || amount < 1) {
        feedback.textContent = 'Indica uma quantidade válida.';
        return;
      }
      restockButton.disabled = true;
      const response = await post('restockScratch', { cardId, amount });
      const result = await response.json();
      feedback.textContent = result.ok ? 'Pedido enviado. Confirma a notificação do servidor.' : 'Não foi possível enviar o pedido.';
      setTimeout(loadOwnerAnalytics, 500);
    };
  }

  ownerContent.querySelectorAll('[data-owner-finance]').forEach(button => {
    button.onclick = async () => {
      const amount = Number(ownerContent.querySelector('#owner-finance-amount').value);
      const feedback = ownerContent.querySelector('#owner-finance-feedback');
      if (!Number.isInteger(amount) || amount < 1) {
        feedback.textContent = 'Indica um valor válido.';
        return;
      }
      button.disabled = true;
      const response = await post('ownerFinance', { action: button.dataset.ownerFinance, amount });
      const result = await response.json();
      feedback.textContent = result.message || 'Não foi possível concluir a operação.';
      if (result.ok) setTimeout(loadOwnerAnalytics, 350);
      button.disabled = false;
    };
  });
}

async function loadOwnerAnalytics() {
  ownerContent.innerHTML = '<p class="status">A carregar dados da empresa...</p>';
  const response = await post('loadOwnerAnalytics');
  renderOwnerAnalytics(await response.json());
}

async function showTab(tab) {
  document.querySelectorAll('.tabs button').forEach(button => button.classList.toggle('active', button.dataset.tab === tab));
  if (tab === 'buy') {
    content.innerHTML = `
      <section class="shop-hero">
        <div><p class="eyebrow">PONTO DE VENDA OFICIAL</p><h2>Escolhe o teu próximo jogo</h2><p>Todos os bilhetes ficam guardados no teu inventário para consultares quando quiseres.</p></div>
        <div class="shop-hero-mark">CJ</div>
      </section>
      <div class="shop-catalog">${shopProducts.map(product => `
        <button class="shop-card ${product.tone}" data-game="${product.id}" type="button">
          <span class="shop-icon">${product.icon}</span>
          <span class="shop-category">${product.category}</span>
          <strong>${product.title}</strong>
          <small>${product.text}</small>
          <span class="shop-action">Comprar <b>→</b></span>
        </button>`).join('')}</div>`;
    content.querySelectorAll('[data-game]').forEach(button => button.onclick = () => post('buyGame', { game: button.dataset.game }));
    return;
  }
  content.innerHTML = '<p class="status">A carregar…</p>';
  const response = await post('loadDashboard', { section: tab });
  const rows = await response.json();
  if (tab === 'profile') {
    content.innerHTML = `<div class="record"><strong>Nível ${esc(rows.level?.label || 'Bronze')}</strong><span>${esc(rows.points || 0)} pontos</span><br><small>Total gasto: €${esc(rows.total_spent || 0)} · Total ganho: €${esc(rows.total_won || 0)}</small></div>`;
    return;
  }
  if (tab === 'company') {
    if (!rows) { content.innerHTML = '<p class="status">Não tens permissão para consultar a empresa.</p>'; return; }
    const transactions = rows.transactions.map(row => `<article class="record"><strong>${esc(row.type)}</strong><span>€${esc(row.amount)}</span><br><small>${esc(row.created_at)}</small></article>`).join('') || '<p class="status">Sem movimentos.</p>';
    const employees = rows.employees.map(row => `<article class="record"><strong>${esc(row.grade)}</strong><span>${esc(row.citizenid)}</span><br><small>${esc(row.hired_at)}</small></article>`).join('') || '<p class="status">Sem empregados.</p>';
    const claims = (rows.claims || []).map(row => `<article class="record"><strong>€${esc(row.amount)}</strong><span>${esc(row.citizenid)}</span><br><small>${esc(row.reason)}</small><br><button class="game-button" data-claim="${esc(row.id)}">Aprovar</button></article>`).join('') || '<p class="status">Sem prémios pendentes.</p>';
    content.innerHTML = `<div class="record"><strong>Saldo da empresa</strong><span>€${esc(rows.balance)}</span></div><h2>Movimentos recentes</h2><div class="record-list">${transactions}</div><h2>Empregados</h2><div class="record-list">${employees}</div><h2>Prémios pendentes</h2><div class="record-list">${claims}</div>`;
    content.querySelectorAll('[data-claim]').forEach(button => button.onclick = () => post('approvePrize', { claimId: Number(button.dataset.claim) }).then(() => showTab('company')));
    return;
  }
  if (!rows.length) { content.innerHTML = '<p class="status">Ainda não existem registos.</p>'; return; }
  content.innerHTML = `<div class="record-list">${rows.map(row => tab === 'tickets'
    ? `<article class="record"><strong>${esc(row.payload.game)}</strong><span>Bilhete ${esc(row.ticket_id)}</span><br><small>${esc(row.status)}</small></article>`
    : tab === 'ranking'
      ? `<article class="record"><strong>${esc(row.citizenid)}</strong><span>${esc(row.points)} pontos</span><br><small>Gasto: €${esc(row.total_spent)} · Ganho: €${esc(row.total_won)}</small></article>`
      : `<article class="record"><strong>${esc(row.game_id)}</strong><span>${esc(JSON.stringify(row.result))}</span><br><small>${esc(row.drawn_at)}</small></article>`).join('')}</div>`;
}

document.querySelectorAll('.tabs button').forEach(button => button.onclick = () => showTab(button.dataset.tab));
document.getElementById('dashboard-close').onclick = () => { dashboard.classList.add('hidden'); document.body.classList.remove('cj-visible'); post('closeDashboard'); };
document.getElementById('owner-close').onclick = () => { ownerDashboard.classList.add('hidden'); document.body.classList.remove('cj-visible'); post('closeOwnerDashboard'); };
document.getElementById('owner-refresh').onclick = loadOwnerAnalytics;
