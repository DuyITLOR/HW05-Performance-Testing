# Test summary — HW05 Performance Testing

> **Sinh tự động** bởi `npm run summary` lúc 2026-08-14T03:46:38.783Z, đọc từ raw `.jtl`.
> Đừng sửa tay. Mọi con số trong `report/main-report.md` và `README.md` phải khớp bảng này.
> Percentile tính theo **nearest-rank**; JMeter dashboard nội suy khác một chút nên chênh
> vài ms ở p99 là bình thường — không phải dấu hiệu file `.jtl` sai.

## Tổng quan từng scenario

| Scenario | Sample | Peak thread | Thời lượng | RPS | Error % | avg | p50 | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Load** | 16,436 | 22 | 359.4s | 45.7 | 0% | 2.6 | 2 | 5 | **6** | 14 | 234 |
| **Stress** | 251,820 | 200 | 479.9s | 524.8 | 0% | 14.6 | 3 | 32 | **70** | 210 | 1058 |
| **Spike** | 37,126 | 212 | 239.7s | 154.9 | 0% | 8.7 | 3 | 15 | **44** | 120 | 282 |
| **Soak** | 45,288 | 22 | 719.7s | 62.9 | 0% | 3 | 2 | 5 | **6** | 16 | 365 |

Đơn vị thời gian: **ms**. RPS = số sample / khoảng thời gian thật của lượt chạy.

---

## Load — `23127178_Load_20260814-093756.jtl`

- Bắt đầu: `2026-08-14T02:37:58.854Z` · thời lượng **359.4s** · peak thread **22**
- Tổng **16,436** sample · error **0%** · **45.7 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 3,274 | 0% | 1.8 | 3 | **4** | 11 | 94 | 1.8 | 4 |
| 2 GET /api/admin/orders | 3,273 | 0% | 3.4 | 5 | **6** | 15 | 171 | 3.2 | 6 |
| 3 GET /api/admin/users | 3,270 | 0% | 1.9 | 3 | **4** | 10 | 96 | 1.8 | 4 |
| 4 POST /api/admin/import-products | 3,265 | 0% | 4.2 | 6 | **8** | 20 | 144 | 4.1 | 8 |
| 5 PUT /api/admin/orders/:id/status | 3,259 | 0% | 1.8 | 3 | **4** | 12 | 234 | 1.8 | 4 |
| 6 POST /api/login (sai mat khau — lockout probe) | 95 | 0% | 1.5 | 3 | **3** | 9 | 9 | 1.5 | 3 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 2,859 | 87.7% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 12.3% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 91 | 95.8% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.2% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Stress — `23127178_Stress_20260814-101731.jtl`

- Bắt đầu: `2026-08-14T03:17:33.242Z` · thời lượng **479.9s** · peak thread **200**
- Tổng **251,820** sample · error **0%** · **524.8 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 50,420 | 0% | 20.1 | 51 | **107** | 288 | 1058 | 20.1 | 107 |
| 2 GET /api/admin/orders | 50,390 | 0% | 12.9 | 28 | **55** | 177 | 505 | 12.5 | 54 |
| 3 GET /api/admin/users | 50,345 | 0% | 10.4 | 23 | **49** | 164 | 545 | 10.3 | 48 |
| 4 POST /api/admin/import-products | 50,307 | 0% | 18.4 | 45 | **82** | 235 | 652 | 18.4 | 82 |
| 5 PUT /api/admin/orders/:id/status | 50,262 | 0% | 11.1 | 24 | **53** | 175 | 539 | 11.1 | 53 |
| 6 POST /api/login (sai mat khau — lockout probe) | 96 | 0% | 2 | 3 | **5** | 33 | 33 | 2 | 5 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 49,862 | 99.2% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 0.8% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 92 | 95.8% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.2% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Spike — `23127178_Spike_20260814-102710.jtl`

- Bắt đầu: `2026-08-14T03:27:12.967Z` · thời lượng **239.7s** · peak thread **212**
- Tổng **37,126** sample · error **0%** · **154.9 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 7,488 | 0% | 11.4 | 19 | **64** | 176 | 282 | 11.4 | 64 |
| 2 GET /api/admin/orders | 7,450 | 0% | 7.8 | 13 | **34** | 88 | 165 | 7.5 | 33 |
| 3 GET /api/admin/users | 7,412 | 0% | 6.3 | 12 | **31** | 80 | 239 | 6.3 | 31 |
| 4 POST /api/admin/import-products | 7,363 | 0% | 11.3 | 20 | **54** | 125 | 243 | 11.3 | 54 |
| 5 PUT /api/admin/orders/:id/status | 7,316 | 0% | 6.8 | 12 | **39** | 93 | 163 | 6.8 | 39 |
| 6 POST /api/login (sai mat khau — lockout probe) | 97 | 0% | 4 | 4 | **14** | 96 | 96 | 4 | 14 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 6,916 | 94.5% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 5.5% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 93 | 95.9% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.1% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Soak — `23127178_Soak_20260814-103245.jtl`

- Bắt đầu: `2026-08-14T03:32:48.318Z` · thời lượng **719.7s** · peak thread **22**
- Tổng **45,288** sample · error **0%** · **62.9 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 9,046 | 0% | 2.2 | 3 | **5** | 12 | 365 | 2.2 | 5 |
| 2 GET /api/admin/orders | 9,041 | 0% | 4 | 6 | **7** | 20 | 331 | 3.7 | 7 |
| 3 GET /api/admin/users | 9,039 | 0% | 2.2 | 3 | **5** | 12 | 343 | 2.2 | 4 |
| 4 POST /api/admin/import-products | 9,036 | 0% | 4.8 | 7 | **9** | 25 | 360 | 4.8 | 9 |
| 5 PUT /api/admin/orders/:id/status | 9,031 | 0% | 2 | 3 | **4** | 11 | 362 | 2 | 4 |
| 6 POST /api/login (sai mat khau — lockout probe) | 95 | 0% | 1.6 | 3 | **4** | 5 | 5 | 1.6 | 4 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 8,631 | 95.6% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 4.4% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 91 | 95.8% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.2% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Các lượt chạy cũ (không dùng làm số liệu báo cáo)

| File | Bắt đầu | Sample | Error % | p95 |
|---|---|---|---|---|
| `23127178_Load_20260813-131228.jtl` | 2026-08-13T06:12:29.700Z | 16436 | 0% | 7 |
| `23127178_Stress_20260813-132001.jtl` | 2026-08-13T06:20:03.598Z | 264141 | 0% | 26 |
| `23127178_Spike_20260813-132940.jtl` | 2026-08-13T06:29:42.180Z | 38069 | 0% | 9 |
| `23127178_Soak_20260813-133515.jtl` | 2026-08-13T06:35:17.523Z | 45365 | 0% | 6 |

> Giữ lại để minh bạch quá trình. Bảng chính chỉ lấy **lượt mới nhất của mỗi scenario**.

