---
slug: pitfall-163-gpt-4-1-doc-vs-runtime-mismatch
date: 2026-05-18
severity: high
tags: [external-model, gpt-4.1, copilot-api, gemma4, routing, doc-drift]
---

# P-163 — GPT-4.1 문서-런타임 불일치 (2026-05 GitHub 차단)

## 증상
- harness 문서/규칙/hook 전반에 "GPT-4.1" 외부 모델 참조가 산재
- 실제 런타임에서 `localhost:4141` (copilot-api)는 2026-05 GitHub 외부 접근 차단으로 사용 불가
- Ollama에 `gpt-4.1` 모델이 없어 `curl localhost:11434 model:gpt-4.1` 호출도 실패
- 결과: 외부 검수 단계에서 silent fail 또는 잘못된 폴백

## 원인
- copilot-api 프록시(`localhost:4141`)가 GitHub의 외부 접근 차단 정책으로 2026-05부터 동작 불가
- 하네스 문서가 copilot-api 기반 GPT-4.1 라우팅을 1순위로 기술한 채 방치됨
- 로컬 Ollama에는 gemma4/exaone3.5/glm 모델만 존재, gpt-4.1 없음

## 해결
- 전체 harness 파일에서 GPT-4.1 참조를 아래 규칙으로 일괄 교체 (2026-05-18):
  - `외부 모델(Codex/GPT-4.1)` → `외부 모델(Codex)`
  - `GPT-4.1 (Ollama)` → `gemma4 (Ollama, 보조 전용)`
  - `Codex + GPT-4.1 병렬` → `Codex (1순위) + gemma4 (보조 의견)`
  - `localhost:4141` curl 블록 → deprecated 주석 처리
- Codex CLI (`bash harness/scripts/codex-rotate.sh`) = 외부 검수 1순위
- gemma4/exaone3.5 (Ollama localhost:11434) = 보조 의견 전용, 단독 PASS/FAIL 판단 금지

## 재발 방지
- 로컬 모델(gemma4, exaone3.5, glm)은 **보조 의견만** — hallucination 위험으로 단독 판단 금지
- 전멸 폴백: Codex 3회 재시도 실패 시 대표님 보고. 로컬 단독 결정 절대 금지.
- 새 외부 모델 추가 시 반드시 harness/CLAUDE.md + rules/architecture.md 동시 업데이트
- `grep -r "localhost:4141" harness/` → 결과 있으면 즉시 수정
