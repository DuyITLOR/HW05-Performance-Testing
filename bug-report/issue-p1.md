## Mô tả

`GET /api/orders/:id` **không kiểm xác thực**. Bất kỳ ai cũng đọc được đơn hàng của bất kỳ người dùng
nào chỉ bằng cách đổi `:id` — không cần token.

## Đặc tả nói gì

`api_specification.md` §4 xếp endpoint này dưới dòng *"Yêu cầu Header: `Authorization: Bearer <token>`"*.

## Thực tế

`server.js:344` thiếu middleware `authenticateToken`, trong khi **mọi route order khác đều có**.

## Cách tái hiện

```bash
curl -i http://localhost:3000/api/orders/1          # → 200, trả về đơn hàng đầy đủ
curl -i http://localhost:3000/api/orders/my-orders  # → 401  (đối chứng)
```

## Bằng chứng

```
-- goi KHONG kem Authorization header:
   HTTP 200
   {"id":1,"user_id":3,"total_amount":500000,"status":"pending",
    "shipping_address":"1 Đường Perf, Q1, TP.HCM","created_at":"2026-08-13 05:08:32"}

-- doi chieu trong DB: order 1 thuoc ai?
   1|3|perf_23127178_001@eshop.test|500000

-- doc them don cua nguoi khac, van khong token:
   order 5   → HTTP 200
   order 12  → HTTP 200
   order 33  → HTTP 200

-- DOI CHUNG: endpoint order khac CO kiem token:
   GET /api/orders/my-orders khong token → HTTP 401
```

__IMAGE__

**Dòng đối chứng cuối là phần quan trọng nhất:** route order ngay bên cạnh vẫn chặn đúng (401), nên
đây **không** phải thiết kế "API này vốn công khai" mà là **một route bị bỏ sót**.

## Mức độ

Bảo mật — IDOR. Đơn hàng chứa địa chỉ giao hàng và số tiền, tức dữ liệu cá nhân.

## Đề xuất sửa

Thêm `authenticateToken` và kiểm `order.user_id === req.user.id` (hoặc `req.user.role === 'admin'`).

---
*Phát hiện khi thiết kế workflow cho HW05 Performance Testing · SV 23127178 · kiểm chứng lại bằng
`bash bug-report/verify-bugs.sh`*
