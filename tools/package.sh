#!/usr/bin/env bash
# ============================================================================
# package.sh — đóng gói bản nộp theo ĐÚNG danh sách §14, rồi zip.
#
#   bash tools/package.sh 95           # điểm tự chấm → 23127178_HW05_AI_Performance_095.zip
#   bash tools/package.sh 95 --check   # chỉ soát thiếu gì, không tạo gói
#
# Vì sao cần script thay vì kéo thả tay:
#
#   §14 liệt kê đích danh từng thứ phải có, và §17 nói **thiếu bất kỳ tài liệu bắt buộc nào là
#   0 điểm**. Kéo thả tay thì sai một lần là mất cả bài, và không kiểm lại được.
#
#   Quan trọng hơn: `docs/` KHÔNG nằm trong danh sách §14, nhưng §5 (bằng chứng chống trùng
#   trong nhóm) lại được viết đầy đủ nhất ở `docs/endpoint-selection.md`. Bỏ cả `docs/` như HW04
#   đã làm thì mất luôn phần đó, và mọi link từ báo cáo trỏ sang nó thành link chết.
#   Cách xử lý ở đây: nội dung cốt lõi đã được đưa THẲNG vào `report/main-report.md §1.1`, và
#   `docs/endpoint-selection.md` vẫn được nộp kèm dưới dạng *supporting material* (§14 cho phép)
#   để link trong báo cáo còn sống. PLAYBOOK và kịch bản video thì KHÔNG nộp — chúng là tài liệu
#   quy trình nội bộ, không phải bằng chứng.
# ============================================================================
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

GRADE="${1:-}"
CHECK=0
[ "${2:-}" = "--check" ] && CHECK=1
if [ -z "$GRADE" ]; then
  echo "Dùng: bash tools/package.sh <điểm 0-100> [--check]"
  exit 2
fi
if ! [[ "$GRADE" =~ ^[0-9]{1,3}$ ]]; then
  echo "Điểm phải là số nguyên trong [000, 100]."
  exit 2
fi
GRADE_NUM=$((10#$GRADE))
if [ "$GRADE_NUM" -lt 0 ] || [ "$GRADE_NUM" -gt 100 ]; then
  echo "Điểm phải nằm trong [000, 100]."
  exit 2
fi
# §14 ghi rõ SelfAssessedGrade là số 3 chữ số; ví dụ 90 phải thành 090.
printf -v GRADE3 '%03d' "$GRADE_NUM"
MSSV="23127178"
NAME="${MSSV}_HW05_AI_Performance_${GRADE3}"

MISSING=0
need() { # $1 = đường dẫn, $2 = mô tả theo §14
  if [ -e "$1" ]; then
    printf "  [OK]    %-46s %s\n" "$1" "$2"
  else
    printf "  [THIEU] %-46s %s\n" "$1" "$2"
    MISSING=$((MISSING + 1))
  fi
}
needglob() { # $1 = pattern, $2 = số lượng tối thiểu, $3 = mô tả
  local n; n=$(ls -1 $1 2>/dev/null | wc -l | tr -d ' ')
  if [ "$n" -ge "$2" ]; then
    printf "  [OK]    %-46s %s (%s file)\n" "$1" "$3" "$n"
  else
    printf "  [THIEU] %-46s %s — có %s, cần ≥%s\n" "$1" "$3" "$n" "$2"
    MISSING=$((MISSING + 1))
  fi
}

echo ""
echo "══ Soát danh sách §14 ═══════════════════════════════════════════════════"
need "report/main-report.md"              "Main report (Markdown)"
need "report/main-report.pdf"             "Main report (PDF)"
need "ai-audit/ai-audit-report.md"        "AI Audit Report (MD)"
need "ai-audit/ai-audit-report.pdf"       "AI Audit Report (PDF)"
need "ai-audit/task2-ai-output-verbatim.md" "Task 2 — prompt + AI output nguyên văn"
need "ai-audit/task2-ai-output-verbatim.pdf" "Task 2 — output nguyên văn (PDF)"
need "ai-audit/design-log.md"             "Nhật ký thiết kế 7 bước (§2 step-by-step)"
need "ai-audit/ai-critique.md"            "AI Critique (MD) — phải 200–300 từ"
need "ai-audit/ai-critique.pdf"           "AI Critique (PDF)"
need "bug-report/bug-report.md"           "Bug report"
need "README.md"                          "README + self-assessment + test summary"
need "TASKS.md"                           "Bản đồ yêu cầu → file (supporting)"
need "git-log/commit-log.txt"             "Git commit log (text)"
needglob "test-plans/${MSSV}_*.jmx" 3     "Test plan {MSSV}_{Scenario}_{YYYYMMDD}"
needglob "results/jtl/*.jtl" 3            "Raw .jtl (nộp ĐẦY ĐỦ)"
needglob "results/html/*/index.html" 3    "HTML report folder"
need "endurance/endurance-threshold.md"   "Endurance threshold (§6)"
need "ci/ci-runs.md"                      "6 lượt CI thật + output cổng ngưỡng (§4.4)"
need ".github/workflows/perf-smoke.yml"   "Workflow CI hiện thực flow chart Task 3"
need "resource-monitor/hardware-report.md" "Hardware report (hostname khớp HW trước)"
needglob "resource-monitor/screenshots/activity-*.png" 4 "Ảnh resource monitor + tool CÙNG khung"
need "resource-monitor/screenshots/hardware-spec.png" "Ảnh spec phần cứng"
need "resource-monitor/screenshots/manifest.json" "Dấu ảnh: sha256 + giờ chụp (mtime bị cp làm mới)"
needglob "bug-report/screenshots/*.png" 1 "Ảnh bug"

echo ""
echo "── Kiểm nội dung ────────────────────────────────────────────────────────"
WORDS=$(sed -n '/^## Critique/,$p' ai-audit/ai-critique.md 2>/dev/null | sed '1d' | wc -w | tr -d ' ')
if [ "$WORDS" -ge 200 ] && [ "$WORDS" -le 300 ]; then
  printf "  [OK]    AI Critique %s từ (yêu cầu 200–300)\n" "$WORDS"
else
  printf "  [THIEU] AI Critique %s từ — §10 đòi 200–300\n" "$WORDS"
  MISSING=$((MISSING + 1))
fi

if grep -q "youtu" README.md 2>/dev/null; then
  printf "  [OK]    Link video demo có trong README\n"
else
  printf "  [THIEU] Link video demo (≥6 phút, unlisted) chưa có trong README\n"
  MISSING=$((MISSING + 1))
fi

if grep -qE "issues/[0-9]+" bug-report/bug-report.md 2>/dev/null; then
  printf "  [OK]    Số GitHub Issue có trong bug report\n"
else
  printf "  [THIEU] Chưa điền số GitHub Issue vào bug report\n"
  MISSING=$((MISSING + 1))
fi

if grep -qE "sinh viên bổ sung" ai-audit/ai-audit-report.md 2>/dev/null; then
  printf "  [THIEU] AI Audit còn chỗ '(sinh viên bổ sung)' — phần Human review chưa viết\n"
  MISSING=$((MISSING + 1))
else
  printf "  [OK]    AI Audit không còn chỗ trống Human review\n"
fi

if grep -qiE 'repo (HW05 )?(hiện là|đang) \*\*private\*\*|repo đang PRIVATE' README.md 2>/dev/null; then
  printf "  [THIEU] Repo public (§14) — README vẫn ghi repo private; phải dùng repo sạch công khai\n"
  MISSING=$((MISSING + 1))
else
  printf "  [KIEM TAY] Mở link repo bằng cửa sổ ẩn danh để xác nhận Public\n"
fi

echo ""
if [ "$MISSING" -gt 0 ]; then
  echo "  ⚠ Thiếu $MISSING mục. §17: thiếu tài liệu bắt buộc = 0 điểm."
  [ "$CHECK" = "1" ] && exit 1
  echo "  Vẫn đóng gói để xem trước, nhưng ĐỪNG nộp bản này."
  echo ""
else
  echo "  Đủ danh sách file cục bộ §14; vẫn phải kiểm link/video/repo từ cửa sổ ẩn danh."
  echo ""
fi
[ "$CHECK" = "1" ] && exit 0

# ── Dựng gói ────────────────────────────────────────────────────────────────
echo "══ Dựng $NAME ═══════════════════════════════════════════════════════════"
rm -rf "$NAME" "$NAME.zip"
mkdir -p "$NAME"

# Đúng những gì §14 đòi, cộng supporting material có lý do rõ ràng.
for item in \
  report ai-audit bug-report git-log TASKS.md \
  test-plans data results endurance resource-monitor k6 tools ci .github \
  README.md package.json .claude
do
  [ -e "$item" ] && cp -R "$item" "$NAME/"
done

# docs/: CHỈ endpoint-selection.md (bằng chứng §5, báo cáo trỏ link sang).
# PLAYBOOK.md và kịch bản video là tài liệu quy trình nội bộ — không nộp.
mkdir -p "$NAME/docs"
cp docs/endpoint-selection.md "$NAME/docs/"

# Rác không nên có trong bản nộp.
find "$NAME" -name '.DS_Store' -delete 2>/dev/null
rm -rf "$NAME/results/html"/*/trace "$NAME/k6/raw" 2>/dev/null
find "$NAME" -name '*.jmeter.log' -size +5M -delete 2>/dev/null

zip -qr "$NAME.zip" "$NAME"
SIZE=$(du -h "$NAME.zip" | cut -f1)

echo ""
echo "  $NAME.zip  ($SIZE)"
echo ""
echo "  Nội dung:"
du -sh "$NAME"/* 2>/dev/null | sed 's/^/    /'
echo ""
echo "  Kiểm trước khi nộp: unzip -l $NAME.zip | tail -5"
echo ""
