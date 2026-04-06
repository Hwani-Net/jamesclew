#!/bin/bash
# SubagentStop hook: Verify URLs and GitHub repos in subagent output
# Extracts URLs/repos from last_assistant_message, checks existence via curl/gh

INPUT=$(cat)
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)

if [ -z "$LAST_MSG" ]; then
  exit 0
fi

STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"
LOG_FILE="$STATE_DIR/hallucination-check.log"

# Extract GitHub repo references — both URL and plain text patterns
# Pattern 1: github.com/owner/repo
REPOS_URL=$(echo "$LAST_MSG" | grep -oE 'github\.com/[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+' | sed 's|github.com/||' | sort -u)
# Pattern 2: plain text owner/repo mentions (e.g., "seanshin0214/persona-mcp")
# Match word/word patterns that look like GitHub repos, filter out file paths
REPOS_TEXT=$(echo "$LAST_MSG" | grep -oE '[a-zA-Z][a-zA-Z0-9_-]*/[a-zA-Z][a-zA-Z0-9_.-]{2,}' \
  | grep -vE '^(src|dist|lib|bin|test|docs|node_modules|\.claude|config|public|assets|com|org|net|io|dev|ai|www|Users|AppData|Program)/' \
  | grep -vE '\.(js|ts|md|json|sh|py|css|html|yaml|yml|txt|log|exe|dll|mjs|cjs)$' \
  | grep -vE '^(C|D|E):/|^/[a-z]+/' \
  | grep -vE '^v[0-9]' \
  | sort -u || true)
# Combine and deduplicate
REPOS=$(echo -e "${REPOS_URL}\n${REPOS_TEXT}" | sort -u | sed '/^$/d')

# Extract HTTP URLs
URLS=$(echo "$LAST_MSG" | grep -oE 'https?://[^ )<>,]+' | sort -u | head -10)

FAILED=0
CHECKED=0
FAILURES=""

# Check GitHub repos exist (skip if rate limited)
for REPO in $REPOS; do
  CHECKED=$((CHECKED + 1))
  RESP=$(curl -s -w "\n%{http_code}" --max-time 5 "https://api.github.com/repos/$REPO" 2>/dev/null)
  HTTP_CODE=$(echo "$RESP" | tail -1)
  if [ "$HTTP_CODE" = "404" ]; then
    FAILED=$((FAILED + 1))
    FAILURES="${FAILURES}\n  - GitHub repo NOT FOUND: $REPO"
    echo "[$(date +%H:%M:%S)] FAIL: repo $REPO (404)" >> "$LOG_FILE"
  elif [ "$HTTP_CODE" = "403" ] || [ "$HTTP_CODE" = "429" ]; then
    # Rate limited — skip remaining checks, don't false positive
    echo "[$(date +%H:%M:%S)] RATE LIMITED: skipping remaining repo checks" >> "$LOG_FILE"
    break
  fi
done

# Check npm packages exist
NPMS=$(echo "$LAST_MSG" | grep -oE 'npm (install|i) [a-zA-Z@][a-zA-Z0-9_./@-]+' | sed 's/npm i\(nstall\)\? //' | sort -u)
NPMS2=$(echo "$LAST_MSG" | grep -oE '"[a-zA-Z@][a-zA-Z0-9_./@-]+":\s*"[\^~]?[0-9]' | grep -oE '"[^"]+":' | tr -d '":' | sort -u)
for PKG in $NPMS $NPMS2; do
  CHECKED=$((CHECKED + 1))
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://registry.npmjs.org/$PKG" 2>/dev/null)
  if [ "$HTTP_CODE" = "404" ]; then
    FAILED=$((FAILED + 1))
    FAILURES="${FAILURES}\n  - npm package NOT FOUND: $PKG"
    echo "[$(date +%H:%M:%S)] FAIL: npm $PKG (404)" >> "$LOG_FILE"
  fi
done

# Check PyPI packages exist
PIPS=$(echo "$LAST_MSG" | grep -oE 'pip[3]? install [a-zA-Z][a-zA-Z0-9_.-]+' | sed 's/pip[3]\? install //' | sort -u)
for PKG in $PIPS; do
  # Skip well-known packages
  case "$PKG" in
    requests|flask|django|numpy|pandas|pytest|black|mypy|pip|setuptools) continue ;;
  esac
  CHECKED=$((CHECKED + 1))
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://pypi.org/pypi/$PKG/json" 2>/dev/null)
  if [ "$HTTP_CODE" = "404" ]; then
    FAILED=$((FAILED + 1))
    FAILURES="${FAILURES}\n  - PyPI package NOT FOUND: $PKG"
    echo "[$(date +%H:%M:%S)] FAIL: pypi $PKG (404)" >> "$LOG_FILE"
  fi
done

# Flag shortened/redirect URLs as suspicious
for URL in $URLS; do
  case "$URL" in
    *bit.ly/*|*tinyurl.com/*|*t.co/*|*goo.gl/*|*shorturl.at/*|*is.gd/*)
      FAILED=$((FAILED + 1))
      FAILURES="${FAILURES}\n  - SUSPICIOUS shortened URL: $URL"
      echo "[$(date +%H:%M:%S)] SUSPICIOUS: shortened url $URL" >> "$LOG_FILE"
      continue ;;
  esac
done

# Check URLs exist (HEAD request only)
for URL in $URLS; do
  # Skip known-good domains and already-flagged shortened URLs
  case "$URL" in
    *github.com/*/issues/*|*github.com/*/pull/*|*api.github.com/*) continue ;;
    *docs.anthropic.com*|*code.claude.com*) continue ;;
    *bit.ly/*|*tinyurl.com/*|*t.co/*|*goo.gl/*|*shorturl.at/*|*is.gd/*) continue ;;
  esac
  CHECKED=$((CHECKED + 1))
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -I --max-time 5 "$URL" 2>/dev/null)
  if [ "$HTTP_CODE" = "404" ] || [ "$HTTP_CODE" = "000" ]; then
    FAILED=$((FAILED + 1))
    FAILURES="${FAILURES}\n  - URL NOT FOUND ($HTTP_CODE): $URL"
    echo "[$(date +%H:%M:%S)] FAIL: url $URL ($HTTP_CODE)" >> "$LOG_FILE"
  fi
done

# If no checks were possible (network down, etc), warn about unverified output
if [ "$CHECKED" -eq 0 ] && [ -n "$REPOS$NPMS$PIPS$URLS" ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SubagentStop\",\"additionalContext\":\"⚠️ VERIFICATION SKIPPED: 네트워크/API 문제로 서브에이전트 출력을 검증할 수 없었습니다. 수동 검증이 필요합니다.\"}}"
  echo "[$(date +%H:%M:%S)] SKIPPED: network issue, manual verification needed" >> "$LOG_FILE"
fi

if [ "$FAILED" -gt 0 ]; then
  REASON="서브에이전트 출력에서 존재하지 않는 리소스 ${FAILED}개 발견 (${CHECKED}개 검사):${FAILURES}"
  # Output additionalContext to warn Claude
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SubagentStop\",\"additionalContext\":\"⚠️ HALLUCINATION WARNING: ${REASON}. 서브에이전트 결과를 신뢰하지 마세요. 직접 검증 후 사용하세요.\"}}"
else
  if [ "$CHECKED" -gt 0 ]; then
    echo "[$(date +%H:%M:%S)] OK: ${CHECKED} resources verified" >> "$LOG_FILE"
  fi
fi

exit 0
