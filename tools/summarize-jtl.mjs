// summarize-jtl.mjs — đọc raw .jtl → results/summary.md
//
//   node tools/summarize-jtl.mjs                       # mọi .jtl trong results/jtl + endurance/jtl
//   node tools/summarize-jtl.mjs results/jtl/x.jtl     # một file
//
// Vì sao cần tool riêng khi JMeter đã có HTML dashboard:
//   1. §11 nói số liệu không được bịa, và cách chắc chắn nhất là **không đếm tay** — mọi con
//      số trong báo cáo truy được về một lệnh chạy lại được trên file .jtl gốc.
//   2. Task 2 đòi "cite the correct value from your raw .jtl log" khi bắt lỗi AI đọc sai
//      metric. Muốn đối chất với AI thì phải có bản tính từ RAW, độc lập với dashboard.
//   3. Dashboard KHÔNG tách elapsed vs latency theo từng label, cũng không phân rã lỗi theo
//      response code. Hai thứ đó là chỗ kết luận nằm: 403 (lockout) và 500 (server thật sự
//      lỗi) mà gộp chung thành "error rate" là đọc sai bản chất.

import { readFileSync, writeFileSync, existsSync, readdirSync, mkdirSync } from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');

// ── CSV parser: URL và failureMessage có thể chứa dấu phẩy trong ngoặc kép ───────
function parseCsv(text) {
  const rows = [];
  let row = [], field = '', inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') { field += '"'; i++; }
        else inQuotes = false;
      } else field += c;
    } else if (c === '"') inQuotes = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); rows.push(row); row = []; field = ''; }
    else if (c !== '\r') field += c;
  }
  if (field.length || row.length) { row.push(field); rows.push(row); }
  return rows.filter((r) => r.length > 1);
}

// Nearest-rank. JMeter dashboard nội suy khác một chút → chênh vài ms ở p99 là bình thường,
// KHÔNG phải bằng chứng file .jtl sai. Ghi rõ để không tự hoảng khi đối chiếu hai bảng.
function pct(sorted, p) {
  if (!sorted.length) return 0;
  const i = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[i];
}
const mean = (a) => (a.length ? a.reduce((s, x) => s + x, 0) / a.length : 0);

// KHÔNG dùng Math.min(...array) / Math.max(...array) trên .jtl: spread đẩy từng phần tử thành
// một tham số, và một lượt Stress có ~90.000 sample → "RangeError: Maximum call stack size
// exceeded". Lỗi này chỉ xuất hiện ở file LỚN, nên lượt Load 16k sample chạy qua bình thường
// và bug ẩn cho tới khi tổng hợp cả 4 lượt.
const minOf = (a) => a.reduce((m, x) => (x < m ? x : m), Infinity);
const maxOf = (a) => a.reduce((m, x) => (x > m ? x : m), -Infinity);
const n1 = (x) => (Math.round(x * 10) / 10).toLocaleString('en-US');

function analyse(file) {
  const rows = parseCsv(readFileSync(file, 'utf8'));
  if (rows.length < 2) return null;
  const header = rows[0].map((h) => h.trim());
  const idx = Object.fromEntries(header.map((h, i) => [h, i]));
  const need = ['timeStamp', 'elapsed', 'label', 'responseCode', 'success'];
  const missing = need.filter((k) => !(k in idx));
  if (missing.length) {
    console.log(`  [BO QUA] ${file} — thiếu cột ${missing.join(', ')} (chạy lại với -q tools/jmeter-user.properties)`);
    return null;
  }

  const samples = [];
  for (const r of rows.slice(1)) {
    const ts = Number(r[idx.timeStamp]);
    const elapsed = Number(r[idx.elapsed]);
    if (!Number.isFinite(ts) || !Number.isFinite(elapsed)) continue;
    samples.push({
      ts,
      elapsed,
      latency: 'Latency' in idx ? Number(r[idx.Latency]) : NaN,
      connect: 'Connect' in idx ? Number(r[idx.Connect]) : NaN,
      label: r[idx.label],
      code: r[idx.responseCode],
      ok: r[idx.success] === 'true',
      threads: 'allThreads' in idx ? Number(r[idx.allThreads]) : NaN,
      bytes: 'bytes' in idx ? Number(r[idx.bytes]) : NaN,
    });
  }
  if (!samples.length) return null;

  const t0 = minOf(samples.map((s) => s.ts));
  const t1 = maxOf(samples.map((s) => s.ts + s.elapsed));
  const durationSec = Math.max((t1 - t0) / 1000, 0.001);

  const byLabel = new Map();
  for (const s of samples) {
    if (!byLabel.has(s.label)) byLabel.set(s.label, []);
    byLabel.get(s.label).push(s);
  }

  const stat = (list) => {
    const el = list.map((s) => s.elapsed).sort((a, b) => a - b);
    const lat = list.map((s) => s.latency).filter(Number.isFinite).sort((a, b) => a - b);
    const errs = list.filter((s) => !s.ok);
    const codes = new Map();
    for (const e of errs) codes.set(e.code, (codes.get(e.code) || 0) + 1);
    // Phân bố code của MỌI sample, kể cả sample được coi là thành công. Cần cho hai chỗ:
    // bước 5 hợp lệ ở cả 200 và 400 (state machine FR-10), và nhánh lockout hợp lệ ở 401/403.
    // Nếu chỉ liệt kê code của sample lỗi thì hai tỉ lệ đó biến mất khỏi báo cáo.
    const allCodes = new Map();
    for (const s of list) allCodes.set(s.code, (allCodes.get(s.code) || 0) + 1);
    return {
      n: list.length,
      errors: errs.length,
      errPct: (errs.length / list.length) * 100,
      codes: [...codes.entries()].sort((a, b) => b[1] - a[1]),
      allCodes: [...allCodes.entries()].sort((a, b) => b[1] - a[1]),
      min: el[0], max: el.at(-1), avg: mean(el),
      p50: pct(el, 50), p90: pct(el, 90), p95: pct(el, 95), p99: pct(el, 99),
      latAvg: lat.length ? mean(lat) : null,
      latP95: lat.length ? pct(lat, 95) : null,
      rps: list.length / durationSec,
    };
  };

  return {
    file,
    name: path.basename(file),
    startIso: new Date(t0).toISOString(),
    durationSec,
    peakThreads: maxOf([...samples.map((s) => s.threads).filter(Number.isFinite), 0]) || null,
    overall: stat(samples),
    labels: [...byLabel.entries()]
      .map(([label, list]) => ({ label, ...stat(list) }))
      .sort((a, b) => b.n - a.n),
  };
}

// ── Chọn file ───────────────────────────────────────────────────────────────────
const argFiles = process.argv.slice(2).filter((a) => !a.startsWith('--'));
let files = argFiles;
if (!files.length) {
  for (const dir of ['results/jtl', 'endurance/jtl']) {
    const abs = path.join(ROOT, dir);
    if (!existsSync(abs)) continue;
    for (const f of readdirSync(abs).filter((f) => f.endsWith('.jtl')).sort()) {
      files.push(path.join(dir, f));
    }
  }
}
if (!files.length) {
  console.log('\nChưa có .jtl nào. Chạy: bash tools/run-scenario.sh Load\n');
  process.exit(0);
}

const results = files.map((f) => analyse(path.resolve(ROOT, f))).filter(Boolean);
if (!results.length) { console.log('\nKhông đọc được .jtl nào.\n'); process.exit(1); }

// Cùng một scenario chạy nhiều lượt → chỉ lượt MỚI NHẤT vào bảng chính, các lượt cũ liệt kê
// riêng. Trộn lẫn rồi chọn số đẹp nhất là cherry-pick, đúng thứ §11 muốn chặn.
const scenarioOf = (name) => (name.match(/_(Load|Stress|Spike|Soak)_/i)?.[1] || 'Khác');
const latestPerScenario = new Map();
for (const r of results) {
  const s = scenarioOf(r.name);
  const cur = latestPerScenario.get(s);
  if (!cur || r.startIso > cur.startIso) latestPerScenario.set(s, r);
}
const order = ['Load', 'Stress', 'Spike', 'Soak', 'Khác'];
const primary = [...latestPerScenario.entries()]
  .sort((a, b) => order.indexOf(a[0]) - order.indexOf(b[0]));

// ── Xuất markdown ───────────────────────────────────────────────────────────────
const out = [];
out.push('# Test summary — HW05 Performance Testing');
out.push('');
out.push(`> **Sinh tự động** bởi \`npm run summary\` lúc ${new Date().toISOString()}, đọc từ raw \`.jtl\`.`);
out.push('> Đừng sửa tay. Mọi con số trong `report/main-report.md` và `README.md` phải khớp bảng này.');
out.push('> Percentile tính theo **nearest-rank**; JMeter dashboard nội suy khác một chút nên chênh');
out.push('> vài ms ở p99 là bình thường — không phải dấu hiệu file `.jtl` sai.');
out.push('');
out.push('## Tổng quan từng scenario');
out.push('');
out.push('| Scenario | Sample | Peak thread | Thời lượng | RPS | Error % | avg | p50 | p90 | **p95** | p99 | max |');
out.push('|---|---|---|---|---|---|---|---|---|---|---|---|');
for (const [scenario, r] of primary) {
  const o = r.overall;
  out.push(`| **${scenario}** | ${o.n.toLocaleString('en-US')} | ${r.peakThreads ?? '-'} | ${n1(r.durationSec)}s | ${n1(o.rps)} | ${n1(o.errPct)}% | ${n1(o.avg)} | ${o.p50} | ${o.p90} | **${o.p95}** | ${o.p99} | ${o.max} |`);
}
out.push('');
out.push('Đơn vị thời gian: **ms**. RPS = số sample / khoảng thời gian thật của lượt chạy.');
out.push('');

for (const [scenario, r] of primary) {
  out.push('---');
  out.push('');
  out.push(`## ${scenario} — \`${r.name}\``);
  out.push('');
  out.push(`- Bắt đầu: \`${r.startIso}\` · thời lượng **${n1(r.durationSec)}s** · peak thread **${r.peakThreads ?? '-'}**`);
  out.push(`- Tổng **${r.overall.n.toLocaleString('en-US')}** sample · error **${n1(r.overall.errPct)}%** · **${n1(r.overall.rps)} RPS**`);
  out.push('');
  out.push('### Theo endpoint');
  out.push('');
  out.push('| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |');
  out.push('|---|---|---|---|---|---|---|---|---|---|');
  for (const l of r.labels) {
    out.push(`| ${l.label} | ${l.n.toLocaleString('en-US')} | ${n1(l.errPct)}% | ${n1(l.avg)} | ${l.p90} | **${l.p95}** | ${l.p99} | ${l.max} | ${l.latAvg === null ? '-' : n1(l.latAvg)} | ${l.latP95 === null ? '-' : l.latP95} |`);
  }
  out.push('');
  out.push('> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.');
  out.push('> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.');
  out.push('');

  // Label nào trả về nhiều hơn một mã → in phân bố. Đây là chỗ đọc ra tỉ lệ 200/400 của bước 5
  // và tỉ lệ 401/403 của nhánh lockout, hai thứ mà bảng "lỗi" không thể hiện được.
  const mixed = r.labels.filter((l) => l.allCodes.length > 1);
  if (mixed.length) {
    out.push('### Phân bố response code (kể cả sample thành công)');
    out.push('');
    out.push('| Endpoint | Code | Số lần | Tỉ lệ |');
    out.push('|---|---|---|---|');
    for (const l of mixed) {
      for (const [code, count] of l.allCodes) {
        out.push(`| ${l.label} | \`${code}\` | ${count.toLocaleString('en-US')} | ${n1((count / l.n) * 100)}% |`);
      }
    }
    out.push('');
    out.push('> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần');
    out.push('> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh');
    out.push('> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.');
    out.push('> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,');
    out.push('> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.');
    out.push('');
  }

  const codeRows = [];
  for (const l of r.labels) {
    for (const [code, count] of l.codes) codeRows.push({ label: l.label, code, count });
  }
  if (codeRows.length) {
    out.push('### Phân rã lỗi theo response code');
    out.push('');
    out.push('| Endpoint | Code | Số lần | Ý nghĩa cần kiểm trước khi kết luận |');
    out.push('|---|---|---|---|');
    const meaning = (c) => ({
      '401': 'Sai credential HOẶC thiếu/hết hạn token — không phải lỗi hiệu năng',
      '403': '**account-lockout** (server.js:40-44) hoặc token sai — KHÔNG được đếm là "server sụp"',
      '400': 'Body sai/thiếu — thường là lỗi test plan, không phải lỗi server',
      '404': 'Sai id trong CSV — kiểm lại data trước khi kết luận',
      '500': 'Lỗi server thật (SQLite busy, exception) — **đây** mới là tín hiệu hiệu năng',
      '503': 'Server từ chối nhận thêm kết nối',
      'Non HTTP response code: java.net.SocketTimeoutException': 'Timeout — server còn sống nhưng không kịp trả',
      'Non HTTP response code: java.net.ConnectException': 'Không nối được — server đã hết backlog hoặc chết',
    })[c] || 'Xem lại raw .jtl';
    for (const row of codeRows.sort((a, b) => b.count - a.count)) {
      out.push(`| ${row.label} | \`${row.code}\` | ${row.count.toLocaleString('en-US')} | ${meaning(row.code)} |`);
    }
    out.push('');
  } else {
    out.push('Không có sample lỗi nào trong lượt này.');
    out.push('');
  }
}

const extra = results.filter((r) => !primary.some(([, p]) => p.file === r.file));
if (extra.length) {
  out.push('---');
  out.push('');
  out.push('## Các lượt chạy cũ (không dùng làm số liệu báo cáo)');
  out.push('');
  out.push('| File | Bắt đầu | Sample | Error % | p95 |');
  out.push('|---|---|---|---|---|');
  for (const r of extra.sort((a, b) => a.startIso.localeCompare(b.startIso))) {
    out.push(`| \`${r.name}\` | ${r.startIso} | ${r.overall.n} | ${n1(r.overall.errPct)}% | ${r.overall.p95} |`);
  }
  out.push('');
  out.push('> Giữ lại để minh bạch quá trình. Bảng chính chỉ lấy **lượt mới nhất của mỗi scenario**.');
  out.push('');
}

mkdirSync(path.join(ROOT, 'results'), { recursive: true });
const dest = path.join(ROOT, 'results/summary.md');
writeFileSync(dest, out.join('\n') + '\n');

console.log(`\n  Đã ghi results/summary.md — ${primary.length} scenario, ${results.length} file .jtl`);
for (const [s, r] of primary) {
  console.log(`    ${s.padEnd(7)} ${String(r.overall.n).padStart(7)} sample · p95 ${String(r.overall.p95).padStart(6)}ms · err ${n1(r.overall.errPct)}%`);
}
console.log('');
