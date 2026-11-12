const orderService = require('../services/order-service');

async function checkout(req, res) {
  const order = await orderService.checkout(req.params.userId, req.body);
  res.status(201).json(order);
}

async function getOrder(req, res) {
  res.json(await orderService.getOrder(req.params.id));
}

module.exports = { checkout, getOrder };
