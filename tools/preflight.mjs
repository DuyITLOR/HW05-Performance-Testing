// preflight.mjs — kiểm môi trường trước khi chạy perf test.
//
// Với perf test, "chạy khi môi trường chưa sẵn sàng" tệ hơn ở HW04 nhiều: HW04 chỉ mất
// một suite toàn Fail, còn ở đây cả .jtl lẫn HTML report đều thành số liệu RÁC nhưng
// TRÔNG NHƯ THẬT (p95 đẹp vì server trả 401 tức thì). Kiểm 20 giây ở đây rẻ hơn nhiều.
//
//   npm run preflight
//
// KHÔNG bao giờ thử đăng nhập sai mật khẩu trong script này: login_attempts += 2 và
// ngưỡng khoá là 3 (server.js:54) → 2 lần sai là khoá tài khoản 180s, tự phá lượt chạy.

import { execFileSync } from 'node:child_process';

const API_URL = process.env.API_URL || 'http://localhost:3000';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@eshop.com';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Admin123!';

let failed = 0;
let warned = 0;

const ok = (name, msg) => console.log(`  [OK]    ${name.padEnd(16)} ${msg}`);
const bad = (name, msg) => { console.log(`  [LOI]   ${name.padEnd(16)} ${msg}`); failed++; };
const warn = (name, msg) => { console.log(`  [LUU Y] ${name.padEnd(16)} ${msg}`); warned++; };

function sh(cmd, args) {
  try {
    return execFileSync(cmd, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
  } catch {
    return null;
  }
}

// java_home và `java -version` in ra **stderr**, không phải stdout — gọi qua shell để gộp lại.
// Bỏ quên chi tiết này là script báo "OK" với giá trị rỗng, đúng loại bug im lặng cần tránh.
function shell(cmd) {
  try {
    return execFileSync('bash', ['-c', `${cmd} 2>&1`], { encoding: 'utf8' }).trim();
  } catch {
    return null;
  }
}

console.log('\n── Công cụ sinh tải ────────────────────────────────────────────────────');

// JMeter — công cụ mặc định của đề (§8). Bản nộp cần .jmx + .jtl + HTML dashboard.
const jmeterVersion = sh('jmeter', ['--version']);
if (jmeterVersion) {
  const line = jmeterVersion.split('\n').find((l) => /\d+\.\d+/.test(l)) || jmeterVersion.split('\n')[0];
  ok('JMeter', line.trim());
} else {
  bad('JMeter', 'chưa cài → brew install jmeter   (§8: JMeter là tool mặc định)');
}

// Java: JMeter chạy trên JVM nào thì CHÍNH NÓ là một phần của kết quả đo.
// Máy này có 2 JDK: Temurin 8 (x86_64 → chạy qua Rosetta, chậm và nhiễu số đo) và
// Temurin 26 (arm64, native). `java` mặc định trỏ về bản 8 → phải ép JAVA_HOME sang arm64.
const archOf = (javaHome) => {
  const out = shell(`"${javaHome}/bin/java" -XshowSettings:properties -version`) || '';
  return out.match(/os\.arch\s*=\s*(\S+)/)?.[1] || '?';
};

let goodJdk = null;
for (const v of ['26', '21', '17']) {
  const home = sh('/usr/libexec/java_home', ['-v', v]);
  if (home && archOf(home) === 'aarch64') { goodJdk = { v, home }; break; }
}
if (goodJdk) {
  ok(`Java ${goodJdk.v}`, `aarch64 · ${goodJdk.home}`);
} else {
  bad('Java', 'không thấy JDK ≥17 bản arm64 → JMeter chạy qua Rosetta, số đo bị nhiễu');
}

// `java` mặc định trên PATH có thể là bản x86_64 (Rosetta) — chạy JMeter bằng nó thì chính
// load generator thành điểm nghẽn. run-scenario.sh tự ép JAVA_HOME, nhưng vẫn phải cảnh báo
// vì gọi `jmeter` tay là bỏ qua đúng chỗ đó.
// Phải soi đúng binary `java` TRÊN PATH, không phải bản java_home mặc định — trên máy này hai
// thứ đó khác nhau (PATH trỏ Temurin 8, java_home trỏ Temurin 26).
const pathJavaArch = (shell('java -XshowSettings:properties -version') || '').match(/os\.arch\s*=\s*(\S+)/)?.[1];
if (pathJavaArch && pathJavaArch !== 'aarch64') {
  const ver = (shell('java -version') || '').split('\n')[0];
  warn('Java trên PATH', `${ver} — ${pathJavaArch} (Rosetta)`);
  warn('', 'Dùng tools/run-scenario.sh (tự ép JAVA_HOME arm64), đừng gọi jmeter tay.');
}

// k6 — bonus của đề (§8). Có thì làm thêm bản mirror để đối chiếu chéo.
const k6Version = sh('k6', ['version']);
if (k6Version) ok('k6 (bonus)', k6Version.split('\n')[0]);
else warn('k6 (bonus)', 'chưa cài → brew install k6   (không bắt buộc, chỉ là điểm bonus)');

console.log('\n── SUT ─────────────────────────────────────────────────────────────────');

// Backend là thứ DUY NHẤT bài này cần (đo API, không đo UI) — nhưng vẫn phải sống.
let products = null;
try {
  const res = await fetch(`${API_URL}/api/products`, { signal: AbortSignal.timeout(5000) });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  products = await res.json();
  ok('Backend API', `${API_URL} → ${products.length} sản phẩm`);
} catch (err) {
  bad('Backend API', `${API_URL} → ${err.message} · chạy: cd .. && ./eshop.sh --seed`);
}

if (products && products.length < 5) {
  warn('Seed data', `chỉ có ${products.length} sản phẩm — chạy ./eshop.sh --seed để về mốc 5 sản phẩm`);
} else if (products) {
  ok('Seed data', 'đủ sản phẩm gốc');
}

// Đăng nhập admin: cần token cho toàn bộ workflow back-office (bước 2→5).
let token = null;
try {
  const res = await fetch(`${API_URL}/api/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASSWORD }),
    signal: AbortSignal.timeout(5000),
  });
  const body = await res.json().catch(() => ({}));
  if (res.status === 403) {
    bad('Admin login', 'tài khoản ĐANG BỊ KHOÁ (lockout 180s) → npm run reset:lockout');
  } else if (!res.ok) {
    bad('Admin login', `HTTP ${res.status} ${body.error || ''} → cd .. && ./eshop.sh --seed`);
  } else {
    token = body.token;
    ok('Admin login', `${ADMIN_EMAIL} · login_attempts=${body.user?.login_attempts ?? '?'}`);
  }
} catch (err) {
  bad('Admin login', err.message);
}

console.log('\n── Endpoint của workflow (§5) ──────────────────────────────────────────');

// Đúng 5 endpoint của workflow đã chốt. Kiểm bằng ĐỌC, không ghi — trừ import-products
// thì chỉ gửi body rỗng để xem có tồn tại route + trả 400 đúng như code, không tạo rác.
if (token) {
  const auth = { Authorization: `Bearer ${token}` };
  const probes = [
    { name: 'admin/orders', method: 'GET', path: '/api/admin/orders', expect: [200] },
    { name: 'admin/users', method: 'GET', path: '/api/admin/users', expect: [200] },
    { name: 'coupons', method: 'GET', path: '/api/coupons', expect: [200] },
    { name: 'import-products', method: 'POST', path: '/api/admin/import-products', body: {}, expect: [400] },
  ];
  for (const p of probes) {
    try {
      const res = await fetch(`${API_URL}${p.path}`, {
        method: p.method,
        headers: p.body ? { ...auth, 'Content-Type': 'application/json' } : auth,
        body: p.body ? JSON.stringify(p.body) : undefined,
        signal: AbortSignal.timeout(8000),
      });
      const n = res.headers.get('content-type')?.includes('json')
        ? (await res.json().catch(() => null))
        : null;
      const size = Array.isArray(n) ? `${n.length} dòng` : '';
      if (p.expect.includes(res.status)) ok(p.name, `${p.method} ${p.path} → ${res.status} ${size}`);
      else warn(p.name, `${p.method} ${p.path} → ${res.status} (chờ ${p.expect.join('/')})`);
    } catch (err) {
      bad(p.name, `${p.path} → ${err.message}`);
    }
  }

  // Cần ít nhất 1 order để bước 5 (PUT /api/admin/orders/:id/status) có việc mà làm.
  try {
    const res = await fetch(`${API_URL}/api/admin/orders`, { headers: auth, signal: AbortSignal.timeout(8000) });
    const orders = await res.json();
    if (!Array.isArray(orders) || orders.length === 0) {
      warn('Order để test', 'chưa có order nào → npm run seed:perf (sinh order + data/orders.csv)');
    } else {
      ok('Order để test', `${orders.length} order · id nhỏ nhất=${Math.min(...orders.map((o) => o.id))}`);
    }
  } catch { /* đã báo ở probe trên */ }
}

console.log('\n── Dữ liệu data-driven (§6) ────────────────────────────────────────────');

const { existsSync, readFileSync } = await import('node:fs');
for (const f of ['data/users.csv', 'data/products_import.csv', 'data/orders.csv']) {
  if (!existsSync(f)) { warn(f, 'chưa có → npm run seed:perf'); continue; }
  const rows = readFileSync(f, 'utf8').trim().split('\n').length - 1;
  if (rows < 1) warn(f, 'chỉ có header, không có dòng dữ liệu');
  else ok(f, `${rows} dòng dữ liệu`);
}

console.log('\n────────────────────────────────────────────────────────────────────────');
if (failed > 0) {
  console.log(`  ${failed} lỗi CHẶN, ${warned} cảnh báo — sửa hết lỗi rồi hãy chạy test.\n`);
  process.exit(1);
}
console.log(`  Sẵn sàng chạy. ${warned} cảnh báo.\n`);
