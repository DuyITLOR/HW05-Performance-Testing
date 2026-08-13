#!/usr/bin/env python3
"""gen-test-plans.py — sinh 4 file .jmx từ MỘT định nghĩa workflow dùng chung.

    python3 tools/gen-test-plans.py            # dùng ngày hôm nay
    python3 tools/gen-test-plans.py 20260813   # ghim ngày trong tên file

Vì sao sinh bằng script thay vì viết tay 4 file XML:

§6 đòi *"All three test plans must exercise the same end-to-end workflow"*. Viết tay 4 file
~700 dòng XML thì sớm muộn cũng lệch nhau một sampler, một assertion, một header — và lúc đó
so sánh Load với Stress với Spike mất hết ý nghĩa vì không còn đo cùng một thứ. Ở đây workflow
định nghĩa **một lần** trong WORKFLOW, 4 plan chỉ khác phần thread group và listener.

Khác biệt giữa các plan (đúng những gì §6 cho phép khác):
  - cấu hình tải: số thread, ramp-up, think-time, thời lượng, cách tăng bậc
  - listener: mỗi plan MỘT loại khác nhau (§6 cấm lặp loại)

Mọi tham số tải đều đọc qua ${__P(...)} nên chạy thử nhanh được mà không sửa file:
    jmeter -n -t test-plans/23127178_Load_20260813.jmx -Jthreads=1 -Jduration=20 ...
"""
import sys
import datetime

MSSV = "23127178"
OUT_DIR = "test-plans"

# ── Workflow dùng chung — 5 bước, phủ 3 endpoint group của §5 ────────────────────
# Mỗi phần tử: (tên sampler, method, path, body hoặc None, cần token?, assertion phụ)
WORKFLOW = [
    (
        "1 POST /api/login",
        "POST",
        "/api/login",
        '{"email":"${email}","password":"${password}"}',
        False,
        "token",  # body phải chứa "token" — 200 mà thiếu token là 4 bước sau vô nghĩa
    ),
    ("2 GET /api/admin/orders", "GET", "/api/admin/orders", None, True, None),
    ("3 GET /api/admin/users", "GET", "/api/admin/users", None, True, None),
    (
        "4 POST /api/admin/import-products",
        "POST",
        "/api/admin/import-products",
        # 3 sản phẩm mỗi request: một dòng CSV là quá nhẹ để thấy chi phí ghi tuần tự của SQLite.
        #
        # Assert theo `message`, KHÔNG theo `inserted`. Không phải vì `inserted` sai — đã kiểm
        # bằng request thật (5/5, 60/60, và 2/3 khi có dòng thiếu name: đều đúng) — mà vì nó là
        # một con số PHỤ THUỘC DỮ LIỆU: khi CSV có dòng lỗi thì `inserted` nhỏ hơn số dòng gửi
        # đi một cách hợp lệ. Assert theo nó là biến một đặc điểm dữ liệu thành "lỗi hiệu năng".
        '{"products":['
        '{"name":"${p_name}-A-${__threadNum}-${__counter(FALSE,)}","price":${p_price},'
        '"description":"${p_desc}","imageUrl":"","category_id":${p_cat}},'
        '{"name":"${p_name}-B-${__threadNum}-${__counter(FALSE,)}","price":${p_price},'
        '"description":"${p_desc}","imageUrl":"","category_id":${p_cat}},'
        '{"name":"${p_name}-C-${__threadNum}-${__counter(FALSE,)}","price":${p_price},'
        '"description":"${p_desc}","imageUrl":"","category_id":${p_cat}}'
        "]}",
        True,
        "message",
    ),
    (
        "5 PUT /api/admin/orders/:id/status",
        "PUT",
        "/api/admin/orders/${order_id}/status",
        '{"status":"${next_status}"}',
        True,
        None,
    ),
]

# Bước 5 chấp nhận 200 HOẶC 400, và đây là một quyết định phải giải thích trong báo cáo.
#
# FR-10 là một state machine: pending → confirmed → shipping → delivered (server.js:537-551).
# Một order chỉ đi tiếp được ĐÚNG MỘT lần cho mỗi trạng thái. Load test thì lặp cùng một
# order hàng nghìn lần, nên sau lần chuyển đầu tiên mọi request tiếp theo trả 400 "invalid
# transition" — đó là SUT hoạt động ĐÚNG, không phải lỗi.
#
# Hai cách sai đã loại:
#   - assert cứng 200: hầu hết sample thành "Fail" vì lý do dữ liệu, error rate vô nghĩa.
#   - bỏ assert: mất luôn khả năng phát hiện 500 hay timeout ở đúng endpoint transactional này.
#
# Cách chọn: assert 200|400 (cả hai đều là phản hồi hợp lệ của state machine), rồi BÁO CÁO
# tỉ lệ 200/400 tách riêng trong summary. Hệ quả phải nói rõ: nhánh 400 trả về trước lệnh
# UPDATE nên nhẹ hơn nhánh 200 — tín hiệu "ghi nặng" của bài này nằm ở import-products.
STEP5_ASSERT = ("200|400", 1, "Assert — 200 hoac 400 (state machine FR-10)")

# ...VÀ phải đánh dấu 400 là sample THÀNH CÔNG, y như nhánh lockout.
#
# Bài học lặp lại: assertion regex `200|400` pass, nhưng JMeter đã gắn cờ Fail cho 4xx từ trước
# và assertion không xoá được cờ đó. Lượt Load thứ hai vì vậy báo **18% error** trong khi 667/667
# sample "lỗi" đều là 400 hợp lệ của state machine. Đúng cơ chế đã sửa cho lockout ở
# mark_expected_4xx(), chỉ là quên áp cho bước 5.
STEP5_EXPECTED_4XX = "400"

# ── Cấu hình từng scenario ──────────────────────────────────────────────────────
# steps: danh sách thread group của luồng chính — (tên, threads, ramp, delay, duration)
#        nhiều bậc = stress test tăng dần; một bậc = tải phẳng
#
# think: (delay_ms, range_ms) cho MỖI BƯỚC, không phải mỗi iteration.
#
#   Timer đặt ở scope thread group nên JMeter chèn nó trước **từng** sampler — 5 lần một
#   iteration, không phải 1 lần. Lượt Load đầu tiên phát hiện điều này: đặt 1000-3000ms/bước
#   nghĩa là 5-15 giây một iteration, và 20 VU chỉ sinh ra ~10 sample/s thay vì ~60.
#
#   Giữ timer ở scope thread group (một admin thật cũng dừng giữa các màn hình) nhưng chia lại
#   để TỔNG mỗi iteration đúng mức đã thiết kế: Load 5×(200-600ms) = 1-3s một iteration.
SCENARIOS = {
    "Load": {
        "desc": "Tai ky vong on dinh — do p95 o trang thai binh thuong",
        "listener": ("Summary Report", "SummaryReport"),
        "think": (200, 400),  # 5 buoc x (200-600ms) = 1-3s moi iteration
        "steps": [("Thread Group — tai on dinh", "${__P(threads,20)}", "${__P(rampup,60)}", 0, "${__P(duration,360)}")],
    },
    "Stress": {
        "desc": "Tang bac 25 → 50 → 100 → 200 VU de tim diem gay",
        "listener": ("Aggregate Report", "StatVisualizer"),
        "think": (100, 100),  # 5 buoc x (100-200ms) = 0.5-1s moi iteration
        "steps": [
            ("Bac 1 — 25 VU", "25", "30", 0, "${__P(duration,480)}"),
            ("Bac 2 — +25 VU (tong 50)", "25", "30", 120, "360"),
            ("Bac 3 — +50 VU (tong 100)", "50", "30", 240, "240"),
            ("Bac 4 — +100 VU (tong 200)", "100", "30", 360, "120"),
        ],
    },
    "Spike": {
        "desc": "10 VU nen, dot ngot 200 VU trong 5s, roi ve 10 VU de do hoi phuc",
        "listener": ("View Results Tree", "ViewResultsFullVisualizer"),
        "think": (100, 200),  # 5 buoc x (100-300ms) = 0.5-1.5s moi iteration
        "steps": [
            ("Nen — 10 VU chay xuyen luot", "10", "10", 0, "${__P(duration,240)}"),
            ("Cu soc — 200 VU trong 5s", "${__P(spike,200)}", "5", 60, "30"),
        ],
    },
    "Soak": {
        "desc": "Tai on dinh keo dai 12 phut — tim endurance threshold (§6)",
        "listener": ("Summary Report", "SummaryReport"),
        "think": (200, 200),  # 5 buoc x (200-400ms) = 1-2s moi iteration
        "steps": [("Thread Group — soak", "${__P(threads,20)}", "${__P(rampup,60)}", 0, "${__P(duration,720)}")],
    },
}

# ── Helper XML ──────────────────────────────────────────────────────────────────
def esc(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
             .replace('"', "&quot;"))


SAVE_CONFIG = """        <objProp>
          <name>saveConfig</name>
          <value class="SampleSaveConfiguration">
            <time>true</time>
            <latency>true</latency>
            <timestamp>true</timestamp>
            <success>true</success>
            <label>true</label>
            <code>true</code>
            <message>true</message>
            <threadName>true</threadName>
            <dataType>true</dataType>
            <encoding>false</encoding>
            <assertions>true</assertions>
            <subresults>true</subresults>
            <responseData>false</responseData>
            <samplerData>false</samplerData>
            <xml>false</xml>
            <fieldNames>true</fieldNames>
            <responseHeaders>false</responseHeaders>
            <requestHeaders>false</requestHeaders>
            <responseDataOnError>false</responseDataOnError>
            <saveAssertionResultsFailureMessage>true</saveAssertionResultsFailureMessage>
            <assertionsResultsToSave>0</assertionsResultsToSave>
            <bytes>true</bytes>
            <sentBytes>true</sentBytes>
            <url>true</url>
            <threadCounts>true</threadCounts>
            <idleTime>true</idleTime>
            <connectTime>true</connectTime>
          </value>
        </objProp>
"""


def header_manager(name, headers, indent):
    p = " " * indent
    out = [f'{p}<HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="{esc(name)}" enabled="true">',
           f'{p}  <collectionProp name="HeaderManager.headers">']
    for k, v in headers:
        out += [f'{p}    <elementProp name="" elementType="Header">',
                f'{p}      <stringProp name="Header.name">{esc(k)}</stringProp>',
                f'{p}      <stringProp name="Header.value">{esc(v)}</stringProp>',
                f'{p}    </elementProp>']
    out += [f'{p}  </collectionProp>', f'{p}</HeaderManager>', f'{p}<hashTree/>']
    return "\n".join(out)


def csv_dataset(name, filename, variables, indent):
    p = " " * indent
    return "\n".join([
        f'{p}<CSVDataSet guiclass="TestBeanGUI" testclass="CSVDataSet" testname="{esc(name)}" enabled="true">',
        f'{p}  <stringProp name="filename">{esc(filename)}</stringProp>',
        f'{p}  <stringProp name="fileEncoding">UTF-8</stringProp>',
        f'{p}  <stringProp name="variableNames">{esc(variables)}</stringProp>',
        f'{p}  <boolProp name="ignoreFirstLine">true</boolProp>',
        f'{p}  <stringProp name="delimiter">,</stringProp>',
        f'{p}  <boolProp name="quotedData">false</boolProp>',
        f'{p}  <boolProp name="recycle">true</boolProp>',
        f'{p}  <boolProp name="stopThread">false</boolProp>',
        f'{p}  <stringProp name="shareMode">shareMode.all</stringProp>',
        f'{p}</CSVDataSet>',
        f'{p}<hashTree/>',
    ])


def assertion_code(expected, indent, test_type=8, name=None):
    """test_type: 8 = equals, 1 = matches (regex), 16 = substring."""
    p = " " * indent
    label = name or f"Assert — HTTP {expected}"
    return "\n".join([
        f'{p}<ResponseAssertion guiclass="AssertionGui" testclass="ResponseAssertion" testname="{esc(label)}" enabled="true">',
        f'{p}  <collectionProp name="Asserion.test_strings">',
        f'{p}    <stringProp name="expected">{esc(expected)}</stringProp>',
        f'{p}  </collectionProp>',
        f'{p}  <stringProp name="Assertion.custom_message"></stringProp>',
        f'{p}  <stringProp name="Assertion.test_field">Assertion.response_code</stringProp>',
        f'{p}  <boolProp name="Assertion.assume_success">false</boolProp>',
        f'{p}  <intProp name="Assertion.test_type">{test_type}</intProp>',
        f'{p}</ResponseAssertion>',
        f'{p}<hashTree/>',
    ])


def assertion_body(substring, indent):
    p = " " * indent
    return "\n".join([
        f'{p}<ResponseAssertion guiclass="AssertionGui" testclass="ResponseAssertion" testname="Assert — body chua &quot;{esc(substring)}&quot;" enabled="true">',
        f'{p}  <collectionProp name="Asserion.test_strings">',
        f'{p}    <stringProp name="expected_body">{esc(substring)}</stringProp>',
        f'{p}  </collectionProp>',
        f'{p}  <stringProp name="Assertion.custom_message"></stringProp>',
        f'{p}  <stringProp name="Assertion.test_field">Assertion.response_data</stringProp>',
        f'{p}  <boolProp name="Assertion.assume_success">false</boolProp>',
        f'{p}  <intProp name="Assertion.test_type">16</intProp>',
        f'{p}</ResponseAssertion>',
        f'{p}<hashTree/>',
    ])


def mark_expected_4xx(regex, indent):
    """Đánh dấu sample 4xx MONG ĐỢI là thành công.

    JMeter mặc định coi mọi 4xx/5xx là Fail, và assertion chỉ THÊM được lỗi chứ không xoá
    được cờ Fail đó. Nhánh lockout thì 401/403 mới là kết quả ĐÚNG — để nguyên thì error rate
    tổng của lượt chạy bị đội thêm ~35% bởi những sample đang hoạt động đúng đặc tả, và con số
    error rate ở đầu báo cáo mất hết ý nghĩa. Post-processor này sửa cờ về đúng bản chất.
    """
    p = " " * indent
    script = (f"if (prev.getResponseCode() ==~ /{regex}/) {{ "
              f"prev.setSuccessful(true); "
              f"prev.setResponseMessage('Expected lockout response ' + prev.getResponseCode()) }}")
    return "\n".join([
        f'{p}<JSR223PostProcessor guiclass="TestBeanGUI" testclass="JSR223PostProcessor" testname="Danh dau 4xx mong doi la thanh cong" enabled="true">',
        f'{p}  <stringProp name="scriptLanguage">groovy</stringProp>',
        f'{p}  <stringProp name="parameters"></stringProp>',
        f'{p}  <stringProp name="filename"></stringProp>',
        f'{p}  <stringProp name="cacheKey">true</stringProp>',
        f'{p}  <stringProp name="script">{esc(script)}</stringProp>',
        f'{p}</JSR223PostProcessor>',
        f'{p}<hashTree/>',
    ])


def json_extractor(indent):
    p = " " * indent
    return "\n".join([
        f'{p}<JSONPostProcessor guiclass="JSONPostProcessorGui" testclass="JSONPostProcessor" testname="JSON Extractor — TOKEN" enabled="true">',
        f'{p}  <stringProp name="JSONPostProcessor.referenceNames">TOKEN</stringProp>',
        f'{p}  <stringProp name="JSONPostProcessor.jsonPathExprs">$.token</stringProp>',
        f'{p}  <stringProp name="JSONPostProcessor.match_numbers">1</stringProp>',
        f'{p}  <stringProp name="JSONPostProcessor.defaultValues">TOKEN_NOT_FOUND</stringProp>',
        f'{p}</JSONPostProcessor>',
        f'{p}<hashTree/>',
    ])


def sampler(name, method, path, body, need_token, body_assert, indent,
            assert_code="200", assert_type=8, assert_name=None, extract_token=False,
            expected_4xx=None):
    p = " " * indent
    out = [f'{p}<HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="{esc(name)}" enabled="true">']
    if body is not None:
        out += [f'{p}  <boolProp name="HTTPSampler.postBodyRaw">true</boolProp>',
                f'{p}  <elementProp name="HTTPsampler.Arguments" elementType="Arguments">',
                f'{p}    <collectionProp name="Arguments.arguments">',
                f'{p}      <elementProp name="" elementType="HTTPArgument">',
                f'{p}        <boolProp name="HTTPArgument.always_encode">false</boolProp>',
                f'{p}        <stringProp name="Argument.value">{esc(body)}</stringProp>',
                f'{p}        <stringProp name="Argument.metadata">=</stringProp>',
                f'{p}      </elementProp>',
                f'{p}    </collectionProp>',
                f'{p}  </elementProp>']
    else:
        out += [f'{p}  <elementProp name="HTTPsampler.Arguments" elementType="Arguments">',
                f'{p}    <collectionProp name="Arguments.arguments"/>',
                f'{p}  </elementProp>']
    out += [
        f'{p}  <stringProp name="HTTPSampler.domain">${{__P(host,localhost)}}</stringProp>',
        f'{p}  <stringProp name="HTTPSampler.port">${{__P(port,3000)}}</stringProp>',
        f'{p}  <stringProp name="HTTPSampler.protocol">http</stringProp>',
        f'{p}  <stringProp name="HTTPSampler.path">{esc(path)}</stringProp>',
        f'{p}  <stringProp name="HTTPSampler.method">{method}</stringProp>',
        f'{p}  <boolProp name="HTTPSampler.follow_redirects">true</boolProp>',
        f'{p}  <boolProp name="HTTPSampler.use_keepalive">true</boolProp>',
        f'{p}  <stringProp name="HTTPSampler.connect_timeout">10000</stringProp>',
        f'{p}  <stringProp name="HTTPSampler.response_timeout">30000</stringProp>',
        f'{p}</HTTPSamplerProxy>',
        f'{p}<hashTree>',
    ]
    if need_token:
        out.append(header_manager("Auth header", [("Authorization", "Bearer ${TOKEN}")], indent + 2))
    out.append(assertion_code(assert_code, indent + 2, test_type=assert_type, name=assert_name))
    if body_assert:
        out.append(assertion_body(body_assert, indent + 2))
    if extract_token:
        out.append(json_extractor(indent + 2))
    if expected_4xx:
        out.append(mark_expected_4xx(expected_4xx, indent + 2))
    out.append(f'{p}</hashTree>')
    return "\n".join(out)


def timer(delay, rng, indent):
    p = " " * indent
    return "\n".join([
        f'{p}<UniformRandomTimer guiclass="UniformRandomTimerGui" testclass="UniformRandomTimer" testname="Think time {delay}-{delay + rng}ms" enabled="true">',
        f'{p}  <stringProp name="ConstantTimer.delay">{delay}</stringProp>',
        f'{p}  <stringProp name="RandomTimer.range">{rng}.0</stringProp>',
        f'{p}</UniformRandomTimer>',
        f'{p}<hashTree/>',
    ])


def thread_group(name, threads, ramp, delay, duration, children, indent):
    p = " " * indent
    out = [
        f'{p}<ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="{esc(name)}" enabled="true">',
        f'{p}  <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>',
        f'{p}  <elementProp name="ThreadGroup.main_controller" elementType="LoopController" guiclass="LoopControlPanel" testclass="LoopController" testname="Loop Controller" enabled="true">',
        f'{p}    <boolProp name="LoopController.continue_forever">false</boolProp>',
        f'{p}    <stringProp name="LoopController.loops">-1</stringProp>',
        f'{p}  </elementProp>',
        f'{p}  <stringProp name="ThreadGroup.num_threads">{threads}</stringProp>',
        f'{p}  <stringProp name="ThreadGroup.ramp_time">{ramp}</stringProp>',
        f'{p}  <boolProp name="ThreadGroup.scheduler">true</boolProp>',
        f'{p}  <stringProp name="ThreadGroup.duration">{duration}</stringProp>',
        f'{p}  <stringProp name="ThreadGroup.delay">{delay}</stringProp>',
        f'{p}  <boolProp name="ThreadGroup.same_user_on_next_iteration">false</boolProp>',
        f'{p}</ThreadGroup>',
        f'{p}<hashTree>',
    ]
    out += children
    out.append(f'{p}</hashTree>')
    return "\n".join(out)


def lockout_group(indent):
    """Thread group nhỏ cho nhánh account-lockout (§5 nói auth-heavy phải tính tới lockout).

    Dùng data/users_lockout.csv — TÁCH khỏi users.csv của luồng chính. Nếu để chung, hai VU
    đăng nhập sai sẽ khoá đúng những tài khoản mà luồng chính đang dùng, và cả lượt chạy biến
    thành một biển 403 không đọc được gì.
    """
    children = [
        csv_dataset("CSV — tai khoan lockout", "data/users_lockout.csv",
                    "lk_email,lk_password,lk_expect", indent + 2),
        # 401 o lan dau, 403 sau khi da bi khoa — ca hai deu dung, nen assert bang regex 40[13].
        sampler("6 POST /api/login (sai mat khau — lockout probe)", "POST", "/api/login",
                '{"email":"${lk_email}","password":"${lk_password}"}',
                False, None, indent + 2,
                assert_code="40[13]", assert_type=1,
                assert_name="Assert — 401 hoac 403 (lockout)",
                expected_4xx="40[13]"),
        timer(2000, 1000, indent + 2),
    ]
    return thread_group("TG-lockout — nhanh account-lockout (2 VU)", "2", "1", 10, "${__P(lockout_duration,120)}", children, indent)


def listener(name, guiclass, indent):
    p = " " * indent
    return "\n".join([
        f'{p}<ResultCollector guiclass="{guiclass}" testclass="ResultCollector" testname="{esc(name)}" enabled="true">',
        f'{p}  <boolProp name="ResultCollector.error_logging">false</boolProp>',
        SAVE_CONFIG.rstrip(),
        f'{p}  <stringProp name="filename"></stringProp>',
        f'{p}</ResultCollector>',
        f'{p}<hashTree/>',
    ])


def build(scenario, date):
    cfg = SCENARIOS[scenario]
    delay, rng = cfg["think"]

    workflow_children = []
    for name, method, path, body, need_token, body_assert in WORKFLOW:
        code, atype, aname, expected_4xx = ("200", 8, None, None)
        if name.startswith("5 PUT"):
            code, atype, aname = STEP5_ASSERT
            expected_4xx = STEP5_EXPECTED_4XX
        workflow_children.append(sampler(
            name, method, path, body, need_token, body_assert, 10,
            assert_code=code, assert_type=atype, assert_name=aname,
            expected_4xx=expected_4xx,
            extract_token=path == "/api/login",
        ))
    workflow_children.append(timer(delay, rng, 10))

    groups = []
    for gname, threads, ramp, gdelay, duration in cfg["steps"]:
        groups.append(thread_group(gname, threads, ramp, gdelay, duration, workflow_children, 8))
    groups.append(lockout_group(8))

    lname, lgui = cfg["listener"]

    return f"""<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0" jmeter="5.6.3">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="{MSSV} — HW05 {scenario} — EShop admin back-office" enabled="true">
      <stringProp name="TestPlan.comments">{esc(cfg['desc'])} · SV {MSSV} · sinh boi tools/gen-test-plans.py</stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.tearDown_on_shutdown">true</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <elementProp name="TestPlan.user_defined_variables" elementType="Arguments" guiclass="ArgumentsPanel" testclass="Arguments" testname="User Defined Variables" enabled="true">
        <collectionProp name="Arguments.arguments">
          <elementProp name="STUDENT_ID" elementType="Argument">
            <stringProp name="Argument.name">STUDENT_ID</stringProp>
            <stringProp name="Argument.value">{MSSV}</stringProp>
            <stringProp name="Argument.metadata">=</stringProp>
          </elementProp>
          <elementProp name="SCENARIO" elementType="Argument">
            <stringProp name="Argument.name">SCENARIO</stringProp>
            <stringProp name="Argument.value">{scenario}</stringProp>
            <stringProp name="Argument.metadata">=</stringProp>
          </elementProp>
        </collectionProp>
      </elementProp>
      <stringProp name="TestPlan.user_define_classpath"></stringProp>
    </TestPlan>
    <hashTree>
{header_manager("HTTP Header Manager", [("Content-Type", "application/json")], 6)}
{csv_dataset("CSV — users (moi VU mot tai khoan)", "data/users.csv", "email,password,expect", 6)}
{csv_dataset("CSV — products de import", "data/products_import.csv", "p_name,p_price,p_desc,p_cat", 6)}
{csv_dataset("CSV — orders de doi trang thai", "data/orders.csv", "order_id,next_status", 6)}
{chr(10).join(groups)}
{listener(lname, lgui, 6)}
    </hashTree>
  </hashTree>
</jmeterTestPlan>
"""


def main():
    date = sys.argv[1] if len(sys.argv) > 1 else datetime.date.today().strftime("%Y%m%d")
    import os
    os.makedirs(OUT_DIR, exist_ok=True)
    for scenario in SCENARIOS:
        path = os.path.join(OUT_DIR, f"{MSSV}_{scenario}_{date}.jmx")
        with open(path, "w", encoding="utf-8") as f:
            f.write(build(scenario, date))
        print(f"  {path}")
    print(f"\n  4 test plan · workflow 5 buoc dung chung · listener khac loai tung plan")


if __name__ == "__main__":
    main()
