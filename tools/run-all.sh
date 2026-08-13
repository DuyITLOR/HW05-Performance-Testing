#!/usr/bin/env bash
# ============================================================================
# run-all.sh — chạy tuần tự cả 3 scenario (§6: Load, Stress, Spike) rồi tổng hợp.
#
#   bash tools/run-all.sh                 # 3 scenario + summary
#   bash tools/run-all.sh --with-soak     # thêm lượt endurance/soak 10–15 phút
#
# CHẠY TUẦN TỰ, KHÔNG SONG SONG. Chạy song song thì 3 lượt tranh CPU của nhau và cả 3 bộ
# số liệu đều vô nghĩa — không còn biết p95 xấu vì endpoint hay vì lượt bên cạnh.
#
# COOLDOWN giữa các lượt là bắt buộc, không phải cho đẹp: SQLite giữ WAL/checkpoint và
# Node giữ heap sau Stress; chạy Spike ngay sau đó là đo một server CHƯA hồi phục, và
# đó là lỗi đọc số liệu kinh điển mà Task 2 yêu cầu chỉ ra.
# ============================================================================
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

COOLDOWN="${COOLDOWN:-90}"
WITH_SOAK=0
[ "${1:-}" = "--with-soak" ] && WITH_SOAK=1

echo ""
echo "══ Preflight ═══════════════════════════════════════════════════════════"
node tools/preflight.mjs || { echo "Preflight thất bại — dừng."; exit 1; }

SCENARIOS=(Load Stress Spike)

for i in "${!SCENARIOS[@]}"; do
  S="${SCENARIOS[$i]}"
  echo ""
  echo "══ [$((i + 1))/${#SCENARIOS[@]}] $S ════════════════════════════════════════════════════"
  bash tools/run-scenario.sh "$S" || { echo "[LOI] $S thất bại — dừng để giữ nguyên bằng chứng."; exit 1; }

  if [ "$i" -lt $((${#SCENARIOS[@]} - 1)) ]; then
    echo "  Cooldown ${COOLDOWN}s để server hồi phục trước lượt sau…"
    sleep "$COOLDOWN"
  fi
done

if [ "$WITH_SOAK" = "1" ]; then
  echo ""
  echo "══ Endurance / soak ════════════════════════════════════════════════════"
  echo "  Cooldown ${COOLDOWN}s…"; sleep "$COOLDOWN"
  bash tools/run-scenario.sh Soak --out endurance || exit 1
fi

echo ""
echo "══ Tổng hợp ════════════════════════════════════════════════════════════"
node tools/summarize-jtl.mjs

echo ""
echo "  Xong cả ${#SCENARIOS[@]} scenario. Việc tiếp theo:"
echo "    1. Kiểm results/summary.md — số trong báo cáo CHỈ được lấy từ đây, không đếm tay (§11)."
echo "    2. open results/html/load/index.html  (và stress/, spike/)"
echo "    3. Đối chiếu results/run-log.md với ảnh Activity Monitor đã chụp."
echo ""
