---
name: ai-audit-logger
description: Record every AI interaction into the mandatory AI Audit Report after an AI session. Use whenever the student chats with an AI tool while doing HW05 (designing test plans, generating .jmx, analysing .jtl logs, writing the continuous-performance proposal). Appends a structured entry (tool, date/time, prompt, output, human review) to ai-audit/ai-audit-report.md.
---

# AI Audit Logger Skill

HW05 có **AI Policy: Open** — bắt buộc có lời khai + AI Audit Report đầy đủ (§9). Thiếu bất kỳ
tài liệu bắt buộc nào là **0 điểm** (§17). Skill này lo phần ghi log để không sót lượt nào.

## Khi nào dùng
- Sau mỗi lượt hỏi AI liên quan tới HW05 (thiết kế scenario, sinh `.jmx`, phân tích `.jtl`,
  viết đề xuất continuous perf testing, viết báo cáo).
- Khi sinh viên nói "ghi audit", "log lượt này".

## Ghi gì cho mỗi lượt (§9)
1. **Tên AI tool** — kèm model (ví dụ `Claude Code (Opus 5)`, `ChatGPT`, `Gemini`).
2. **Ngày và giờ** — thời điểm thật; chỉ biết ngày thì ghi ngày.
3. **Prompt của sinh viên** — nguyên văn, trong code block.
4. **Output của AI** — đầy đủ, hoặc tóm tắt trung thực.
5. **Human review** — sinh viên đã kiểm/sửa gì. Phần này sinh viên tự viết.

## Riêng cho HW05 — ghi thêm 3 trường

HW05 chấm nặng phần "AI sai/bỏ sót gì và vì sao" ở **cả hai** Task (§6 với test plan, Task 2
với phân tích log), nên mỗi lượt cần thêm:

| Trường | Nội dung |
|---|---|
| **Bước trong quy trình** | Bước nào của skill `perf-test-plan` (1–7) hay `jtl-analysis` (0–4)? Ghi rõ để chứng minh dùng AI **từng bước**, không phải một prompt gộp — §2 cấm đích danh prompt kiểu *"chạy load test rồi cho tôi biết hiệu năng có tốt không"* |
| **AI sai / bỏ sót** | ramp-up không thực tế · thiếu think-time · sai số thread · assertion yếu · không xử lý account lockout · hard-code token · đọc average thay p95 · gộp 403 vào lỗi hiệu năng · đề xuất tối ưu không kiểm chứng được |
| **Vì sao bỏ sót** | prompt thiếu ngữ cảnh · giới hạn của model · đặc điểm của endpoint (đúng ba nhóm lý do §6 yêu cầu phân loại) |

Ba trường này chép thẳng được sang mục human review của `report/main-report.md` — viết một
lần, dùng hai chỗ.

## Quy trình
1. Mở `ai-audit/ai-audit-report.md`.
2. Tìm `Interaction #N` lớn nhất → lượt mới là `#N+1`.
3. Chèn ngay **phía trên** dòng `<!-- NEW_INTERACTION_MARKER -->`, theo đúng template:

   ```markdown
   ### Interaction #<N>
   - **Task / Scenario:** <Load | Stress | Spike | Soak | Task 2 phân tích | Task 3 đề xuất | Skills>
   - **Bước trong quy trình:** <perf-test-plan bước 2 | jtl-analysis bước 1 | ...>
   - **AI tool:** <tool + model>
   - **Date & time:** <YYYY-MM-DD HH:MM>
   - **Prompt:**
     ```
     <nguyên văn>
     ```
   - **AI output (tóm tắt):** <tóm tắt trung thực hoặc nguyên văn>
   - **AI sai / bỏ sót:** <...>
   - **Vì sao bỏ sót:** <prompt | model | đặc điểm endpoint>
   - **Human review:** <sinh viên đã kiểm và sửa gì>
   - **Commit:** <hash hoặc message của commit tương ứng, nếu có>
   ```
4. Giữ nguyên dòng khai báo `"I use AI tools for the following tasks."` ở đầu file.

## Riêng Task 2 — lưu output AI TRƯỚC khi soát

Task 2 chấm *"AI phân tích"* và *"mình soát lại"* thành hai mục riêng. Sửa output của AI rồi
mới lưu là làm mất vật chứng của mục thứ nhất, và mục thứ hai mất luôn đối tượng để soát.
Lưu nguyên văn trước, soát sau, ghi phần soát vào một block riêng.
