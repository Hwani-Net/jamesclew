#!/bin/bash
# Post-deploy live verification hook.
# Triggered after `firebase deploy` via PostToolUse on Bash.
# Checks HTTP 200 on deployed site. Fails if verification fails.

# Consume stdin (required by hook protocol)
INPUT=$(cat)

# Determine hosting URL from .firebaserc (most reliable)
HOSTING_URL=""
for RC in ".firebaserc" "pipelines/blog/.firebaserc"; do
  if [ -f "$RC" ]; then
    PROJECT_ID=$(sed -n 's/.*"default"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$RC" 2>/dev/null)
    if [ -n "$PROJECT_ID" ]; then
      HOSTING_URL="https://${PROJECT_ID}.web.app"
      break
    fi
  fi
done

# Fallback: try to extract from stdin
if [ -z "$HOSTING_URL" ]; then
  PROJECT_ID=$(echo "$INPUT" | sed -n 's/.*https:\/\/\([^.]*\)\.web\.app.*/\1/p' | head -1)
  if [ -n "$PROJECT_ID" ]; then
    HOSTING_URL="https://${PROJECT_ID}.web.app"
  fi
fi

if [ -z "$HOSTING_URL" ]; then
  echo "⚠️ verify-deploy: Could not determine hosting URL" >&2
  exit 0
fi

# ─── Pipeline step evidence check ───
STATE_DIR="$HOME/.harness-state"
REVIEW_FILE="$STATE_DIR/pipeline_review_done"
MISSING_STEPS=""

if [ ! -f "$REVIEW_FILE" ]; then
  MISSING_STEPS="${MISSING_STEPS}Step 2 (품질검수 — /ultrareview) "
elif [ "$(wc -c < "$REVIEW_FILE" 2>/dev/null)" -lt 20 ] 2>/dev/null; then
  MISSING_STEPS="${MISSING_STEPS}Step 2 (증거 불충분 — pipeline_review_done 최소 20byte, 현재 $(wc -c < "$REVIEW_FILE")byte) "
elif ! grep -qiE 'ultrareview|verdict|PASS|FAIL|REWORK|step.*2|"step":2' "$REVIEW_FILE" 2>/dev/null; then
  # Must contain /ultrareview result signature — prevents self-review bypass
  MISSING_STEPS="${MISSING_STEPS}Step 2 (ultrareview 시그니처 없음 — /ultrareview 결과 JSON이어야 함) "
fi

if [ -n "$MISSING_STEPS" ]; then
  echo "🚫 Pipeline step 미완료: ${MISSING_STEPS}" >&2
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"[PIPELINE BLOCK] 배포 차단 — ${MISSING_STEPS}. /ultrareview 완료 후 echo '{\\\"step\\\":2,\\\"verdict\\\":\\\"PASS\\\"}' > ~/.harness-state/pipeline_review_done 실행 후 재배포.\"}}" >&2
  exit 2
fi

# ─── Sanity check: quick curl before handing off to expect MCP ───
# Hook can block (exit 2) on hard failure; expect MCP handles deep verification
QUICK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$HOSTING_URL/" 2>/dev/null)
if [ "$QUICK_STATUS" != "200" ]; then
  echo "🚨 Deploy verification FAILED: ${HOSTING_URL}/ → HTTP ${QUICK_STATUS}" >&2
  bash "$HOME/.claude/hooks/telegram-notify.sh" error "Deploy verification failed: ${HOSTING_URL} (HTTP ${QUICK_STATUS})" 2>/dev/null
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[DEPLOY-VERIFY FAILED] ${HOSTING_URL} HTTP ${QUICK_STATUS}. 수정 후 재배포 필요. 검증 통과 전까지 대표님께 보고 금지.\"}}" >&2
  exit 2
fi

# ─── URL validation (prevent injection) ───
if ! echo "$HOSTING_URL" | grep -qE '^https://[a-zA-Z0-9._-]+\.web\.app$'; then
  echo "⚠️ verify-deploy: URL format invalid: $HOSTING_URL" >&2
  exit 0
fi

# ─── expect MCP 브라우저 검증 지시 (Playwright 대체) ───
# hook에서 MCP 직접 호출 불가 → additionalContext로 에이전트에 지시 주입

bash "$HOME/.claude/hooks/telegram-notify.sh" heartbeat 2>/dev/null

VERIFY_DIRECTIVE="[DEPLOY-VERIFY OK] ${HOSTING_URL} HTTP 200 통과. expect MCP로 심층 검증 필수 (순서대로):
1. mcp__expect__open(url: \"${HOSTING_URL}\") — 페이지 로드
2. mcp__expect__network_requests() — 4xx/5xx, 중복 요청, mixed content 확인
3. mcp__expect__console_logs(type: \"error\") — JS 에러 확인
4. mcp__expect__screenshot() — 데스크톱 풀페이지
5. mcp__expect__playwright(script: \"page.setViewportSize({width:390,height:844})\") → mcp__expect__screenshot() — 모바일
6. mcp__expect__accessibility_audit() — WCAG 접근성
7. mcp__expect__close()

network_requests에서 4xx/5xx 발견 시 FAIL → 수정 후 재배포. 전체 통과 시에만 대표님께 보고."

echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"${VERIFY_DIRECTIVE}\"}}"
exit 0
