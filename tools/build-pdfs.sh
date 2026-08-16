#!/usr/bin/env bash
# build-pdfs.sh — xuất PDF cho các tài liệu §14 đòi phải có cả Markdown lẫn PDF.
#   bash tools/build-pdfs.sh
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

DOCS=(
  "report/main-report.md"
  "ai-audit/ai-audit-report.md"
  "ai-audit/task2-ai-output-verbatim.md"
  "ai-audit/ai-critique.md"
  "bug-report/bug-report.md"
)

# Máy có thể có nhiều Python; chọn bản đã có `markdown` thay vì phụ thuộc thứ tự PATH.
PYTHON=""
for candidate in python3 /usr/bin/python3 /Library/Frameworks/Python.framework/Versions/3.11/bin/python3; do
  if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import markdown' >/dev/null 2>&1; then
    PYTHON="$candidate"
    break
  fi
done
if [ -z "$PYTHON" ]; then
  echo "  [LOI] Không tìm thấy Python có module markdown."
  echo "        Cài bằng: python3 -m pip install markdown"
  exit 1
fi

for md in "${DOCS[@]}"; do
  if [ ! -f "$md" ]; then
    echo "  [BO QUA] bỏ qua $md (chưa có)"
    continue
  fi
  pdf="${md%.md}.pdf"
  "$PYTHON" tools/md2pdf.py "$md" "$pdf" && echo "  [OK]   $pdf"
done
