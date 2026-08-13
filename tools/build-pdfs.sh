#!/usr/bin/env bash
# build-pdfs.sh — xuất PDF cho các tài liệu §14 đòi phải có cả Markdown lẫn PDF.
#   bash tools/build-pdfs.sh
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

DOCS=(
  "report/main-report.md"
  "ai-audit/ai-audit-report.md"
  "ai-audit/ai-critique.md"
  "bug-report/bug-report.md"
)

for md in "${DOCS[@]}"; do
  if [ ! -f "$md" ]; then
    echo "  [BO QUA] bỏ qua $md (chưa có)"
    continue
  fi
  pdf="${md%.md}.pdf"
  python3 tools/md2pdf.py "$md" "$pdf" && echo "  [OK]   $pdf"
done
