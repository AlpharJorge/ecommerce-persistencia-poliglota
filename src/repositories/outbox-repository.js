const { pool, withTransaction } = require('../db/postgres');

async function claimBatch(limit) {
  return withTransaction(async (client) => {
    const result = await client.query(
      `SELECT id, payload
         FROM sync_outbox
        WHERE processed_at IS NULL AND available_at <= now()
        ORDER BY id
        FOR UPDATE SKIP LOCKED
        LIMIT $1`,
      [limit]
    );
    if (result.rows.length) {
      await client.query(
        'UPDATE sync_outbox SET attempts = attempts + 1 WHERE id = ANY($1::bigint[])',
        [result.rows.map((row) => row.id)]
      );
    }
    return result.rows;
  });
}

async function markProcessed(id) {
  await pool.query(
    'UPDATE sync_outbox SET processed_at = now(), last_error = NULL WHERE id = $1',
    [id]
  );
}

async function markFailed(id, error) {
  await pool.query(
    `UPDATE sync_outbox
        SET last_error = $2,
            available_at = now() + (LEAST(attempts, 10) * interval '5 seconds')
      WHERE id = $1`,
    [id, String(error.message || error).slice(0, 2000)]
  );
}

module.exports = { claimBatch, markProcessed, markFailed };
