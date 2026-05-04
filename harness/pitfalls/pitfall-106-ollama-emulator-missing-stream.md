---
slug: pitfall-106-ollama-emulator-missing-stream
title: Ollama API emulator 만들 때 stream NDJSON 미구현 → 클라이언트 무한 대기
tags: [ollama, streaming, ndjson, adapter, connect-ai]
date: 2026-05-03
---

# 증상
Connect AI(VS Code 확장)가 어댑터 4142로 호출 → HTTP 200 응답 받음 → 그러나 **화면에 응답 표시 안 됨**.
어댑터 로그엔 200 정상 처리 흔적 있음. 클라이언트 측만 빈 채팅 버블.

# 원인
Connect AI는 Ollama 표준대로 `stream: true` 보냄.
Ollama 서버는 stream:true 시 **NDJSON 형식**으로 응답:
```
{"message":{"content":"안"},"done":false}\n
{"message":{"content":"녕"},"done":false}\n
{"message":{"content":""},"done":true,"done_reason":"stop"}\n
```
어댑터 v2/v3 초기 구현은 stream 옵션을 무시하고 항상 단일 JSON 응답:
```
{"message":{"content":"안녕하세요"},"done":true}
```
Ollama 클라이언트(Connect AI)는 첫 청크만 보고 NDJSON 파싱 시도 → 형식 불일치 → 무시 → 무한 대기.

# 해결
어댑터에서 inbody의 `stream` 플래그 분기:
- `stream:false` → 단일 JSON (Ollama non-stream 형식)
- `stream:true` → **NDJSON 2-chunk 응답** (Content-Type: application/x-ndjson)
  - chunk 1: `{message:{content:전체내용}, done:false}`
  - chunk 2: `{message:{content:""}, done:true, done_reason:..., usage 통계}`

upstream(copilot-api)은 항상 non-stream으로 호출해도 OK — 어댑터가 클라이언트에게만 가짜 stream 흉내.

# 재발 방지
Ollama API emulator/proxy 작성 시 필수 체크리스트:
- [ ] `/api/tags` GET (모델 목록)
- [ ] `/api/chat` POST stream:false (단일 JSON)
- [ ] `/api/chat` POST **stream:true (NDJSON 2-chunk 이상)**
- [ ] `/api/generate` POST 양쪽 모두
- [ ] Content-Type: `application/x-ndjson` (stream 시)
- [ ] 각 line 끝에 `\n` 필수

검증 명령:
```bash
curl -N -X POST http://127.0.0.1:PORT/api/chat \
  -d '{"model":"...","messages":[...],"stream":true}'
# 출력이 2줄 이상의 JSON이어야 정상
```
