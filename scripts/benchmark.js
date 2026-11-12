const { Pool } = require('pg');
const config = require('../src/config');

const pool = new Pool({ connectionString: config.postgresUrl });

function executionTime(plan) {
  const root = plan[0]['Execution Time'];
  return Number(root).toFixed(3);
}

async function explain(client, userId) {
  const result = await client.query(
    `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
     SELECT id, status, total, created_at
       FROM orders
      WHERE user_id = $1
      ORDER BY created_at DESC
      LIMIT 50`,
    [userId]
  );
  return result.rows[0]['QUERY PLAN'];
}

async function benchmark() {
  const client = await pool.connect();
  try {
    const user = await client.query(
      "SELECT id FROM users WHERE email LIKE 'benchmark%@example.com' ORDER BY email LIMIT 1"
    );
    if (!user.rowCount) throw new Error('Execute npm run seed antes do benchmark');

    await client.query('DROP INDEX IF EXISTS idx_orders_user_created_at');
    const withoutIndex = await explain(client, user.rows[0].id);

    await client.query('CREATE INDEX idx_orders_user_created_at ON orders(user_id, created_at DESC)');
    await client.query('ANALYZE orders');
    const withIndex = await explain(client, user.rows[0].id);

    console.table([
      { cenario: 'Sem indice', tempo_ms: executionTime(withoutIndex) },
      { cenario: 'Com indice', tempo_ms: executionTime(withIndex) }
    ]);
    console.log('\nPlano sem indice:\n', JSON.stringify(withoutIndex, null, 2));
    console.log('\nPlano com indice:\n', JSON.stringify(withIndex, null, 2));
  } finally {
    await client.query('CREATE INDEX IF NOT EXISTS idx_orders_user_created_at ON orders(user_id, created_at DESC)');
    client.release();
    await pool.end();
  }
}

benchmark().catch((error) => {
  console.error(error);
  process.exit(1);
});
