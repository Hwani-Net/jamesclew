---
title: pitfall-158 — Ollama proxy 호출 duration_ms=0으로 기록되어 SLA 측정 맹점
slug: pitfall-158-ollama-proxy-duration-zero-on-stream-start
date: 2026-05-17
tier: distilled
tags: [gateway, metrics, streaming, ollama, duration, observability, fastapi]
---

## 증상

FastAPI 게이트웨이가 모든 호출의 `duration_ms`, `model` 등을 `metrics.jsonl`에 누적 기록하는데, **Ollama proxy 경로의 호출 모두 `duration_ms=0`** 으로 찍힌다. 가상 모델(Claude CLI subprocess, Codex CLI subprocess) 호출은 정상(예: 24930ms)으로 기록.

실측: 519회 호출 중 5건 미만만 non-zero duration. `/metrics` 집계가 `avg_duration_ms=0` 또는 `total_duration_ms=0`로 출력 → 성능 이상 감지 불가.

## 원인

1. **`_proxy_stream(path, body)` 함수가 비동기 generator로 즉시 return**. 호출자(엔드포인트 핸들러)가 generator 함수 호출 직후 `StreamingResponse`에 넘기고, metrics는 그 시점에 기록 (`duration_ms=0`).
2. 실제 스트리밍 완료 시각은 `StreamingResponse`가 client에 모든 청크 전송한 뒤. 그 시점에 callback이 없으면 측정 불가.
3. 가상 모델(subprocess) 경로는 `subprocess.run()` blocking 호출이라 응답 받은 후 즉시 metrics에 기록 → 정상 측정.

## 해결

3가지 방향:

1. **StreamingResponse `background` 파라미터로 후처리 task** — `BackgroundTask`로 metrics flush 시점을 응답 완료 후로 미룸.
   ```python
   from starlette.background import BackgroundTask
   async def record_metrics(start_ts, model):
       dur = (time.time() - start_ts) * 1000
       _append_metric(model, dur)
   return StreamingResponse(stream, background=BackgroundTask(record_metrics, start, model))
   ```

2. **스트림 wrapper로 첫 청크/마지막 청크 시각 측정** — generator를 한 단계 감싸 마지막 yield 후 metrics 기록.

3. **stream 완료 시점 측정 포기 + Ollama 호출 자체에 별도 instrumentation** — Ollama API의 응답 헤더(`X-Response-Time` 등) 활용. 단 표준 헤더 아니라 비추천.

가장 깔끔: **방안 1 (BackgroundTask)**. FastAPI 표준 패턴, race condition 없음, 라이브 traffic 영향 0.

## 재발 방지

1. **proxy/streaming 코드에서 "duration 측정 = 함수 호출 직후" 패턴 의심**. async generator는 함수 호출 시점이 실행 시점 아님.
2. `/metrics` 같은 집계 엔드포인트 도입 시 첫 cycle 후 **non-zero duration 비율 확인** (예: 90%+ non-zero가 정상). 0이 우세하면 측정 위치 재검토.
3. 가상 모델(subprocess blocking)과 proxy(async streaming) 측정 방식이 다르다는 점을 metrics 스키마에 명시 (예: `measurement_kind: "blocking"` vs `"stream-background"`).
4. 단순 access log + duration_ms 0 조합은 **"호출 자체가 즉시 응답한 것"으로 오해**될 수 있음. 같은 모델의 여러 호출이 0ms면 측정 결함 의심.

## 관련

- [[pitfall-156-agent-tool-hallucination-without-web-search]]
- [[pitfall-157-publisher-collection-mismatch-with-live-site]]
- gpt-korea decisions.md R-MODEL-1 (옵션 1 metrics 도입 결정)
