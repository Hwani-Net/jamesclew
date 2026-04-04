#!/bin/bash
# log-api-cost.sh — API 비용 로깅 유틸리티
# Usage: bash log-api-cost.sh <service> <model> <cost> <purpose>
# Example: bash log-api-cost.sh perplexity sonar-deep-research 0.80 "공기청정기 리서치"
#
# 제한하지 않음, 관찰만. 월말 집계용.

STATE_DIR="$HOME/.claude/hooks/state"
LOG_FILE="$STATE_DIR/api_cost_log.jsonl"
mkdir -p "$STATE_DIR"

# Summary mode — no logging
if [ "$1" = "summary" ]; then
  :
else
  SERVICE="${1:-unknown}"
  MODEL="${2:-unknown}"
  COST="${3:-0}"
  PURPOSE="${4:-}"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"service\":\"$SERVICE\",\"model\":\"$MODEL\",\"cost\":$COST,\"purpose\":\"$PURPOSE\"}" >> "$LOG_FILE"
fi

# Monthly summary on request
if [ "$1" = "summary" ]; then
  MONTH=$(date +%Y-%m)
  echo "=== $MONTH API Cost Summary ==="
  if [ -f "$LOG_FILE" ]; then
    python3 -c "
import json, sys, os
sys.stdout.reconfigure(encoding='utf-8')
log_file = os.path.expanduser('~/.claude/hooks/state/api_cost_log.jsonl')
month = '${MONTH}'
total = 0
by_service = {}
with open(log_file, encoding='utf-8') as f:
    for line in f:
        try:
            d = json.loads(line.strip())
            if d['ts'].startswith(month):
                cost = float(d.get('cost', 0))
                total += cost
                svc = d.get('service', 'unknown')
                by_service[svc] = by_service.get(svc, 0) + cost
        except: pass
print(f'Total: \${total:.2f}')
for svc, cost in sorted(by_service.items(), key=lambda x: -x[1]):
    print(f'  {svc}: \${cost:.2f}')
"
  else
    echo "No log file found"
  fi
fi
