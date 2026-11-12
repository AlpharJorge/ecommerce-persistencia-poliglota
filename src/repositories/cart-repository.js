const { db } = require('../db/mongo');

async function getCart(userId) {
  return db().collection('carts').findOne({ userId }, { projection: { _id: 0 } });
}

async function saveCart(userId, items, ttlHours) {
  const expiresAt = new Date(Date.now() + ttlHours * 60 * 60 * 1000);
  await db().collection('carts').updateOne(
    { userId },
    { $set: { userId, items, updatedAt: new Date(), expiresAt } },
    { upsert: true }
  );
  return getCart(userId);
}

async function deleteCart(userId) {
  await db().collection('carts').deleteOne({ userId });
}

module.exports = { getCart, saveCart, deleteCart };
