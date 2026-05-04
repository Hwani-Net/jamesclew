#!/bin/bash
# JamesClaw Harness Deploy Script
# 소스: D:/jamesclew/harness/ → 대상: ~/.claude/
# 사용법: bash harness/deploy.sh

set -euo pipefail

# --dry-run flag: diff preview only, no actual deployment
if [[ "${1:-}" == "--dry-run" ]]; then
  echo "[DRY-RUN] diff preview:"
  diff -rq harness/ "$HOME/.claude/" 2>/dev/null | head -30 || true
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.claude"

echo "🔨 JamesClaw Harness 배포 시작"
echo "   소스: $SCRIPT_DIR"
echo "   대상: $TARGET"

# 핵심 설정 파일
cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"

# settings.json — 사용자 /model 영구 설정 보존 (화이트리스트 외 legacy 값은 자동 청소)
USER_MODEL=""
if [ -f "$TARGET/settings.json" ]; then
  CURRENT_MODEL=$(jq -r '.model // empty' "$TARGET/settings.json" 2>/dev/null)
  case "$CURRENT_MODEL" in
    opus|sonnet|haiku|default) USER_MODEL="$CURRENT_MODEL" ;;
    "") : ;;
    *) echo "⚠️  legacy model '$CURRENT_MODEL' 자동 청소 (picker 옵션 아님)" ;;
  esac
fi
cp "$SCRIPT_DIR/settings.json" "$TARGET/settings.json"
if [ -n "$USER_MODEL" ]; then
  jq --arg m "$USER_MODEL" '.model = $m' "$TARGET/settings.json" > "$TARGET/settings.json.tmp" \
    && mv "$TARGET/settings.json.tmp" "$TARGET/settings.json"
  echo "✅ CLAUDE.md + settings.json (사용자 model 보존: $USER_MODEL)"
else
  echo "✅ CLAUDE.md + settings.json"
fi

# Awesome statusline — model 우선순위 패치 보존 (플러그인 업데이트 시 유실 방지)
if [ -f "$SCRIPT_DIR/awesome-statusline.sh" ]; then
  cp "$SCRIPT_DIR/awesome-statusline.sh" "$TARGET/awesome-statusline.sh"
  chmod +x "$TARGET/awesome-statusline.sh"
  echo "✅ awesome-statusline.sh (model 우선순위 패치 영구 적용)"
fi

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
cp -r "$SCRIPT_DIR/scripts/"* "$TARGET/scripts/"
echo "✅ scripts/ ($(ls "$SCRIPT_DIR/scripts/" | wc -l)개)"

# Tavily rotator
cp "$SCRIPT_DIR/scripts/tavily-rotator.mjs" "$TARGET/tavily-rotator.mjs"
echo "✅ tavily-rotator.mjs"

# Agents
mkdir -p "$TARGET/agents"
cp "$SCRIPT_DIR/agents/"*.md "$TARGET/agents/"
echo "✅ agents/ ($(ls "$SCRIPT_DIR/agents/"*.md | wc -l)개)"

# Slash commands
if [ -d "$SCRIPT_DIR/commands" ]; then
  mkdir -p "$TARGET/commands"
  cp "$SCRIPT_DIR/commands/"*.md "$TARGET/commands/"
  echo "✅ commands/ ($(ls "$SCRIPT_DIR/commands/"*.md | wc -l)개)"
fi

# PITFALLS — DEPRECATED (2026-04-17): gbrain으로 마이그레이션됨
# 신규 pitfall: gbrain put pitfall-NNN-{slug} --content "..."
# 아카이브: harness/archive/PITFALLS-2026-04-17.md (읽기 전용)

# ADR (설계 결정 기록)
if [ -d "$SCRIPT_DIR/../docs/adr" ]; then
  mkdir -p "$TARGET/docs/adr"
  cp "$SCRIPT_DIR/../docs/adr/"*.md "$TARGET/docs/adr/"
  echo "✅ docs/adr/"
fi

# Mirror commands + rules + docs to Obsidian for reference
VAULT="${OBSIDIAN_VAULT:-C:/Users/AIcreator/Obsidian-Vault}"
if [ -d "$VAULT/01-jamesclaw/harness" ]; then
  mkdir -p "$VAULT/01-jamesclaw/harness/commands"
  mkdir -p "$VAULT/01-jamesclaw/harness/rules"
  mkdir -p "$VAULT/01-jamesclaw/harness/docs"
  cp -u "$SCRIPT_DIR/commands/"*.md "$VAULT/01-jamesclaw/harness/commands/" 2>/dev/null
  cp -u "$SCRIPT_DIR/rules/"*.md "$VAULT/01-jamesclaw/harness/rules/" 2>/dev/null
  if [ -d "$SCRIPT_DIR/docs" ]; then
    cp -ru "$SCRIPT_DIR/docs/"* "$VAULT/01-jamesclaw/harness/docs/" 2>/dev/null
  fi
  echo "✅ commands/ + rules/ + docs/ mirrored to Obsidian"
fi

echo ""
echo "🎉 배포 완료. reload window 후 적용됩니다."
