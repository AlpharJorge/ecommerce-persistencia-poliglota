const { MongoClient } = require('mongodb');
const config = require('../config');

const client = new MongoClient(config.mongoUrl, { maxPoolSize: 20 });
let database;

async function connectMongo() {
  if (!database) {
    await client.connect();
    database = client.db(config.mongoDb);
  }
  return database;
}

function db() {
  if (!database) throw new Error('MongoDB ainda nao foi conectado');
  return database;
}

async function closeMongo() {
  await client.close();
  database = undefined;
}

module.exports = { connectMongo, db, closeMongo };
