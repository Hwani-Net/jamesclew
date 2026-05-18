---
slug: pitfall-123-copilot-api-supported-endpoints-metadata-missing
title: copilot-api supported_endpoints 메타 누락으로 호출 가능 모델이 화이트리스트에서 제외됨
date: 2026-05-07
severity: medium
status: resolved
tags: [adapter, copilot-api, shopify-unrelated, model-discovery]
---

# copilot-api supported_endpoints 메타 누락 — 어댑터 화이트리스트 자동 제외

## 증상

Connect AI 모델 오케스트레이션 모달의 dropdown에 `gpt-4.1`, `gpt-4o` 안 보임. 어댑터 `/api/tags`(127.0.0.1:4142)에도 미노출. 다른 GPT 모델(gpt-5-mini, gpt-5.2, gpt-5.4, gpt-5.5)은 정상 노출.

대표님 직접 지적 — "gpt 4.1이 왜 안보여?"

## 원인 (data-driven 검증)

`http://127.0.0.1:4141/v1/models` 응답 분석:

```
gpt-4.1        supported_endpoints=[]      ← 빈 리스트
gpt-4o         supported_endpoints=[]      ← 빈 리스트
gpt-41-copilot supported_endpoints=[]      ← 빈 리스트
gpt-5-mini     supported_endpoints=['/chat/completions', ...]  ← OK
gpt-5.2        supported_endpoints=['/chat/completions', ...]  ← OK
gpt-5.4        supported_endpoints=['/chat/completions', ...]  ← OK
```

어댑터 `fetch_whitelist()`는 `supported_endpoints`에 `/chat/completions` 포함 모델만 화이트리스트에 추가. `gpt-4.1`은 빈 리스트라 자동 제외 → `/api/tags`에서 노출 안 됨 → 모달 dropdown에서 사라짐.

**중요**: 호출 자체는 정상 작동. `POST /v1/chat/completions` `model=gpt-4.1` → 1.4초 응답 검증 완료 (이전 세션). 즉 metadata 누락만 문제.

추정 원인: copilot-api(@jeffreycao/copilot-api) 또는 GitHub Copilot 백엔드가 일부 모델의 metadata를 누락 반환. Pro 구독 vs Business 권한 차이일 수도.

## 해결

`C:/temp/bench/connect_ai_adapter_v3.py` v6.5 패치:

```python
COPILOT_FORCE_CHAT_MODELS = [
    "gpt-4.1",   # instruction following 우수 — 이미지 도구 매핑용
    "gpt-4o",    # vision 지원 chat 모델
]

def fetch_whitelist():
    # ... 기존 supported_endpoints 검사 ...
    # 강제 포함: copilot-api가 supported_endpoints=[] 반환해도 호출 가능한 모델
    for forced in COPILOT_FORCE_CHAT_MODELS:
        if forced in upstream_ids:
            result.add(forced)
```

업스트림에 모델이 존재하기만 하면(supported_endpoints 무관) 화이트리스트에 강제 포함.

검증:
- `/api/tags` 모델 수: 13 → **15** (gpt-4.1, gpt-4o 추가)
- 모달 dropdown에 `gpt-4.1 [adapter]`, `gpt-4o [adapter]` 표시됨

## 재발 방지

1. 신규 GPT 모델 노출 안 될 때 우선 `curl /v1/models` 응답에서 `supported_endpoints` 확인
2. 빈 리스트면 `COPILOT_FORCE_CHAT_MODELS`에 추가하고 호출 테스트로 작동 확인
3. copilot-api 업데이트 시 metadata 정상화될 수 있음 — 주기적 재검증
4. 어댑터 시작 시 `[whitelist fetched: ...]` 로그에서 누락 모델 확인

## 검증 사례

- 2026-05-07 11:32 — 모달에 gpt-4.1 안 보임 지적
- 2026-05-07 12:15 — supported_endpoints=[] 검증, COPILOT_FORCE_CHAT_MODELS 패치, 노출 복원
