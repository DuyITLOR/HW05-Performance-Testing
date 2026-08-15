# Task 1 — bảng trace để tự review

> File nội bộ, **không nộp** (`package.sh` không đưa vào gói). Dùng để đi qua từng ý của Task 1,
> tự mở file kiểm, rồi tick.
>
> Task 2 / Task 3 / các mục §5–§15: xem [`TASKS.md`](../TASKS.md).

**Tình trạng: 6/9 ý xong · 3 ý chưa làm.**

| Ý | Yêu cầu | Trạng thái |
|---|---|---|
| 1 | Design and generate with AI | **Xong** — nhật ký 7 bước ở `ai-audit/design-log.md`; còn 1 việc của sinh viên |
| 2 | Make the workflow data-driven | **Xong** |
| 3 | Use three different report views | **Xong** |
| 4 | Name each test plan | **Xong** |
| 5 | Review and fix (human review) | **Xong** |
| 6 | Run as completely as possible, with evidence | **Hở** — thiếu 5 ảnh |
| 7 | Determine the endurance threshold | **Xong** |
| 8 | Record a demo video | **Chưa** |
| 9 | Report issues | Nội dung xong · **chưa mở Issue** |

---

## Ý 1 — Design and generate with AI

> *"Drive an AI tool — step by step, not with a single generic prompt — to design and generate
> three test plans: Load, Stress, and Spike. All three test plans must exercise the same
> end-to-end workflow, covering all three endpoint groups… Have the AI help choose realistic
> parameters (think-time, ramp-up, thread / virtual-user counts) for each scenario, and briefly
> justify how the workflow covers each endpoint group."*

### Đã làm

- **4 plan** (3 bắt buộc + `Soak` phục vụ ý 7), sinh từ một định nghĩa duy nhất.
- **Cùng một workflow**: hằng `WORKFLOW` trong [`tools/gen-test-plans.py`](../tools/gen-test-plans.py) (dòng 29). Cả 4 plan phát ra từ nó nên **không thể lệch nhau** — đây là bằng chứng mạnh nhất cho chữ *"the same end-to-end workflow"*.
- **Phủ 3 nhóm** — workflow 6 bước:

| Bước | Endpoint | Nhóm |
|---|---|---|
| 1 | `POST /api/login` (admin) | auth-heavy |
| 2 | `GET /api/admin/orders` | read-heavy |
| 3 | `GET /api/admin/users` | read-heavy |
| 4 | `POST /api/admin/import-products` | transactional |
| 5 | `PUT /api/admin/orders/:id/status` | transactional |
| 6 | `POST /api/login` (mật khẩu sai) | auth-heavy — nhánh account-lockout |

- **Justify**: cột *"Vì sao đáng đo"* trong [`report/main-report.md §1.2`](../report/main-report.md).
- **Tham số + lý do**: [`§2.1`](../report/main-report.md) — bảng 4 scenario, cộng 3 đoạn giải thích (think-time tính theo **bước** chứ không theo iteration · Stress tăng **theo bậc** để tìm *điểm* gãy · Spike cần **nhánh nền** mới đo được hồi phục).

### Tự kiểm

```bash
grep -n "^WORKFLOW = " tools/gen-test-plans.py     # workflow định nghĩa 1 lần
grep -n "^SCENARIOS = " tools/gen-test-plans.py    # tham số 4 scenario
sed -n '/### 1.2 Workflow/,/### 1.3/p' report/main-report.md
sed -n '/### 2.1 Tham số/,/### 2.2/p' report/main-report.md
```

- [ ] Đọc bảng §1.2, tự thấy 3 nhóm được phủ hợp lý
- [ ] Đọc §2.1, đồng ý với từng con số (20 VU · ramp 60s · think 1–3s/iteration…)
- [ ] Mở 1 file `.jmx` trong JMeter GUI, xác nhận 6 sampler đúng thứ tự

### Bằng chứng "step by step" — [`ai-audit/design-log.md`](../ai-audit/design-log.md)

Đề đòi *"step by step, **not** with a single generic prompt"*. Nhật ký ghi đủ 7 bước, mỗi bước:
hỏi gì · căn cứ nào · quyết ra sao · thay đổi cụ thể nào trong file.

| Bước | Nội dung | Bắt được lỗi |
|---|---|---|
| 1 | Nạp 5 đặc điểm SUT trước khi chốt tham số | — (4/5 về sau gây lỗi nếu bỏ qua) |
| 2 | Chốt tham số, mỗi con số một lý do | — |
| 3 | Sinh `.jmx` bằng script để 3 plan **không thể** lệch workflow | — |
| 4 | Assertion kiểm cả mã lỗi lẫn nội dung | — |
| 5 | Human review theo checklist 8 mục | **1 lỗi** |
| 6 | Smoke test 20–40s trước lượt 6 phút | **2 lỗi** |
| 7 | Đọc kết quả trước khi tin nó | **3 lỗi** (+4 lỗi tooling) |

Con số đắt nhất trong nhật ký: **7/10 lỗi không làm test plan báo lỗi.** Không có bước 5–6–7 thì cả
7 lỗi đó đi thẳng vào báo cáo.

- [ ] Đọc `design-log.md`, đối chiếu với `.jmx` xem các quyết định có khớp file thật không

### ⚠️ Còn một việc chỉ bạn làm được

`design-log.md` chứng minh **quy trình** đi từng bước. Nhưng `ai-audit-report.md` ghi **prompt
nguyên văn của bạn**, và những prompt đó ngắn — *"hãy thực hiện toàn bộ giùm tui"*. Hai file cố ý
tách nhau: trộn lại thành "sinh viên đã hỏi 7 câu" là bịa, và §11 cấm đúng điều đó.

Chỗ khép lại khoảng cách này là **trường Human review** trong 8 lượt audit — nó cho thấy **bạn**
quyết gì ở mỗi bước, không phải AI. Tôi cố ý để trống, không viết thay.

- [ ] Điền Human review cho 8 lượt trong [`ai-audit/ai-audit-report.md`](../ai-audit/ai-audit-report.md) — mỗi lượt vài dòng: kiểm gì, thấy gì, quyết gì
- [ ] *(tuỳ chọn, chắc hơn)* hỏi AI thêm vài lượt tách bước cho một scenario và ghi vào audit — ~15 phút

---

## Ý 2 — Make the workflow data-driven

> *"Use CSV input data in the end-to-end workflow to parameterize requests… You may use one or
> more CSV files."*

### Đã làm — 4 file

| File | Dòng | Cột | Dùng ở bước |
|---|---|---|---|
| [`data/users.csv`](../data/users.csv) | 50 | `email,password,expect` | 1 — **mỗi VU một tài khoản riêng** |
| [`data/users_lockout.csv`](../data/users_lockout.csv) | 2 | `email,password,expect_regex` | 6 — **file riêng** |
| [`data/products_import.csv`](../data/products_import.csv) | 60 | `name,price,description,category_id` | 4 |
| [`data/orders.csv`](../data/orders.csv) | 400 | `order_id,next_status` | 5 |

Hai quyết định đáng review:

1. **Mỗi VU một tài khoản.** Dùng chung một dòng `users` là tự tạo write-contention trên đúng dòng đó (login nào cũng `UPDATE login_attempts` — `server.js:47`), tức đo ra nghẽn của **cách sinh tải** chứ không phải của endpoint.
2. **Nhánh lockout dùng file CSV riêng.** Bản đầu để 2 dòng mật khẩu sai ở cuối `users.csv`; luồng chính đọc chính file đó với `recycle=true` nên **tự khoá tài khoản của mình** → 2,9% iteration vô giá trị. Đây là lỗi #5 trong bảng human review.

### Tự kiểm

```bash
head -3 data/*.csv
grep -c CSVDataSet test-plans/23127178_Load_20260813.jmx    # 8 = 4 khối × 2 dòng tag
npm run seed:perf -- --users 50 --orders 400                # sinh lại toàn bộ
```

- [ ] Xác nhận `users.csv` **không còn** dòng mật khẩu sai nào
- [ ] Xác nhận `orders.csv` chỉ có `confirmed` (chuyển đổi hợp lệ duy nhất từ `pending`)

---

## Ý 3 — Use three different report views

> *"Across the three test plans, use three distinct listener / report types… do not repeat a type."*

### Đã làm

| Plan | Listener | Vì sao đặt ở đây |
|---|---|---|
| Load | **Summary Report** | tải ổn định → cần bảng tổng hợp gọn |
| Stress | **Aggregate Report** (`StatVisualizer`) | cần cột percentile để thấy điểm gãy |
| Spike | **View Results Tree** (`ViewResultsFullVisualizer`) | cần xem *nội dung* response lúc sốc; và chỉ an toàn ở lượt ngắn |
| Soak | Summary Report | trùng Load — nhưng Soak **không thuộc 3 plan bắt buộc**, phục vụ ý 7 |

### Tự kiểm

```bash
for f in test-plans/*.jmx; do
  echo "$(basename $f): $(grep -o 'guiclass="\(SummaryReport\|StatVisualizer\|ViewResultsFullVisualizer\)"' $f | head -1)"
done
```

- [ ] Ba plan bắt buộc ra ba loại khác nhau

---

## Ý 4 — Name each test plan

> *"{StudentID}_{ScenarioType}_{YYYYMMDD}"*

### Đã làm

```
test-plans/23127178_Load_20260813.jmx
test-plans/23127178_Stress_20260813.jmx
test-plans/23127178_Spike_20260813.jmx
test-plans/23127178_Soak_20260813.jmx
```

- [ ] Đúng mẫu. §11 kiểm tay đúng cái tên này.

### ⚠️ Cân nhắc

Ngày trong tên là **13/08** (ngày sinh plan), lượt chạy đang nộp là **14/08**. Đúng mẫu, nhưng nếu
muốn tên khớp ngày chạy: `npm run plans` sinh lại với ngày hôm nay (nhớ chạy lại test sau đó, vì
`run-scenario.sh` tìm plan theo tên).

---

## Ý 5 — Review and fix (human review)

> *"Report what the AI got wrong or missed — for example, unrealistic ramp-up or think-time, wrong
> thread counts, weak assertions, or missing account-lockout handling — and explain **why** it
> missed them (prompt quality, model limitations, or characteristics of the endpoint)."*

### Đã làm — 10 lỗi, đủ 3 nhóm lý do

Bảng đầy đủ: [`report/main-report.md §2.4`](../report/main-report.md) · chi tiết kèm prompt nguyên
văn: [`ai-audit/ai-audit-report.md`](../ai-audit/ai-audit-report.md) (8 lượt).

Đúng những ví dụ đề nêu đều có thật trong danh sách:

| Đề nêu ví dụ | Lỗi tương ứng |
|---|---|
| *unrealistic think-time* | #6 — timer ở scope thread group, chèn 5 lần/iteration → tải nhẹ hơn thiết kế 5 lần |
| *weak assertions* | #2 (lockout 41% error giả) · #3 (bước 5 assert cứng 200) · #7 (18% error giả) |
| *missing account-lockout handling* | #5 — `users.csv` chứa dòng mật khẩu sai, luồng chính tự khoá tài khoản của mình |

Điểm đáng nói nhất khi review: **7 trong 10 lỗi không làm test plan báo lỗi.** Plan vẫn chạy, vẫn
ra `.jtl`, vẫn sinh dashboard — chỉ con số là sai.

### Tự kiểm

```bash
sed -n '/### 2.4 Human review/,/### 2.5/p' report/main-report.md
grep -c "^### Interaction" ai-audit/ai-audit-report.md    # 8 lượt
```

- [ ] Đọc 10 dòng, tự thấy phân loại lý do hợp lý
- [ ] **Điền Human review** cho 8 lượt (xem ý 1)

---

## Ý 6 — Run as completely as possible, with evidence

> *"Execute all three scenarios and capture, for each run, a screenshot of the tool together with
> the backend process's resource usage… plus a hardware report (a dxdiag / screenfetch screenshot
> and a spec table). When Stress/Spike runs trigger the 3-fail login lockout, reset it between runs
> and document the steps. Produce the raw .jtl logs and the HTML report folders."*

### Đã làm

| Thành phần | Trạng thái | Chỗ kiểm |
|---|---|---|
| Chạy đủ 3 scenario | **Có** (+ Soak) | [`results/run-log.md`](../results/run-log.md) |
| Raw `.jtl` | **Có** nhưng lẫn 3 batch — xem cảnh báo dưới | `results/jtl/`, `endurance/jtl/` |
| HTML report folder | **Có** — 4 folder | `results/html/{load,stress,spike}`, `endurance/html/soak` |
| Reset lockout + **ghi thủ tục** | **Có** | [`§2.6`](../report/main-report.md) · `tools/reset-lockout.mjs`, `tools/reset-orders.mjs`, chạy tự động đầu mỗi lượt |
| **Bảng spec** phần cứng | **Có** | [`resource-monitor/hardware-report.md`](../resource-monitor/hardware-report.md) |
| **Ảnh screenfetch** | **THIẾU** | — |
| **Ảnh tool + monitor mỗi lượt** | **1/4** | chỉ `activity-load.png` |

Ngoài yêu cầu: bằng chứng tài nguyên **dạng số** có đầy đủ — `results/resources/*.csv`, lấy mẫu 2
giây/lần cho cả `node` **và** JMeter. Cột JMeter là chỗ phát hiện nút cổ chai nằm ở load generator.

### Hai batch đang giữ, và vì sao

| Batch | Vai trò |
|---|---|
| **15/08** (4 lượt) | **Bộ số liệu chính** của báo cáo |
| 13/08 (4 lượt) | Giữ để so sánh ở §2.8 — nơi việc so hai batch đã **bác bỏ** một kết luận của chính báo cáo |

Batch 14/08 đã xoá (đã bị 15/08 thay thế). `run-log.md` chỉ còn 2 batch, `npm run summary` lấy lượt
mới nhất mỗi scenario nên số liệu khớp báo cáo.

### Việc còn lại

- [ ] `npm run capture` — chạy 4 lượt liền, chụp 5 ảnh khi script beep. Vừa được ảnh khớp timestamp, vừa dọn chuyện 3 batch
- [ ] Sau đó: `npm run summary && npm run drift`, rồi báo tôi cập nhật số trong báo cáo
- [ ] Ảnh screenfetch: chạy `screenfetch` trong Terminal, `Cmd+Shift+4` chụp **đúng cửa sổ đó** → `resource-monitor/screenshots/hardware-spec.png`
- [ ] Kiểm mắt từng ảnh trước khi commit: chỉ có JMeter/terminal + Activity Monitor trong khung, **không** có cửa sổ project khác

> Ba lần tôi tự chụp đều lọt nội dung riêng tư (VS Code project khác, Mission Control, một app CRM
> có số điện thoại khách). Đó là lý do phần này chuyển sang bạn chụp — bạn thấy màn hình, tôi không.

---

## Ý 7 — Determine the endurance threshold

> *"Run a short endurance / soak test (around 10–15 minutes at sustained load) to empirically find
> your hardware's threshold, reported with concrete numbers (e.g., maximum stable RPS, memory
> ceiling)."*

### Đã làm

Chi tiết: [`endurance/endurance-threshold.md`](../endurance/endurance-threshold.md)

| Chỉ số | Giá trị |
|---|---|
| Thời lượng | **719,6s** (12 phút) · 45.220 sample |
| **Max stable RPS** | **62,8 req/s** |
| p95 | **6 ms** · p99 11 ms |
| Trôi p95 (5 phút đầu → cuối) | **+0%** |
| RSS `node` đầu → cuối | 19,3 → 29,0 MB |
| **Trần bộ nhớ** | **83,5 MB** |
| CPU `node` đỉnh | 22,1% |

Điểm mạnh khi review: **định nghĩa "ổn định" được chốt TRƯỚC khi chạy** (error < 1% và p95 không
tăng quá 20%), nên không thể chọn ngưỡng sau khi thấy kết quả.

Điểm trung thực đáng giữ: mục 6 nói rõ 62,8 RPS **không** phải năng lực tối đa — `node` CPU lúc đó
mới 22,1%, còn ở lượt Stress cùng backend chịu 564 req/s với CPU 98,4%. Và mục đó cũng ghi rằng con số
này chỉ có nghĩa **kèm điều kiện `load_1m` ≈ 3,8**, sau bài học §2.8.

### Tự kiểm

```bash
npm run drift        # in lại bảng p95 theo từng phút + kiểm định nghĩa ổn định
```

- [ ] Đọc bảng 12 phút, tự thấy throughput ổn định 65–66 RPS từ phút 2
- [ ] Đọc mục 5 (rò rỉ bộ nhớ) và mục 6 (ngưỡng này nghĩa là gì) — đồng ý với lập luận

---

## Ý 8 — Record a demo video

> *"An unlisted YouTube video of at least 6 minutes total… showing the tool and the resource
> monitor in the same frame, with your own Vietnamese narration."*

**Chưa làm.** Kịch bản 3 clip đã chia timeline: [`docs/kich-ban-video-demo.md`](kich-ban-video-demo.md).

- [ ] Quay ≥6 phút, unlisted, giọng mình
- [ ] JMeter/terminal và Activity Monitor **trong cùng khung**
- [ ] Mở đầu bằng `whoami` + `hostname` (cách HW04 dùng để xác thực tác giả)
- [ ] Kể **một chỗ AI làm sai mà mình sửa** — có 10 chỗ để chọn
- [ ] Dán link vào `README.md` và `report/main-report.md`

> Chuyện đáng kể nhất: mở hai bảng số 13/08 và 14/08 cạnh nhau, giải thích vì sao **cùng một test
> plan** cho p95 chênh **2,7 lần** — và vì sao điều đó chứng minh mô hình CI ở Task 3 có lỗ hổng.

---

## Ý 9 — Report issues

> *"Log any genuine bugs or performance issues… on your GitHub Issues page with screenshots."*

### Đã làm — nội dung xong, chưa mở Issue

| # | Bug | Trạng thái |
|---|---|---|
| BUG-P1 | `GET /api/orders/:id` **không kiểm token** → đọc được đơn của bất kỳ ai. Route bên cạnh (`/api/orders/my-orders`) vẫn trả 401 → là route **bị bỏ sót** | Xác nhận bằng request thật |
| BUG-P2 | `POST /api/coupon-usage` tồn tại, ghi thật vào DB, **không có trong `api_specification.md`** | Xác nhận |
| — | *"`import-products` báo sai số dòng insert"* | **BỊ BÁC BỎ** — 5/5, 60/60, 2/3 đều đúng. Giữ ở mục "đã loại" kèm bảng kiểm chứng |

Vấn đề hiệu năng: 0% error ở cả 4 lượt, nhưng **có** một suy giảm đo được — §2.8, dữ liệu phình 8
lần làm hệ thống xấu đi 2,4–6,4 lần dưới tải cao.

### Việc còn lại

```bash
bash bug-report/verify-bugs.sh     # chạy lại toàn bộ bằng chứng, chụp màn hình lúc này
```

- [ ] Chụp ảnh → `bug-report/screenshots/bug-p1-orders-idor.png`, `bug-p2-coupon-usage.png`
- [ ] Mở 2 Issue (lệnh `gh issue create` có sẵn ở [`bug-report/bug-report.md`](../bug-report/bug-report.md) mục 4)
- [ ] Điền số Issue vào bảng mục 1 của bug report

---

## Soát tổng trước khi nộp

```bash
bash tools/package.sh 95 --check    # liệt kê chính xác còn thiếu gì theo §14
```

Lần chạy gần nhất: **thiếu 6 mục** — 3 ảnh activity, ảnh screenfetch, ảnh bug, link video, số
Issue, Human review trong AI Audit.
