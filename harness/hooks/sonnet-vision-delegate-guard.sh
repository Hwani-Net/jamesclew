#!/bin/bash
# PostToolUse on Read — 이미지 파일 감지 시 Opus 위임 권장
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# 이미지 파일이 아니면 종료
if [[ ! "$FILE_PATH" =~ \.(png|jpg|jpeg|webp|gif)$ ]] && [[ "$FILE_PATH" != *"/screenshot"* ]]; then
  exit 0
fi

# /tmp/screenshot 경로는 claude-in-chrome이나 expect MCP의 산출물 가능성 높음
LOG=~/.harness-state/vision-reads.log
mkdir -p ~/.harness-state
echo "$(date +%s) $FILE_PATH" >> "$LOG"

# 현재 세션 모델이 Sonnet인지 판별 어려움 — 대신 SubagentStop 이벤트 조합으로 감지
# PostToolUse에선 단순히 로그만 남기고 audit에서 검증
# 다만 /tmp/screenshot으로 시작하는 경로에 대해선 알림 제공
if [[ "$FILE_PATH" == *"/tmp/"* ]] && [[ "$FILE_PATH" == *"screenshot"* || "$FILE_PATH" =~ \.(png|jpg)$ ]]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[💡 VISION ROUTING] 이미지 Read 감지. Sonnet 실행 중이면 이 결과를 신뢰하지 말고 Opus 메인 세션에 SendMessage로 위임하세요. (Sonnet Vision 디테일 정확도 -20~30%)\"}}"
fi

exit 0
