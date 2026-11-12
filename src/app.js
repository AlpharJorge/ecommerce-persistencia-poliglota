const express = require('express');
const path = require('node:path');
const routes = require('./routes');
const { notFound, errorHandler } = require('./middleware/error-handler');

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '1mb' }));
app.use(express.static(path.join(__dirname, '..', 'public')));
app.use('/api', routes);
app.use(notFound);
app.use(errorHandler);

module.exports = app;
