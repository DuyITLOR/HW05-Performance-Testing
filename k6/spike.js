// spike.js — bản k6 của scenario Spike. Khớp 23127178_Spike_20260813.jmx.
//
//   k6 run --summary-export k6/summary-spike.json k6/spike.js
//
// Hai scenario chạy song song, đúng như hai thread group của bản JMeter:
//   baseline — 10 VU chạy xuyên lượt, để ĐO ĐƯỢC thời gian hồi phục sau cú sốc
//   spike    — 200 VU trong 5 giây rồi rút về 0
//
// Không có nhánh baseline chạy tiếp sau cú sốc thì không đo được hồi phục — chỉ thấy "lúc sốc
// thì chậm", vốn là điều hiển nhiên và không phải câu hỏi của spike test.

import { workflow, uniform } from './workflow.js';

export const options = {
  scenarios: {
    baseline: {
      executor: 'constant-vus',
      vus: 10,
      duration: '4m',
      exec: 'baseline',
    },
    spike: {
      executor: 'ramping-vus',
      startVUs: 0,
      startTime: '60s',
      stages: [
        { duration: '5s', target: 200 },
        { duration: '25s', target: 200 },
        { duration: '5s', target: 0 },
      ],
      exec: 'spike',
    },
  },
};

const thinkBaseline = uniform(0.5, 1.5);
const thinkSpike = uniform(0, 0.5);

export function baseline() {
  workflow(thinkBaseline);
}

export function spike() {
  workflow(thinkSpike);
}
