// seed-perf-data.mjs — sinh dữ liệu + 3 file CSV cho workflow data-driven (§6).
//
//   node tools/seed-perf-data.mjs                 # 50 account, 30 order, 60 dòng import
//   node tools/seed-perf-data.mjs --users 200     # đổi số lượng
//
// Vì sao KHÔNG dùng chung một tài khoản cho mọi VU:
//   1. Mỗi lần login thành công đều `UPDATE users SET login_attempts=0` (server.js:47) →
//      dùng chung 1 dòng users là tự tạo write-contention nhân tạo, đo ra nghẽn KHÔNG
//      phải của endpoint mà của chính cách sinh tải.
//   2. Một VU nhập sai là khoá tài khoản → kéo sập toàn bộ VU còn lại (xem reset-lockout.mjs).
//
// Sinh ra:
//   data/users.csv            email,password,expect  ← có cả dòng mật khẩu SAI để test lockout
//   data/products_import.csv  name,price,description,category_id  ← body cho import-products
//   data/orders.csv           order_id,next_status   ← id thật trong DB cho PUT .../status

import { writeFileSync, mkdirSync } from 'node:fs';
import path from 'node:path';

const API_URL = process.env.API_URL || 'http://localhost:3000';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@eshop.com';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Admin123!';
const ROOT = path.resolve(import.meta.dirname, '..');

const argv = process.argv.slice(2);
const num = (flag, dflt) => {
  const i = argv.indexOf(flag);
  return i >= 0 ? Number(argv[i + 1]) : dflt;
};
const N_USERS = num('--users', 50);
const N_ORDERS = num('--orders', 30);
const N_IMPORT = num('--import', 60);

const STAMP = '23127178';           // MSSV — đánh dấu mọi dữ liệu do bài này sinh ra
const PASSWORD = 'Perf1234!';

async function api(method, pathname, body, token) {
  const res = await fetch(`${API_URL}${pathname}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(15000),
  });
  const data = await res.json().catch(() => null);
  return { status: res.status, data };
}

// ── 1. Tài khoản ────────────────────────────────────────────────────────────────
console.log(`\nSinh ${N_USERS} tài khoản perf…`);
const users = [];
for (let i = 1; i <= N_USERS; i++) {
  const email = `perf_${STAMP}_${String(i).padStart(3, '0')}@eshop.test`;
  const r = await api('POST', '/api/register', { name: `Perf User ${i}`, email, password: PASSWORD });
  // Email là UNIQUE → chạy lại script lần hai sẽ trả 500. Đó là bình thường, tài khoản đã có.
  if (r.status !== 200 && i === 1) console.log(`  (register trả ${r.status} — có thể tài khoản đã tồn tại từ lần trước)`);
  users.push({ email, password: PASSWORD });
}
console.log(`  ${users.length} tài khoản sẵn dùng`);

// ── 2. Order để bước "cập nhật trạng thái" có việc mà làm ───────────────────────
const admin = await api('POST', '/api/login', { email: ADMIN_EMAIL, password: ADMIN_PASSWORD });
if (admin.status !== 200) {
  console.error(`\nKhông đăng nhập được admin (HTTP ${admin.status}). Chạy: npm run reset:lockout`);
  process.exit(1);
}
const adminToken = admin.data.token;

console.log(`\nSinh ${N_ORDERS} order (mỗi order 1 VU khác nhau)…`);
const orderIds = [];
for (let i = 0; i < N_ORDERS; i++) {
  const u = users[i % users.length];
  const login = await api('POST', '/api/login', { email: u.email, password: u.password });
  if (login.status !== 200) continue;
  const co = await api('POST', '/api/checkout', {
    total_amount: 500000 + i * 10000,
    shipping_address: `${i + 1} Đường Perf, Q1, TP.HCM`,
  }, login.data.token);
  if (co.data?.orderId) orderIds.push(co.data.orderId);
}
console.log(`  ${orderIds.length} order, id ${orderIds[0]}…${orderIds.at(-1)}`);

// ── 3. Ghi 3 file CSV ───────────────────────────────────────────────────────────
mkdirSync(path.join(ROOT, 'data'), { recursive: true });

// users.csv — CHỈ chứa tài khoản đăng nhập được. Cột `expect` luôn 200.
//
// Bản đầu từng để 2 dòng mật khẩu sai ở cuối file này, ý là để nhánh lockout dùng luôn. Lượt
// chạy Load thật cho thấy đó là một lỗi thiết kế dữ liệu: thread group chính đọc users.csv với
// `recycle=true`, nên nó cũng gặp 2 dòng đó → login 401 → hai tài khoản bị khoá → những lần
// đọc sau trả 403 → và vì không có token, **cả 4 bước còn lại của iteration đó cũng 403**.
// Kết quả: ~3% iteration hoàn toàn vô giá trị, và error rate đọc ra là lỗi của dữ liệu test
// chứ không phải của SUT.
//
// Nhánh lockout nay dùng file riêng: data/users_lockout.csv.
const userRows = [
  'email,password,expect',
  ...users.map((u) => `${u.email},${u.password},200`),
];
writeFileSync(path.join(ROOT, 'data/users.csv'), userRows.join('\n') + '\n');
console.log(`\n  data/users.csv            ${userRows.length - 1} dòng`);

// Hai tài khoản riêng cho nhánh lockout — tạo thật để login trả 401 (sai mật khẩu),
// chứ không phải 401 vì "user không tồn tại" (server.js:37-38 trả cùng mã, khác nguyên nhân).
const lockoutRows = ['email,password,expect_regex'];
for (const suffix of ['a', 'b']) {
  const email = `perf_${STAMP}_lockout_${suffix}@eshop.test`;
  await api('POST', '/api/register', { name: `Perf Lockout ${suffix}`, email, password: PASSWORD });
  lockoutRows.push(`${email},WrongPassword!,40[13]`);
}
// File riêng để thread group "lockout probe" không đụng vào users.csv của luồng chính.
// `expect_regex` là 40[13] vì cùng một request sai mật khẩu trả 401 ở lần đầu và 403 sau khi
// đã bị khoá — hai mã đều đúng, tuỳ thời điểm trong lượt chạy.
writeFileSync(path.join(ROOT, 'data/users_lockout.csv'), lockoutRows.join('\n') + '\n');
console.log(`  data/users_lockout.csv    ${lockoutRows.length - 1} dòng`);

const importRows = ['name,price,description,category_id'];
for (let i = 1; i <= N_IMPORT; i++) {
  importRows.push(`Perf SP ${STAMP}-${String(i).padStart(3, '0')},${100000 + i * 1000},San pham sinh boi HW05 perf test,${(i % 3) + 1}`);
}
writeFileSync(path.join(ROOT, 'data/products_import.csv'), importRows.join('\n') + '\n');
console.log(`  data/products_import.csv  ${importRows.length - 1} dòng`);

// orders.csv — chỉ dùng `confirmed`.
//
// State machine FR-10 (server.js:537-551) chỉ cho pending → confirmed hoặc pending → canceled.
// tools/reset-orders.mjs đưa mọi order về `pending` trước mỗi lượt, nên `confirmed` là
// chuyển đổi hợp lệ duy nhất đáng dùng: nó đi tới lệnh UPDATE thật.
//
// Từng thử xen kẽ `shipping`: từ `pending` thì shipping là chuyển đổi KHÔNG hợp lệ → 400 trả
// về trước khi kịp ghi, tức là một nửa số sample của bước 5 không đo cái gì cả.
const orderRows = ['order_id,next_status', ...orderIds.map((id) => `${id},confirmed`)];
writeFileSync(path.join(ROOT, 'data/orders.csv'), orderRows.join('\n') + '\n');
console.log(`  data/orders.csv           ${orderRows.length - 1} dòng`);

console.log('\nXong. Kiểm lại bằng: npm run preflight\n');
