#!/bin/bash
# cost-tracker.sh — PostToolUse hook for MCP cost tracking
# Auto-logs Perplexity/Tavily/external model calls to api_cost_log.jsonl
# Purpose: observation only, no rate limiting. Monthly summary via /cost-summary.

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"
LOG="$STATE_DIR/api_cost_log.jsonl"
mkdir -p "$STATE_DIR"

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[ -z "$TOOL_NAME" ] && exit 0

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
COST=0
SERVICE=""
MODEL=""

case "$TOOL_NAME" in
  # Perplexity — from architecture.md cost table
  *perplexity*search*)     SERVICE="perplexity"; MODEL="sonar";               COST=0.006 ;;
  *perplexity*ask*)        SERVICE="perplexity"; MODEL="sonar-pro";           COST=0.030 ;;
  *perplexity*reason*)     SERVICE="perplexity"; MODEL="sonar-reasoning";     COST=0.020 ;;
  *perplexity*research*)   SERVICE="perplexity"; MODEL="sonar-deep-research"; COST=0.800 ;;

  # Tavily — free tier tracking (no cost, just call count)
  *tavily*search*)         SERVICE="tavily";     MODEL="search";              COST=0 ;;
  *tavily*extract*)        SERVICE="tavily";     MODEL="extract";             COST=0 ;;
  *tavily*crawl*)          SERVICE="tavily";     MODEL="crawl";               COST=0 ;;
  *tavily*research*)       SERVICE="tavily";     MODEL="research";            COST=0 ;;

  # Bash — external model CLI detection
  Bash)
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
    case "$CMD" in
      *codex\ exec*)       SERVICE="codex";      MODEL="codex-cli";           COST=0 ;;  # subscription
      *opencode\ run*)     SERVICE="antigravity";MODEL="gemini-3.1-pro";      COST=0 ;;  # free via antigravity
      *gemini*)            SERVICE="gemini";     MODEL="gemini-cli";          COST=0 ;;
      *) exit 0 ;;
    esac
    ;;

  *) exit 0 ;;
esac

# Append log entry
PURPOSE=$(echo "$INPUT" | jq -r '.tool_input.query // .tool_input.prompt // .tool_input.command // ""' 2>/dev/null | head -c 80 | tr '\n' ' ' | sed 's/"/\\"/g')
echo "{\"ts\":\"$TS\",\"service\":\"$SERVICE\",\"model\":\"$MODEL\",\"cost\":$COST,\"purpose\":\"$PURPOSE\"}" >> "$LOG"

# ── Hourly cost warning (observe + warn, no blocking) ──
HOUR_KEY=$(date -u +%Y-%m-%dT%H)
HOURLY_COST=$(grep "$HOUR_KEY" "$LOG" 2>/dev/null | jq -s '[.[].cost] | add // 0' 2>/dev/null || echo "0")
WARN_THRESHOLD="${COST_WARN_USD:-4.00}"
if [ "$(echo "$HOURLY_COST > $WARN_THRESHOLD" | bc -l 2>/dev/null)" = "1" ]; then
  echo "{\"systemMessage\":\"[COST WARN] Hourly API cost \$$HOURLY_COST exceeds \$$WARN_THRESHOLD. Consider reducing external model calls.\"}"
fi

exit 0
