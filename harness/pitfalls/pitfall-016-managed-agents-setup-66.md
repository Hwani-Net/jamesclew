---
type: pitfall
id: P-016
title: "Managed Agents setup() 반복 호출 — $8.66 낭비"
tags: [pitfall, jamesclew]
---

# P-016: Managed Agents setup() 반복 호출 — $8.66 낭비

- **발견**: 2026-04-12
- **증상**: managed-blog-agent.py에서 agents.create를 매 실행마다 호출. 14회 호출 → 각각 새 세션 + 풀 프롬프트 처리 → $8.66 소비
- **원인**: "Agent는 1회 생성, 이후 ID 재사용" 패턴 미숙지. setup()을 테스트할 때마다 새 Agent 생성
- **해결**: agent_id를 config 파일에 저장하고 재사용하도록 수정
- **재발 방지**: Managed Agents는 "생성 1회, 세션 N회" 원칙. 현재는 Managed Agents 미사용 (서브에이전트로 대체)
