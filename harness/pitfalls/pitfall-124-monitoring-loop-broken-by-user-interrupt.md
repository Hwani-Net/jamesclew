---
slug: pitfall-124-monitoring-loop-broken-by-user-interrupt
title: "사용자 인터럽트 후 자율 모니터링 루프 재개 잊음"
date: 2026-05-10
tags: [pitfall, monitoring, scheduling, self-paced]
---

# 증상
"/loop" 자율 모니터링 진행 중 사용자가 직접 질문/지시(인터럽트) → 응답 후 ScheduleWakeup 재설정 안 함 → 자동 모니터링 루프 끊김. 사용자: "야. 자율모니터링 왜 멈췄어?"

# 원인
ScheduleWakeup은 fired되거나 사용자 인터럽트로 끊김 양쪽 모두 가능. fired 후에는 자동으로 다음 wakeup 잡아야 하지만, 사용자 인터럽트 응답 turn에서는 ScheduleWakeup 호출을 잊기 쉬움. 응답 작성 + 다음 작업 처리에 집중하다 보니 백그라운드 루프 재설정을 빠뜨림.

# 해결
**모니터링 모드 진입 후 매 turn 끝에 ScheduleWakeup 재설정 필수**:
- fired 후 처리 turn: 다음 wakeup 잡음 (이미 가이드 명시)
- **사용자 인터럽트 응답 turn: 응답 끝나기 전에 ScheduleWakeup 재호출** (이게 누락됨)

규칙: "모니터링 활성 중인지 체크 → 활성이면 매 응답 끝에 ScheduleWakeup"

# 재발 방지
- 자율 모니터링 시작 시점에 마음에 새기기: "다음 turn 끝에 ScheduleWakeup 재호출"
- 사용자 질문이 짧고 명확해도 응답만 하지 말고 wakeup 재설정
- 스스로 모니터링 stop 결정한 게 아니면 wakeup 유지

# 자체 검증
- 본 사례 (2026-05-10 02:48) 사용자 직접 지적
