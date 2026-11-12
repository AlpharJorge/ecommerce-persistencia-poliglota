const app = require('./app');
const config = require('./config');
const { pool } = require('./db/postgres');
const { connectMongo, closeMongo } = require('./db/mongo');
const { startOutboxWorker, stopOutboxWorker } = require('./services/outbox-service');

let server;

async function start() {
  await Promise.all([pool.query('SELECT 1'), connectMongo()]);
  startOutboxWorker();
  server = app.listen(config.port, () => {
    console.log(`API disponivel em http://localhost:${config.port}/api`);
  });
}

async function shutdown(signal) {
  console.log(`${signal} recebido; encerrando...`);
  stopOutboxWorker();
  if (server) await new Promise((resolve) => server.close(resolve));
  await Promise.allSettled([pool.end(), closeMongo()]);
  process.exit(0);
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

start().catch((error) => {
  console.error('Nao foi possivel iniciar a API', error);
  process.exit(1);
});
