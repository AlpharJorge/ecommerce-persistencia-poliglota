const orderRepository = require('../repositories/order-repository');
const productRepository = require('../repositories/product-repository');
const cartRepository = require('../repositories/cart-repository');
const { HttpError } = require('../utils/http-error');
const { normalizeItems } = require('../utils/validation');
const { snapshotFromCore } = require('./product-service');

const PAYMENT_METHODS = new Set(['pix', 'credit_card', 'debit_card', 'boleto']);

async function checkout(userId, input) {
  const items = normalizeItems(input.items);
  const paymentMethod = input.paymentMethod || 'pix';
  if (!PAYMENT_METHODS.has(paymentMethod)) {
    throw new HttpError(400, 'paymentMethod invalido');
  }

  const orderId = await orderRepository.createOrder(userId, items, paymentMethod);

  // Reduz a janela de defasagem; o outbox permanece como garantia de recuperacao.
  const productIds = await orderRepository.listProductIds(orderId);
  await Promise.allSettled(productIds.map(async (productId) => {
    const core = await productRepository.findCoreById(productId);
    if (core) await productRepository.applyCoreSnapshot(snapshotFromCore(core));
  }));
  await cartRepository.deleteCart(userId);
  return orderRepository.findOrderById(orderId);
}

async function getOrder(orderId) {
  const order = await orderRepository.findOrderById(orderId);
  if (!order) throw new HttpError(404, 'Pedido nao encontrado');
  return order;
}

module.exports = { checkout, getOrder };
