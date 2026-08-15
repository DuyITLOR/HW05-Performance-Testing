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
| Bắt đầu / kết thúc (UTC) | `2026-08-15T08:52:47Z` → `2026-08-15T09:04:51Z` |
| Raw log | [`endurance/jtl/23127178_Soak_20260815-155247.jtl`](jtl/) — 45.166 sample |
| Dashboard | [`endurance/html/soak/index.html`](html/soak/index.html) |
| Mẫu tài nguyên | [`endurance/resources/23127178_Soak_20260815-155247.resources.csv`](resources/) — 2 giây/mẫu |
| Kích thước dữ liệu | bảng `products` ~**900.000 dòng** |
| **Tải nền khi đo** | `load_1m` trung bình **4,6** trên máy 12 lõi — biến số áp đảo, xem [main-report §2.8](../report/main-report.md) |

## 3. Kết quả — ngưỡng tìm được

| Chỉ số | Giá trị | Lấy từ đâu |
|---|---|---|
| **Max stable RPS** | **62,8 req/s** | 45.166 sample / 719,6s |
| **p95 toàn lượt** | **8 ms** | `results/summary.md`, dòng Soak |
| p99 toàn lượt | 12 ms | như trên |
| max | 192 ms | như trên |
| Error rate | **0%** | không có sample nào `success=false` |
| **RSS nửa đầu → nửa sau** | **74,5 → 78,3 MB** (**+5,0%**) | file resources — xem mục 5 vì sao KHÔNG dùng mẫu-đầu/mẫu-cuối |
| **Trần bộ nhớ (RSS đỉnh)** | **83,1 MB** | như trên |
| CPU `node` đỉnh | **23,6%** | như trên |
| CPU JMeter đỉnh | 49,3% · RSS đỉnh 822 MB | như trên |

### Theo endpoint

| Endpoint | Sample | avg | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|
| 1 POST /api/login | 9.019 | 2,8 | 5 | **6** | 10 | 125 |
| 2 GET /api/admin/orders | 9.018 | 4,8 | 7 | **8** | 12 | 88 |
| 3 GET /api/admin/users | 9.014 | 2,7 | 5 | **6** | 10 | 116 |
| 4 POST /api/admin/import-products | 9.012 | 5,4 | 8 | **10** | 14 | 192 |
| 5 PUT /api/admin/orders/:id/status | 9.009 | 2,3 | 4 | **5** | 9 | 81 |
| 6 POST /api/login (lockout probe) | 90 | 2,3 | 4 | **5** | 9 | 9 |

## 4. p95 có trôi không — bảng theo từng phút

| Phút | Sample | RPS | Error % | p50 | **p95** | p99 |
|---|---|---|---|---|---|---|
| 1 | 2096 | 34,9 | 0% | 4 | **9** | 12 |
| 2 | 3959 | 66 | 0% | 3 | **8** | 13 |
| 3 | 3927 | 65,5 | 0% | 2 | **7** | 10 |
| 4 | 3911 | 65,2 | 0% | 3 | **8** | 14 |
| 5 | 3930 | 65,5 | 0% | 3 | **8** | 12 |
| 6 | 3903 | 65,1 | 0% | 3 | **9** | 18 |
| 7 | 3902 | 65 | 0% | 3 | **8** | 12 |
| 8 | 3909 | 65,2 | 0% | 3 | **8** | 12 |
| 9 | 3927 | 65,5 | 0% | 3 | **7** | 10 |
| 10 | 3904 | 65,1 | 0% | 3 | **8** | 11 |
| 11 | 3897 | 65 | 0% | 3 | **8** | 11 |
| 12 | 3901 | 65 | 0% | 3 | **7** | 10 |

| Khoảng | p95 | Ghi chú |
|---|---|---|
| 5 phút đầu | **8 ms** | 17.823 sample |
| 5 phút cuối | **8 ms** | 19.563 sample |
| **Độ trôi** | **+0%** | ngưỡng ±20% → **đạt** |

**Kết luận: ỔN ĐỊNH** theo đúng định nghĩa đã chốt trước khi chạy. Độ trôi **đúng 0%** — p95 phút 1
và phút 12 đều 6ms.

Phút 1 có RPS thấp hơn vì còn đang ramp-up (60s); từ phút 2 trở đi throughput đứng rất chắc ở
65–66 RPS với biên độ dưới 2%. Các phút lẻ có p95 nhích lên 7ms là nhiễu bình thường, không thành xu hướng. Đây là loại dao động
mà nếu chỉ nhìn số tổng thì không thấy, và là lý do ngưỡng hồi quy ở Task 3 đặt 20% chứ không phải 5%.

## 5. Có rò rỉ bộ nhớ không

**Trước hết, một con số phải bỏ đi.** Tool `soak-drift.mjs` ban đầu in *"Trôi RSS +228,9%"*, tính bằng
**mẫu cuối chia mẫu đầu**. Mẫu đầu là **19,7 MB** — lấy lúc process vừa nhận request đầu tiên, chưa nạp
xong module, chưa có cache trang SQLite. So nó với mẫu cuối là so hai trạng thái khác nhau. Con số đó
đọc như một vụ rò rỉ, và nếu tin nó thì báo cáo kết luận sai. Đã sửa tool; ghi thành lỗi #13 trong
[`ai-audit/ai-audit-report.md`](../ai-audit/ai-audit-report.md).

**Số đúng: nửa đầu 74,5 MB → nửa sau 78,3 MB = +5,0%.** RSS theo từng phút cho thấy rõ hình dạng:

| Phút | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RSS tb (MB) | 59,5 | 80,0 | 74,7 | 77,5 | 79,0 | 76,6 | 76,9 | 78,0 | 79,0 | 79,4 | 78,0 | 79,1 | 71,8 |

Phút 1 thấp vì đang ramp-up. Từ phút 2 trở đi RSS **đi ngang trong dải 75–80 MB** suốt 12 phút.

Ba lý do loại giả thuyết rò rỉ:

1. **Hình dạng là bậc thang rồi phẳng**, không phải đường leo. Rò rỉ cho đường leo đơn điệu.
2. **p95 trôi 0%.** Rò rỉ trong Node gần như luôn kéo p95 tăng vì GC làm việc nhiều dần.
3. **Đỉnh 83,1 MB trên máy 16 GB** — bằng 0,5% RAM.

Muốn khẳng định chắc chắn thì phải chạy soak **≥60 phút** và xem RSS có tiếp tục leo sau khi p95 đã ổn
định. Lượt 12 phút **không đủ để kết luận về rò rỉ**, chỉ đủ để nói *không thấy dấu hiệu nào*.

## 6. Ngưỡng này có nghĩa gì và không có nghĩa gì

**Có nghĩa:** trên máy `Le-Nhut-Duy.local`, load generator **và** SUT cùng máy, `load_1m` trung bình
**4,6**, bảng `products` ~900.000 dòng — backend EShop giữ được **62,8 req/s trong 12 phút** với p95
8ms, 0% error, không suy giảm.

**Không có nghĩa:**

- **Không phải năng lực tối đa của backend.** 62,8 req/s do **20 VU và think-time 1–2s** quyết định:
  `node` CPU lúc đó chỉ **23,6%**. Cùng backend ở lượt Stress chịu **539,7 req/s**, và ở đó CPU mới lên
  **97,7%** — đó mới là mức sát trần.
- **Không so được với lượt soak nào có tải nền khác.** Đây là giới hạn quan trọng nhất và nó có số đo:
  [`main-report §2.8`](../report/main-report.md) cho ba điểm dữ liệu nơi `load_1m` chênh 1,8 lần tạo ra
  chênh **2,6 lần** ở p95 Stress. Mọi con số trong file này chỉ có nghĩa **kèm `load_1m` ≈ 4,6**.
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
