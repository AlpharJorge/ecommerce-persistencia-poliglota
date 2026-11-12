const { MongoClient } = require('mongodb');

const mongoUrl = process.env.MONGO_URL || 'mongodb://127.0.0.1:27017';
const databaseName = process.env.MONGO_DB || 'ecommerce';

const products = [
  {
    productId: '10000000-0000-0000-0000-000000000001',
    description: 'Smartphone com tela AMOLED e conectividade 5G.',
    images: ['https://example.invalid/phone-front.jpg'],
    specifications: { ram: '8 GB', storage: '128 GB', color: 'Preto' }
  },
  {
    productId: '10000000-0000-0000-0000-000000000002',
    description: 'Camiseta de algodao com corte regular.',
    images: ['https://example.invalid/tshirt-blue.jpg'],
    specifications: { size: 'M', color: 'Azul', material: 'Algodao' }
  },
  {
    productId: '10000000-0000-0000-0000-000000000003',
    description: 'Headset sem fio com microfone e cancelamento de ruido.',
    images: ['https://example.invalid/headset.jpg'],
    specifications: { connection: 'Bluetooth 5.3', battery: '30 h' }
  }
];

async function ensureCollection(db, name, options = {}) {
  const exists = await db.listCollections({ name }, { nameOnly: true }).hasNext();
  if (!exists) await db.createCollection(name, options);
}

async function main() {
  const client = new MongoClient(mongoUrl);
  try {
    await client.connect();
    const db = client.db(databaseName);
    await ensureCollection(db, 'product_catalog', {
      validator: {
        $jsonSchema: {
          bsonType: 'object',
          required: ['productId', 'description', 'specifications'],
          properties: {
            productId: { bsonType: 'string' },
            description: { bsonType: 'string' },
            images: { bsonType: 'array', items: { bsonType: 'string' } },
            specifications: { bsonType: 'object' },
            coreSnapshot: { bsonType: 'object' }
          }
        }
      }
    });
    await ensureCollection(db, 'carts');
    await ensureCollection(db, 'page_cache');

    await db.collection('product_catalog').createIndex({ productId: 1 }, { unique: true });
    await db.collection('carts').createIndex({ userId: 1 }, { unique: true });
    await db.collection('carts').createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    await db.collection('page_cache').createIndex({ productId: 1 }, { unique: true });
    await db.collection('page_cache').createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

    for (const product of products) {
      await db.collection('product_catalog').updateOne(
        { productId: product.productId },
        { $setOnInsert: product },
        { upsert: true }
      );
    }
    console.log('MongoDB inicializado com colecoes, indices TTL e catalogo de exemplo.');
  } finally {
    await client.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
