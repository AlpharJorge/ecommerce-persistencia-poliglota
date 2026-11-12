const config = require('../config');
const { withTransaction } = require('../db/postgres');
const productRepository = require('../repositories/product-repository');
const { HttpError } = require('../utils/http-error');
const { requireMoney } = require('../utils/validation');

function snapshotFromCore(core) {
  return {
    productId: core.id,
    price: core.price,
    stock: core.stock,
    active: core.active,
    updatedAt: core.updated_at
  };
}

async function getProductPage(productId) {
  const cached = await productRepository.findPageCache(productId);
  if (cached) return { source: 'cache', ...cached.page };

  const [core, catalog] = await Promise.all([
    productRepository.findCoreById(productId),
    productRepository.findCatalog(productId)
  ]);
  if (!core || !core.active) throw new HttpError(404, 'Produto nao encontrado');

  const page = {
    id: core.id,
    sku: core.sku,
    name: core.name,
    price: Number(core.price),
    stock: core.stock,
    category: { id: core.category_id, name: core.category_name },
    description: catalog?.description || '',
    images: catalog?.images || [],
    specifications: catalog?.specifications || {},
    updatedAt: core.updated_at
  };
  await productRepository.setPageCache(productId, page, config.cacheTtlSeconds);
  return { source: 'database', ...page };
}

async function updateProductCore(productId, input) {
  const changes = {};
  if (input.price !== undefined) changes.price = requireMoney(input.price, 'price');
  if (input.stock !== undefined) {
    const stock = Number(input.stock);
    if (!Number.isInteger(stock) || stock < 0) {
      throw new HttpError(400, 'stock deve ser um inteiro nao negativo');
    }
    changes.stock = stock;
  }
  if (input.active !== undefined) {
    if (typeof input.active !== 'boolean') throw new HttpError(400, 'active deve ser booleano');
    changes.active = input.active;
  }
  if (!Object.keys(changes).length) {
    throw new HttpError(400, 'Informe ao menos price, stock ou active');
  }

  const updated = await withTransaction(async (client) => {
    const row = await productRepository.updateCore(productId, changes, client);
    if (!row) throw new HttpError(404, 'Produto nao encontrado');
    return row;
  });

  // Tentativa sincrona de Write-Through; o outbox transacional garante nova tentativa.
  try {
    await productRepository.applyCoreSnapshot(snapshotFromCore(updated));
  } catch (error) {
    console.warn('Write-Through imediato falhou; o outbox tentara novamente', error.message);
  }
  return updated;
}

async function updateCatalog(productId, input) {
  const core = await productRepository.findCoreById(productId);
  if (!core) throw new HttpError(404, 'Produto nao encontrado no PostgreSQL');
  if (typeof input.description !== 'string') {
    throw new HttpError(400, 'description e obrigatoria');
  }
  if (input.images !== undefined && !Array.isArray(input.images)) {
    throw new HttpError(400, 'images deve ser uma lista');
  }
  if (input.specifications !== undefined && (typeof input.specifications !== 'object' || Array.isArray(input.specifications))) {
    throw new HttpError(400, 'specifications deve ser um objeto');
  }
  const catalog = await productRepository.upsertCatalog(productId, {
    description: input.description,
    images: input.images || [],
    specifications: input.specifications || {},
    coreSnapshot: {
      price: Number(core.price), stock: core.stock, active: core.active, updatedAt: core.updated_at
    }
  });
  await productRepository.invalidatePageCache(productId);
  return catalog;
}

async function invalidateProductCache(productId) {
  await productRepository.invalidatePageCache(productId);
}

module.exports = {
  getProductPage,
  updateProductCore,
  updateCatalog,
  invalidateProductCache,
  snapshotFromCore
};
