---
slug: pitfall-140-connect-ai-extension-fallback-cascade
title: Connect AI extension의 hardcoded LM Studio fallback 경로 12건 + 자동 engine recovery 로직이 settings.ollamaUrl을 무시하고 1234를 강제 호출
date: 2026-05-09
tags: [connect-ai, extension, hardcoded, fallback, cascade, lm-studio, engine-recovery]
severity: high
debug_hops: 4 (P12 → P13 → P14)
---

# Connect AI extension의 hardcoded 1234 fallback 경로 12건이 settings.ollamaUrl을 무시

## 증상
- 사용자 settings.json `connectAiLab.ollamaUrl=http://127.0.0.1:4142` 명시 + adapter 4142 정상 동작 + claude-opus-4.7 정상 응답
- 그러나 Connect AI에서 CEO 호출 시 매번:
  ```
  ⚠️ CEO 호출 실패: connect ECONNREFUSED 127.0.0.1:1234
  💡 LLM 서버에 연결 못함 — Ollama/LM Studio가 켜져 있는지 확인.
  ```
- LM Studio(1234)는 안 켜져 있음 — Connect AI가 자기 판단으로 1234를 시도

## 원인 (3-layer cascade)

### Layer 1 — 자동 engine recovery (P13)
extension.js line 23552 영역의 함수: 모델 호출 fail 시 `mismatched` 조건이 true면 1234/11434 자동 probe + settings.json `ollamaUrl` 강제 변경:
```js
if (await probe("http://127.0.0.1:1234", true)) target = "http://127.0.0.1:1234";
else if (await probe("http://127.0.0.1:11434", false)) target = "http://127.0.0.1:11434";
if (target && target !== url2) {
  await cfg.update("ollamaUrl", target, vscode2.ConfigurationTarget.Global);
}
```

### Layer 2 — startup auto-detect (line 23684)
extension activate 시 LM Studio detection — 1234/v1/models GET 시도 + 응답 있으면 settings 강제 변경.

### Layer 3 — queryLMStudio 보조 함수 (line 16932)
일부 모델 목록 조회에서 LM Studio 직접 호출.

총 **12건의 hardcoded `127.0.0.1:1234`** 가 extension.js에 분산. settings.ollamaUrl 변경해도 hardcoded 경로는 그대로.

## 해결 (3단계 patch)

### P12 — adapter copilot-api fault tolerance (#138)
adapter 4142가 4141 fail 시에도 claude-cli/codex-cli 모델 노출.

### P13 — engine recovery 비활성화
line 23552의 probe 함수 직전에 `return;` 주입 — recovery 흐름 통째로 차단.
```js
/* PATCH v7.3: engine recovery 비활성화 — 4142 adapter는 LM/Ollama 아니지만 정상 동작 */
return;
let target = "";
if (await probe(...))
```

### P14 — 1234 → 4142 redirect (12건)
extension.js의 모든 `127.0.0.1:1234` hardcode를 `127.0.0.1:4142`로 sed 변환. Connect AI가 LM Studio를 호출하려 해도 우리 adapter 경유 → claude-opus-4.7 등 정상 응답.

```python
content.replace("127.0.0.1:1234", "127.0.0.1:4142")  # 12건
```

마커: `/* PATCH v7.4: 1234 → 4142 redirect (LM Studio hardcode를 adapter로) */`

## 영구 보존 (자동 재적용)
`D:/jamesclew/harness/scripts/connect-ai-adapter/repatch-extension.ps1` v7.4 헤더 갱신:
- P13 마커 검사 + 비활성화 코드 재주입
- P14 마커 검사 + 12건 redirect 재실행
- BOM 보존 (PITFALL #139 fix)

## 재발 방지 체크리스트
1. **외부 extension 사용 시 hardcoded 경로 grep** — `127.0.0.1`, `localhost`, port 번호 모두 검사
2. **settings.json 우선이 아닐 수 있다** — extension 자체 fallback 로직 가능성 항상 의심
3. **mismatched/probe/recovery 같은 변수명 함수는 모두 자동 변경 위험** — settings 덮어쓰기 의도 코드 식별 후 비활성화 검토
4. **모든 hardcoded port를 adapter port로 redirect** — 가장 강력한 방어선

## 관련 PITFALL
- pitfall-138 adapter-copilot-api-cascade-failure (P12)
- pitfall-139 ps1-no-bom-cp949-mojibake-injection (BOM)
- pitfall-136 adapter-cwd-system32-surrogate-corruption (cwd)
- pitfall-137 powershell-stderr-cp949-corruption (P11)

## 인용 (대표님 원문)
> "왜 자꾸 문제가 재발해?"

근본 원인: **6개 layer cascade dependency** (Connect AI → settings → adapter 4142 → copilot-api 4141 / claude CLI / LM Studio 1234 / Ollama 11434) 한쪽 고치면 다음 fall. 마켓플레이스 v2.89.58 코드는 우리 통제 외이며 가정 못 한 fallback 경로 다수 보유. 9개 패치(P9~P14 + cwd + BOM + cleanup)로 점진 차단.
