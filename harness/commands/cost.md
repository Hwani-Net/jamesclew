---
description: "API 비용 요약"
---

# /cost — API 비용 요약

외부 API 호출 비용을 집계합니다. 제한하지 않고 관찰만.

## 실행

```bash
python << 'PYEOF'
import json, sys, os
from collections import defaultdict
from datetime import datetime
sys.stdout.reconfigure(encoding='utf-8')

log = os.path.expanduser('~/.harness-state/api_cost_log.jsonl')
if not os.path.exists(log):
    print("로그 없음")
    exit()

total = 0
by_service = defaultdict(lambda: {'cost': 0, 'count': 0})
by_day = defaultdict(float)
this_month = datetime.utcnow().strftime('%Y-%m')

with open(log, encoding='utf-8') as f:
    for line in f:
        try:
            d = json.loads(line.strip())
            if not d['ts'].startswith(this_month):
                continue
            cost = float(d.get('cost', 0))
            svc = d.get('service', 'unknown')
            total += cost
            by_service[svc]['cost'] += cost
            by_service[svc]['count'] += 1
            by_day[d['ts'][:10]] += cost
        except: pass

print(f"=== {this_month} API Cost Summary ===")
print(f"Total: ${total:.3f}")
print()
print("=== By service ===")
for svc, data in sorted(by_service.items(), key=lambda x: -x[1]['cost']):
    print(f"  {svc:15} ${data['cost']:>7.3f}  ({data['count']} calls)")
print()
print("=== Recent days ===")
for day in sorted(by_day.keys())[-7:]:
    print(f"  {day}: ${by_day[day]:.3f}")
PYEOF
```
