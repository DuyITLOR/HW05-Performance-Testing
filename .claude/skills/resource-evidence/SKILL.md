---
name: resource-evidence
description: Capture resource-monitor and hardware evidence for a performance run exactly as the assignment requires — tool and monitor in the same frame, hostname matching previous homework, timestamps that line up with the run log. Use before and during each Load/Stress/Spike/Soak run, and when preparing the demo video or checking that submitted evidence will survive TA verification.
---

# Resource Evidence Skill

§6 đòi ảnh bằng chứng, §11 nói TA **kiểm tay** chính những ảnh đó. Sai định dạng bằng chứng là
mất điểm mà không cách nào cứu, vì phải chạy lại mới có ảnh mới.

## Khi nào dùng
- Ngay trước và trong mỗi lượt chạy.
- Khi chuẩn bị quay video demo, hoặc soát lại bộ bằng chứng trước khi zip.

## Ba yêu cầu bắt buộc — đọc kỹ chữ

| Yêu cầu | Nguyên văn đề | Nghĩa là |
|---|---|---|
| Cùng khung hình | *"showing the tool and the resource monitor **in the same frame**"* | **một** ảnh/video chứa **cả hai**. Hai ảnh riêng ghép cạnh nhau **không** thoả |
| Hostname khớp | *"hardware report, whose hostname matches your previous homework deployments"* | `hostname` phải trùng HW02/03/04. Đổi máy giữa các HW là phải giải thích |
| Bằng chứng thật | *"must not be AI-generated or fabricated"* | timestamp trong ảnh phải khớp `results/run-log.md` |

## Quy trình cho mỗi lượt chạy

1. **Trước khi chạy** — mở Activity Monitor, tab CPU, sắp cạnh terminal sao cho **cả hai cửa
   sổ nằm trong một khung**. Lọc theo `node` để thấy process backend.

2. **Ghi mốc RSS đầu lượt** (cần cho endurance threshold):
   ```bash
   ps -o pid,rss,%cpu,command -p "$(pgrep -f 'node server.js' | head -1)"
   ```

3. **Chạy** — `bash tools/run-scenario.sh <Scenario>`. Script tự ghi mốc thời gian vào
   `results/run-log.md`; đó là thứ dùng để đối chiếu với ảnh.

4. **Chụp lúc tải cao nhất**, không phải lúc vừa bấm chạy:
   - Load: khoảng giữa lượt, khi đã ổn định
   - Stress: đúng bậc VU cao nhất
   - Spike: **trong lúc** đang sốc — chỉ có vài giây, chuẩn bị sẵn tay
   - Soak: hai ảnh — phút đầu và phút cuối (để thấy RSS có trôi)

   Lưu: `resource-monitor/screenshots/activity-<scenario>.png`

5. **Ghi mốc RSS cuối lượt** bằng đúng lệnh ở bước 2.

6. **Bảng spec phần cứng:**
   ```bash
   bash tools/hardware-report.sh          # → resource-monitor/hardware-report.md
   ```
   Kèm một ảnh spec (`screenfetch`/`neofetch`, hoặc  > About This Mac) →
   `resource-monitor/screenshots/hardware-spec.png`.

## Soát trước khi zip

- [ ] 4 ảnh Activity Monitor (load/stress/spike/soak), mỗi ảnh có **cả** JMeter và monitor
- [ ] 1 ảnh spec phần cứng
- [ ] `hardware-report.md` có bảng spec **và** hostname trùng HW trước
- [ ] Timestamp trong ảnh khớp dòng tương ứng ở `results/run-log.md`
- [ ] Video ≥6 phút, unlisted, thuyết minh tiếng Việt, hai thứ trong cùng khung
- [ ] Video mở đầu bằng `whoami` + `hostname` (cách HW04 đã dùng để xác thực tác giả)

## Đọc con số tài nguyên cho đúng

| Quan sát | Kết luận thường đúng | Đừng kết luận |
|---|---|---|
| `node` ~100% một lõi, các lõi khác rảnh | đã chạm giới hạn **một luồng JS** — đúng bản chất SUT | "CPU quá tải" (tổng CPU vẫn còn dư nhiều) |
| `java` (JMeter) ăn CPU cao hơn `node` | **load generator** là nút cổ chai, số đo không tin được | "server chịu tải tốt" |
| RSS `node` tăng đều suốt lượt soak | ứng viên rò rỉ bộ nhớ — cần đo lại để xác nhận | "rò rỉ bộ nhớ" ngay từ một lượt |
| Disk write dựng đứng lúc import | SQLite ghi tuần tự — đúng chỗ đã dự đoán | "ổ đĩa chậm" |
