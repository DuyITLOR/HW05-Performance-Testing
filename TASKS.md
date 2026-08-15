# Bản đồ yêu cầu → nơi đáp ứng → **cách tự kiểm**

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178 · **Bài:** HW05-AI Performance Testing

File này có **ba** cột, và cột thứ ba là cột quan trọng nhất.

Cột 1 là yêu cầu của đề. Cột 2 nói nội dung nằm ở đâu. **Cột 3 là lệnh để tự kiểm nội dung đó có
thật và có đúng hay không** — vì cột 2 chỉ là một lời khẳng định, và người review không có cách nào
phân biệt "con số này đo được" với "con số này được viết ra" nếu chỉ đọc tài liệu.

**Chạy hết một lượt:**

```bash
bash tools/verify-all.sh      # hoac: npm run verify
```

Script đó tính lại mọi con số **từ `.jmx` · `.jtl` · `.csv` · mtime của ảnh**, rồi so với con số
đang in trong báo cáo. Lệch thì in `[FAIL]` kèm **cả hai giá trị**. Nó không đọc số từ file `.md`
nào để tính — `.md` chỉ dùng để so.

Trạng thái hiện tại: **33 PASS · 1 FAIL** (FAIL duy nhất là **link video demo** chưa có).

**Vì sao không tách thành `task1/` `task2/` `task3/`:** §14 đòi *"**Main report** … including the
performance-testing report **and** your AI-analysis critique"* — Task 1 và Task 2 phải nằm trong
**một** báo cáo. Task 2 phân tích chính số liệu Task 1 sinh ra, Task 3 dựa trên phát hiện của cả
hai (§2.8, §3.4), nên chép chúng ra ba file rời sẽ tạo hai nguồn số liệu và chắc chắn lệch nhau. Ba
task vì thế là **ba chương của báo cáo**, còn bằng chứng nằm theo *loại* (`results/`, `test-plans/`,
`endurance/`, `ci/`) đúng như §14 gọi tên chúng.

---

## Task 1 — AI-assisted test design and execution (60 điểm)

| Yêu cầu của đề | Nơi đáp ứng | **Tự kiểm bằng** |
|---|---|---|
| Ba test plan **Load, Stress, Spike** | [`test-plans/`](test-plans/) — `23127178_{Load,Stress,Spike}_20260813.jmx` (+ `Soak` cho §6) | `ls test-plans/` |
| Cả ba plan **cùng một workflow end-to-end** | [`tools/gen-test-plans.py`](tools/gen-test-plans.py) hằng `WORKFLOW` — định nghĩa **một lần**, 4 plan phát ra từ nó | `verify-all.sh` mục 1 — rút danh sách endpoint của **từng** `.jmx` rồi so chuỗi. Sửa tay một plan là đỏ |
| Phủ **3 endpoint group** + *briefly justify* | [`report/main-report.md §1.2`](report/main-report.md) — bảng 6 bước, cột "Vì sao đáng đo" | `grep 'HTTPSampler.path' test-plans/23127178_Load_*.jmx` |
| **Không trùng** trong nhóm (§5) | [`report/main-report.md §1.1`](report/main-report.md) — bảng đăng ký nhóm 05 · bản đầy đủ: [`docs/endpoint-selection.md`](docs/endpoint-selection.md) | đối chiếu tay với ảnh chat nhóm — **chỉ mục này không tự động kiểm được** |
| **Tham số** think-time / ramp-up / VU + lý do | [`report/main-report.md §2.1`](report/main-report.md) | `sed -n '/^SCENARIOS/,/^}/p' tools/gen-test-plans.py` |
| **Dùng AI từng bước**, không một prompt gộp (§2) | [`ai-audit/design-log.md`](ai-audit/design-log.md) — **7 bước** · prompt nguyên văn: [`ai-audit/ai-audit-report.md`](ai-audit/ai-audit-report.md) — **12 lượt** | `grep -c '^### Interaction #' ai-audit/ai-audit-report.md` |
| **Data-driven bằng CSV** | [`data/`](data/) — 4 file · §1.3 | `verify-all.sh` mục 2 — kiểm mỗi CSV **có được plan nào dùng thật** không |
| **Ba listener khác loại** | Summary Report (Load) · Aggregate Report (Stress) · View Results Tree (Spike) | `verify-all.sh` mục 1 — đếm listener **khác loại**, phải đúng 3 |
| **Human review** — AI sai gì, vì sao | [`report/main-report.md §2.4`](report/main-report.md) — **15 lỗi kỹ thuật + 2 lỗi bản nộp**, 3 nhóm lý do | `grep -c '^| 1[0-9] \||^| [1-9] \|' report/main-report.md` |
| **Raw `.jtl`** nộp đầy đủ | [`results/jtl/`](results/jtl/) (10) · [`endurance/jtl/`](endurance/jtl/) (3) | `verify-all.sh` mục 3 — **tính lại sample/p95/error** từ raw rồi so với báo cáo |
| **HTML report folder** | [`results/html/{load,stress,spike}/`](results/html/) · [`endurance/html/soak/`](endurance/html/) | mở `results/html/spike/index.html` |
| Ảnh **tool + resource monitor cùng khung** | [`resource-monitor/screenshots/`](resource-monitor/screenshots/) — 5 ảnh | **`verify-all.sh` mục 4** — kiểm mtime từng ảnh có nằm **trong khoảng lượt chạy** của run-log không (§11) |
| Số liệu tài nguyên tính được | [`results/resources/*.csv`](results/resources/) — 2 giây/mẫu, có cả cột JMeter và `load_1m` | `verify-all.sh` mục 5 |
| **Hardware report** (hostname khớp HW trước) | [`resource-monitor/hardware-report.md`](resource-monitor/hardware-report.md) — `Le-Nhut-Duy.local` | `verify-all.sh` mục 6 · `hostname -s` |
| **Reset lockout giữa các lượt** + ghi thủ tục | [`report/main-report.md §2.6`](report/main-report.md) · [`tools/reset-lockout.mjs`](tools/reset-lockout.mjs), [`tools/reset-orders.mjs`](tools/reset-orders.mjs) | `node tools/reset-lockout.mjs` (cần SUT chạy) |
| **Endurance threshold** kèm số cụ thể | [`endurance/endurance-threshold.md`](endurance/endurance-threshold.md) · §2.7 | `node tools/soak-drift.mjs` — tính lại từ `.jtl` |
| **Video demo ≥6 phút** | **CHƯA CÓ** — kịch bản `docs/kich-ban-video-demo.md` (chỉ trong repo, không đóng gói) · phải có cả đoạn **demo Agent Skill end-to-end** (§7) | `verify-all.sh` mục 6 — đang **[FAIL]** |
| **Report issues** lên GitHub Issues | [`bug-report/bug-report.md`](bug-report/bug-report.md) — Issue [#288](https://github.com/DuyITLOR/group05_eshop/issues/288) · [#289](https://github.com/DuyITLOR/group05_eshop/issues/289) | `bash bug-report/verify-bugs.sh` — **gọi request thật** vào SUT, chạy lại từng bằng chứng |

## Task 2 — AI analysis and misinterpretation hunt (10 điểm)

| Yêu cầu của đề | Nơi đáp ứng | **Tự kiểm bằng** |
|---|---|---|
| **AI phân tích** `.jtl` + đề xuất ngưỡng | [`§3.1`](report/main-report.md) — nguyên văn, **chưa sửa một chữ** | đọc — chỗ này cố tình không sửa để còn cái mà soát |
| **Soát lỗi đọc metric** kèm *"correct value from your raw `.jtl`"* | [`§3.2`](report/main-report.md) — **7 lỗi**, mỗi lỗi kèm giá trị đúng **và tên file** | `node tools/ci-gate.mjs results/jtl/23127178_Stress_20260815-153717.jtl --p95 20` → so p99/max với bảng |
| Trong đó có lỗi của **chính báo cáo**, bị bác bỏ | [`§2.8`](report/main-report.md) — mục **thu hồi**, giữ lại thay vì xoá | so 3 batch: `npm run summary` rồi đọc `results/summary.md` |
| Phân loại đề xuất **feasible / hallucinated** | [`§3.3`](report/main-report.md) — 6 đề xuất + **cách kiểm chứng** từng cái, + **4 đề xuất AI không nêu** | mỗi dòng feasible có cột "cách kiểm chứng" — chạy được |
| Bản tính độc lập từ raw log để đối chất | [`results/summary.md`](results/summary.md) ← [`tools/summarize-jtl.mjs`](tools/summarize-jtl.mjs) | `npm run summary` — sinh lại, so với bản đang có |
| Đo hồi phục sau sốc | [`§3.4`](report/main-report.md) — bảng cửa sổ 10s, **2 cột 2 lượt** vì phát hiện cũ **không tái hiện được** | `verify-all.sh` mục 3 + bảng 4 lượt Spike trong §3.4 |
| Quy trình tái dùng được | [`.claude/skills/jtl-analysis/SKILL.md`](.claude/skills/jtl-analysis/SKILL.md) | — |

## Task 3 — Continuous Performance Testing proposal (10 điểm, G9.6)

| Yêu cầu của đề | Nơi đáp ứng | **Tự kiểm bằng** |
|---|---|---|
| **Mô hình** theo dõi commit, khi nào chạy, cảnh báo hồi quy p95 | [`§4.1`](report/main-report.md) | — |
| **Flow chart** | [`§4.1`](report/main-report.md) — mermaid **15 nút**, render sẵn trong PDF | mở `report/main-report.pdf` |
| Giải thích **từng** nhánh | [`§4.2`](report/main-report.md) — 8 nhánh | — |
| **Trade-off** (chi phí, báo động giả) | [`§4.3`](report/main-report.md) — **7 trade-off**, mỗi cái nói rõ *cái phải trả* | — |
| Liên kết về số liệu thật của bài | [`§2.8`](report/main-report.md) và [`§3.4`](report/main-report.md) | `npm run summary` |
| **Đã chạy thật, không chỉ vẽ** | [`§4.4`](report/main-report.md) + [`ci/ci-runs.md`](ci/ci-runs.md) — **6 lượt CI**, **1 lượt build ĐỎ**; kết quả **sửa lại chính §4.3** | `gh run list --workflow=perf-smoke.yml` · `verify-all.sh` mục 8 · cổng chạy ngoài CI được: `node tools/ci-gate.mjs <jtl> --p95 8` |

## Các mục còn lại của đề

| Mục | Nơi đáp ứng | **Tự kiểm bằng** |
|---|---|---|
| §7 Agent Skills | [`.claude/skills/`](.claude/skills/) — 4 skill, dùng thật trong bài | `ls .claude/skills/` |
| §8 Công cụ | JMeter 5.6.3 · k6 v2.1.0 ([`k6/`](k6/), bonus, **chưa chạy**) · Activity Monitor · Claude Code (Opus 5) | `jmeter -v` |
| §9 AI Audit Report | [`ai-audit/ai-audit-report.md`](ai-audit/ai-audit-report.md) — **12 lượt**, prompt nguyên văn, mỗi lượt có Human review ghi rõ *đã kiểm* / *chưa tự kiểm* | `grep -c 'SV đã kiểm' ai-audit/ai-audit-report.md` |
| §10 AI Critique 200–300 từ | [`ai-audit/ai-critique.md`](ai-audit/ai-critique.md) — **293 từ** | `verify-all.sh` mục 6 — đếm lại |
| §11 Anti-AI-Cheat | tên `.jmx` đúng mẫu · `.jtl` đầy đủ · hostname khớp HW trước · mốc thời gian: [`results/run-log.md`](results/run-log.md), [`endurance/run-log.md`](endurance/run-log.md) | **`verify-all.sh` mục 1 + 4** — đây là mục kiểm được chặt nhất: ảnh phải nằm trong khoảng lượt chạy |
| §12 Commit theo từng bước | [`git-log/commit-log.txt`](git-log/) ← [`tools/commit-plan.sh`](tools/commit-plan.sh) | `git log --oneline \| wc -l` |
| §14 Đóng gói nộp bài | [`tools/package.sh`](tools/package.sh) — **từ chối** báo đủ khi còn thiếu | `bash tools/package.sh 100 --check` |
| §15 Self-assessment | [`README.md §3`](README.md) — **100/100**, hai chỗ từng trừ đã bịt bằng việc làm | đọc §3, mỗi dòng có cột căn cứ |

---

## Chỗ KHÔNG tự động kiểm được

Nói ra để không tạo cảm giác mọi thứ đều đã được máy xác nhận:

1. **Không trùng endpoint trong nhóm (§5)** — căn cứ là ảnh chat nhóm, phải đối chiếu bằng mắt.
2. **Nội dung ảnh chụp** — script kiểm được *thời điểm* ảnh, không kiểm được *trong ảnh có gì*. Con
   số CPU đọc từ ảnh phải xem bằng mắt và so với `results/resources/*.csv`.
3. **Video demo** — chưa có.
4. **k6** — có bản mirror, **chưa chạy lần nào**. §8 xếp k6 là bonus nên không tính điểm, nhưng cũng
   không được nói là đã đối chiếu chéo.
