# AI Critique — HW05 Performance Testing

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178

> §10 đòi một đoạn **200–300 từ** trả lời ba câu: AI sai ở đâu · vì sao nó không tự bắt được ·
> nguyên tắc rút ra. Đếm lại số từ:
> ```bash
> sed -n '/^## Critique/,$p' ai-audit/ai-critique.md | sed '1d' | wc -w
> ```

## Critique

AI Audit ghi mười bảy lỗi, nhưng chỉ **một loại** đáng viết. Nhiều lỗi lộ khi đối chiếu `.jtl`, code
và resource CSV: dữ liệu test tự khoá tài khoản, 4xx hợp lệ bị tính thành lỗi, số chép nhầm giữa hai lượt.

Ba lỗi còn lại cùng một hình dạng. Lần rõ nhất: AI so hai lượt cách nhau hai ngày, thấy p95 chênh
vài lần, kết luận **kích thước dữ liệu** là nguyên nhân, kèm cơ chế thuyết phục về SQLite một writer.
Nó gọi đó là "phát hiện quan trọng nhất của bài". Lượt sạch hôm sau bác bỏ: database lớn hơn mười sáu
lần mà p95 vẫn **thấp hơn** — 26 xuống 7ms. Biến tương quan mạnh nhất nằm ở cột `load_1m` mà AI tự
ghi ra nhưng không đọc — vẫn chưa đủ gọi là nguyên nhân.

Vì sao không tự bắt được? Vì cơ chế nó viện ra **đúng về lý thuyết** — SQLite thật sự có một writer.
Nhưng cơ chế đúng không chứng minh được nó gây ra con số đang xét.

Rút ra nguyên tắc cũng không bảo vệ được ai: lần thứ ba xảy ra **trong lúc đang viết mục này**. Đo
**một** lượt CI, AI viết ngay "runner chậm hơn local 12,6 lần". Ba lượt cùng cấu hình sau cho p95
101, 15 và 8ms — phương sai lớn hơn hiệu số nó vừa quy cho phần cứng.

Nghi ngờ mạnh nhất phải dành cho kết luận **nghe hay nhất**. Lỗi kỹ thuật tự lộ khi chạy; một giải
thích nhân quả sai sống lâu vì nó thoả mãn người đọc. Biết tên lỗi không ngăn được việc mắc nó — chỉ
thêm một điểm dữ liệu mới ngăn được.
