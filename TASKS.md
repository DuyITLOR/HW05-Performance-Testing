# Bản đồ yêu cầu → nơi đáp ứng

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178 · **Bài:** HW05-AI Performance Testing

Mục đích của file này: người chấm mở một trang là biết **từng yêu cầu của đề nằm ở đâu**, không
phải đọc dò cả repo.

**Vì sao không tách thành `task1/` `task2/` `task3/`:** §14 đòi *"**Main report** … including the
performance-testing report **and** your AI-analysis critique"* — Task 1 và Task 2 phải nằm trong
**một** báo cáo. Task 2 phân tích chính số liệu Task 1 sinh ra, Task 3 dựa trên phát hiện của cả
hai (§2.8), nên chép chúng ra ba file rời sẽ tạo hai nguồn số liệu và chắc chắn lệch nhau. Ba task
vì thế là **ba chương của báo cáo**, còn bằng chứng thì nằm theo *loại* (`results/`, `test-plans/`,
`endurance/`) đúng như §14 gọi tên chúng.

---

## Task 1 — AI-assisted test design and execution (60 điểm)

> Bảng trace chi tiết từng ý, có ô tick để tự review: [`docs/review-task1.md`](docs/review-task1.md)
> *(file nội bộ, không nộp)*

| Yêu cầu của đề | Nơi đáp ứng |
|---|---|
| Ba test plan **Load, Stress, Spike** | [`test-plans/`](test-plans/) — `23127178_{Load,Stress,Spike}_20260813.jmx` (+ `Soak` cho endurance §6) |
| Cả ba plan **cùng một workflow end-to-end** | [`tools/gen-test-plans.py`](tools/gen-test-plans.py) hằng `WORKFLOW` (dòng 29) — định nghĩa **một lần**, 4 plan phát ra từ nó nên không thể lệch |
| Phủ **3 endpoint group** + *briefly justify* | [`report/main-report.md §1.2`](report/main-report.md) — bảng 6 bước, cột "Vì sao đáng đo" |
| **Không trùng** trong nhóm (§5) | [`report/main-report.md §1.1`](report/main-report.md) — bảng đăng ký nhóm 05 + xác nhận chỗ giao duy nhất · bản đầy đủ: [`docs/endpoint-selection.md`](docs/endpoint-selection.md) |
| **Tham số** think-time / ramp-up / VU + lý do | [`report/main-report.md §2.1`](report/main-report.md) — bảng 4 scenario + 3 đoạn giải thích · nguồn: [`gen-test-plans.py`](tools/gen-test-plans.py) hằng `SCENARIOS` (dòng 107) |
| **Dùng AI từng bước**, không một prompt gộp (§2) | [`ai-audit/design-log.md`](ai-audit/design-log.md) — **nhật ký 7 bước**: mỗi bước hỏi gì, căn cứ, quyết định, thay đổi cụ thể trong file · quy trình: [`.claude/skills/perf-test-plan/SKILL.md`](.claude/skills/perf-test-plan/SKILL.md) · prompt nguyên văn: [`ai-audit/ai-audit-report.md`](ai-audit/ai-audit-report.md) |
| **Data-driven bằng CSV** | [`data/`](data/) — 4 file · mô tả: [`report/main-report.md §1.3`](report/main-report.md) |
| **Ba listener khác loại** | Summary Report (Load) · Aggregate Report (Stress) · View Results Tree (Spike) — bảng ở [`§2.1`](report/main-report.md) |
| **Human review** — AI sai gì, vì sao | [`report/main-report.md §2.4`](report/main-report.md) — bảng 10 lỗi, 3 nhóm lý do · chi tiết kèm prompt nguyên văn: [`ai-audit/ai-audit-report.md`](ai-audit/ai-audit-report.md) |
| **Raw `.jtl`** nộp đầy đủ | [`results/jtl/`](results/jtl/) · [`endurance/jtl/`](endurance/jtl/) |
| **HTML report folder** | [`results/html/{load,stress,spike}/`](results/html/) · [`endurance/html/soak/`](endurance/html/) |
| Ảnh **tool + resource monitor cùng khung** | [`resource-monitor/screenshots/`](resource-monitor/screenshots/) · số liệu tài nguyên tính được: [`results/resources/*.csv`](results/resources/) (2 giây/mẫu, có cả cột JMeter) |
| **Hardware report** (hostname khớp HW trước) | [`resource-monitor/hardware-report.md`](resource-monitor/hardware-report.md) — `Le-Nhut-Duy.local` |
| **Reset lockout giữa các lượt** + ghi lại thủ tục | [`report/main-report.md §2.6`](report/main-report.md) · script: [`tools/reset-lockout.mjs`](tools/reset-lockout.mjs), [`tools/reset-orders.mjs`](tools/reset-orders.mjs) |
| **Endurance threshold** kèm số cụ thể | [`endurance/endurance-threshold.md`](endurance/endurance-threshold.md) · tóm tắt: [`§2.7`](report/main-report.md) |
| **Video demo ≥6 phút** | *(chờ)* — kịch bản: [`docs/kich-ban-video-demo.md`](docs/kich-ban-video-demo.md) |
| **Report issues** lên GitHub Issues | [`bug-report/bug-report.md`](bug-report/bug-report.md) · kiểm chứng lại: `bash bug-report/verify-bugs.sh` |

## Task 2 — AI analysis and misinterpretation hunt (10 điểm)

| Yêu cầu của đề | Nơi đáp ứng |
|---|---|
| **AI phân tích** `.jtl` + đề xuất ngưỡng | [`report/main-report.md §3.1`](report/main-report.md) — nguyên văn, **chưa sửa** |
| **Soát lỗi đọc metric**, kèm *"correct value from your raw `.jtl` log"* | [`report/main-report.md §3.2`](report/main-report.md) — 7 lỗi, mỗi lỗi kèm giá trị đúng **và tên file `.jtl`** |
| Phân loại đề xuất tối ưu **feasible / hallucinated** | [`report/main-report.md §3.3`](report/main-report.md) — 6 đề xuất + **cách kiểm chứng** từng cái, + 2 đề xuất AI không nêu |
| Bản tính độc lập từ raw log để đối chất | [`results/summary.md`](results/summary.md) sinh bởi [`tools/summarize-jtl.mjs`](tools/summarize-jtl.mjs) · độ trôi: [`tools/soak-drift.mjs`](tools/soak-drift.mjs) |
| Quy trình tái dùng được | [`.claude/skills/jtl-analysis/SKILL.md`](.claude/skills/jtl-analysis/SKILL.md) |

## Task 3 — Continuous Performance Testing proposal (10 điểm, G9.6)

| Yêu cầu của đề | Nơi đáp ứng |
|---|---|
| **Mô hình** theo dõi commit, quyết định khi nào chạy, cảnh báo hồi quy p95 | [`report/main-report.md §4.1`](report/main-report.md) |
| **Flow chart** | [`§4.1`](report/main-report.md) — mermaid 15 nút, có sẵn trong PDF |
| Giải thích từng nhánh | [`§4.2`](report/main-report.md) |
| **Trade-off** (chi phí, báo động giả) | [`§4.3`](report/main-report.md) — 6 trade-off, mỗi cái nói rõ *cái phải trả* |
| Liên kết về số liệu thật của bài | [`§2.8`](report/main-report.md) chứng minh lượt Load 3 phút trong CI **không** bắt được hồi quy do dữ liệu phình → buộc thêm nhánh Stress theo lịch |

## Các mục còn lại của đề

| Mục | Nơi đáp ứng |
|---|---|
| §7 Agent Skills | [`.claude/skills/`](.claude/skills/) — 4 skill, đều dùng thật trong bài · index: [`.claude/README.md`](.claude/README.md) |
| §8 Công cụ đã dùng | JMeter 5.6.3 (chính) · k6 v2.1.0 ([`k6/`](k6/), bonus) · Activity Monitor · Claude Code (Opus 5) |
| §9 AI Audit Report | [`ai-audit/ai-audit-report.md`](ai-audit/ai-audit-report.md) — 8 lượt, prompt nguyên văn |
| §10 AI Critique 200–300 từ | [`ai-audit/ai-critique.md`](ai-audit/ai-critique.md) — **298 từ** |
| §11 Anti-AI-Cheat | tên `.jmx` đúng mẫu · `.jtl` nộp đầy đủ · hostname khớp HW trước · mốc thời gian từng lượt: [`results/run-log.md`](results/run-log.md), [`endurance/run-log.md`](endurance/run-log.md) |
| §12 Commit theo từng bước | [`git-log/commit-log.txt`](git-log/) · sinh bởi [`tools/commit-plan.sh`](tools/commit-plan.sh) |
| §14 Đóng gói nộp bài | [`tools/package.sh`](tools/package.sh) — dựng `.zip` theo đúng danh sách §14 và **từ chối** báo đủ khi còn thiếu · soát: `bash tools/package.sh <điểm> --check` |
| §15 Self-assessment | [`README.md §3`](README.md) — căn cứ đã điền cho cả 6 dòng |
