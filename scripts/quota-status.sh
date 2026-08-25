#!/bin/bash
# quota-status.sh v2 — SessionStart 훅: 캐시 즉시 표시(비차단) + stale/오류 시 백그라운드 갱신 (크리틱 수렴판)
# fail-open: 어떤 실패에도 세션 시작을 막지 않는다. raw 외부 문자열은 위생 처리 후 출력.
OUT="$HOME/.claude/state/quota-status.json"
MAX_AGE=2700

refresh_bg() { nohup "$HOME/.claude/scripts/quota-refresh.sh" </dev/null >/dev/null 2>&1 & }

if [[ ! -f "$OUT" ]]; then
  echo "━ 쿼터 상태: 캐시 없음 — 백그라운드 수집 시작 (다음 세션부터 표시) ━"
  refresh_bg
  exit 0
fi

python3 - "$OUT" "$MAX_AGE" 2>/dev/null <<'PY'
import json, re, sys, time

def clean(s, maxlen=40):
    s = re.sub(r'[\x00-\x1f\x7f]|\x1b\[[0-9;]*m', '', str(s))
    return s[:maxlen] if s else "?"

d = json.load(open(sys.argv[1]))
max_age = int(sys.argv[2])
now = int(time.time())
wa = d.get("written_at", d.get("generated_at", 0))
if not isinstance(wa, int) or wa <= 0 or wa > now + 60:
    sys.exit(3)  # 손상/미래 타임스탬프 = invalid
age = now - wa

c = d.get("claude", {}); x = d.get("codex", {})
c_data = c.get("data", c) if isinstance(c, dict) else {}
x_data = x.get("data", x) if isinstance(x, dict) else {}

cu = c_data.get("used_percent")
if cu is not None:
    claude_s = clean(cu) + "%"
elif c_data.get("healthy"):
    claude_s = "여유(no_active_limit)"
elif isinstance(c, dict) and c.get("ok") is False:
    claude_s = "수집실패(이전값 기준)"
else:
    claude_s = "불명"

codex_note = "" if not (isinstance(x, dict) and x.get("ok") is False) else " [수집실패·이전값]"
print(f"━ 쿼터 상태 (캐시 {age//60}분 전) ━")
print(f"Claude 사용률: {claude_s} | Codex 주간 잔량: {clean(x_data.get('weekly_remaining','?'))}{codex_note} (리필 {clean(x_data.get('weekly_refills_in','?'))})")

try:
    if cu is not None and float(cu) >= 75:
        print("→ 소진 사다리 ①.5 절약 모드 권고: Fable=지휘 전용, 실행·대량 읽기 외부 레인으로")
except (TypeError, ValueError):
    pass
try:
    wr = str(x_data.get("weekly_remaining", "")).rstrip("%")
    if wr and float(wr) <= 25:
        print("→ Codex 주간 잔량 주의: 크리틱 우선 배정, 구현 폴백 자제")
except (TypeError, ValueError):
    pass

sys.exit(2 if age > max_age else 0)
PY
rc=$?
case "$rc" in
  0) ;;
  2) echo "(캐시 만료 — 백그라운드 갱신 시작)"; refresh_bg ;;
  *) echo "━ 쿼터 상태: 캐시 손상/읽기 실패 — 백그라운드 갱신 시작 ━"; refresh_bg ;;
esac
exit 0
