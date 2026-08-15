# AI Audit Report — HW05 Performance Testing

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178
- **Bài:** HW05-AI Performance Testing — **AI Policy:** Open (§9 bắt buộc có phụ lục này)

> **I use AI tools for the following tasks.**

| AI tool | Model | Dùng cho |
|---|---|---|
| Claude Code | Opus 5 (1M context) | Chọn phạm vi endpoint (§5) · dựng repo + tooling · sinh 4 test plan JMeter · bản mirror k6 · phân tích `.jtl` · viết báo cáo |

> **§2 đòi dùng AI *"step by step, not with a single generic prompt"*.** File này ghi **prompt
> nguyên văn của sinh viên** — và những prompt đó ngắn. Bảy bước của quy trình được ghi riêng ở
> [`design-log.md`](design-log.md): mỗi bước hỏi gì, căn cứ nào, quyết ra sao, thay đổi cụ thể nào
> trong file. Hai file tách nhau **có chủ ý** — trộn lại thành "sinh viên đã hỏi bảy câu" sẽ là bịa,
> và §11 cấm đúng điều đó.
>
> **Ranh giới cần đọc trước khi chấm mục "human review":** các trường *AI sai / bỏ sót* dưới đây
> ghi lại những gì **phát hiện được trong phiên làm việc** (phần lớn qua smoke test và qua đọc
> lại code SUT). Trường **Human review** là phần sinh viên tự kiểm và tự chịu trách nhiệm —
> chỗ nào còn ghi *(sinh viên bổ sung)* là chỗ chưa được sinh viên ký nhận.

---

## Các lượt tương tác

### Interaction #1 — Chọn phạm vi endpoint (§5)
- **Task / Scenario:** §5 — chọn endpoint group, chống trùng trong nhóm
- **Bước trong quy trình:** trước `perf-test-plan` bước 1
- **AI tool:** Claude Code (Opus 5)
- **Date & time:** 2026-08-13 11:05
- **Prompt:**
  ```
  ngoài endpoint nhóm đã chọn thì bạn hãy chọn cho tui 1 vài endpoint đi
  (kèm 2 ảnh chụp chat nhóm: đăng ký endpoint của Nguyễn, Quan, Thế Đạt;
   kèm đề bài 2026.HW05.Performance Testing_En.pdf)
  ```
- **AI output (tóm tắt):** Đọc 31 route thật trong `backend/server.js`, đối chiếu với đăng ký của
  3 thành viên, kết luận toàn bộ luồng khách hàng đã bị chiếm → đề xuất workflow **admin
  back-office** 5 bước (`login` → `admin/orders` → `admin/users` → `import-products` →
  `orders/:id/status`) phủ đủ 3 nhóm. Kèm 5 endpoint bổ sung còn trống và 3 lưu ý về SUT
  (lockout kích hoạt sau 2 lần sai; không có rate limiting; `import-products` báo sai số dòng).
- **AI sai / bỏ sót:** **Một kết luận sai do chỉ đọc code, không chạy thử.** AI khẳng định
  `POST /api/admin/import-products` "báo số dòng đã insert nhỏ hơn thực tế" vì `stmt.finalize()`
  trả response trước các callback `stmt.run` ([`server.js:234`](../../eshop-sut/backend/server.js#L234)).
  Kiểm bằng request thật ở lượt #8 thì **sai hoàn toàn**: 5/5, 60/60, và 2/3 khi có dòng thiếu
  `name` — đều đúng, vì `node-sqlite3` xếp các lệnh trên cùng handle theo thứ tự và callback của
  `finalize` chạy sau chúng. Kết luận này đã lan vào 5 file tài liệu trước khi bị bắt.
- **Vì sao bỏ sót:** **chất lượng prompt và phương pháp** — prompt hỏi "đọc code và đề xuất
  endpoint", nên AI trả lời bằng suy luận từ code và trình bày suy luận đó như một sự thật đã
  kiểm. Không có bước nào bắt nó phân biệt "đọc được từ code" với "đã chạy thử".
- **Human review:** *(sinh viên bổ sung — cần xác nhận lại bảng đăng ký của nhóm khớp với chat,
  và tự đọc `server.js` ở 5 dòng được dẫn để kiểm chứng.)*
- **Commit:** `docs: playbook, agent skills and report scaffolding`

### Interaction #2 — Dựng repo và tooling
- **Task / Scenario:** hạ tầng bài làm
- **Bước trong quy trình:** trước `perf-test-plan` bước 1
- **AI tool:** Claude Code (Opus 5)
- **Date & time:** 2026-08-13 11:10
- **Prompt:**
  ```
  tham khảo các bài hw trc setup repo cho HW05 giùm tui
  ```
- **AI output (tóm tắt):** Đọc quy ước HW02/03/04 (`.gitignore`, `README` self-assessment,
  `tools/`, `.claude/skills/`), dựng repo HW05 cùng bộ khung + 9 script + 4 Agent Skill + 3 tài
  liệu docs + khung 5 tài liệu §14.
- **AI sai / bỏ sót:** **Một bug thật trong script do AI viết:** `preflight.mjs` đọc
  `/usr/libexec/java_home -V` từ **stdout**, nhưng lệnh này in ra **stderr** → script báo
  `[OK] Java (arm64)` với giá trị **rỗng**, tức là một lỗi im lặng: báo xanh trong khi không
  kiểm được gì. Đã sửa bằng hàm `shell()` gộp `2>&1` và đọc `os.arch` từ chính JDK.
- **Vì sao bỏ sót:** đặc điểm của công cụ — hành vi stdout/stderr của `java_home` không suy ra
  được từ ngữ nghĩa lệnh, phải chạy thử mới thấy.
- **Human review:** *(sinh viên bổ sung.)* Ghi chú kỹ thuật: sau khi sửa, preflight phát hiện
  đúng việc `java` trên PATH là Temurin 8 **x86_64** trong khi máy có Temurin 26 arm64.
- **Commit:** `test: environment checks and data-driven fixtures`

### Interaction #3 — Kế hoạch thực hiện
- **Task / Scenario:** lập kế hoạch
- **Bước trong quy trình:** —
- **AI tool:** Claude Code (Opus 5)
- **Date & time:** 2026-08-13 11:40
- **Prompt:**
  ```
  giờ tui phải làm j nữa
  ```
- **AI output (tóm tắt):** Danh sách 8 bước theo thứ tự ưu tiên theo trọng số điểm (Task 1 =
  60/100 nên làm trước), kèm lệnh cụ thể cho từng bước.
- **AI sai / bỏ sót:** —
- **Vì sao bỏ sót:** —
- **Human review:** *(sinh viên bổ sung.)*
- **Commit:** —

### Interaction #4 — Sinh 4 test plan và chạy
- **Task / Scenario:** Load · Stress · Spike · Soak
- **Bước trong quy trình:** `perf-test-plan` bước 1→7
- **AI tool:** Claude Code (Opus 5)
- **Date & time:** 2026-08-13 12:00
- **Prompt:**
  ```
  hãy thực hiện toàn bộ giùm tui
  ```
- **AI output (tóm tắt):** Cài JMeter, seed 50 tài khoản + 430 order + 3 file CSV, viết
  `tools/gen-test-plans.py` sinh 4 `.jmx` từ **một** định nghĩa workflow dùng chung (§6 đòi 3
  plan cùng workflow), chạy smoke test 20s, sửa lỗi, rồi chạy 3 lượt chính + soak.
- **AI sai / bỏ sót:** **Hai lỗi thật trong test plan do AI sinh, smoke test mới lộ ra:**
  1. **Nhánh lockout bị tính thành lỗi hiệu năng.** AI gắn assertion regex `40[13]` cho request
     đăng nhập sai mật khẩu và tưởng thế là đủ. Nhưng JMeter mặc định coi mọi 4xx là Fail, và
     assertion chỉ **thêm** được lỗi chứ không **xoá** được cờ Fail. Kết quả smoke test:
     **41,38% error** trong khi SUT hoạt động hoàn toàn đúng. Sửa bằng `JSR223PostProcessor`
     (Groovy) gọi `prev.setSuccessful(true)` khi mã trả về khớp `40[13]`.
  2. **Bước 5 assert cứng HTTP 200, không tính tới state machine.** `PUT /api/admin/orders/:id/status`
     đi qua FR-10 (`server.js:537-551`): một order chỉ chuyển tiếp được **một lần** cho mỗi
     trạng thái, nên từ lần lặp thứ hai trở đi SUT trả 400 "invalid transition" — đúng đặc tả.
     AI còn xen kẽ `shipping` trong `orders.csv`, mà từ `pending` thì `shipping` là chuyển đổi
     **không hợp lệ** → một nửa sample của bước 5 trả 400 ngay từ đầu. Sửa: assert `200|400`
     kèm giải thích, `orders.csv` chỉ dùng `confirmed`, và thêm `tools/reset-orders.mjs` đưa
     order về `pending` trước mỗi lượt.
- **Vì sao bỏ sót:** cả hai đều thuộc nhóm **đặc điểm của endpoint**, không phải giới hạn model:
  hành vi "assertion không xoá được cờ Fail" là chi tiết của JMeter chỉ hiện ra khi chạy, và
  state machine FR-10 nằm trong code SUT chứ không nằm trong đặc tả API. Prompt cũng chưa nêu
  hai điều này — nên có phần lỗi ở chất lượng prompt.
- **Human review:** *(sinh viên bổ sung.)* Ghi chú: cả hai lỗi đều được phát hiện nhờ **chạy
  thử 20 giây trước khi chạy lượt 6 phút** — nếu bỏ bước smoke test thì đã có 3 lượt chính với
  error rate vô nghĩa và phải chạy lại toàn bộ.
- **Commit:** `test(plans): generate the four JMeter plans from one shared workflow`

### Interaction #5 — Hai lỗi nữa chỉ lượt chạy dài mới lộ ra
- **Task / Scenario:** Load (lượt chạy thật đầu tiên, đã **huỷ giữa lượt**)
- **Bước trong quy trình:** `perf-test-plan` bước 6→7 (chạy và đọc kết quả trước khi tin nó)
- **AI tool:** Claude Code (Opus 5)
- **Date & time:** 2026-08-13 12:21
- **Prompt:** cùng lượt #4 — đây là phần đọc kết quả và sửa, không phải prompt mới.
- **AI output (tóm tắt):** Lượt Load chạy được, nhưng error rate đứng ở ~2,9% và throughput chỉ
  ~10 sample/s. Phân tích `.jtl` đang ghi cho thấy hai nguyên nhân độc lập nhau.
- **AI sai / bỏ sót:**
  3. **Dữ liệu test tự đầu độc lượt chạy.** `data/users.csv` do AI sinh có 2 dòng cuối dùng
     `WrongPassword!` (ý ban đầu là để test lockout). Nhưng thread group chính đọc chính file đó
     với `recycle=true`, nên nó cũng gặp 2 dòng ấy → login 401 → **hai tài khoản bị khoá 180s**
     → mọi lần đọc lại 2 dòng đó trả 403, và vì không có token nên **cả 4 bước còn lại của
     iteration đó cũng 403**. Đó chính là toàn bộ ~2,9% error: đúng 9 lần × 5 label. Không một
     sample nào trong số đó nói gì về hiệu năng của SUT. Sửa: `users.csv` chỉ còn tài khoản
     đăng nhập được; nhánh lockout tách sang `data/users_lockout.csv`.
  4. **Think-time nhân 5 lần so với ý định.** AI đặt Uniform Random Timer 1000–3000ms ở scope
     **thread group**, mà JMeter chèn timer trước **từng** sampler — 5 lần một iteration, tức
     5–15 giây/iteration thay vì 1–3s. Hệ quả: 20 VU sinh ra ~10 sample/s thay vì ~60, nên
     "Load test 20 VU" thực chất đo một mức tải nhẹ hơn nhiều lần so với thiết kế. Sửa: chia
     lại còn 200–600ms mỗi bước để **tổng** mỗi iteration đúng 1–3s, giữ nguyên ngữ nghĩa
     "admin dừng giữa các màn hình".
- **Vì sao bỏ sót:** lỗi 3 là **chất lượng prompt** — không ai nói rõ "file dữ liệu của luồng
  chính không được chứa dòng âm tính". Lỗi 4 là **đặc điểm công cụ**: phạm vi tác dụng của timer
  trong JMeter là kiến thức phải có sẵn, và AI đã áp dụng sai một cách hoàn toàn im lặng — plan
  vẫn chạy, vẫn ra số, chỉ là đo sai mức tải.
- **Human review:** *(sinh viên bổ sung.)* Ghi chú: đã **huỷ lượt chạy** giữa đường và **xoá
  toàn bộ `.jtl` / dashboard / run-log** của nó thay vì giữ lại để báo cáo. Số liệu từ một lượt
  đã biết là sai thì không được xuất hiện ở đâu trong bài, kể cả kèm chú thích.
- **Commit:** `test(plans): stop the test data from poisoning its own run`

### Interaction #6 — Cùng một lỗi, lần thứ hai
- **Task / Scenario:** Load (lượt chạy thật thứ hai, cũng **huỷ giữa lượt**)
- **Bước trong quy trình:** `perf-test-plan` bước 7
- **AI tool:** Claude Code (Opus 5)
- **Date & time:** 2026-08-13 13:10
- **Prompt:** cùng lượt #4.
- **AI output (tóm tắt):** Sau khi sửa 4 lỗi trước, lượt Load chạy đúng 50 sample/s như thiết kế
  và 0% error trong 90 giây đầu. Nhưng error rate rồi leo lên **18,25%**.
- **AI sai / bỏ sót:**
  7. **Áp cơ chế đúng cho nhánh lockout mà quên áp cho bước 5.** Toàn bộ 667 sample "lỗi" là
     `400` của `PUT /api/admin/orders/:id/status` — tức phản hồi **đúng** của state machine
     FR-10 khi order đã chuyển trạng thái rồi. Assertion `200|400` pass, nhưng JMeter đã gắn cờ
     Fail cho 4xx từ trước và assertion không xoá được cờ đó — **đúng cơ chế đã phát hiện và đã
     sửa ở lượt #4 cho nhánh lockout**, chỉ là không nghĩ tới việc bước 5 cũng cần. Sửa: dùng
     lại `mark_expected_4xx("400")` cho bước 5.
- **Vì sao bỏ sót:** không phải giới hạn model cũng không phải đặc điểm endpoint — đây là
  **suy luận không được mang sang chỗ tương tự**. Đã hiểu đúng cơ chế ở một nơi mà không tự hỏi
  "chỗ nào khác trong plan cũng trả 4xx hợp lệ?".
- **Human review:** *(sinh viên bổ sung.)* Ghi chú: lỗi này là ví dụ rõ nhất cho việc **error
  rate là chỉ số phải nghi ngờ trước tiên**. 18% error trên một hệ thống đang hoàn toàn khoẻ —
  nếu tin con số đó thì báo cáo sẽ kết luận sai hoàn toàn về endpoint transactional.
- **Commit:** `test(plans): count the expected 400 from FR-10 as a pass`

### Interaction #7 — Lỗi trong chính tooling đo tài nguyên
- **Task / Scenario:** thu bằng chứng tài nguyên (§6)
- **Bước trong quy trình:** `resource-evidence` bước 2
- **AI tool:** Claude Code (Opus 5)
- **Date & time:** 2026-08-13 13:19
- **Prompt:** cùng lượt #4.
- **AI output (tóm tắt):** `tools/sample-resources.sh` lấy mẫu CPU/RSS của backend mỗi 2 giây để
  có số liệu tính được cho endurance threshold.
- **AI sai / bỏ sót:**
  8. **Bám vào tiến trình sai.** Script dùng `pgrep -f 'node server.js' | head -1`. Trên máy này
     pgrep khớp **hai** pid: tiến trình `/bin/zsh -c …` đã khởi động backend (chuỗi đó nằm trong
     command line của nó) và tiến trình `node` thật. `head -1` chọn cái shell → file CSV ghi
     **RSS 0,5 MB và CPU 0,0%** suốt 6 phút, trong khi `node` thật đang ở ~76 MB / ~18% CPU.
     Sửa: lọc theo token đầu của command line phải là `node`
     (`ps -Ao pid=,command= | awk '/[n]ode server\.js/ && $2 ~ /node$/ …'`).
- **Vì sao bỏ sót:** **đặc điểm môi trường**. `pgrep -f` khớp trên toàn bộ command line, nên một
  shell wrapper chứa cùng chuỗi cũng khớp — điều này chỉ hiện ra khi backend được khởi động qua
  wrapper, đúng như cách phiên làm việc này khởi động nó.
- **Human review:** *(sinh viên bổ sung.)* Ghi chú: file tài nguyên của lượt **Load** và
  **Stress** đầu tiên vì thế **vô giá trị ở các cột `node_*`** (cột `java_*` của JMeter vẫn
  đúng). Đã chạy lại hai lượt đó sau khi sửa, thay thế toàn bộ `.jtl`/dashboard/resources — chứ
  không giữ lại kèm chú thích "cột này không dùng được".
- **Commit:** `test: sample CPU and RSS through each run`

### Interaction #8 — Kiểm bug bằng request thật, và một kết luận bị bác bỏ
- **Task / Scenario:** bug report
- **Bước trong quy trình:** `jtl-analysis` bước 3 (phân loại phát hiện: kiểm được hay không)
- **AI tool:** Claude Code (Opus 5)
- **Date & time:** 2026-08-13 13:58
- **Prompt:** cùng lượt #4.
- **AI output (tóm tắt):** Viết `bug-report/verify-bugs.sh` chạy lại từng bằng chứng, rồi thực
  thi trên SUT đang chạy.
- **AI sai / bỏ sót:**
  9. **Một "bug" AI khẳng định từ lượt #1 bị bác bỏ khi chạy thử.** AI đã nói
     `POST /api/admin/import-products` "báo số dòng đã insert nhỏ hơn thực tế" vì
     `stmt.finalize()` trả response trước các callback `stmt.run`
     ([`server.js:234`](../../eshop-sut/backend/server.js#L234)). Kiểm bằng ba lô request thật:
     5/5, 60/60, và 2/3 khi có một dòng thiếu `name` — **cả ba đều đúng**. `node-sqlite3` xếp
     các lệnh trên cùng handle theo thứ tự và callback của `finalize` chạy sau chúng.
     Kết luận sai này đã lan vào **5 file** (bug report, endpoint-selection, PLAYBOOK, SKILL
     perf-test-plan, chú thích trong `gen-test-plans.py` và `k6/workflow.js`) trước khi bị bắt.
- **Vì sao bỏ sót:** **phương pháp**, không phải model. Suy luận từ code nghe rất hợp lý và có
  kèm số dòng cụ thể, nên nó được ghi lại như một sự thật đã kiểm. Không có bước nào bắt phải
  phân biệt *"đọc được từ code"* với *"đã chạy và thấy"*.
- **Human review:** *(sinh viên bổ sung.)* Ghi chú: bug report giữ lại mục này ở phần **"Ứng
  viên đã LOẠI"** kèm bảng ba lô kiểm chứng, chứ không xoá đi. Một nhận định sai đã đi vào tài
  liệu thì việc ghi lại vì sao nó sai có giá trị hơn là làm như chưa từng có nó.
- **Commit:** `docs(bug): verify each finding, and retract the one that failed verification`

### Interaction #9 — Batch sạch bác bỏ phát hiện của chính lượt trước
- **Task / Scenario:** cả 4 scenario, batch 15/08
- **Bước trong quy trình:** `jtl-analysis` bước 2 (soát lỗi đọc metric) — lần này soát chính mình
- **AI tool:** Claude Code (Opus 5)
- **Date & time:** 2026-08-15 15:05
- **Prompt:**
  ```
  làm đi
  ```
  *(tiếp nối "okay sửa cho tui đi" — chạy lại batch sạch để `.jmx` khớp `.jtl` sau khi sửa lỗi #11)*
- **AI output (tóm tắt):** Batch 15/08 cho p95 Stress **7ms** — trong khi batch 14/08 cho **70ms** với
  cùng test plan. Kiểm `load_1m` trong file resources thì thấy nguyên nhân, và nó không phải nguyên
  nhân đã viết trong báo cáo.
- **AI sai / bỏ sót:**
  12. **Kết luận nhân quả từ một so sánh không kiểm soát biến nào.** Báo cáo từng có mục §2.8 mang tên
      *"phát hiện quan trọng nhất của bài"*: so hai batch, thấy p95 chênh 2,4–6,4 lần, kết luận
      **kích thước dữ liệu** là nguyên nhân, kèm cơ chế nghe rất hợp lý (SQLite một writer). Batch
      15/08 bác bỏ: database **lớn hơn 16 lần** (50k → 830.139 dòng) mà **nhanh hơn ~10 lần**. Biến
      thật là `load_1m` — batch 13/08 chạy khi máy gánh 1,3–2 lần tải nền, nhất quán trên cả 4 lượt.
      Lúc đo vẫn có 4 container Docker, VS Code và một tiến trình AI agent chạy song song.
      Kết luận sai đó đã lan tới: **headline README**, **một nhánh flow chart Task 3**, và một dòng
      **self-assessment** khoe rằng bài tự chỉ ra lỗ hổng của chính nó bằng số đo.
- **Vì sao bỏ sót:** **phương pháp** — cùng loại lỗi #9 nhưng nặng hơn. Ở #9 tôi trình bày một suy
  luận từ code như sự thật đã kiểm. Ở đây tôi có **dữ liệu thật**, nhưng dữ liệu đó đến từ hai lượt
  chạy khác nhau ở **nhiều biến cùng lúc**, và tôi quy toàn bộ chênh lệch cho một biến tôi thấy thú
  vị. Một cơ chế đúng về lý thuyết (SQLite một writer) không chứng minh được nó là nguyên nhân của
  con số cụ thể này — hai việc khác nhau, và tôi đã trộn.
- **Human review:** *(sinh viên bổ sung.)* Ghi chú: §2.8 được **viết lại thành mục thu hồi** chứ không
  xoá đi, vì bản thân việc bác bỏ nó là nội dung có giá trị nhất cho Task 2 — nó là một lỗi đọc metric
  thật, có bằng chứng, do chính người viết bắt.
- **Commit:** `docs: retract the data-growth finding the new batch disproves`

### Interaction #10 — Tool của tôi in ra một con số dẫn tới kết luận sai
- **Task / Scenario:** Soak, batch 15/08 15:52
- **Bước trong quy trình:** `jtl-analysis` bước 4 (chốt endurance threshold)
- **AI tool:** Claude Code (Opus 5)
- **Date & time:** 2026-08-15 16:10
- **Prompt:** *(tiếp nối lượt #9 — phần đọc kết quả sau khi batch cuối chạy xong)*
- **AI output (tóm tắt):** `soak-drift.mjs` in `Trôi RSS +228,9%` cho lượt Soak, kèm kết luận
  "ỔN ĐỊNH" ở phần p95.
- **AI sai / bỏ sót:**
  13. **Tool tự viết in ra một tỉ lệ so hai trạng thái khác nhau.** `Trôi RSS` được tính bằng
      **mẫu cuối chia mẫu đầu**, mà mẫu đầu (19,7 MB) lấy lúc process chưa warm-up xong. Ra
      **+228,9%** — đọc như một vụ rò rỉ bộ nhớ. Sự thật: RSS leo lên ~78 MB trong 60 giây ramp-up
      rồi **phẳng suốt 12 phút**; so nửa đầu với nửa sau chỉ **+5,0%** (74,5 → 78,3 MB).
      Nếu tin con số tool in ra thì báo cáo sẽ kết luận "có rò rỉ" trên một hệ thống hoàn toàn ổn định.
- **Vì sao bỏ sót:** **đặc điểm dữ liệu** — chuỗi đo có một giai đoạn warm-up ở đầu, và mọi phép so
  "đầu với cuối" trên chuỗi như vậy đều sai. Lỗi cùng họ với #12: so hai thứ không cùng loại rồi gọi
  kết quả là "độ trôi". Khác #12 ở chỗ lần này biến gây nhiễu nằm **bên trong chính lượt đo**, không
  phải ở môi trường.
- **Human review:** *(sinh viên bổ sung.)* Ghi chú: đã sửa tool để in **nửa đầu / nửa sau**, và giữ
  lại dòng mẫu-đầu→mẫu-cuối kèm cảnh báo ngay dưới nó, để lần sau không ai đọc nhầm lần nữa.
- **Commit:** `test(soak): compare like with like when reporting RSS drift`

<!-- NEW_INTERACTION_MARKER -->

---

## Tổng hợp — AI sai gì trên toàn bài

| # | Lượt | AI sai / bỏ sót | Nhóm lý do (§6) | Đã sửa thành |
|---|---|---|---|---|
| 1 | #2 | `preflight.mjs` đọc `java_home -V` từ stdout trong khi lệnh in ra stderr → báo `[OK]` với giá trị rỗng (lỗi im lặng) | đặc điểm công cụ | hàm `shell()` gộp `2>&1`, đọc `os.arch` trực tiếp từ JDK |
| 2 | #4 | Nhánh lockout: assertion regex đúng nhưng không xoá được cờ Fail của 4xx → smoke test báo 41,38% error trong khi SUT chạy đúng | đặc điểm endpoint | `JSR223PostProcessor` gọi `prev.setSuccessful(true)` cho `40[13]` |
| 3 | #4 | Bước 5 assert cứng 200, bỏ qua state machine FR-10 | đặc điểm endpoint | assert `200|400` + `reset-orders.mjs` + `orders.csv` chỉ dùng `confirmed` |
| 4 | #4 | `orders.csv` xen kẽ `shipping` — chuyển đổi không hợp lệ từ `pending` | đặc điểm endpoint | chỉ sinh `confirmed`, sửa cả trong `seed-perf-data.mjs` |
| 5 | #5 | `users.csv` chứa 2 dòng mật khẩu sai → luồng chính tự khoá tài khoản của mình, ~2,9% iteration vô giá trị | chất lượng prompt | tách `data/users_lockout.csv`, `users.csv` chỉ còn tài khoản hợp lệ |
| 6 | #5 | Timer ở scope thread group → think-time chèn 5 lần/iteration, tải thực tế nhẹ hơn thiết kế ~5 lần | đặc điểm công cụ | chia lại 200–600ms mỗi bước để tổng đúng 1–3s |
| 7 | #6 | Bước 5: 400 hợp lệ của FR-10 vẫn bị tính là lỗi → báo 18,25% error trên hệ thống khoẻ. Cùng cơ chế đã sửa ở lỗi #2 nhưng không mang sang | suy luận không mở rộng | dùng lại `mark_expected_4xx("400")` cho bước 5 |
| 8 | #7 | `sample-resources.sh` bám vào tiến trình `zsh` bao ngoài thay vì `node` → ghi RSS 0,5MB / CPU 0% suốt lượt chạy | đặc điểm môi trường | lọc theo token đầu command line phải là `node` |
| 9 | #8 | Khẳng định `import-products` báo sai số dòng insert — **bác bỏ** khi chạy thử (5/5, 60/60, 2/3 đều đúng). Đã lan vào 5 file | phương pháp: suy luận từ code trình bày như sự thật đã kiểm | giữ lại ở mục "đã loại" kèm bảng kiểm chứng; sửa lý do không assert theo `inserted` |
| 10 | #8 | `Math.min(...array)` trong `summarize-jtl.mjs` tràn call stack với `.jtl` 264k sample — chạy qua bình thường ở lượt Load 16k | đặc điểm dữ liệu (chỉ lộ ở file lớn) | thay bằng `reduce` |
| 11 | #8 | `mark_expected_4xx()` hardcode chữ *"Expected lockout response"*, dùng lại cho bước 5 mà quên đổi → raw `.jtl` ghi nhãn **"lockout"** cho ~50.000 sample của một endpoint không liên quan gì tới lockout | suy luận không mở rộng (cùng loại lỗi #7) | tham số hoá `reason`: bước 5 ghi *"FR-10 invalid transition"*, nhánh lockout ghi *"Account lockout"* |
| 12 | #9 | Kết luận **kích thước dữ liệu** gây suy giảm 2,4–6,4 lần, từ một so sánh hai batch không kiểm soát biến nào. Batch 15/08 bác bỏ: DB lớn hơn 16 lần mà nhanh hơn 10 lần; biến thật là `load_1m`. Đã lan tới headline README, flow chart Task 3, self-assessment | phương pháp: nhân quả từ tương quan không kiểm soát | §2.8 viết lại thành **mục thu hồi**, kèm 4 cặp `load_1m` làm bằng chứng |
| 13 | #10 | `soak-drift.mjs` tính "trôi RSS" bằng mẫu-cuối / mẫu-đầu, mà mẫu đầu lấy trước warm-up → in **+228,9%**, đọc như rò rỉ. Thực tế nửa-đầu/nửa-sau chỉ **+5,0%** | đặc điểm dữ liệu: chuỗi đo có warm-up ở đầu | so nửa đầu với nửa sau; giữ dòng cũ kèm cảnh báo |

**Nhận xét xuyên suốt:** 10 trong 13 lỗi **không làm test plan báo lỗi** — plan vẫn chạy, vẫn ra
`.jtl`, vẫn sinh dashboard đẹp. Chúng chỉ làm con số **sai**. Đó là lý do bước "đọc kết quả
trước khi tin nó" trong skill `perf-test-plan` không phải thủ tục hình thức: nếu chỉ kiểm "test
có chạy không" thì cả 10 lỗi này đều lọt.

**Chi phí thật của 13 lỗi:** hai lượt chạy phải huỷ và xoá bỏ toàn bộ bằng chứng, cộng khoảng 25
phút chạy lại. Nếu không đọc `.jtl` giữa lượt mà chờ đến khi viết báo cáo mới đọc, thì cái phải
làm lại là **cả bốn lượt cộng phần phân tích**.

> Bảng này chép sang [`report/main-report.md §2.4`](../report/main-report.md) — viết một lần,
> dùng hai chỗ.
