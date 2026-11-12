const { HttpError } = require('../utils/http-error');

function notFound(req, res) {
  res.status(404).json({ error: 'Rota nao encontrada' });
}

function errorHandler(error, req, res, next) {
  if (res.headersSent) return next(error);

  if (error instanceof HttpError) {
    return res.status(error.status).json({ error: error.message, details: error.details });
  }

  const pgMap = {
    '22P02': [400, 'Formato de dado invalido'],
    '22023': [400, error.message],
    '23503': [400, 'Referencia inexistente'],
    '23505': [409, 'Registro duplicado'],
    P0001: [409, error.message],
    P0002: [404, error.message]
  };
  if (error?.code && pgMap[error.code]) {
    const [status, message] = pgMap[error.code];
    return res.status(status).json({ error: message });
  }

  console.error(error);
  res.status(500).json({ error: 'Erro interno' });
}

module.exports = { notFound, errorHandler };
