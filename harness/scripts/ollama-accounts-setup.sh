#!/usr/bin/env bash
# ollama-accounts-setup.sh — Initialize Ollama account rotation directory
# Usage: bash ollama-accounts-setup.sh
# Copies current ~/.ollama/id_ed25519* as account1, prints instructions for more

set -euo pipefail

ACCOUNTS_DIR="$HOME/.ollama-accounts"
OLLAMA_DIR="$HOME/.ollama"
ACCOUNT1="$ACCOUNTS_DIR/account1"

mkdir -p "$ACCOUNT1"

# Copy current keys as account1
if [ -f "$OLLAMA_DIR/id_ed25519" ] && [ -f "$OLLAMA_DIR/id_ed25519.pub" ]; then
  cp "$OLLAMA_DIR/id_ed25519"     "$ACCOUNT1/id_ed25519"
  cp "$OLLAMA_DIR/id_ed25519.pub" "$ACCOUNT1/id_ed25519.pub"
  chmod 600 "$ACCOUNT1/id_ed25519"
  echo "[setup] account1 saved from current ~/.ollama keys."
else
  echo "[setup] WARNING: ~/.ollama/id_ed25519 not found. account1 is empty." >&2
  echo "[setup] Run 'ollama signin' first, then re-run this script." >&2
fi

# Show existing accounts
EXISTING=$(ls -d "$ACCOUNTS_DIR"/account*/ 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "[setup] Accounts directory: $ACCOUNTS_DIR"
echo "[setup] Accounts found: $EXISTING"
echo ""
echo "=== To add more accounts ==="
echo ""
echo "  Step 1: Sign in with a new Ollama account:"
echo "            ollama signin"
echo "            (enter credentials for account N)"
echo ""
echo "  Step 2: Copy the generated keys:"
echo "            N=2  # increment for each new account"
echo "            mkdir -p $ACCOUNTS_DIR/account\$N"
echo "            cp $OLLAMA_DIR/id_ed25519     $ACCOUNTS_DIR/account\$N/"
echo "            cp $OLLAMA_DIR/id_ed25519.pub $ACCOUNTS_DIR/account\$N/"
echo "            chmod 600 $ACCOUNTS_DIR/account\$N/id_ed25519"
echo ""
echo "  Step 3: Sign back in with your main account:"
echo "            ollama signin"
echo "            (restore main account credentials)"
echo ""
echo "  Repeat steps 1-3 for account3, account4, etc."
echo ""
echo "=== Usage ==="
echo "  bash harness/scripts/ollama-cloud-rotate.sh \"your prompt here\""
