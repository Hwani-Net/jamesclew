---
type: pitfall
id: P-029
title: "Ralph Loop이 GPT-4.1(copilot-api) 세션에서 1회차에 중단"
tags: [pitfall, jamesclew]
---

# P-029: Ralph Loop이 GPT-4.1(copilot-api) 세션에서 1회차에 중단

- **발견**: 2026-04-17
- **증상**: copilot-api 메인 세션에서 `/ralph-loop --max-iterations 100` 실행 시 1회차 실행 후 모델이 "일정 시간 후 다시 확인하세요" user-polling 응답으로 종료. 자율 반복 안 됨
- **원인**: Ralph Loop은 **Stop hook이 턴 종료를 감지하여 같은 프롬프트를 재주입**하는 방식. Anthropic 직결 세션 + Claude 모델에 최적화된 plugin. GPT-4.1 + copilot-api 프록시 조합에서는 (1) 모델이 자율 에이전트 패턴 미성숙 (2) 프록시 경유 시 Stop hook이 제대로 재주입 못 할 가능성 (3) 모델이 "분석 완료" 선언 후 stop
- **해결 4옵션**:
  1. **Opus 메인 세션에서 실행** (권장) — Ralph Loop 원래 용도
  2. **Sonnet teammate 경유** — `Agent(model: sonnet)` 안에서 실행. 1x 크레딧
  3. **수동 bash while loop** — `for i in 1..100; curl localhost:4141 ...` (무료, hook 의존 없음)
  4. **GitHub Copilot 변형** — `wasimakh2/ralph-github-copilot` (copilot CLI 전용)
- **재발 방지**: CLAUDE.md에 "Ralph Loop / 자율 반복 스킬은 Anthropic 직결 세션(Opus/Sonnet)에서만 실행. copilot-api 프록시 세션에서는 수동 bash 루프 대체" 규칙 추가 검토
- **참조**: ralph-loop.md skill 파일 — "Stop hook이 SAME PROMPT 재주입"
