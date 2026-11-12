const { Pool } = require('pg');
const config = require('../src/config');

const pool = new Pool({ connectionString: config.postgresUrl });

async function seed() {
  console.log('Gerando dados de benchmark...');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(`
      INSERT INTO users(id, name, email)
      SELECT gen_random_uuid(), 'Cliente Benchmark ' || n, 'benchmark' || n || '@example.com'
        FROM generate_series(1, 1000) AS n
      ON CONFLICT (email) DO NOTHING
    `);

    await client.query(`
      INSERT INTO products(id, category_id, sku, name, price, stock)
      VALUES (
        '10000000-0000-0000-0000-000000000099',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'BENCHMARK-PRODUCT', 'Produto de Benchmark', 49.90, 1000000
      )
      ON CONFLICT (id) DO NOTHING
    `);

    const existing = await client.query(`
      SELECT count(*)::int AS total
      FROM orders o JOIN users u ON u.id = o.user_id
      WHERE u.email LIKE 'benchmark%@example.com'
    `);
    const missing = Math.max(0, 100000 - existing.rows[0].total);

    await client.query(`
      CREATE TEMP TABLE new_benchmark_orders (
        id UUID PRIMARY KEY,
        user_id UUID NOT NULL,
        total NUMERIC(14,2) NOT NULL,
        created_at TIMESTAMPTZ NOT NULL
      ) ON COMMIT DROP
    `);
    await client.query(`
      INSERT INTO new_benchmark_orders(id, user_id, total, created_at)
      SELECT gen_random_uuid(), u.id, (10 + random() * 990)::numeric(14,2),
             now() - (random() * interval '365 days')
        FROM generate_series(1, $1) AS n
        CROSS JOIN LATERAL (
          SELECT id FROM users WHERE email LIKE 'benchmark%@example.com'
          ORDER BY email OFFSET (n % 1000) LIMIT 1
        ) AS u
    `, [missing]);
    await client.query(`
      INSERT INTO orders(id, user_id, status, total, created_at)
      SELECT id, user_id, 'paid', total, created_at FROM new_benchmark_orders
    `);

    // Dados sinteticos de benchmark nao devem consumir estoque nem gerar 100 mil eventos.
    await client.query('ALTER TABLE order_items DISABLE TRIGGER trg_order_item_stock');
    await client.query(`
      INSERT INTO order_items(order_id, product_id, quantity, unit_price)
      SELECT id, '10000000-0000-0000-0000-000000000099', 1, total
      FROM new_benchmark_orders
    `);
    await client.query('ALTER TABLE order_items ENABLE TRIGGER trg_order_item_stock');
    await client.query(`
      INSERT INTO payments(order_id, method, status, amount, paid_at)
      SELECT id, 'pix', 'approved', total, created_at FROM new_benchmark_orders
    `);
    await client.query('COMMIT');
    const count = await client.query(`
      SELECT count(DISTINCT o.id) AS orders, count(oi.id) AS items
      FROM orders o
      JOIN users u ON u.id = o.user_id
      JOIN order_items oi ON oi.order_id = o.id
      WHERE u.email LIKE 'benchmark%@example.com'
    `);
    console.log(`Concluido: ${count.rows[0].orders} pedidos e ${count.rows[0].items} itens de benchmark.`);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

seed().catch((error) => {
  console.error(error);
  process.exit(1);
});
