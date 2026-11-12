CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE order_status AS ENUM ('pending', 'paid', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'approved', 'declined', 'refunded');
CREATE TYPE movement_type AS ENUM ('sale', 'restock', 'adjustment');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL CHECK (length(trim(name)) >= 2),
  email TEXT NOT NULL UNIQUE CHECK (email LIKE '%@%'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE CHECK (length(trim(name)) >= 2)
);

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  sku TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  active BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  status order_status NOT NULL DEFAULT 'pending',
  total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
  id BIGSERIAL PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
  UNIQUE (order_id, product_id)
);

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
  method TEXT NOT NULL CHECK (method IN ('pix', 'credit_card', 'debit_card', 'boleto')),
  status payment_status NOT NULL DEFAULT 'approved',
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  paid_at TIMESTAMPTZ
);

CREATE TABLE inventory_movements (
  id BIGSERIAL PRIMARY KEY,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  order_item_id BIGINT REFERENCES order_items(id) ON DELETE SET NULL,
  movement movement_type NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity <> 0),
  stock_after INTEGER NOT NULL CHECK (stock_after >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sync_outbox (
  id BIGSERIAL PRIMARY KEY,
  aggregate_type TEXT NOT NULL,
  aggregate_id UUID NOT NULL,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  available_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_user_created_at ON orders(user_id, created_at DESC);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_inventory_product_created ON inventory_movements(product_id, created_at DESC);
CREATE INDEX idx_outbox_pending ON sync_outbox(available_at, id) WHERE processed_at IS NULL;

CREATE OR REPLACE FUNCTION touch_product_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_products_touch
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION touch_product_updated_at();

CREATE OR REPLACE FUNCTION reserve_stock_and_audit()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  remaining INTEGER;
BEGIN
  UPDATE products
     SET stock = stock - NEW.quantity
   WHERE id = NEW.product_id
     AND active = true
     AND stock >= NEW.quantity
  RETURNING stock INTO remaining;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Estoque insuficiente para o produto %', NEW.product_id
      USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO inventory_movements(product_id, order_item_id, movement, quantity, stock_after)
  VALUES (NEW.product_id, NEW.id, 'sale', -NEW.quantity, remaining);
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_order_item_stock
AFTER INSERT ON order_items
FOR EACH ROW EXECUTE FUNCTION reserve_stock_and_audit();

CREATE OR REPLACE FUNCTION enqueue_product_snapshot()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO sync_outbox(aggregate_type, aggregate_id, event_type, payload)
  VALUES (
    'product', NEW.id, 'product.snapshot.changed',
    jsonb_build_object(
      'productId', NEW.id,
      'price', NEW.price,
      'stock', NEW.stock,
      'active', NEW.active,
      'updatedAt', NEW.updated_at
    )
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_product_outbox
AFTER INSERT OR UPDATE OF price, stock, active ON products
FOR EACH ROW EXECUTE FUNCTION enqueue_product_snapshot();

CREATE OR REPLACE FUNCTION create_order(
  p_user_id UUID,
  p_items JSONB,
  p_payment_method TEXT DEFAULT 'pix'
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
  v_order_id UUID;
  v_item JSONB;
  v_product products%ROWTYPE;
  v_total NUMERIC(14,2) := 0;
  v_quantity INTEGER;
BEGIN
  IF jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'O pedido deve conter ao menos um item' USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
    RAISE EXCEPTION 'Usuario inexistente' USING ERRCODE = '23503';
  END IF;

  IF p_payment_method NOT IN ('pix', 'credit_card', 'debit_card', 'boleto') THEN
    RAISE EXCEPTION 'Metodo de pagamento invalido' USING ERRCODE = '22023';
  END IF;

  INSERT INTO orders(user_id) VALUES (p_user_id) RETURNING id INTO v_order_id;

  -- Ordem deterministica de bloqueio reduz o risco de deadlock entre pedidos multi-item.
  FOR v_item IN
    SELECT value FROM jsonb_array_elements(p_items) ORDER BY value->>'productId'
  LOOP
    v_quantity := (v_item->>'quantity')::INTEGER;
    IF v_quantity IS NULL OR v_quantity <= 0 THEN
      RAISE EXCEPTION 'Quantidade invalida' USING ERRCODE = '22023';
    END IF;

    SELECT * INTO v_product
      FROM products
     WHERE id = (v_item->>'productId')::UUID
       AND active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Produto inexistente ou inativo: %', v_item->>'productId'
        USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO order_items(order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, v_product.id, v_quantity, v_product.price);
    v_total := v_total + (v_product.price * v_quantity);
  END LOOP;

  UPDATE orders SET total = v_total, status = 'paid' WHERE id = v_order_id;
  INSERT INTO payments(order_id, method, status, amount, paid_at)
  VALUES (v_order_id, p_payment_method, 'approved', v_total, now());

  RETURN v_order_id;
END;
$$;

CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
  o.id AS order_id,
  o.created_at,
  o.status,
  u.id AS user_id,
  u.name AS customer_name,
  u.email,
  count(oi.id) AS distinct_items,
  sum(oi.quantity) AS units,
  o.total,
  p.method AS payment_method,
  p.status AS payment_status
FROM orders o
JOIN users u ON u.id = o.user_id
JOIN order_items oi ON oi.order_id = o.id
LEFT JOIN payments p ON p.order_id = o.id
GROUP BY o.id, u.id, p.method, p.status;
