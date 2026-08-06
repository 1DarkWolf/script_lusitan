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

function scratch(event) {
  if (!drawing || completed) return;
  const bounds = canvas.getBoundingClientRect();
  const x = (event.clientX - bounds.left) * (canvas.width / bounds.width);
  const y = (event.clientY - bounds.top) * (canvas.height / bounds.height);
  context.beginPath();
  context.arc(x, y, 18, 0, Math.PI * 2);
  context.fill();
  const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
  let clear = 0;
  for (let index = 3; index < pixels.length; index += 4) if (pixels[index] === 0) clear++;
  if (clear / (canvas.width * canvas.height) >= .5) {
    completed = true;
    drawing = false;
    status.textContent = 'A validar o bilhete…';
    post('scratchComplete');
  }
}

canvas.addEventListener('pointerdown', event => { drawing = true; canvas.setPointerCapture(event.pointerId); scratch(event); });
canvas.addEventListener('pointermove', scratch);
canvas.addEventListener('pointerup', () => { drawing = false; });
document.getElementById('close').addEventListener('click', () => { app.classList.add('hidden'); post('closeScratch'); });
finish.addEventListener('click', () => { app.classList.add('hidden'); post('closeScratch'); });

window.addEventListener('message', ({ data }) => {
  if (data.action === 'openScratch') {
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
