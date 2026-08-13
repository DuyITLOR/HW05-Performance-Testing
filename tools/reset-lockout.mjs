// reset-lockout.mjs — mở khoá tài khoản bị account-lockout giữa các lượt chạy.
//
// §6 đòi đích danh: "When Stress/Spike runs trigger the 3-fail login lockout, reset it
// between runs and document the steps." Script này LÀ các bước đó, chạy được và ghi lại
// bằng chứng trước/sau để dán vào báo cáo.
//
//   node tools/reset-lockout.mjs              # mở khoá mọi tài khoản
//   node tools/reset-lockout.mjs --check      # chỉ xem, không sửa
//   node tools/reset-lockout.mjs a@b.com      # chỉ một tài khoản
//
// Vì sao cần: server.js:54 cộng `login_attempts + 2` (đúng đặc tả phải là +1) và ngưỡng
// khoá là 3 → chỉ **2 lần sai mật khẩu** là khoá 180 giây (server.js:56-58). Ở Stress/Spike
// với hàng trăm VU dùng chung vài tài khoản, hàng loạt request sau đó trả 403 và error-rate
// bị đọc sai thành "server sụp", trong khi thật ra là lockout. Reset trước MỖI lượt.

import { execFileSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import path from 'node:path';

const DB = process.env.ESHOP_DB
  || path.resolve(import.meta.dirname, '../../eshop-sut/backend/database.sqlite');

if (!existsSync(DB)) {
  console.error(`Không thấy database: ${DB}`);
  console.error('Chỉ định đường dẫn khác: ESHOP_DB=/path/to/database.sqlite node tools/reset-lockout.mjs');
  process.exit(1);
}

const args = process.argv.slice(2);
const checkOnly = args.includes('--check');
const email = args.find((a) => !a.startsWith('--'));

const q = (sql) =>
  execFileSync('sqlite3', ['-header', '-column', DB, sql], { encoding: 'utf8' }).trimEnd();

const where = email ? `WHERE email = '${email.replace(/'/g, "''")}'` : '';

console.log(`\nDB: ${DB}\n`);
console.log('── Trước ───────────────────────────────────────────────────────────────');
console.log(q(`SELECT id, email, role, login_attempts, locked_until FROM users ${where} ORDER BY id LIMIT 40;`) || '(không có dòng nào)');

const locked = q(
  `SELECT COUNT(*) FROM users ${where ? where + ' AND' : 'WHERE'} locked_until IS NOT NULL;`
).split('\n').pop().trim();

if (checkOnly) {
  console.log(`\n${locked} tài khoản đang có locked_until. Bỏ --check để mở khoá.\n`);
  process.exit(0);
}

q(`UPDATE users SET login_attempts = 0, locked_until = NULL ${where};`);

console.log('\n── Sau ─────────────────────────────────────────────────────────────────');
console.log(q(`SELECT id, email, role, login_attempts, locked_until FROM users ${where} ORDER BY id LIMIT 40;`));
console.log(`\nĐã mở khoá (trước đó ${locked} tài khoản bị khoá).`);
console.log('Chụp lại màn hình này làm bằng chứng "reset lockout giữa các lượt" cho §6.\n');
