const cartService = require('../services/cart-service');

async function getCart(req, res) {
  res.json(await cartService.getCart(req.params.userId));
}

async function saveCart(req, res) {
  res.json(await cartService.saveCart(req.params.userId, req.body.items));
}

module.exports = { getCart, saveCart };
