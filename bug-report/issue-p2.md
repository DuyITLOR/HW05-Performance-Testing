## Mô tả

`POST /api/coupon-usage` tồn tại trong code, cần token, và **ghi thật vào bảng `coupon_usage`** —
nhưng **không có trong `api_specification.md`**.

## Bằng chứng

```
-- so lan xuat hien trong api_specification.md: 0
-- trong server.js:
   444:app.post("/api/coupon-usage", authenticateToken, (req, res) => {
-- goi thu that:
   response      : {"message":"Usage recorded"}
   coupon_usage  : 4 → 5 dong      ← endpoint co GHI DB that
```

__IMAGE__

## Vì sao đáng báo

Tài liệu API là căn cứ để chọn phạm vi kiểm thử. **Không ai test được endpoint mình không biết là
có** — endpoint này sẽ không bao giờ xuất hiện trong bảng phân công của nhóm nào.

## Một điểm đáng lưu ý thêm

Endpoint ghi `coupon_usage` mà **không kiểm** coupon có tồn tại hay người dùng đã dùng quá
`max_uses_per_user` chưa — trong khi `POST /api/apply-coupon` thì có kiểm (`server.js:391`). Tức là
ghi thẳng vào bảng này **bỏ qua được toàn bộ luật giới hạn số lần dùng coupon**.

Chưa tách thành issue riêng vì cần đọc kỹ hơn phần nghiệp vụ coupon, nhưng ghi lại ở đây.

## Đề xuất sửa

Chọn một trong hai: (1) bổ sung endpoint vào `api_specification.md` kèm mô tả ràng buộc, hoặc
(2) xoá endpoint nếu nó là code chết — và nếu giữ thì thêm kiểm `max_uses_per_user`.

---
*Phát hiện khi rà endpoint cho HW05 Performance Testing · SV 23127178 · kiểm chứng lại bằng
`bash bug-report/verify-bugs.sh`*
