const { Pool } = require('pg');
const config = require('../config');

const pool = new Pool({ connectionString: config.postgresUrl, max: 20 });

pool.on('error', (error) => {
  console.error('Erro inesperado no pool PostgreSQL', error);
});

async function withTransaction(work) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await work(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = { pool, withTransaction };
