#!/usr/bin/env bash
# ============================================================================
# Tạo 2 GitHub Issue cho hai bug HW05 phát hiện. SV: Lê Nhựt Duy — 23127178
#
#   DRY_RUN=1 bash bug-report/create-github-issues.sh   # chỉ in ra, không tạo
#   bash bug-report/create-github-issues.sh              # tạo thật
#
# CHẠY MỘT LẦN. Chạy lại sẽ tạo issue trùng.
#
# Nội dung issue nằm ở file riêng (`issue-p1.md`, `issue-p2.md`) chứ không nhúng trong script.
# Bản đầu dùng heredoc lồng trong $( ) và vỡ cú pháp vì nội dung có backtick + ngoặc — tách file
# thì không còn chuyện escape, và nội dung issue đọc/sửa được như một tài liệu bình thường.
#
# Ảnh (§6 đòi Issue phải CÓ ảnh):
#   gh CLI không upload được ảnh local vào issue. Dùng cách của HW03/HW04: đẩy ảnh lên branch
#   `evidence/` của repo SUT rồi nhúng raw URL. Ảnh hiện ngay trong issue.
#
#   Đẩy qua **GitHub Contents API**, KHÔNG dùng checkout local của eshop-sut — working tree ở đó
#   có nhiều file sửa dở, một lệnh `git add -A` nhầm là đẩy kèm hết. Qua API thì không thể.
# ============================================================================
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

REPO="${REPO:-DuyITLOR/group05_eshop}"
DRY_RUN="${DRY_RUN:-0}"
BRANCH="${EVIDENCE_BRANCH:-evidence/23127178-hw05}"
DIR="docs/bug-evidence/23127178-HW05"
BASE="https://raw.githubusercontent.com/$REPO/$BRANCH/$DIR"
SHOT="bug-report/screenshots/bug-evidence-verify-bugs.png"
IMG_MD="![Bằng chứng chạy verify-bugs.sh]($BASE/bug-evidence-verify-bugs.png)"

echo ">> Repo: $REPO · branch ảnh: $BRANCH · DRY_RUN=$DRY_RUN"
[ -f "$SHOT" ] || { echo "Không thấy ảnh: $SHOT"; exit 1; }
for f in bug-report/issue-p1.md bug-report/issue-p2.md; do
  [ -f "$f" ] || { echo "Không thấy $f"; exit 1; }
  grep -q "__IMAGE__" "$f" || echo "   [luu y] $f không có chỗ chèn __IMAGE__"
done

if [ "$DRY_RUN" != "1" ]; then
  gh auth status >/dev/null || { echo "Chưa đăng nhập gh → gh auth login"; exit 1; }

  # 1. Branch evidence (tạo nếu chưa có)
  DEFAULT=$(gh api "repos/$REPO" --jq .default_branch)
  if gh api "repos/$REPO/git/ref/heads/$BRANCH" >/dev/null 2>&1; then
    echo "   branch $BRANCH đã có"
  else
    SHA=$(gh api "repos/$REPO/git/ref/heads/$DEFAULT" --jq .object.sha)
    gh api "repos/$REPO/git/refs" -f ref="refs/heads/$BRANCH" -f sha="$SHA" >/dev/null
    echo "   tạo branch $BRANCH từ $DEFAULT"
  fi

  # 2. Đẩy ảnh qua Contents API
  path="$DIR/$(basename "$SHOT")"
  existing=$(gh api "repos/$REPO/contents/$path?ref=$BRANCH" --jq .sha 2>/dev/null || true)
  args=(-f "message=evidence(hw05): bang chung verify-bugs.sh"
        -f "branch=$BRANCH"
        -f "content=$(base64 -i "$SHOT" | tr -d '\n')")
  [ -n "$existing" ] && args+=(-f "sha=$existing")
  gh api -X PUT "repos/$REPO/contents/$path" "${args[@]}" >/dev/null
  echo "   đẩy ảnh lên: $path"

  # 3. Label (bỏ qua nếu đã có)
  gh label create "performance-testing" -R "$REPO" --color 0E8A16 \
    --description "Phat hien tu HW05 performance testing" 2>/dev/null || true
  gh label create "security" -R "$REPO" --color D93F0B \
    --description "Lo hong bao mat" 2>/dev/null || true
  gh label create "documentation" -R "$REPO" --color 0075CA \
    --description "Tai lieu lech voi code" 2>/dev/null || true
fi

# ── Tạo issue ───────────────────────────────────────────────────────────────
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

create() { # $1 = file body, $2 = title, $3 = labels
  local body="$tmp/$(basename "$1")"
  # Chèn ảnh vào chỗ __IMAGE__ (python vì sed không xử lý URL có / dễ dàng)
  python3 - "$1" "$body" "$IMG_MD" <<'PY'
import sys
src, dst, img = sys.argv[1], sys.argv[2], sys.argv[3]
open(dst, 'w').write(open(src).read().replace('__IMAGE__', img))
PY
  if [ "$DRY_RUN" = "1" ]; then
    echo ""
    echo "════ [DRY_RUN] $2"
    echo "labels : $3"
    echo "body   : $(wc -l < "$body") dòng · ảnh nhúng: $(grep -c 'raw.githubusercontent' "$body")"
    head -6 "$body" | sed 's/^/  /'
    echo "  …"
    return 0
  fi
  gh issue create -R "$REPO" --title "$2" --body-file "$body" --label "$3"
}

create bug-report/issue-p1.md \
  "BUG-P1: GET /api/orders/:id doc duoc don hang cua nguoi khac, khong can token" \
  "security,performance-testing"

create bug-report/issue-p2.md \
  "BUG-P2: POST /api/coupon-usage khong co trong api_specification.md" \
  "documentation,performance-testing"

echo ""
if [ "$DRY_RUN" = "1" ]; then
  echo ">> DRY_RUN — chưa tạo gì. Bỏ DRY_RUN=1 để tạo thật."
else
  echo ">> Xong. Điền số Issue vào bảng mục 1 của bug-report/bug-report.md."
  echo ">> Kiểm ảnh: curl -sI $BASE/bug-evidence-verify-bugs.png | head -1   (phải là 200)"
fi
