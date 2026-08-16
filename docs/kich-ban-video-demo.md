# KỊCH BẢN QUAY VIDEO DEMO HW05 — BẢN DỄ ĐỌC

- **Sinh viên:** Lê Nhựt Duy
- **MSSV:** 23127178
- **Video đã quay:** https://youtu.be/hCf4bXwzx2A — **11:49**, unlisted (đã kiểm `isUnlisted:true`, `isPrivate:false`)
- **Thời lượng nên quay:** 8–10 phút
- **Bắt buộc:** video từ 6 phút, YouTube **Unlisted**, giọng nói tiếng Việt của mình
- **Trong lúc chạy test:** Terminal/JMeter và Activity Monitor phải xuất hiện **cùng một khung hình**
- **Agent Skill:** phải có một đoạn sử dụng skill từ đầu đến kết quả

> Những câu nằm trong khối **ĐỌC NGUYÊN VĂN** đã được viết để đọc thẳng khi quay.
> Không cần học thuộc. Đọc chậm, nghỉ một nhịp ở dấu chấm.

---

# 1. Chuẩn bị trước khi quay

## Mở sẵn các cửa sổ

- VS Code mở thư mục `HW05-Performance-Testing`.
- Terminal đặt bên phải màn hình.
- Activity Monitor đặt phía dưới hoặc bên trái Terminal.
- Trong Activity Monitor:
  - chọn tab **CPU**;
  - nhập `node` vào ô tìm kiếm;
  - chọn **View → Update Frequency → Very Often**.
- Mở sẵn các file:
  - `README.md`;
  - `test-plans/23127178_Stress_20260813.jmx`;
  - `results/summary.md`;
  - `report/main-report.md`;
  - `.claude/skills/perf-test-plan/SKILL.md`.

## Kiểm tra trước khi bấm ghi

- Đóng Zalo, Mail, Discord và các tab có thông tin riêng tư.
- Tăng cỡ chữ Terminal và VS Code để người xem đọc được.
- Bật SUT trước khi quay.
- Chọn đúng microphone trong QuickTime.
- Quay thử 15–20 giây rồi nghe lại tiếng.
- Có thể quay thành nhiều đoạn rồi ghép; đề không yêu cầu một lần quay liên tục.

---

# 2. Kịch bản chính

## CẢNH 1 — GIỚI THIỆU (0:00–0:40)

### THAO TÁC

Mở `README.md`, để phần tên sinh viên và bảng kết quả tổng quan trên màn hình.

### ĐỌC NGUYÊN VĂN

> Em là Lê Nhựt Duy, MSSV 23127178. Đây là video demo bài HW05 Performance Testing trên hệ thống
> EShop.
>
> Trong bài này, em dùng JMeter để chạy ba loại kiểm thử chính là Load, Stress và Spike. Em cũng chạy
> thêm một lượt Soak trong 12 phút để kiểm tra độ ổn định.
>
> Video này sẽ trình bày ba phần: cách em thiết kế test plan, cách em chạy và đọc kết quả, và cách em
> dùng Agent Skill để kiểm soát quy trình.

---

## CẢNH 2 — GIẢI THÍCH LUỒNG KIỂM THỬ (0:40–1:25)

### THAO TÁC

Trong `README.md`, cuộn đến bảng **Phạm vi — ba endpoint group**.

### ĐỌC NGUYÊN VĂN

> Cả ba test plan đều chạy cùng một luồng quản trị.
>
> Đầu tiên là đăng nhập, thuộc nhóm auth-heavy. Tiếp theo là xem danh sách đơn hàng và người dùng,
> thuộc nhóm read-heavy. Sau đó là import sản phẩm và đổi trạng thái đơn hàng, thuộc nhóm
> transactional.
>
> Ngoài ra, em có một nhánh đăng nhập sai mật khẩu để kiểm tra account lockout.
>
> Em giữ nguyên luồng này trong Load, Stress và Spike. Ba plan chỉ khác số người dùng ảo, thời gian
> tăng tải và think-time. Nhờ vậy, kết quả giữa ba scenario có thể so sánh với nhau.

---

## CẢNH 3 — TEST PLAN VÀ DỮ LIỆU CSV (1:25–2:20)

### THAO TÁC

Mở `tools/gen-test-plans.py`, tìm `WORKFLOW`, sau đó tìm `SCENARIOS`.

Chạy:

```bash
npm run plans
```

Sau đó mở thư mục `test-plans/` và `data/`.

### ĐỌC NGUYÊN VĂN

> File này không trực tiếp gửi request. Nó tạo ra bốn file JMeter gồm Load, Stress, Spike và Soak.
>
> Workflow được viết một lần rồi dùng chung cho cả bốn plan. Khi cần sửa endpoint hoặc assertion,
> em chỉ sửa một chỗ và sinh lại toàn bộ. Cách này tránh việc bốn file JMeter bị lệch nhau.
>
> Toàn bộ dữ liệu test nằm ngoài script. Em dùng bốn file CSV cho tài khoản, tài khoản lockout, sản
> phẩm import và đơn hàng.
>
> Em tách tài khoản lockout thành file riêng. Bản đầu em để chung với tài khoản bình thường, làm luồng
> chính tự đăng nhập sai và tự khóa tài khoản của nó. Đây là một lỗi dữ liệu test mà em phát hiện sau
> khi kiểm tra kết quả chạy thử.

---

## CẢNH 4 — LOAD, STRESS VÀ SPIKE KHÁC NHAU THẾ NÀO (2:20–3:05)

### THAO TÁC

Mở bảng cấu hình scenario trong `report/main-report.md`, mục cấu hình Load, Stress, Spike và Soak.

### ĐỌC NGUYÊN VĂN

> Load dùng 20 người dùng ảo để mô phỏng mức tải thông thường.
>
> Stress tăng theo bốn bậc: 25, 50, 100 và 200 người dùng ảo. Mục tiêu là quan sát hệ thống khi tải
> tăng dần và xem tài nguyên bắt đầu tiến gần giới hạn ở đâu.
>
> Spike giữ 10 người dùng nền, sau đó thêm 200 người dùng trong 5 giây. Thiết kế này giúp em nhìn được
> trạng thái trước, trong và sau cú sốc.
>
> Soak dùng 20 người dùng ảo trong 12 phút. Kết quả 62,8 request mỗi giây là mức em đã xác nhận ổn
> định trong 12 phút. Em không gọi đây là mức tối đa, vì em chưa chạy nhiều bậc soak để tìm giới hạn
> cuối cùng.

---

## CẢNH 5 — CHẠY THẬT VÀ THEO DÕI TÀI NGUYÊN (3:05–5:00)

> Đây là cảnh bắt buộc. Terminal và Activity Monitor phải nằm trong cùng khung hình.

### THAO TÁC

Đặt Terminal và Activity Monitor cạnh nhau. Trong Terminal chạy:

```bash
bash tools/capture-run.sh Spike
```

Trong lúc chờ JMeter chạy, đọc phần bên dưới. Khi script báo đến mốc spike, chỉ vào dòng `node` trong
Activity Monitor và giữ nguyên khung hình vài giây.

### ĐỌC NGUYÊN VĂN

> Bây giờ em chạy thật scenario Spike. Terminal bên phải đang chạy JMeter. Activity Monitor bên cạnh
> đang hiển thị CPU của backend Node.
>
> Script này vừa chạy JMeter, vừa ghi CPU và bộ nhớ mỗi hai giây. Nó cũng nhắc em đúng thời điểm cú
> spike xảy ra để em không chụp trượt đỉnh tải.
>
> Bản đầu em canh bằng mắt nên ảnh chỉ bắt được khoảng 35 phần trăm CPU, trong khi file tài nguyên ghi
> đỉnh hơn 80 phần trăm. Vì vậy em sửa quy trình: thời điểm chụp phải được tính từ lúc JMeter bắt đầu,
> không tính từ lúc em bấm Enter.
>
> Ở lượt Spike dùng làm kết quả chính, ảnh Activity Monitor ghi khoảng 72,6 phần trăm CPU. File lấy mẫu
> độc lập ghi đỉnh 75,7 phần trăm. Hai nguồn chỉ lệch khoảng ba điểm phần trăm.
>
> Việc để tool và Activity Monitor trong cùng khung chứng minh đây là lượt chạy thật trên máy của em,
> chứ không chỉ là một bảng số liệu đã chuẩn bị trước.

### NẾU KHÔNG MUỐN CHỜ HẾT 4 PHÚT

Có thể dừng phần ghi sau khi đã quay được cảnh spike, rồi chuyển sang clip tiếp theo. Khi dựng video,
giữ ít nhất 60–90 giây có Terminal và Activity Monitor cùng xuất hiện.

---

## CẢNH 6 — RESET ACCOUNT LOCKOUT (5:00–5:35)

### THAO TÁC

Chạy:

```bash
node tools/reset-lockout.mjs
node tools/reset-orders.mjs
```

### ĐỌC NGUYÊN VĂN

> Trước mỗi lượt, em reset account lockout và đưa đơn hàng về trạng thái pending.
>
> Nếu không reset lockout, lượt sau sẽ bắt đầu bằng các tài khoản đã bị khóa và kết quả sẽ sai.
>
> Nếu không reset đơn hàng, bước đổi trạng thái sẽ trả 400 vì đơn đó đã được chuyển ở lượt trước.
>
> Hai bước reset này được tự động gọi trước mỗi scenario và cũng được ghi trong run log.

---

## CẢNH 7 — ĐỌC KẾT QUẢ JTL (5:35–6:55)

### THAO TÁC

Chạy:

```bash
npm run summary
```

Mở `results/summary.md`, chỉ vào bảng tổng quan. Sau đó chạy:

```bash
node tools/ci-gate.mjs results/jtl/23127178_Stress_20260815-153717.jtl --p95 20
```

### ĐỌC NGUYÊN VĂN

> File JTL là dữ liệu thô. Mỗi request được ghi thành một dòng. Script summary đọc trực tiếp các file
> này để tính số sample, throughput, p95, p99 và error rate. Vì vậy các con số trong báo cáo đều có
> thể tính lại, không phải nhập bằng tay.
>
> Kết quả Stress chính có 258.992 sample, throughput 539,7 request mỗi giây, p95 là 18 mili-giây và
> p99 là 124 mili-giây. Request chậm nhất mất gần 3,7 giây.
>
> Average chỉ là 9,6 mili-giây. Nếu chỉ nhìn average, em sẽ bỏ qua phần đuôi rất chậm. Vì vậy em luôn
> đọc p95, p99 và max cùng nhau.
>
> Error rate được ghi là 0 phần trăm, nhưng điều này cần giải thích. Một số mã 400 của state machine
> và 401, 403 của nhánh lockout là phản hồi đúng theo kịch bản, nên test plan đánh dấu chúng là thành
> công.
>
> Vì vậy, 539,7 request mỗi giây là throughput của toàn bộ workflow HTTP. Nó không có nghĩa là có
> 539 giao dịch đổi trạng thái đơn hàng hoàn tất trong một giây.

---

## CẢNH 8 — HUMAN REVIEW: AI ĐÃ ĐỌC SAI GÌ (6:55–7:55)

### THAO TÁC

Mở `report/main-report.md`, đến mục **AI phân tích và soát lỗi đọc metric**.

### ĐỌC NGUYÊN VĂN

> Sau khi có raw JTL, em nhờ AI phân tích trước rồi tự kiểm tra lại.
>
> AI nói hệ thống xử lý 200 người dùng đồng thời tốt vì p95 chỉ 18 mili-giây. Kết luận này thiếu một
> nửa dữ liệu: CPU của Node đã lên 97,7 phần trăm của một lõi, p99 là 124 mili-giây và max gần 3,7
> giây. Hệ thống giữ được p95 thấp nhưng đã tiến gần giới hạn một luồng.
>
> AI cũng cho rằng p95 tăng vì database lớn hơn. Em từng tin và từng viết đúng kết luận đó. Sau khi
> có thêm một lượt chạy, dữ liệu lớn hơn nhưng kết quả lại nhanh hơn. Vì vậy em thu hồi kết luận cũ.
>
> Bài học của em là một nguyên nhân nghe hợp lý chưa phải là một nguyên nhân đã được chứng minh. Khi
> so các lượt performance test, phải kiểm soát tải nền và các biến môi trường trước khi kết luận.

---

## CẢNH 9 — DEMO AGENT SKILL END-TO-END (7:55–8:55)

### THAO TÁC

Mở `.claude/skills/perf-test-plan/SKILL.md`, cuộn chậm qua bảy bước.

Trong Claude Code, nhập đúng prompt sau:

```text
Dùng skill perf-test-plan để thiết kế một lượt Load cho nhóm read-heavy gồm
GET /api/admin/orders và GET /api/admin/users. Đi từng bước và dừng ở bước
human review để tôi kiểm tra trước khi chốt kết quả.
```

Nếu AI xử lý lâu, có thể tạm dừng ghi và quay tiếp khi nó đã tới bước human review.

### ĐỌC NGUYÊN VĂN

> Đây là Agent Skill perf-test-plan mà em dùng trong bài.
>
> Skill chia việc thiết kế test plan thành bảy bước. AI phải xác định endpoint, dữ liệu, tải, assertion
> và bằng chứng. Sau đó nó phải dừng ở bước human review để em kiểm tra trước khi chốt.
>
> Ở ví dụ này, em yêu cầu skill thiết kế một lượt Load cho nhóm read-heavy. Đây là input của em. Phần
> AI đang trả về là quá trình thực hiện. Và đây là điểm dừng human review.
>
> Em kiểm tra số người dùng ảo, ramp-up, think-time, dữ liệu CSV và assertion. Nếu một mục chưa hợp lý,
> em sửa ở bước này thay vì chạy ngay.
>
> Tác dụng của skill không phải là thay em quyết định. Nó giúp em không bỏ sót bước, còn kết quả cuối
> cùng vẫn do em kiểm tra và chịu trách nhiệm.

### THAO TÁC CUỐI CẢNH

Sau khi kiểm tra phần human review, nhập tiếp:

```text
Tôi đã kiểm tra các tham số. Hãy tiếp tục, chốt test plan và cho tôi xem
output cuối cùng gồm endpoint, VU, ramp-up, think-time và assertion.
```

Mở output cuối cùng hoặc test plan mà skill vừa tạo. Chỉ vào endpoint, VU, ramp-up, think-time và
assertion để chứng minh quy trình đã đi từ **input → human review → output**.

---

## CẢNH 10 — KẾT THÚC (8:55–9:15)

### THAO TÁC

Giữ màn hình ở output cuối cùng của Agent Skill hoặc quay lại bảng kết quả tổng quan trong
`README.md`.

### ĐỌC NGUYÊN VĂN

> Qua Agent Skill này, AI giúp em thực hiện đúng từng bước, nhưng em vẫn là người kiểm tra tham số và
> chịu trách nhiệm cho kết quả cuối cùng.
>
> Em xin kết thúc phần demo. Cảm ơn thầy cô và anh chị đã xem video.

---

# 3. Nếu cần rút video xuống gần 7 phút

Giữ nguyên các cảnh sau:

1. Giới thiệu.
2. Workflow ba endpoint group.
3. Cảnh chạy thật có Activity Monitor.
4. Reset lockout.
5. Giải thích p95, p99 và error rate.
6. Human review AI.
7. Agent Skill end-to-end.

Có thể rút ngắn:

- Cảnh tạo test plan còn 30 giây.
- Chỉ nói một câu về Load/Stress/Spike.
- Không cần chạy `npm run summary` nếu đã mở sẵn `results/summary.md`.

Không được cắt:

- Tool và Activity Monitor cùng khung.
- Giọng nói của mình.
- Giải thích reset lockout.
- Agent Skill từ input đến human review và output.

---

# 4. Checklist sau khi quay

- [ ] Tổng thời lượng ít nhất **6 phút**.
- [ ] Nghe rõ giọng nói từ đầu đến cuối.
- [ ] Có Terminal/JMeter và Activity Monitor trong cùng khung khi test đang chạy.
- [ ] Có nói về Load, Stress và Spike.
- [ ] Có giải thích reset account lockout.
- [ ] Có giải thích p95, p99 và error rate.
- [ ] Có nói rõ vì sao một số 400/401/403 được tính là phản hồi hợp lệ.
- [ ] Có demo Agent Skill từ prompt đến human review và output.
- [ ] Không lộ thông báo hoặc thông tin riêng tư.
- [ ] Upload YouTube ở chế độ **Unlisted**, không phải Private.
- [ ] Mở link bằng cửa sổ ẩn danh để chắc chắn người chấm xem được.
- [ ] Dán link vào `README.md`, `report/main-report.md` và `TASKS.md`.
- [ ] Xóa các dòng `CHƯA CÓ`, `THIẾU` và `chờ quay`.
- [ ] Xuất lại PDF và đóng gói lại bài nộp.

---

# 5. Mẫu mô tả YouTube

```text
HW05 — Performance Testing on EShop
Sinh viên: Lê Nhựt Duy — MSSV 23127178

00:00 Giới thiệu
00:40 Workflow và endpoint groups
01:25 Test plan và CSV data-driven
02:20 Load, Stress, Spike và Soak
03:05 Chạy JMeter cùng Activity Monitor
05:00 Reset account lockout
05:35 Đọc JTL, p95, p99 và error rate
06:55 Human review kết quả AI
07:55 Agent Skill end-to-end
08:55 Kết thúc
```
