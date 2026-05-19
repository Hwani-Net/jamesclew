#!/bin/bash
# agentmemory-mirror-obsidian.sh — PostToolUse hook
# mcp__agentmemory__memory_save 호출 직후 결과를 옵시디언 06-raw/agentmemory/에 자동 미러링.
# CONSOLIDATION_ENABLED=false 환경에서 OBSIDIAN_AUTO_EXPORT 한계 우회 (P-169 v3).

# TEST_HARNESS=1 분기
if [[ -n "$TEST_HARNESS" ]]; then
  echo "[agentmemory-mirror] TEST: skipped"
  exit 0
fi

# stdin JSON 파싱
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null)

# memory_save만 처리
if [[ "$tool_name" != "mcp__agentmemory__memory_save" ]]; then
  exit 0
fi

# 옵시디언 vault 경로
VAULT="${OBSIDIAN_VAULT:-C:/Users/AIcreator/Obsidian-Vault}"
EXPORT_DIR="$VAULT/06-raw/agentmemory"
mkdir -p "$EXPORT_DIR" 2>/dev/null

# memory_save 결과에서 saved ID 추출
saved_id=$(echo "$input" | jq -r '.tool_response.saved // .tool_response.content[0].text // ""' 2>/dev/null | grep -oE 'mem_[a-z0-9_]+' | head -1)
[[ -z "$saved_id" ]] && exit 0

# input에서 저장한 content/concepts/type 추출 (tool_input 또는 도구 입력)
content=$(echo "$input" | jq -r '.tool_input.content // ""' 2>/dev/null)
concepts=$(echo "$input" | jq -r '.tool_input.concepts // ""' 2>/dev/null)
mem_type=$(echo "$input" | jq -r '.tool_input.type // "fact"' 2>/dev/null)
files=$(echo "$input" | jq -r '.tool_input.files // ""' 2>/dev/null)

[[ -z "$content" ]] && exit 0

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DATE=$(date +"%Y-%m-%d")
OUT_FILE="$EXPORT_DIR/${DATE}-${saved_id}.md"

# 마크다운 작성 (frontmatter + content)
cat > "$OUT_FILE" <<EOF
---
title: "agentmemory: ${saved_id}"
tier: raw
date: $DATE
saved_at: $NOW
memory_id: $saved_id
memory_type: $mem_type
concepts: [$concepts]
files: [$files]
source: mcp__agentmemory__memory_save
---

# $saved_id

$content

## 메타
- 자동 미러링: agentmemory-mirror-obsidian.sh (PostToolUse hook)
- BASB tier: raw (사람이 distilled/synthesized로 진화)
EOF

echo "[agentmemory-mirror] saved: $OUT_FILE" >&2
exit 0
