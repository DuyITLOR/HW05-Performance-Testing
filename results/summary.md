# Test summary — HW05 Performance Testing

> **Sinh tự động** bởi `npm run summary` lúc 2026-08-15T08:03:08.107Z, đọc từ raw `.jtl`.
> Đừng sửa tay. Mọi con số trong `report/main-report.md` và `README.md` phải khớp bảng này.
> Percentile tính theo **nearest-rank**; JMeter dashboard nội suy khác một chút nên chênh
> vài ms ở p99 là bình thường — không phải dấu hiệu file `.jtl` sai.

## Tổng quan từng scenario

| Scenario | Sample | Peak thread | Thời lượng | RPS | Error % | avg | p50 | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Load** | 16,395 | 22 | 359.4s | 45.6 | 0% | 2.9 | 2 | 6 | **7** | 10 | 104 |
| **Stress** | 270,848 | 200 | 479.8s | 564.4 | 0% | 3.1 | 2 | 5 | **7** | 29 | 363 |
| **Spike** | 38,388 | 212 | 239.8s | 160.1 | 0% | 2.6 | 2 | 5 | **6** | 13 | 51 |
| **Soak** | 45,220 | 22 | 719.6s | 62.8 | 0% | 2.7 | 2 | 5 | **6** | 11 | 230 |

Đơn vị thời gian: **ms**. RPS = số sample / khoảng thời gian thật của lượt chạy.

---

## Load — `23127178_Load_20260815-142705.jtl`

- Bắt đầu: `2026-08-15T07:27:07.306Z` · thời lượng **359.4s** · peak thread **22**
- Tổng **16,395** sample · error **0%** · **45.6 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 3,269 | 0% | 2 | 4 | **5** | 7 | 78 | 2 | 5 |
| 2 GET /api/admin/orders | 3,266 | 0% | 4 | 6 | **7** | 9 | 80 | 3.8 | 7 |
| 3 GET /api/admin/users | 3,261 | 0% | 2 | 4 | **4** | 7 | 43 | 1.9 | 4 |
| 4 POST /api/admin/import-products | 3,255 | 0% | 4.6 | 7 | **9** | 13 | 104 | 4.6 | 9 |
| 5 PUT /api/admin/orders/:id/status | 3,250 | 0% | 1.8 | 3 | **4** | 7 | 38 | 1.8 | 4 |
| 6 POST /api/login (sai mat khau — lockout probe) | 94 | 0% | 2.1 | 4 | **5** | 12 | 12 | 2.1 | 5 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 2,850 | 87.7% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 12.3% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 90 | 95.7% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.3% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Stress — `23127178_Stress_20260815-143439.jtl`

- Bắt đầu: `2026-08-15T07:34:40.520Z` · thời lượng **479.8s** · peak thread **200**
- Tổng **270,848** sample · error **0%** · **564.4 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 54,237 | 0% | 3.4 | 5 | **7** | 40 | 363 | 3.4 | 7 |
| 2 GET /api/admin/orders | 54,192 | 0% | 3.2 | 5 | **6** | 25 | 217 | 3.2 | 6 |
| 3 GET /api/admin/users | 54,148 | 0% | 2.3 | 4 | **5** | 24 | 210 | 2.3 | 5 |
| 4 POST /api/admin/import-products | 54,106 | 0% | 4.5 | 6 | **9** | 37 | 326 | 4.5 | 9 |
| 5 PUT /api/admin/orders/:id/status | 54,068 | 0% | 2.1 | 4 | **5** | 24 | 211 | 2.1 | 5 |
| 6 POST /api/login (sai mat khau — lockout probe) | 97 | 0% | 1.6 | 3 | **4** | 12 | 12 | 1.6 | 4 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 53,668 | 99.3% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 0.7% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 93 | 95.9% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.1% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Spike — `23127178_Spike_20260815-144416.jtl`

- Bắt đầu: `2026-08-15T07:44:18.135Z` · thời lượng **239.8s** · peak thread **212**
- Tổng **38,388** sample · error **0%** · **160.1 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 7,745 | 0% | 2.5 | 4 | **6** | 18 | 41 | 2.5 | 6 |
| 2 GET /api/admin/orders | 7,701 | 0% | 3 | 5 | **6** | 10 | 28 | 2.9 | 6 |
| 3 GET /api/admin/users | 7,662 | 0% | 1.8 | 3 | **4** | 8 | 29 | 1.8 | 4 |
| 4 POST /api/admin/import-products | 7,614 | 0% | 3.9 | 7 | **8** | 16 | 51 | 3.9 | 8 |
| 5 PUT /api/admin/orders/:id/status | 7,571 | 0% | 1.8 | 4 | **5** | 12 | 27 | 1.8 | 5 |
| 6 POST /api/login (sai mat khau — lockout probe) | 95 | 0% | 1.8 | 3 | **5** | 7 | 7 | 1.8 | 5 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 7,171 | 94.7% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 5.3% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 91 | 95.8% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.2% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Soak — `23127178_Soak_20260815-144951.jtl`

- Bắt đầu: `2026-08-15T07:49:52.791Z` · thời lượng **719.6s** · peak thread **22**
- Tổng **45,220** sample · error **0%** · **62.8 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 9,033 | 0% | 1.9 | 3 | **5** | 9 | 130 | 1.9 | 5 |
| 2 GET /api/admin/orders | 9,030 | 0% | 3.7 | 6 | **7** | 12 | 115 | 3.4 | 7 |
| 3 GET /api/admin/users | 9,027 | 0% | 1.9 | 3 | **4** | 8 | 169 | 1.8 | 4 |
| 4 POST /api/admin/import-products | 9,021 | 0% | 4.2 | 7 | **8** | 15 | 230 | 4.2 | 8 |
| 5 PUT /api/admin/orders/:id/status | 9,016 | 0% | 1.6 | 3 | **4** | 8 | 133 | 1.6 | 4 |
| 6 POST /api/login (sai mat khau — lockout probe) | 93 | 0% | 1.6 | 3 | **3** | 8 | 8 | 1.6 | 3 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 8,616 | 95.6% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 4.4% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 89 | 95.7% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.3% |

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

