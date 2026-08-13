// load.js — bản k6 của scenario Load. Tham số khớp 23127178_Load_20260813.jmx.
//
//   k6 run --summary-export k6/summary-load.json k6/load.js
//
// Mục đích của bản mirror này KHÔNG phải chạy lại cho có, mà để trả lời một câu cụ thể:
// p95 đo được có bao nhiêu phần là chi phí của chính load generator? JMeter cấp một thread JVM
// cho mỗi VU; k6 dùng goroutine, nhẹ hơn nhiều bậc. Cùng một mức tải mà k6 báo p95 thấp hơn
// đáng kể thì phần chênh đó thuộc về công cụ, không thuộc về server.

import { workflow, uniform } from './workflow.js';

export const options = {
  vus: Number(__ENV.VUS || 20),
  duration: __ENV.DURATION || '6m',
  // Ngưỡng lấy từ định nghĩa "ổn định" đã chốt TRƯỚC khi chạy (endurance/endurance-threshold.md).
  thresholds: {
    http_req_failed: ['rate<0.01'],
    step4_import_products: ['p(95)<1500'],
  },
};

const think = uniform(1, 3);

export default function () {
  workflow(think);
}
