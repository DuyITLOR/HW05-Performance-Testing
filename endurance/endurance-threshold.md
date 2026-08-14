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
| Thời lượng | **725s** (12 phút 5 giây) |
| Bắt đầu / kết thúc (UTC) | `2026-08-14T03:32:46Z` → `2026-08-14T03:44:51Z` |
| Raw log | [`endurance/jtl/23127178_Soak_20260814-103245.jtl`](jtl/) — 45.288 sample |
| Dashboard | [`endurance/html/soak/index.html`](html/soak/index.html) |
| Mẫu tài nguyên | [`endurance/resources/23127178_Soak_20260814-103245.resources.csv`](resources/) — 2 giây/mẫu |
| Kích thước dữ liệu | bảng `products` **436.692 dòng**, file SQLite **33 MB** — xem [main-report §2.8](../report/main-report.md) |

## 3. Kết quả — ngưỡng tìm được

| Chỉ số | Giá trị | Lấy từ đâu |
|---|---|---|
| **Max stable RPS** | **62,9 req/s** | 45.288 sample / 719,7s |
| **p95 toàn lượt** | **6 ms** | `results/summary.md`, dòng Soak |
| p99 toàn lượt | 16 ms | như trên |
| max | 365 ms | như trên |
| Error rate | **0%** | không có sample nào `success=false` |
| **RSS `node` đầu → cuối** | **16,9 → 33,9 MB** | file resources cùng lượt |
| **Trần bộ nhớ (RSS đỉnh)** | **80,8 MB** | như trên |
| CPU `node` đỉnh | **20,7%** | như trên |
| CPU JMeter đỉnh | 161% · RSS đỉnh 812 MB | như trên |

### Theo endpoint

| Endpoint | Sample | avg | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|
| 1 POST /api/login | 9.046 | 2,2 | 3 | **5** | 12 | 365 |
| 2 GET /api/admin/orders | 9.041 | 4,0 | 6 | **7** | 20 | 331 |
| 3 GET /api/admin/users | 9.039 | 2,2 | 3 | **5** | 12 | 343 |
| 4 POST /api/admin/import-products | 9.036 | 4,8 | 7 | **9** | 25 | 360 |
| 5 PUT /api/admin/orders/:id/status | 9.031 | 2,0 | 3 | **4** | 11 | 362 |
| 6 POST /api/login (lockout probe) | 95 | 1,6 | 3 | **4** | 5 | 5 |

## 4. p95 có trôi không — bảng theo từng phút

| Phút | Sample | RPS | Error % | p50 | **p95** | p99 |
|---|---|---|---|---|---|---|
| 1 | 2.104 | 35,1 | 0% | 2 | **6** | 13 |
| 2 | 3.979 | 66,3 | 0% | 2 | **6** | 12 |
| 3 | 3.929 | 65,5 | 0% | 2 | **6** | 12 |
| 4 | 3.937 | 65,6 | 0% | 2 | **6** | 11 |
| 5 | 3.912 | 65,2 | 0% | 2 | **8** | 28 |
| 6 | 3.930 | 65,5 | 0% | 2 | **7** | 9 |
| 7 | 3.921 | 65,4 | 0% | 2 | **7** | 17 |
| 8 | 3.900 | 65,0 | 0% | 2 | **8** | **105** |
| 9 | 3.902 | 65,0 | 0% | 2 | **7** | 19 |
| 10 | 3.935 | 65,6 | 0% | 2 | **6** | 9 |
| 11 | 3.922 | 65,4 | 0% | 2 | **7** | 23 |
| 12 | 3.917 | 65,3 | 0% | 2 | **6** | 11 |

| Khoảng | p95 | Ghi chú |
|---|---|---|
| 5 phút đầu | **6 ms** | 17.861 sample |
| 5 phút cuối | **6 ms** | 19.599 sample |
| **Độ trôi** | **+0%** | ngưỡng cho phép ±20% → **đạt** |

**Kết luận: ỔN ĐỊNH** theo đúng định nghĩa đã chốt trước khi chạy. Độ trôi **đúng 0%** — p95 phút 1
và phút 12 đều 6ms.

Phút 1 chỉ có 35,1 RPS vì còn đang ramp-up (60s); từ phút 2 trở đi throughput đứng rất chắc ở
65–66 RPS với biên độ dưới 2%. Phút 5 và 8 có p95 nhích lên 8ms và p99 phút 8 lên **105ms** — một
đỉnh đơn lẻ, không thành xu hướng (phút 9–12 trở lại 6–7ms). Đây là loại nhiễu mà nếu chỉ nhìn số
tổng thì không thấy, và cũng là lý do ngưỡng hồi quy ở Task 3 đặt 20% chứ không phải 5%.

## 5. Có rò rỉ bộ nhớ không

RSS `node` tăng **+100,6%** (16,9 → 33,9 MB) — gấp đôi. Con số phần trăm nghe rất giống rò rỉ,
nhưng **không phải**, và cơ sở để loại giả thuyết đó không phải là "12 phút thì chưa sao":

1. **Mốc xuất phát rất thấp.** 16,9 MB là RSS lúc process vừa nhận request đầu tiên, chưa nạp xong
   module và chưa có cache trang SQLite. 33,9 MB là heap ổn định sau warm-up. Gấp đôi một con số
   nhỏ vẫn là một con số nhỏ — đây đúng là chỗ đọc phần trăm mà bỏ giá trị tuyệt đối sẽ kết luận sai.
2. **p95 trôi 0%.** Rò rỉ bộ nhớ trong Node gần như luôn kéo theo p95 **tăng** vì GC phải làm việc
   nhiều dần. Ở đây p95 phút 1 và phút 12 bằng nhau.
3. **Đỉnh 80,8 MB trên máy 16 GB** — bằng 0,5% RAM.

Muốn khẳng định chắc chắn thì phải chạy soak **≥60 phút** và xem RSS có tiếp tục leo sau khi
p95 đã ổn định. Lượt 12 phút của bài này **không đủ để kết luận về rò rỉ**, chỉ đủ để nói *không
thấy dấu hiệu nào*.

## 6. Ngưỡng này có nghĩa gì và không có nghĩa gì

**Có nghĩa:** trên máy `Le-Nhut-Duy.local` (M2 Pro, 12 lõi, 16 GB), với load generator **và** SUT
cùng máy, và bảng `products` ở **436.692 dòng**, backend EShop giữ được **62,9 req/s trong 12
phút** với p95 6ms, 0% error, không suy giảm.

**Không có nghĩa:**

- **Không phải năng lực tối đa của backend.** 62,9 req/s là mức do **20 VU và think-time 1–2s**
  quyết định, không phải do server chạm giới hạn: `node` CPU đỉnh chỉ **20,7%**. Lượt Stress cho
  thấy cùng backend đó chịu **524,8 req/s** vẫn 0% error, và ở đó `node` CPU mới đạt **108%**.
- **Không phải ngưỡng của một endpoint đơn lẻ**, mà của **cả workflow 6 bước**.
- **Không suy ra được cho kích thước dữ liệu khác.** Đây là giới hạn quan trọng nhất và nó có số
  đo hẳn hoi: cùng lượt soak này trên DB nhỏ hơn 8 lần cho **cùng** p95 6ms, nhưng cùng lượt
  **Stress** thì chênh **2,4–2,8 lần**. Ở 20 VU thì kích thước dữ liệu không ảnh hưởng; ở 200 VU
  thì ảnh hưởng nặng — xem [`main-report §2.8`](../report/main-report.md).
- **Không suy ra được cho môi trường khác.** SUT là một process Node + SQLite một writer.

## 7. Muốn tìm ngưỡng thật thì làm gì tiếp

Ba bước, theo thứ tự rẻ → đắt:

1. **Chạy lại Stress bằng k6** ([`k6/stress.js`](../k6/stress.js)) — goroutine nhẹ hơn thread JVM
   nhiều bậc, nên cùng một máy sẽ đẩy được tải cao hơn. So p95 với bản JMeter để **định lượng**
   phần chi phí thuộc về load generator.
2. **Bỏ think-time và tăng VU** cho tới khi `node` CPU chạm ~100% một lõi. Đó mới là trần của SUT.
3. **Tách load generator sang máy khác** trong cùng LAN. Đắt nhất nhưng là cách duy nhất loại bỏ
   hoàn toàn việc hai bên tranh CPU.
