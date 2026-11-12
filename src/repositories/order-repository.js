const { pool } = require('../db/postgres');

async function createOrder(userId, items, paymentMethod) {
  const result = await pool.query(
    'SELECT create_order($1::uuid, $2::jsonb, $3::text) AS order_id',
    [userId, JSON.stringify(items), paymentMethod]
  );
  return result.rows[0].order_id;
}

async function findOrderById(orderId) {
  const result = await pool.query(
    `SELECT o.id, o.user_id, o.status, o.total, o.created_at,
            p.method AS payment_method, p.status AS payment_status,
            COALESCE(json_agg(json_build_object(
              'productId', oi.product_id,
              'quantity', oi.quantity,
              'unitPrice', oi.unit_price
            ) ORDER BY oi.id) FILTER (WHERE oi.id IS NOT NULL), '[]') AS items
       FROM orders o
       LEFT JOIN payments p ON p.order_id = o.id
       LEFT JOIN order_items oi ON oi.order_id = o.id
      WHERE o.id = $1
      GROUP BY o.id, p.method, p.status`,
    [orderId]
  );
  return result.rows[0] || null;
}

async function listProductIds(orderId) {
  const result = await pool.query(
    'SELECT DISTINCT product_id FROM order_items WHERE order_id = $1',
    [orderId]
  );
  return result.rows.map((row) => row.product_id);
}

module.exports = { createOrder, findOrderById, listProductIds };
