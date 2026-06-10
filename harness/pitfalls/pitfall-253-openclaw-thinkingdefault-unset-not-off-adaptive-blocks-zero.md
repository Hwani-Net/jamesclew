# P-253: OpenClaw thinkingDefault 미설정 ≠ off + thinking 블록 0개 ≠ off (adaptive 특성 오판 주의)

- **발견**: 2026-06-02 (대표님 "JARVIS 멍청 → 다른 봇도 thinking 확인" → 9봇 thinking 점검)
- **영향**: 봇 추론 설정 점검 시 "thinking 블록 0 = off"로 성급 단정하면 멀쩡한(adaptive) 봇을 고장으로 오판. premature_conclusion 위험.

## 증상 / 내 오판
- 9봇 중 JARVIS(main)만 `thinkingDefault: off` 명시, 나머지 8봇은 미설정.
- 세션 jsonl 실측: EVE(sonnet) 40응답·TARS(codex) 354응답 내내 **thinking 블록 0개** → 나는 "8봇 전부 OFF, 바보 상태"로 단정.
- **이게 부분 오판이었음** (codex 공식문서 교차로 정정).

## 사실 (codex 공식문서 교차 — docs.openclaw.ai/ko/tools/thinking)
- **미설정 = 완전 off 아님.** thinkingDefault 없으면 → 세션/전역 기본 → 없으면 **provider/model 기본값(reasoning 가능 모델은 non-off fallback)**.
- **sonnet-4-6 = `adaptive` 기본** (켜짐). 단 adaptive는 **요청별로 필요할 때만** thinking을 씀 → 간단한 응답엔 **thinking 블록 0이 정상**. 즉 "0개 = off"가 아니다.
- **codex/gpt-5.5 = reasoning effort `medium` 기본** → 미설정이어도 켜져 있었음. (codex harness reasoning은 thinking 블록 형식으로 안 보일 수 있음 → 354응답 0이 곧 off가 아님)
- **haiku** = OpenClaw fallback상 켜짐 추론(전용 문구 불명).
- **gemma4(로컬)** = thinking 약함, 명시 강제 효과 제한적.
- **JARVIS만 명시 `off`였음** = 유일하게 진짜 추론 꺼진 봇 → "멍청"의 실제 원인. high 교정 정당.

## 해결 (적용)
- 핵심 판단봇은 모델 기본(adaptive/medium)보다 **일관된 깊은 추론을 위해 명시 강제**:
  - JARVIS/EVE/FRIDAY/KITT(opus·sonnet) = `high`, TARS(codex) = `high`, C3PO/Joi(haiku) = `medium`.
  - Data/TRON(gemma4 로컬) = 모델 기본 유지(thinking 약해 강제 무의미).
- 적용 방식: `agents.list[].thinkingDefault` 수정 → config hot-reload(restart 불필요), 9봇 connected 유지.
- **트레이드오프**: 명시 high = 항상 깊게 추론(품질↑) vs adaptive = 필요시만(비용↓). 대표님 정책 "봇은 멍청하면 안 됨" → 핵심봇 high 강제 채택.

## 재발 방지
- **봇 추론 점검 시 "thinking 블록 0 = off"로 단정 금지.** adaptive 모델은 필요시만 thinking → 0이 정상. 실제 설정값(`thinkingDefault`)과 **모델별 기본 동작(adaptive/reasoning effort)**을 같이 확인.
- 명시 `off`만이 확실한 "추론 꺼짐". 미설정은 모델 기본(대개 켜짐).
- 봇이 "멍청"하면: ①thinkingDefault `off` 명시 여부 ②모델 자체 ③stale 컨텍스트(P-252) 순으로 확인. 이번 JARVIS는 ①(명시 off)이 원인.

## 관련
- [[pitfall-252-openclaw-main-session-fix-not-synced-to-bot-session-stale-self-action]] (같은 세션 JARVIS 점검)
- [[pitfall-245-openclaw-codex-harness-model-must-be-codex-provider]] (codex/gpt-5.5 모델·runtime)
