#!/usr/bin/env bash
# enforce-cross-review.sh — PostToolUse(Write|Edit) hook
# Detects blog draft writes and injects cross-review reminder
# Triggers when draft.md is written to a drafts/ directory

INPUT=$(cat)
FILE=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null || echo "$INPUT" | grep -oP '"path"\s*:\s*"\K[^"]+' 2>/dev/null)

# Only trigger for blog draft files
if [[ "$FILE" == *drafts*draft.md* ]] || [[ "$FILE" == *drafts*draft*.md* ]]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[⚠️ CROSS-REVIEW 필수] 블로그 초안이 작성되었습니다. 발행 전 반드시 외부 모델 교차검수를 수행하세요: bash harness/scripts/codex-rotate.sh \"AI냄새 평가 프롬프트\". 자기 검수(Opus/Sonnet 단독 판단) 금지."}}'
fi
