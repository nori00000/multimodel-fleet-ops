#!/bin/bash
# quota-refresh.sh v2 — Claude/Codex 잔량 수집 → 캐시 원자 기록 (2026-08-25 크리틱 수렴판)
# 느림(codex ~30s+) — 백그라운드 전용. 소스별 성공/실패를 분리 기록, 실패 시 last_good 보존.
set -u
umask 077
STATE_DIR="$HOME/.claude/state"
OUT="$STATE_DIR/quota-status.json"
LOCK="$STATE_DIR/.quota-refresh.lock"
mkdir -p "$STATE_DIR"

# mkdir 원자 락 + PID 생존 확인
if ! mkdir "$LOCK" 2>/dev/null; then
  oldpid=$(cat "$LOCK/pid" 2>/dev/null)
  if [[ -n "$oldpid" ]] && kill -0 "$oldpid" 2>/dev/null; then exit 0; fi
  rm -rf "$LOCK" 2>/dev/null; mkdir "$LOCK" 2>/dev/null || exit 0
fi
echo $$ > "$LOCK/pid"
TMP=""
trap '[[ -n "$TMP" ]] && rm -f "$TMP"; [[ "$(cat "$LOCK/pid" 2>/dev/null)" == "$$" ]] && rm -rf "$LOCK"' EXIT

run_to() { perl -e 'alarm shift; exec @ARGV' "$@" 2>/dev/null; }

CLAUDE_JSON=$(run_to 15 "$HOME/bin/claude-usage-now"); CLAUDE_RC=$?
CODEX_RAW=$(run_to 90 "$HOME/bin/codex-usage-now"); CODEX_RC=$?
PREV=$(cat "$OUT" 2>/dev/null || echo '{}')

export CLAUDE_JSON CODEX_RAW PREV CLAUDE_RC CODEX_RC
TMP=$(mktemp "$STATE_DIR/.quota-status.XXXXXX") || exit 1
python3 - > "$TMP" <<'PY'
import json, os, time
now = int(time.time())
try: prev = json.loads(os.environ.get("PREV") or "{}")
except Exception: prev = {}

def src(ok, data, prev_key):
    if ok and data:
        return {"ok": True, "collected_at": now, "data": data}
    old = prev.get(prev_key, {})
    return {"ok": False, "collected_at": old.get("collected_at"),
            "error": "collect_failed", "data": old.get("data", {})}

claude_data = {}
if os.environ.get("CLAUDE_RC") == "0":
    try: claude_data = json.loads(os.environ.get("CLAUDE_JSON") or "")
    except Exception: claude_data = {}

codex_data = {}
if os.environ.get("CODEX_RC") == "0":
    for line in (os.environ.get("CODEX_RAW") or "").splitlines():
        if ": " in line:
            k, v = line.split(": ", 1)
            if k in ("plan","weekly_used","weekly_remaining","weekly_resets_at","weekly_refills_in","5h_remaining"):
                codex_data[k] = v.strip()

out = {"written_at": now,
       "claude": src(bool(claude_data), claude_data, "claude"),
       "codex": src(bool(codex_data), codex_data, "codex")}
print(json.dumps(out, ensure_ascii=False))
PY
rc=$?
if [[ $rc -eq 0 && -s "$TMP" ]]; then
  mv "$TMP" "$OUT" || exit 1
  TMP=""
else
  exit 1
fi
