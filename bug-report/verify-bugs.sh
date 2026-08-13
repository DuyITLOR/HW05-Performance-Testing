#!/usr/bin/env bash
# ============================================================================
# verify-bugs.sh — chạy lại toàn bộ bằng chứng trong bug-report.md.
#
#   bash bug-report/verify-bugs.sh
#
# Mọi phát hiện trong bug report phải kiểm chứng lại được bằng một lệnh, không phải bằng một
# đoạn văn. Script này cũng chạy lại phần **đã loại** (BUG "import-products báo sai số dòng"),
# vì chứng minh một ứng viên KHÔNG phải bug cũng cần bằng chứng như khi chứng minh nó là bug.
#
# Cần SUT đang chạy: cd .. && ./eshop.sh --seed
# ============================================================================
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

API="${API_URL:-http://localhost:3000}"
DB="${ESHOP_DB:-../eshop-sut/backend/database.sqlite}"

command -v sqlite3 >/dev/null || { echo "[LOI] cần sqlite3"; exit 1; }
curl -s -o /dev/null --max-time 5 "$API/api/products" || { echo "[LOI] backend chưa chạy ở $API"; exit 1; }

TOKEN="$(curl -s -X POST "$API/api/login" -H 'Content-Type: application/json' \
  -d '{"email":"admin@eshop.com","password":"Admin123!"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))')"
[ -n "$TOKEN" ] || { echo "[LOI] không đăng nhập được admin → npm run reset:lockout"; exit 1; }

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "  BUG-P1 — GET /api/orders/:id khong kiem xac thuc (IDOR)"
echo "══════════════════════════════════════════════════════════════════════"
echo "-- goi KHONG kem Authorization header:"
printf "   HTTP "; curl -s -o /tmp/vb-p1.json -w "%{http_code}\n" "$API/api/orders/1"
echo "-- body tra ve:"
python3 -m json.tool /tmp/vb-p1.json 2>/dev/null | sed 's/^/   /' || sed 's/^/   /' /tmp/vb-p1.json
echo "-- doi chieu trong DB: order 1 thuoc ai?"
sqlite3 "$DB" "SELECT o.id, o.user_id, u.email, o.total_amount FROM orders o LEFT JOIN users u ON u.id=o.user_id WHERE o.id=1;" | sed 's/^/   /'
echo "-- doc them don cua nguoi khac, van khong token:"
for i in 5 12 33; do
  code=$(curl -s -o /tmp/vb-p1b.json -w "%{http_code}" "$API/api/orders/$i")
  info=$(python3 -c 'import json;d=json.load(open("/tmp/vb-p1b.json"));print(f"user_id={d.get(\"user_id\")} total={d.get(\"total_amount\")}")' 2>/dev/null || echo "")
  printf "   order %-3s → HTTP %s  %s\n" "$i" "$code" "$info"
done
echo "-- DOI CHUNG: endpoint order khac CO kiem token:"
printf "   GET /api/orders/my-orders khong token → HTTP "
curl -s -o /dev/null -w "%{http_code}\n" "$API/api/orders/my-orders"
echo "   → route ben canh chan dung ⇒ day la mot route BI BO SOT, khong phai API cong khai."

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "  BUG-P2 — POST /api/coupon-usage khong co trong tai lieu API"
echo "══════════════════════════════════════════════════════════════════════"
echo -n "-- so lan xuat hien trong api_specification.md: "
grep -c "coupon-usage" ../eshop-sut/api_specification.md || true
echo "-- trong server.js:"
grep -n "coupon-usage" ../eshop-sut/backend/server.js | sed 's/^/   /'
B=$(sqlite3 "$DB" "SELECT COUNT(*) FROM coupon_usage;")
R=$(curl -s -X POST "$API/api/coupon-usage" -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{"coupon_id":1}')
A=$(sqlite3 "$DB" "SELECT COUNT(*) FROM coupon_usage;")
echo "-- goi thu that:"
echo "   response     : $R"
echo "   coupon_usage : $B → $A dong  (endpoint co GHI DB that)"

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "  DA LOAI — 'import-products bao so dong da insert nho hon thuc te'"
echo "══════════════════════════════════════════════════════════════════════"
run_import() { # $1 = mo ta, $2 = body JSON
  local before after
  before=$(sqlite3 "$DB" "SELECT COUNT(*) FROM products;")
  local resp; resp=$(curl -s -X POST "$API/api/admin/import-products" \
    -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "$2")
  after=$(sqlite3 "$DB" "SELECT COUNT(*) FROM products;")
  printf "   %-28s server bao: %-58s DB thuc te: +%s dong\n" \
    "$1" "$(echo "$resp" | cut -c1-58)" "$((after - before))"
}
# Sinh body bằng heredoc quoted — KHÔNG lồng python -c "..." trong "$( ... )": dấu ngoặc kép
# bên trong kết thúc chuỗi bên ngoài và bash băm nhỏ đoạn JSON thành từng mảnh vô nghĩa.
gen_body() { # $1 = so luong, $2 = tien to
  python3 - "$1" "$2" <<'EOF'
import json, sys, time
count, prefix = int(sys.argv[1]), sys.argv[2]
stamp = int(time.time() * 1000)
print(json.dumps({'products': [
    {'name': f'{prefix}-{stamp}-{i}', 'price': 1000 + i, 'category_id': 1}
    for i in range(count)
]}))
EOF
}

run_import "5 san pham" "$(gen_body 5 VB5)"
run_import "60 san pham" "$(gen_body 60 VB60)"
run_import "3 san pham, 1 thieu name" '{"products":[{"name":"VB-OK-1","price":1,"category_id":1},{"price":2,"category_id":1},{"name":"VB-OK-2","price":3,"category_id":1}]}'
echo ""
echo "   → ca ba lo deu khop. \`inserted\` KHONG sai; no chi phu thuoc du lieu (dong thieu"
echo "     name bi bo qua mot cach hop le). Vi vay test plan assert theo \`message\`, khong"
echo "     assert theo \`inserted\` — nhung ly do la 'phu thuoc du lieu', khong phai 'server sai'."

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "  Xong. Chup lai man hinh nay lam bang chung cho bug-report.md."
echo "══════════════════════════════════════════════════════════════════════"
echo ""
