# k6/ — bản mirror bằng k6 (bonus §8)

§8 nói: *"JMeter (default) or k6 (bonus)"*. Bài này **lấy JMeter làm bản chính** vì §14 và §11
đòi đích danh những thứ chỉ JMeter sinh ra:

- `.jmx` đặt tên theo `{StudentID}_{ScenarioType}_{YYYYMMDD}`
- **raw `.jtl`** nộp đầy đủ
- **HTML report folder**
- **3 listener khác loại** (Summary Report / Aggregate Report / View Results Tree)

k6 không có `.jtl` cũng không có listener; nộp k6 làm bản chính là tự đặt mình vào thế phải
thuyết minh "cái này tương đương" cho từng hạng mục §11 kiểm tay. Vì thế k6 ở đây là **bản đối
chiếu chéo**, không thay thế.

## k6 dùng để làm gì trong bài này

Đối chiếu chéo một câu hỏi cụ thể: **p95 đo được có phải do JMeter tự nó là điểm nghẽn?**

JMeter là một thread JVM cho mỗi VU; k6 là goroutine, nhẹ hơn nhiều lần. Nếu cùng một mức tải mà
k6 báo p95 thấp hơn JMeter đáng kể, thì phần chênh đó là chi phí của load generator, **không**
phải của server. Đó là một lập luận kiểm chứng được cho phần Task 2, không phải chỉ là "làm thêm
cho có bonus".

## Chạy

```bash
k6 run --summary-export k6/summary-load.json k6/load.js
k6 run --out csv=k6/raw/load.csv k6/load.js       # CSV để so với .jtl
```

`k6/raw/*.json` và `*.ndjson` bị .gitignore: `--out json` ghi một dòng JSON cho **mỗi** metric
point, một lượt 10 phút phình lên hàng trăm MB. Giữ lại `--summary-export` + CSV là đủ để đối
chiếu.

## File

| File | Tương ứng scenario |
|---|---|
| `load.js` | <!-- TODO --> |
| `stress.js` | <!-- TODO --> |
| `spike.js` | <!-- TODO --> |

> Viết k6 script **sau khi** JMeter plan đã xong và đã review. Làm ngược lại thì hai bản lệch
> nhau về tham số và không còn so sánh được — mất luôn giá trị duy nhất của việc chạy hai tool.
