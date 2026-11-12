const express = require('express');
const { pool } = require('../db/postgres');
const { db } = require('../db/mongo');
const productController = require('../controllers/product-controller');
const cartController = require('../controllers/cart-controller');
const orderController = require('../controllers/order-controller');
const { requireUuid } = require('../utils/validation');

const router = express.Router();

const asyncRoute = (handler) => (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
const uuidParam = (name) => (req, res, next) => {
  try {
    requireUuid(req.params[name], name);
    next();
  } catch (error) {
    next(error);
  }
};

router.get('/health', asyncRoute(async (req, res) => {
  const [postgres, mongo] = await Promise.all([
    pool.query('SELECT 1 AS ok'),
    db().command({ ping: 1 })
  ]);
  res.json({ status: 'ok', postgres: postgres.rows[0].ok === 1, mongo: mongo.ok === 1 });
}));

router.get('/products/:id', uuidParam('id'), asyncRoute(productController.getProduct));
router.put('/products/:id/core', uuidParam('id'), asyncRoute(productController.updateProduct));
router.put('/products/:id/catalog', uuidParam('id'), asyncRoute(productController.updateCatalog));
router.delete('/products/:id/cache', uuidParam('id'), asyncRoute(productController.invalidateCache));

router.get('/carts/:userId', uuidParam('userId'), asyncRoute(cartController.getCart));
router.put('/carts/:userId', uuidParam('userId'), asyncRoute(cartController.saveCart));

router.post('/users/:userId/checkout', uuidParam('userId'), asyncRoute(orderController.checkout));
router.get('/orders/:id', uuidParam('id'), asyncRoute(orderController.getOrder));

module.exports = router;
