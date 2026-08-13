#!/usr/bin/env bash
# ============================================================================
# hardware-report.sh — sinh bảng spec phần cứng cho §6 ("a dxdiag/screenfetch screenshot
# and a spec table") → resource-monitor/hardware-report.md
#
#   bash tools/hardware-report.sh
#
# §11 kiểm: **hostname phải khớp các HW trước**. Vì thế hostname nằm ở dòng đầu bảng, và
# script in cả `whoami` để dùng làm cảnh mở đầu video demo như HW04 đã làm.
#
# Endurance threshold (§6) chỉ có nghĩa khi gắn với đúng cấu hình máy này. Bảng spec chính
# là mẫu số của con số đó — thiếu nó thì "max stable RPS = N" không nói được điều gì.
# ============================================================================
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

OUT="resource-monitor/hardware-report.md"
mkdir -p resource-monitor/screenshots

CHIP="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo '?')"
CORES="$(sysctl -n hw.ncpu)"
PCORES="$(sysctl -n hw.perflevel0.logicalcpu 2>/dev/null || echo '-')"
ECORES="$(sysctl -n hw.perflevel1.logicalcpu 2>/dev/null || echo '-')"
MEM_GB=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
MODEL="$(sysctl -n hw.model)"
OSV="$(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
KERNEL="$(uname -mrs)"
HOSTNAME_S="$(hostname)"
USER_S="$(whoami)"
DISK="$(df -h / | awk 'NR==2 {print $2" tổng, "$4" trống"}')"

jver() { command -v "$1" >/dev/null && "$@" 2>&1 | head -1 || echo 'chưa cài'; }
JMETER_V="$(jver jmeter --version | tr -d '\r')"
K6_V="$(jver k6 version)"
NODE_V="$(jver node --version)"
JAVA_ARM="$(/usr/libexec/java_home -v 26 2>/dev/null || /usr/libexec/java_home -v 21 2>/dev/null || echo '-')"

{
  echo "# Hardware report — HW05 Performance Testing"
  echo ""
  echo "> Sinh tự động bởi \`tools/hardware-report.sh\` lúc **$(date -u +%Y-%m-%dT%H:%M:%SZ)** (UTC)."
  echo "> §11 kiểm hostname khớp với các HW trước — hostname ở dòng đầu bảng."
  echo ""
  echo "## Máy chạy test (load generator **và** SUT nằm cùng máy)"
  echo ""
  echo "| Hạng mục | Giá trị |"
  echo "|---|---|"
  echo "| **Hostname** | \`${HOSTNAME_S}\` |"
  echo "| User | \`${USER_S}\` |"
  echo "| Model | ${MODEL} |"
  echo "| CPU | ${CHIP} |"
  echo "| Số lõi logic | ${CORES} (performance: ${PCORES} · efficiency: ${ECORES}) |"
  echo "| RAM | ${MEM_GB} GB |"
  echo "| Ổ đĩa (/) | ${DISK} |"
  echo "| OS | ${OSV} |"
  echo "| Kernel | ${KERNEL} |"
  echo ""
  echo "## Công cụ"
  echo ""
  echo "| Công cụ | Version |"
  echo "|---|---|"
  echo "| JMeter | ${JMETER_V} |"
  echo "| Java (arm64, dùng để chạy JMeter) | ${JAVA_ARM} |"
  echo "| k6 (bonus) | ${K6_V} |"
  echo "| Node.js (backend SUT + tool) | ${NODE_V} |"
  echo ""
  echo "## Điều phải nói rõ khi đọc mọi con số của bài này"
  echo ""
  echo "Load generator (JMeter) và SUT (Node + SQLite) chạy **trên cùng một máy ${MEM_GB}GB /"
  echo "${CORES} lõi**. Nghĩa là:"
  echo ""
  echo "- Ở mức tải cao, JMeter và backend **tranh cùng số lõi đó**. Một phần latency đo được"
  echo "  là chi phí của chính load generator, không phải của server. Đây là giới hạn phải"
  echo "  khai báo, không phải thứ để che."
  echo "- Endurance threshold tìm ra vì thế là **ngưỡng của cấu hình \"cùng máy\" này**, không"
  echo "  phải năng lực tối đa của backend nếu tách máy."
  echo "- Backend là Node **một process, một luồng JS** + SQLite ghi tuần tự → ngưỡng sẽ chạm"
  echo "  ở mức thấp hơn kỳ vọng của một server production, và đó là kết quả đúng của SUT này."
  echo ""
  echo "## Ảnh bằng chứng"
  echo ""
  echo "| Ảnh | File |"
  echo "|---|---|"
  echo "| Activity Monitor — lượt Load | \`screenshots/activity-load.png\` |"
  echo "| Activity Monitor — lượt Stress | \`screenshots/activity-stress.png\` |"
  echo "| Activity Monitor — lượt Spike | \`screenshots/activity-spike.png\` |"
  echo "| Activity Monitor — lượt Soak | \`screenshots/activity-soak.png\` |"
  echo "| Spec máy (screenfetch / About This Mac) | \`screenshots/hardware-spec.png\` |"
  echo ""
  echo "> Mỗi ảnh phải có **JMeter và resource monitor trong CÙNG khung hình** (§6), và"
  echo "> timestamp khớp dòng tương ứng trong [\`results/run-log.md\`](../results/run-log.md)."
} > "$OUT"

echo "  Đã ghi $OUT"
echo ""
echo "  Chụp ảnh spec: mở screenfetch/neofetch (brew install screenfetch) hoặc  Apple > About This Mac"
echo "  Lưu vào      : resource-monitor/screenshots/hardware-spec.png"
