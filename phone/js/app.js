const resultContainer = document.getElementById('results');
const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[character]));
const balls = (numbers, kind = '') => `<div class="balls">${(numbers || []).map(number => `<span class="ball ${kind}">${escapeHtml(number)}</span>`).join('')}</div>`;

function entry(label, content) {
  return `<p class="label">${escapeHtml(label)}</p>${content}`;
}

function resultDetails(result) {
  if (result.game_id === 'euromillions') return entry('Números', balls(result.numbers)) + entry('Estrelas', balls(result.stars, 'special'));
  if (result.game_id === 'totoloto') return entry('Números', balls(result.numbers)) + entry('Número da sorte', balls([result.luckyNumber], 'special'));
  if (result.game_id === 'eurodreams') return entry('Números', balls(result.numbers)) + entry('Número Dream', balls([result.dreamNumber], 'dream'));
  if (result.game_id === 'joker') return entry('Código Joker', `<span class="code">${escapeHtml(result.code)}</span>`);
  return entry('Número vencedor', `<span class="code">${escapeHtml(result.number)}</span>`);
}

function render(results) {
  if (!results.length) {
    resultContainer.innerHTML = '<p class="empty">Ainda não existem resultados publicados.</p>';
    return;
  }

  resultContainer.innerHTML = results.map(row => `<article class="result"><h2>${escapeHtml(row.label)}</h2><p class="date">${escapeHtml(row.drawn_at)}</p>${resultDetails(row.result || {})}</article>`).join('');
}

async function loadResults() {
  resultContainer.innerHTML = '<p class="empty">A atualizar resultados...</p>';
  try {
    const results = await fetchNui('getLotteryResults');
    render(Array.isArray(results) ? results : []);
  } catch (_) {
    resultContainer.innerHTML = '<p class="empty">Não foi possível carregar os resultados.</p>';
  }
}

document.getElementById('refresh').addEventListener('click', loadResults);
loadResults();
