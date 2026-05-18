---
slug: pitfall-135-connect-ai-llm-response-surrogate-pair-broken
title: Connect AI extension의 LLM 응답 재직렬화 시 emoji surrogate pair 깨짐
date: 2026-05-08
tags: [connect-ai, antigravity, surrogate-pair, json-parse, opus-adapter, emoji]
severity: high
---

# Connect AI extension의 LLM 응답 재직렬화 시 emoji surrogate pair 깨짐

## 증상
- CEO 에이전트 모델을 `claude-opus-4.7 [adapter]` 로 변경 시 작업 분배 요청 실패
- 화면 표시:
  ```
  ⚠️ CEO가 작업 분배 계획(JSON)을 생성하지 못했어요.
  원본 응답:
  API Error: 400 The request body is not valid JSON: invalid high surrogate in string: line 1 column 909 (char 908)
  ```
- 다른 모델(sonnet-4.6, gpt-5-mini)에서는 발생 안 함

## 원인
1. Antigravity의 `claude-opus-4.7 [adapter]` 어댑터가 응답 스트리밍 중 emoji를 **high surrogate** 단계까지만 보내고 low surrogate 손실 (응답 잘림 또는 chunk 경계 분할)
2. Connect AI extension이 받은 응답을 `_chatHistory.push`로 누적 → 다음 호출 페이로드의 messages 배열에 그대로 포함
3. 다음 요청 직렬화 시 `JSON.stringify(payload)`가 짝 잃은 surrogate를 그대로 직렬화 → **API가 invalid JSON으로 거부**
4. Claude Code 본체는 v2.1.132에서 동일 fix 적용됨 ("Fixed `--resume` failing with `no low surrogate in string` when a tool error truncation split an emoji"). 그러나 **Connect AI extension은 별도 코드 — 같은 fix 미적용 상태**

## 해결
### 헬퍼 추가 (extension.ts line 14~27)
```typescript
function _sanitizeSurrogates(s: string): string {
  if (typeof s !== "string") return s;
  return s
    .replace(/[\uD800-\uDBFF](?![\uDC00-\uDFFF])/g, "")
    .replace(/(?<![\uD800-\uDBFF])[\uDC00-\uDFFF]/g, "");
}
```
- 짝 잃은 surrogate (high without low, low without high) 단순 제거
- 정상 emoji (4-byte UTF-8 = 2 surrogate pair)는 보존

### 적용 지점
- line 20176 직전 — 1차 스트리밍 종료 후 `_chatHistory.push` 직전: `aiMessage = _sanitizeSurrogates(aiMessage)`
- line 20599 직전 — 2차 스트리밍(followUp 멀티턴) 종료 후 동일 패턴

### 검증
- `npm run compile` exit 0 → `out/extension.js` 재생성
- Antigravity `Developer: Reload Window` 후 CEO Opus 4.7 [adapter] 재호출 → 400 재발 안 함

## 재발 방지
1. **외부 LLM adapter 응답을 다음 호출 페이로드로 재사용하는 모든 지점은 surrogate sanitize 필수** — Connect AI뿐 아니라 모든 extension·proxy·orchestrator
2. **Anthropic / OpenAI 직접 SDK는 자체적으로 처리하지만, "어댑터" 계층(`[adapter]` 표시)은 의심**
3. **헬퍼 함수 표준화** — `_sanitizeSurrogates`를 모든 LLM 응답 핸들러의 첫 줄에 적용 패턴화
4. **Stream chunk 경계 인식** — 본질적 해결은 chunk 경계가 surrogate pair 중간일 때 buffer 후 다음 chunk와 합치는 로직. 현재는 sanitize로 대증 처리

## 관련 함정
- v2.1.132 Claude Code 본체 fix가 Connect AI에 자동 적용 안 됨 → 외부 IDE extension은 별도 코드베이스라는 인지 필요
- 대표님이 "Opus 4.7로 가져가야 더 똑똑하다" 의도 → 어댑터 호환성 검증 우선

## 관련 파일
- `D:/conneteailab/_tracking/connect-ai/src/extension.ts` (line 14~27 helper, line 20176/20599 적용)
- `D:/conneteailab/_tracking/connect-ai/out/extension.js` (compile 산출물)

## 인용 (대표님 원문)
> "Ceo는 현재 opus로 변경하니 에러가 발생하고"
