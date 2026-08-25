#!/bin/bash
# night-batch-runner.sh v0.5 — 수면 창 야간 배치 (2026-08-25 Codex 크리틱 22건 수렴판)
# 능력 경계: opencode --agent night-batch (도구 전면 차단, 순수 생성) + --pure + 작업별 --dir
# 설계: docs/night-batch.md / 크리틱: docs/night-batch.md 참조
# NIGHT_BATCH_FORCE=1 = 창 밖 수동 테스트
set -u
BASE="$HOME/night-batch"
mkdir -p "$BASE"/{queue,running,work,done,failed,logs}   # 클린 설치에서도 시작 가능 (크리틱 #1)
LOG="$BASE/logs/run-$(date +%Y%m%d-%H%M%S).log"
LOCK="$BASE/.runner.lock"
OPENCODE="$HOME/.opencode/bin/opencode"
MAX_JOBS_PER_NIGHT=20
MAX_INSTR_BYTES=204800   # 200KB
CUTOFF_H=5; CUTOFF_M=30  # 05:30 이후 신규 작업 금지
# 레인 정확 allowlist (설계 표 4종)
ALLOWED_LANES="opencode-go/deepseek-v4-pro opencode-go/deepseek-v4-flash opencode-go/glm-5.3 opencode-go/mimo-v2.5-pro"

log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

secs_until_cutoff() {
  # 지금부터 다음 05:30까지 남은 초 (창 밖 FORCE 테스트면 큰 값)
  [[ "${NIGHT_BATCH_FORCE:-0}" == "1" ]] && { echo 86400; return; }
  local now h target
  now=$(date +%s); h=$(date +%H)
  if [[ "$h" == "23" ]]; then
    target=$(date -v+1d -v${CUTOFF_H}H -v${CUTOFF_M}M -v0S +%s)
  else
    target=$(date -v${CUTOFF_H}H -v${CUTOFF_M}M -v0S +%s)
  fi
  echo $(( target - now ))
}

in_window() {
  [[ "${NIGHT_BATCH_FORCE:-0}" == "1" ]] && return 0
  local h=$(date +%H)
  (( 10#$h == 23 || 10#$h < 6 )) || return 1   # 산술 비교 (shellcheck SC2071)
  [[ $(secs_until_cutoff) -gt 0 ]]
}

# ── singleton 락 (mkdir 원자 + PID 생존 확인) ──
acquire_lock() {
  if mkdir "$LOCK" 2>/dev/null; then echo $$ > "$LOCK/pid"; return 0; fi
  local oldpid; oldpid=$(cat "$LOCK/pid" 2>/dev/null)
  if [[ -n "$oldpid" ]] && kill -0 "$oldpid" 2>/dev/null; then return 1; fi
  # 죽은 소유자 — 회수
  rm -rf "$LOCK" 2>/dev/null; mkdir "$LOCK" 2>/dev/null || return 1
  echo $$ > "$LOCK/pid"
}
release_lock() { [[ "$(cat "$LOCK/pid" 2>/dev/null)" == "$$" ]] && rm -rf "$LOCK"; }

acquire_lock || exit 0
trap 'release_lock' EXIT
[[ -x "$OPENCODE" ]] || { log "FATAL: opencode 없음"; exit 1; }
umask 077
mkdir -p "$BASE/work"

log "=== 야간 배치 v0.5 시작 (host=$(hostname -s), pid=$$) ==="

# ── 크래시 복구: 이전 실행 잔존물은 재실행하지 않고 아침 보고행 ──
for leftover in "$BASE/running"/*.md; do
  [[ -e "$leftover" ]] || break
  n=$(basename "$leftover")
  mv "$leftover" "$BASE/failed/recovered-$n"
  log "복구: running/$n → failed/recovered-$n (이전 실행 크래시 잔존)"
done

run_job() {  # $1=지시서(running 경로) $2=job이름
  local run_file="$1" name="$2"
  local lane jto instr_size remain eff_to
  instr_size=$(wc -c < "$run_file")
  if [[ $instr_size -gt $MAX_INSTR_BYTES ]]; then
    log "거부 $name: 지시서 ${instr_size}B > ${MAX_INSTR_BYTES}B"; mv "$run_file" "$BASE/failed/$name.md"; return; fi

  lane=$(awk -F': ' '/^lane:/{print $2; exit}' "$run_file" | tr -d '[:space:]')
  jto=$(awk -F': ' '/^timeout:/{print $2; exit}' "$run_file" | tr -d '[:space:]')
  lane="${lane:-opencode-go/deepseek-v4-pro}"
  case " $ALLOWED_LANES " in
    *" $lane "*) ;;
    *) log "거부 $name: 비허용 레인 '$lane'"; mv "$run_file" "$BASE/failed/$name.md"; return ;;
  esac
  [[ "$jto" =~ ^[0-9]+$ ]] || jto=1800
  (( jto < 60 )) && jto=60; (( jto > 3600 )) && jto=3600
  remain=$(secs_until_cutoff)
  eff_to=$(( jto < remain ? jto : remain ))
  (( eff_to < 60 )) && { log "중단 $name: 컷오프 임박(${remain}s) — 큐 반환"; mv "$run_file" "$BASE/queue/$name.md"; return 1; }

  local work="$BASE/work/$name"
  mkdir -p "$work"

  # ── aside 웹 수집 (기본 제공): 지시서의 fetch: URL들을 러너가 대행 수집해 자료로 첨부 ──
  # LLM은 무도구 유지 — 웹접근은 러너의 결정론 수집 + 자료 첨부로 기본 제공 (2026-08-25 사용자 지시)
  local fetch_args=() furl fi=0
  while IFS= read -r furl; do
    furl=$(echo "$furl" | sed 's/^fetch: *//' | tr -d '[:space:]')
    [[ "$furl" =~ ^https:// ]] || continue   # https 전용 (SSRF 표면 축소 — 사설IP 검증은 백로그)
    (( fi >= 8 )) && { log "$name: fetch 상한(8) 초과 — 이후 URL 생략"; break; }
    fi=$((fi+1))
    if curl -sL --fail --proto '=https' --proto-redir '=https' --max-time 45 --max-filesize 3000000 -A "Mozilla/5.0" "$furl" -o "$work/fetched-$fi.html" 2>/dev/null && [[ -s "$work/fetched-$fi.html" ]]; then
      printf '<!-- source: %s -->\n' "$furl" | cat - "$work/fetched-$fi.html" > "$work/fetched-$fi.tmp" && mv "$work/fetched-$fi.tmp" "$work/fetched-$fi.html"
      fetch_args+=(-f "$work/fetched-$fi.html")
      log "$name: fetch OK [$fi] $furl ($(wc -c < "$work/fetched-$fi.html")B)"
    else
      log "$name: fetch 실패 [$fi] $furl"
    fi
  done < <(grep '^fetch:' "$run_file")

  log "실행 $name lane=$lane eff_timeout=${eff_to}s (요청 ${jto}s, 웹자료 ${#fetch_args[@]}건)"
  local start_ts=$(date +%s)

  # 독립 프로세스 그룹으로 실행 → 데드라인 시 그룹 전체 TERM→KILL
  perl -e 'setpgrp(0,0); exec @ARGV' \
    "$OPENCODE" run \
    "Follow the instruction in the attached instruction file. Header lines (lane/timeout/fetch) are metadata - ignore them. Additional attached files are fetched web material to use as source data." \
    --pure --agent night-batch -m "$lane" --dir "$work" \
    -f "$run_file" ${fetch_args[@]+"${fetch_args[@]}"} \
    > "$work/out.md" 2> "$work/stderr.log" &
  local pid=$!
  local waited=0 rc=124
  while (( waited < eff_to )); do
    kill -0 "$pid" 2>/dev/null || { wait "$pid"; rc=$?; break; }
    sleep 5; waited=$((waited+5))
  done
  if kill -0 "$pid" 2>/dev/null; then
    kill -TERM -"$pid" 2>/dev/null; sleep 10
    kill -KILL -"$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    rc=124; log "타임아웃 $name: 프로세스 그룹 종료"
  fi
  local dur=$(( $(date +%s) - start_ts ))

  # 원자 커밋: work/<job>을 통째로 done|failed로 승격 (부분 상태 노출 없음)
  printf '{"job":"%s","lane":"%s","exit":%d,"duration_s":%d,"eff_timeout_s":%d,"finished":"%s","instr_sha":"%s"}\n' \
    "$name" "$lane" "$rc" "$dur" "$eff_to" "$(date '+%F %T')" "$(shasum -a 256 "$run_file" | cut -c1-16)" > "$work/meta.json"
  mv "$run_file" "$work/instruction.md"
  if [[ $rc -eq 0 && -s "$work/out.md" ]]; then
    mv "$work" "$BASE/done/$name"; log "완료 $name (${dur}s)"
  else
    mv "$work" "$BASE/failed/$name"; log "실패 $name exit=$rc (${dur}s)"
  fi
}

count=0
while in_window; do
  job=$(ls "$BASE/queue"/*.md 2>/dev/null | sort | head -1)
  [[ -z "$job" ]] && { log "큐 비었음 — 종료"; break; }
  [[ $count -ge $MAX_JOBS_PER_NIGHT ]] && { log "야간 상한 도달 — 종료"; break; }
  name=$(basename "$job" .md)
  # job 이름 검증 (경로 탈출 방지)
  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { log "거부: 비정상 이름 '$name'"; mv "$job" "$BASE/failed/badname-$$.md"; continue; }
  run_file="$BASE/running/$name.md"
  mv "$job" "$run_file" 2>/dev/null || continue
  run_job "$run_file" "$name" || break   # 컷오프 임박 신호면 루프 종료
  count=$((count+1))
done

log "=== 야간 배치 종료: ${count}건 처리 ==="
