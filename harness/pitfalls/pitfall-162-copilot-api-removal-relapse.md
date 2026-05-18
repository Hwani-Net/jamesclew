---
title: "PITFALL-162: copilot-api 사망 후 반복 추천 패턴"
date: 2026-05-18
tags: [pitfall, copilot-api, llm-routing, deprecated-tool, repeated-mistake]
severity: high
---

# PITFALL-162: copilot-api 사망 후 반복 추천 패턴

## 증상
- 자율 진화 OS 도구 추천 중 LLM provider로 `copilot-api(localhost:4141)`를 다시 추천함
- 대표님이 "GitHub에서 막혔다. 이전에 삭제 지시했다"고 재지적
- harness 활성 코드 52개 파일에 copilot-api 잔존 발견

## 원인 (근본)
1. 이전 삭제 지시 미완료 — CLAUDE.md, settings.json, modules.yaml, hooks/copilot-api-autostart.sh, scripts/copilot-api-start.sh, rules/autonomous-evolution.md, commands/*, docs/* 등에 광범위 잔존
2. CLAUDE.md를 "Multi-Model Orchestration" 섹션에서 copilot-api 항목을 정상 도구로 계속 참조
3. 새 작업(자율 진화 OS) 설계 시 CLAUDE.md를 무비판적으로 신뢰하여 추천 풀에 포함

## 해결
1. **즉시**: harness 활성 파일 52개에서 copilot-api 모든 언급 제거 (PITFALLS 디렉토리는 역사 기록으로 보존)
2. **대체**:
   - 외부 LLM 호출은 **codex CLI** (`codex exec` + 6계정 OAuth 로테이션)으로 통일
   - 또는 **Ollama 로컬** (localhost:11434, 무료, 오프라인)
3. **hooks/scripts**: `copilot-api-autostart.sh`, `copilot-api-start.sh` 파일 자체 제거
4. **gbrain import** 후 슬러그 `pitfall-162-copilot-api-removal-relapse`로 검색 가능

## 재발 방지
1. CLAUDE.md "Multi-Model Orchestration" 섹션 재작성 — copilot-api 행 삭제
2. **자율 진화 OS 설계 시 외부 LLM 후보 추천 전 다음 체크**:
   - `gbrain query "copilot-api"` 결과에 deprecated 표시 있는지
   - codex CLI(OAuth) / Ollama / 새 도구 순으로 우선 검토
3. 도구 폐기 결정 시 **CLAUDE.md/settings.json/hooks/scripts/rules/docs/commands** 전체 작업 단위로 제거 — 부분 제거 금지
4. 폐기 처리 시 PITFALL 즉시 기록 + gbrain put로 미래 세션 차단

## 검증
- `grep -r "copilot-api" D:/jamesclew/harness/` 결과가 PITFALLS만 남으면 성공
- 새 세션에서 `gbrain query "copilot-api"` → PITFALL-162가 1순위 노출

## 관련
- [[pitfall-105-opencode-claude-via-antigravity-banned]] — Antigravity 차단 사례
- [[pitfall-138-adapter-copilot-api-cascade-failure]] — copilot-api 어댑터 캐스케이드 실패
- [[pitfall-029-ralph-loop-gpt-4-copilot-api]] — Ralph Loop + copilot-api 사용
