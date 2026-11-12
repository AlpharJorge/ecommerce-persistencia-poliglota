const { performance } = require('node:perf_hooks');

const baseUrl = process.env.API_URL || 'http://localhost:3000/api';
const productId = process.env.PRODUCT_ID || '10000000-0000-0000-0000-000000000001';
const total = Number(process.env.TOTAL_REQUESTS || 500);
const concurrency = Number(process.env.CONCURRENCY || 25);

function percentile(values, fraction) {
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * fraction))];
}

async function timedGet() {
  const started = performance.now();
  const response = await fetch(`${baseUrl}/products/${productId}`);
  const body = await response.json();
  if (!response.ok) throw new Error(`${response.status}: ${JSON.stringify(body)}`);
  return { duration: performance.now() - started, source: body.source };
}

async function runLoad() {
  const invalidated = await fetch(`${baseUrl}/products/${productId}/cache`, { method: 'DELETE' });
  if (!invalidated.ok) throw new Error(`Falha ao invalidar cache: HTTP ${invalidated.status}`);

  const cold = await timedGet();
  await timedGet();

  let cursor = 0;
  const durations = [];
  const sources = { cache: 0, database: 0 };
  const started = performance.now();

  async function worker() {
    while (true) {
      const current = cursor++;
      if (current >= total) return;
      const result = await timedGet();
      durations.push(result.duration);
      sources[result.source] = (sources[result.source] || 0) + 1;
    }
  }

  await Promise.all(Array.from({ length: concurrency }, worker));
  const elapsedSeconds = (performance.now() - started) / 1000;

  console.table([{
    requisicoes: total,
    concorrencia: concurrency,
    requisicoes_por_segundo: (total / elapsedSeconds).toFixed(2),
    latencia_fria_ms: cold.duration.toFixed(2),
    p50_quente_ms: percentile(durations, 0.50).toFixed(2),
    p95_quente_ms: percentile(durations, 0.95).toFixed(2),
    p99_quente_ms: percentile(durations, 0.99).toFixed(2),
    respostas_cache: sources.cache,
    respostas_banco: sources.database
  }]);
}

runLoad().catch((error) => {
  console.error(error);
  process.exit(1);
});
