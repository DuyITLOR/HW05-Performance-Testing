// ============================================================================
// ci-gate.mjs — đọc raw .jtl, so với ngưỡng, và QUYẾT ĐỊNH pass/fail cho build.
//
//   node tools/ci-gate.mjs <file.jtl> --p95 40 --error-rate 1 [--min-samples 500]
//
// Đây là nút "Threshold gate" trong flow chart Task 3. Ba điều nó làm khác một script
// `if p95 > X then exit 1` thông thường:
//
//   1. **Có ngưỡng sàn số sample** (`--min-samples`). Một lượt CI chết ở giây thứ 3 vẫn có thể
//      cho p95 = 2ms và đi qua mọi ngưỡng trên. Không kiểm số sample thì cổng này bảo vệ
//      không phải hiệu năng mà là *sự im lặng*.
//   2. **4xx hợp lệ không tính là lỗi.** Cột `success` của JMeter đã được
//      `JSR223PostProcessor` trong plan sửa lại cho nhánh lockout và cho FR-10 (xem lỗi #2 và
//      #7 trong ai-audit). Cổng đọc cột `success`, KHÔNG tự suy từ `responseCode`, nếu không nó
//      sẽ dựng lại đúng cái lỗi 18,25%-error-rate mà bài này mất hai lượt chạy để bắt.
//   3. **In cả số không dùng để gate** (p50/p99/max, tách theo endpoint). Một cổng chỉ in con số
//      nó vừa so thì lúc fail không ai biết vì sao.
//
// Ngưỡng KHÔNG hardcode trong file này. Chúng là tham số, vì §4 của báo cáo lập luận rằng ngưỡng
// tuyệt đối mang từ máy này sang máy khác là vô nghĩa — và workflow này được chạy hai lần với hai
// bộ ngưỡng để chứng minh đúng điều đó bằng hai kết quả build thật.
// ============================================================================
import { readFileSync, appendFileSync, existsSync } from 'node:fs';

const argv = process.argv.slice(2);
const file = argv.find((a) => !a.startsWith('--'));
const optOf = (name, dflt) => {
  const i = argv.indexOf(`--${name}`);
  return i === -1 ? dflt : Number(argv[i + 1]);
};

if (!file || !existsSync(file)) {
  console.error(`Không thấy .jtl: ${file ?? '(chưa truyền)'}`);
  console.error('Dùng: node tools/ci-gate.mjs <file.jtl> --p95 40 --error-rate 1');
  process.exit(2);
}

const maxP95 = optOf('p95', Infinity);
const maxErrPct = optOf('error-rate', Infinity);
const minSamples = optOf('min-samples', 1);

// ── Đọc .jtl theo TÊN cột, không theo chỉ số ────────────────────────────────
// Thứ tự cột của JMeter đổi theo cấu hình listener (`Hostname` có/không). Bám chỉ số là tự
// đặt bẫy cho lần chạy sau.
const lines = readFileSync(file, 'utf8').split('\n').filter((l) => l.length > 0);
const head = lines[0].split(',');
const col = (name) => {
  const i = head.indexOf(name);
  if (i === -1) throw new Error(`.jtl thiếu cột "${name}" — header: ${head.join(',')}`);
  return i;
};
const iElapsed = col('elapsed');
const iLabel = col('label');
const iSuccess = col('success');
const iCode = col('responseCode');

const all = [];
const perLabel = new Map();
let failed = 0;
const codes = new Map();

for (let n = 1; n < lines.length; n++) {
  const f = lines[n].split(',');
  if (f.length < head.length) continue; // dòng cuối bị cắt khi JMeter bị kill
  const ms = Number(f[iElapsed]);
  if (!Number.isFinite(ms)) continue;
  const label = f[iLabel];
  all.push(ms);
  if (!perLabel.has(label)) perLabel.set(label, []);
  perLabel.get(label).push(ms);
  if (f[iSuccess] !== 'true') failed++;
  codes.set(f[iCode], (codes.get(f[iCode]) ?? 0) + 1);
}

if (all.length === 0) {
  console.error('.jtl không có sample nào đọc được.');
  process.exit(1);
}

const pct = (arr, p) => {
  const s = [...arr].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.ceil((p / 100) * s.length) - 1)];
};
// reduce thay cho Math.max(...arr): với .jtl vài trăm nghìn dòng thì spread tràn call stack —
// lỗi #10 trong ai-audit, gặp thật ở file 264.141 sample.
const maxOf = (a) => a.reduce((m, x) => (x > m ? x : m), -Infinity);
const mean = (a) => a.reduce((s, x) => s + x, 0) / a.length;

const errPct = (failed / all.length) * 100;
const p95 = pct(all, 95);

const rows = [
  ['Sample', all.length, minSamples === 1 ? '—' : `≥ ${minSamples}`, all.length >= minSamples],
  ['Error rate', `${errPct.toFixed(2)}%`, maxErrPct === Infinity ? '—' : `≤ ${maxErrPct}%`, errPct <= maxErrPct],
  ['p95', `${p95} ms`, maxP95 === Infinity ? '—' : `≤ ${maxP95} ms`, p95 <= maxP95],
];

const pad = (s, n) => String(s).padEnd(n);
console.log(`\nCổng ngưỡng — ${file}\n`);
console.log(`  ${pad('Chỉ số', 12)} ${pad('Đo được', 12)} ${pad('Ngưỡng', 14)} Kết quả`);
console.log(`  ${'─'.repeat(52)}`);
for (const [name, got, limit, ok] of rows) {
  console.log(`  ${pad(name, 12)} ${pad(got, 12)} ${pad(limit, 14)} ${ok ? 'PASS' : 'FAIL'}`);
}

console.log(`\n  Số không dùng để gate, in ra để lúc fail còn đọc được:`);
console.log(`    avg ${mean(all).toFixed(1)} · p50 ${pct(all, 50)} · p90 ${pct(all, 90)} · p99 ${pct(all, 99)} · max ${maxOf(all)} ms`);
console.log(`    mã trả về: ${[...codes.entries()].sort((a, b) => b[1] - a[1]).map(([c, n]) => `${c}×${n}`).join(' · ')}`);
console.log(`\n  p95 theo endpoint:`);
for (const [label, arr] of [...perLabel.entries()].sort()) {
  console.log(`    ${pad(label, 42)} ${pct(arr, 95)} ms   (${arr.length} sample)`);
}

// ── Ghi vào GitHub Actions job summary ─────────────────────────────────────
if (process.env.GITHUB_STEP_SUMMARY) {
  const md = [
    `### Cổng ngưỡng hiệu năng`,
    ``,
    `| Chỉ số | Đo được | Ngưỡng | |`,
    `|---|---|---|---|`,
    ...rows.map(([n, g, l, ok]) => `| ${n} | **${g}** | ${l} | ${ok ? 'PASS' : '**FAIL**'} |`),
    ``,
    `avg ${mean(all).toFixed(1)} · p50 ${pct(all, 50)} · p90 ${pct(all, 90)} · p99 ${pct(all, 99)} · max ${maxOf(all)} ms`,
    ``,
    `| Endpoint | p95 | Sample |`,
    `|---|---|---|`,
    ...[...perLabel.entries()].sort().map(([l, a]) => `| \`${l}\` | ${pct(a, 95)} ms | ${a.length} |`),
    ``,
  ].join('\n');
  appendFileSync(process.env.GITHUB_STEP_SUMMARY, md);
}

const breached = rows.filter(([, , , ok]) => !ok);
if (breached.length > 0) {
  console.error(`\n  BUILD FAIL — vượt ${breached.length} ngưỡng: ${breached.map(([n]) => n).join(', ')}\n`);
  process.exit(1);
}
console.log(`\n  BUILD PASS — trong mọi ngưỡng.\n`);
