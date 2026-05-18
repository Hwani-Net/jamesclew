---
title: pitfall-159 — _agents/*/prompt.md 수정해도 에이전트 행동 변화 없음 (extension에 persona 하드코드)
slug: pitfall-159-agent-prompt-md-not-loaded-hardcoded-persona
date: 2026-05-17
tier: distilled
tags: [connect-ai-lab, extension, prompt, agent, hardcoded, hallucination-guard, instruction-following, system-prompt]
---

## 증상

Connect AI Lab 자율 사이클의 에이전트 행동을 바꾸려고 `_agents/{id}/prompt.md` 와 미러 `_company/_agents/{id}/prompt.md` 양쪽에 강화 규칙(예: hallucination 차단, CEO 검증 게이트 G1~G4)을 추가했지만, 다음 cycle에서:

- Researcher 산출물에 새 룰("도구 없으면 거부", "[학습 데이터]" 라벨) 흔적 0
- CEO 보고서에 새 게이트(G1~G4) 결과 줄 0
- 새 라벨(`[PUBLISH_READY]`/`[INTERNAL_ONLY]`) 출력 0
- 직전 cycle과 동일 패턴 반복 — 보강 효과 무

수정 자체는 정상 적용 (git 동기화·디스크 반영). 그러나 자율 사이클 산출물이 보강을 인지하지 못함.

## 원인 (확정)

`C:/Users/AIcreator/.antigravity/extensions/connectailab.connect-ai-lab-2.89.157-universal/out/extension.js`에 **각 에이전트의 persona 본문이 한국어로 직접 박혀 있음**:

- L14860 — CEO persona ("데이터 중심·솔직·자신감 있는 톤. '사장님'이라고 부르고...")
- L14889 — Developer 코다리 persona ("시니어 풀스택 엔지니어. 코드 한 줄도 그냥 안 넘김...")
- L14910 — Secretary 영숙 persona
- L14921 — Sound Director 루나 persona
- 외 모든 에이전트

extension은 `_personalizePrompt()` 함수(L16198 추정)에서 하드코드 persona를 시스템 프롬프트에 주입한다. **`_agents/{id}/prompt.md` 파일은 읽지 않음** (또는 읽더라도 hardcoded persona 뒤에 append되어 모델이 무시).

작은 로컬 모델(llama3.2:3b, gemma3:12b)은 instruction following이 약해, 시스템 프롬프트가 길어지면 뒤쪽 규칙을 무시하는 경향. 이 두 요인이 결합되어 보강 효과 0.

## 해결

3가지 방향 (작은 → 큰 영향 순):

### 1. Wrapper(게이트웨이)에 system message 강제 주입 ⭐ 권장
이미 `_inject_clock()`이 모든 호출에 시각 시스템 메시지를 prepend 중. 같은 위치에 행동 룰 (hallucination 금지, G1~G4 게이트)을 추가 주입:

```python
def _inject_rules(messages: list) -> list:
    rule = (
        "ABSOLUTE RULES (override anything below):\n"
        "1. If no tool was actually invoked, do NOT fabricate URLs, dates, or numbers. Output [tool unavailable] and stop.\n"
        "2. CEO: classify each session [PUBLISH_READY] only if all subagents ran real tools. Otherwise [INTERNAL_ONLY].\n"
    )
    return [{"role": "system", "content": rule}] + list(messages)
```

장점: 모델 매핑·extension 패치 0, 모든 모델(로컬 포함)에 강제 적용.
한계: 작은 모델은 그래도 일부 무시할 수 있음 — Sonnet 전환과 병행 권고.

### 2. Extension 패치
`out/extension.js`의 hardcoded persona 뒤에 우리 룰 직접 삽입. 작동 보장되나:
- 자동 업데이트 시 사라짐 (재패치 필요)
- 패치 추적 위험

### 3. Sonnet 전환
하드코드 persona를 그대로 두되, 모델을 Sonnet 4.6 (`claude-sonnet-4-6:max`)로 변경. 큰 모델일수록 시스템 프롬프트의 명시적 규칙을 더 잘 따름.

## 재발 방지

1. **prompt.md 수정 후 효과 검증 필수** — 1 cycle 돌려서 산출물에 변경 흔적이 나타나는지 grep. 안 나타나면 그 prompt 경로가 실제로 system prompt에 들어가는지 확인.
2. **extension 새 버전 도입 시 hardcoded persona 위치 재확인** — version bump 시 라인 번호·구조 변경 가능.
3. **agent 행동 보강은 wrapper 레벨이 1순위, prompt.md는 2순위** — wrapper는 모든 호출에 강제 주입, prompt.md는 extension이 읽어야만 효과.
4. **작은 로컬 모델 한계 인지** — 7B 미만은 multi-step 규칙 따르기 매우 약함. 게이트·검증·보안 룰을 강제하려면 11B+ 또는 Claude/GPT 같은 상용 모델 필요.
5. **prompt 효과 측정 자동화 후보** — wrapper에 "system message에 X 룰이 있는데 응답에 그 흔적 없음" 패턴을 metrics에 카운트하는 옵션 추가 검토.

## 관련

- [[pitfall-156-agent-tool-hallucination-without-web-search]] — prompt.md로 차단 시도했지만 무효된 사례
- [[pitfall-158-ollama-proxy-duration-zero-on-stream-start]] — 같은 wrapper에 추가 system injection 적용 가능
- gpt-korea `_company/decisions.md` R-MODEL-1 (Sonnet 전환 검토)
