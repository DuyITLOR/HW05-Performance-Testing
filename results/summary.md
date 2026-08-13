# Test summary — HW05 Performance Testing

> **Sinh tự động** bởi `npm run summary` lúc 2026-08-13T06:48:47.784Z, đọc từ raw `.jtl`.
> Đừng sửa tay. Mọi con số trong `report/main-report.md` và `README.md` phải khớp bảng này.
> Percentile tính theo **nearest-rank**; JMeter dashboard nội suy khác một chút nên chênh
> vài ms ở p99 là bình thường — không phải dấu hiệu file `.jtl` sai.

## Tổng quan từng scenario

| Scenario | Sample | Peak thread | Thời lượng | RPS | Error % | avg | p50 | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Load** | 16,436 | 22 | 359.5s | 45.7 | 0% | 3 | 2 | 5 | **7** | 14 | 167 |
| **Stress** | 264,141 | 200 | 479.8s | 550.5 | 0% | 6.9 | 2 | 11 | **26** | 93 | 716 |
| **Spike** | 38,069 | 212 | 239.6s | 158.9 | 0% | 4.3 | 2 | 5 | **9** | 55 | 369 |
| **Soak** | 45,365 | 22 | 719.6s | 63 | 0% | 2.7 | 2 | 5 | **6** | 13 | 160 |

Đơn vị thời gian: **ms**. RPS = số sample / khoảng thời gian thật của lượt chạy.

---

## Load — `23127178_Load_20260813-131228.jtl`

- Bắt đầu: `2026-08-13T06:12:29.700Z` · thời lượng **359.5s** · peak thread **22**
- Tổng **16,436** sample · error **0%** · **45.7 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 3,276 | 0% | 2.2 | 4 | **5** | 11 | 62 | 2.2 | 5 |
| 2 GET /api/admin/orders | 3,271 | 0% | 3.8 | 6 | **7** | 15 | 134 | 3.6 | 7 |
| 3 GET /api/admin/users | 3,271 | 0% | 2.1 | 4 | **5** | 11 | 85 | 2.1 | 5 |
| 4 POST /api/admin/import-products | 3,266 | 0% | 4.7 | 7 | **9** | 20 | 167 | 4.7 | 9 |
| 5 PUT /api/admin/orders/:id/status | 3,259 | 0% | 2.1 | 4 | **5** | 12 | 79 | 2.1 | 5 |
| 6 POST /api/login (sai mat khau — lockout probe) | 93 | 0% | 2.1 | 5 | **6** | 11 | 11 | 2 | 6 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 2,859 | 87.7% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 12.3% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 89 | 95.7% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.3% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Stress — `23127178_Stress_20260813-132001.jtl`

- Bắt đầu: `2026-08-13T06:20:03.598Z` · thời lượng **479.8s** · peak thread **200**
- Tổng **264,141** sample · error **0%** · **550.5 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 52,893 | 0% | 9.3 | 14 | **40** | 164 | 716 | 9.3 | 40 |
| 2 GET /api/admin/orders | 52,851 | 0% | 6.5 | 11 | **23** | 69 | 440 | 6.3 | 23 |
| 3 GET /api/admin/users | 52,810 | 0% | 5.1 | 8 | **19** | 70 | 475 | 5.1 | 19 |
| 4 POST /api/admin/import-products | 52,765 | 0% | 8.9 | 15 | **34** | 108 | 559 | 8.9 | 34 |
| 5 PUT /api/admin/orders/:id/status | 52,729 | 0% | 4.6 | 8 | **19** | 61 | 463 | 4.6 | 19 |
| 6 POST /api/login (sai mat khau — lockout probe) | 93 | 0% | 1.6 | 4 | **4** | 7 | 7 | 1.6 | 4 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 52,329 | 99.2% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 0.8% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 89 | 95.7% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.3% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Spike — `23127178_Spike_20260813-132940.jtl`

- Bắt đầu: `2026-08-13T06:29:42.180Z` · thời lượng **239.6s** · peak thread **212**
- Tổng **38,069** sample · error **0%** · **158.9 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 7,673 | 0% | 5.3 | 5 | **10** | 84 | 369 | 5.3 | 10 |
| 2 GET /api/admin/orders | 7,632 | 0% | 4 | 5 | **9** | 39 | 187 | 3.9 | 8 |
| 3 GET /api/admin/users | 7,599 | 0% | 3.3 | 4 | **7** | 44 | 214 | 3.3 | 7 |
| 4 POST /api/admin/import-products | 7,562 | 0% | 5.8 | 7 | **13** | 66 | 257 | 5.8 | 13 |
| 5 PUT /api/admin/orders/:id/status | 7,509 | 0% | 3.1 | 4 | **7** | 43 | 198 | 3.1 | 7 |
| 6 POST /api/login (sai mat khau — lockout probe) | 94 | 0% | 4.3 | 4 | **5** | 255 | 255 | 4.3 | 5 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 7,109 | 94.7% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 5.3% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 90 | 95.7% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.3% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Soak — `23127178_Soak_20260813-133515.jtl`

- Bắt đầu: `2026-08-13T06:35:17.523Z` · thời lượng **719.6s** · peak thread **22**
- Tổng **45,365** sample · error **0%** · **63 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 9,062 | 0% | 2.1 | 4 | **5** | 13 | 119 | 2.1 | 5 |
| 2 GET /api/admin/orders | 9,058 | 0% | 3.7 | 6 | **7** | 15 | 148 | 3.5 | 7 |
| 3 GET /api/admin/users | 9,054 | 0% | 1.9 | 3 | **4** | 9 | 72 | 1.9 | 4 |
| 4 POST /api/admin/import-products | 9,049 | 0% | 4 | 7 | **8** | 16 | 96 | 4 | 8 |
| 5 PUT /api/admin/orders/:id/status | 9,045 | 0% | 1.7 | 3 | **4** | 9 | 160 | 1.7 | 4 |
| 6 POST /api/login (sai mat khau — lockout probe) | 97 | 0% | 1.7 | 3 | **4** | 9 | 9 | 1.6 | 4 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 8,645 | 95.6% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 4.4% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 93 | 95.9% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.1% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

