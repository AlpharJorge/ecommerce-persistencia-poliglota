const productService = require('../services/product-service');

async function getProduct(req, res) {
  res.json(await productService.getProductPage(req.params.id));
}

async function updateProduct(req, res) {
  res.json(await productService.updateProductCore(req.params.id, req.body));
}

async function updateCatalog(req, res) {
  res.json(await productService.updateCatalog(req.params.id, req.body));
}

async function invalidateCache(req, res) {
  await productService.invalidateProductCache(req.params.id);
  res.status(204).end();
}

module.exports = { getProduct, updateProduct, updateCatalog, invalidateCache };
