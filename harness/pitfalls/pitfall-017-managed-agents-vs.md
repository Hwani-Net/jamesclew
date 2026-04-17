---
type: pitfall
id: P-017
title: "Managed Agents vs 서브에이전트 혼동 — 불필요한 복잡도"
tags: [pitfall, jamesclew]
---

# P-017: Managed Agents vs 서브에이전트 혼동 — 불필요한 복잡도

- **발견**: 2026-04-12
- **증상**: 블로그 생성에 Managed Agents API를 사용. 로컬 MCP 접근 불가, 파일 다운로드 필요, 디버깅 어려움
- **원인**: "5H 보존"이 목적이었으나, Agent(model: sonnet)도 Sonnet 풀 사용이라 5H 느린 소비. Managed Agents의 복잡도 대비 이점 부족
- **해결**: managed-blog-agent.py 삭제 (2026-04-16). 서브에이전트 + 외부 모델 검수 패턴으로 전환
- **재발 방지**: CLAUDE.md 용어 정의 테이블 추가 — "Agent"=서브에이전트, "Agent Teams"=TeamCreate, "Managed Agents"=API(미사용)
