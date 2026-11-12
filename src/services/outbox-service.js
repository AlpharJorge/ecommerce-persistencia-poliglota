const config = require('../config');
const outboxRepository = require('../repositories/outbox-repository');
const productRepository = require('../repositories/product-repository');

let timer;
let running = false;

async function processOutbox() {
  if (running) return;
  running = true;
  try {
    const events = await outboxRepository.claimBatch(config.outboxBatchSize);
    for (const event of events) {
      try {
        await productRepository.applyCoreSnapshot(event.payload);
        await outboxRepository.markProcessed(event.id);
      } catch (error) {
        await outboxRepository.markFailed(event.id, error);
      }
    }
  } catch (error) {
    console.error('Falha ao processar outbox', error);
  } finally {
    running = false;
  }
}

function startOutboxWorker() {
  if (timer) return;
  processOutbox();
  timer = setInterval(processOutbox, config.outboxIntervalMs);
  timer.unref();
}

function stopOutboxWorker() {
  if (timer) clearInterval(timer);
  timer = undefined;
}

module.exports = { processOutbox, startOutboxWorker, stopOutboxWorker };
