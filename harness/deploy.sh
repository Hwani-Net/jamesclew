#!/bin/bash
# JamesClaw Harness Deploy Script
# 소스: D:/jamesclew/harness/ → 대상: ~/.claude/
# 사용법: bash harness/deploy.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.claude"

echo "🔨 JamesClaw Harness 배포 시작"
echo "   소스: $SCRIPT_DIR"
echo "   대상: $TARGET"

# 핵심 설정 파일
cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
cp "$SCRIPT_DIR/settings.json" "$TARGET/settings.json"
echo "✅ CLAUDE.md + settings.json"

# Rules
mkdir -p "$TARGET/rules"
cp "$SCRIPT_DIR/rules/"*.md "$TARGET/rules/"
echo "✅ rules/ ($(ls "$SCRIPT_DIR/rules/"*.md | wc -l)개)"

# Hooks (sh + ts)
mkdir -p "$TARGET/hooks"
cp "$SCRIPT_DIR/hooks/"*.sh "$TARGET/hooks/"
chmod +x "$TARGET/hooks/"*.sh
if ls "$SCRIPT_DIR/hooks/"*.ts 1>/dev/null 2>&1; then
  cp "$SCRIPT_DIR/hooks/"*.ts "$TARGET/hooks/"
fi
echo "✅ hooks/ ($(ls "$SCRIPT_DIR/hooks/"*.sh "$SCRIPT_DIR/hooks/"*.ts 2>/dev/null | wc -l)개)"

# Scripts
mkdir -p "$TARGET/scripts"
cp "$SCRIPT_DIR/scripts/"* "$TARGET/scripts/"
echo "✅ scripts/ ($(ls "$SCRIPT_DIR/scripts/" | wc -l)개)"

# Tavily rotator
cp "$SCRIPT_DIR/scripts/tavily-rotator.mjs" "$TARGET/tavily-rotator.mjs"
echo "✅ tavily-rotator.mjs"

# Agents
mkdir -p "$TARGET/agents"
cp "$SCRIPT_DIR/agents/"*.md "$TARGET/agents/"
echo "✅ agents/ ($(ls "$SCRIPT_DIR/agents/"*.md | wc -l)개)"

# PITFALLS (전역 실수 기록)
cp "$SCRIPT_DIR/PITFALLS.md" "$TARGET/PITFALLS.md"
echo "✅ PITFALLS.md (전역)"

# ADR (설계 결정 기록)
if [ -d "$SCRIPT_DIR/../docs/adr" ]; then
  mkdir -p "$TARGET/docs/adr"
  cp "$SCRIPT_DIR/../docs/adr/"*.md "$TARGET/docs/adr/"
  echo "✅ docs/adr/"
fi

echo ""
echo "🎉 배포 완료. reload window 후 적용됩니다."
