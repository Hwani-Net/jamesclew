#!/bin/bash
# wiki-raw-save.sh — PostToolUse hook
# Perplexity/Tavily 도구 결과를 06-raw/에 자동 저장
# Trigger: mcp__perplexity__* | mcp__tavily__extract | mcp__tavily__crawl | mcp__tavily__search

INPUT=$(cat 2>/dev/null)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

case "$TOOL_NAME" in
  mcp__perplexity__*|mcp__tavily__extract|mcp__tavily__crawl|mcp__tavily__search)
    VAULT="${OBSIDIAN_VAULT:-C:/Users/AIcreator/Obsidian-Vault}"
    RAW_DIR="$VAULT/06-raw"
    mkdir -p "$RAW_DIR"

    # Extract query/url from tool_input
    TITLE=$(echo "$INPUT" | jq -r '
      .tool_input.query //
      .tool_input.url //
      .tool_input.urls[0] //
      empty
    ' 2>/dev/null | head -c 60)
    [ -z "$TITLE" ] && exit 0

    # Extract first URL from tool_output (fallback to tool_input url)
    URL=$(echo "$INPUT" | jq -r '.tool_input.url // .tool_input.urls[0] // empty' 2>/dev/null)
    if [ -z "$URL" ]; then
      URL=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null \
        | grep -oE 'https?://[^"[:space:]]+' | head -1)
    fi
    [ -z "$URL" ] && URL="(no url)"

    # Slugify title
    SLUG=$(echo "$TITLE" \
      | tr '[:upper:]' '[:lower:]' \
      | iconv -c -f utf-8 -t ascii//TRANSLIT 2>/dev/null \
      | tr -cs 'a-z0-9' '-' \
      | sed 's/^-//;s/-$//' \
      | head -c 40)
    [ -z "$SLUG" ] && SLUG="raw"

    DATE=$(date +%Y-%m-%d)
    FILE="$RAW_DIR/${DATE}-${SLUG}.md"

    # Don't overwrite existing file
    [ -f "$FILE" ] && exit 0

    # Truncate tool_output to 5000 chars
    CONTENT=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null | head -c 5000)

    cat > "$FILE" << MDEOF
---
title: "$TITLE"
url: $URL
date: $DATE
source: $TOOL_NAME
auto_saved: true
---

# $TITLE

$CONTENT
MDEOF

    echo "[wiki-raw-save] saved: $FILE" >&2
    ;;
esac

exit 0
