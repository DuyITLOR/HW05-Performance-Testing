# HW05 — Performance Testing on EShop

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178
- **Môn:** Kiểm thử phần mềm (QA/QC) — **Bài:** HW05-AI Performance Testing

> **Trạng thái:** Task 1, 2, 3 đã hoàn tất — 4 lượt chạy JMeter (**364.011 sample**, 0% error),
> endurance threshold đã chốt bằng số, 2 bug chức năng xác nhận bằng request thật, 10 lỗi của AI
> ghi đầy đủ. **Còn thiếu:** ảnh Activity Monitor, video demo, GitHub Issues — xem [§9](#9-việc-còn-lại).
> Quy trình làm bài: [docs/PLAYBOOK.md](docs/PLAYBOOK.md) (trong repo, không kèm bản nộp).

## Liên kết

| | |
|---|---|
| **Repo bài làm (HW05)** | https://github.com/DuyITLOR/HW05-Performance-Testing |
| **SUT (hệ thống được kiểm thử)** | https://github.com/ttbhanh/eshop-sut |
| **GitHub Issues** | *(chờ mở — xem §9)* |
| **Video demo (≥6 phút, unlisted)** | *(chờ quay — kịch bản: [docs/kich-ban-video-demo.md](docs/kich-ban-video-demo.md))* |
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
| 1 | `POST /api/login` (admin) | **auth-heavy** | **40 ms** ← đắt nhất |
| 2 | `GET /api/admin/orders` | **read-heavy** | 23 ms |
| 3 | `GET /api/admin/users` | **read-heavy** | 19 ms |
| 4 | `POST /api/admin/import-products` | **transactional** | **34 ms** |
| 5 | `PUT /api/admin/orders/:id/status` | **transactional** | 19 ms |
| 6 | `POST /api/login` (mật khẩu sai) | **auth-heavy** | 4 ms — nhánh phủ account-lockout |

Cả 4 test plan (Load / Stress / Spike / Soak) chạy **cùng** workflow này, chỉ khác tham số tải —
đúng yêu cầu §6. Sinh từ một định nghĩa duy nhất: `npm run plans`.

---

## 2. Test Summary Report (§14)

> Bảng dưới **sinh tự động** bằng `npm run summary` từ raw `.jtl`. Đừng sửa tay.

| Chỉ số | Giá trị |
|---|---|
| Scenario đã chạy | **4** — Load · Stress · Spike · Soak (endurance) |
| Endpoint group được phủ | **3** — auth-heavy · read-heavy · transactional |
| Tổng sample | **364.011** |
| Error rate | **0%** ở cả 4 lượt |
| **Endurance threshold** | **63,0 req/s** ổn định 12 phút · p95 **6 ms** · trần bộ nhớ **83,1 MB** |
| Tải cao nhất chịu được | **550,5 req/s** ở 200 VU, p95 26 ms, 0% error — **chưa chạm điểm gãy** |
| Thời gian hồi phục sau spike | **< 20 giây**, hồi phục ngay trong lúc vẫn chịu 212 VU |
| Bug chức năng | **2** xác nhận (+1 ứng viên đã loại sau khi kiểm) |
| Vấn đề hiệu năng | **0** — kèm lý do vì sao phép đo chưa chạm giới hạn |
| Lỗi của AI đã bắt và sửa | **10** (7 trong số đó không làm test plan báo lỗi) |

### Bốn lượt chạy

| Scenario | Sample | Peak VU | Thời lượng | RPS | Error % | avg | p50 | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Load** | 16.436 | 22 | 359,5s | 45,7 | 0% | 3 | 2 | 5 | **7** | 14 | 167 |
| **Stress** | 264.141 | 200 | 479,8s | **550,5** | 0% | 6,9 | 2 | 11 | **26** | 93 | 716 |
| **Spike** | 38.069 | 212 | 239,6s | 158,9 | 0% | 4,3 | 2 | 5 | **9** | 55 | 369 |
| **Soak** | 45.365 | 22 | 719,6s | 63,0 | 0% | 2,7 | 2 | 5 | **6** | 13 | 160 |

Đơn vị: **ms**. Mốc thời gian từng lượt: [results/run-log.md](results/run-log.md) ·
[endurance/run-log.md](endurance/run-log.md).

> **Phát hiện chính:** Stress **không tìm được điểm gãy**. Không phải vì SUT mạnh — mà vì
> **load generator chạm giới hạn trước**: JMeter tiêu CPU đỉnh **158%** và 770 MB RAM ở 200 VU,
> trong khi `node` chỉ đỉnh **79%** (đo ở lượt Spike, 212 VU). Đọc "0% error ở 550 RPS" thành
> "backend còn dư sức" là sai — nó chỉ có nghĩa JMeter không đẩy nổi cao hơn.
> Phân tích đầy đủ: [report/main-report.md §3.2](report/main-report.md).

---

## 3. Bảng tự đánh giá (Self-Assessment)

> Đuôi tên file zip = tổng điểm tự chấm → `23127178_HW05_AI_Performance_<điểm>.zip`.
> **Cột điểm để trống — sinh viên tự quyết.** Cột căn cứ đã điền sẵn để đối chiếu.

| No. | Tiêu chí | Điểm tối đa | Điểm tự chấm | Căn cứ |
|-----|----------|-------------|--------------|--------|
| 1 | Task 1 — Load testing | 20 | | 16.436 sample · 20 VU · think-time 1–3s/iteration bằng Uniform Random Timer · p95 7ms, 0% error · data-driven từ 4 file CSV · listener **Summary Report** (không lặp loại) · p95 tách theo từng endpoint, không chỉ số tổng |
| 2 | Task 1 — Stress testing | 20 | | 264.141 sample · tăng **theo bậc** 25→50→100→200 VU để tìm *điểm* gãy chứ không chỉ biết có gãy · 550,5 RPS · listener **Aggregate Report** · **kết luận trung thực rằng chưa tìm được điểm gãy**, kèm bằng chứng số (JMeter CPU 158% vs node 79%) thay vì kết luận "SUT chịu tải tốt" |
| 3 | Task 1 — Spike testing | 20 | | 38.069 sample · 10 VU nền + 200 VU trong 5s, có nhánh nền chạy xuyên lượt để **đo được hồi phục** · listener **View Results Tree** · bảng p95 theo cửa sổ 10s cho thấy 5→47→10→6ms: hồi phục < 20s **ngay trong lúc vẫn chịu 212 VU**, tức 47ms là chi phí khởi tạo thread + login đồng thời, không phải server nghẽn |
| 4 | Task 2 — AI analysis + misinterpretation hunt | 10 | | **6 lỗi đọc metric** của AI, mỗi lỗi kèm giá trị đúng **và tên file `.jtl`**: nhầm giới hạn load generator thành giới hạn backend · dùng average khi p99 gấp 13 lần avg · dùng p95 tổng khi endpoint đắt nhất cao gấp 1,54 lần · đọc "0% error" thành "mọi request thành công" trong khi 99,2% bước 5 trả 400 · kết luận đúng vì lý do sai ở phần rò rỉ bộ nhớ · 6 đề xuất tối ưu phân loại feasible/hallucinated kèm **cách kiểm chứng**, và 1 đề xuất **AI không nêu mà tôi bổ sung** (phân trang) |
| 5 | Task 3 — Continuous Performance Testing (G9.6) | 10 | | Flow chart mermaid 11 nút · giải thích **từng** nhánh quyết định · 5 trade-off, mỗi cái nói rõ **cái phải trả** (chỉ Load tự động hoá được; hồi quy 10–15% sẽ lọt; baseline phải chạy 2 lần mỗi lượt CI) · liên kết ngược về số liệu thật của bài (§2.3, §3.2) thay vì lập luận chung |
| 6 | Agent Skills | 10 | | 4 skill trong `.claude/skills/`, **dùng thật trong bài**: `perf-test-plan` (7 bước, checklist duyệt 8 mục), `jtl-analysis` (bảng 6 lỗi đọc metric + phân loại feasible/hallucinated), `resource-evidence` (định dạng bằng chứng §6/§11), `ai-audit-logger` (§9 + 3 trường riêng HW05). **Chờ video demo skill.** |
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
report/ ai-audit/ bug-report/ git-log/ docs/
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
| 4 raw `.jtl` đầy đủ + 4 HTML dashboard | **Đạt** — 364.011 sample |
| [endurance/endurance-threshold.md](endurance/endurance-threshold.md) | **Đạt** — 63,0 RPS · p95 6ms · trần 83,1 MB · trôi −14,3% |
| [resource-monitor/hardware-report.md](resource-monitor/hardware-report.md) | **Đạt** — hostname `Le-Nhut-Duy.local` khớp HW trước |
| Ảnh Activity Monitor (JMeter + monitor **cùng khung**) | **Thiếu** → `npm run capture` |
| Ảnh spec phần cứng | **Thiếu** |
| Video demo ≥6 phút, unlisted, tiếng Việt | **Thiếu** |
| GitHub Issues cho 2 bug | **Thiếu** → lệnh có sẵn trong bug-report §4 |
| Task 3 — flow chart + trade-off | **Đạt** — main-report §4 |
| [git-log/commit-log.txt](git-log/) | Xuất bằng `bash tools/commit-plan.sh log` |

## 9. Việc còn lại

1. **`npm run capture`** — chạy lại 4 lượt, script đếm tới đúng giây cần chụp. Ảnh phải có JMeter
   **và** Activity Monitor trong **cùng khung hình** (§6), và timestamp khớp `run-log.md` (§11).
   Sau khi chạy lại: `npm run summary` rồi cập nhật các bảng số trong README và main-report.
2. **Ảnh spec máy** → `resource-monitor/screenshots/hardware-spec.png`.
3. **Video ≥6 phút**, unlisted, giọng mình — kịch bản 3 clip đã chia timeline trong
   [docs/kich-ban-video-demo.md](docs/kich-ban-video-demo.md). Nhớ kể **một chỗ AI làm sai mà mình
   sửa**: có 10 chỗ để chọn.
4. **2 GitHub Issue** cho BUG-P1/P2 — lệnh `gh issue create` có sẵn trong bug-report §4.
5. **Điền phần "Human review"** trong AI Audit — mọi chỗ ghi *(sinh viên bổ sung)*.
6. **Chấm điểm tự đánh giá** ở §3 → đuôi tên file zip.

## 10. Bốn điều quyết định cách đọc mọi con số của bài này

1. **Load generator và SUT cùng một máy.** JMeter tiêu CPU đỉnh 158% ở 200 VU. Đây là lý do trực
   tiếp khiến Stress không tìm được điểm gãy.
2. **Mật khẩu lưu plaintext** ([`server.js:46`](../eshop-sut/backend/server.js#L46)) — login không
   tốn CPU băm, nên p95 40ms của nó **không** đại diện cho hệ thống băm mật khẩu đúng cách.
3. **Lockout kích hoạt sau 2 lần sai, không phải 3** (`login_attempts + 2`, ngưỡng 3 —
   [`server.js:54`](../eshop-sut/backend/server.js#L54)). Mọi `403` đo được là **hành vi chức
   năng**, không phải server quá tải.
4. **Bước 5 chỉ ghi thật 400 lần mỗi lượt** (bằng số dòng `orders.csv`); phần còn lại trả 400 do
   state machine FR-10 — hợp lệ, nhưng nhẹ hơn nhánh ghi. Tín hiệu ghi nặng nằm ở bước 4.
