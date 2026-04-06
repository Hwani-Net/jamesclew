#!/bin/bash
# post-edit-dispatcher.sh — Single PostToolUse dispatcher for Write/Edit
# Replaces 5 separate hooks with 1 sequential dispatcher.

INPUT=$(cat)

# Extract file path
FILE=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null || echo "$INPUT" | grep -oP '"path"\s*:\s*"\K[^"]+' 2>/dev/null)

# 1. Auto-format (non-blocking)
if [ -n "$FILE" ]; then
  case "$FILE" in
    *.js|*.ts|*.jsx|*.tsx|*.json|*.css|*.html) npx prettier --write "$FILE" 2>/dev/null || true ;;
    *.py) python -m black --quiet "$FILE" 2>/dev/null || true ;;
  esac
fi

# 2. Quality gate (lightweight check)
echo "$INPUT" | bash "$HOME/.claude/hooks/quality-gate.sh" post-edit 2>/dev/null

# 3. Regression guard
echo "$INPUT" | bash "$HOME/.claude/hooks/regression-guard.sh" 2>/dev/null

# 4. Change tracker
echo "$INPUT" | bash "$HOME/.claude/hooks/change-tracker.sh" 2>/dev/null

# 5. Test manipulation guard
echo "$INPUT" | bash "$HOME/.claude/hooks/test-manipulation-guard.sh" 2>/dev/null

exit 0
