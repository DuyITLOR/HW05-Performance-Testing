# HW05 — Playbook thực hiện

> Sinh viên: Lê Nhựt Duy — 23127178. Dùng AI theo **từng bước** (§2), không ra một prompt gộp.
> Mỗi bước = 1 commit nhỏ (§12). File này nằm trong repo, **không kèm** trong bản nộp .zip.

## Sơ đồ tổng thể

```
Chốt workflow + 3 endpoint group (§5 — docs/endpoint-selection.md)
  → sinh dữ liệu data-driven (npm run seed:perf → data/*.csv)
  → AI sinh test plan Load, rồi Stress, rồi Spike — TỪNG BƯỚC, người duyệt từng bước (§6)
  → human review: sửa ramp-up / think-time / thread count / assertion / lockout
  → chạy 3 lượt, mỗi lượt kèm ảnh JMeter + Activity Monitor CÙNG khung hình
  → soak 10–15 phút → chốt endurance threshold bằng số cụ thể
  → npm run summary  → Task 2: AI phân tích .jtl, mình bắt lỗi đọc metric
  → Task 3: mô hình continuous perf testing + flow chart + trade-off
  → video ≥6 phút → AI Audit + Critique → README self-assessment → zip nộp
```

## 0. Khởi động SUT

SUT dùng chung cho mọi HW, đặt ở **`../eshop-sut/`** (đã .gitignore — không commit vào repo bài).

```bash
cd ~/Documents/HK3_Nam3/kiem_thu       # THƯ MỤC GỐC — nơi có eshop.sh
./eshop.sh --seed                      # reset DB + backend :3000 · web :5273 · admin :5274
./eshop.sh stop
```

Bài này chỉ đo **backend API :3000**. Web/admin không cần cho việc đo, nhưng cứ để chạy vì
video demo có thể cần mở giao diện cho dễ hiểu.

Tài khoản seed: `admin@eshop.com / Admin123!` · `test@eshop.com / Test1234!`

## 0b. Cài công cụ

```bash
brew install jmeter                    # §8: JMeter là tool mặc định — bản nộp cần .jmx/.jtl/dashboard
brew install k6                        # bonus (đã có sẵn trên máy này)
cd ~/Documents/HK3_Nam3/kiem_thu/HW05-Performance-Testing
npm run preflight                      # kiểm tool + SUT + 5 endpoint + data
```

> **Java:** máy này mặc định `java` = Temurin 8 **x86_64** → JMeter sẽ chạy qua Rosetta và
> chính load generator trở thành điểm nghẽn. `tools/run-scenario.sh` tự ép `JAVA_HOME` sang
> JDK arm64 (26/21/17). Vì thế **đừng gọi `jmeter` tay** cho các lượt lấy số liệu.

## 1. Chốt phạm vi (§5) → [`docs/endpoint-selection.md`](endpoint-selection.md)

Đã chốt: workflow **admin back-office**, 5 bước, phủ đủ auth-heavy / read-heavy / transactional,
không trùng ai trong nhóm. Ba đặc điểm SUT phải nhớ khi thiết kế plan: lockout kích hoạt sau
**2** lần sai · không có rate limiting · `inserted` của `import-products` phụ thuộc dữ liệu nên không dùng làm assertion.

## 2. Dữ liệu data-driven (§6)

```bash
npm run seed:perf            # 50 account + 30 order + 60 dòng import → data/*.csv
npm run seed:perf -- --users 200 --orders 100    # khi cần nhiều VU hơn
```

**Mỗi VU một tài khoản riêng.** Dùng chung một tài khoản là tự tạo write-contention trên đúng
một dòng `users` (vì login nào cũng `UPDATE login_attempts`) → đo ra nghẽn của cách sinh tải,
không phải của endpoint.

## 3. Task 1 — AI sinh 3 test plan → skill `/perf-test-plan`

Với **mỗi** scenario, đi đúng các bước của skill; không ra một prompt kiểu *"viết test plan
load test cho API này"* (§2 cấm đích danh kiểu prompt đó).

| Bước | Việc | Commit gợi ý |
|---|---|---|
| 1 | Mô tả workflow + đặc điểm SUT cho AI (lockout, không rate limit, SQLite ghi tuần tự) | — |
| 2 | Cùng AI chốt tham số từng scenario: thread, ramp-up, think-time, loop, duration | — |
| 3 | Sinh `.jmx` bằng `python3 tools/gen-test-plans.py`; tên đúng `23127178_{Scenario}_YYYYMMDD.jmx` | `test(load): JMeter plan for back-office workflow` |
| 4 | Gắn CSV Data Set Config + JSON Extractor lấy token + assertion từng bước | `test(load): data-driven CSV + token extraction` |
| 5 | **Human review** — sửa và ghi lại AI sai gì, vì sao (bảng §6) | `docs: human review of AI-generated load plan` |
| 6 | **Smoke test 20–40 giây**, đọc `.jtl`, sửa tới khi lỗi đúng nguyên nhân | `test(load): fix think-time and assertion` |
| 7 | Chạy lượt chính thức kèm ảnh Activity Monitor | `test: raw jtl + dashboard for load run` |

> **Bước 6 không được bỏ.** Ở bài này, smoke test và 90 giây đầu của lượt chính đã bắt được 5 lỗi
> mà plan **vẫn chạy bình thường** với chúng: nhánh lockout bị tính thành lỗi hiệu năng (41% error
> giả), bước 5 assert cứng 200 trong khi FR-10 trả 400 hợp lệ (18% error giả), think-time nhân 5
> lần, và `users.csv` chứa dòng mật khẩu sai khiến luồng chính tự khoá tài khoản của mình. Chi
> tiết: [`ai-audit/ai-audit-report.md`](../ai-audit/ai-audit-report.md).

### Vì sao sinh `.jmx` bằng script

`tools/gen-test-plans.py` định nghĩa workflow **một lần** rồi phát ra 4 plan. §6 đòi cả 3 plan
chạy **cùng** một workflow end-to-end; viết tay 4 file XML 400–1100 dòng thì sớm muộn cũng lệch
nhau một assertion, và lúc đó so sánh Load với Stress với Spike mất ý nghĩa. Sửa workflow ở một
chỗ, chạy lại script, cả 4 plan đồng bộ.

**Tham số khởi điểm** (chốt lại cùng AI, đừng bê nguyên):

| Scenario | Thread (VU) | Ramp-up | Think-time | Thời lượng | Mục đích |
|---|---|---|---|---|---|
| **Load** | 20–30 | 60s | 1–3s ngẫu nhiên | 5–10 phút | tải kỳ vọng, p95 ở trạng thái ổn định |
| **Stress** | tăng bậc 25→50→100→200 | mỗi bậc 60s | 0.5–1s | ~10 phút | tìm điểm gãy |
| **Spike** | 10 → **200 trong 5s** → về 10 | ~0 | 0–0.5s | 3–5 phút | đo hồi phục sau cú sốc |
| **Soak** | mức ổn định cao nhất tìm được | 60s | 1–2s | **10–15 phút** | endurance threshold (§6) |

**Ba listener khác nhau, không lặp lại loại** (§6) — đây là chỗ dễ mất điểm oan:

| Test plan | Listener | Vì sao đặt ở đây |
|---|---|---|
| Load | **Summary Report** | tải ổn định → cần bảng tổng hợp gọn |
| Stress | **Aggregate Report** | cần cột percentile để thấy điểm gãy |
| Spike | **View Results Tree** | cần xem *nội dung* response lúc sốc (403 lockout? 500? timeout?) — và **chỉ bật ở lượt spike ngắn**, bật ở lượt dài là listener tự nó ăn hết RAM |

## 4. Chạy và thu bằng chứng (§6)

```bash
bash tools/run-scenario.sh Load        # tự reset lockout → chạy → .jtl + dashboard + run-log
bash tools/run-scenario.sh Stress
bash tools/run-scenario.sh Spike
bash tools/run-all.sh                  # cả 3, có cooldown 90s giữa các lượt
bash tools/run-all.sh --with-soak      # kèm luôn lượt endurance
npm run summary                        # → results/summary.md
```

Trước **mỗi** lượt: mở Activity Monitor, đặt cạnh terminal, **chụp/quay cùng khung hình** —
§6 đòi vậy và §11 kiểm đúng chỗ đó. Lưu vào `resource-monitor/screenshots/activity-<scenario>.png`.

```bash
bash tools/hardware-report.sh          # → resource-monitor/hardware-report.md (bảng spec + hostname)
npm run reset:lockout                  # mở khoá tài khoản; --check để chỉ xem
```

> **Cooldown giữa các lượt là bắt buộc.** Chạy Spike ngay sau Stress là đo một server chưa
> hồi phục — và đó đúng là loại lỗi đọc số liệu mà Task 2 yêu cầu chỉ ra.

## 5. Endurance threshold (§6) → [`endurance/endurance-threshold.md`](../endurance/endurance-threshold.md)

Soak 10–15 phút ở mức tải ổn định, rồi báo cáo bằng **số cụ thể**, tối thiểu:

- max stable RPS (mức RPS cao nhất mà error rate còn ~0 và p95 không trôi lên)
- p95 ở mức đó
- RSS của process `node` lúc bắt đầu và lúc kết thúc (có trôi = rò rỉ)
- điều kiện phần cứng: lấy từ `resource-monitor/hardware-report.md`

Định nghĩa "ổn định" phải viết ra trước khi chạy, nếu không sẽ tự chọn số đẹp sau khi thấy
kết quả. Đề xuất: **error rate < 1% và p95 không tăng quá 20% giữa 5 phút đầu và 5 phút cuối.**

## 6. Task 2 — AI phân tích + bắt lỗi đọc metric → skill `/jtl-analysis`

1. Đưa AI raw `.jtl` (hoặc `results/summary.md`), yêu cầu phân tích + đề xuất ngưỡng.
2. **Human review:** với mỗi chỗ AI đọc sai metric, ghi *giá trị đúng lấy từ raw `.jtl`* và
   giải thích sai ở đâu. Bốn lỗi AI hay mắc trên chính bộ số liệu này:
   - gộp `403` (lockout) vào "server sụp" — trong khi đó là hành vi chức năng
   - lấy **average** làm kết luận trong khi phân phối lệch phải → phải dùng p95/p99
   - đọc `elapsed` như thời gian xử lý server, bỏ qua cột `Latency`
   - so RPS giữa hai lượt có **thời lượng khác nhau** mà không chuẩn hoá
3. Yêu cầu AI đề xuất tối ưu (index, connection pool, SQLite WAL…) rồi tự phân loại
   **feasible / hallucinated** kèm lý do. Với SUT này: WAL và index là feasible; "bật
   connection pool cho SQLite" gần như luôn là hallucinated vì `sqlite3` của Node dùng một
   handle trên file cục bộ, không có pool theo nghĩa client-server.

## 7. Task 3 — Continuous Performance Testing (§Task 3, 10đ)

Vào phần kết luận của `report/main-report.md`: mô hình theo dõi commit của SUT, quyết định khi
nào chạy perf test, và cảnh báo khi p95 hồi quy. Bắt buộc có **flow chart** + thảo luận
**trade-off** (chi phí, báo động giả). Vẽ bằng mermaid trong markdown.

## 8. Tài liệu và nộp bài (§9, §10, §14)

```bash
bash tools/build-pdfs.sh    # main-report · ai-audit-report · ai-critique · bug-report → PDF
```

- **AI Critique** phải **200–300 từ**, trả lời đủ 3 câu §10. Đếm lại trước khi nộp.
- **Video ≥6 phút**, unlisted, thuyết minh tiếng Việt, JMeter + resource monitor **cùng khung hình**.
- Tên file zip: `23127178_HW05_AI_Performance_<điểm tự chấm>.zip`.
- §12: mỗi bước của quy trình một commit; xuất `git-log/commit-log.txt` bằng `git log --graph --stat`.

## 9. Bẫy đã biết của bài này

| Bẫy | Hậu quả nếu sập | Cách tránh |
|---|---|---|
| JMeter chạy trên Java 8 x86_64 (Rosetta) | load generator tự nó là điểm nghẽn, mọi số đo nhiễu | dùng `tools/run-scenario.sh` (tự ép JAVA_HOME arm64) |
| Dùng chung 1 tài khoản cho mọi VU | 403 hàng loạt do lockout, đọc sai thành server sụp | dùng pool account hợp lệ; ghi rõ khi VU vượt số account |
| Không reset lockout giữa các lượt | lượt sau đo trên tài khoản còn bị khoá | `run-scenario.sh` tự reset; §6 đòi ghi lại bước này |
| Bật View Results Tree ở lượt dài | listener ăn hết RAM, JMeter chậm hơn cả SUT | chỉ bật ở lượt Spike ngắn |
| Chạy 3 scenario song song | 3 lượt tranh CPU, cả 3 bộ số liệu vô nghĩa | `run-all.sh` chạy tuần tự + cooldown |
| Không xoá folder `-o` cũ | JMeter báo lỗi **sau khi** chạy xong → mất cả lượt | `run-scenario.sh` tự dọn |
| Assert theo `inserted` của import-products | assertion Fail vì lý do dữ liệu, không phải hiệu năng | assert HTTP status + field `message` (`inserted` đã kiểm và **đúng**, nhưng nó phụ thuộc dữ liệu) |
| Đếm số liệu bằng tay từ dashboard | lệch giữa README và báo cáo | chỉ lấy từ `results/summary.md` |
