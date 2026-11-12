const { pool } = require('../db/postgres');
const { db } = require('../db/mongo');

async function findCoreById(productId, queryable = pool) {
  const result = await queryable.query(
    `SELECT p.id, p.sku, p.name, p.price, p.stock, p.active, p.updated_at,
            c.id AS category_id, c.name AS category_name
       FROM products p
       JOIN categories c ON c.id = p.category_id
      WHERE p.id = $1`,
    [productId]
  );
  return result.rows[0] || null;
}

async function updateCore(productId, changes, queryable) {
  const fields = [];
  const values = [];
  for (const [column, value] of Object.entries(changes)) {
    values.push(value);
    fields.push(`${column} = $${values.length}`);
  }
  values.push(productId);
  const result = await queryable.query(
    `UPDATE products SET ${fields.join(', ')} WHERE id = $${values.length} RETURNING *`,
    values
  );
  return result.rows[0] || null;
}

async function findCatalog(productId) {
  return db().collection('product_catalog').findOne(
    { productId },
    { projection: { _id: 0 } }
  );
}

async function upsertCatalog(productId, catalog) {
  await db().collection('product_catalog').updateOne(
    { productId },
    { $set: { productId, ...catalog, updatedAt: new Date() } },
    { upsert: true }
  );
  return findCatalog(productId);
}

async function findPageCache(productId) {
  return db().collection('page_cache').findOne(
    { productId, expiresAt: { $gt: new Date() } },
    { projection: { _id: 0 } }
  );
}

async function setPageCache(productId, page, ttlSeconds) {
  await db().collection('page_cache').updateOne(
    { productId },
    {
      $set: {
        productId,
        page,
        cachedAt: new Date(),
        expiresAt: new Date(Date.now() + ttlSeconds * 1000)
      }
    },
    { upsert: true }
  );
}

async function invalidatePageCache(productId) {
  await db().collection('page_cache').deleteOne({ productId });
}

async function applyCoreSnapshot(snapshot) {
  await db().collection('product_catalog').updateOne(
    { productId: String(snapshot.productId) },
    {
      $set: {
        productId: String(snapshot.productId),
        coreSnapshot: {
          price: Number(snapshot.price),
          stock: Number(snapshot.stock),
          active: Boolean(snapshot.active),
          updatedAt: new Date(snapshot.updatedAt)
        }
      },
      $setOnInsert: { description: '', specifications: {}, images: [] }
    },
    { upsert: true }
  );
  await invalidatePageCache(String(snapshot.productId));
}

module.exports = {
  findCoreById,
  updateCore,
  findCatalog,
  upsertCatalog,
  findPageCache,
  setPageCache,
  invalidatePageCache,
  applyCoreSnapshot
};
