# AI Critique — HW05 Performance Testing

- **Sinh viên:** Lê Nhựt Duy — **MSSV:** 23127178

> §10 đòi một đoạn **200–300 từ** trả lời ba câu: AI sai ở đâu · vì sao nó không tự bắt được ·
> nguyên tắc rút ra. Đếm lại số từ:
> ```bash
> sed -n '/^## Critique/,$p' ai-audit/ai-critique.md | sed '1d' | wc -w
> ```

## Critique

AI sai bảy lần trong bài này, và điều đáng nói là **kiểu sai**: năm trong bảy lỗi không làm test
plan báo lỗi. Plan vẫn chạy, vẫn sinh `.jtl`, vẫn ra dashboard trông chuyên nghiệp — chỉ con số
là sai. Lỗi tệ nhất: AI đặt Uniform Random Timer ở scope thread group mà không tính rằng JMeter
chèn timer trước *từng* sampler, nên think-time thành 5–15 giây một iteration thay vì 1–3 giây;
"load test 20 VU" thực chất đo mức tải nhẹ hơn năm lần thiết kế. Lỗi thứ hai: AI để hai dòng mật
khẩu sai trong chính file dữ liệu của luồng chính, khiến luồng tự khoá tài khoản của mình. Và một
lỗi lặp lại: AI hiểu đúng rằng assertion không xoá được cờ Fail của 4xx, sửa cho nhánh lockout,
rồi quên áp cho bước 5 — báo 18,25% error trên hệ thống đang hoàn toàn khoẻ.

Vì sao nó không tự bắt được? Vì nó không có vòng phản hồi từ thực tế. Nó tối ưu cho plan *trông
đúng*, không phải plan *đo đúng*, và cả ba lỗi trên chỉ lộ ra khi đối chiếu `.jtl` với kỳ vọng.
Nó cũng không biết những thứ chỉ nằm trong code SUT: lockout kích hoạt sau hai lần sai, state
machine FR-10 chỉ cho chuyển tiếp một lần.

Nguyên tắc rút ra: chạy thử ngắn và **đọc log thô trước khi tin bất kỳ con số nào**. Tôi huỷ hai
lượt chạy và xoá sạch bằng chứng của chúng — số liệu đã biết là sai thì không được xuất hiện ở
đâu. AI dựng khung rất nhanh; quyết định con số nào đáng tin vẫn là việc của người làm.
