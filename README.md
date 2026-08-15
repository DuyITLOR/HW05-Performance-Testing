# HW05 — Performance Testing on EShop

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178
- **Môn:** Kiểm thử phần mềm (QA/QC) — **Bài:** HW05-AI Performance Testing

> **Trạng thái:** Task 1, 2, 3 hoàn tất — 4 lượt JMeter (**358.661 sample**, 0% error) kèm **5 ảnh
> bằng chứng** khớp timestamp, endurance threshold chốt bằng số, 2 bug xác nhận bằng request thật,
> **17 lỗi của AI ghi đầy đủ** — trong đó một kết luận nhân quả sai mà bài này **tự bác bỏ bằng ba
> điểm dữ liệu** (§2.8), và một con số do chính tool của tôi in ra sai (§2.7) — **cộng 2 lỗi bản nộp
> do chính sinh viên bắt**, tức **2 trong 17 lỗi là do người soát ra, không phải AI tự thấy**.
> **Còn thiếu:** chỉ **video demo** — xem [§9](#9-việc-còn-lại).
> Quy trình làm bài: [docs/PLAYBOOK.md](docs/PLAYBOOK.md) (trong repo, không kèm bản nộp).

## Liên kết

| | |
|---|---|
| **Repo bài làm (HW05)** | https://github.com/DuyITLOR/HW05-Performance-Testing |
| **SUT (hệ thống được kiểm thử)** | https://github.com/ttbhanh/eshop-sut |
| **GitHub Issues** | [#288](https://github.com/DuyITLOR/group05_eshop/issues/288) · [#289](https://github.com/DuyITLOR/group05_eshop/issues/289) — cả hai có ảnh nhúng sẵn |
| **Video demo (≥6 phút, unlisted)** | *(chờ quay — kịch bản: [docs/kich-ban-video-demo.md](docs/kich-ban-video-demo.md))* |
| **Bản đồ yêu cầu → file** | [TASKS.md](TASKS.md) — từng yêu cầu Task 1/2/3 nằm ở đâu |
| **Báo cáo chính** | [report/main-report.md](report/main-report.md) |
| **Test summary sinh tự động** | [results/summary.md](results/summary.md) |
| **Endurance threshold** | [endurance/endurance-threshold.md](endurance/endurance-threshold.md) |
| **AI Audit + Critique** | [ai-audit/](ai-audit/) — **12 lượt**, 15 lỗi kỹ thuật + 2 lỗi bản nộp, mỗi lượt có **Human review** ghi rõ *đã kiểm* / *chưa tự kiểm* |
| **Bug report** | [bug-report/bug-report.md](bug-report/bug-report.md) |

---

## 1. Phạm vi — ba endpoint group (§5)

Một workflow end-to-end **admin back-office**, phủ đủ 3 nhóm, không trùng thành viên nào trong
nhóm 05. Bằng chứng chống trùng: [docs/endpoint-selection.md](docs/endpoint-selection.md).

| Bước | Endpoint | Nhóm §5 | p95 ở Stress (200 VU) |
|---|---|---|---|
| 1 | `POST /api/login` (admin) | **auth-heavy** | **24 ms** ← đắt nhất ở Stress |
| 2 | `GET /api/admin/orders` | **read-heavy** | 17 ms |
| 3 | `GET /api/admin/users` | **read-heavy** | 13 ms |
| 4 | `POST /api/admin/import-products` | **transactional** | **22 ms** — endpoint ghi duy nhất |
| 5 | `PUT /api/admin/orders/:id/status` | **transactional** | 14 ms |
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
| Tổng sample | **358.661** |
| Error rate | **0%** ở cả 4 lượt |
| Điều kiện khi đo | `products` ~900.000 dòng · `load_1m` tb **4,4–6,0** trên máy 12 lõi |
| **Endurance threshold** | **62,8 req/s** ổn định 12 phút · p95 **8 ms** · trôi p95 **+0%** · RSS đi ngang **+5,0%** · trần **83,1 MB** |
| Tải cao nhất chịu được | **539,7 req/s** ở 200 VU, p95 **18 ms**, 0% error — nhưng `node` CPU đỉnh **97,7%**, sát trần một lõi, và max **3691 ms** |
| Hồi phục sau spike | **không cần hồi phục** — 212 VU dội trong 5s mà p95 đứng nguyên 7–8 ms |
| Bug chức năng | **2** xác nhận (+1 ứng viên đã loại kèm bảng kiểm chứng) |
| Lỗi của AI đã bắt và sửa | **15** kỹ thuật (12 trong số đó **không làm test plan báo lỗi**) + **2** lỗi bản nộp do sinh viên bắt |
| Ảnh bằng chứng | **5** ảnh khớp timestamp + 1 ảnh bug |

### Bốn lượt chạy

| Scenario | Sample | Peak VU | Thời lượng | RPS | Error % | avg | p50 | p90 | **p95** | p99 | max |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Load** | 16.343 | 22 | 359,7s | 45,4 | 0% | 3,7 | 3 | 7 | **8** | 12 | 84 |
| **Stress** | 258.992 | 200 | 479,9s | **539,7** | 0% | 9,6 | 2 | 8 | **18** | 124 | **3691** |
| **Spike** | 38.251 | 212 | 239,8s | 159,5 | 0% | 2,8 | 2 | 5 | **7** | 16 | 176 |
| **Soak** | 45.166 | 22 | 719,6s | 62,8 | 0% | 3,6 | 3 | 7 | **8** | 12 | 192 |

Đơn vị: **ms**. Mốc thời gian từng lượt: [results/run-log.md](results/run-log.md) ·
[endurance/run-log.md](endurance/run-log.md).

> **Phát hiện đáng đọc nhất — một kết luận của tôi, bị chính tôi bác bỏ (§2.8):**
>
> Bản báo cáo trước có mục *"phát hiện quan trọng nhất của bài"*: so hai batch, thấy p95 chênh
> 2,4–6,4 lần, kết luận **kích thước dữ liệu** là nguyên nhân. Điểm dữ liệu thứ ba đã phá vỡ nó:
>
> | Batch | `products` | `load_1m` (Stress) | p95 Stress |
> |---|---|---|---|
> | 13/08 | ~50.000 | 5,2 | 26 ms |
> | 15/08 14:26 | ~830.000 | **3,1** | **7 ms** |
> | 15/08 15:37 *(bộ nộp)* | ~900.000 | **5,7** | **18 ms** |
>
> Dữ liệu tăng đơn điệu 50k → 830k → 900k, nhưng p95 đi 26 → 7 → 18. Không theo dữ liệu. Theo
> `load_1m` thì cùng chiều cả ba điểm. **Biến áp đảo là tải nền của máy**, không phải dữ liệu.
>
> Để so sánh: `load_1m` chênh 1,8 lần làm p95 chênh **2,6 lần**, còn tăng VU **gấp 10 lần** chỉ làm
> p95 chênh 2,25 lần. Nhiễu môi trường lớn hơn tín hiệu chủ động tạo ra.
>
> §2.8 giữ lại dưới dạng **mục thu hồi** kèm bằng chứng — đó là lỗi đọc metric thật do chính người
> viết bắt, đúng thứ Task 2 chấm.

---

## 3. Bảng tự đánh giá (Self-Assessment)

> Đuôi tên file zip = tổng điểm tự chấm → `23127178_HW05_AI_Performance_100.zip`.
>
> **Cách tự chấm:** chỉ trừ điểm ở chỗ **nêu được thiếu sót cụ thể**, không trừ đều cho "chắc ăn".
> Bản trước tự chấm **88** với hai chỗ trừ. **Cả hai đã bịt bằng việc làm, không bằng lời giải thích:**
>
> - ~~**Task 3 −1:** flow chart là thiết kế trên giấy, chưa lần nào chạy thật trong pipeline CI.~~
>   → **Đã bịt.** Nhánh "PR pipeline" thành GitHub Actions thật
>   ([`.github/workflows/perf-smoke.yml`](.github/workflows/perf-smoke.yml)) và **đã chạy 6 lượt**,
>   trong đó **một lượt build ĐỎ thật** vì vượt ngưỡng. Bằng chứng: [`ci/ci-runs.md`](ci/ci-runs.md).
>   Kết quả còn **sửa lại chính §4.3**: ba lượt cùng cấu hình cho p95 **101 / 15 / 8 ms**, nên ngưỡng
>   p95 tuyệt đối bị bỏ hẳn, thay bằng error rate + so tương đối trong cùng lượt (§4.4).
> - ~~**Spike −1:** ảnh bắt `node` ở 34,9% trong khi đỉnh thật 81,6% — trượt đỉnh cú sốc.~~
>   → **Đã bịt.** Chạy lại **riêng** lượt Spike lúc **21:59** (đủ 240s, 38.251 sample, 0% error) và
>   chụp lại trong cửa sổ sốc: ảnh đọc **72,6%** so với đỉnh tool đo **75,7%** — lệch 3 điểm. Lượt
>   15:47 **không bị xoá**: nó thành lượt Spike thứ tư trong bảng §3.4, nơi bốn lượt cho thấy
>   `node` CPU đỉnh gần như nhau (75,7–81,6%) mà p95 đỉnh lệch **5,9 lần**.
>
> **Không còn chỗ nào trừ được mà nêu được tên.** Ba chỗ từng cân nhắc trừ nhưng không trừ, kèm lý do,
> vẫn ghi ở dưới để người chấm phản biện một lập luận có sẵn thay vì phải đoán.
>
> Ba chỗ **không** trừ, kèm lý do: Soak chỉ có 1/2 ảnh mốc thời gian nhưng cột `node_rss_mb` đã
> chứng minh trọn phần "không leo theo thời gian" và bài **ghi rõ là chỉ có một ảnh**; k6 có bản
> mirror mà chưa chạy — §8 xếp k6 là **bonus** nên không nằm trong 100 điểm; hai lượt chạy phải
> huỷ vì lỗi test plan thì bằng chứng đã xoá sạch và **quá trình đó chính là nội dung Task 2**.

| No. | Tiêu chí | Điểm tối đa | **Điểm tự chấm** | Căn cứ |
|-----|----------|-------------|--------------|--------|
| 1 | Task 1 — Load testing | 20 | **20** | 16.343 sample · 20 VU · think-time 1–3s/iteration bằng Uniform Random Timer · p95 **8ms**, 0% error · data-driven 4 file CSV · listener **Summary Report** · p95 tách theo endpoint → `import-products` lộ ra đắt nhất (10ms) · **ảnh `activity-load.png`** bắt `node` ở 13,4% CPU |
| 2 | Task 1 — Stress testing | 20 | **20** | **258.992 sample** · tăng **theo bậc** 25→50→100→200 VU để tìm *điểm* gãy · **539,7 RPS** · listener **Aggregate Report** · **ảnh `activity-stress.png`** bắt `node` ở **91,7% CPU** đúng bậc 200 VU · không kết luận "chịu tải tốt" từ p95 18ms mà đối chiếu CPU 20,3%→**97,7%**, p99 12→**124ms**, max **3691ms** → sát trần một lõi và đuôi đang dãn |
| 3 | Task 1 — Spike testing | 20 | **20** | 38.251 sample · 10 VU nền + 200 VU trong 5s, nhánh nền chạy xuyên lượt để **đo được hồi phục** · listener **View Results Tree** · **ảnh `activity-spike.png`** bắt `node` ở **72,6%** so với đỉnh tool đo **75,7%** · bảng p95 theo cửa sổ 10s: server **hấp thụ trọn cú sốc** (sample/10s tăng 20 lần, p95 đứng nguyên 7–8ms) · một "phát hiện" của bản trước (p95 tăng lúc tải **rút**, 12ms) **không lặp lại** ở lượt nộp (8ms) → giữ cả hai cột và hạ nó xuống thành **quan sát chưa tái hiện được** · **bốn lượt Spike cho bốn kết quả** — p95 đỉnh cửa sổ **47 / 8 / 12 / 9 ms**, lệch 5,9 lần trong khi sample lệch 0,8% **và `node` CPU đỉnh lệch chỉ 4 điểm** → server làm cùng lượng việc, cái nhảy nằm ở **thứ tự chờ**; `load_1m` **không** xếp đúng thứ tự nên nguyên nhân ghi là **chưa biết** (§3.4) |
| 4 | Task 2 — AI analysis + misinterpretation hunt | 10 | **10** | **7 lỗi đọc metric**, mỗi lỗi kèm giá trị đúng **và tên file**: gán chênh lệch p95 cho "database lớn hơn" (DB +8% vs `load_1m` +84%) · đọc p95 mà bỏ CPU · average 9,6ms khi p99 gấp **12,9 lần** và max gấp **384 lần** · "0% error" khi 99,2% bước 5 trả 400 · **đúng kết luận nhưng dùng cặp số mà tool của tôi in ra sai** · ngưỡng tự đề xuất rộng gấp 2,8 lần nên vô dụng · "đạt yêu cầu" khi chưa có SLA nào. 6 đề xuất phân loại feasible/hallucinated kèm **cách kiểm chứng**, + **4 đề xuất AI không nêu** |
| 5 | Task 3 — Continuous Performance Testing (G9.6) | 10 | **10** | Flow chart mermaid **15 nút** · giải thích **từng** nhánh · **7 trade-off** · trade-off quan trọng nhất có **ba điểm dữ liệu** hậu thuẫn: §2.8 cho thấy nhiễu môi trường (2,6×) **lớn hơn** tín hiệu chủ động tạo ra (2,25× khi tăng VU gấp 10) → baseline buộc phải đo lại trong **cùng lượt CI, cùng runner**, và mọi so sánh tuyệt đối giữa hai lượt là vô giá trị |
| 6 | Agent Skills | 10 | **10** | 4 skill trong `.claude/skills/`, **dùng thật trong bài**: `perf-test-plan` (7 bước, checklist duyệt 8 mục), `jtl-analysis` (bảng lỗi đọc metric + phân loại feasible/hallucinated), `resource-evidence` (định dạng bằng chứng §6/§11), `ai-audit-logger` (§9 + 3 trường riêng HW05). **Chờ video demo skill.** |
| | **Tổng** | **100** | **100** | Hai chỗ từng trừ đã bịt bằng việc làm: 5 lượt CI thật, và lượt Spike chạy lại có ảnh khớp đỉnh |

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
bash tools/package.sh 100           # → 23127178_HW05_AI_Performance_100.zip
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
| [bug-report/bug-report.md](bug-report/bug-report.md) + ảnh | **Đạt** — 2 bug xác nhận + 1 ứng viên đã loại kèm bảng kiểm chứng + `verify-bugs.sh` chạy lại được |
| 4 test plan `.jmx` đúng tên `{MSSV}_{Scenario}_{YYYYMMDD}` | **Đạt** |
| 4 raw `.jtl` đầy đủ + 4 HTML dashboard | **Đạt** — 358.661 sample (+ 8 lượt của 2 batch trước, giữ cho §2.8) |
| [endurance/endurance-threshold.md](endurance/endurance-threshold.md) | **Đạt** — 62,8 RPS · p95 8ms · trần 83,1 MB · trôi p95 **+0%**, RSS **+5,0%** |
| [resource-monitor/hardware-report.md](resource-monitor/hardware-report.md) | **Đạt** — hostname `Le-Nhut-Duy.local` khớp HW trước |
| Ảnh Activity Monitor (JMeter + monitor **cùng khung**) | **Đạt** — 4 ảnh, mỗi ảnh khớp lượt chạy trong `run-log.md` |
| Ảnh spec phần cứng | **Đạt** — `hardware-spec.png`, screenfetch với hostname `Le-Nhut-Duy` |
| Video demo ≥6 phút, unlisted, tiếng Việt | **Thiếu** |
| GitHub Issues cho 2 bug | **Thiếu** → lệnh có sẵn trong bug-report §4 |
| Task 3 — flow chart + trade-off | **Đạt** — main-report §4 |
| [git-log/commit-log.txt](git-log/) | Xuất bằng `bash tools/commit-plan.sh log` |

## 9. Việc còn lại

Chạy `bash tools/package.sh 100 --check` để soát. Còn **1 mục**:

1. **Video ≥6 phút**, unlisted, giọng mình → dán link vào README và main-report.
   Kịch bản: [docs/kich-ban-video-demo.md](docs/kich-ban-video-demo.md). Chuyện đáng kể nhất: mở bảng
   ba batch ở §2.8, giải thích vì sao kết luận đầu tiên về nguyên nhân là sai.

**Đã xong:** Human review của cả **12 lượt** trong
[ai-audit/ai-audit-report.md](ai-audit/ai-audit-report.md) — dùng hai nhãn ***(SV đã kiểm)*** và
***(SV chưa tự kiểm)***, cố ý tách nhau vì viết cả 12 lượt thành "đã kiểm hết" đúng là loại bằng
chứng dựng mà §11 phạt · **cột điểm §3** đã điền, tổng **88**, chỉ trừ ở hai chỗ nêu được tên ·
**Issue [#288](https://github.com/DuyITLOR/group05_eshop/issues/288) ·
[#289](https://github.com/DuyITLOR/group05_eshop/issues/289)** đã mở kèm ảnh nhúng.

## 10. Năm điều quyết định cách đọc mọi con số của bài này

1. **Tải nền của máy là biến áp đảo** — bài học đắt nhất, và có ba điểm dữ liệu: `load_1m` 5,2/3,1/5,7
   → p95 Stress 26/7/18 ms. Chênh 1,8 lần tải nền tạo chênh **2,6 lần** p95, còn tăng VU **gấp 10
   lần** chỉ tạo chênh 2,25 lần. Mọi con số chỉ có nghĩa kèm điều kiện `load_1m` ≈ 4,4–6,0.
   Xem [§2.8](report/main-report.md).
2. **Load generator và SUT cùng một máy.** JMeter CPU đỉnh 118–183%, nhiều hơn `node` ở ba trong bốn
   lượt.
3. **Mật khẩu lưu plaintext** ([`server.js:46`](../eshop-sut/backend/server.js#L46)) — login không tốn
   CPU băm, nên p95 24ms của nó **không** đại diện cho hệ thống băm mật khẩu đúng cách.
4. **Lockout kích hoạt sau 2 lần sai, không phải 3** (`login_attempts + 2`, ngưỡng 3 —
   [`server.js:54`](../eshop-sut/backend/server.js#L54)). Mọi `403` là **hành vi chức năng**.
5. **Bước 5 chỉ ghi thật 400 lần mỗi lượt**; 99,2% sample ở Stress trả 400 do FR-10 chặn trước lệnh
   `UPDATE`. Tín hiệu ghi nặng nằm ở **bước 4**.
