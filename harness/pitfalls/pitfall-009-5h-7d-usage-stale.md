---
type: pitfall
id: P-009
title: "5H/7D Usage 캐시 stale 상태 미감지"
tags: [pitfall, jamesclew]
---

# P-009: 5H/7D Usage 캐시 stale 상태 미감지

- **발견**: 2026-04-05
- **증상**: 5H 40%, 7D 36%를 실제 수치로 보고했지만, 캐시가 2시간 전 데이터. resets_at 시간이 이미 지남
- **원인**: 캐시 TTL(30분) 만료 + throttle(10분) 내 재시도 불가 → stale 캐시를 그대로 사용
- **해결**: 캐시 삭제 후 다음 statusline 호출에서 갱신
- **재발 방지**: usage 보고 시 resets_at 시간을 현재시각과 비교. 지났으면 "stale 데이터" 명시
