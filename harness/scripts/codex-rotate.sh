#!/usr/bin/env bash
# codex-rotate.sh — Codex 멀티계정 로테이션 래퍼
# Usage: bash codex-rotate.sh "프롬프트"
# 기본 계정 → 429 시 다음 계정으로 자동 전환 (최대 6개)
# evaluator.sh 외에 blog-review, blog-fix 등에서도 사용

set -euo pipefail

PROMPT="$*"
ACCOUNTS_DIR="$HOME/.codex-accounts"
CODEX_CONFIG="$HOME/.codex"
STATE_FILE="$HOME/.harness-state/codex-rotation-state"

# Ensure state dir exists
mkdir -p "$(dirname "$STATE_FILE")"

# Collect accounts
ACCTS=()
if [ -d "$ACCOUNTS_DIR" ]; then
  while IFS= read -r f; do ACCTS+=("$f"); done \
    < <(ls "$ACCOUNTS_DIR"/account*.json 2>/dev/null | sort)
fi

if [ ${#ACCTS[@]} -eq 0 ]; then
  echo "ERROR: No accounts in $ACCOUNTS_DIR" >&2
  exit 1
fi

# Read last successful account index
LAST_IDX=0
[ -f "$STATE_FILE" ] && LAST_IDX=$(cat "$STATE_FILE" 2>/dev/null || echo 0)

# Try each account starting from last successful
for (( i=0; i<${#ACCTS[@]}; i++ )); do
  IDX=$(( (LAST_IDX + i) % ${#ACCTS[@]} ))
  ACCT="${ACCTS[$IDX]}"
  ACCT_NAME=$(basename "$ACCT" .json)

  # Swap auth
  cp "$ACCT" "$CODEX_CONFIG/auth.json" 2>/dev/null || true

  # Run codex
  OUTPUT=$(codex exec "$PROMPT" 2>&1) || true

  # Check for rate limit
  if echo "$OUTPUT" | grep -q "usage_limit_reached\|429\|rate.*limit\|hit your usage limit"; then
    echo "[codex-rotate] $ACCT_NAME: rate limited, trying next..." >&2
    continue
  fi

  # Success — save state and output
  echo "$IDX" > "$STATE_FILE"
  echo "$OUTPUT"
  exit 0
done

# All accounts exhausted
echo "[codex-rotate] All ${#ACCTS[@]} accounts rate limited. Trying GLM-5.1 via ollama-cloud-rotate.sh..." >&2

# GLM-5.1 cloud fallback (7 accounts, free)
GLM_RESULT=$(bash "$(dirname "$0")/ollama-cloud-rotate.sh" "$PROMPT" 2>/dev/null)

if [ -n "$GLM_RESULT" ]; then
  echo "[codex-rotate] GLM-5.1 fallback result:"
  echo "$GLM_RESULT"
  exit 0
fi

echo "[codex-rotate] GLM-5.1 also failed. Falling back to gemma4." >&2

# Gemma4 fallback
RESULT=$(curl -s http://localhost:11434/api/generate -d "{
  \"model\": \"gemma3:12b\",
  \"prompt\": \"$PROMPT\",
  \"stream\": false,
  \"options\": {\"num_predict\": 2000}
}" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('response',''))" 2>/dev/null)

if [ -n "$RESULT" ]; then
  echo "[codex-rotate] gemma4 fallback result:"
  echo "$RESULT"
  exit 0
fi

echo "[codex-rotate] ALL MODELS EXHAUSTED. Manual intervention needed." >&2
exit 1
