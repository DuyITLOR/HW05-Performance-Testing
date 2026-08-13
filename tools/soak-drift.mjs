// soak-drift.mjs — đo độ TRÔI của p95 và của bộ nhớ trong một lượt soak.
//
//   node tools/soak-drift.mjs                                  # tự tìm .jtl Soak mới nhất
//   node tools/soak-drift.mjs endurance/jtl/xxx_Soak_*.jtl
//
// Vì sao cần tool riêng: `summarize-jtl.mjs` cho p95 của **toàn lượt**, còn endurance threshold
// (§6) hỏi một câu khác — p95 có **trôi lên theo thời gian** hay không. Một lượt soak có p95
// tổng đẹp vẫn có thể đang xấu dần: 5 phút đầu 4ms, 5 phút cuối 40ms, trung bình vẫn nhỏ.
//
// Định nghĩa "ổn định" đã chốt TRƯỚC khi chạy (endurance/endurance-threshold.md):
//   error rate < 1%  VÀ  p95 không tăng quá 20% giữa 5 phút đầu và 5 phút cuối.

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');
const WINDOW_SEC = 60;

function parseCsv(text) {
  const rows = [];
  let row = [], field = '', inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') { if (text[i + 1] === '"') { field += '"'; i++; } else inQuotes = false; }
      else field += c;
    } else if (c === '"') inQuotes = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); rows.push(row); row = []; field = ''; }
    else if (c !== '\r') field += c;
  }
  if (field.length || row.length) { row.push(field); rows.push(row); }
  return rows.filter((r) => r.length > 1);
}

const pct = (sorted, p) => {
  if (!sorted.length) return 0;
  return sorted[Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1))];
};
const n1 = (x) => Math.round(x * 10) / 10;

// Xem chú thích cùng vấn đề trong summarize-jtl.mjs: spread trên mảng lớn làm tràn call stack.
const minOf = (a) => a.reduce((m, x) => (x < m ? x : m), Infinity);
const maxOf = (a) => a.reduce((m, x) => (x > m ? x : m), -Infinity);

// ── Chọn file .jtl ──────────────────────────────────────────────────────────────
let file = process.argv[2];
if (!file) {
  for (const dir of ['endurance/jtl', 'results/jtl']) {
    const abs = path.join(ROOT, dir);
    if (!existsSync(abs)) continue;
    const hit = readdirSync(abs).filter((f) => /Soak.*\.jtl$/.test(f)).sort().pop();
    if (hit) { file = path.join(dir, hit); break; }
  }
}
if (!file) { console.log('\nKhông thấy .jtl nào của scenario Soak.\n'); process.exit(1); }
const jtlPath = path.resolve(ROOT, file);

const rows = parseCsv(readFileSync(jtlPath, 'utf8'));
const h = Object.fromEntries(rows[0].map((k, i) => [k.trim(), i]));
const samples = rows.slice(1)
  .map((r) => ({
    ts: Number(r[h.timeStamp]),
    elapsed: Number(r[h.elapsed]),
    label: r[h.label],
    code: r[h.responseCode],
    ok: r[h.success] === 'true',
  }))
  .filter((s) => Number.isFinite(s.ts) && Number.isFinite(s.elapsed));

if (!samples.length) { console.log('\n.jtl không có sample hợp lệ.\n'); process.exit(1); }

const t0 = minOf(samples.map((s) => s.ts));
const t1 = maxOf(samples.map((s) => s.ts));
const totalSec = (t1 - t0) / 1000;

// ── p95 theo từng cửa sổ 60 giây ────────────────────────────────────────────────
const windows = new Map();
for (const s of samples) {
  const w = Math.floor((s.ts - t0) / 1000 / WINDOW_SEC);
  if (!windows.has(w)) windows.set(w, []);
  windows.get(w).push(s);
}

console.log(`\nFile     : ${file}`);
console.log(`Thời lượng: ${n1(totalSec)}s · ${samples.length.toLocaleString('en-US')} sample\n`);
console.log('| Phút | Sample | RPS | Error % | p50 | **p95** | p99 |');
console.log('|---|---|---|---|---|---|---|');
for (const [w, list] of [...windows.entries()].sort((a, b) => a[0] - b[0])) {
  const el = list.map((s) => s.elapsed).sort((a, b) => a - b);
  const errs = list.filter((s) => !s.ok).length;
  console.log(`| ${w + 1} | ${list.length} | ${n1(list.length / WINDOW_SEC)} | ${n1((errs / list.length) * 100)}% | ${pct(el, 50)} | **${pct(el, 95)}** | ${pct(el, 99)} |`);
}

// ── So 5 phút đầu với 5 phút cuối ───────────────────────────────────────────────
const FIVE = 5 * 60 * 1000;
const head = samples.filter((s) => s.ts - t0 < FIVE);
const tail = samples.filter((s) => t1 - s.ts < FIVE);
const p95 = (list) => pct(list.map((s) => s.elapsed).sort((a, b) => a - b), 95);
const errPct = (list) => (list.filter((s) => !s.ok).length / list.length) * 100;

const p95Head = p95(head), p95Tail = p95(tail);
const drift = p95Head ? ((p95Tail - p95Head) / p95Head) * 100 : 0;
const errAll = errPct(samples);

console.log('\n── Kiểm định nghĩa "ổn định" ───────────────────────────────────────────');
console.log(`  p95 5 phút ĐẦU  : ${p95Head} ms  (${head.length.toLocaleString('en-US')} sample)`);
console.log(`  p95 5 phút CUỐI : ${p95Tail} ms  (${tail.length.toLocaleString('en-US')} sample)`);
console.log(`  Độ trôi         : ${drift >= 0 ? '+' : ''}${n1(drift)}%   (ngưỡng cho phép: ±20%)`);
console.log(`  Error rate tổng : ${n1(errAll)}%        (ngưỡng cho phép: < 1%)`);
const stable = Math.abs(drift) <= 20 && errAll < 1;
console.log(`\n  → ${stable ? 'ỔN ĐỊNH theo đúng định nghĩa đã chốt trước khi chạy.' : 'KHÔNG ổn định — xem cửa sổ nào bắt đầu xấu ở bảng trên.'}`);
console.log(`  → Max stable RPS ở mức tải này: ${n1(samples.length / totalSec)} req/s`);

// ── Bộ nhớ, đọc từ file resources cùng lượt ─────────────────────────────────────
const resPath = jtlPath.replace('/jtl/', '/resources/').replace(/\.jtl$/, '.resources.csv');
if (existsSync(resPath)) {
  const rrows = parseCsv(readFileSync(resPath, 'utf8'));
  const rh = Object.fromEntries(rrows[0].map((k, i) => [k.trim(), i]));
  const pts = rrows.slice(1)
    .map((r) => ({
      rss: Number(r[rh.node_rss_mb]),
      cpu: Number(r[rh.node_cpu_pct]),
      jcpu: Number(r[rh.java_cpu_pct]),
      jrss: Number(r[rh.java_rss_mb]),
    }))
    .filter((p) => Number.isFinite(p.rss) && p.rss > 0);
  if (pts.length) {
    const first = pts[0], last = pts.at(-1);
    const maxRss = maxOf(pts.map((p) => p.rss));
    const maxCpu = maxOf(pts.map((p) => p.cpu));
    const maxJCpu = maxOf(pts.map((p) => p.jcpu));
    const maxJRss = maxOf(pts.map((p) => p.jrss));
    console.log('\n── Tài nguyên (từ file resources cùng lượt) ────────────────────────────');
    console.log(`  node RSS   : ${first.rss} → ${last.rss} MB   (đỉnh ${maxRss} MB)`);
    console.log(`  node CPU   : đỉnh ${maxCpu}%   ← trần của MỘT luồng JS là ~100%`);
    console.log(`  JMeter CPU : đỉnh ${maxJCpu}%   ·  JMeter RSS đỉnh ${maxJRss} MB`);
    const rssDrift = first.rss ? ((last.rss - first.rss) / first.rss) * 100 : 0;
    console.log(`  Trôi RSS   : ${rssDrift >= 0 ? '+' : ''}${n1(rssDrift)}%`);
    if (maxJCpu > maxCpu) {
      console.log('\n  [LUU Y] JMeter ăn CPU nhiều hơn backend → một phần latency đo được là chi phí');
      console.log('          của load generator, không phải của server. Phải nói rõ trong báo cáo.');
    }
  } else {
    console.log('\n  [LUU Y] File resources không có mẫu node hợp lệ (xem lỗi #8 trong AI audit).');
  }
} else {
  console.log(`\n  (không thấy file resources: ${path.relative(ROOT, resPath)})`);
}
console.log('');
