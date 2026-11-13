const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeItems,
  requireUuid,
  requireMoney,
  requireStockDelta
} = require('../src/utils/validation');

test('combina produtos repetidos no pedido', () => {
  const id = '10000000-0000-0000-0000-000000000001';
  assert.deepEqual(normalizeItems([
    { productId: id, quantity: 2 },
    { productId: id, quantity: 3 }
  ]), [{ productId: id, quantity: 5 }]);
});

test('recusa quantidade negativa', () => {
  assert.throws(() => normalizeItems([
    { productId: '10000000-0000-0000-0000-000000000001', quantity: -1 }
  ]), /quantity/);
});

test('valida UUID e dinheiro', () => {
  assert.equal(requireUuid('10000000-0000-0000-0000-000000000001', 'id'), '10000000-0000-0000-0000-000000000001');
  assert.equal(requireMoney('19.9', 'price'), '19.90');
  assert.throws(() => requireUuid('invalido', 'id'), /UUID/);
});

test('valida ajuste de estoque', () => {
  assert.equal(requireStockDelta(5), 5);
  assert.equal(requireStockDelta(-3), -3);

  assert.throws(() => requireStockDelta(0), /delta/);
  assert.throws(() => requireStockDelta(1.5), /delta/);
  assert.throws(() => requireStockDelta('texto'), /delta/);
});