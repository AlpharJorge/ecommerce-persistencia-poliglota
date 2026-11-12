const config = require('../config');
const cartRepository = require('../repositories/cart-repository');
const { normalizeItems } = require('../utils/validation');

async function getCart(userId) {
  return (await cartRepository.getCart(userId)) || { userId, items: [] };
}

async function saveCart(userId, items) {
  return cartRepository.saveCart(userId, normalizeItems(items), config.cartTtlHours);
}

module.exports = { getCart, saveCart };
