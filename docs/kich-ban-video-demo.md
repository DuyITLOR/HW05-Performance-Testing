# Kịch bản quay video demo — HW05

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178
- **Yêu cầu:** ≥ 6 phút · YouTube **Unlisted** · giọng **tiếng Việt** của mình · tool và resource
  monitor **trong cùng khung**
- **Mục tiêu:** **10:00**. Đề cho phép **chia nhiều clip**, mỗi scenario một clip — tổng ≥6 phút là đủ,
  không cần một take liền mạch.

---

## Mục đích của video (đọc trước khi quay — nó quyết định quay cái gì)

Video **không phải để trình bày kết quả**. Kết quả đã nằm trong `.zip` rồi, người chấm đọc nhanh hơn
bạn nói. Video là **thứ duy nhất** nối kết quả đó với **bạn**, trên **máy của bạn**, tại **một thời
điểm**. Đọc ba ràng buộc của đề thì thấy rõ:

| Đề bắt buộc | Nó chặn gì |
|---|---|
| tool + resource monitor **cùng khung** | `.jtl` sửa được, ảnh mượn được — video liên tục có đồng hồ, hostname, số **nhảy thật** thì không |
| **giọng của chính bạn** | AI làm được file; AI không giải thích thay bạn được |
| **≥ 6 phút** | đủ dài để không thể đọc một bản tóm tắt rồi xong |

**Hệ quả thực tế:**

- **Đáng quay dù nhìn tầm thường:** đồng hồ menu bar trong khung · số Activity Monitor nhảy trong lúc
  chạy · bạn kể **một lỗi bạn từng mắc** và vì sao · gõ lệnh rồi để nó chạy ra kết quả.
- **Nhìn oách mà gần như không tính:** slide · nhạc · đọc to báo cáo · zoom vào dashboard đẹp.

Nếu người chấm chỉ hỏi một câu sau khi xem, nó là: *"em có thật sự chạy cái này, và có hiểu số này
không?"* Mọi thứ trong kịch bản phục vụ đúng câu đó.

---

## Đường đi của dữ liệu — nói ở đầu video, 30 giây

Nói cái này TRƯỚC khi mở file nào. Không có nó thì người xem không biết mỗi file đứng ở đâu.

```
  tools/gen-test-plans.py          ← script Python. KHÔNG test gì. Nó VIẾT RA file.
            ↓  npm run plans
  test-plans/*.jmx  (4 file XML)   ← "đề bài" cho JMeter: gọi endpoint nào, bao nhiêu VU
            ↓  jmeter -n -t <file>
  JMeter                           ← NGƯỜI ĐI THI. Bắn request thật vào SUT
            ↓
  results/jtl/*.jtl                ← sổ ghi thô: MỖI request một dòng, kèm thời gian phản hồi
            ↓  npm run summary
  results/summary.md               ← p95 / p99 / error rate
            ↓
  report/main-report.md            ← số trong báo cáo
```

**[NÓI]** *"Em nói trước đường đi này để anh/chị biết mỗi file đứng ở đâu. Chỉ có JMeter là thứ thật
sự đo. Mọi script khác của em làm ba việc: **viết đề bài** cho JMeter, **dọn dẹp** trước khi đo, và
**đọc lại** sổ ghi thô sau khi đo."*

---

## Chuẩn bị trước khi bấm ghi

| Việc | Chi tiết |
|---|---|
| Cửa sổ | Terminal **phải**, Activity Monitor **dưới** (tab CPU, ô tìm gõ `node`), VS Code **trái** |
| Activity Monitor | **View → Update Frequency → Very often (1s)** |
| SUT | `cd eshop-sut/backend && node server.js` ở tab riêng, để thấy được |
| Cỡ chữ Terminal | ≥ 16pt |
| Đóng | Zalo, Mail, Discord, mọi tab riêng tư — menu bar sẽ nằm trong khung |
| Ghi | QuickTime → New Screen Recording → **Options → Microphone** |
| Thử | Quay 20 giây, **nghe lại**. Sai mic là mất cả 10 phút |

---

## 0:00 – 0:50 · Mở đầu + đường đi dữ liệu

**[NÓI]** *"Em là Lê Nhựt Duy, MSSV 23127178, HW05 Performance Testing trên EShop backend API."*

**[LÀM]** Vẽ/đọc sơ đồ đường đi ở trên.

**[NÓI]** *"Em đi theo **file**. Với mỗi file em nói ba điều: nó **không** làm gì, nó **làm** gì, và
**thiếu nó thì hỏng ở đâu**. Vì bài này có 15 lỗi kỹ thuật bị bắt trong quá trình làm, và phần lớn
công cụ ở đây sinh ra đúng để chặn những lỗi đó."*

---

## 0:50 – 2:30 · Nhóm 1 — File **viết ra đề bài** cho JMeter

### `tools/gen-test-plans.py`

**[NÓI — nói thẳng, đừng vòng]** *"File này **không test gì cả**. Nó là **máy đánh máy**: chạy nó thì
**không có một request nào được gửi đi**. Nó chỉ viết ra 4 file XML — cái mà JMeter sẽ đọc."*

**[LÀM]** Mở file, chỉ vào **dòng 29** (`WORKFLOW`) rồi **dòng 108** (`SCENARIOS`).

**[NÓI]** *"Cả file 480 dòng nhưng chỉ có hai chỗ đáng nhìn. Dòng 29: **6 bước** của luồng admin —
login, xem đơn, xem user, import sản phẩm, đổi trạng thái đơn, và một nhánh login sai mật khẩu.
Dòng 108: tham số tải của 4 scenario — Load 20 VU, Stress tăng bậc 25→50→100→200, Spike 10 VU nền rồi
dội 200 VU trong 5 giây, Soak 20 VU chạy 12 phút."*

**[GÕ]** `npm run plans`

**[NÓI]** *"Ra 4 file. Mỗi file khoảng 425 dòng XML."*

**[TÁC DỤNG — nói chậm, đây là chỗ dễ nói hỏng nhất]**

*"Bình thường người ta tạo file `.jmx` bằng **GUI của JMeter**, kéo thả chuột. Một file thì nhanh.
Nhưng bài này cần **4** file, và đề bắt cả 4 phải chạy **đúng cùng 6 bước** đó.*

*Nếu làm bằng GUI thì em sẽ dựng 1 file rồi copy ra 4, sửa số VU trong từng bản. Hôm sau phát hiện
bước 4 assert sai — **em phải sửa 4 chỗ**. Quên một chỗ thì Load và Stress **không còn đo cùng một
thứ nữa**, mà nhìn vào file XML 425 dòng thì **không ai thấy được**. Số vẫn ra, bảng so sánh vẫn vẽ
được — và bảng đó vô nghĩa.*

*Bài này đã bị đúng chuyện đó ở việc khác: em sửa lỗi 4xx cho nhánh lockout mà **quên** áp cho bước 5,
kết quả là báo **18% error** trên một hệ thống hoàn toàn khoẻ.*

*Nên: 6 bước viết **một lần**, ở một chỗ. Sửa một chỗ, chạy lại, cả 4 file đổi theo. **Không thể
quên — vì không có chỗ thứ hai để quên.**"*

**[LÀM — chứng minh 10 giây, thay cho mọi lời giải thích]**

**[GÕ]**
```bash
for f in test-plans/*.jmx; do
  echo "$(basename $f)  $(grep -oE 'name="HTTPSampler.path">[^<]*' $f | sed 's/.*>//' | sort -u | md5)"
done
```

**[NÓI]** *"Bốn dòng, **cùng một mã băm**. Tức danh sách endpoint của 4 plan **giống hệt nhau** —
không phải em nói, mà máy tính ra."*

### `test-plans/23127178_Load_20260813.jmx` — khối JSR223

**[LÀM]** Mở file, tìm `JSR223PostProcessor`.

**[NÓI]** *"Đây là mấy dòng Groovy. Nó gọi `prev.setSuccessful(true)` khi mã trả về là 400 của FR-10
hoặc 403 của lockout — tức **ép JMeter coi mấy mã đó là thành công**."*

**[TÁC DỤNG]** *"Vì sao phải ép: JMeter mặc định coi **mọi** mã 4xx là **thất bại**. Mà bài này có hai
loại 4xx là phản hồi **đúng**: 403 khi tài khoản bị khoá — đó là bảo mật hoạt động đúng; và 400 khi
đổi trạng thái đơn không hợp lệ — đó là state machine hoạt động đúng.*

*Chỗ khó là: em đã thử dùng assertion để nói 'mã này chấp nhận được', **nhưng không được** — assertion
chỉ **thêm** được lỗi, chứ **không xoá** được cờ thất bại JMeter đã gắn từ trước. Nên smoke test đầu
tiên báo **41% error** trên một hệ thống chạy hoàn toàn đúng. Em mất hai lượt chạy mới hiểu ra, và
đoạn Groovy này là cách sửa."*

### `data/` — 4 file CSV

**[GÕ]** `head -3 data/users.csv` rồi `cat data/users_lockout.csv`

**[NÓI]** *"50 tài khoản, mỗi VU một tài khoản riêng. Và một file **thứ hai** chỉ có 2 dòng mật khẩu
sai."*

**[TÁC DỤNG]** *"Hai file tách nhau vì bản đầu em để chung. Luồng chính đọc chính file đó, nên nó
**gặp 2 dòng sai mật khẩu và tự khoá tài khoản của mình** — 2,9% iteration thành rác. Tách file là để
dữ liệu test không tự đầu độc lượt chạy của nó."*

---

## 2:30 – 3:30 · Nhóm 2 — File **dọn dẹp trước khi đo**

**[NÓI]** *"Ba file này không đo gì. Chúng đưa hệ thống về trạng thái sạch trước khi đo."*

### `tools/preflight.mjs`

**[GÕ]** `npm run preflight`

**[NÓI]** *"Kiểm SUT có sống, CSV có đủ dòng, và Java nào đang chạy."*

**[TÁC DỤNG]** *"Dòng Java là dòng quan trọng. `java` mặc định trên máy em là Temurin 8 **x86_64** —
bản Intel, chạy qua Rosetta. Nếu JMeter chạy trên bản đó thì **chính JMeter thành điểm nghẽn**, và
mọi con số đo được là chi phí của công cụ đo, không phải của server. Preflight bắt chuyện đó **trước**
khi mất 6 phút chạy.*

*Bản đầu của file này còn có bug: nó đọc kết quả từ luồng ra chuẩn, trong khi lệnh in ra **luồng
lỗi**, nên nó báo `[OK] Java` với giá trị **rỗng** — báo xanh mà thực ra không kiểm gì."*

### `tools/reset-lockout.mjs` và `tools/reset-orders.mjs`

**[GÕ]** `node tools/reset-lockout.mjs` rồi `node tools/reset-orders.mjs`

**[NÓI]** *"Cái đầu đưa số lần đăng nhập sai về 0 cho mọi tài khoản. Cái sau đưa đơn hàng về trạng
thái `pending`."*

**[TÁC DỤNG]** *"Đề đòi **reset account lockout giữa các lượt** và ghi lại thủ tục. Cụ thể ở SUT này:
nó cộng số lần sai **2 đơn vị** mỗi lần — bug có từ bài trước — nên tài khoản bị khoá sau **2** lần
sai, không phải 3. Không reset thì lượt sau bắt đầu với tài khoản đang bị khoá, và toàn bộ 403 đó sẽ
bị đọc thành lỗi hiệu năng.*

*`reset-orders` thì vì bước 5 đi qua state machine: một đơn chỉ chuyển tiếp được **một lần** cho mỗi
trạng thái. Không reset thì từ lượt thứ hai nó trả 400 hết."*

---

## 3:30 – 5:40 · Nhóm 3 — **Chạy thật**, hai cửa sổ trong cùng khung

> Đoạn bắt buộc. Chọn **Spike** vì chỉ 4 phút và có khoảnh khắc rõ nhất.

### `tools/capture-run.sh`

**[GÕ]** `bash tools/capture-run.sh Spike`

**[NÓI]** *"Script này gọi JMeter chạy thật, đồng thời lấy mẫu CPU mỗi 2 giây, và **đếm ngược** tới
giây thứ 72 để nhắc em chụp ảnh."*

**[TÁC DỤNG]** *"Vì sao cần đếm ngược: cửa sổ cú sốc chỉ rộng **30 giây** — CPU lên 75% rồi tụt về 8%
trong khoảng 24 giây. Canh bằng mắt là trượt. Lần đầu em chụp được **34,9%** trong khi đỉnh thật là
**81,6%** — tức tấm ảnh **nói ngược** điều báo cáo nói. Script đếm từ lúc **JMeter thật sự bắt đầu**,
không phải từ lúc em bấm Enter."*

**[LÀM — đây là bằng chứng chính của cả video]** Đến mốc: **chỉ vào Activity Monitor**, đọc to số
`node` đang chạm ~72%. Giữ khung có **cả hai cửa sổ** vài giây. Đừng nói gì thêm, để người xem nhìn.

**[NÓI]** *"Đây đúng là tấm `activity-spike.png` trong bài nộp: ảnh đọc **72,6%**, còn tool đo đỉnh
**75,7%**. Hai nguồn độc lập, lệch 3 điểm."*

### `tools/sample-resources.sh`

**[GÕ]** `tail -3 results/resources/23127178_Spike_*.resources.csv`

**[NÓI]** *"Đây là file mà script vừa ghi song song: CPU và bộ nhớ của `node` **và** của JMeter, mỗi
2 giây, cộng cột tải nền của máy."*

**[TÁC DỤNG]** *"Tấm ảnh chỉ là **một lát cắt**; file này cho **cả đường cong**, nên tính được đỉnh.
Bản đầu nó bám sai tiến trình — lệnh tìm khớp cả cái **shell** đã khởi động backend — nên nó ghi bộ
nhớ 0,5 MB suốt 6 phút trong khi `node` thật đang ở 76 MB."*

---

## 5:40 – 7:20 · Nhóm 4 — File **đọc sổ ghi thô** (p95, p99, error rate)

### `tools/summarize-jtl.mjs`

**[GÕ]** `npm run summary` → mở `results/summary.md`

**[NÓI]** *"Đọc cả 13 file `.jtl` thô, tính ra bảng này."*

**[TÁC DỤNG]** *"Tác dụng: **không con số nào trong báo cáo được đếm bằng tay.** Mọi số trong báo cáo
truy được về file này, và file này truy được về `.jtl`. Đề có mục chống gian lận, và đây là cách em
trả lời mục đó."*

### `tools/ci-gate.mjs` — giải thích p95 / p99 / error rate

**[GÕ]** `node tools/ci-gate.mjs results/jtl/23127178_Stress_20260815-153717.jtl --p95 20`

**[NÓI]** chỉ tay vào từng số:
- *"**p95 = 18ms** — 95 phần trăm request nhanh hơn 18 mili-giây."*
- *"**p99 = 124ms** — nhưng 1% chậm nhất thì gấp **7 lần** con số vừa rồi."*
- *"**max = 3.691ms** — có request phải chờ **gần 4 giây**."*
- *"**avg = 9,6ms** — và đây là lý do **không được báo cáo bằng average**: p99 gấp **13 lần** avg, max
  gấp **205 lần** p95. Average xoá sạch cái đuôi, mà cái đuôi mới là chỗ người dùng thấy chậm."*

**[TÁC DỤNG — quan trọng nhất cả video, nói chậm]**

*"Giờ đến chỗ dễ hiểu sai nhất. Bài em ghi **error rate 0%** ở cả 4 lượt. Nhưng nhìn dòng mã trả về:
có **51.301 mã 400**.*

*Không mâu thuẫn. Test plan **cố ý** đánh dấu hai loại mã là thành công, vì chúng là phản hồi **đúng
đặc tả**: 400 khi state machine chặn một chuyển trạng thái không hợp lệ, và 401/403 của nhánh thử
lockout. Cái sai sẽ là 500 hoặc timeout — và **không có mẫu nào** như vậy.*

*Cổng này đọc **cột `success`** mà JMeter ghi, **không** tự suy từ mã HTTP. Nếu nó tự suy thì sẽ dựng
lại đúng cái lỗi 18% error rate em nói ở đầu video.*

*Và hệ quả phải nói ra: **539,7 request/giây là throughput của toàn bộ workflow HTTP, không phải của
giao dịch đổi trạng thái đơn hoàn tất.** Chỉ **400** request chạm được lệnh ghi thật; tải ghi thật của
bài đến từ bước **import sản phẩm**, không phải bước 5. Nói 539 giao dịch/giây là nói quá."*

### `tools/soak-drift.mjs`

**[GÕ]** `npm run drift`

**[TÁC DỤNG]** *"Tính độ trôi của p95 và bộ nhớ qua lượt Soak 12 phút, để chốt ngưỡng chịu đựng
**62,8 request/giây**. Em **cố ý không** gọi đó là *mức tối đa*, vì chính lượt Stress đã đạt **539,7**.
62,8 là mức em **đã xác nhận giữ ổn định 12 phút** ở 20 VU — muốn tìm mức tối đa thì phải tăng dần
nhiều bậc, việc đó em chưa làm và có ghi rõ.*

*File này cũng từng in **'trôi bộ nhớ +228,9%'** — đọc y như rò rỉ bộ nhớ — chỉ vì nó lấy mẫu đầu
**trước khi tiến trình khởi động xong**. So nửa đầu với nửa sau thì chỉ **+5%**."*

**[LÀM]** Mở `results/html/spike/index.html`, chỉ vào đồ thị response time theo thời gian. 15 giây.

---

## 7:20 – 8:50 · Nhóm 5 — **Agent Skills** (§7, end-to-end)

> Đoạn quyết định 10 điểm Agent Skills. Phải thấy **input → human review → output**.

**[NÓI]** *"Agent Skill là file hướng dẫn quy trình cho AI. Nó không phải prompt, mà là **checklist
bắt AI đi từng bước và dừng lại cho em duyệt**."*

### `.claude/skills/perf-test-plan/SKILL.md`

**[LÀM]** Mở file, cuộn qua 7 bước.

**[NÓI]** *"7 bước để thiết kế **một** test plan cho **một** nhóm endpoint, kèm checklist 8 mục phải
duyệt trước khi chạy."*

**[LÀM — chạy thật trên một nhóm endpoint hoàn chỉnh]** Gõ vào Claude Code:

```
Dùng skill perf-test-plan, thiết kế lượt Load cho endpoint group read-heavy
(GET /api/admin/orders và GET /api/admin/users). Đi từng bước, dừng ở bước
duyệt để tôi kiểm.
```

**[NÓI]** khi nó dừng *"Đây là **bước human review** — skill bắt dừng ở đây, không cho chạy tiếp. Em
kiểm think-time đặt ở phạm vi nào, vì lỗi số 6 của bài là timer đặt ở phạm vi thread group nên JMeter
chèn nó **5 lần mỗi vòng lặp** thay vì 1 lần — làm tải thực tế **nhẹ hơn thiết kế 5 lần**, mà plan
vẫn chạy bình thường, vẫn ra số, vẫn ra dashboard đẹp."*

**[LÀM]** Mở output nó sinh ra.

### `.claude/skills/jtl-analysis/SKILL.md`

**[LÀM]** Mở file, chỉ vào bảng các kiểu đọc sai metric. Rồi mở `report/main-report.md` mục 3.2.

**[NÓI]** *"Em cho AI phân tích `.jtl` **trước**, giữ nguyên văn trong báo cáo, rồi dùng skill này
soát lại — ra **7 lỗi**. Em đọc một lỗi."*

**[TÁC DỤNG]** *"AI nói p95 tăng *'có thể do database đã lớn hơn'*. Kiểm lại: database tăng **8%**,
còn tải nền của máy tăng **84%**. Nó chọn giả thuyết **nghe hợp lý** thay vì đọc cột tải nền mà chính
bộ tool của em đã ghi ra.*

*Và điều đáng nói nhất: **em cũng từng mắc đúng lỗi đó.** Mục 2.8 của báo cáo là mục em **thu hồi**
một kết luận của chính mình — em từng viết rằng dữ liệu lớn hơn làm hệ thống chậm đi, rồi một lượt
chạy sạch bác bỏ: database **lớn hơn 16 lần** mà **nhanh hơn 10 lần**. Em giữ mục đó lại dưới dạng
thu hồi thay vì xoá."*

**[NÓI nhanh]** *"Hai skill còn lại: `resource-evidence` quy định định dạng bằng chứng ảnh,
`ai-audit-logger` ghi mỗi lượt tương tác vào phụ lục — hiện **12 lượt**, mỗi lượt có prompt nguyên
văn và ô ghi rõ chỗ nào em **đã tự kiểm**, chỗ nào **chưa**."*

---

## 8:50 – 9:40 · Nhóm 6 — File **kiểm lại chính bài mình**

### `tools/verify-all.sh`

**[GÕ]** `npm run verify`

**[TÁC DỤNG]** *"Mọi tài liệu trong repo chỉ là **lời khẳng định**. Người chấm không có cách nào phân
biệt 'con số này đo được' với 'con số này được viết ra'. Script này đi ngược lại: **tính lại** từ
`.jmx`, `.jtl`, `.csv`, rồi **so với con số đang in trong báo cáo**. Lệch thì in FAIL kèm **cả hai
giá trị**. Nó không lấy số từ file markdown nào để tính."*

**[LÀM]** Chỉ vào mục 1 và mục 4.

**[NÓI]** *"Mục 1 rút danh sách endpoint của **từng** plan rồi so — sửa tay một plan là đỏ ngay. Mục 4
kiểm bằng chứng ảnh: giờ chụp mỗi ảnh phải nằm **trong khoảng lượt chạy**, lấy từ file dấu có kèm mã
băm, **không** lấy từ thời gian sửa file — vì lệnh copy khi đóng gói đặt thời gian mới, nên chạy
validator bên trong file zip sẽ báo đỏ mọi ảnh thật."*

### `bug-report/verify-bugs.sh`

**[GÕ]** `bash bug-report/verify-bugs.sh`

**[TÁC DỤNG]** *"Gọi request **thật** vào SUT để chứng minh lại 2 bug em báo. Dòng quan trọng nhất là
dòng **đối chứng**: gọi `/api/orders/1` không token trả **200**, còn `/api/orders/my-orders` không
token trả **401**. Không có dòng đối chứng thì bug chỉ là 'endpoint này không cần token' — có thể bị
phản biện là API vốn công khai. Có nó thì thành **một route bị bỏ sót**. Đã mở Issue **#288** và
**#289**."*

---

## 9:40 – 10:00 · Kết — Task 3 đã chạy thật

**[GÕ]** `gh run list --workflow=perf-smoke.yml`

**[NÓI]** *"Task 3 đề chỉ đòi **đề xuất trên giấy**. Em hiện thực nhánh PR pipeline thành GitHub
Actions thật và chạy **6 lượt**, trong đó **một lượt build đỏ** vì vượt ngưỡng."*

**[TÁC DỤNG — câu kết]** *"Và nó **không** xác nhận điều em dựng nó ra để xác nhận. Ba lượt **giống
nhau từng tham số** cho p95 **101, 15 và 8 mili-giây**. Cùng code, cùng ngưỡng — ngưỡng 8ms làm build
đỏ ở lượt này thì lượt kia vừa đủ xanh. Nên em **bỏ hẳn** ngưỡng p95 tuyệt đối trong đề xuất, chuyển
sang chặn bằng error rate và so thứ hạng endpoint **trong cùng một lượt**.*

*Kết quả đo **sửa lại đề xuất**, chứ không phải minh hoạ cho nó. Em xin hết."*

---

## Soát sau khi quay

| | |
|---|---|
| ☐ | Tổng thời lượng **≥ 6:00** (cộng dồn nếu chia clip) — kiểm bằng thanh thời gian |
| ☐ | Đoạn 3:30–5:40 thấy **rõ cả** Activity Monitor và Terminal |
| ☐ | Đã nói **vì sao 400/403 được đánh dấu thành công** |
| ☐ | Đã nói **cách reset lockout giữa các lượt** |
| ☐ | Có đoạn **Agent Skill end-to-end**, thấy bước human review |
| ☐ | Không cửa sổ riêng tư / thông báo nào lọt khung |
| ☐ | YouTube: **Unlisted**, KHÔNG phải Private |
| ☐ | Mở link ở cửa sổ ẩn danh để chắc người khác xem được |
| ☐ | Thêm **timestamp** vào description, nhất là mốc Agent Skill |

**Sau khi có link:** đưa link để dán vào `README.md`, `report/main-report.md`, `TASKS.md`, đổi Agent
Skills thành **10**, bỏ dấu `100*`, xoá mọi câu *"CHƯA CÓ"/"THIẾU"/"chờ quay"*, build lại PDF, đóng gói.

---

## Nếu quay quá dài — cắt theo thứ tự này

**Giữ bằng mọi giá:** đoạn chạy thật có Activity Monitor · giải thích 400/403 thành công · Agent Skill
end-to-end · reset lockout · giải thích p95/p99/error rate.

**Cắt được:** `soak-drift` (nói một câu thay vì chạy) · hai skill cuối · HTML dashboard · phần
`verify-bugs.sh` (bug report đã nộp kèm).
