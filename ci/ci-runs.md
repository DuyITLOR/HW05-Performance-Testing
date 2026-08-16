# Continuous Performance Testing — 6 lượt CI thật

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178
- **Workflow:** [`.github/workflows/perf-smoke.yml`](../.github/workflows/perf-smoke.yml)
- **Cổng ngưỡng:** [`tools/ci-gate.mjs`](../tools/ci-gate.mjs)
- **Ngày chạy:** 2026-08-15

> **Vì sao vẫn giữ file này dù repo đã public:** link Actions và artifact là bằng chứng bên ngoài,
> có thể hết hạn hoặc thay đổi quyền truy cập. Toàn bộ output cổng ngưỡng được chép nguyên văn vào
> đây để bản ZIP tự chứa đủ bằng chứng.

Workflow hiện thực nhánh **"PR pipeline"** của flow chart §4: checkout SUT → khởi động → seed qua
API → sinh test plan từ **cùng một** định nghĩa workflow → JMeter non-GUI → **cổng ngưỡng quyết
định build đỏ/xanh** → lưu `.jtl` + dashboard làm artifact.

Mục đích **không** phải lấy một dấu tích xanh. §4 lập luận rằng ngưỡng hiệu năng **tuyệt đối** là vô
nghĩa vì nhiễu môi trường lớn hơn tín hiệu — và trước hôm nay đó là **suy đoán trên giấy**. 6 lượt
dưới đây là phép kiểm nó.

---

## 1. Sáu lượt, kết quả

Runner mọi lượt: `Linux x86_64` · **2 vCPU** · RAM 7 GB · `ubuntu-24.04` · Node v20.20.2 · Java
17.0.20 · JMeter 5.6.3 · DB **5 dòng `products`** (bản `database.sqlite` sạch trong repo SUT).
Test plan: **cùng file** `23127178_Load_*.jmx` sinh từ `tools/gen-test-plans.py`, ramp-up 10s, 60s.

| # | Run ID | Kích hoạt | VU | Ngưỡng p95 | Sample | **p95** | p99 | max | Error | `load_1m` đầu lượt | Build |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `31878443521` | push | 5 | 200 ms | 785 | **7** | 14 | 728 | 0% | *(chưa ghi)* | **PASS** |
| 2 | `31878612141` | tay | **20** | **8 ms** | 2.621 | **101** | 1.186 | 1.879 | 0% | *(chưa ghi)* | **FAIL** |
| 3 | `31878808200` | push | 5 | 200 ms | 779 | **8** | 223 | 395 | 0% | 0,49 | **PASS** |
| 4 | `31878937737` | tay | **20** | 200 ms | 2.646 | **15** | 918 | 2.296 | 0% | 0,34 | **PASS** |
| 5 | `31879092139` | tay | **20** | 200 ms | 2.763 | **8** | 32 | 720 | 0% | 0,88 | **PASS** |
| 6 | `31879549205` | push | 5 | 200 ms | 779 | **8** | 14 | 389 | 0% | *(chưa đọc)* | **PASS** |

**Lượt 6 so với lượt 3 — sửa lại một câu đã viết sai.** Bản trước ghi p99/max của lượt 6 là
**223/395** rồi kết luận *"trùng khít lượt 3"*. Đọc lại log GitHub thì lượt 6 là **p99 14 · max 389**,
còn lượt 3 là **p99 223 · max 395** — hai con số 223/395 bị **chép nhầm từ lượt 3 sang lượt 6**, và
người review ngoài bắt được.

Đúng là: hai lượt 5 VU **khớp ở p95** (đều 8ms, đều 779 sample) nhưng **đuôi lệch 16 lần** ở p99
(14 so với 223). Nghĩa là ngay ở 5 VU, **p95 thì lặp lại được, p99 thì không** — kết luận này *mạnh
hơn* câu "trùng khít" ban đầu, vì nó cho thấy phần không ổn định nằm ở **đuôi**, không ở phân vị giữa.

**Một điều chưa giải thích được về lượt 6:** nó do `push` kích hoạt, nhưng đối chiếu
`git diff --name-only` của push đó thì **không file nào khớp** danh sách `paths` của workflow
(`test-plans/**`, `tools/gen-test-plans.py`, `tools/ci-gate.mjs`, `.github/workflows/perf-smoke.yml`).
Giả thuyết chưa kiểm: `concurrency: group: perf-smoke` xếp hàng nên lượt này là lượt bị hoãn từ một
push trước. Ghi là **chưa biết** — đúng nguyên tắc của §2.8, không nhận một cơ chế nghe hợp lý làm
nguyên nhân khi chưa kiểm.

Đối chiếu local (MacBook 12 lõi, batch nộp): **20 VU · p95 8ms · p99 12 · max 84 · 0% error.**

`load_1m` của lượt 1–2 không có vì bước ghi điều kiện lúc đó chỉ ghi vào `$GITHUB_STEP_SUMMARY`,
mà job summary **không lấy lại được qua API** sau khi run xong. Đã sửa thành `tee` từ lượt 3.
Ghi ra đây thay vì lặng lẽ để trống hai ô.

---

## 2. Đọc ra gì — và điều tôi đi tìm không phải điều tìm được

### 2.1 Ngưỡng của máy này áp lên máy khác thì build đỏ (lượt 2)

Cùng test plan, cùng SUT, cùng 20 VU, chỉ khác **máy chạy**: ngưỡng `p95 ≤ 8ms` lấy từ số đo local
làm build **FAIL** ở 101ms. Đây là điều workflow được dựng ra để kiểm, và nó xảy ra thật.

### 2.2 Nhưng ở 5 VU thì cùng ngưỡng đó lại PASS — tín hiệu xanh giả (lượt 1, 3)

Runner 2 vCPU ở **5 VU** cho p95 **7–8ms**, tức **bằng** máy 12 lõi ở 20 VU. Một smoke test nhỏ hơn
thiết kế sẽ **đi qua đúng cái ngưỡng mà nó lẽ ra phải chặn**. Kết luận cho §4: ngưỡng phải luôn
**đi kèm mức tải**, và `--min-samples` của cổng không bảo vệ được điều này — 785 sample là đủ nhiều,
chỉ là đo ở mức tải sai.

### 2.3 Phát hiện lớn nhất, và tôi không đi tìm nó: **cùng cấu hình, ba kết quả khác nhau**

Lượt 2, 4, 5 **giống nhau từng tham số** — 20 VU, ramp 10s, 60s, cùng plan, cùng runner spec:

| | Lượt 2 | Lượt 4 | Lượt 5 |
|---|---|---|---|
| **p95** | **101 ms** | **15 ms** | **8 ms** |
| p99 | 1.186 | 918 | 32 |
| max | 1.879 | 2.296 | 720 |
| Sample | 2.621 | 2.646 | 2.763 |

**p95 lệch 12,6 lần giữa hai lượt không khác nhau một tham số nào.** Hệ quả trực tiếp: ngưỡng 8ms
làm build **đỏ** ở lượt 2 thì ở lượt 5 **vừa đủ xanh** — cùng code, cùng plan, cùng ngưỡng. Một cổng
hiệu năng đặt bằng số tuyệt đối trên runner dùng chung là một cổng **tung đồng xu**.

Cùng chuyện ở đuôi, ngay cả tại 5 VU: p99 **14ms** (lượt 1) so với **223ms** (lượt 3) — **16 lần**,
trong khi p95 hai lượt đó chỉ lệch 7 vs 8.

`load_1m` đo lúc **bắt đầu** lượt **không** dự báo được: 0,34 → p95 15ms, còn 0,88 → p95 8ms, ngược
chiều. Nghĩa là nhiễu đến **trong lúc** đo (máy ảo dùng chung hạ tầng với người khác), và bài này
**không có** dữ liệu lấy mẫu tài nguyên xuyên lượt trên CI để chỉ ra thủ phạm. Ghi nhận là **chưa
biết**, không đoán.

### 2.4 Điều duy nhất ổn định qua cả 6 lượt: **error rate 0%**

Cả 6 lượt đều 0% error, kể cả lượt p95 vọt lên 101ms, và phân bố mã trả về giữ nguyên hình dạng
(`200` chiếm ~79%, `400` của FR-10 ~18%, `403` lockout ~3%). Vậy **error rate mang được qua môi
trường, còn phân vị độ trễ thì không**. Đó là một kết luận dùng được: cổng CI nên chặn bằng error
rate và bằng **so sánh tương đối trong cùng một lượt**, không bằng ngưỡng p95 tuyệt đối.

---

## 3. Output nguyên văn của cổng ngưỡng

### Lượt 2 — `31878612141` · 20 VU · ngưỡng 8 ms → **BUILD FAIL**

```
Cổng ngưỡng — ci-out/ci-load.jtl

  Chỉ số       Đo được      Ngưỡng         Kết quả
  ────────────────────────────────────────────────────
  Sample       2621         ≥ 200          PASS
  Error rate   0.00%        ≤ 1%           PASS
  p95          101 ms       ≤ 8 ms         FAIL

  Số không dùng để gate, in ra để lúc fail còn đọc được:
    avg 34.9 · p50 2 · p90 11 · p99 1186 · max 1879 ms
    mã trả về: 200×2059 · 400×468 · 403×90 · 401×4

  p95 theo endpoint:
    1 POST /api/login                          75 ms   (513 sample)
    2 GET /api/admin/orders                    58 ms   (511 sample)
    3 GET /api/admin/users                     67 ms   (504 sample)
    4 POST /api/admin/import-products          166 ms   (501 sample)
    5 PUT /api/admin/orders/:id/status         53 ms   (498 sample)
    6 POST /api/login (sai mat khau — lockout probe) 4 ms   (94 sample)

  BUILD FAIL — vượt 1 ngưỡng: p95
```

Thứ tự endpoint đắt nhất **giữ nguyên** như local: `import-products` (166ms) vẫn đứng đầu, đúng như
§2.3 — nó là endpoint `INSERT` duy nhất. Nghĩa là **thứ tự tương đối giữa các endpoint mang được qua
môi trường, còn giá trị tuyệt đối thì không.** Đây là căn cứ cho đề xuất ở §4: gate theo **thứ hạng
và tỉ lệ trong cùng lượt**, không theo con số ms.

### Lượt 5 — `31879092139` · 20 VU · ngưỡng 200 ms → **BUILD PASS**

```
  Sample       2763         ≥ 200          PASS
  Error rate   0.00%        ≤ 1%           PASS
  p95          8 ms         ≤ 200 ms       PASS

    avg 7.3 · p50 2 · p90 6 · p99 32 · max 720 ms
    mã trả về: 200×2173 · 400×496 · 403×90 · 401×4
```

Cùng 20 VU với lượt 2. p95 **8ms thay vì 101ms**.

### Lượt 3 — `31878808200` · 5 VU · ngưỡng 200 ms → **BUILD PASS**

```
  Sample       779          ≥ 200          PASS
  Error rate   0.00%        ≤ 1%           PASS
  p95          8 ms         ≤ 200 ms       PASS

    avg 7.8 · p50 3 · p90 6 · p99 223 · max 395 ms
    mã trả về: 200×578 · 400×105 · 403×92 · 401×4
```

---

## 4. Hai chi tiết của cổng ngưỡng, và vì sao chúng cần thiết

**Cổng đọc cột `success`, không tự suy từ `responseCode`.** Test plan đánh dấu 4xx hợp lệ là pass
qua `JSR223PostProcessor` — FR-10 invalid transition và account lockout. Một cổng tự tính lại
pass/fail từ mã HTTP sẽ dựng lại đúng lỗi **18,25% error rate** mà bài này mất hai lượt chạy để bắt
(lỗi #2 và #7 trong AI audit). Kiểm trên `.jtl` thật: **496 mã `400` + 90 mã `403`, error rate
0,00%**.

**Cổng có sàn số sample (`--min-samples 200`).** Một lượt chết ở giây thứ 3 cho p95 = 2ms và **đi
qua mọi ngưỡng trên**. Không có sàn thì cổng bảo vệ *sự im lặng*, không bảo vệ hiệu năng.

---

## 5. Cách chạy lại

```bash
gh workflow run perf-smoke.yml -f p95_ms=8 -f threads=20 -f duration=60    # bản làm build ĐỎ
gh workflow run perf-smoke.yml -f p95_ms=200 -f threads=20 -f duration=60  # bản XANH
gh run list --workflow=perf-smoke.yml
```

Cổng chạy được ngoài CI, trên bất kỳ `.jtl` nào:

```bash
node tools/ci-gate.mjs results/jtl/23127178_Load_20260815-152938.jtl --p95 8 --error-rate 1
```
