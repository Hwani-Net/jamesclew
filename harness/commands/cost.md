---
description: "외부 API 비용 요약 (Tavily/OpenAI 등). Claude 구독은 /usage 참조"
---

# /cost — 외부 API 비용 요약

> **역할 분리 (2026-05-19 갱신)**
> - **`/usage`** (Claude Code v2.1.118+ 네이티브) — Claude API 사용량/5H 7D 한도/구독 비용
> - **`/usage-credits`** (v2.1.144+, 구 `/extra-usage`) — 추가 사용량 크레딧 정보
> - **`/cost`** (본 스킬) — 외부 API 비용 누적 로그 (Tavily, OpenAI gpt-4o-mini, Codex 외 유료 호출 등)
>
> 세 영역은 겹치지 않음. Claude 비용 = `/usage` + `/usage-credits`, 외부 = `/cost`.

`~/.harness-state/api_cost_log.jsonl`에 기록된 외부 API 호출 비용을 집계합니다. 제한하지 않고 관찰만.

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
