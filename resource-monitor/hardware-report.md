# Hardware report — HW05 Performance Testing

> Sinh tự động bởi `tools/hardware-report.sh` lúc **2026-08-13T04:29:33Z** (UTC).
> §11 kiểm hostname khớp với các HW trước — hostname ở dòng đầu bảng.

## Máy chạy test (load generator **và** SUT nằm cùng máy)

| Hạng mục | Giá trị |
|---|---|
| **Hostname** | `Le-Nhut-Duy.local` |
| User | `macos` |
| Model | Mac14,9 |
| CPU | Apple M2 Pro |
| Số lõi logic | 12 (performance: 8 · efficiency: 4) |
| RAM | 16 GB |
| Ổ đĩa (/) | 926Gi tổng, 247Gi trống |
| OS | macOS 26.1 (25B78) |
| Kernel | Darwin 25.1.0 arm64 |

## Công cụ

| Công cụ | Version |
|---|---|
| JMeter | **Apache JMeter 5.6.3** — đúng bản mặc định §8 · `jmeter -v` |
| Java **thực tế chạy JMeter** | openjdk version "26.0.1" 2026-04-21 · `os.arch = aarch64` · `JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-26.jdk/Contents/Home` |
| k6 (bonus) | k6 v2.1.0 (commit/devel, go1.26.4, darwin/arm64) |
| Node.js (backend SUT + tool) | v22.23.1 |

> **Cập nhật:** bảng trên ghi lại **sau khi** JMeter đã cài và đã chạy đủ 4 scenario. Bản đầu ghi
> *"JMeter | chưa cài"* vì hardware report được sinh **trước** khi cài công cụ, và dòng đó bị để
> nguyên qua nhiều vòng sửa — một dấu vết trạng thái cũ, do người review ngoài bắt được.
>
> **Vì sao dòng Java quan trọng hơn nó trông:** `java` mặc định trên PATH của máy này là Temurin 8
> **x86_64**, chạy qua Rosetta. Nếu JMeter chạy trên bản đó thì load generator tự nó thành điểm nghẽn
> và mọi số đo nhiễu. `tools/run-scenario.sh` **ép** `JAVA_HOME` sang JDK arm64 trước khi gọi
> `jmeter`, nên bản ghi ở đây là bản **thực tế đã dùng**, không phải bản mặc định của hệ thống. Lỗi
> #1 trong AI audit chính là chỗ này: `preflight.mjs` từng báo `[OK] Java` với giá trị **rỗng**.

## Điều phải nói rõ khi đọc mọi con số của bài này

Load generator (JMeter) và SUT (Node + SQLite) chạy **trên cùng một máy 16GB /
12 lõi**. Nghĩa là:

- Ở mức tải cao, JMeter và backend **tranh cùng số lõi đó**. Một phần latency đo được
  là chi phí của chính load generator, không phải của server. Đây là giới hạn phải
  khai báo, không phải thứ để che.
- Endurance threshold tìm ra vì thế là **ngưỡng của cấu hình "cùng máy" này**, không
  phải năng lực tối đa của backend nếu tách máy.
- Backend là Node **một process, một luồng JS** + SQLite ghi tuần tự → ngưỡng sẽ chạm
  ở mức thấp hơn kỳ vọng của một server production, và đó là kết quả đúng của SUT này.

## Ảnh bằng chứng

| Ảnh | File |
|---|---|
| Activity Monitor — lượt Load | `screenshots/activity-load.png` |
| Activity Monitor — lượt Stress | `screenshots/activity-stress.png` |
| Activity Monitor — lượt Spike | `screenshots/activity-spike.png` |
| Activity Monitor — lượt Soak | `screenshots/activity-soak.png` |
| Spec máy (screenfetch / About This Mac) | `screenshots/hardware-spec.png` |

> Mỗi ảnh phải có **JMeter và resource monitor trong CÙNG khung hình** (§6), và
> timestamp khớp dòng tương ứng trong [`results/run-log.md`](../results/run-log.md).
