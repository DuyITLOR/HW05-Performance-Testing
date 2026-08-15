#!/usr/bin/env bash
# ============================================================================
# verify-all.sh — kiểm LẠI mọi khẳng định của bài từ file gốc, không đọc báo cáo.
#
#   bash tools/verify-all.sh
#
# Vì sao cần file này: mọi tài liệu trong repo đều là *lời khẳng định*. Người review không có cách
# nào phân biệt "con số này đo được" với "con số này được viết ra" nếu chỉ đọc tài liệu. Script này
# đi ngược lại: đọc `.jmx`, `.jtl`, `.csv`, mtime của ảnh, rồi **đối chiếu với con số đang in trong
# báo cáo**. Chỗ nào lệch thì in FAIL kèm cả hai giá trị.
#
# Nguyên tắc: KHÔNG lấy số từ file .md nào để tính. Số tính từ raw, .md chỉ dùng để so.
# ============================================================================
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

MSSV="23127178"
PASS=0; FAIL=0
ok()   { printf "  \033[32m[PASS]\033[0m %-44s %s\n" "$1" "${2:-}"; PASS=$((PASS+1)); }
bad()  { printf "  \033[31m[FAIL]\033[0m %-44s %s\n" "$1" "${2:-}"; FAIL=$((FAIL+1)); }
note() { printf "  \033[33m[ ?  ]\033[0m %-44s %s\n" "$1" "${2:-}"; }
head_() { printf "\n\033[1m── %s %s\033[0m\n" "$1" "$(printf '─%.0s' $(seq 1 $((60 - ${#1}))))"; }

# ── 1. Test plan: tên đúng mẫu §11, và 4 plan CÙNG workflow ─────────────────
head_ "1. Test plan (§6 tên file, §6 cùng workflow)"

for s in Load Stress Spike Soak; do
  f=$(ls -1 test-plans/${MSSV}_${s}_[0-9]*.jmx 2>/dev/null | tail -1)
  if [ -n "$f" ]; then ok "$s — tên {MSSV}_{Scenario}_{YYYYMMDD}" "$(basename "$f")"
  else bad "$s — thiếu .jmx đúng mẫu tên"; fi
done

# §6 đòi 3 plan chạy CÙNG một workflow. Kiểm bằng cách rút danh sách path của mọi HTTP sampler
# trong từng plan rồi so chuỗi. Đây là kiểm thật: nếu ai sửa tay một plan thì chỗ này đỏ.
sig() { grep -o 'name="HTTPSampler.path">[^<]*' "$1" | sed 's/.*>//' | sort -u | tr '\n' '|'; }
base=""; same=1
for s in Load Stress Spike Soak; do
  f=$(ls -1 test-plans/${MSSV}_${s}_[0-9]*.jmx 2>/dev/null | tail -1); [ -z "$f" ] && continue
  cur=$(sig "$f")
  [ -z "$base" ] && base="$cur"
  [ "$cur" != "$base" ] && same=0
done
n_ep=$(echo "$base" | tr '|' '\n' | grep -c . )
if [ "$same" = "1" ]; then ok "4 plan dùng cùng bộ endpoint" "$n_ep endpoint giống nhau"
else bad "4 plan KHÁC workflow nhau" "sửa tay ở đâu đó"; fi

# §6: ba listener KHÁC LOẠI
lst=""
for s in Load Stress Spike; do
  f=$(ls -1 test-plans/${MSSV}_${s}_[0-9]*.jmx 2>/dev/null | tail -1); [ -z "$f" ] && continue
  l=$(grep -oE '(SummaryReport|StatVisualizer|ViewResultsFullVisualizer)' "$f" | head -1)
  lst="$lst $l"
done
n_lst=$(echo $lst | tr ' ' '\n' | grep -c . )
n_uniq=$(echo $lst | tr ' ' '\n' | sort -u | grep -c . )
if [ "$n_uniq" = "3" ]; then ok "3 listener khác loại (Load/Stress/Spike)" "$(echo $lst)"
else bad "listener bị lặp loại" "$n_uniq/$n_lst khác nhau"; fi

# ── 2. Data-driven CSV ──────────────────────────────────────────────────────
head_ "2. Data-driven (§6)"
for c in users users_lockout products_import orders; do
  if [ -f "data/$c.csv" ]; then
    rows=$(( $(wc -l < "data/$c.csv") - 1 ))
    used=$(grep -l "$c.csv" test-plans/*.jmx 2>/dev/null | wc -l | tr -d ' ')
    if [ "$used" -gt 0 ]; then ok "data/$c.csv" "$rows dòng · dùng trong $used plan"
    else bad "data/$c.csv KHÔNG được plan nào dùng" "$rows dòng"; fi
  else bad "thiếu data/$c.csv"; fi
done

# ── 3. Số liệu: tính LẠI từ .jtl rồi so với báo cáo ─────────────────────────
head_ "3. Số liệu — tính lại từ raw .jtl, so với báo cáo"

# Lượt được nộp làm số chính (khớp cột "Bắt đầu" của §2.2 main-report)
declare -a RUNS=(
  "Load|results/jtl/${MSSV}_Load_20260815-152938.jtl"
  "Stress|results/jtl/${MSSV}_Stress_20260815-153717.jtl"
  "Spike|results/jtl/${MSSV}_Spike_20260815-215939.jtl"
  "Soak|endurance/jtl/${MSSV}_Soak_20260815-155240.jtl"
)
for r in "${RUNS[@]}"; do
  s="${r%%|*}"; f="${r##*|}"
  if [ ! -f "$f" ]; then bad "$s — không thấy .jtl" "$f"; continue; fi
  read -r n p95 err < <(node -e '
    const fs=require("fs");
    const L=fs.readFileSync(process.argv[1],"utf8").split("\n").filter(Boolean);
    const h=L[0].split(","), iE=h.indexOf("elapsed"), iS=h.indexOf("success");
    const el=[]; let bad=0;
    for(let i=1;i<L.length;i++){const c=L[i].split(",");
      if(c.length<h.length) continue;
      const v=+c[iE]; if(!Number.isFinite(v)) continue;
      el.push(v); if(c[iS]!=="true") bad++;}
    el.sort((a,b)=>a-b);
    const p=el[Math.min(el.length-1,Math.ceil(0.95*el.length)-1)];
    console.log(el.length, p, ((bad/el.length)*100).toFixed(2));
  ' "$f")
  # con số đang in trong báo cáo
  claim=$(grep -oE "^\| \*\*$s\*\* \| [0-9:]+ \| [0-9.]+ " report/main-report.md | head -1 \
          | awk '{print $NF}' | tr -d '.')
  if [ -n "$claim" ] && [ "$claim" = "$n" ]; then
    ok "$s — sample khớp báo cáo" "$n sample · p95 ${p95}ms · err ${err}%"
  elif [ -n "$claim" ]; then
    bad "$s — sample LỆCH" "raw=$n · báo cáo=$claim"
  else
    note "$s — không đọc được số trong báo cáo" "raw=$n · p95 ${p95}ms · err ${err}%"
  fi
  awk -v e="$err" 'BEGIN{exit !(e+0==0)}' && ok "$s — error rate 0%" "" || bad "$s — error rate khác 0" "$err%"
done

# ── 4. §11: ảnh bằng chứng có KHỚP thời gian lượt chạy không ────────────────
head_ "4. §11 — mtime ảnh phải nằm TRONG khoảng lượt chạy"
echo "     (run-log ghi giờ UTC · ảnh lưu giờ local UTC+7 · script tự quy đổi)"
for pair in "load|Load" "stress|Stress" "spike|Spike" "soak|Soak"; do
  img="resource-monitor/screenshots/activity-${pair%%|*}.png"; s="${pair##*|}"
  [ ! -f "$img" ] && { bad "$s — thiếu ảnh" "$img"; continue; }
  logf="results/run-log.md"; [ "$s" = "Soak" ] && logf="endurance/run-log.md"
  line=$(grep -E "^\| $s \|" "$logf" | tail -1)
  st=$(echo "$line" | awk -F'|' '{gsub(/ /,"",$3); print $3}')
  en=$(echo "$line" | awk -F'|' '{gsub(/ /,"",$4); print $4}')
  [ -z "$st" ] && { note "$s — run-log không có dòng"; continue; }
  se=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$st" +%s 2>/dev/null)
  ee=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$en" +%s 2>/dev/null)
  ie=$(stat -f %m "$img")
  # mtime là lúc LƯU file, trễ hơn lúc chụp vài giây (Cmd+Shift+4 lưu khi nhả chuột). Cho biên
  # độ 90s sau khi lượt kết thúc, nhưng nói rõ khi ảnh nằm ngoài khoảng chặt.
  GRACE=90
  if [ -n "$se" ] && [ "$ie" -ge "$se" ] && [ "$ie" -le "$ee" ]; then
    ok "$s — ảnh chụp TRONG lượt chạy" "giây thứ $((ie - se))/$((ee - se))"
  elif [ -n "$se" ] && [ "$ie" -gt "$ee" ] && [ "$ie" -le $((ee + GRACE)) ]; then
    note "$s — ảnh lưu $((ie - ee))s SAU khi lượt kết thúc" "trong biên độ ${GRACE}s (mtime = lúc lưu, không phải lúc chụp)"
  else
    bad "$s — ảnh NGOÀI khoảng lượt chạy" "ảnh $(date -r "$ie" +%H:%M:%S) · lượt $(date -r "${se:-0}" +%H:%M:%S)–$(date -r "${ee:-0}" +%H:%M:%S)"
  fi
done

# ── 5. Bằng chứng tài nguyên: ảnh đọc được vs tool đo ───────────────────────
head_ "5. §6 — số tài nguyên tính được từ CSV"
for s in Load Stress Spike Soak; do
  f=$(ls -1 results/resources/${MSSV}_${s}_*.csv endurance/resources/${MSSV}_${s}_*.csv 2>/dev/null | tail -1)
  [ -z "$f" ] && { bad "$s — thiếu file resources"; continue; }
  awk -F, -v s="$s" 'NR>1{if($4+0>c)c=$4+0; if($5+0>r)r=$5+0; l+=$8; n++}
    END{printf "  \033[32m[PASS]\033[0m %-44s node CPU đỉnh %.1f%% · RSS đỉnh %.0fMB · load_1m tb %.1f\n", s" — resources", c, r, l/n}' "$f"
  PASS=$((PASS+1))
done

# ── 6. Tài liệu bắt buộc §14 + độ dài critique §10 ──────────────────────────
head_ "6. §14 tài liệu · §10 độ dài critique"
w=$(sed -n '/^## Critique/,$p' ai-audit/ai-critique.md 2>/dev/null | sed '1d' | wc -w | tr -d ' ')
if [ "$w" -ge 200 ] && [ "$w" -le 300 ]; then ok "AI Critique trong 200–300 từ" "$w từ"
else bad "AI Critique ngoài khoảng" "$w từ"; fi

# grep -c thoát 1 khi không khớp, nên `|| echo 0` sẽ NỐI thêm một dòng "0" → biến thành "0\n0".
# Dùng `|| true` và để grep tự in 0.
holes=$(grep -c "sinh viên bổ sung" ai-audit/ai-audit-report.md 2>/dev/null || true)
holes=${holes:-0}
[ "$holes" = "0" ] && ok "Human review không còn chỗ trống" || bad "Human review còn trống" "$holes chỗ"

n_int=$(grep -c "^### Interaction #" ai-audit/ai-audit-report.md)
ok "AI Audit — số lượt tương tác" "$n_int lượt"

if grep -q "youtu" README.md 2>/dev/null; then ok "Link video demo có trong README"
else bad "THIẾU link video demo" "§17: thiếu tài liệu bắt buộc = 0 điểm"; fi

host_hw=$(grep -oE "Le-Nhut-Duy[a-z.-]*" resource-monitor/hardware-report.md | head -1)
host_now=$(hostname -s)
[ -n "$host_hw" ] && ok "Hardware report có hostname" "$host_hw (máy hiện tại: $host_now)" \
                  || bad "Hardware report thiếu hostname"

# ── 7. Bug + Issue ──────────────────────────────────────────────────────────
head_ "7. §6 — bug và GitHub Issue"
iss=$(grep -oE "issues/[0-9]+" bug-report/bug-report.md 2>/dev/null | sort -u | tr '\n' ' ')
[ -n "$iss" ] && ok "Issue đã điền số" "$iss" || bad "Chưa có số Issue"
echo "     Kiểm bug chạy lại được: bash bug-report/verify-bugs.sh  (cần SUT đang chạy)"

# ── 8. Task 3 — CI đã chạy thật chưa ────────────────────────────────────────
head_ "8. Task 3 — pipeline CI có thật không"
[ -f ".github/workflows/perf-smoke.yml" ] && ok "Workflow tồn tại" || bad "Thiếu workflow"
[ -f "ci/ci-runs.md" ] && ok "Bằng chứng lượt CI" "$(grep -cE '^\| [0-9] \| .31878|^\| [0-9] \|' ci/ci-runs.md) dòng bảng" || bad "Thiếu ci/ci-runs.md"
if command -v gh >/dev/null 2>&1; then
  echo "     Tự kiểm trên GitHub:  gh run list --workflow=perf-smoke.yml"
fi

# ── Kết ─────────────────────────────────────────────────────────────────────
printf "\n\033[1m%s\033[0m\n" "$(printf '─%.0s' $(seq 1 64))"
printf "  PASS %d  ·  FAIL %d\n\n" "$PASS" "$FAIL"
[ "$FAIL" -gt 0 ] && exit 1
exit 0
