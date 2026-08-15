# Test summary — HW05 Performance Testing

> **Sinh tự động** bởi `npm run summary` lúc 2026-08-15T15:09:25.542Z, đọc từ raw `.jtl`.
> Đừng sửa tay. Mọi con số trong `report/main-report.md` và `README.md` phải khớp bảng này.
> Percentile tính theo **nearest-rank**; JMeter dashboard nội suy khác một chút nên chênh
> vài ms ở p99 là bình thường — không phải dấu hiệu file `.jtl` sai.

## Tổng quan từng scenario

| Scenario | Sample | Peak thread | Thời lượng | RPS | Error % | avg | p50 | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Load** | 16,343 | 22 | 359.7s | 45.4 | 0% | 3.7 | 3 | 7 | **8** | 12 | 84 |
| **Stress** | 258,992 | 200 | 479.9s | 539.7 | 0% | 9.6 | 2 | 8 | **18** | 124 | 3691 |
| **Spike** | 38,251 | 212 | 239.8s | 159.5 | 0% | 2.8 | 2 | 5 | **7** | 16 | 176 |
| **Soak** | 45,166 | 22 | 719.6s | 62.8 | 0% | 3.6 | 3 | 7 | **8** | 12 | 192 |

Đơn vị thời gian: **ms**. RPS = số sample / khoảng thời gian thật của lượt chạy.

---

## Load — `23127178_Load_20260815-152938.jtl`

- Bắt đầu: `2026-08-15T08:29:39.729Z` · thời lượng **359.7s** · peak thread **22**
- Tổng **16,343** sample · error **0%** · **45.4 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 3,259 | 0% | 2.8 | 5 | **6** | 9 | 33 | 2.8 | 6 |
| 2 GET /api/admin/orders | 3,256 | 0% | 4.8 | 7 | **9** | 13 | 84 | 4.5 | 8 |
| 3 GET /api/admin/users | 3,248 | 0% | 2.7 | 5 | **6** | 9 | 46 | 2.6 | 6 |
| 4 POST /api/admin/import-products | 3,244 | 0% | 5.7 | 9 | **10** | 16 | 53 | 5.6 | 10 |
| 5 PUT /api/admin/orders/:id/status | 3,241 | 0% | 2.6 | 5 | **6** | 10 | 49 | 2.5 | 6 |
| 6 POST /api/login (sai mat khau — lockout probe) | 95 | 0% | 2.9 | 5 | **6** | 10 | 10 | 2.9 | 6 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 2,841 | 87.7% |
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

## Stress — `23127178_Stress_20260815-153717.jtl`

- Bắt đầu: `2026-08-15T08:37:18.613Z` · thời lượng **479.9s** · peak thread **200**
- Tổng **258,992** sample · error **0%** · **539.7 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 51,863 | 0% | 12 | 9 | **24** | 185 | 3691 | 12 | 24 |
| 2 GET /api/admin/orders | 51,820 | 0% | 9.8 | 8 | **17** | 102 | 3623 | 9.5 | 16 |
| 3 GET /api/admin/users | 51,778 | 0% | 7.4 | 6 | **13** | 79 | 3628 | 7.4 | 13 |
| 4 POST /api/admin/import-products | 51,736 | 0% | 11.4 | 11 | **22** | 135 | 3687 | 11.4 | 22 |
| 5 PUT /api/admin/orders/:id/status | 51,701 | 0% | 7.3 | 6 | **14** | 91 | 3638 | 7.3 | 14 |
| 6 POST /api/login (sai mat khau — lockout probe) | 94 | 0% | 2.2 | 5 | **6** | 18 | 18 | 2.2 | 6 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 51,301 | 99.2% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 0.8% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 90 | 95.7% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.3% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Spike — `23127178_Spike_20260815-215939.jtl`

- Bắt đầu: `2026-08-15T14:59:40.808Z` · thời lượng **239.8s** · peak thread **212**
- Tổng **38,251** sample · error **0%** · **159.5 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 7,715 | 0% | 2.7 | 5 | **7** | 24 | 106 | 2.7 | 7 |
| 2 GET /api/admin/orders | 7,679 | 0% | 3.2 | 5 | **7** | 13 | 123 | 3.1 | 6 |
| 3 GET /api/admin/users | 7,627 | 0% | 2 | 4 | **5** | 12 | 148 | 1.9 | 5 |
| 4 POST /api/admin/import-products | 7,591 | 0% | 4.1 | 7 | **9** | 21 | 176 | 4.1 | 9 |
| 5 PUT /api/admin/orders/:id/status | 7,543 | 0% | 1.8 | 4 | **5** | 11 | 89 | 1.8 | 5 |
| 6 POST /api/login (sai mat khau — lockout probe) | 96 | 0% | 2.2 | 4 | **6** | 15 | 15 | 2.2 | 6 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 7,143 | 94.7% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 5.3% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 92 | 95.8% |
| 6 POST /api/login (sai mat khau — lockout probe) | `401` | 4 | 4.2% |

> Bước 5 hợp lệ ở **cả 200 và 400**: FR-10 chỉ cho một order chuyển tiếp một lần
> cho mỗi trạng thái, nên từ lần lặp thứ hai trở đi 400 là phản hồi đúng. Nhánh
> lockout hợp lệ ở **401 và 403** — 401 ở lần sai đầu, 403 sau khi đã bị khoá.
> Hệ quả khi đọc số: nhánh 400 trả về **trước** lệnh UPDATE nên nhẹ hơn nhánh 200,
> vậy p95 của bước 5 bị kéo xuống theo tỉ lệ 400 — tín hiệu ghi nặng nằm ở bước 4.

Không có sample lỗi nào trong lượt này.

---

## Soak — `23127178_Soak_20260815-155240.jtl`

- Bắt đầu: `2026-08-15T08:52:41.779Z` · thời lượng **719.6s** · peak thread **22**
- Tổng **45,166** sample · error **0%** · **62.8 RPS**

### Theo endpoint

| Endpoint (label) | Sample | Err % | avg | p90 | **p95** | p99 | max | latency avg | latency p95 |
|---|---|---|---|---|---|---|---|---|---|
| 1 POST /api/login | 9,019 | 0% | 2.8 | 5 | **6** | 10 | 125 | 2.8 | 6 |
| 2 GET /api/admin/orders | 9,018 | 0% | 4.8 | 7 | **8** | 12 | 88 | 4.5 | 8 |
| 3 GET /api/admin/users | 9,014 | 0% | 2.7 | 5 | **6** | 10 | 116 | 2.6 | 5 |
| 4 POST /api/admin/import-products | 9,012 | 0% | 5.4 | 8 | **10** | 14 | 192 | 5.4 | 10 |
| 5 PUT /api/admin/orders/:id/status | 9,009 | 0% | 2.3 | 4 | **5** | 9 | 81 | 2.3 | 5 |
| 6 POST /api/login (sai mat khau — lockout probe) | 94 | 0% | 2.8 | 5 | **6** | 8 | 8 | 2.8 | 6 |

> `elapsed` (avg/p95) là **toàn bộ** thời gian request; `latency` là tới byte đầu tiên.
> Chênh lệch lớn giữa hai cột = thời gian nằm ở truyền/nhận body, không ở xử lý server.

### Phân bố response code (kể cả sample thành công)

| Endpoint | Code | Số lần | Tỉ lệ |
|---|---|---|---|
| 5 PUT /api/admin/orders/:id/status | `400` | 8,609 | 95.6% |
| 5 PUT /api/admin/orders/:id/status | `200` | 400 | 4.4% |
| 6 POST /api/login (sai mat khau — lockout probe) | `403` | 90 | 95.7% |
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
| `23127178_Load_20260815-142705.jtl` | 2026-08-15T07:27:07.306Z | 16395 | 0% | 7 |
| `23127178_Stress_20260815-143439.jtl` | 2026-08-15T07:34:40.520Z | 270848 | 0% | 7 |
| `23127178_Spike_20260815-144416.jtl` | 2026-08-15T07:44:18.135Z | 38388 | 0% | 6 |
| `23127178_Soak_20260815-144951.jtl` | 2026-08-15T07:49:52.791Z | 45220 | 0% | 6 |
| `23127178_Spike_20260815-154700.jtl` | 2026-08-15T08:47:02.046Z | 38160 | 0% | 7 |

> Giữ lại để minh bạch quá trình. Bảng chính chỉ lấy **lượt mới nhất của mỗi scenario**.

