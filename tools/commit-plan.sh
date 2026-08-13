#!/usr/bin/env bash
# ============================================================================
# commit-plan.sh — commit HW05 theo từng bước của quy trình.
#
# §12 đòi: **một commit cho mỗi bước của procedure** (mỗi test plan, phần phân tích AI,
# đề xuất continuous testing…), và cuối cùng xuất commit log ra file text.
#
#   bash tools/commit-plan.sh status      # xem đã commit gì, còn gì
#   bash tools/commit-plan.sh scaffold    # commit bộ khung + tooling (6 commit)
#   bash tools/commit-plan.sh log         # xuất git-log/commit-log.txt
#
# KHÔNG lùi ngày commit (--date). Ngày trong git log phải là ngày làm thật — §11 nói bằng
# chứng không được dựng, và §12 dùng đúng cái log này để kiểm.
#
# Message commit viết bằng TIẾNG ANH (giữ đúng quy ước HW02/HW03/HW04); phần in ra màn hình
# giữ tiếng Việt.
# ============================================================================
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

c() { # $1 = subject, $2 = body
  if git diff --cached --quiet; then
    echo "  [BO QUA] không có gì để commit: $1"
    return 0
  fi
  git commit -q -m "$1" -m "$2" && printf "  [OK]   %2d. %s\n" "$(git rev-list --count HEAD)" "$1"
}

case "${1:-status}" in

# ─────────────────────────────────────────────────────────────────────────────
scaffold)
echo "── Commit bộ khung + tooling ─────────────────────────────────────────"

git add .gitignore package.json
c "chore: repo skeleton for HW05 performance testing" \
"Mirrors the layout HW02-HW04 settled on so the submission checklist maps one-to-one onto
folders: report/ ai-audit/ bug-report/ git-log/ docs/, plus the HW05-specific test-plans/
data/ results/ endurance/ resource-monitor/.

.gitignore commits what section 11 asks for by name - the .jmx plans, the raw .jtl logs in
full, the HTML dashboards, the resource screenshots - and excludes only what would defeat
that: JMeter's own log noise and k6 --out json, which writes one JSON line per metric point
and reaches hundreds of MB on a ten-minute run."

git add tools/preflight.mjs tools/seed-perf-data.mjs tools/reset-lockout.mjs
c "test: environment checks and data-driven fixtures" \
"preflight.mjs refuses to let a run start against a dead backend. That matters more here than
in HW04: a broken environment does not produce an obviously empty suite, it produces a .jtl
full of fast 401s and a p95 that looks excellent.

seed-perf-data.mjs gives every virtual user its own account. Sharing one account would put
every login through the same users row - each successful login runs UPDATE login_attempts
(server.js:47) - so the contention measured would belong to the load script, not the endpoint.

reset-lockout.mjs is the reset procedure section 6 asks to be documented. Lockout fires after
two wrong passwords, not three, because login_attempts increments by 2 against a threshold of
3 (server.js:54-58)."

git add tools/run-scenario.sh tools/run-all.sh tools/jmeter-user.properties
c "test: JMeter run harness with arm64 JVM pinning and cooldowns" \
"run-scenario.sh pins JAVA_HOME to the arm64 JDK. The java on PATH here is Temurin 8 x86_64,
so an unpinned run puts JMeter under Rosetta and the load generator itself becomes the
bottleneck being measured.

It also clears the -o dashboard folder before starting. JMeter refuses to write into a
non-empty one and reports it only after the test has finished, which costs the whole run.

jmeter-user.properties forces Latency and Connect into the .jtl. Without Latency there is no
way to separate server think-time from transfer time, and that separation is the core of the
Task 2 argument - adding it after the fact is too late.

run-all.sh runs the three scenarios in sequence with a 90s cooldown. Running them in parallel
makes all three datasets meaningless; running Spike immediately after Stress measures a server
that has not recovered."

git add tools/summarize-jtl.mjs
c "test: derive every reported number from the raw .jtl" \
"Task 2 requires citing the correct value from the raw log when the AI misreads a metric, so
there has to be a calculation independent of JMeter's dashboard to argue against.

Reports per-endpoint percentiles - the overall p95 is diluted by the fast GETs - and breaks
errors down by response code, because 403 here is account lockout, a functional behaviour,
while 500 is the actual performance signal. Collapsing both into one error rate is the
misreading the assignment asks students to catch.

Percentiles use nearest-rank; JMeter interpolates, so a few ms of drift at p99 is expected and
is noted in the output itself so it is not mistaken for a corrupt log."

git add tools/hardware-report.sh tools/md2pdf.py tools/build-pdfs.sh tools/commit-plan.sh
c "chore: hardware report and document tooling" \
"hardware-report.sh puts hostname on the first row because section 11 checks it against the
earlier homework deployments. It also states the constraint that shapes every number in the
report: the load generator and the SUT share one machine, so the endurance threshold belongs
to that arrangement rather than to the backend alone.

md2pdf.py is carried over unchanged from HW04 - section 14 wants Markdown and PDF for four
documents."

git add .claude docs demo git-log
c "docs: playbook, agent skills and report scaffolding" \
"Four skills for section 7: perf-test-plan drives one scenario through seven steps,
jtl-analysis covers the Task 2 analysis and the misinterpretation hunt, resource-evidence
covers the evidence format section 11 verifies by hand, ai-audit-logger records each AI turn
for section 9.

docs/endpoint-selection.md records the section 5 anti-duplication position: the whole customer
journey is already claimed by the other three group members, so this submission takes the
admin back-office workflow. Only POST /api/login overlaps, and it cannot be avoided since
every other step needs the token.

The report, AI audit, critique, bug report and endurance documents are scaffolded with the
required sections and word limits marked, empty of numbers until a run produces them."

echo ""
echo "  Xong. Bước tiếp theo: bash tools/commit-plan.sh plans"
;;

# ─────────────────────────────────────────────────────────────────────────────
plans)
echo "── Commit test plan, dữ liệu và bản k6 ───────────────────────────────"

git add tools/gen-test-plans.py test-plans/
c "test(plans): generate the four JMeter plans from one shared workflow" \
"Section 6 requires all three plans to exercise the same end-to-end workflow. Hand-writing four
XML files of 400-1100 lines drifts by one assertion sooner or later, and once they differ,
comparing Load against Stress against Spike no longer compares the same thing.

gen-test-plans.py defines the five-step workflow once and emits Load, Stress, Spike and Soak
from it. Only the load profile and the listener differ - Summary Report, Aggregate Report and
View Results Tree, no type reused, as section 6 demands. Every load parameter reads through
\${__P(...)} so a 20-second smoke run needs no file edit."

git add tools/seed-perf-data.mjs tools/reset-orders.mjs data/
c "test(data): per-VU accounts, and stop the data from poisoning its own run" \
"users.csv first carried two deliberately-wrong passwords at the end, meant for the lockout
branch. The main thread group reads that same file with recycle=true, so it hit those rows,
locked the two accounts for 180 seconds, and then every retry returned 403 - and with no token,
the remaining four steps of those iterations returned 403 too. That accounted for the entire
2.9% error rate of the first real run: nine iterations times five labels, none of which said
anything about the SUT's performance. The lockout branch now reads its own users_lockout.csv.

reset-orders.mjs is the same idea as reset-lockout.mjs. Step 5 walks the FR-10 state machine
(server.js:537-551), where an order advances once per state, so without a reset the next run
starts with every order already terminal and step 5 returns 400 from its first second."

git add tools/sample-resources.sh tools/run-scenario.sh
c "test: sample CPU and RSS through each run" \
"Section 6 asks for a resource-monitor screenshot, but a screenshot cannot be computed with.
The endurance threshold needs numbers - RSS at the start against RSS at the end, the memory
ceiling - and reading those off an image is guessing.

The sampler also records the JMeter process, which the screenshot usually omits. If java burns
more CPU than node, the bottleneck is the load generator and every conclusion about the server
is wrong; without that column the mistake is invisible."

git add k6/
c "test(k6): mirror the workflow in k6 for cross-checking (bonus)" \
"JMeter gives each VU a JVM thread; k6 uses a goroutine. If k6 reports a materially lower p95
at the same load, that difference belongs to the tool rather than to the server - which is a
checkable argument for the Task 2 analysis, not just a bonus box ticked.

Reads the same three CSVs and keeps the same five steps and assertions as the .jmx, including
not asserting on the inserted count, which is data-dependent rather than wrong. No jslib imports: a
performance test should not need the network to compile."

echo ""
echo "  Xong. Bước tiếp theo: bash tools/commit-plan.sh runs"
;;

# ─────────────────────────────────────────────────────────────────────────────
runs)
echo "── Commit bằng chứng chạy ────────────────────────────────────────────"

git add results/jtl results/html results/resources results/run-log.md results/summary.md \
        endurance/jtl endurance/html endurance/resources endurance/run-log.md \
        resource-monitor/hardware-report.md resource-monitor/screenshots
c "test: raw jtl, dashboards and resource samples for all four runs" \
"Load, Stress, Spike and Soak, run in sequence with a 90-second cooldown between them. Raw .jtl
in full as section 11 requires, one HTML dashboard per scenario, one resource CSV per run, and
run-log.md carrying the UTC start and end of each run so the Activity Monitor screenshots can
be matched against a real run.

Two earlier attempts were cancelled mid-run and their evidence deleted rather than kept with a
footnote - numbers already known to be wrong do not belong anywhere in the submission. What
went wrong in them is recorded in ai-audit/ai-audit-report.md."

git add tools/capture-run.sh tools/soak-drift.mjs package.json
c "test: guide the evidence screenshots, and measure p95 drift over time" \
"Section 6 wants the tool and the resource monitor in one frame, and section 11 checks the
timestamp in the image against a real run - so a screenshot is only worth anything if it was
taken during the run that ends up as the submitted evidence.

capture-run.sh counts down to the second worth capturing rather than leaving it to guesswork:
Load at 180s once ramp-up has settled, Stress at 420s when the 200-VU step is live, Spike at
72s in the middle of a shock that lasts 30 seconds, Soak at 90s and again at 690s so the two
images can be compared for RSS drift. Missing the moment costs a whole run.

soak-drift.mjs answers the question summarize-jtl.mjs cannot: not what p95 was, but whether it
climbed. A soak with a healthy overall p95 can still be degrading - 4ms for five minutes then
40ms - and the average hides it. It reports per-minute windows and checks them against the
stability definition fixed before the run."

git add bug-report/verify-bugs.sh
c "docs(bug): verify each finding, and retract the one that failed verification" \
"Every claim in the bug report now re-runs from one command. The script also re-runs the
candidate that was RETRACTED, because showing something is not a bug needs the same evidence as
showing that it is.

The retracted one was mine: I read server.js:234, saw stmt.finalize() reply before the stmt.run
callbacks, and stated as fact that import-products under-reports its insert count. Three real
batches say otherwise - 5/5, 60/60, and 2/3 when one row is missing a name. node-sqlite3 
serialises statements on one handle and finalize's callback runs after them. That wrong reading
had already reached five files.

Reading code produces a hypothesis. Only running it produces a finding."

git add report/ ai-audit/ bug-report/bug-report.md endurance/endurance-threshold.md README.md docs/
c "docs: report, AI audit, critique, bug report and endurance threshold" \
"Every number traces to results/summary.md, which is generated from the raw .jtl - nothing is
counted by hand.

The AI audit records seven mistakes the AI made, five of which left the test plan running
normally and only corrupted the numbers: think-time multiplied fivefold by timer scope, a
lockout branch counted as a performance failure at 41% error, and the expected 400 of FR-10
counted as failure at 18% error on a healthy system. The critique is 298 words against the
200-300 the assignment sets."

echo ""
echo "  Xong. Bước cuối: bash tools/commit-plan.sh log"
;;

# ─────────────────────────────────────────────────────────────────────────────
log)
mkdir -p git-log
git log --graph --stat --date=iso --pretty=format:'%h %ad %an%n  %s%n%b' > git-log/commit-log.txt
echo "  Đã xuất git-log/commit-log.txt ($(git rev-list --count HEAD) commit)"
;;

# ─────────────────────────────────────────────────────────────────────────────
status)
echo ""
echo "── Commit hiện có ($(git rev-list --count HEAD)) ─────────────────────────────────────"
git log --oneline | head -30
echo ""
echo "── Chưa commit ───────────────────────────────────────────────────────"
git status --short
echo ""
echo "── §12 ───────────────────────────────────────────────────────────────"
echo "  Đòi: một commit cho MỖI bước của quy trình + xuất commit log ra file text."
echo "  Các bước dự kiến còn lại, mỗi bước một commit:"
echo "    test(load|stress|spike): JMeter plan            × 3"
echo "    test: raw jtl + dashboard cho từng lượt         × 3"
echo "    docs: human review AI sinh test plan (§6)"
echo "    test: endurance/soak + ngưỡng chịu tải"
echo "    docs: Task 2 — AI phân tích + bắt lỗi đọc metric"
echo "    docs: Task 3 — continuous perf testing + flow chart"
echo "    docs: bug report + GitHub Issues"
echo "    docs: AI audit + critique (200–300 từ)"
echo "    docs: README self-assessment + test summary"
echo "    docs: xuất commit log  →  bash tools/commit-plan.sh log"
echo ""
;;

*)
echo "Dùng: bash tools/commit-plan.sh {status|scaffold|log}"
exit 2
;;
esac
