# AI Critique — HW05 Performance Testing

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178

## Critique

Trong bài này, AI giúp em tổng hợp log. Tuy nhiên, AI khá dễ
kết luận khi số liệu chưa đủ. Lỗi rõ nhất là khi nó so sánh hai lượt chạy cách nhau hai ngày, thấy
p95 chênh lệch rồi cho rằng nguyên nhân đến từ kích thước database. Giải thích về SQLite một writer
nghe hợp lý nên lúc đầu em gần như tin theo. Nhưng lượt chạy sau cho kết quả ngược
lại: database lớn hơn khoảng mười sáu lần mà p95 giảm từ 26ms xuống 7ms. Vì vậy kết luận trước đó
không đủ bằng chứng.

Theo em, AI không phát hiện lỗi này vì nó ưu tiên tạo một lời giải thích hợp lý từ kiến thức có sẵn,
thay vì kiểm tra các biến đã được kiểm soát hay chưa. Prompt ban đầu của em cũng chỉ yêu cầu phân
tích kết quả, chưa yêu cầu AI tìm giả thuyết ngược lại hoặc đề nghị chạy thêm để xác nhận.

Một lỗi tương tự xuất hiện với kết quả CI. Từ một lượt đo, AI nói runner chậm hơn máy local 12,6
lần. Ba lượt cùng cấu hình sau đó lại có p95 là 101, 15 và 8ms. Độ dao động giữa các lượt lớn hơn
chênh lệch mà AI vừa quy cho phần cứng.

Bài học em rút ra là không nên tin ngay một kết luận chỉ vì phần giải thích nghe hợp lý. Với
performance testing, em cần xem log gốc, ghi lại điều kiện chạy và có thêm lượt đo trước khi kết
luận nguyên nhân. AI phù hợp để gợi ý và hỗ trợ đọc dữ liệu, còn quyết định cuối cùng vẫn phải do em
tự kiểm chứng.
