---
name: jtl-analysis
description: Analyse raw JMeter .jtl logs, derive performance thresholds and the endurance ceiling, and audit an AI's analysis for metric misinterpretation. Use after a performance run has produced a .jtl file, when writing the Task 2 analysis section, or when an AI (or a report) makes claims about p95, error rate, throughput or resource usage that need checking against the raw log.
---

# JTL Analysis Skill

Task 2 chấm hai việc **khác nhau**: AI phân tích (output của AI) và mình soát lại (phần của
mình). Skill này lo cả hai, theo đúng thứ tự đó.

## Khi nào dùng
- Vừa xong một lượt chạy, đã có `results/jtl/*.jtl`.
- Đang viết mục Task 2, hoặc cần kiểm một phát biểu về p95 / error rate / throughput.

## Bước 0 — Có bản tính từ RAW trước khi hỏi AI

```bash
npm run summary                              # mọi .jtl → results/summary.md
node tools/summarize-jtl.mjs results/jtl/23127178_Stress_20260813-143000.jtl
```

Task 2 đòi *"cite the correct value from your raw `.jtl` log"*. Không có bản tính độc lập từ
raw thì không đối chất được với AI — chỉ còn cách tin nó, mà đó đúng là điều đề muốn chặn.

## Bước 1 — Cho AI phân tích (đây là output của AI, giữ nguyên văn)

Đưa AI `results/summary.md` **và** trích đoạn raw `.jtl`, yêu cầu: phân tích kết quả, chỉ ra
nút cổ chai, đề xuất ngưỡng hiệu năng. Lưu **nguyên văn** câu trả lời vào
`ai-audit/ai-audit-report.md` trước khi soát — sửa rồi mới lưu là làm mất chính vật chứng.

## Bước 2 — Soát lỗi đọc metric (đây là phần của mình, chấm nặng)

Sáu lỗi hay gặp trên đúng bộ số liệu của SUT này:

| # | Lỗi AI hay mắc | Vì sao sai | Đối chứng từ raw |
|---|---|---|---|
| 1 | Gộp `403` vào "server quá tải" | 403 ở đây là **account lockout** (`server.js:40-44`) — hành vi chức năng, xảy ra cả khi server rảnh | bảng "Phân rã lỗi theo response code" trong `summary.md` |
| 2 | Kết luận bằng **average** | phân phối lệch phải: vài request chậm khủng bị average pha loãng | so cột `avg` với `p95`/`p99` cùng dòng |
| 3 | Coi `elapsed` là thời gian xử lý server | `elapsed` gồm cả truyền body; `Latency` mới là tới byte đầu | hai cột `latency avg` / `latency p95` |
| 4 | So RPS giữa hai lượt **khác thời lượng** | RPS = sample / duration; lượt ngắn có warm-up chiếm tỉ lệ lớn hơn | cột `Thời lượng` ở bảng tổng quan |
| 5 | Đọc p95 **tổng** thay vì p95 **từng endpoint** | endpoint nhanh (GET) pha loãng endpoint chậm (import) | bảng "Theo endpoint" |
| 6 | Nói "server sụp" khi peak thread < số thread cấu hình | nghẽn nằm ở **load generator**, không ở SUT | `Peak thread` vs cấu hình trong `.jmx` |

Mỗi lỗi bắt được → ghi thành một dòng: **AI nói gì · giá trị đúng từ raw `.jtl` (kèm tên file)
· sai ở đâu**. Đó chính là định dạng Task 2 yêu cầu.

## Bước 3 — Phân loại đề xuất tối ưu: feasible hay hallucinated

Yêu cầu AI đề xuất tối ưu, rồi tự phân loại từng đề xuất kèm lý do. Trên SUT này:

| Đề xuất | Phân loại | Lý do |
|---|---|---|
| Thêm index cho `orders.user_id` | **feasible** — kiểm được | `GET /api/admin/orders` JOIN theo `user_id`, bảng không có index; đo lại được sau khi thêm |
| Bật SQLite **WAL** | **feasible** | đúng loại tải ghi nhiều của `import-products`; một dòng `PRAGMA journal_mode=WAL` |
| Thêm **connection pool** cho SQLite | thường **hallucinated** | `sqlite3` của Node mở handle trên file cục bộ, không phải client-server → không có pool theo nghĩa đó |
| Bật HTTP keep-alive / nén | **feasible** nhưng ít tác dụng ở đây | body nhỏ, và cả hai đầu đều ở localhost |
| Scale ngang / thêm replica | **hallucinated trong phạm vi bài** | SUT là một process trên máy cá nhân; không kiểm chứng được bằng bằng chứng của bài này |
| Redis cache cho product list | feasible về kỹ thuật, **ngoài phạm vi** | phải nói rõ là không kiểm chứng, đừng để lẫn vào nhóm "đã chứng minh" |

Phân loại phải kèm **cách kiểm chứng**. Một đề xuất không nói được cách đo lại thì xếp vào
hallucinated, bất kể nghe hợp lý cỡ nào.

## Bước 4 — Chốt endurance threshold (§6)

Định nghĩa "ổn định" **trước** khi xem kết quả soak, nếu không sẽ tự chọn số đẹp:

> Ổn định = error rate < 1% **và** p95 không tăng quá 20% giữa 5 phút đầu và 5 phút cuối.

Báo cáo bằng số cụ thể vào `endurance/endurance-threshold.md`:

| Chỉ số | Cách lấy |
|---|---|
| max stable RPS | RPS cao nhất còn thoả định nghĩa trên |
| p95 tại mức đó | `summary.md`, dòng scenario Soak |
| RSS của `node` đầu/cuối | Activity Monitor, hoặc `ps -o rss= -p <pid>` |
| ngưỡng bộ nhớ | RSS lúc p95 bắt đầu trôi |
| cấu hình phần cứng | `resource-monitor/hardware-report.md` |

Luôn kèm một câu về giới hạn: load generator và SUT **chạy cùng máy**, nên đây là ngưỡng của
cấu hình đó, không phải năng lực tối đa của backend.
