# HW05 — Performance Testing on EShop

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178
- **Môn:** Kiểm thử phần mềm (QA/QC) — **Bài:** HW05-AI Performance Testing

> **Trạng thái:** Task 1, 2, 3 hoàn tất — 4 lượt JMeter (**350.670 sample**, 0% error),
> endurance threshold chốt bằng số, 2 bug xác nhận bằng request
> thật, 10 lỗi của AI ghi đầy đủ, và một **phát hiện hiệu năng thật** (§2.8 của báo cáo: dữ liệu
> phình 8 lần làm hệ thống xấu đi 2,4–6,4 lần **nhưng chỉ dưới tải cao**).
> **Còn thiếu:** ảnh Activity Monitor, ảnh spec máy, video demo, GitHub Issues — xem [§9](#9-việc-còn-lại).
> Quy trình làm bài: [docs/PLAYBOOK.md](docs/PLAYBOOK.md) (trong repo, không kèm bản nộp).

## Liên kết

| | |
|---|---|
| **Repo bài làm (HW05)** | https://github.com/DuyITLOR/HW05-Performance-Testing |
| **SUT (hệ thống được kiểm thử)** | https://github.com/ttbhanh/eshop-sut |
| **GitHub Issues** | *(chờ mở — xem §9)* |
| **Video demo (≥6 phút, unlisted)** | *(chờ quay — kịch bản: [docs/kich-ban-video-demo.md](docs/kich-ban-video-demo.md))* |
| **Bản đồ yêu cầu → file** | [TASKS.md](TASKS.md) — từng yêu cầu Task 1/2/3 nằm ở đâu |
| **Báo cáo chính** | [report/main-report.md](report/main-report.md) |
| **Test summary sinh tự động** | [results/summary.md](results/summary.md) |
| **Endurance threshold** | [endurance/endurance-threshold.md](endurance/endurance-threshold.md) |
| **AI Audit (10 lỗi) + Critique** | [ai-audit/](ai-audit/) |
| **Bug report** | [bug-report/bug-report.md](bug-report/bug-report.md) |

---

## 1. Phạm vi — ba endpoint group (§5)

Một workflow end-to-end **admin back-office**, phủ đủ 3 nhóm, không trùng thành viên nào trong
nhóm 05. Bằng chứng chống trùng: [docs/endpoint-selection.md](docs/endpoint-selection.md).

| Bước | Endpoint | Nhóm §5 | p95 ở Stress (200 VU) |
|---|---|---|---|
| 1 | `POST /api/login` (admin) | **auth-heavy** | **107 ms** ← đắt nhất |
| 2 | `GET /api/admin/orders` | **read-heavy** | 55 ms |
| 3 | `GET /api/admin/users` | **read-heavy** | 49 ms |
| 4 | `POST /api/admin/import-products` | **transactional** | **82 ms** |
| 5 | `PUT /api/admin/orders/:id/status` | **transactional** | 53 ms |
| 6 | `POST /api/login` (mật khẩu sai) | **auth-heavy** | 5 ms — nhánh phủ account-lockout |

Cả 4 test plan (Load / Stress / Spike / Soak) chạy **cùng** workflow này, chỉ khác tham số tải —
đúng yêu cầu §6. Sinh từ một định nghĩa duy nhất: `npm run plans`.

---

## 2. Test Summary Report (§14)

> Bảng dưới **sinh tự động** bằng `npm run summary` từ raw `.jtl`. Đừng sửa tay.

| Chỉ số | Giá trị |
|---|---|
| Scenario đã chạy | **4** — Load · Stress · Spike · Soak (endurance) |
| Endpoint group được phủ | **3** — auth-heavy · read-heavy · transactional |
| Tổng sample | **350.670** |
| Error rate | **0%** ở cả 4 lượt |
| Kích thước dữ liệu khi đo | `products` **436.692 dòng** · SQLite **33 MB** |
| **Endurance threshold** | **62,9 req/s** ổn định 12 phút · p95 **6 ms** · trôi p95 **+0%** · trần bộ nhớ **80,8 MB** |
| Tải cao nhất chịu được | **524,8 req/s** ở 200 VU, p95 70 ms, 0% error — nhưng `node` CPU đỉnh **108%**, đã vào vùng bão hoà |
| Thời gian hồi phục sau spike | **< 10 giây** sau khi tải rút; **không** hồi phục trong lúc còn chịu 212 VU |
| Bug chức năng | **2** xác nhận (+1 ứng viên đã loại sau khi kiểm) |
| **Phát hiện hiệu năng** | dữ liệu phình 8 lần → xấu đi **2,4–6,4 lần** ở tải cao, **0×** ở tải kỳ vọng |
| Lỗi của AI đã bắt và sửa | **10** (7 trong số đó không làm test plan báo lỗi) |

### Bốn lượt chạy

| Scenario | Sample | Peak VU | Thời lượng | RPS | Error % | avg | p50 | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Load** | 16.436 | 22 | 359,4s | 45,7 | 0% | 2,6 | 2 | 5 | **6** | 14 | 234 |
| **Stress** | 251.820 | 200 | 479,9s | **524,8** | 0% | 14,6 | 3 | 32 | **70** | 210 | **1058** |
| **Spike** | 37.126 | 212 | 239,7s | 154,9 | 0% | 8,7 | 3 | 15 | **44** | 120 | 282 |
| **Soak** | 45.288 | 22 | 719,7s | 62,9 | 0% | 3,0 | 2 | 5 | **6** | 16 | 365 |

Đơn vị: **ms**. Mốc thời gian từng lượt: [results/run-log.md](results/run-log.md) ·
[endurance/run-log.md](endurance/run-log.md).

> **Phát hiện chính (§2.8 của báo cáo):** hai bộ lượt chạy tồn tại — cùng test plan, cùng máy,
> nhưng bảng `products` khác nhau **8 lần**. So sánh cho ra điều quan trọng nhất của bài:
>
> | | Load 20 VU | Stress 200 VU | Spike 212 VU |
> |---|---|---|---|
> | p95 login | 5 → 4 ms · **0,80×** | 40 → 107 ms · **2,67×** | 10 → 64 ms · **6,40×** |
> | p95 admin/users | 5 → 4 ms · 0,80× | 19 → 49 ms · **2,58×** | 7 → 31 ms · **4,43×** |
>
> **Hồi quy do dữ liệu phình hoàn toàn vô hình ở tải kỳ vọng, chỉ lộ ra dưới tải cao.** Cơ chế:
> SQLite chỉ có **một writer**, nên INSERT chậm hơn tạo hàng đợi mà cả hai endpoint **chỉ đọc**
> cũng phải xếp sau. Ở 20 VU hàng đợi kịp rỗng; ở 200 VU thì không.
>
> Hệ quả: mô hình CI ở Task 3 chạy Load 3 phút **sẽ không bắt được loại hồi quy này** — một lỗ
> hổng trong chính đề xuất của tôi, và đã được bù bằng nhánh Stress theo lịch trên snapshot DB
> production. Phân tích đầy đủ: [report/main-report.md §2.8](report/main-report.md).

---

## 3. Bảng tự đánh giá (Self-Assessment)

> Đuôi tên file zip = tổng điểm tự chấm → `23127178_HW05_AI_Performance_<điểm>.zip`.
> **Cột điểm để trống — sinh viên tự quyết.** Cột căn cứ đã điền sẵn để đối chiếu.

| No. | Tiêu chí | Điểm tối đa | Điểm tự chấm | Căn cứ |
|-----|----------|-------------|--------------|--------|
| 1 | Task 1 — Load testing | 20 | | 16.436 sample · 20 VU · think-time 1–3s/iteration bằng Uniform Random Timer · p95 **6ms**, 0% error · data-driven từ 4 file CSV · listener **Summary Report** (không lặp loại) · p95 tách theo từng endpoint |
| 2 | Task 1 — Stress testing | 20 | | **251.820 sample** · tăng **theo bậc** 25→50→100→200 VU để tìm *điểm* gãy chứ không chỉ biết có gãy · **524,8 RPS** · listener **Aggregate Report** · không kết luận "SUT chịu tải tốt" từ 0% error mà chỉ ra p95 tăng **11,7 lần** cho 10 lần số VU và `node` CPU đỉnh **108%** — đã vào vùng bão hoà |
| 3 | Task 1 — Spike testing | 20 | | 37.126 sample · 10 VU nền + 200 VU trong 5s, có nhánh nền chạy xuyên lượt để **đo được hồi phục** · listener **View Results Tree** · bảng p95 theo cửa sổ 10s: 5 → 65 → 59 → 46 → 6ms, tức **không** hồi phục trong lúc còn tải, chỉ hồi phục < 10s sau khi tải rút · **so được với lượt DB nhỏ** (ở đó server hấp thụ được cú sốc ngay trong lúc chịu tải) → chứng minh spike test trên DB mới seed cho kết luận sai |
| 4 | Task 2 — AI analysis + misinterpretation hunt | 10 | | **7 lỗi đọc metric**, mỗi lỗi kèm giá trị đúng **và tên file `.jtl`**: "không suy giảm" trong khi p95 tăng 11,7 lần · average 14,6ms khi p99 gấp **14,4 lần** và max gấp **72 lần** · p95 tổng 70ms khi login ở 107ms · "0% error" trong khi 99,2% bước 5 trả 400 · kết luận đúng vì lý do sai ở rò rỉ bộ nhớ · **ngưỡng do chính AI đề xuất (p95<100ms) đã bị vi phạm bởi số liệu nó vừa đọc** · và lỗi nặng nhất: kết luận "không cần tối ưu" từ một lát cắt duy nhất, bỏ qua §2.8. 6 đề xuất phân loại feasible/hallucinated kèm **cách kiểm chứng**, + **2 đề xuất AI không nêu mà tôi bổ sung** |
| 5 | Task 3 — Continuous Performance Testing (G9.6) | 10 | | Flow chart mermaid **15 nút** · giải thích **từng** nhánh · **6 trade-off**, mỗi cái nói rõ cái phải trả · **tự chỉ ra một lỗ hổng trong chính đề xuất của mình bằng số đo**: §2.8 chứng minh lượt Load 3 phút trong CI sẽ không bắt được hồi quy do dữ liệu phình, nên phải thêm nhánh Stress theo lịch trên snapshot DB production · và trade-off cuối: **perf test tự làm hỏng điều kiện đo của nó** (bộ test này đẩy `products` từ 50k lên 436k dòng) |
| 6 | Agent Skills | 10 | | 4 skill trong `.claude/skills/`, **dùng thật trong bài**: `perf-test-plan` (7 bước, checklist duyệt 8 mục), `jtl-analysis` (bảng lỗi đọc metric + phân loại feasible/hallucinated), `resource-evidence` (định dạng bằng chứng §6/§11), `ai-audit-logger` (§9 + 3 trường riêng HW05). **Chờ video demo skill.** |
| | **Tổng** | **100** | | |

---

## 4. Cách chạy

```bash
# 1. Khởi động SUT (dùng chung cho mọi HW, ở ../eshop-sut/)
cd ~/Documents/HK3_Nam3/kiem_thu && ./eshop.sh --seed      # backend :3000
cd HW05-Performance-Testing

# 2. Cài công cụ (lần đầu)
brew install jmeter k6

# 3. Kiểm môi trường + sinh dữ liệu + sinh test plan
npm run preflight          # tool · SUT · 6 endpoint của workflow · CSV
npm run seed:perf -- --users 50 --orders 400    # → data/*.csv
npm run plans              # → 4 file .jmx từ một workflow dùng chung

# 4. Chạy — CÓ hướng dẫn chụp ảnh đúng mốc
npm run capture            # 4 lượt, script đếm tới giây cần chụp từng lượt
npm run capture -- --auto  # tự chụp bằng screencapture (cần quyền Screen Recording)
npm run capture -- --list  # chỉ xem mốc chụp rồi thoát

# hoặc chạy không cần ảnh:
bash tools/run-all.sh --with-soak

# 5. Số liệu và bằng chứng
npm run summary            # → results/summary.md  (nguồn DUY NHẤT của mọi con số)
npm run drift              # → p95 theo từng phút + endurance threshold
npm run hardware           # → resource-monitor/hardware-report.md
bash bug-report/verify-bugs.sh    # chạy lại toàn bộ bằng chứng bug
bash tools/build-pdfs.sh   # xuất PDF cho 4 tài liệu §14

# 6. Đóng gói nộp bài
bash tools/package.sh 95 --check    # soát đủ/thiếu theo §14, không tạo gói
bash tools/package.sh 95            # → 23127178_HW05_AI_Performance_095.zip
```

> **Java:** máy này mặc định `java` = Temurin 8 **x86_64** → JMeter chạy qua Rosetta và chính
> load generator thành điểm nghẽn. `tools/run-scenario.sh` tự ép `JAVA_HOME` sang JDK arm64.
> **Đừng gọi `jmeter` tay** cho các lượt lấy số liệu.

---

## 5. Cấu trúc repo

```
test-plans/          4 test plan .jmx — {MSSV}_{Scenario}_{YYYYMMDD} (§6, §11 kiểm tên)
data/                4 file CSV data-driven (§6)
results/
├── jtl/             raw .jtl ĐẦY ĐỦ (§11) — Load · Stress · Spike
├── html/<scenario>/ HTML dashboard từng lượt
├── resources/       mẫu CPU/RSS 2 giây/lần của node và JMeter
├── run-log.md       mốc UTC từng lượt, để đối chiếu ảnh monitor (§11)
└── summary.md       sinh tự động từ raw .jtl — nguồn duy nhất của mọi con số
endurance/           lượt soak 12 phút + endurance-threshold.md (§6)
resource-monitor/    hardware-report.md (spec + hostname) + screenshots/
k6/                  bản mirror k6 (bonus §8) — cùng workflow, để đối chiếu chéo
tools/               13 script — xem §6
TASKS.md             bản đồ: từng yêu cầu của đề → file + section
report/ ai-audit/ bug-report/ git-log/
docs/                endpoint-selection.md NỘP KÈM (bằng chứng §5) · PLAYBOOK + kịch bản video KHÔNG nộp
.claude/skills/      4 Agent Skill (§7)
```

## 6. Tooling

| Script | Việc |
|---|---|
| `preflight.mjs` | kiểm tool + SUT + 6 endpoint + CSV trước khi chạy |
| `gen-test-plans.py` | sinh 4 `.jmx` từ **một** định nghĩa workflow (§6 đòi cùng workflow) |
| `seed-perf-data.mjs` | 50 tài khoản + 400 order + 4 file CSV |
| `reset-lockout.mjs` · `reset-orders.mjs` | reset lockout và state machine giữa các lượt (§6 đòi ghi lại) |
| `run-scenario.sh` | 1 lượt: ép JAVA_HOME arm64 · reset · `.jtl` + dashboard + run-log + mẫu tài nguyên |
| `run-all.sh` | 3–4 lượt tuần tự + cooldown 90s |
| **`capture-run.sh`** | chạy + **đếm tới đúng giây cần chụp ảnh** từng lượt |
| `sample-resources.sh` | mẫu CPU/RSS của `node` **và** JMeter — cột JMeter là chỗ phát hiện nút cổ chai nằm ở load generator |
| `summarize-jtl.mjs` | raw `.jtl` → `summary.md`: p95 **từng endpoint** + phân rã response code |
| `soak-drift.mjs` | p95 theo từng phút + kiểm định nghĩa "ổn định" + trôi RSS |
| `hardware-report.sh` | bảng spec + hostname (§11 kiểm khớp HW trước) |
| `md2pdf.py` · `build-pdfs.sh` · `commit-plan.sh` | tài liệu và commit theo §12 |

## 7. Agent Skills (§7)

| Skill | Việc |
|---|---|
| [`perf-test-plan`](.claude/skills/perf-test-plan/SKILL.md) | 7 bước thiết kế + duyệt một test plan, kèm checklist 8 mục |
| [`jtl-analysis`](.claude/skills/jtl-analysis/SKILL.md) | phân tích raw `.jtl`, chốt ngưỡng, bắt lỗi AI đọc sai metric (Task 2) |
| [`resource-evidence`](.claude/skills/resource-evidence/SKILL.md) | thu bằng chứng đúng chuẩn §6/§11 |
| [`ai-audit-logger`](.claude/skills/ai-audit-logger/SKILL.md) | ghi AI Audit Report (§9) + 3 trường riêng HW05 |

## 8. Tài liệu bắt buộc (§14) — checklist

| File | Trạng thái |
|---|---|
| [report/main-report.md](report/main-report.md) + PDF | **Đạt** — số liệu 4 lượt, human review 10 lỗi, Task 2 (6 lỗi đọc metric), Task 3, 4 giới hạn |
| [ai-audit/ai-audit-report.md](ai-audit/ai-audit-report.md) + PDF | **Đạt** — 8 lượt tương tác, prompt nguyên văn, bảng tổng hợp 10 lỗi |
| [ai-audit/ai-critique.md](ai-audit/ai-critique.md) + PDF | **Đạt** — **298 từ** (yêu cầu 200–300), trả lời đủ 3 câu §10 |
| [bug-report/bug-report.md](bug-report/bug-report.md) | **Đạt** — 2 bug xác nhận + 1 ứng viên đã loại kèm bảng kiểm chứng + `verify-bugs.sh` chạy lại được |
| 4 test plan `.jmx` đúng tên `{MSSV}_{Scenario}_{YYYYMMDD}` | **Đạt** |
| 4 raw `.jtl` đầy đủ + 4 HTML dashboard | **Đạt** — 350.670 sample (+ 4 lượt DB nhỏ giữ lại cho §2.8) |
| [endurance/endurance-threshold.md](endurance/endurance-threshold.md) | **Đạt** — 62,9 RPS · p95 6ms · trần 80,8 MB · trôi **+0%** |
| [resource-monitor/hardware-report.md](resource-monitor/hardware-report.md) | **Đạt** — hostname `Le-Nhut-Duy.local` khớp HW trước |
| Ảnh Activity Monitor (JMeter + monitor **cùng khung**) | **Thiếu** — xem §9 |
| Ảnh spec phần cứng | **Thiếu** |
| Video demo ≥6 phút, unlisted, tiếng Việt | **Thiếu** |
| GitHub Issues cho 2 bug | **Thiếu** → lệnh có sẵn trong bug-report §4 |
| Task 3 — flow chart + trade-off | **Đạt** — main-report §4 |
| [git-log/commit-log.txt](git-log/) | Xuất bằng `bash tools/commit-plan.sh log` |

## 9. Việc còn lại

1. **Ảnh Activity Monitor cho 4 lượt + ảnh spec máy.** Lần chụp đầu đã bị **xoá bỏ**: `screencapture`
   chụp toàn màn hình nên bắt được cửa sổ đang ở trước (VS Code của project khác, Mission Control)
   chứ không phải JMeter + Activity Monitor — vô giá trị làm bằng chứng §6, và làm lộ nội dung
   không liên quan. Cách chụp đúng: giới hạn vùng chụp theo đúng hai cửa sổ cần thiết
   (`screencapture -R`), và **phải chụp trong lúc lượt chạy đang diễn ra** nên cần chạy lại 4 lượt.
2. **Video ≥6 phút**, unlisted, giọng mình — kịch bản 3 clip đã chia timeline trong
   [docs/kich-ban-video-demo.md](docs/kich-ban-video-demo.md). Nhớ kể **một chỗ AI làm sai mà mình
   sửa**: có 10 chỗ để chọn.
3. **2 GitHub Issue** cho BUG-P1/P2 — lệnh `gh issue create` có sẵn trong bug-report §4.
4. **Điền phần "Human review"** trong AI Audit — mọi chỗ ghi *(sinh viên bổ sung)*.
5. **Chấm điểm tự đánh giá** ở §3 → đuôi tên file zip.

## 10. Năm điều quyết định cách đọc mọi con số của bài này

1. **Kích thước dữ liệu không được kiểm soát giữa các lượt** — biến số **lớn nhất** của bài,
   xem §2.8 của báo cáo. Bộ số liệu này đo trên 436.692 dòng `products`; mọi so sánh với lượt khác
   phải khai kèm kích thước DB.
2. **Load generator và SUT cùng một máy.** Ở Stress, JMeter CPU đỉnh 118% và `node` 108% — xấp xỉ
   nhau, nên một phần latency đo được vẫn là chi phí của load generator.
3. **Mật khẩu lưu plaintext** ([`server.js:46`](../eshop-sut/backend/server.js#L46)) — login không
   tốn CPU băm, nên p95 107ms của nó **không** đại diện cho hệ thống băm mật khẩu đúng cách.
4. **Lockout kích hoạt sau 2 lần sai, không phải 3** (`login_attempts + 2`, ngưỡng 3 —
   [`server.js:54`](../eshop-sut/backend/server.js#L54)). Mọi `403` đo được là **hành vi chức
   năng**, không phải server quá tải.
5. **Bước 5 chỉ ghi thật 400 lần mỗi lượt** (bằng số dòng `orders.csv`); phần còn lại trả 400 do
   state machine FR-10 — hợp lệ, nhưng nhẹ hơn nhánh ghi. Tín hiệu ghi nặng nằm ở bước 4.
