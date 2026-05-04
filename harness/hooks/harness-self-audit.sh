#!/bin/bash
# harness-self-audit.sh — 메타 hook (2026-05-04 신설, P-111 영구 차단)
#
# 외부 검수(Codex gpt-5.5 + GPT-4.1) 권장 설계:
#   SessionStart + 주 1회 cron으로 모든 hook의 4단계 자동 검증.
#   1. 등록 (settings.json hooks 배열 entry)
#   2. 존재 (파일 + 실행권한)
#   3. 입력 (의존 state 파일 공급원 매핑 검증)
#   4. 실행 (TEST_HARNESS 모드 dry-run exit 0)
#
# 침묵 hook 발견 시:
#   - ~/.harness-state/hook_audit_report.txt 기록
#   - SessionStart additionalContext 주입 (Claude가 인지)
#   - 텔레그램 알림 (실패 허용)

set -euo pipefail

[[ -n "${TEST_HARNESS:-}" ]] && {
  echo "[TEST] harness-self-audit.sh — settings.json 파싱 + 4단계 검증 시뮬레이션"
  exit 0
}

REPORT="$HOME/.harness-state/hook_audit_report.txt"
SETTINGS="$HOME/.claude/settings.json"
HOOKS_DIR="$HOME/.claude/hooks"

mkdir -p "$(dirname "$REPORT")"

# ── 의존 매트릭스: hook이 동작하려면 필요한 state 파일 공급원 (P-111 audit 결과) ──
# format: hook_name|state_path|type (static = 항상 존재해야, dynamic = 필요 시 생성)
DEPS_MAP="
emergency-mode-check.sh|$HOME/.harness-state/5h_usage.txt|static
self-evolve-trigger.sh|$HOME/.harness-state/context_usage.txt|optional
pitfall-auto-record-stop.sh|pitfall_pending.json|dynamic
enforce-build-transition.sh|build-{hash}/build_detected|dynamic
"

# ── settings.json에서 등록된 hook 파일 목록 추출 ──
REGISTERED=$(python3 - "$SETTINGS" 2>/dev/null <<'PYEOF' || echo ""
import json, sys, re
try:
    with open(sys.argv[1], encoding='utf-8') as f:
        s = json.load(f)
except Exception as e:
    print(f"ERROR:settings_parse:{e}", file=sys.stderr)
    sys.exit(1)
hooks = s.get('hooks', {})
seen = set()
for event, hlist in hooks.items():
    for h in hlist:
        for inner in h.get('hooks', []):
            cmd = inner.get('command', '')
            m = re.search(r'hooks/([\w\-]+\.sh)', cmd)
            if m:
                key = f'{event}\t{m.group(1)}'
                if key not in seen:
                    seen.add(key)
                    sys.stdout.write(key + '\n')
PYEOF
)
# Windows CRLF 제거 (Git Bash + Windows Python 호환)
REGISTERED=$(echo "$REGISTERED" | tr -d '\r')

if [ -z "$REGISTERED" ]; then
  echo "[harness-self-audit] settings.json 파싱 실패 — skip" >&2
  exit 0
fi

ISSUES=""
ISSUE_COUNT=0
PASS_COUNT=0
TOTAL=0

while IFS=$'\t' read -r EVENT HOOK; do
  [ -z "$HOOK" ] && continue
  TOTAL=$((TOTAL+1))
  HOOK_PATH="$HOOKS_DIR/$HOOK"

  # 1. 존재
  if [ ! -f "$HOOK_PATH" ]; then
    ISSUES="${ISSUES}- $EVENT/$HOOK: 파일 없음\n"
    ISSUE_COUNT=$((ISSUE_COUNT+1))
    continue
  fi

  # 2. 의존 state 파일 (static만 검사)
  DEP_LINE=$(echo "$DEPS_MAP" | grep "^$HOOK|" || true)
  if [ -n "$DEP_LINE" ]; then
    DEP_TYPE=$(echo "$DEP_LINE" | awk -F'|' '{print $3}')
    DEP_PATH=$(echo "$DEP_LINE" | awk -F'|' '{print $2}')
    if [ "$DEP_TYPE" = "static" ] && [ ! -f "$DEP_PATH" ]; then
      ISSUES="${ISSUES}- $EVENT/$HOOK: 의존 state 부재 — $DEP_PATH (공급원 hook 점검 필요)\n"
      ISSUE_COUNT=$((ISSUE_COUNT+1))
      continue
    fi
  fi

  # 3. TEST_HARNESS 모드 dry-run (TEST 분기 있는 hook만)
  if grep -q 'TEST_HARNESS' "$HOOK_PATH" 2>/dev/null; then
    if ! TEST_HARNESS=1 timeout 5 bash "$HOOK_PATH" </dev/null >/dev/null 2>&1; then
      ISSUES="${ISSUES}- $EVENT/$HOOK: TEST 모드 실행 실패 (exit 비0 또는 timeout)\n"
      ISSUE_COUNT=$((ISSUE_COUNT+1))
      continue
    fi
  fi

  PASS_COUNT=$((PASS_COUNT+1))
done <<< "$REGISTERED"

# 보고서 작성
{
  echo "# Harness Self-Audit Report"
  echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  echo "## Summary"
  echo "- Total registered: $TOTAL"
  echo "- PASS: $PASS_COUNT"
  echo "- ISSUES: $ISSUE_COUNT"
  echo ""
  echo "## Issues"
  if [ "$ISSUE_COUNT" -eq 0 ]; then
    echo "(none)"
  else
    printf "%b" "$ISSUES"
  fi
} > "$REPORT"

# 침묵 hook 있으면 알림
if [ "$ISSUE_COUNT" -gt 0 ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"[HARNESS-AUDIT] $ISSUE_COUNT건 침묵 hook 의심 — 보고서: $REPORT (cat 으로 확인). P-111 패턴 재발 가능성.\"}}"

  if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
    SHORT=$(printf "%b" "$ISSUES" | head -c 300)
    curl -s --max-time 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      --data-urlencode "text=[HARNESS-AUDIT] $ISSUE_COUNT건 hook 침묵 의심: $SHORT" > /dev/null 2>&1 || true
  fi
fi

exit 0
