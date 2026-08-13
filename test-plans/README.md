# test-plans/ — 3 test plan JMeter (§6)

Tên file **bắt buộc** theo `{StudentID}_{ScenarioType}_{YYYYMMDD}`, và §11 kiểm tay đúng cái tên
này:

```
23127178_Load_YYYYMMDD.jmx
23127178_Stress_YYYYMMDD.jmx
23127178_Spike_YYYYMMDD.jmx
23127178_Soak_YYYYMMDD.jmx      ← lượt endurance (§6), ngoài 3 plan bắt buộc
```

`tools/run-scenario.sh` tự tìm plan theo mẫu `23127178_<Scenario>_*.jmx` và lấy **bản mới nhất**
nếu có nhiều ngày. Vì thế đặt tên sai là script không thấy plan.

## Cả 3 plan phải chạy CÙNG một workflow

§6 nói rõ: *"All three test plans must exercise the same end-to-end workflow, covering all three
endpoint groups."* Chỉ **tham số tải** khác nhau, không được đổi endpoint giữa các plan — nếu
đổi thì không còn so sánh được Load với Stress với Spike.

Workflow: xem [`docs/endpoint-selection.md`](../docs/endpoint-selection.md).

## Ba listener khác loại (§6)

| Plan | Listener | Vì sao đặt ở đây |
|---|---|---|
| Load | Summary Report | tải ổn định → cần bảng tổng hợp gọn |
| Stress | Aggregate Report | cần percentile để thấy điểm gãy |
| Spike | View Results Tree | cần xem *nội dung* response lúc sốc — và chỉ an toàn ở lượt ngắn |

Lặp lại loại listener giữa hai plan là mất điểm mục này.

## Cách tạo

Dùng skill `/perf-test-plan` (7 bước). Đừng ra một prompt gộp kiểu "viết test plan load test cho
API này" — §2 cấm đích danh.
