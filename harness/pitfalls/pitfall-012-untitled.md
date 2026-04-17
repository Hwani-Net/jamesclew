---
type: pitfall
id: P-012
title: "외부 모델 로테이션 규칙만 존재, 구현 없음"
tags: [pitfall, jamesclew]
---

# P-012: 외부 모델 로테이션 규칙만 존재, 구현 없음

- **발견**: 2026-04-10
- **증상**: Codex 429 한도 초과 시 수동으로 외부 모델 전환 필요. evaluator.sh에 `codex exec` 하드코딩, 재시도/로테이션 로직 0
- **원인**: architecture.md와 qa.md에 로테이션 규칙만 명시. 실제 스크립트에는 codex 단일 호출만 구현
- **해결**: codex-rotate.sh 6계정 자동 로테이션 구현. ~~Antigravity(opencode)~~ 2026-04 폐기 → GPT-4.1(copilot-api) + Gemma 4 폴백으로 대체
- **재발 방지**: 규칙 추가 시 구현 코드도 동시 작성. "규칙 vs 구현" 갭을 /audit 체크리스트에 추가
