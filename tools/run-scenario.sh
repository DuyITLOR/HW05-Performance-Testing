#!/usr/bin/env bash
# ============================================================================
# run-scenario.sh — chạy MỘT scenario JMeter ở chế độ non-GUI, sinh .jtl + HTML dashboard.
#
#   bash tools/run-scenario.sh Load
#   bash tools/run-scenario.sh Stress
#   bash tools/run-scenario.sh Spike
#   bash tools/run-scenario.sh Soak   --out endurance    # lượt endurance/soak (§6)
#
# Script này lo 4 việc dễ làm sai nếu gọi jmeter tay:
#   1. Ép JAVA_HOME sang JDK arm64. Máy này `java` mặc định là Temurin 8 **x86_64** → JMeter
#      chạy qua Rosetta, load generator tự nó thành điểm nghẽn và mọi số đo đều nhiễu.
#   2. Reset account-lockout TRƯỚC lượt chạy (§6 đòi làm và đòi ghi lại các bước).
#   3. Xoá sạch folder -o. JMeter từ chối sinh dashboard vào folder không rỗng và báo lỗi
#      SAU KHI đã chạy hết bài test — mất cả lượt chạy.
#   4. Ghi run-log: thời điểm bắt đầu/kết thúc + version tool, để đối chiếu với ảnh
#      Activity Monitor. §11 kiểm bằng chứng có thật, nên timestamp phải khớp nhau.
# ============================================================================
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

SCENARIO="${1:-}"
if [ -z "$SCENARIO" ]; then
  echo "Dùng: bash tools/run-scenario.sh <Load|Stress|Spike|Soak> [--out <folder>]"
  exit 2
fi
shift || true

OUT_ROOT="results"
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT_ROOT="$2"; shift 2 ;;
    *) echo "Tham số lạ: $1"; exit 2 ;;
  esac
done

MSSV="23127178"
LOWER="$(echo "$SCENARIO" | tr '[:upper:]' '[:lower:]')"

# ── Test plan: khớp {MSSV}_{ScenarioType}_{YYYYMMDD}.jmx (§6 quy định tên, §11 kiểm tên) ──
PLAN="$(ls -1 test-plans/${MSSV}_${SCENARIO}_*.jmx 2>/dev/null | sort | tail -1)"
if [ -z "$PLAN" ]; then
  echo "[LOI] Không thấy test plan: test-plans/${MSSV}_${SCENARIO}_YYYYMMDD.jmx"
  echo "      Tên file là thứ §11 kiểm tay — phải đúng {StudentID}_{ScenarioType}_{YYYYMMDD}."
  exit 1
fi

# ── Java arm64 ────────────────────────────────────────────────────────────────
for v in 26 21 17; do
  if JH="$(/usr/libexec/java_home -v "$v" 2>/dev/null)"; then
    export JAVA_HOME="$JH"
    break
  fi
done
if [ -z "${JAVA_HOME:-}" ]; then
  echo "[LUU Y] Không thấy JDK ≥17. JMeter có thể chạy trên Temurin 8 x86_64 (Rosetta) →"
  echo "        số đo bị nhiễu bởi chính load generator. Cân nhắc: brew install temurin"
else
  echo "  JAVA_HOME = $JAVA_HOME"
fi

command -v jmeter >/dev/null || { echo "[LOI] chưa cài JMeter → brew install jmeter"; exit 1; }

# ── Đường dẫn output ─────────────────────────────────────────────────────────
STAMP="$(date +%Y%m%d-%H%M%S)"
JTL="${OUT_ROOT}/jtl/${MSSV}_${SCENARIO}_${STAMP}.jtl"
HTML="${OUT_ROOT}/html/${LOWER}"
LOG="${OUT_ROOT}/jtl/${MSSV}_${SCENARIO}_${STAMP}.jmeter.log"
RUNLOG="${OUT_ROOT}/run-log.md"

mkdir -p "${OUT_ROOT}/jtl" "${OUT_ROOT}/html" "${OUT_ROOT}/resources"

if [ -d "$HTML" ] && [ -n "$(ls -A "$HTML" 2>/dev/null)" ]; then
  echo "  Dọn dashboard cũ: $HTML"
  rm -rf "$HTML"
fi
mkdir -p "$HTML"

# ── Reset lockout trước khi chạy (§6) ────────────────────────────────────────
echo ""
echo "── Reset trạng thái trước lượt chạy ──────────────────────────────────"
node tools/reset-lockout.mjs 2>&1 | tail -4
node tools/reset-orders.mjs 2>&1 | tail -6

# ── Chạy ─────────────────────────────────────────────────────────────────────
echo ""
echo "── ${SCENARIO} ───────────────────────────────────────────────────────"
echo "  plan  : $PLAN"
echo "  jtl   : $JTL"
echo "  html  : $HTML"
echo ""
echo "  MỞ Activity Monitor NGAY BÂY GIỜ và quay/chụp cùng khung hình với terminal này."
echo "  §6 đòi ảnh tool + resource monitor, §11 kiểm hai thứ đó phải ở CÙNG khung."
echo ""

START_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
START_EPOCH="$(date +%s)"

# Lấy mẫu CPU/RSS trong suốt lượt chạy. Ảnh Activity Monitor là bằng chứng cho người đọc,
# file này là bằng chứng tính toán được — endurance threshold (§6) đòi con số RSS đầu/cuối.
RES_CSV="${OUT_ROOT}/resources/${MSSV}_${SCENARIO}_${STAMP}.resources.csv"
bash tools/sample-resources.sh "$RES_CSV" 2 &
SAMPLER_PID=$!
trap 'kill "$SAMPLER_PID" 2>/dev/null' EXIT

jmeter -n \
  -t "$PLAN" \
  -l "$JTL" \
  -j "$LOG" \
  -q tools/jmeter-user.properties \
  -e -o "$HTML" \
  -Jstudent.id="$MSSV" \
  -Jscenario="$SCENARIO"
RC=$?

END_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DURATION=$(( $(date +%s) - START_EPOCH ))

kill "$SAMPLER_PID" 2>/dev/null
trap - EXIT

# Tóm tắt tài nguyên ngay tại đây để không phải mở CSV ra đọc tay.
if [ -f "$RES_CSV" ]; then
  awk -F, 'NR>1 && $5 != "" {
      if (first == "") first = $5
      last = $5
      if ($4 + 0 > maxn) maxn = $4 + 0
      if ($5 + 0 > maxr) maxr = $5 + 0
      if ($6 + 0 > maxj) maxj = $6 + 0
      n++
    }
    END {
      if (n == 0) { print "  (khong lay duoc mau tai nguyen)"; exit }
      printf "  Tai nguyen: node RSS %.1f → %.1f MB (dinh %.1f) · node CPU dinh %.1f%% · JMeter CPU dinh %.1f%%\n", first, last, maxr, maxn, maxj
    }' "$RES_CSV"
fi

# ── Ghi run-log ──────────────────────────────────────────────────────────────
{
  [ -f "$RUNLOG" ] || {
    echo "# Run log — HW05 perf test"
    echo ""
    echo "> Sinh tự động bởi \`tools/run-scenario.sh\`. Dùng để đối chiếu timestamp trong ảnh"
    echo "> Activity Monitor và trong video demo với lượt chạy thật (§11)."
    echo ""
    echo "| Scenario | Bắt đầu (UTC) | Kết thúc (UTC) | Thời lượng | Exit | Test plan | .jtl |"
    echo "|---|---|---|---|---|---|---|"
  }
  echo "| ${SCENARIO} | ${START_ISO} | ${END_ISO} | ${DURATION}s | ${RC} | \`$(basename "$PLAN")\` | \`$(basename "$JTL")\` |"
} >> "$RUNLOG"

echo ""
if [ "$RC" -ne 0 ]; then
  echo "[LOI] JMeter thoát với mã $RC — xem $LOG"
  exit "$RC"
fi

LINES=$(( $(wc -l < "$JTL") - 1 ))
echo "  Xong sau ${DURATION}s · ${LINES} sample trong .jtl"
echo "  Dashboard : open ${HTML}/index.html"
echo "  Tổng hợp  : npm run summary"
echo ""
