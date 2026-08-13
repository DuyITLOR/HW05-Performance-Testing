# Agent Skills — HW05 Performance Testing

Bốn skill dùng cho bài này. §7 khuyến khích xây Agent Skill áp dụng được quy trình
performance-testing + phân tích log cho **các endpoint khác** về sau, và nộp kèm video demo
end-to-end trên **một endpoint group hoàn chỉnh**.

| Skill | Gọi khi nào |
|---|---|
| [`perf-test-plan`](skills/perf-test-plan/SKILL.md) | thiết kế + sinh một test plan mới (Load/Stress/Spike/Soak) — quy trình 7 bước, dùng AI **từng bước** (§2) |
| [`jtl-analysis`](skills/jtl-analysis/SKILL.md) | sau khi có `.jtl` — phân tích, chốt ngưỡng, và **bắt lỗi AI đọc sai metric** (Task 2) |
| [`resource-evidence`](skills/resource-evidence/SKILL.md) | thu bằng chứng tài nguyên + phần cứng đúng chuẩn §6/§11 |
| [`ai-audit-logger`](skills/ai-audit-logger/SKILL.md) | sau mỗi lượt hỏi AI — ghi vào AI Audit Report (§9) |

## Thứ tự dùng cho một endpoint group

```
/perf-test-plan            → 7 bước cho một scenario (lặp lại cho Load, Stress, Spike, Soak)
   ├─ Bước 6  →  /resource-evidence   (ảnh tool + monitor cùng khung, hardware report)
   ├─ sau khi chạy  →  /jtl-analysis  (đọc raw .jtl, chốt ngưỡng, bắt lỗi AI)
   └─ sau mỗi lượt hỏi AI  →  /ai-audit-logger
```

## Nguyên tắc chung của cả 4 skill

- **Từng bước, không prompt gộp.** §2 nói rõ: không ra một prompt kiểu *"chạy load test rồi
  cho tôi biết hiệu năng có tốt không"*. Dẫn AI qua từng bước của kỹ thuật như đã học.
- **Người duyệt từng bước.** Nộp thẳng output thô của AI là không được chấp nhận (§2).
- **Không bịa số liệu.** Mọi con số chỉ được lấy từ raw `.jtl` qua `npm run summary` (§11).
  Con số nào không truy được về một file `.jtl` cụ thể thì không được xuất hiện trong báo cáo.
- **Tách lỗi chức năng khỏi lỗi hiệu năng.** Trên SUT này, `403` gần như luôn là account
  lockout — một hành vi chức năng — chứ không phải server quá tải. Gộp hai thứ vào một con số
  "error rate" là sai bản chất, và đó chính là loại lỗi Task 2 chấm điểm.
