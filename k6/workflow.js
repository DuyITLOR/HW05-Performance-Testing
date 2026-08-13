// workflow.js — workflow 5 bước dùng chung cho cả 3 scenario k6.
//
// Giữ ĐÚNG thứ tự và đúng assertion như bản JMeter (tools/gen-test-plans.py). Nếu hai bản đo
// hai workflow khác nhau thì việc chạy hai tool mất hết giá trị: không còn tách được "chênh
// lệch do tool" khỏi "chênh lệch do workflow".
//
// Không dùng thư viện ngoài (papaparse trên jslib.k6.io) — k6 sẽ phải tải module qua mạng lúc
// biên dịch, và một bài đo hiệu năng không nên phụ thuộc mạng để chạy được.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend } from 'k6/metrics';

const BASE = __ENV.BASE_URL || 'http://localhost:3000';

// ── Đọc CSV trong init context ──────────────────────────────────────────────────
function csv(path) {
  const lines = open(path).trim().split('\n');
  const header = lines[0].split(',');
  return lines.slice(1).map((line) => {
    const cells = line.split(',');
    const row = {};
    header.forEach((h, i) => { row[h.trim()] = (cells[i] || '').trim(); });
    return row;
  });
}

export const users = csv('../data/users.csv').filter((u) => u.expect === '200');
export const products = csv('../data/products_import.csv');
export const orders = csv('../data/orders.csv');

// Một Trend cho mỗi bước: k6 mặc định chỉ cho http_req_duration tổng, mà kết luận của bài này
// nằm ở p95 CỦA TỪNG endpoint — endpoint đọc nhanh pha loãng endpoint ghi chậm.
export const t = {
  login: new Trend('step1_login', true),
  orders: new Trend('step2_admin_orders', true),
  usersList: new Trend('step3_admin_users', true),
  importProducts: new Trend('step4_import_products', true),
  status: new Trend('step5_order_status', true),
};

const JSON_HEADERS = { 'Content-Type': 'application/json' };

export function workflow(think) {
  // Mỗi VU một tài khoản riêng — dùng chung một dòng users là tự tạo write-contention trên
  // đúng dòng đó, vì mọi login thành công đều UPDATE login_attempts (server.js:47).
  const user = users[(__VU - 1) % users.length];
  const product = products[__ITER % products.length];
  const order = orders[(__VU * 7 + __ITER) % orders.length];

  // 1 — auth-heavy
  const login = http.post(`${BASE}/api/login`,
    JSON.stringify({ email: user.email, password: user.password }),
    { headers: JSON_HEADERS, tags: { step: '1_login' } });
  t.login.add(login.timings.duration);
  const ok = check(login, {
    'login 200': (r) => r.status === 200,
    'login tra ve token': (r) => !!(r.json() || {}).token,
  });
  if (!ok) { sleep(think()); return; }

  const auth = { headers: { ...JSON_HEADERS, Authorization: `Bearer ${login.json().token}` } };

  // 2, 3 — read-heavy
  const r2 = http.get(`${BASE}/api/admin/orders`, { ...auth, tags: { step: '2_admin_orders' } });
  t.orders.add(r2.timings.duration);
  check(r2, { 'admin/orders 200': (r) => r.status === 200 });

  const r3 = http.get(`${BASE}/api/admin/users`, { ...auth, tags: { step: '3_admin_users' } });
  t.usersList.add(r3.timings.duration);
  check(r3, { 'admin/users 200': (r) => r.status === 200 });

  // 4 — transactional: 3 sản phẩm mỗi request, giống hệt bản JMeter
  const item = (suffix) => ({
    name: `${product.name}-${suffix}-${__VU}-${__ITER}`,
    price: Number(product.price),
    description: product.description,
    imageUrl: '',
    category_id: Number(product.category_id),
  });
  const r4 = http.post(`${BASE}/api/admin/import-products`,
    JSON.stringify({ products: [item('A'), item('B'), item('C')] }),
    { ...auth, tags: { step: '4_import_products' } });
  t.importProducts.add(r4.timings.duration);
  // Assert theo `message`, không theo `inserted`: con số đó phụ thuộc dữ liệu (dòng CSV
  // thiếu `name` bị bỏ qua một cách hợp lệ), nên assert theo nó là biến đặc điểm dữ liệu
  // thành lỗi. Bản thân `inserted` đã kiểm bằng request thật và cho số ĐÚNG.
  check(r4, {
    'import 200': (r) => r.status === 200,
    'import co message': (r) => !!(r.json() || {}).message,
  });

  // 5 — transactional: 200 hoặc 400 đều là phản hồi hợp lệ của state machine FR-10
  const r5 = http.put(`${BASE}/api/admin/orders/${order.order_id}/status`,
    JSON.stringify({ status: order.next_status }),
    { ...auth, tags: { step: '5_order_status' } });
  t.status.add(r5.timings.duration);
  check(r5, { 'status 200 hoac 400 (FR-10)': (r) => r.status === 200 || r.status === 400 });

  sleep(think());
}

// Think-time ngẫu nhiên đều. Hằng số sẽ làm mọi VU đồng bộ thành từng đợt và tạo ra các đỉnh
// tải giả không có trong thực tế.
export const uniform = (min, max) => () => min + Math.random() * (max - min);
