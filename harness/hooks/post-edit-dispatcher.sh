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

# 6. Auto session rename suggestion — PRD.md / PLAN.md 작성 감지
# 디렉토리 이름을 슬러그화해 ~/.harness-state/session_rename_pending.txt 작성
# user-prompt.ts가 다음 user prompt 시 읽고 클로드에게 안내 주입
if [ -n "$FILE" ]; then
  case "$FILE" in
    */PRD.md|*/PLAN.md|*/prd.md|*/plan.md|*/Prd.md|*/Plan.md)
      PROJECT_DIR=$(dirname "$FILE")
      PROJECT_NAME=$(basename "$PROJECT_DIR")
      # 슬러그화: 소문자 + 하이픈, 영숫자/하이픈만
      SLUG=$(echo "$PROJECT_NAME" \
        | tr '[:upper:]' '[:lower:]' \
        | tr '_ .' '---' \
        | sed 's/[^a-z0-9-]//g' \
        | sed 's/--*/-/g' \
        | sed 's/^-//;s/-$//')
      if [ -n "$SLUG" ]; then
        mkdir -p "$HOME/.harness-state"
        echo "$SLUG" > "$HOME/.harness-state/session_rename_pending.txt"
      fi
      ;;
  esac
fi

exit 0
