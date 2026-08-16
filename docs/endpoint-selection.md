# §5 — Chọn nhóm endpoint và chống trùng trong nhóm

> Sinh viên: Lê Nhựt Duy — 23127178 · Nhóm 05
> §5 đòi: phủ **3 endpoint group** (auth-heavy · read-heavy · transactional) trong **một
> workflow end-to-end duy nhất**, và **không trùng workflow** với thành viên nào trong nhóm.

## 1. Đăng ký của các thành viên (chốt qua chat nhóm, 2026-08-11)

| Thành viên | Endpoint đã đăng ký |
|---|---|
| Nguyễn | `POST /api/login` · `GET /api/products?search=` · `GET /api/products/:id` · `POST /api/cart` · `POST /api/checkout` |
| Quan | `GET /api/categories` · `GET /api/orders/my-orders` · `POST /api/forgot-password` · `POST /api/apply-coupon` · `PUT /api/orders/:id/cancel` |
| Thế Đạt | `POST /api/login` · `GET /api/categories` · `POST /api/categories` |
| **23127178 (bài này)** | **workflow back-office — bảng §2 dưới** |

Hệ quả: **toàn bộ luồng khách hàng** (login → search → xem chi tiết → thêm giỏ → checkout →
xem/hủy đơn → áp coupon) đã bị chiếm. Lấy lại bất kỳ đoạn nào của luồng đó là trùng workflow
theo đúng nghĩa §5 cấm.

## 2. Workflow đã chọn — "Admin back-office"

Một virtual user đăng nhập admin, đọc hai danh sách quản trị, rồi thực hiện hai thao tác ghi.

| Bước | Endpoint | Nhóm §5 | Vì sao bước này nằm trong workflow |
|---|---|---|---|
| 1 | `POST /api/login` (admin) | **auth-heavy** | Bắt buộc để có JWT cho 4 bước sau. Mỗi login thành công còn kèm một lệnh ghi: `UPDATE users SET login_attempts=0, locked_until=NULL` ([`server.js:47`](../../eshop-sut/backend/server.js#L47)) → endpoint auth của SUT này **không phải read-only**, đó là điều làm nó đáng đo |
| 2 | `GET /api/admin/orders` | **read-heavy** | JOIN `orders` × `users`, không phân trang, không index ([`server.js:510`](../../eshop-sut/backend/server.js#L510)) → chi phí tăng theo số order mà lượt Stress vừa sinh ra |
| 3 | `GET /api/admin/users` | **read-heavy** | `SELECT *` toàn bảng `users`, không phân trang ([`server.js:494`](../../eshop-sut/backend/server.js#L494)) |
| 4 | `POST /api/admin/import-products` | **transactional** | Bulk INSERT nhiều dòng qua một prepared statement ([`server.js:199`](../../eshop-sut/backend/server.js#L199)). SQLite ghi tuần tự → **đây là chỗ ngưỡng chịu tải thật sẽ lộ ra** |
| 5 | `PUT /api/admin/orders/:id/status` | **transactional** | Ghi có điều kiện, đổi trạng thái trong state machine FR-10 ([`server.js:525`](../../eshop-sut/backend/server.js#L525)) |

Endpoint bổ sung để tăng tỉ lệ đọc trong mix (đều **chưa ai đăng ký**):

| Endpoint | Nhóm | Ghi chú |
|---|---|---|
| `GET /api/coupons` | read-heavy | Cần token ([`server.js:356`](../../eshop-sut/backend/server.js#L356)) |
| `POST /api/coupon-usage` | transactional | **Không có trong `api_specification.md`**, chỉ tồn tại trong code ([`server.js:444`](../../eshop-sut/backend/server.js#L444)) → tài liệu API thiếu endpoint, ghi vào bug report |
| `GET /api/orders/:id` | read-heavy | **Không có `authenticateToken`** ([`server.js:344`](../../eshop-sut/backend/server.js#L344)) → dùng làm baseline "read không xác thực" để so với các endpoint có auth |

## 3. Xác nhận không trùng

Chỉ có `POST /api/login` giao với người khác, và nó **không thể tránh**: mọi endpoint trong
workflow này đều đi qua `authenticateToken`, không có token thì không đo được gì. Bản thân
Nguyễn và Thế Đạt cũng đã trùng nhau ở đúng endpoint này. Bốn bước còn lại (2→5) **không
xuất hiện trong đăng ký của bất kỳ ai**, nên workflow là duy nhất.

## 4. Ba đặc điểm của SUT quyết định cách thiết kế test plan

1. **Lockout kích hoạt sau 2 lần sai, không phải 3.** `login_attempts + 2` với ngưỡng 3
   ([`server.js:54-58`](../../eshop-sut/backend/server.js#L54)) → 2 lần sai mật khẩu là khoá
   180 giây. Ở Stress/Spike, dùng chung vài tài khoản là tự tạo ra một đợt 403 hàng loạt và
   rất dễ đọc sai thành "server sụp". Cách xử lý: dùng pool **50 tài khoản hợp lệ** từ
   [`data/users.csv`](../data/users.csv) (một tài khoản/VU ở Load/Soak; tái sử dụng theo vòng ở
   Stress/Spike), còn nhánh test lockout dùng **tài khoản riêng biệt**
   (`perf_23127178_lockout_*`), và reset trước mỗi lượt bằng `npm run reset:lockout`.
2. **Không có rate limiting ở bất kỳ route nào.** Mọi 4xx đo được đến từ lockout / token /
   body sai — không phải throttling. Đừng giải thích 403 bằng "server tự bảo vệ".
3. **`inserted` của `import-products` là con số phụ thuộc dữ liệu, không phải con số sai.**
   Ban đầu tôi đọc code và kết luận `stmt.finalize()` trả response trước khi các callback
   `stmt.run` chạy xong ([`server.js:234`](../../eshop-sut/backend/server.js#L234)) nên `inserted`
   bị nhỏ hơn thực tế. **Kiểm bằng request thật thì kết luận đó SAI**: 5/5, 60/60, và 2/3 khi có
   một dòng thiếu `name` — cả ba đều đúng, vì `node-sqlite3` xếp các lệnh trên cùng một handle
   theo thứ tự và callback của `finalize` chạy sau chúng.
   Vẫn **không assert theo `inserted`**, nhưng vì lý do khác: dòng CSV thiếu `name` bị bỏ qua
   một cách hợp lệ, nên assert theo con số đó là biến một đặc điểm dữ liệu thành "lỗi hiệu năng".
   Assert bằng HTTP status + sự tồn tại của field `message`.

## 5. Dữ liệu data-driven (§6)

| File | Cột | Dùng ở bước |
|---|---|---|
| [`data/users.csv`](../data/users.csv) | `email,password,expect` | 1 — pool 50 tài khoản hợp lệ; ở Stress/Spike nhiều VU sẽ tái sử dụng cùng account |
| [`data/users_lockout.csv`](../data/users_lockout.csv) | `email,password,expect_regex` | nhánh lockout — **file riêng**, xem lý do dưới |
| [`data/products_import.csv`](../data/products_import.csv) | `name,price,description,category_id` | 4 — body của import |
| [`data/orders.csv`](../data/orders.csv) | `order_id,next_status` | 5 — id order thật; chỉ `confirmed`, là chuyển đổi hợp lệ duy nhất từ `pending` |

> **Vì sao nhánh lockout phải có file CSV riêng.** Bản đầu để 2 dòng mật khẩu sai ở cuối
> `users.csv`. Thread group chính đọc chính file đó với `recycle=true` nên nó cũng gặp 2 dòng ấy
> → login 401 → hai tài khoản bị khoá 180s → mọi lần đọc lại trả 403, và vì không có token nên
> **cả 4 bước còn lại của iteration đó cũng 403**. Lượt chạy thật đầu tiên vì thế có ~2,9% error
> hoàn toàn do dữ liệu test, không phải do SUT.

Sinh lại toàn bộ: `npm run seed:perf`.
