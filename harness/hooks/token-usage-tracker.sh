#!/bin/bash
# token-usage-tracker.sh — Stop hook. 세션의 토큰 사용량을 시간대별로 원장에 적재.
#
# 왜 필요한가: 원격 세션 컨테이너는 휘발성이라 세션이 끝나면
# ~/.claude/projects/**/*.jsonl 트랜스크립트가 사라진다. 세션이 멈출 때마다
# 시간대별 롤업을 ~/.harness-state/token_usage.jsonl 로 뽑아 두면
# token-usage-report.py 가 여러 세션을 가로질러 집계할 수 있다.
#
# 원장 한 줄 = (session_id, hour) 단위 누적 스냅샷. 같은 키가 여러 번 기록되므로
# 리포트 쪽에서 rev가 가장 큰 행만 채택한다(중복 합산 방지).
# 관측 전용 — 아무것도 차단하지 않고 항상 exit 0.

cat >/dev/null 2>&1   # hook stdin 소비 (사용하지 않음)

STATE_DIR="$HOME/.harness-state"
LOG="$STATE_DIR/token_usage.jsonl"
SCRIPT="$HOME/.claude/scripts/token-usage-report.py"
mkdir -p "$STATE_DIR"

# 리포에서 직접 실행되는 경우(하네스 미설치)도 지원
[ -f "$SCRIPT" ] || SCRIPT="$(dirname "$(dirname "$(readlink -f "$0")")")/scripts/token-usage-report.py"
[ -f "$SCRIPT" ] || exit 0

PY=$(command -v python3 || command -v python) || exit 0

TMP=$(mktemp) || exit 0
if "$PY" "$SCRIPT" --emit-ledger >"$TMP" 2>/dev/null && [ -s "$TMP" ]; then
  cat "$TMP" >>"$LOG"
fi
rm -f "$TMP"

# 원장이 무한정 커지지 않도록 최근 20000줄만 유지
if [ "$(wc -l <"$LOG" 2>/dev/null || echo 0)" -gt 20000 ]; then
  tail -n 20000 "$LOG" >"$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

exit 0
