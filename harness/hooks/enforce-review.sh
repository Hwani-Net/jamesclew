#!/bin/bash
# enforce-review.sh — PostToolUse hook for firebase deploy
# After deploy, inject mandatory external model review reminder
# Ensures agent runs GPT-4.1 (copilot-api) + Codex before reporting to user

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only trigger on firebase deploy
echo "$COMMAND" | grep -q "firebase deploy" || exit 0

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[⚠️ 배포 후 필수 검수] firebase deploy 완료. 보고 전 반드시:\n1. agent-browser로 전체 페이지 스크린샷 + 이미지 로드 확인 (naturalWidth > 0)\n2. Opus+Sonnet 서브에이전트로 이미지-제품 매칭 검증\n3. GPT-4.1 (curl localhost:4141) + codex exec 로 콘텐츠 교차 검수\n4. 전부 통과 후에만 대표님께 보고. 검수 없이 '배포 완료' 보고 금지."}}
EOF
