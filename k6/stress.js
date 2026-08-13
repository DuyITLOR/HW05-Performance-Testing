// stress.js — bản k6 của scenario Stress. Bậc tải khớp 23127178_Stress_20260813.jmx.
//
//   k6 run --summary-export k6/summary-stress.json k6/stress.js
//
// Tăng theo BẬC, không tăng một phát: mục đích là tìm ĐIỂM gãy (mức VU nào error rate bật lên),
// chứ không phải chỉ biết rằng có gãy. Nhảy thẳng lên 200 VU thì mọi thứ đổ vỡ cùng lúc và
// không còn quy được nguyên nhân cho mức tải nào.

import { workflow, uniform } from './workflow.js';

export const options = {
  stages: [
    { duration: '30s', target: 25 },
    { duration: '90s', target: 25 },
    { duration: '30s', target: 50 },
    { duration: '90s', target: 50 },
    { duration: '30s', target: 100 },
    { duration: '90s', target: 100 },
    { duration: '30s', target: 200 },
    { duration: '90s', target: 200 },
    { duration: '30s', target: 0 },
  ],
  // KHÔNG đặt threshold fail cho stress test: mục đích của nó là chạm giới hạn, nên "vượt
  // ngưỡng" ở đây là kết quả mong đợi, không phải tín hiệu sai.
};

const think = uniform(0.5, 1);

export default function () {
  workflow(think);
}
