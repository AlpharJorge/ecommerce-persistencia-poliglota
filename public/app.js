const API = '/api';
const USER_ID = '11111111-1111-1111-1111-111111111111';
const PRODUCT_IDS = [
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000002',
  '10000000-0000-0000-0000-000000000003'
];

const state = {
  products: [],
  cart: new Map()
};

const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

async function request(path, options = {}) {
  const response = await fetch(`${API}${path}`, {
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
    ...options
  });
  if (response.status === 204) return null;
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || 'Não foi possível concluir a operação.');
  return data;
}

function setMessage(elementId, text, type = '') {
  const element = document.getElementById(elementId);
  element.textContent = text;
  element.className = `mensagem ${type}`.trim();
}

async function checkHealth() {
  const badge = document.getElementById('status-api');
  try {
    const health = await request('/health');
    badge.innerHTML = '<i></i> online';
    badge.className = 'connection online';
  } catch (error) {
    badge.innerHTML = '<i></i> offline';
    badge.className = 'connection offline';
  }
}

function renderProducts() {
  const container = document.getElementById('lista-produtos');
  if (!state.products.length) {
    container.innerHTML = '<p>Nenhum produto disponível.</p>';
    return;
  }
  container.innerHTML = state.products.map((product) => `
    <article class="produto">
      <span class="produto-categoria">${escapeHtml(product.category.name)}</span>
      <h3>${escapeHtml(product.name)}</h3>
      <p>${escapeHtml(product.description || 'Produto do catálogo de demonstração.')}</p>
      <div class="produto-dados">
        <strong class="produto-preco">${money.format(product.price)}</strong>
        <span class="produto-estoque">${product.stock} unidade(s) em estoque</span>
        <span class="origem">leitura: ${product.source === 'cache' ? 'cache' : 'bancos'}</span>
        <div class="quantidade-linha">
          <input id="qty-${product.id}" type="number" min="1" max="${product.stock}" value="1" aria-label="Quantidade de ${escapeHtml(product.name)}">
          <button class="primary-button adicionar" data-product-id="${product.id}" ${product.stock === 0 ? 'disabled' : ''}>Adicionar</button>
        </div>
      </div>
    </article>
  `).join('');

  const totalStock = state.products.reduce((sum, product) => sum + Number(product.stock), 0);
  const catalogValue = state.products.reduce((sum, product) => sum + (Number(product.price) * Number(product.stock)), 0);
  const cacheReads = state.products.filter((product) => product.source === 'cache').length;
  document.getElementById('total-produtos').textContent = state.products.length;
  document.getElementById('total-estoque').textContent = totalStock.toLocaleString('pt-BR');
  document.getElementById('valor-catalogo').textContent = money.format(catalogValue);
  document.getElementById('status-cache').textContent = cacheReads ? `${cacheReads} via cache` : 'Bancos';
}

async function loadProducts() {
  const container = document.getElementById('lista-produtos');
  container.innerHTML = '<p class="loading">Carregando produtos...</p>';
  try {
    state.products = await Promise.all(PRODUCT_IDS.map((id) => request(`/products/${id}`)));
    renderProducts();
    fillAdminForm();
    renderCart();
  } catch (error) {
    container.innerHTML = `<p>Erro ao carregar catálogo: ${escapeHtml(error.message)}</p>`;
  }
}

function cartItems() {
  return [...state.cart.entries()].map(([productId, quantity]) => ({ productId, quantity }));
}

async function saveCart() {
  if (!state.cart.size) return;
  await request(`/carts/${USER_ID}`, {
    method: 'PUT',
    body: JSON.stringify({ items: cartItems() })
  });
}

function renderCart() {
  const container = document.getElementById('itens-carrinho');
  const button = document.getElementById('finalizar-pedido');
  let total = 0;
  if (!state.cart.size) {
    container.className = 'empty-state';
    container.textContent = 'Nenhum produto adicionado.';
    document.getElementById('total-carrinho').textContent = money.format(0);
    button.disabled = true;
    return;
  }

  container.className = '';
  container.innerHTML = cartItems().map((item) => {
    const product = state.products.find((entry) => entry.id === item.productId);
    if (!product) return '';
    total += product.price * item.quantity;
    return `
      <div class="item-carrinho">
        <div><strong>${escapeHtml(product.name)}</strong><small>${money.format(product.price)} por unidade</small></div>
        <input class="quantidade-carrinho" data-product-id="${product.id}" type="number" min="1" max="${product.stock}" value="${item.quantity}" aria-label="Quantidade no carrinho">
        <button class="remover" data-product-id="${product.id}" type="button">Remover</button>
      </div>
    `;
  }).join('');
  document.getElementById('total-carrinho').textContent = money.format(total);
  button.disabled = false;
}

function showOrder(order) {
  const result = document.getElementById('resultado-pedido');
  result.className = 'pedido-confirmado';
  result.innerHTML = `
    <h3>Pedido confirmado</h3>
    <p><strong>Código:</strong> ${escapeHtml(order.id)}</p>
    <p><strong>Status:</strong> ${escapeHtml(order.status)}</p>
    <p><strong>Pagamento:</strong> ${escapeHtml(order.payment_method || 'pix')}</p>
    <p><strong>Total:</strong> ${money.format(Number(order.total))}</p>
  `;
  document.getElementById('pedido-id').value = order.id;
}

function fillAdminForm() {
  const select = document.getElementById('admin-produto');
  const previous = select.value;
  select.innerHTML = state.products.map((product) => `<option value="${product.id}">${escapeHtml(product.name)}</option>`).join('');
  if (state.products.some((product) => product.id === previous)) select.value = previous;
  updateAdminFields();
}

function updateAdminFields() {
  const product = state.products.find((entry) => entry.id === document.getElementById('admin-produto').value);
  if (!product) return;
  document.getElementById('admin-preco').value = Number(product.price).toFixed(2);
  document.getElementById('admin-estoque').value = product.stock;
}

document.getElementById('lista-produtos').addEventListener('click', async (event) => {
  const button = event.target.closest('.adicionar');
  if (!button) return;
  const productId = button.dataset.productId;
  const quantity = Number(document.getElementById(`qty-${productId}`).value);
  const product = state.products.find((entry) => entry.id === productId);
  if (!Number.isInteger(quantity) || quantity < 1 || quantity > product.stock) {
    setMessage('mensagem-carrinho', 'Informe uma quantidade válida.', 'erro');
    return;
  }
  state.cart.set(productId, (state.cart.get(productId) || 0) + quantity);
  renderCart();
  try {
    await saveCart();
    setMessage('mensagem-carrinho', 'Carrinho salvo no MongoDB.', 'sucesso');
  } catch (error) {
    setMessage('mensagem-carrinho', error.message, 'erro');
  }
});

document.getElementById('itens-carrinho').addEventListener('change', async (event) => {
  if (!event.target.matches('.quantidade-carrinho')) return;
  const quantity = Number(event.target.value);
  if (Number.isInteger(quantity) && quantity > 0) {
    state.cart.set(event.target.dataset.productId, quantity);
    renderCart();
    try { await saveCart(); } catch (error) { setMessage('mensagem-carrinho', error.message, 'erro'); }
  }
});

document.getElementById('itens-carrinho').addEventListener('click', (event) => {
  const button = event.target.closest('.remover');
  if (!button) return;
  state.cart.delete(button.dataset.productId);
  renderCart();
  setMessage('mensagem-carrinho', 'Item removido do carrinho.');
});

document.getElementById('finalizar-pedido').addEventListener('click', async () => {
  const button = document.getElementById('finalizar-pedido');
  button.disabled = true;
  setMessage('mensagem-carrinho', 'Processando pedido...');
  try {
    const order = await request(`/users/${USER_ID}/checkout`, {
      method: 'POST',
      body: JSON.stringify({ items: cartItems(), paymentMethod: 'pix' })
    });
    state.cart.clear();
    renderCart();
    showOrder(order);
    setMessage('mensagem-carrinho', 'Pedido finalizado com sucesso.', 'sucesso');
    await loadProducts();
  } catch (error) {
    setMessage('mensagem-carrinho', error.message, 'erro');
    button.disabled = false;
  }
});

document.getElementById('form-consulta-pedido').addEventListener('submit', async (event) => {
  event.preventDefault();
  const id = document.getElementById('pedido-id').value.trim();
  if (!id) return;
  try {
    showOrder(await request(`/orders/${encodeURIComponent(id)}`));
  } catch (error) {
    document.getElementById('resultado-pedido').className = 'empty-state';
    document.getElementById('resultado-pedido').textContent = error.message;
  }
});

document.getElementById('form-produto').addEventListener('submit', async (event) => {
  event.preventDefault();
  const productId = document.getElementById('admin-produto').value;
  const price = Number(document.getElementById('admin-preco').value);
  const stock = Number(document.getElementById('admin-estoque').value);
  try {
    await request(`/products/${productId}/core`, {
      method: 'PUT',
      body: JSON.stringify({ price, stock })
    });
    setMessage('mensagem-admin', 'Preço e estoque atualizados. O cache foi invalidado.', 'sucesso');
    await loadProducts();
  } catch (error) {
    setMessage('mensagem-admin', error.message, 'erro');
  }
});

document.getElementById('admin-produto').addEventListener('change', updateAdminFields);
document.getElementById('atualizar-catalogo').addEventListener('click', loadProducts);

checkHealth();
loadProducts();
