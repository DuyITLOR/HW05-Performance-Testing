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
| Thời lượng | **719,6s** (12 phút) |
| Bắt đầu / kết thúc (UTC) | `2026-08-15T07:49:51Z` → `2026-08-15T08:01:57Z` |
| Raw log | [`endurance/jtl/23127178_Soak_20260815-144951.jtl`](jtl/) — 45.220 sample |
| Dashboard | [`endurance/html/soak/index.html`](html/soak/index.html) |
| Mẫu tài nguyên | [`endurance/resources/23127178_Soak_20260815-144951.resources.csv`](resources/) — 2 giây/mẫu |
| Kích thước dữ liệu | bảng `products` **830.139 dòng** |
| **Tải nền khi đo** | `load_1m` trung bình **3,8** trên máy 12 lõi — biến số áp đảo, xem [main-report §2.8](../report/main-report.md) |

## 3. Kết quả — ngưỡng tìm được

| Chỉ số | Giá trị | Lấy từ đâu |
|---|---|---|
| **Max stable RPS** | **62,8 req/s** | 45.220 sample / 719,6s |
| **p95 toàn lượt** | **6 ms** | `results/summary.md`, dòng Soak |
| p99 toàn lượt | 11 ms | như trên |
| max | 230 ms | như trên |
| Error rate | **0%** | không có sample nào `success=false` |
| **RSS `node` đầu → cuối** | **19,3 → 29,0 MB** | file resources cùng lượt |
| **Trần bộ nhớ (RSS đỉnh)** | **83,5 MB** | như trên |
| CPU `node` đỉnh | **22,1%** | như trên |
| CPU JMeter đỉnh | 139,2% · RSS đỉnh 818 MB | như trên |

### Theo endpoint

| Endpoint | Sample | avg | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|
| 1 POST /api/login | 9.033 | 1,9 | 3 | **5** | 9 | 130 |
| 2 GET /api/admin/orders | 9.030 | 3,7 | 6 | **7** | 12 | 115 |
| 3 GET /api/admin/users | 9.027 | 1,9 | 3 | **4** | 8 | 169 |
| 4 POST /api/admin/import-products | 9.021 | 4,2 | 7 | **8** | 15 | 230 |
| 5 PUT /api/admin/orders/:id/status | 9.016 | 1,6 | 3 | **4** | 8 | 133 |
| 6 POST /api/login (lockout probe) | 89 | 1,6 | 3 | **4** | 8 | 8 |

## 4. p95 có trôi không — bảng theo từng phút

| Phút | Sample | RPS | Error % | p50 | **p95** | p99 |
|---|---|---|---|---|---|---|
| 1 | 2100 | 35 | 0% | 3 | **8** | 10 |
| 2 | 3952 | 65,9 | 0% | 2 | **6** | 9 |
| 3 | 3936 | 65,6 | 0% | 2 | **6** | 14 |
| 4 | 3914 | 65,2 | 0% | 2 | **6** | 9 |
| 5 | 3918 | 65,3 | 0% | 2 | **7** | 9 |
| 6 | 3933 | 65,6 | 0% | 2 | **7** | 12 |
| 7 | 3909 | 65,2 | 0% | 2 | **6** | 9 |
| 8 | 3901 | 65 | 0% | 2 | **6** | 23 |
| 9 | 3931 | 65,5 | 0% | 2 | **6** | 10 |
| 10 | 3931 | 65,5 | 0% | 2 | **6** | 10 |
| 11 | 3909 | 65,2 | 0% | 2 | **7** | 13 |
| 12 | 3886 | 64,8 | 0% | 2 | **6** | 17 |

| Khoảng | p95 | Ghi chú |
|---|---|---|
| 5 phút đầu | **6 ms** | 17.820 sample |
| 5 phút cuối | **6 ms** | 19.584 sample |
| **Độ trôi** | **+0%** | ngưỡng cho phép ±20% → **đạt** |

**Kết luận: ỔN ĐỊNH** theo đúng định nghĩa đã chốt trước khi chạy. Độ trôi **đúng 0%** — p95 phút 1
và phút 12 đều 6ms.

Phút 1 có RPS thấp hơn vì còn đang ramp-up (60s); từ phút 2 trở đi throughput đứng rất chắc ở
65–66 RPS với biên độ dưới 2%. Các phút lẻ có p95 nhích lên 7ms là nhiễu bình thường, không thành xu hướng. Đây là loại dao động
mà nếu chỉ nhìn số tổng thì không thấy, và là lý do ngưỡng hồi quy ở Task 3 đặt 20% chứ không phải 5%.

## 5. Có rò rỉ bộ nhớ không

RSS `node` tăng **+50,3%** (19,3 → 29,0 MB). Con số phần trăm nghe như rò rỉ, nhưng **không phải**,
và cơ sở để loại giả thuyết đó không phải là "12 phút thì chưa sao":

1. **Mốc xuất phát rất thấp.** 19,3 MB là RSS lúc process vừa nhận request đầu tiên. 29,0 MB là heap
   ổn định sau warm-up. Tăng 50% của một con số nhỏ vẫn là một con số nhỏ.
2. **p95 trôi 0%.** Rò rỉ trong Node gần như luôn kéo p95 **tăng** vì GC phải làm việc nhiều dần.
3. **Đỉnh 83,5 MB trên máy 16 GB** — bằng 0,5% RAM.

Muốn khẳng định chắc chắn thì phải chạy soak **≥60 phút** và xem RSS có tiếp tục leo sau khi
p95 đã ổn định. Lượt 12 phút của bài này **không đủ để kết luận về rò rỉ**, chỉ đủ để nói *không
thấy dấu hiệu nào*.

## 6. Ngưỡng này có nghĩa gì và không có nghĩa gì

**Có nghĩa:** trên máy `Le-Nhut-Duy.local`, với load generator **và** SUT cùng máy, `load_1m` trung
bình **3,8**, và bảng `products` ở **830.139 dòng**, backend EShop giữ được **62,8 req/s trong 12
phút** với p95 6ms, 0% error, không suy giảm.

**Không có nghĩa:**

- **Không phải năng lực tối đa của backend.** 62,8 req/s là mức do **20 VU và think-time 1–2s** quyết
  định: `node` CPU lúc đó chỉ **22,1%**. Cùng backend đó ở lượt Stress chịu **564 req/s** vẫn 0% lỗi,
  và ở đó CPU mới lên **98,4%** — đó mới là mức sát trần.
- **Không so được với lượt soak nào có tải nền khác.** Đây là giới hạn quan trọng nhất và nó có số đo:
  xem [`main-report §2.8`](../report/main-report.md), nơi `load_1m` chênh 1,7 lần đã tạo ra chênh lệch
  10 lần ở p95 của lượt Stress. Mọi con số trong file này chỉ có nghĩa **kèm điều kiện `load_1m` ≈ 3,8**.
- **Không phải ngưỡng của một endpoint đơn lẻ**, mà của **cả workflow 6 bước**.
- **Không suy ra được cho môi trường khác.** SUT là một process Node + SQLite một writer; trần thật là
  ~100% của **một** lõi, 11 lõi còn lại không giúp gì.

## 7. Muốn tìm ngưỡng thật thì làm gì tiếp

Ba bước, theo thứ tự rẻ → đắt:

1. **Chạy lại Stress bằng k6** ([`k6/stress.js`](../k6/stress.js)) — goroutine nhẹ hơn thread JVM
   nhiều bậc, nên cùng một máy sẽ đẩy được tải cao hơn. So p95 với bản JMeter để **định lượng**
   phần chi phí thuộc về load generator.
2. **Bỏ think-time và tăng VU** cho tới khi `node` CPU chạm ~100% một lõi. Đó mới là trần của SUT.
3. **Tách load generator sang máy khác** trong cùng LAN. Đắt nhất nhưng là cách duy nhất loại bỏ
   hoàn toàn việc hai bên tranh CPU.
