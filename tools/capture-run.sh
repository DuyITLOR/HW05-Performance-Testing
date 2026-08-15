#!/usr/bin/env bash
# ============================================================================
# capture-run.sh — chạy các lượt perf test và hướng dẫn chụp ảnh bằng chứng ĐÚNG LÚC.
#
#   bash tools/capture-run.sh                 # cả 4 lượt, hỏi trước mỗi lượt
#   bash tools/capture-run.sh Spike Soak      # chỉ 2 lượt
#   bash tools/capture-run.sh --auto          # tự chụp bằng screencapture (cần cấp quyền)
#   bash tools/capture-run.sh --list          # xem mốc chụp của từng lượt rồi thoát
#
# Vì sao cần script này thay vì tự canh tay:
#
#   §6 đòi ảnh có **JMeter và resource monitor trong CÙNG khung hình**, và §11 kiểm timestamp
#   trong ảnh khớp lượt chạy thật. Nghĩa là ảnh chỉ có giá trị nếu chụp đúng lượt chạy được giữ
#   làm bằng chứng cuối cùng — chụp ở một lượt nháp rồi ghép vào báo cáo là đúng thứ §11 chặn.
#
#   Và mốc chụp không phải lúc bấm chạy: Load phải chụp sau khi ramp-up xong, Stress phải chụp
#   đúng bậc 200 VU (giây 360–480), Spike chỉ sốc trong ~30 giây quanh giây 60. Canh tay thì
#   trượt, mà trượt là phải chạy lại cả lượt.
# ============================================================================
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

AUTO=0
LIST=0
SCENARIOS=()
for a in "$@"; do
  case "$a" in
    --auto) AUTO=1 ;;
    --list) LIST=1 ;;
    Load|Stress|Spike|Soak) SCENARIOS+=("$a") ;;
    *) echo "Tham số lạ: $a"; echo "Dùng: bash tools/capture-run.sh [Load|Stress|Spike|Soak]... [--auto] [--list]"; exit 2 ;;
  esac
done
[ ${#SCENARIOS[@]} -eq 0 ] && SCENARIOS=(Load Stress Spike Soak)

SHOTS="resource-monitor/screenshots"
mkdir -p "$SHOTS"

# ── Mốc chụp: giây thứ mấy kể từ lúc JMeter bắt đầu, và vì sao đúng mốc đó ─────
# Lấy từ chính cấu hình thread group trong tools/gen-test-plans.py.
peak_info() {
  case "$1" in
    Load)   echo "180|360|ramp-up 60s xong tu giay 60 → giay 180 la giua giai doan on dinh" ;;
    Stress) echo "420|480|bac 4 (200 VU) bat dau o giay 360, keo dai 120s → giay 420 la giua bac cao nhat" ;;
    Spike)  echo "72|240|cu soc bat dau giay 60, ramp 5s, keo dai 30s → giay 72 la giua cu soc" ;;
    Soak)   echo "90|720|sau ramp-up; lay THEM mot anh o giay 690 de thay RSS co troi khong" ;;
  esac
}

if [ "$LIST" = "1" ]; then
  echo ""
  echo "── Mốc chụp từng lượt ────────────────────────────────────────────────"
  for s in Load Stress Spike Soak; do
    IFS='|' read -r at total why <<< "$(peak_info "$s")"
    printf "  %-7s chụp ở giây %-4s (lượt dài %ss)\n           %s\n" "$s" "$at" "$total" "$why"
  done
  echo ""
  exit 0
fi

# ── Kiểm quyền screencapture nếu dùng --auto ─────────────────────────────────
if [ "$AUTO" = "1" ]; then
  TESTSHOT="$(mktemp -t capture-test).png"
  screencapture -x "$TESTSHOT" 2>/dev/null
  if [ ! -s "$TESTSHOT" ]; then
    echo ""
    echo "[LOI] screencapture không chụp được — macOS chưa cấp quyền Screen Recording cho Terminal."
    echo "      Cấp quyền: System Settings → Privacy & Security → Screen & System Audio Recording"
    echo "      → bật cho Terminal (hoặc iTerm), rồi mở lại Terminal."
    echo ""
    echo "      Hoặc bỏ --auto để chụp tay (script vẫn báo đúng thời điểm)."
    rm -f "$TESTSHOT"
    exit 1
  fi
  rm -f "$TESTSHOT"
  echo "  screencapture hoạt động — sẽ tự chụp đúng mốc."
fi

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "  CHUẨN BỊ — làm một lần, dùng cho cả ${#SCENARIOS[@]} lượt"
echo "══════════════════════════════════════════════════════════════════════"
echo ""
echo "  1. Mở Activity Monitor (Cmd+Space → 'Activity Monitor')"
echo "  2. Tab CPU · ô Search gõ:  node"
echo "  3. Xếp Activity Monitor và CỬA SỔ TERMINAL NÀY cạnh nhau, thấy được CẢ HAI cùng lúc"
echo "     → §6 đòi hai thứ trong CÙNG khung hình; chụp riêng rồi ghép KHÔNG được tính."
echo ""
if [ "$AUTO" = "0" ]; then
  echo "  4. Nhớ tổ hợp chụp:  Cmd+Shift+4  rồi kéo chọn vùng ôm cả hai cửa sổ"
  echo "     (hoặc Cmd+Shift+3 chụp toàn màn hình — cũng thoả nếu cả hai đều nhìn thấy)"
  echo "  5. Ảnh mặc định vào Desktop; script sẽ nhắc tên file cần đổi thành."
else
  echo "  4. Không cần bấm gì — script tự chụp toàn màn hình đúng mốc."
fi
echo ""
read -r -p "  Xếp cửa sổ xong thì bấm ENTER để bắt đầu... " _

# ── Chạy từng lượt ────────────────────────────────────────────────────────────
IDX=0
for S in "${SCENARIOS[@]}"; do
  IDX=$((IDX + 1))
  IFS='|' read -r AT TOTAL WHY <<< "$(peak_info "$S")"
  TARGET="$SHOTS/activity-$(echo "$S" | tr '[:upper:]' '[:lower:]').png"
  OUT_ARG=""
  [ "$S" = "Soak" ] && OUT_ARG="--out endurance"

  echo ""
  echo "══════════════════════════════════════════════════════════════════════"
  echo "  [$IDX/${#SCENARIOS[@]}]  $S   —  lượt dài ~${TOTAL}s"
  echo "══════════════════════════════════════════════════════════════════════"
  echo "  Mốc chụp : giây thứ $AT"
  echo "  Lý do    : $WHY"
  echo "  Lưu vào  : $TARGET"
  echo ""
  # Không hỏi ENTER trước từng lượt: 4 lần bấm cách nhau ~8 phút nghĩa là phải trực máy chỉ để
  # bấm. Chỉ hỏi một lần ở đầu (lúc xếp cửa sổ), phần còn lại tự chạy. Ctrl+C để dừng hẳn.
  echo "  Bắt đầu sau 5 giây… (Ctrl+C để dừng hẳn)"
  sleep 5

  # Chạy nền để script còn đếm giây và nhắc chụp.
  bash tools/run-scenario.sh "$S" $OUT_ARG > "/tmp/capture-$S.log" 2>&1 &
  RUN_PID=$!

  # run-scenario.sh còn reset lockout + reset order trước khi gọi jmeter, nên mốc chụp tính từ
  # lúc JMeter thật sự bắt đầu, không phải từ lúc bấm ENTER. Chờ dòng "Starting standalone test".
  echo -n "  Đang khởi động JMeter"
  WAITED=0
  while ! grep -q "Starting standalone test" "/tmp/capture-$S.log" 2>/dev/null; do
    if ! kill -0 "$RUN_PID" 2>/dev/null; then
      echo ""
      echo "  [LOI] lượt chạy thoát sớm — xem /tmp/capture-$S.log"
      tail -12 "/tmp/capture-$S.log"
      exit 1
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
    [ "$WAITED" -gt 120 ] && { echo ""; echo "  [LOI] JMeter không khởi động sau 120s"; exit 1; }
  done
  echo " xong."

  # Đếm tới mốc chụp.
  echo ""
  for ((t = 0; t < AT; t += 5)); do
    LEFT=$((AT - t))
    printf "\r  Còn %3ds tới mốc chụp… (đang chạy: %s)   " "$LEFT" "$S"
    sleep 5
  done
  printf "\r%-70s\r" " "

  # Chụp.
  if [ "$AUTO" = "1" ]; then
    screencapture -x "$TARGET"
    if [ -s "$TARGET" ]; then
      echo "  [OK] Đã chụp: $TARGET ($(du -h "$TARGET" | cut -f1))"
    else
      echo "  [LOI] chụp thất bại — chụp tay ngay bây giờ (Cmd+Shift+4)"
    fi
  else
    printf '\a'   # tiếng beep
    echo "  ┌────────────────────────────────────────────────────────────┐"
    echo "  │  CHỤP NGAY BÂY GIỜ:  Cmd+Shift+4  → kéo ôm cả hai cửa sổ   │"
    echo "  └────────────────────────────────────────────────────────────┘"
    echo "  Lưu / đổi tên thành: $TARGET"
    echo ""
  fi

  # ── Spike: chụp THÊM hai mốc nữa trong cửa sổ sốc ──────────────────────────
  # Lượt Spike đầu tiên chụp đúng một ảnh ở giây 72 và bắt `node` ở 34,9%, trong khi đỉnh thật của
  # lượt là 81,6%. Cửa sổ sốc rộng ~30 giây mà CPU trong đó KHÔNG phẳng: nó lên theo ramp 5s, đạt
  # đỉnh, rồi tụt khi các VU bắt đầu chờ think-time lệch pha nhau. Một ảnh trong cửa sổ 30 giây là
  # một lát cắt may rủi.
  #
  # §6 chỉ đòi **một** ảnh cho mỗi scenario. Hai mốc thêm là **bảo hiểm cho việc canh giờ**, không
  # phải yêu cầu: nếu ảnh ở giây 72 đọc ra số thấp (tức đã trượt), thì còn hai mốc nữa vẫn nằm trong
  # cửa sổ sốc để chụp. Nếu tấm đầu đã tốt thì bỏ qua hai mốc sau, không sao cả.
  #
  # Điều KHÔNG được làm: chụp nhiều tấm rồi chọn tấm có số cao nhất mà im lặng — đó là chọn bằng
  # chứng. Nếu giữ nhiều tấm thì giữ hết và nói rõ tấm nào ở giây nào. Lượt 21:59 chỉ cần tấm đầu:
  # đọc 72,6% so với đỉnh tool đo 75,7%.
  if [ "$S" = "Spike" ]; then
    echo ""
    echo "  Cửa sổ sốc rộng ~30s và CPU trong đó KHÔNG phẳng → chụp thêm 2 mốc, GIỮ CẢ BA."
    echo "  (Mẹo: Activity Monitor → View → Update Frequency → Very often (1s), nếu không cột"
    echo "   %CPU chỉ đổi mỗi 5 giây và ảnh dễ bắt trượt đỉnh.)"
    # Mốc lấy từ chính file resources của lượt Spike đã chạy: giây 64 → 46,9% · giây 72 → 72,3% ·
    # giây 96 → 14,5%. Nhánh sốc sống từ giây 60 đến 90 (delay 60 + duration 30), nên cả ba mốc
    # phải nằm gọn trong khoảng đó. Giây 88 sát mép quá — đổi thành 78 và 84, cụm quanh chỗ CPU
    # cao nhất. Ảnh cũ bắt 34,9% gần như chắc chắn vì chụp sau giây 90, lúc CPU đã sụp về ~14%.
    PREV=$AT
    for NEXT in 78 84; do
      GAP=$((NEXT - PREV))
      EXTRA="$SHOTS/activity-spike-t${NEXT}.png"
      for ((t = 0; t < GAP; t += 2)); do
        printf "\r  Còn %2ds tới mốc giây %s…   " "$((GAP - t))" "$NEXT"
        sleep 2
      done
      printf "\r%-70s\r" " "
      if [ "$AUTO" = "1" ]; then
        screencapture -x "$EXTRA"
        echo "  [OK] Đã chụp mốc giây $NEXT: $EXTRA"
      else
        printf '\a'
        echo "  ┌────────────────────────────────────────────────────────────┐"
        printf '  │  CHỤP LẦN NỮA (giây %-3s):  Cmd+Shift+4                     │\n' "$NEXT"
        echo "  └────────────────────────────────────────────────────────────┘"
        echo "  Lưu thành: $EXTRA"
        echo ""
      fi
      PREV=$NEXT
    done
    echo "  Xong 3 mốc. Giữ cả ba — đừng xoá ảnh có số thấp, chính chỗ biến thiên là bằng chứng."
  fi

  # Soak: thêm một ảnh ở cuối để so RSS đầu/cuối.
  if [ "$S" = "Soak" ]; then
    SECOND_AT=$((TOTAL - 30))
    REMAIN=$((SECOND_AT - AT))
    echo "  Ảnh thứ hai của Soak ở giây $SECOND_AT (để so RSS đầu/cuối) — còn ${REMAIN}s."
    for ((t = 0; t < REMAIN; t += 10)); do
      printf "\r  Còn %3ds tới ảnh thứ hai…   " "$((REMAIN - t))"
      sleep 10
    done
    printf "\r%-70s\r" " "
    TARGET2="$SHOTS/activity-soak-cuoi.png"
    if [ "$AUTO" = "1" ]; then
      screencapture -x "$TARGET2"
      [ -s "$TARGET2" ] && echo "  [OK] Đã chụp: $TARGET2"
    else
      printf '\a'
      echo "  CHỤP ẢNH THỨ HAI NGAY BÂY GIỜ → lưu thành: $TARGET2"
    fi
  fi

  # Chờ lượt chạy xong.
  echo "  Chờ $S chạy hết…"
  wait "$RUN_PID"
  RC=$?
  grep -E "Tai nguyen|Xong sau" "/tmp/capture-$S.log" | sed 's/^/  /'
  if [ "$RC" -ne 0 ]; then
    echo "  [LOI] $S thoát với mã $RC — xem /tmp/capture-$S.log"
    exit "$RC"
  fi

  # Cooldown trước lượt sau.
  if [ "$IDX" -lt "${#SCENARIOS[@]}" ]; then
    echo ""
    echo "  Cooldown 90s để server hồi phục trước lượt sau…"
    echo "  (Chạy lượt sau ngay là đo một server chưa hồi phục — số liệu không so được.)"
    for ((t = 0; t < 90; t += 10)); do
      printf "\r  Còn %2ds…   " "$((90 - t))"
      sleep 10
    done
    printf "\r%-40s\r" " "
  fi
done

# ── Tổng hợp và soát bằng chứng ───────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "  TỔNG HỢP"
echo "══════════════════════════════════════════════════════════════════════"
node tools/summarize-jtl.mjs
node tools/soak-drift.mjs 2>/dev/null | tail -22

echo ""
echo "── Soát ảnh bằng chứng ───────────────────────────────────────────────"
MISSING=0
for S in "${SCENARIOS[@]}"; do
  f="$SHOTS/activity-$(echo "$S" | tr '[:upper:]' '[:lower:]').png"
  if [ -s "$f" ]; then
    echo "  [OK]   $f ($(du -h "$f" | cut -f1))"
  else
    echo "  [THIEU] $f"
    MISSING=$((MISSING + 1))
  fi
done
[ -s "$SHOTS/hardware-spec.png" ] \
  && echo "  [OK]   $SHOTS/hardware-spec.png" \
  || { echo "  [THIEU] $SHOTS/hardware-spec.png  ← ảnh spec máy (§6)"; MISSING=$((MISSING + 1)); }

echo ""
echo "── Đối chiếu timestamp (§11) ─────────────────────────────────────────"
echo "  Mở results/run-log.md và kiểm giờ trong ảnh khớp dòng tương ứng."
grep -E "^\| (Load|Stress|Spike|Soak)" results/run-log.md 2>/dev/null | tail -8 | sed 's/^/  /'

echo ""
if [ "$MISSING" -gt 0 ]; then
  echo "  Còn $MISSING ảnh chưa có. Ảnh thiếu là mất điểm mục bằng chứng §6."
else
  echo "  Đủ ảnh. Việc còn lại: quay video ≥6 phút và mở GitHub Issues."
fi
echo ""
