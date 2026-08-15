# AI Critique — HW05 Performance Testing

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178

> §10 đòi một đoạn **200–300 từ** trả lời ba câu: AI sai ở đâu · vì sao nó không tự bắt được ·
> nguyên tắc rút ra. Đếm lại số từ:
> ```bash
> sed -n '/^## Critique/,$p' ai-audit/ai-critique.md | sed '1d' | wc -w
> ```

## Critique

AI sai mười ba lần, nhưng chỉ một lỗi nghiêm trọng. Mười hai lỗi kia là kỹ thuật: think-time nhân
năm lần vì timer sai scope, dữ liệu test tự khoá tài khoản của chính nó, 4xx hợp lệ bị tính thành
lỗi hiệu năng. Chúng lộ ra ngay khi đọc `.jtl`.

Lỗi còn lại khác hẳn: AI so hai lượt chạy cách nhau hai ngày, thấy p95 chênh vài lần, rồi kết
luận **kích thước dữ liệu** là nguyên nhân — kèm cơ chế nghe rất thuyết phục về SQLite một writer.
Nó gọi đó là "phát hiện quan trọng nhất của bài", đưa lên headline README, dựng một nhánh flow chart
Task 3 dựa trên nó. Lượt chạy sạch hôm sau bác bỏ: database lớn hơn mười sáu lần mà nhanh hơn mười
lần. Biến thật là tải nền của máy, nằm sẵn ở cột `load_1m` mà AI đã tự ghi ra nhưng không đọc.

Vì sao nó không tự bắt được? Vì cơ chế nó viện ra **đúng về lý thuyết**. SQLite thật sự có một
writer. Nhưng cơ chế đúng không chứng minh được nó là nguyên nhân của con số đang xét — AI không phân
biệt hai việc đó, và không có phản xạ hỏi "hai lượt này còn khác nhau ở đâu nữa".

Nguyên tắc rút ra: nghi ngờ mạnh nhất phải dành cho những kết luận **nghe hay nhất**. Lỗi kỹ thuật
tự lộ ra khi chạy; một giải thích nhân quả sai thì sống rất lâu, vì nó thoả mãn người đọc. Bài này
giữ mục đó lại dưới dạng thu hồi thay vì xoá — vì chỗ đó mới là chỗ học được nhiều nhất.
