# Kịch bản quay video demo — HW05

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178
- **Yêu cầu:** ≥ 6 phút · YouTube **Unlisted** · giọng thuyết minh **tiếng Việt** · JMeter/tool và
  Activity Monitor **trong cùng khung**
- **Mục tiêu thời lượng:** **10:00** (đệm 4 phút trên mức tối thiểu — đừng quay sát 6:00)

> **Cách dùng file này.** Mỗi khối có ba phần: **[GÕ]** lệnh gõ trên màn hình · **[NÓI]** lời thuyết
> minh · **[TÁC DỤNG]** câu **quan trọng nhất** phải nói cho mỗi file. Người chấm đã đọc được file
> chứa gì; điều họ không tự thấy là **file đó ngăn được lỗi nào**. Nói phần TÁC DỤNG chậm và rõ.
>
> Nguyên tắc xuyên suốt: **không đọc code dòng nào.** Mở file, chỉ vào một chỗ, nói nó **làm gì**.

---

## Chuẩn bị trước khi bấm ghi

| Việc | Chi tiết |
|---|---|
| Cửa sổ | Terminal **bên phải**, Activity Monitor **bên dưới** (tab CPU, ô tìm gõ `node`), VS Code bên trái. Cả ba thấy được cùng lúc |
| Activity Monitor | **View → Update Frequency → Very often (1s)** |
| SUT | `cd eshop-sut/backend && node server.js` — chạy ở tab Terminal riêng, để thấy được |
| Terminal | Cỡ chữ ≥ 16pt. Người chấm xem trên laptop |
| Đóng | Zalo, Mail, Discord, mọi tab riêng tư. Menu bar sẽ nằm trong khung |
| Ghi màn hình | QuickTime → File → New Screen Recording → chọn **Options → Microphone** |
| Thử giọng | Quay 20 giây, nghe lại. Sai mic là mất cả 10 phút |

---

## 0:00 – 0:40 · Mở đầu

**[NÓI]** *"Em là Lê Nhựt Duy, MSSV 23127178, HW05 Performance Testing trên EShop backend. Trong
video này em đi theo **file**: mỗi file chứa gì, chạy ra gì, và quan trọng nhất là **nó ngăn được lỗi
nào**. Vì bài này có 15 lỗi kỹ thuật bị bắt trong quá trình làm, và phần lớn công cụ ở đây sinh ra
đúng để chặn những lỗi đó."*

**[GÕ]** `ls` — cho thấy cấu trúc repo một nhịp.

---

## 0:40 – 2:10 · Nhóm 1 — File **sinh ra** test plan

### `tools/gen-test-plans.py`

**[GÕ]** Mở file, cuộn tới hằng `WORKFLOW` rồi `SCENARIOS`.

**[NÓI]** *"File này chứa **hai** hằng số. `WORKFLOW` là 6 bước end-to-end của luồng admin
back-office. `SCENARIOS` là tham số tải của 4 scenario — Load 20 VU, Stress 4 bậc 25→50→100→200,
Spike 10 VU nền cộng 200 VU dội trong 5 giây, Soak 20 VU trong 12 phút."*

**[GÕ]** `npm run plans`

**[NÓI]** *"Chạy ra 4 file `.jmx`."*

**[TÁC DỤNG]** *"Tác dụng: §6 đòi ba test plan phải chạy **cùng một workflow**. Nếu em viết 4 file
`.jmx` bằng tay thì sớm muộn chúng lệch nhau, và người chấm không có cách nào biết. Sinh từ **một**
định nghĩa thì chúng **không thể** lệch — đó là bảo đảm về cấu trúc, không phải lời hứa."*

### `test-plans/23127178_Load_20260813.jmx`

**[GÕ]** Mở file, chỉ vào `JSR223PostProcessor`.

**[NÓI]** *"Đoạn Groovy này gọi `prev.setSuccessful(true)` khi mã trả về là 400 của FR-10 hoặc 403
của lockout."*

**[TÁC DỤNG]** *"Tác dụng — và đây là lỗi đắt nhất của bài: JMeter mặc định coi **mọi** 4xx là Fail,
và assertion chỉ **thêm** được lỗi chứ **không xoá** được cờ Fail. Không có đoạn này thì smoke test
báo **41% error** trên một hệ thống hoàn toàn khoẻ. Em mất hai lượt chạy mới hiểu ra."*

### `data/` — 4 file CSV

**[GÕ]** `head -3 data/users.csv` rồi `cat data/users_lockout.csv`

**[TÁC DỤNG]** *"Hai file tách nhau **có lý do**. Bản đầu em để 2 dòng mật khẩu sai trong
`users.csv`, mà luồng chính đọc chính file đó — nên nó **tự khoá tài khoản của mình**, 2,9% iteration
thành rác. Tách file là để dữ liệu test không tự đầu độc lượt chạy."*

---

## 2:10 – 3:10 · Nhóm 2 — File **dọn dẹp trước khi đo**

### `tools/preflight.mjs`

**[GÕ]** `npm run preflight`

**[TÁC DỤNG]** *"Tác dụng: `java` mặc định trên máy em là Temurin 8 **x86_64**, chạy qua Rosetta.
Nếu JMeter chạy trên bản đó thì **load generator tự nó thành điểm nghẽn** và mọi số đo nhiễu.
Preflight bắt chuyện đó **trước** khi mất 6 phút chạy. Bản đầu của file này còn có bug: nó đọc
`java_home -V` từ stdout trong khi lệnh in ra **stderr**, nên báo `[OK] Java` với giá trị **rỗng** —
báo xanh mà không kiểm gì."*

### `tools/reset-lockout.mjs` và `tools/reset-orders.mjs`

**[GÕ]** `node tools/reset-lockout.mjs` → `node tools/reset-orders.mjs`

**[NÓI]** *"Cái đầu đưa `login_attempts` về 0 cho mọi tài khoản. Cái sau đưa order về `pending`."*

**[TÁC DỤNG]** *"§6 đòi **reset account lockout giữa các lượt** và ghi lại thủ tục. Tác dụng cụ thể:
SUT này cộng `login_attempts` **2 đơn vị** mỗi lần sai — bug có từ HW trước — nên khoá sau **2** lần
sai, không phải 3. Không reset thì lượt sau bắt đầu với tài khoản đang bị khoá, và toàn bộ 403 đó sẽ
bị đọc thành lỗi hiệu năng. Còn `reset-orders` là vì bước 5 đi qua state machine FR-10: một order chỉ
chuyển tiếp **một lần** cho mỗi trạng thái, nên không reset thì từ lượt thứ hai nó trả 400 hết."*

---

## 3:10 – 5:20 · Nhóm 3 — **Chạy thật**, có Activity Monitor trong khung

> Đây là đoạn bắt buộc phải có cả hai cửa sổ. Chọn **Spike** vì nó chỉ 4 phút và có khoảnh khắc rõ nhất.

### `tools/capture-run.sh`

**[GÕ]** `bash tools/capture-run.sh Spike`

**[NÓI]** trong lúc chờ *"Script đang đếm ngược tới giây thứ 72."*

**[TÁC DỤNG]** *"Tác dụng: cửa sổ cú sốc chỉ rộng **30 giây** — CPU lên 75% rồi tụt về 8% trong
khoảng 24 giây. Canh tay là trượt. Lần đầu em chụp được **34,9%** trong khi đỉnh thật là **81,6%**,
tức ảnh nói ngược điều báo cáo nói. Script đếm ngược từ lúc **JMeter thật sự bắt đầu**, không phải
từ lúc bấm Enter."*

**[LÀM]** Đến mốc: chỉ vào Activity Monitor, đọc to số `node` **đang chạm ~72%**. Để cả hai cửa sổ
trong khung vài giây — **đây là bằng chứng §6**.

**[NÓI]** *"Đây là ảnh `activity-spike.png` trong bài: `node` 72,6%, tool đo đỉnh 75,7% — hai nguồn
độc lập khớp nhau."*

### `tools/sample-resources.sh`

**[GÕ]** `tail -3 results/resources/23127178_Spike_*.resources.csv`

**[TÁC DỤNG]** *"Chạy song song lượt test, lấy mẫu CPU/RSS của `node` và của JMeter mỗi 2 giây, cộng
cột `load_1m`. Tác dụng: ảnh chỉ là **một lát cắt**, file này cho **cả đường cong** nên tính được
đỉnh. Bản đầu bám sai tiến trình — `pgrep -f 'node server.js'` khớp cả cái **shell** đã khởi động
backend — nên ghi RSS 0,5 MB suốt 6 phút."*

---

## 5:20 – 7:00 · Nhóm 4 — File **đọc kết quả** (p95, p99, error rate)

### `tools/summarize-jtl.mjs` → `results/summary.md`

**[GÕ]** `npm run summary` rồi mở `results/summary.md`

**[NÓI]** *"Đọc cả 13 file `.jtl` raw, sinh ra bảng này."*

**[TÁC DỤNG]** *"Tác dụng: **không con số nào trong báo cáo được đếm tay** — §11 kiểm đúng chỗ đó.
Mọi số trong `main-report` đều truy được về file này, và file này truy được về `.jtl`."*

### `tools/ci-gate.mjs` — giải thích p95 / p99 / error rate

**[GÕ]** `node tools/ci-gate.mjs results/jtl/23127178_Stress_20260815-153717.jtl --p95 20`

**[NÓI]** chỉ vào từng số:
- *"p95 **18ms** — 95% request nhanh hơn 18ms."*
- *"p99 **124ms** — nhưng 1% chậm nhất thì gấp **7 lần** con p95 đó."*
- *"max **3.691ms** — có request chờ **gần 4 giây**."*
- *"avg 9,6ms — và đây là lý do **không được báo cáo bằng average**: p99 gấp **13 lần** avg, max gấp
  **205 lần** p95. Average xoá sạch cái đuôi."*

**[TÁC DỤNG — QUAN TRỌNG NHẤT, nói chậm]** *"Chỗ này phải nói rõ: **error rate 0% không có nghĩa là
không có 4xx.** Nhìn dòng mã trả về — có **51.301 mã 400**. Chúng được đánh dấu là **thành công** vì
đó là phản hồi **đúng đặc tả**: FR-10 chặn chuyển trạng thái không hợp lệ. Cổng này đọc cột
`success` của JMeter, **không** tự suy từ `responseCode` — nếu nó tự suy thì sẽ dựng lại đúng lỗi
18,25% error rate mà em mất hai lượt chạy để bắt. Và hệ quả: **539,7 req/s là throughput của toàn bộ
HTTP workflow, không phải của giao dịch đổi trạng thái hoàn tất** — chỉ 400 request chạm được lệnh
ghi thật."*

### `tools/soak-drift.mjs`

**[GÕ]** `npm run drift`

**[TÁC DỤNG]** *"Tính độ trôi p95 và RSS của lượt Soak 12 phút → chốt endurance threshold **62,8
req/s**. Bài **cố ý không** gọi đó là *maximum stable RPS*, vì chính lượt Stress đã đạt **539,7
req/s**. 62,8 là mức **đã xác nhận bền được** ở 20 VU. Và file này từng in **'trôi RSS +228,9%'** —
đọc y như rò rỉ bộ nhớ — chỉ vì nó lấy mẫu đầu **trước khi warm-up xong**. So nửa đầu với nửa sau thì
chỉ **+5%**."*

### Mở HTML dashboard

**[LÀM]** Mở `results/html/spike/index.html`, chỉ vào đồ thị response time over time.

---

## 7:00 – 8:40 · Nhóm 5 — **Agent Skills** (§7, end-to-end)

> Đoạn này quyết định 10 điểm Agent Skills. Phải thấy **input → human review → output**.

### `.claude/skills/perf-test-plan/SKILL.md`

**[GÕ]** Mở file, cuộn qua 7 bước.

**[NÓI]** *"Skill này là quy trình 7 bước để thiết kế **một** test plan cho **một** endpoint group,
kèm checklist duyệt 8 mục trước khi chạy."*

**[LÀM — end-to-end trên một endpoint group hoàn chỉnh]** Gõ prompt thật vào Claude Code:

```
Dùng skill perf-test-plan, thiết kế lượt Load cho endpoint group read-heavy
(GET /api/admin/orders và GET /api/admin/users). Đi từng bước, dừng ở bước
duyệt để tôi kiểm.
```

**[NÓI]** khi nó dừng ở bước duyệt *"Đây là **bước human review** — skill bắt dừng lại ở đây. Em kiểm
think-time đặt ở scope nào, vì lỗi số 6 của bài là timer đặt ở scope thread group nên bị chèn **5
lần** mỗi iteration, làm tải thực tế **nhẹ hơn thiết kế 5 lần** mà plan vẫn chạy bình thường."*

**[LÀM]** Mở plan/output nó sinh ra.

### `.claude/skills/jtl-analysis/SKILL.md`

**[GÕ]** Mở file, chỉ vào bảng các kiểu đọc sai metric.

**[NÓI]** *"Skill này soát lỗi đọc metric. Em cho AI phân tích `.jtl` trước, giữ nguyên văn trong
báo cáo §3.1, rồi dùng skill này soát lại — ra **7 lỗi**."*

**[LÀM]** Mở `report/main-report.md §3.2`, đọc **một** dòng — chọn dòng #1:

**[TÁC DỤNG]** *"AI nói p95 tăng *'có thể do database đã lớn hơn'*. Kiểm lại: database tăng **8%**,
còn `load_1m` tăng **84%**. Nó chọn giả thuyết nghe hợp lý thay vì đọc cột `load_1m` mà chính bộ tool
này đã ghi ra. Và điều đáng nói nhất: **em cũng từng mắc đúng lỗi đó** — §2.8 là mục **thu hồi** một
kết luận của chính em."*

### Hai skill còn lại — nói nhanh

**[NÓI]** *"`resource-evidence` quy định định dạng bằng chứng ảnh. `ai-audit-logger` ghi mỗi lượt
tương tác vào phụ lục §9 — hiện có **12 lượt**, mỗi lượt có prompt nguyên văn và trường Human review
ghi rõ chỗ nào em **đã tự kiểm**, chỗ nào **chưa**."*

---

## 8:40 – 9:40 · Nhóm 6 — File **kiểm lại và đóng gói**

### `tools/verify-all.sh` ← nói kỹ, đây là file mạnh nhất

**[GÕ]** `npm run verify`

**[TÁC DỤNG]** *"Tác dụng: mọi tài liệu trong repo chỉ là **lời khẳng định**. Người chấm không có
cách nào phân biệt 'con số này đo được' với 'con số này được viết ra'. Script này đi ngược lại: tính
lại từ `.jmx`, `.jtl`, `.csv`, rồi **so với con số đang in trong báo cáo** — lệch thì in FAIL kèm cả
hai giá trị. Nó **không** lấy số từ file `.md` nào để tính."*

**[LÀM]** Chỉ vào mục 1 và mục 4:

**[NÓI]** *"Mục 1 rút danh sách endpoint của **từng** `.jmx` rồi so chuỗi — sửa tay một plan là đỏ.
Mục 4 kiểm §11: giờ chụp mỗi ảnh phải nằm **trong khoảng lượt chạy**, lấy từ
`manifest.json` có kèm `sha256`, **không** lấy từ `mtime` — vì `cp` khi đóng gói đặt mtime mới, nên
validator chạy trong `.zip` sẽ báo đỏ mọi ảnh thật."*

### `bug-report/verify-bugs.sh`

**[GÕ]** `bash bug-report/verify-bugs.sh`

**[TÁC DỤNG]** *"Gọi request **thật** vào SUT để chứng minh lại 2 bug. Dòng quan trọng nhất là dòng
**đối chứng**: `GET /api/orders/1` không token trả **200**, còn `GET /api/orders/my-orders` không
token trả **401**. Không có dòng đối chứng thì bug chỉ là 'endpoint này không cần token' — có thể bị
phản biện là API vốn công khai. Có nó thì thành **một route bị bỏ sót**. Đã mở Issue **#288** và
**#289**."*

### `tools/package.sh`

**[GÕ]** `bash tools/package.sh 100 --check`

**[TÁC DỤNG]** *"Soát đúng danh sách §14 và **từ chối báo đủ** khi còn thiếu. §17 nói thiếu tài liệu
bắt buộc là **0 điểm**, nên bước này không được làm bằng mắt."*

---

## 9:40 – 10:00 · Kết — Task 3 đã chạy thật

**[GÕ]** `gh run list --workflow=perf-smoke.yml`

**[NÓI]** *"Task 3 đề chỉ đòi **đề xuất**. Em hiện thực nhánh PR pipeline thành GitHub Actions thật
và chạy **6 lượt**, trong đó **một lượt build đỏ**."*

**[TÁC DỤNG — câu kết]** *"Và nó **không** xác nhận điều em dựng nó ra để xác nhận. Ba lượt **giống
nhau từng tham số** cho p95 **101, 15 và 8 ms** — ngưỡng 8ms làm build đỏ ở lượt này thì lượt kia vừa
đủ xanh. Cùng code, cùng ngưỡng. Nên em **bỏ hẳn** ngưỡng p95 tuyệt đối trong đề xuất, chuyển sang
error rate và so thứ hạng endpoint trong **cùng một lượt**. Kết quả đo **sửa lại đề xuất**, chứ không
phải minh hoạ cho nó. Em xin hết."*

---

## Soát sau khi quay

| | |
|---|---|
| ☐ | Thời lượng **≥ 6:00** — kiểm bằng thanh thời gian, đừng đoán |
| ☐ | Có tiếng nói suốt, không đoạn im quá 15 giây |
| ☐ | Đoạn 3:10–5:20 thấy **rõ cả** Activity Monitor và Terminal |
| ☐ | Đã nói **vì sao 400/403 được đánh dấu success** |
| ☐ | Đã nói **cách reset lockout giữa các lượt** |
| ☐ | Đã có đoạn **Agent Skill end-to-end**, thấy bước human review |
| ☐ | Không có cửa sổ riêng tư / thông báo nào lọt vào khung |
| ☐ | Upload YouTube: chọn **Unlisted**, **KHÔNG** chọn Private |
| ☐ | Mở link ở cửa sổ ẩn danh để chắc người khác xem được |
| ☐ | Thêm **timestamp** vào description, nhất là mốc đoạn Agent Skill |

**Sau khi có link:** đưa link cho AI để dán vào `README.md`, `report/main-report.md`, `TASKS.md`,
đổi Agent Skills từ điểm có điều kiện thành **10**, bỏ dấu `100*`, xoá mọi câu *"CHƯA CÓ"/"THIẾU"/
*"chờ quay"*, build lại PDF và đóng gói lại.

---

## Nếu quay quá dài — cắt theo thứ tự này

Cắt từ dưới lên, **tuyệt đối không cắt** 3 nhóm đầu tiên trong danh sách giữ:

**Giữ bằng mọi giá:** đoạn chạy thật có Activity Monitor · giải thích 400/403 success · Agent Skill
end-to-end · reset lockout · p95/p99/error rate.

**Cắt được:** `soak-drift` (nói một câu thay vì chạy) · hai skill cuối · `package.sh` · phần HTML
dashboard (dashboard đã nộp kèm, người chấm mở được).
