// reset-orders.mjs — đưa mọi order về trạng thái `pending` trước mỗi lượt chạy.
//
//   node tools/reset-orders.mjs              # reset tất cả
//   node tools/reset-orders.mjs --check      # chỉ xem phân bố trạng thái
//
// Cùng lý do như reset-lockout.mjs: bước 5 của workflow (`PUT /api/admin/orders/:id/status`)
// đi qua state machine FR-10 (server.js:537-551). Một order chỉ chuyển tiếp được ĐÚNG MỘT
// lần cho mỗi trạng thái, nên nếu không reset thì lượt chạy sau bắt đầu với toàn bộ order đã
// nằm ở trạng thái cuối, và 100% request bước 5 trả 400 ngay từ giây đầu.
//
// Không reset thì hai lượt chạy khác nhau đo hai thứ khác nhau, và so sánh Load với Stress
// mất ý nghĩa — đúng loại lỗi mà việc "chạy lại được" phải loại bỏ.

import { execFileSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import path from 'node:path';

const DB = process.env.ESHOP_DB
  || path.resolve(import.meta.dirname, '../../eshop-sut/backend/database.sqlite');

if (!existsSync(DB)) {
  console.error(`Không thấy database: ${DB}`);
  process.exit(1);
}

const q = (sql) =>
  execFileSync('sqlite3', ['-header', '-column', DB, sql], { encoding: 'utf8' }).trimEnd();

const dist = () => q('SELECT status, COUNT(*) AS n FROM orders GROUP BY status ORDER BY n DESC;');

console.log('\n── Trạng thái order trước ──────────────────────────────────────────────');
console.log(dist() || '(không có order nào)');

if (process.argv.includes('--check')) {
  console.log('\nBỏ --check để reset về pending.\n');
  process.exit(0);
}

q("UPDATE orders SET status = 'pending';");

console.log('\n── Sau ─────────────────────────────────────────────────────────────────');
console.log(dist());
console.log('\nĐã reset. Bước 5 của workflow lại có đường chuyển hợp lệ pending → confirmed.\n');
