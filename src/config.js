require('dotenv').config();

function positiveInteger(name, fallback) {
  const value = Number(process.env[name] ?? fallback);
  if (!Number.isInteger(value) || value <= 0) {
    throw new Error(`${name} deve ser um inteiro positivo`);
  }
  return value;
}

module.exports = {
  port: positiveInteger('PORT', 3000),
  postgresUrl: process.env.POSTGRES_URL || 'postgresql://ecommerce:ecommerce@localhost:5432/ecommerce',
  mongoUrl: process.env.MONGO_URL || 'mongodb://localhost:27017',
  mongoDb: process.env.MONGO_DB || 'ecommerce',
  cacheTtlSeconds: positiveInteger('CACHE_TTL_SECONDS', 600),
  cartTtlHours: positiveInteger('CART_TTL_HOURS', 24),
  outboxIntervalMs: positiveInteger('OUTBOX_INTERVAL_MS', 2000),
  outboxBatchSize: positiveInteger('OUTBOX_BATCH_SIZE', 50)
};
