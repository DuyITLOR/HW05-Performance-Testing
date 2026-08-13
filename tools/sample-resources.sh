#!/usr/bin/env bash
# ============================================================================
# sample-resources.sh — lấy mẫu CPU/RSS của backend (và của JMeter) trong lúc chạy test.
#
#   bash tools/sample-resources.sh <file-csv-dau-ra> [chu-ky-giay]
#
# Chạy nền, tự dừng khi nhận SIGTERM. run-scenario.sh gọi nó quanh lượt chạy.
#
# Vì sao cần, khi §6 đã đòi ảnh Activity Monitor:
#   Ảnh chụp là bằng chứng cho người đọc, nhưng KHÔNG tính toán được. Endurance threshold (§6)
#   đòi con số: "RSS đầu lượt → cuối lượt", "trần bộ nhớ". Đọc hai số đó từ ảnh là đoán.
#   File CSV này cho phép nói "RSS tăng từ X lên Y trong 12 phút" và kiểm lại được.
#
#   Nó cũng đo luôn tiến trình `java` của JMeter — thứ ảnh Activity Monitor hay bỏ qua. Nếu
#   JMeter ăn CPU nhiều hơn backend thì nút cổ chai nằm ở load generator, và mọi kết luận về
#   "server chịu tải kém" đều sai. Không có cột này thì không phát hiện được.
# ============================================================================
set -uo pipefail

OUT="${1:?Thieu duong dan file CSV dau ra}"
INTERVAL="${2:-2}"

mkdir -p "$(dirname "$OUT")"
echo "iso_time,epoch,node_pid,node_cpu_pct,node_rss_mb,java_cpu_pct,java_rss_mb,load_1m" > "$OUT"

trap 'exit 0' TERM INT

while true; do
  # KHÔNG dùng `pgrep -f 'node server.js' | head -1`: trên máy này pgrep khớp CẢ tiến trình
  # `/bin/zsh -c …` đã khởi động backend (vì chuỗi đó nằm trong command line của nó), và `head -1`
  # chọn đúng cái shell — RSS 0,5MB, CPU 0,0%. Lượt Load đầu tiên ghi ra một file tài nguyên
  # toàn số vô nghĩa mà vẫn trông như dữ liệu thật.
  # Lọc theo token đầu của command line phải là `node`, không phải shell.
  NODE_PID="$(ps -Ao pid=,command= | awk '/[n]ode server\.js/ && $2 ~ /node$/ {print $1; exit}')"
  if [ -n "$NODE_PID" ]; then
    read -r NCPU NRSS <<< "$(ps -o %cpu=,rss= -p "$NODE_PID" 2>/dev/null | awk '{print $1, $2}')"
  else
    NCPU=""; NRSS=""
  fi

  # JMeter chạy dưới tiến trình java với class ApacheJMeter. Cộng dồn nếu có nhiều tiến trình.
  read -r JCPU JRSS <<< "$(ps -Ao %cpu=,rss=,command= 2>/dev/null \
    | awk '/ApacheJMeter|jmeter/ && !/awk|sample-resources/ {c+=$1; r+=$2} END {printf "%.1f %d", c, r}')"

  LOAD="$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')"

  printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$(date +%s)" \
    "${NODE_PID:-}" \
    "${NCPU:-}" \
    "$(awk -v r="${NRSS:-0}" 'BEGIN {printf "%.1f", r/1024}')" \
    "${JCPU:-}" \
    "$(awk -v r="${JRSS:-0}" 'BEGIN {printf "%.1f", r/1024}')" \
    "${LOAD:-}" >> "$OUT"

  sleep "$INTERVAL"
done
