const resultContainer = document.getElementById('results');
const resultCount = document.getElementById('result-count');
const refreshButton = document.getElementById('refresh');
let phoneComponentsReady = false;
let loading = false;

const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[character]));
const balls = (numbers, kind = '') => `<div class="balls">${(numbers || []).map(number => `<span class="ball ${kind}">${escapeHtml(number)}</span>`).join('')}</div>`;
const resultGroup = (label, content) => `<div class="result-group"><p class="result-label">${escapeHtml(label)}</p>${content}</div>`;

function resultDetails(result) {
  if (result.game_id === 'euromillions') {
    return resultGroup('Números', balls(result.numbers)) + resultGroup('Estrelas', balls(result.stars, 'special'));
  }
  if (result.game_id === 'totoloto') {
    return resultGroup('Números', balls(result.numbers)) + resultGroup('Número da sorte', balls([result.luckyNumber], 'special'));
  }
  if (result.game_id === 'eurodreams') {
    return resultGroup('Números', balls(result.numbers)) + resultGroup('Número Dream', balls([result.dreamNumber], 'dream'));
  }
  if (result.game_id === 'joker') {
    return resultGroup('Código Joker', `<span class="code">${escapeHtml(result.code)}</span>`);
  }
  return resultGroup('Número vencedor', `<span class="code">${escapeHtml(result.number)}</span>`);
}

function render(results) {
  resultCount.textContent = String(results.length);
  if (!results.length) {
    resultContainer.innerHTML = '<div class="empty-card"><p>Ainda não existem resultados publicados.</p></div>';
    return;
  }

  resultContainer.innerHTML = results.map(row => `
    <article class="result-card">
      <div class="result-topline">
        <div>
          <h3 class="game-name">${escapeHtml(row.label)}</h3>
          <p class="draw-date">${escapeHtml(row.drawn_at)}</p>
        </div>
        <span class="draw-badge">OFICIAL</span>
      </div>
      <div class="result-divider"></div>
      ${resultDetails({ ...row.result, game_id: row.game_id })}
      <div class="result-footer"><span><i class="official-dot"></i>Resultado publicado</span><span>Centro de Jogos</span></div>
    </article>
  `).join('');
}

async function loadResults() {
  if (loading || !phoneComponentsReady || typeof globalThis.fetchNui !== 'function') return;
  loading = true;
  refreshButton.disabled = true;
  resultContainer.innerHTML = '<div class="loading-card"><span class="loading-dot" aria-hidden="true"></span><p>A atualizar resultados...</p></div>';

  try {
    const results = await globalThis.fetchNui('getLotteryResults');
    render(Array.isArray(results) ? results : []);
  } catch (_) {
    resultCount.textContent = '!';
    resultContainer.innerHTML = '<div class="empty-card"><p>Não foi possível carregar os resultados. Tenta atualizar novamente.</p></div>';
  } finally {
    loading = false;
    refreshButton.disabled = false;
  }
}

refreshButton.addEventListener('click', loadResults);

window.addEventListener('message', event => {
  if (event.data !== 'componentsLoaded') return;
  phoneComponentsReady = true;
  loadResults();
});

if (typeof globalThis.fetchNui === 'function') {
  phoneComponentsReady = true;
  loadResults();
}
