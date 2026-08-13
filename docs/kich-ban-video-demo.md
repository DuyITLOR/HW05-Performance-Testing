# Kịch bản video demo — HW05

> §6: **≥6 phút tổng**, có thể chia một clip cho mỗi scenario. Bắt buộc: **JMeter và resource
> monitor trong CÙNG khung hình**, thuyết minh **tiếng Việt** bằng giọng của mình, video
> **unlisted**. §11 kiểm đúng ba điều đó.

## Chuẩn bị trước khi bấm ghi

- [ ] SUT đang chạy: `cd ~/Documents/HK3_Nam3/kiem_thu && ./eshop.sh --seed`
- [ ] `npm run preflight` sạch lỗi
- [ ] Dữ liệu đã sinh: `npm run seed:perf`
- [ ] Activity Monitor mở sẵn, tab CPU, lọc `node`, **đặt cạnh terminal trong cùng khung ghi**
- [ ] Đặt vùng ghi ôm **cả hai** cửa sổ — kiểm bằng cách ghi thử 10 giây rồi xem lại
- [ ] Tắt thông báo (Do Not Disturb), đóng tab riêng tư

## Bố cục 3 clip — tổng ~7 phút (đệm trên mức 6 phút của đề)

### Clip 1 — Load (~2:30)

| Thời lượng | Nội dung | Lời thoại (ý chính) |
|---|---|---|
| 0:00–0:20 | `whoami` · `hostname` · `date` | "Đây là máy của tôi, hostname trùng với các HW trước — đúng yêu cầu §11." |
| 0:20–0:50 | Mở `test-plans/23127178_Load_*.jmx` trong JMeter GUI | Chỉ vào: 5 bước workflow, 3 CSV Data Set, JSON Extractor lấy token, Uniform Random Timer |
| 0:50–1:10 | Chỉ vào listener | "Plan này dùng **Summary Report**; Stress dùng Aggregate, Spike dùng View Results Tree — §6 không cho lặp loại." |
| 1:10–2:10 | `bash tools/run-scenario.sh Load` — **cả terminal và Activity Monitor trong khung** | Nói trong lúc chạy: `node` ăn gần hết **một** lõi trong khi các lõi khác rảnh → trần của một luồng JS |
| 2:10–2:30 | Mở `results/html/load/index.html` | Chỉ p95, không chỉ average — và nói vì sao |

### Clip 2 — Stress (~2:30)

| Thời lượng | Nội dung | Lời thoại (ý chính) |
|---|---|---|
| 0:00–0:30 | Chỉ cấu hình bậc VU 25→50→100→200 | "Tăng theo bậc để tìm **điểm** gãy, không phải chỉ biết là có gãy." |
| 0:30–1:50 | Chạy, quan sát Activity Monitor lúc bậc cao nhất | Chỉ lúc error rate bật lên và nói con số VU tại thời điểm đó |
| 1:50–2:30 | `npm run summary` → mở bảng phân rã response code | **Điểm nhấn:** tách 403 (lockout — chức năng) khỏi 500/timeout (hiệu năng). Gộp hai thứ là đọc sai bản chất |

### Clip 3 — Spike + phần đã sửa của AI (~2:00)

| Thời lượng | Nội dung | Lời thoại (ý chính) |
|---|---|---|
| 0:00–1:00 | Chạy Spike, chỉ đoạn dựng đứng rồi về mức thấp | "Đo thời gian **hồi phục**: bao lâu p95 về mức trước cú sốc." |
| 1:00–1:30 | Mở View Results Tree, xem một response lỗi thật | Đọc nội dung response — thứ hai listener kia không cho thấy |
| 1:30–2:00 | **Một chỗ đã sửa test plan do AI sinh sai** | Ví dụ: AI bỏ think-time → "load test" hoá ra là stress test; hoặc AI dùng chung một tài khoản cho mọi VU → lockout hàng loạt |

> Mục cuối là mục dễ ghi điểm nhất và cũng dễ bỏ quên nhất: §6 chấm riêng phần "AI sai gì và
> mình sửa gì". Nói ra trong video mạnh hơn viết trong báo cáo.

## Nếu làm thêm video Agent Skill (§7)

Clip riêng ~3–4 phút, đi end-to-end trên **một endpoint group hoàn chỉnh**, mỗi skill một cảnh
theo 3 nhịp (cách HW04 đã làm và được đánh giá tốt):

1. mở SKILL.md, đọc nó gồm những bước gì
2. gõ prompt gọi nó
3. mở thành quả ra xem bên trong có gì

Thứ tự: `/perf-test-plan` → `/resource-evidence` → `/jtl-analysis` → `/ai-audit-logger`.

## Sau khi quay

- [ ] Upload YouTube, chế độ **Unlisted**
- [ ] Kiểm lại: tổng thời lượng **≥6 phút**
- [ ] Kiểm lại: có khung nào JMeter và monitor **không** cùng khung hình không
- [ ] Dán link vào `README.md` và `report/main-report.md`
