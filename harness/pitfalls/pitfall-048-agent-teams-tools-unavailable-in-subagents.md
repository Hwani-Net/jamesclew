---
title: Agent Teams 도구(TaskList/TaskUpdate/SendMessage)가 서브에이전트에서 미동작
date: 2026-04-18
severity: P0
project: dashboard-saas-mvp
---

## 증상

Agent Teams 세션에서 `Agent()` 서브에이전트로 spawn된 teammate가
`TaskList`, `TaskUpdate`, `SendMessage` 도구 호출 시 다음 중 하나로 실패:

- "도구가 현재 세션에 없음"
- "Agent Teams 세션 전용 도구"
- 도구 호출 자체가 0건 (3초 만에 종료)

## 원인

Agent Teams 도구는 TeamCreate로 생성된 팀 컨텍스트에 귀속됨.
`Agent()` 서브에이전트는 **별도 격리된 컨텍스트**로 실행되므로
부모 세션의 팀 도구를 자동 상속하지 않는다.

`model: sonnet`, `team_name`, `name` 파라미터를 지정해도 동일하게 실패.
(v2.1.112 기준 — 향후 버전에서 해결될 수 있음)

## 해결 (임시)

director(Opus 메인 세션)가 TaskUpdate를 **직접 호출**하여 모든 태스크 상태를 수동 관리.
teammate의 TaskUpdate 미이행 시 director가 폴링/관찰 후 수동 처리.

## 재발 방지

1. Agent Teams 실험 시 첫 teammate spawn 후 즉시 `TaskList` 호출 테스트.
   실패하면 "director 직접 관리 모드"로 전환, 기대치 조정.
2. `SendMessage` 도구도 동일하게 불가 — R4.5 이중 전송 규칙은 director가 proxy 역할로 보완.
3. 진정한 teammate 자율 큐는 현재 Claude Code 서브에이전트 아키텍처에서 불가능.
   향후 `Agent(inherit_team: true)` 류 옵션 추가 여부 주시.
