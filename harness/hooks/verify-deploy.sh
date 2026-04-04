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
fi

# Capture Playwright screenshots for visual review (non-blocking)
SCREENSHOT_DIR="$HOME/.claude/hooks/state/screenshots"
mkdir -p "$SCREENSHOT_DIR"
DESKTOP_IMG="${SCREENSHOT_DIR}/deploy-desktop.png"
MOBILE_IMG="${SCREENSHOT_DIR}/deploy-mobile.png"

npx playwright screenshot --browser=chromium --full-page --wait-for-timeout=3000 "$HOSTING_URL" "$DESKTOP_IMG" >/dev/null 2>&1 &
npx playwright screenshot --browser=chromium --full-page --wait-for-timeout=3000 --viewport-size="390,844" "$HOSTING_URL" "$MOBILE_IMG" >/dev/null 2>&1 &
wait

HAS_SCREENSHOTS="false"
if [ -f "$DESKTOP_IMG" ] && [ -f "$MOBILE_IMG" ]; then
  HAS_SCREENSHOTS="true"
fi

echo -e "✅ Deploy verification PASSED\n${RESULTS}" >&2
bash "$HOME/.claude/hooks/telegram-notify.sh" heartbeat "✅ Deploy verified: ${HOSTING_URL}" 2>/dev/null

if [ "$HAS_SCREENSHOTS" = "true" ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[DEPLOY-VERIFY OK] ${HOSTING_URL} HTTP 검증 통과. [필수] Playwright 스크린샷이 ${SCREENSHOT_DIR}/ 에 저장됨. Read 도구로 deploy-desktop.png + deploy-mobile.png을 확인하고 디자인 5패스 검토를 완료한 후에만 대표님께 보고하세요.\"}}"
else
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[DEPLOY-VERIFY OK] ${HOSTING_URL} HTTP 검증 통과. Playwright 스크린샷 실패 — 수동으로 Playwright 스크린샷 촬영 후 디자인 5패스 검토를 완료한 후에만 보고하세요.\"}}"
fi
exit 0
