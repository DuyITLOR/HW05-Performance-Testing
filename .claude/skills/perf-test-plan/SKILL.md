---
name: perf-test-plan
description: Design and generate one JMeter performance test plan (Load, Stress, Spike, or Soak) for an EShop API endpoint group, step by step. Use when starting a new performance scenario — picking thread counts, ramp-up, think-time, CSV parameterization, token extraction, assertions and listeners — and when reviewing an AI-generated .jmx before running it.
---

# Perf Test Plan Skill

Sinh **một** test plan JMeter cho một scenario, đi đúng 7 bước. Lặp lại skill cho từng
scenario (Load → Stress → Spike → Soak). Cả 3 plan §6 đòi phải chạy **cùng một workflow
end-to-end**, chỉ khác tham số tải.

## Khi nào dùng
- Bắt đầu một scenario mới, hoặc chuyển workflow sang endpoint group khác.
- Khi cần duyệt lại một `.jmx` do AI sinh trước khi tin vào số nó tạo ra.

## Bước 1 — Nạp ngữ cảnh SUT trước khi hỏi AI bất cứ điều gì

Ba đặc điểm dưới đây quyết định tham số của plan. Không nói ra thì AI sẽ sinh một plan
generic và sai ở đúng những chỗ khó phát hiện nhất:

1. **Backend là Node một process, một luồng JS + SQLite ghi tuần tự.** Không có cluster,
   không có connection pool. Tăng VU quá một mức thì chỉ làm dài queue, không tăng throughput.
2. **Account lockout kích hoạt sau 2 lần sai** (`login_attempts + 2`, ngưỡng 3 —
   `server.js:54-58`), khoá 180s. Mọi thiết kế "login sai để test negative" phải dùng tài
   khoản riêng, tách khỏi luồng chính.
3. **Không có rate limiting.** Mọi 4xx đến từ credential/token/body, không phải throttling.

## Bước 2 — Chốt tham số cùng AI, có lý do cho từng số

Yêu cầu AI **giải thích vì sao** chọn từng con số, rồi tự đối chiếu với mục đích scenario:

| Scenario | Câu hỏi phải trả lời được | Dấu hiệu tham số sai |
|---|---|---|
| **Load** | p95 ở tải kỳ vọng là bao nhiêu? | không có think-time → không phải "tải kỳ vọng" mà là stress |
| **Stress** | điểm gãy ở đâu (VU nào error rate bật lên)? | tăng VU một phát → không tìm được *điểm* gãy, chỉ biết "gãy" |
| **Spike** | sau cú sốc bao lâu thì p95 về mức cũ? | không có đoạn "về mức thấp" sau spike → không đo được hồi phục |
| **Soak** | có rò rỉ / trôi p95 sau 10–15 phút? | chạy < 10 phút → không phải soak |

**Think-time là bắt buộc ở Load.** Không có think-time thì mỗi VU thành một vòng lặp bận, và
20 VU sinh tải như hàng trăm người thật — con số đo được không nói được gì về tải kỳ vọng.
Dùng Uniform Random Timer, không dùng hằng số (hằng số làm mọi VU đồng bộ thành từng đợt).

## Bước 3 — Sinh `.jmx`, đặt tên đúng ngay từ đầu

`23127178_{Load|Stress|Spike|Soak}_{YYYYMMDD}.jmx` trong `test-plans/`. §11 kiểm tay đúng
cái tên này; đổi tên sau khi đã chạy là chỗ dễ lệch giữa `.jmx`, `.jtl` và báo cáo.

Cấu trúc tối thiểu:

```
Test Plan
├── User Defined Variables            BASE_URL=http://localhost:3000
├── HTTP Header Manager               Content-Type: application/json
├── HTTP Cookie Manager               (mỗi thread một cookie store)
├── CSV Data Set Config × 3           users.csv · products_import.csv · orders.csv
│                                     Recycle=true, Sharing mode=All threads
├── Thread Group                      tham số từ bước 2
│   ├── 1. POST /api/login            + JSON Extractor  $.token → ${TOKEN}
│   ├── 2. GET  /api/admin/orders     Authorization: Bearer ${TOKEN}
│   ├── 3. GET  /api/admin/users
│   ├── 4. POST /api/admin/import-products
│   ├── 5. PUT  /api/admin/orders/${order_id}/status
│   └── Uniform Random Timer          think-time
└── Listener                          MỘT loại, khác với 2 plan còn lại
```

## Bước 4 — Assertion: kiểm cả mã lỗi lẫn nội dung

| Bước | Assert | Vì sao không assert chặt hơn/lỏng hơn |
|---|---|---|
| login | status 200 **và** có `token` trong body | 200 mà thiếu token thì 4 bước sau vô nghĩa nhưng vẫn "pass" |
| các GET | status 200 **và** body là JSON array | 401/403 trả rất nhanh → nếu chỉ đo thời gian sẽ ra p95 **đẹp giả** |
| import-products | status 200 **và** có field `message` | **KHÔNG** assert theo `inserted`: con số đó phụ thuộc dữ liệu (dòng thiếu `name` bị bỏ qua hợp lệ), nên assert theo nó biến đặc điểm dữ liệu thành lỗi hiệu năng |
| update status | status 200 | order đã ở trạng thái cuối sẽ lỗi — đó là data, không phải hiệu năng |

Assertion yếu là lỗi AI hay mắc nhất ở bài này, và nó nguy hiểm vì làm kết quả **tốt hơn thực
tế**: request bị từ chối trả về gần như tức thì, kéo p95 xuống.

## Bước 5 — Human review, ghi lại AI sai gì (§6 chấm mục này)

Checklist duyệt `.jmx` do AI sinh:

- [ ] Có think-time chưa? Loại timer nào? (hằng số là dấu hiệu chưa nghĩ tới đồng bộ hoá VU)
- [ ] Ramp-up có tương xứng số thread, hay dồn hết vào giây đầu?
- [ ] Token lấy từ JSON Extractor, hay bị hard-code một token đã hết hạn?
- [ ] CSV có `Recycle=true`? Sharing mode đúng? Hết dòng thì thread làm gì?
- [ ] Assertion có kiểm nội dung, hay chỉ kiểm status?
- [ ] Có nhánh login sai (test lockout)? Nếu có, đã dùng **tài khoản riêng** chưa?
- [ ] Listener có trùng loại với 2 plan còn lại? (§6 cấm lặp loại)
- [ ] View Results Tree có bị bật ở lượt dài? (ăn RAM, làm chậm chính JMeter)

Mỗi chỗ sửa → ghi vào `report/main-report.md` theo 3 trường: **sai gì · vì sao AI bỏ sót
(prompt / model / đặc điểm endpoint) · mình sửa thành gì**. §6 đòi đúng ba trường này.

## Bước 6 — Chạy, kèm bằng chứng → gọi `/resource-evidence`

```bash
bash tools/run-scenario.sh Load          # tự reset lockout, ép JAVA_HOME arm64, dọn folder -o
npm run summary
```

## Bước 7 — Đọc kết quả trước khi tin nó

Ba câu phải trả lời được, nếu không thì lượt chạy chưa dùng được:

1. Error % có bao nhiêu phần là **403 lockout** (chức năng) và bao nhiêu là **500/timeout**
   (hiệu năng)? `results/summary.md` đã tách sẵn theo response code.
2. p95 của **từng endpoint** — hay chỉ có p95 tổng? Số tổng bị endpoint nhanh nhất pha loãng.
3. Peak thread thực tế có bằng số thread đã cấu hình? Nếu nhỏ hơn, JMeter không kịp sinh tải
   và nút cổ chai đang ở load generator, không ở SUT.
