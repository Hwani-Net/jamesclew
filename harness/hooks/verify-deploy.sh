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

FAIL=0
RESULTS=""

# Check key endpoints
for ENDPOINT in "/" "/sitemap.xml" "/404.html"; do
  URL="${HOSTING_URL}${ENDPOINT}"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL" 2>/dev/null)
  if [ "$STATUS" = "200" ]; then
    RESULTS="${RESULTS}  ✅ ${ENDPOINT} → ${STATUS}\n"
  else
    RESULTS="${RESULTS}  ❌ ${ENDPOINT} → ${STATUS}\n"
    FAIL=1
  fi
done

if [ "$FAIL" -eq 1 ]; then
  echo -e "🚨 Deploy verification FAILED\n${RESULTS}" >&2
  bash "$HOME/.claude/hooks/telegram-notify.sh" heartbeat "❌ Deploy verification failed: ${HOSTING_URL}" 2>/dev/null
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[DEPLOY-VERIFY FAILED] ${HOSTING_URL} 라이브 검증 실패. 수정 후 재배포 필요. 검증 통과 전까지 대표님께 보고 금지.\"}}" >&2
  exit 2
else
  echo -e "✅ Deploy verification PASSED\n${RESULTS}" >&2
  bash "$HOME/.claude/hooks/telegram-notify.sh" heartbeat "✅ Deploy verified: ${HOSTING_URL}" 2>/dev/null
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[DEPLOY-VERIFY OK] ${HOSTING_URL} 라이브 검증 통과 (index/sitemap/404 모두 200). 대표님께 결과 보고 가능.\"}}" >&2
  exit 0
fi
