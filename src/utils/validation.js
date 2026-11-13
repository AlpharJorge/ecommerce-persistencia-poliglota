const { HttpError } = require('./http-error');

// PostgreSQL aceita UUIDs no formato hexadecimal mesmo sem bits RFC de versao/variante.
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function requireUuid(value, field) {
  if (typeof value !== 'string' || !UUID_PATTERN.test(value)) {
    throw new HttpError(400, `${field} deve ser um UUID valido`);
  }
  return value;
}

function normalizeItems(items) {
  if (!Array.isArray(items) || items.length === 0) {
    throw new HttpError(400, 'items deve ser uma lista nao vazia');
  }
  const combined = new Map();
  for (const item of items) {
    const productId = requireUuid(item?.productId, 'productId');
    const quantity = Number(item?.quantity);
    if (!Number.isInteger(quantity) || quantity <= 0 || quantity > 1000) {
      throw new HttpError(400, 'quantity deve ser um inteiro entre 1 e 1000');
    }
    combined.set(productId, (combined.get(productId) || 0) + quantity);
  }
  return [...combined.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([productId, quantity]) => ({ productId, quantity }));
}

function requireMoney(value, field) {
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0) {
    throw new HttpError(400, `${field} deve ser um valor nao negativo`);
  }
  return number.toFixed(2);
}

function requireStockDelta(value) {
  const delta = Number(value);

  if (!Number.isInteger(delta) || delta === 0) {
    throw new HttpError(400, 'delta deve ser um inteiro diferente de zero');
  }

  return delta;
}

module.exports = {
  requireUuid,
  normalizeItems,
  requireMoney,
  requireStockDelta
};
