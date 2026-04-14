---
name: Session 2026-04-03 Summary
description: 하네스 대규모 업그레이드 세션 — Phase 1 완성 + 페르소나 시스템 + Hallucination 방지
type: project
---

## 완료 작업

### 하네스 Phase 1 완성
- PreToolUse/PostToolUse hook: jq → grep 패턴 매칭
- deny list: pipe+curl/wget, chain+rm 패턴 추가
- effortLevel 고정 제거 → 자율 선택

### Hook 버그 수정
- Usage API 429: 1분 캐시 + 실패 시 "?" 표시
- Reload 중복 메시지: 15초 디바운스
- Stop hook: telegram-notify.sh stop 통합

### 페르소나 시스템 구축
- persona-mcp v0.3.1 설치 (Windows import.meta.url 래퍼)
- stakeholder-mcp 설치 (Windows 경로 수정, OpenRouter 7키 로테이션)
- 옵시디언 71개 페르소나 보강 (AI 스크립트, 에러 0)
- 옵시디언 → stakeholder-mcp 동적 등록 검증

### 하네스 설계 재구성
- "MCP 3개 한도" → "Tool 50개 한도"
- "21K/cycle" → 삭제 (시스템 오버헤드만 24K)
- "Perplexity 딥리서치" → "검색만, 분석은 Opus"
- stitch-mcp 온디맨드 전환, perplexity search만 허용

### Hallucination 방지 3계층
- 1계층 (command): SubagentStop — URL/repo curl 404 감지 (이름만 언급해도 감지)
- 2계층 (command): PreToolUse — 메모리 쓰기 전 URL 검증 → deny
- 3계층 (prompt): SubagentStop — Haiku 의미적 사실 확인

### 텔레그램 알림 개선
- 컨텍스트 사용량 표시 (🧠 Context: 310K/31%)
- 50%+ 주의, 70%+ /compact 권장 경고
- Usage 캐시 TTL: 5분 → 1분

### 메모리/피드백
- feedback_effort_level.md — 자율 선택
- feedback_quality_first.md — 품질 최우선, 학습데이터 의존 금지

## 다음 세션 TODO
1. Custom Agents 구현 (researcher, code-reviewer, content-writer)
2. Quality Gate hook (코드 변경→테스트 미실행 시 commit 경고)
3. 3계층 prompt hook 작동 검증 (reload 후)
4. Phase 2 수익 파이프라인 착수
