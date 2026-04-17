---
type: pitfall
id: P-022
title: "Agent Teams 해체 시 TeamDelete 누락 → 다음 팀 생성 블로킹"
tags: [pitfall, jamesclew]
---

# P-022: Agent Teams 해체 시 TeamDelete 누락 → 다음 팀 생성 블로킹

- **발견**: 2026-04-16
- **재발**: 2026-04-16 (Critic-Implementer 100회 루프에서 "Already leading team 'loop-100'" 에러)
- **증상**: TeamCreate 호출 시 "Already leading team X. A leader can only manage one team at a time." 에러로 새 팀 생성 불가
- **원인**: teammate에게 shutdown_request를 보내 프로세스 종료 확인(shutdown_approved)까지 했지만, TeamDelete 호출을 빠뜨림. teammate 종료 ≠ 팀 해체. 세션 내 in-memory 팀 컨텍스트가 남아있음
- **해결**: TeamDelete 즉시 호출 후 TeamCreate 진행. 같은 세션에서만 가능 — 다른 세션에서는 접근 불가
- **재발 방지**: 팀 작업 완료 체크리스트 — ①모든 teammate에 shutdown_request ②shutdown_approved 확인 ③TeamDelete 호출 (이 3단계가 완전한 팀 해체)
- **자동화 방안**: TeamCreate 프롬프트 시 자동으로 기존 팀 상태 확인 + TeamDelete 선행하는 래퍼 skill 필요. `/team-reset` 스킬로 "현재 팀 해체 + 새 팀 생성" 단일 명령 제공 검토
