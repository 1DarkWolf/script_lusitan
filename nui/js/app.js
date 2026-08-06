const app = document.getElementById('scratch-app');
const canvas = document.getElementById('scratch-canvas');
const context = canvas.getContext('2d', { willReadFrequently: true });
const status = document.getElementById('status');
const prize = document.getElementById('prize');
const finish = document.getElementById('finish');
let drawing = false;
let completed = false;

const post = (name, data = {}) => fetch(`https://${GetParentResourceName()}/${name}`, {
  method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(data)
});

function paintCover() {
  const bounds = canvas.getBoundingClientRect();
  canvas.width = Math.floor(bounds.width);
  canvas.height = Math.floor(bounds.height);
  context.globalCompositeOperation = 'source-over';
  context.fillStyle = '#d3a62f';
  context.fillRect(0, 0, canvas.width, canvas.height);
  context.fillStyle = 'rgba(255,255,255,.26)';
  for (let x = -canvas.height; x < canvas.width; x += 16) context.fillRect(x, 0, 7, canvas.height);
  context.globalCompositeOperation = 'destination-out';
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

window.addEventListener('message', ({ data }) => {
  if (data.action === 'openDashboard') {
    document.body.classList.add('cj-visible');
    app.classList.add('hidden');
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
    document.body.classList.remove('cj-visible');
  }
  if (data.action === 'openScratch') {
    document.body.classList.add('cj-visible');
    document.getElementById('card-title').textContent = data.card.label;
    prize.textContent = '?';
    status.textContent = 'Mantém premido e raspa.';
    finish.classList.add('hidden');
    completed = false;
    app.classList.remove('hidden');
    requestAnimationFrame(paintCover);
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

async function showTab(tab) {
  document.querySelectorAll('.tabs button').forEach(button => button.classList.toggle('active', button.dataset.tab === tab));
  if (tab === 'buy') {
    content.innerHTML = `<div class="game-grid">${games.map(([id, label]) => `<button class="game-button" data-game="${id}">${label}</button>`).join('')}</div>`;
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
