# AI Critique — HW05 Performance Testing

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178

> §10 đòi một đoạn **200–300 từ** trả lời ba câu: AI sai ở đâu · vì sao nó không tự bắt được ·
> nguyên tắc rút ra. Đếm lại số từ:
> ```bash
> sed -n '/^## Critique/,$p' ai-audit/ai-critique.md | sed '1d' | wc -w
> ```

## Critique

AI sai mười sáu lần, nhưng chỉ **một loại** lỗi đáng viết ra. Mười ba lỗi là kỹ thuật: dữ liệu
test tự khoá tài khoản của chính nó, 4xx hợp lệ bị tính thành lỗi hiệu năng. Chúng lộ ra ngay khi
đọc `.jtl`.

Ba lỗi còn lại cùng một hình dạng. Lần rõ nhất: AI so hai lượt cách nhau hai ngày, thấy p95 chênh
vài lần, kết luận **kích thước dữ liệu** là nguyên nhân, kèm cơ chế thuyết phục về SQLite một writer.
Nó gọi đó là "phát hiện quan trọng nhất của bài" và đưa lên headline README. Lượt sạch hôm sau
bác bỏ: database lớn hơn mười sáu lần mà nhanh hơn mười lần.
Biến thật nằm ở cột `load_1m` mà AI tự ghi ra nhưng không đọc.

Vì sao không tự bắt được? Vì cơ chế nó viện ra **đúng về lý thuyết** — SQLite thật sự có một
writer. Nhưng cơ chế đúng không chứng minh được nó gây ra con số đang xét.

Và rút ra nguyên tắc thì không bảo vệ được ai: lần thứ ba xảy ra **trong lúc đang viết mục này**. Đo
**một** lượt CI, AI viết ngay "runner chậm hơn máy local 12,6 lần". Ba lượt cùng cấu hình sau đó cho
p95 101, 15 và 8ms — phương sai lớn hơn hiệu số nó vừa quy cho phần cứng.

Nghi ngờ mạnh nhất phải dành cho kết luận **nghe hay nhất**. Lỗi kỹ thuật tự lộ khi chạy; một giải
thích nhân quả sai sống lâu vì nó thoả mãn người đọc. Biết tên lỗi không ngăn được việc mắc nó — chỉ
thêm một điểm dữ liệu mới ngăn được.
