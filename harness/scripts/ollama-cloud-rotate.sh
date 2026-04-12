#!/usr/bin/env bash
# ollama-cloud-rotate.sh -- Ollama cloud account key rotation wrapper
# Usage: bash ollama-cloud-rotate.sh "prompt"
# Rotates ~/.ollama keys per account on rate limit; falls back to gemma4:31b

set -euo pipefail

PROMPT="$*"
ACCOUNTS_DIR="$HOME/.ollama-accounts"
OLLAMA_DIR="$HOME/.ollama"
STATE_FILE="$HOME/.harness-state/ollama-rotation-state"
CLOUD_MODEL="glm-5.1:cloud"
FALLBACK_MODEL="gemma4:31b"
API="http://localhost:11434/api/generate"

mkdir -p "$(dirname "$STATE_FILE")"

# JSON-escape prompt once
EP=$(printf '%s' "$PROMPT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")

ollama_call() { # $1=model -> prints response text or empty
  curl -s --max-time 120 "$API" -H "Content-Type: application/json" \
    -d "{\"model\":\"$1\",\"prompt\":$EP,\"stream\":false,\"options\":{\"num_predict\":4096}}" 2>/dev/null \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('response',''))" 2>/dev/null
}

# Collect accounts
ACCTS=()
if [ -d "$ACCOUNTS_DIR" ]; then
  while IFS= read -r d; do
    [ -f "$d/id_ed25519" ] && ACCTS+=("$d")
  done < <(ls -d "$ACCOUNTS_DIR"/account*/ 2>/dev/null | sort)
fi

if [ ${#ACCTS[@]} -gt 0 ]; then
  LAST_IDX=0; [ -f "$STATE_FILE" ] && LAST_IDX=$(cat "$STATE_FILE" 2>/dev/null || echo 0)

  for (( i=0; i<${#ACCTS[@]}; i++ )); do
    IDX=$(( (LAST_IDX + i) % ${#ACCTS[@]} ))
    ACCT="${ACCTS[$IDX]}"
    mkdir -p "$OLLAMA_DIR"
    cp "$ACCT/id_ed25519"     "$OLLAMA_DIR/id_ed25519"     2>/dev/null || true
    cp "$ACCT/id_ed25519.pub" "$OLLAMA_DIR/id_ed25519.pub" 2>/dev/null || true
    chmod 600 "$OLLAMA_DIR/id_ed25519" 2>/dev/null || true
    echo "[ollama-rotate] account$((IDX+1)) -> $CLOUD_MODEL" >&2

    RAW=$(curl -s --max-time 120 "$API" -H "Content-Type: application/json" \
      -d "{\"model\":\"$CLOUD_MODEL\",\"prompt\":$EP,\"stream\":false}" 2>/dev/null) || true

    if [ -z "$RAW" ] || echo "$RAW" | grep -qi "rate.limit\|quota\|429\|usage.limit\|credit"; then
      echo "[ollama-rotate] account$((IDX+1)): rate limited, next..." >&2; continue
    fi

    RESULT=$(echo "$RAW" | python3 -c "import sys,json; print(json.load(sys.stdin).get('response',''))" 2>/dev/null)
    if [ -n "$RESULT" ]; then echo "$IDX" > "$STATE_FILE"; echo "$RESULT"; exit 0; fi
  done
  echo "[ollama-rotate] All ${#ACCTS[@]} cloud accounts exhausted -> $FALLBACK_MODEL" >&2
else
  echo "[ollama-rotate] No accounts found -> $FALLBACK_MODEL" >&2
fi

# Local fallback -- always free
RESULT=$(ollama_call "$FALLBACK_MODEL")
if [ -n "$RESULT" ]; then echo "[ollama-rotate] $FALLBACK_MODEL:"; echo "$RESULT"; exit 0; fi

echo "[ollama-rotate] ALL MODELS EXHAUSTED. Is Ollama running?" >&2
exit 1
