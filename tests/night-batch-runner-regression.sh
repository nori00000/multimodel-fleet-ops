#!/bin/bash
# Regression: rerunning an identically named job must create sibling archives,
# never done/<job>/<job> or failed/<job>/<job>.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT
BASE="$TEST_HOME/night-batch"
FAKE="$TEST_HOME/.opencode/bin/opencode"

mkdir -p "$(dirname "$FAKE")" "$BASE/queue"
cat > "$FAKE" <<'EOF'
#!/bin/bash
printf 'generated output\n'
exit "${FAKE_OPENCODE_EXIT:-0}"
EOF
chmod +x "$FAKE"

enqueue() {
  printf 'lane: opencode-go/deepseek-v4-pro\ntimeout: 60\nrepeat regression\n' > "$BASE/queue/repeat.md"
}

run_runner() {
  HOME="$TEST_HOME" NIGHT_BATCH_FORCE=1 FAKE_OPENCODE_EXIT="$1" \
    bash "$ROOT/scripts/night-batch-runner.sh"
}

enqueue; run_runner 0
enqueue; run_runner 0
[[ -d "$BASE/done/repeat" ]]
[[ -d "$BASE/done/repeat-2" ]]
[[ ! -e "$BASE/done/repeat/repeat" ]]

enqueue; run_runner 1
enqueue; run_runner 1
[[ -d "$BASE/failed/repeat" ]]
[[ -d "$BASE/failed/repeat-2" ]]
[[ ! -e "$BASE/failed/repeat/repeat" ]]

printf 'night-batch repeated-name regression: PASS\n'
