INSERT INTO users (id, name, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Camila Compradora', 'camila@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'Rafael Estoque', 'rafael@example.com')
ON CONFLICT (id) DO NOTHING;

INSERT INTO categories (id, name) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Eletronicos'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Moda')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, category_id, sku, name, price, stock) VALUES
  ('10000000-0000-0000-0000-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'PHONE-128-BLK', 'Smartphone 128 GB', 1999.90, 25),
  ('10000000-0000-0000-0000-000000000002', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'TSHIRT-M-BLU', 'Camiseta Azul M', 79.90, 50),
  ('10000000-0000-0000-0000-000000000003', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'HEADSET-BT', 'Headset Bluetooth', 249.90, 1)
ON CONFLICT (id) DO NOTHING;
