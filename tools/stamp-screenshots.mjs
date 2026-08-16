// ============================================================================
// stamp-screenshots.mjs — đóng dấu bộ ảnh bằng chứng: sha256 + giờ chụp + lượt chạy tương ứng.
//
//   node tools/stamp-screenshots.mjs          # ghi resource-monitor/screenshots/manifest.json
//   node tools/stamp-screenshots.mjs --check   # chỉ kiểm, không ghi
//
// VÌ SAO CẦN: `verify-all.sh` từng kiểm §11 bằng **mtime** của ảnh — mtime phải nằm trong khoảng
// lượt chạy của run-log. Cách đó đúng trong repo gốc nhưng **sai trong bản nộp**: `package.sh` dùng
// `cp -R`, và `cp` đặt mtime mới cho bản copy. Người chấm mở `.zip` rồi chạy validator sẽ thấy đỏ
// toàn bộ, dù ảnh hoàn toàn thật.
//
// Manifest giải quyết bằng cách **chốt giờ chụp thành dữ liệu** thay vì đọc từ metadata filesystem:
//
//   - `captured_at`  ghi một lần từ mtime trong repo gốc, sau đó không đổi dù copy bao nhiêu lần.
//   - `sha256`       phát hiện ảnh bị đổi SAU KHI đóng dấu. Nói cho đúng: nó KHÔNG chống được người
//                    cố ý sửa ảnh rồi chạy lại stamp — manifest nằm cùng repo nên hash cập nhật theo.
//                    Cái nó chống được là thay đổi vô tình và sai sót lúc đóng gói. Đừng đọc nó
//                    thành một dấu xác thực.
//   - `run`          lượt chạy tương ứng trong run-log, cùng offset giây tính từ lúc lượt bắt đầu.
//
// Manifest KHÔNG chứng minh ảnh chụp đúng cái gì — nó chỉ chốt "file này, giờ này". Nội dung trong
// ảnh vẫn phải xem bằng mắt. Ghi rõ ở đây để không ai đọc manifest thành một dấu xác thực.
// ============================================================================
import { readFileSync, writeFileSync, existsSync, statSync, readdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');
const SHOTS = path.join(ROOT, 'resource-monitor/screenshots');
const OUT = path.join(SHOTS, 'manifest.json');
const CHECK = process.argv.includes('--check');

const sha = (f) => createHash('sha256').update(readFileSync(f)).digest('hex');

// ── Đọc run-log để gắn ảnh với lượt chạy ────────────────────────────────────
const runs = [];
for (const rel of ['results/run-log.md', 'endurance/run-log.md']) {
  const abs = path.join(ROOT, rel);
  if (!existsSync(abs)) continue;
  for (const line of readFileSync(abs, 'utf8').split('\n')) {
    const m = line.match(/^\|\s*(Load|Stress|Spike|Soak)\s*\|\s*(\S+Z)\s*\|\s*(\S+Z)\s*\|/);
    if (m) runs.push({ scenario: m[1], start: m[2], end: m[3], jtl: (line.match(/`([^`]*\.jtl)`/) ?? [])[1] });
  }
}

const SCENARIO_OF = { 'activity-load.png': 'Load', 'activity-stress.png': 'Stress',
                      'activity-spike.png': 'Spike', 'activity-soak.png': 'Soak' };

const prev = existsSync(OUT) ? JSON.parse(readFileSync(OUT, 'utf8')) : { screenshots: {} };
const out = { note: 'captured_at chốt một lần từ repo gốc — KHÔNG đọc lại mtime, vì cp/zip đặt mtime mới. sha256 phát hiện ảnh bị ĐỔI SAU KHI đóng dấu (copy sai, ghi đè vô tình, hoặc thay ảnh mà quên chạy lại stamp) — nó KHÔNG chống được người cố ý sửa ảnh rồi cập nhật luôn hash, vì manifest nằm cùng repo. Không phải dấu xác thực. Nội dung trong ảnh vẫn phải xem bằng mắt.', screenshots: {} };

let changed = 0, problems = 0;
for (const f of readdirSync(SHOTS).filter((f) => f.endsWith('.png')).sort()) {
  const abs = path.join(SHOTS, f);
  const digest = sha(abs);
  const old = prev.screenshots?.[f];

  // Giữ captured_at cũ nếu ảnh KHÔNG đổi. Chỉ lấy mtime khi ảnh mới hoặc đã thay nội dung.
  const captured = old && old.sha256 === digest ? old.captured_at : new Date(statSync(abs).mtimeMs).toISOString();
  if (!old) changed++;
  else if (old.sha256 !== digest) { changed++; console.log(`  [đổi] ${f} — sha256 khác, cập nhật captured_at`); }

  const entry = { sha256: digest, captured_at: captured, bytes: statSync(abs).size };

  const scen = SCENARIO_OF[f];
  if (scen) {
    const r = runs.filter((r) => r.scenario === scen).pop();
    if (r) {
      const t = Date.parse(captured), s = Date.parse(r.start), e = Date.parse(r.end);
      entry.run = { scenario: scen, start: r.start, end: r.end, jtl: r.jtl };
      entry.offset_s = Math.round((t - s) / 1000);
      entry.inside_run = t >= s && t <= e;
      if (!entry.inside_run) { problems++; console.log(`  [LƯU Ý] ${f} — giờ chụp NGOÀI khoảng lượt ${scen}`); }
    }
  }
  out.screenshots[f] = entry;
}

if (CHECK) {
  let bad = 0;
  for (const [f, e] of Object.entries(prev.screenshots ?? {})) {
    const abs = path.join(SHOTS, f);
    if (!existsSync(abs)) { console.log(`  [THIẾU] ${f}`); bad++; continue; }
    if (sha(abs) !== e.sha256) { console.log(`  [SAI HASH] ${f} — ảnh đã bị thay so với manifest`); bad++; }
  }
  console.log(bad === 0 ? `\n  Manifest khớp — ${Object.keys(prev.screenshots ?? {}).length} ảnh, hash đúng.\n`
                        : `\n  ${bad} ảnh không khớp manifest.\n`);
  process.exit(bad === 0 ? 0 : 1);
}

writeFileSync(OUT, JSON.stringify(out, null, 2) + '\n');
console.log(`\n  Đã ghi ${path.relative(ROOT, OUT)} — ${Object.keys(out.screenshots).length} ảnh`
          + `${changed ? `, ${changed} mục mới/đổi` : ', không có gì đổi'}`
          + `${problems ? `, ${problems} ảnh ngoài khoảng lượt chạy` : ''}\n`);
for (const [f, e] of Object.entries(out.screenshots)) {
  const tag = e.run ? (e.inside_run ? `giây ${e.offset_s} của lượt ${e.run.scenario}` : `NGOÀI lượt ${e.run.scenario}`) : '—';
  console.log(`    ${f.padEnd(30)} ${e.captured_at}  ${tag}`);
}
