# Endurance threshold — HW05

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178
- **Máy:** `Le-Nhut-Duy.local` — Apple M2 Pro, 12 lõi, 16 GB, macOS 26.1

> §6: *"Run a short endurance / soak test (around 10–15 minutes at sustained load) to
> empirically find your hardware's threshold, reported with concrete numbers (e.g., maximum
> stable RPS, memory ceiling)."*

## 1. Định nghĩa "ổn định" — chốt TRƯỚC khi chạy

> **Ổn định** = error rate < **1%** (không tính 403 do lockout) **và** p95 không tăng quá **20%**
> giữa 5 phút đầu và 5 phút cuối của lượt soak.

Viết định nghĩa ra trước khi xem kết quả, nếu không sẽ tự chọn ngưỡng nào cho ra số đẹp. Đây cũng
là mốc dùng lại ở Task 3 làm ngưỡng cảnh báo hồi quy p95, để cả bài chỉ có **một** định nghĩa
hồi quy.

Kiểm lại bất cứ lúc nào: `npm run drift`

## 2. Cấu hình lượt soak

| | |
|---|---|
| Test plan | [`test-plans/23127178_Soak_20260813.jmx`](../test-plans/23127178_Soak_20260813.jmx) |
| VU | 20 |
| Ramp-up | 60s |
| Think-time | 5 bước × (200–400ms) = **1–2s mỗi iteration** |
| Thời lượng | **724s** (12 phút 4 giây) |
| Bắt đầu / kết thúc (UTC) | `2026-08-13T06:35:16Z` → `2026-08-13T06:47:20Z` |
| Raw log | [`endurance/jtl/23127178_Soak_20260813-133515.jtl`](jtl/) — 45.365 sample |
| Dashboard | [`endurance/html/soak/index.html`](html/soak/index.html) |
| Mẫu tài nguyên | [`endurance/resources/23127178_Soak_20260813-133515.resources.csv`](resources/) — 2 giây/mẫu |

## 3. Kết quả — ngưỡng tìm được

| Chỉ số | Giá trị | Lấy từ đâu |
|---|---|---|
| **Max stable RPS** | **63,0 req/s** | 45.365 sample / 719,6s |
| **p95 toàn lượt** | **6 ms** | `results/summary.md`, dòng Soak |
| p99 toàn lượt | 13 ms | như trên |
| max | 160 ms | như trên |
| Error rate | **0%** | không có sample nào `success=false` |
| **RSS `node` đầu → cuối** | **19,8 → 35,8 MB** | file resources cùng lượt |
| **Trần bộ nhớ (RSS đỉnh)** | **83,1 MB** | như trên |
| CPU `node` đỉnh | **19,7%** | như trên — trần một luồng JS là ~100% |
| CPU JMeter đỉnh | 60,9% · RSS đỉnh 788 MB | như trên |

### Theo endpoint

| Endpoint | Sample | avg | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|
| 1 POST /api/login | 9.062 | 2,1 | 4 | **5** | 13 | 119 |
| 2 GET /api/admin/orders | 9.058 | 3,7 | 6 | **7** | 15 | 148 |
| 3 GET /api/admin/users | 9.054 | 1,9 | 3 | **4** | 9 | 72 |
| 4 POST /api/admin/import-products | 9.049 | 4,0 | 7 | **8** | 16 | 96 |
| 5 PUT /api/admin/orders/:id/status | 9.045 | 1,7 | 3 | **4** | 9 | 160 |
| 6 POST /api/login (lockout probe) | 97 | 1,7 | 3 | **4** | 9 | 9 |

## 4. p95 có trôi không — bảng theo từng phút

| Phút | Sample | RPS | Error % | p50 | **p95** | p99 |
|---|---|---|---|---|---|---|
| 1 | 2.816 | 46,9 | 0% | 2 | **7** | 16 |
| 2 | 3.981 | 66,4 | 0% | 2 | **6** | 12 |
| 3 | 3.926 | 65,4 | 0% | 2 | **6** | 11 |
| 4 | 3.955 | 65,9 | 0% | 2 | **7** | 18 |
| 5 | 3.926 | 65,4 | 0% | 2 | **7** | 18 |
| 6 | 3.924 | 65,4 | 0% | 2 | **7** | 11 |
| 7 | 3.902 | 65,0 | 0% | 2 | **7** | 16 |
| 8 | 3.933 | 65,6 | 0% | 2 | **6** | 14 |
| 9 | 3.947 | 65,8 | 0% | 2 | **6** | 10 |
| 10 | 3.928 | 65,5 | 0% | 2 | **6** | 17 |
| 11 | 3.921 | 65,4 | 0% | 2 | **6** | 11 |
| 12 | 3.912 | 65,2 | 0% | 2 | **6** | 10 |

| Khoảng | p95 | Ghi chú |
|---|---|---|
| 5 phút đầu | **7 ms** | 17.898 sample |
| 5 phút cuối | **6 ms** | 19.667 sample |
| **Độ trôi** | **−14,3%** | ngưỡng cho phép ±20% → **đạt** |

**Kết luận: ỔN ĐỊNH** theo đúng định nghĩa đã chốt trước khi chạy. p95 **giảm** theo thời gian
chứ không tăng.

Phút 1 chỉ có 46,9 RPS vì còn đang ramp-up (60s); từ phút 2 trở đi throughput đứng rất chắc ở
65–66 RPS với biên độ dưới 2%.

## 5. Có rò rỉ bộ nhớ không

RSS `node` tăng **+80,8%** (19,8 → 35,8 MB). Con số phần trăm nghe như rò rỉ, nhưng **không phải**,
và cơ sở để loại giả thuyết đó không phải là "12 phút thì chưa sao":

1. **Mốc xuất phát rất thấp.** 19,8 MB là RSS lúc process vừa nhận request đầu tiên, chưa nạp
   xong module và chưa có cache trang SQLite. 35,8 MB là heap ổn định sau warm-up.
2. **p95 giảm −14,3%.** Rò rỉ bộ nhớ trong Node gần như luôn kéo theo p95 **tăng** vì GC phải làm
   việc nhiều dần. Ở đây p95 đi ngược lại.
3. **Đỉnh 83,1 MB trên máy 16 GB** — bằng 0,5% RAM. Kể cả nếu tăng tuyến tính suốt 12 phút thì
   cũng còn cách rất xa mọi giới hạn.

Muốn khẳng định chắc chắn thì phải chạy soak **≥60 phút** và xem RSS có tiếp tục leo sau khi
p95 đã ổn định. Lượt 12 phút của bài này **không đủ để kết luận về rò rỉ**, chỉ đủ để nói *không
thấy dấu hiệu nào*.

## 6. Ngưỡng này có nghĩa gì và không có nghĩa gì

**Có nghĩa:** trên máy `Le-Nhut-Duy.local` (M2 Pro, 12 lõi, 16 GB), với cấu hình load generator
**và** SUT cùng máy, backend EShop giữ được **63 req/s trong 12 phút** với p95 6ms, 0% error, và
không suy giảm.

**Không có nghĩa:**

- **Không phải năng lực tối đa của backend.** 63 req/s là mức do **20 VU và think-time 1–2s**
  quyết định, không phải do server chạm giới hạn: `node` CPU đỉnh chỉ **19,7%**. Lượt Stress cho
  thấy cùng backend đó chịu **550 req/s** vẫn 0% error.
- **Không phải ngưỡng của một endpoint đơn lẻ**, mà của **cả workflow 6 bước**.
- **Không suy ra được cho môi trường khác.** SUT là một process Node, một luồng JS + SQLite ghi
  tuần tự. Trần thật của nó là ~100% của **một** lõi; 11 lõi còn lại của máy không giúp gì.
- **Không đo được ngưỡng thật vì load generator chạm giới hạn trước.** Ở Stress, JMeter tiêu CPU
  đỉnh **158%** trong khi `node` (ở lượt Spike với 212 VU) chỉ đỉnh **79%**. Muốn tìm ngưỡng thật
  của backend thì phải tách load generator sang máy khác, hoặc dùng k6 — xem
  [`report/main-report.md §3.2`](../report/main-report.md).

## 7. Muốn tìm ngưỡng thật thì làm gì tiếp

Ba bước, theo thứ tự rẻ → đắt:

1. **Chạy lại Stress bằng k6** ([`k6/stress.js`](../k6/stress.js)) — goroutine nhẹ hơn thread JVM
   nhiều bậc, nên cùng một máy sẽ đẩy được tải cao hơn. So p95 với bản JMeter để **định lượng**
   phần chi phí thuộc về load generator.
2. **Bỏ think-time và tăng VU** cho tới khi `node` CPU chạm ~100% một lõi. Đó mới là trần của SUT.
3. **Tách load generator sang máy khác** trong cùng LAN. Đắt nhất nhưng là cách duy nhất loại bỏ
   hoàn toàn việc hai bên tranh CPU.
