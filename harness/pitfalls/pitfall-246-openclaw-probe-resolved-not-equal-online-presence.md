# P-246: openclaw "probe resolved" / channels status "connected" ≠ Discord online presence (봇 online 오판)

- **발견**: 2026-06-01 (gw2 봇 online 복구 오판 반복)
- **영향**: 봇이 실제로 Discord 멤버목록에 offline인데 "복구됐다"고 거짓 보고 → 대표님 "여전히 4개만" 반복 지적.

## 증상
- `channels status --probe` → `Discord c3po: enabled, configured, running, connected, ... works` 인데 **대표님 Discord 화면엔 offline**.
- 로그 `[discord] [c3po] Discord bot probe resolved @C3PO` 를 online으로 오판.
- gw1 4봇은 online, gw2 3봇(c3po/joi/kitt)은 offline — 같은 openclaw인데 결과 다름.

## 근본 원인 (실측)
- **probe resolved** = REST API로 봇 토큰 검증(앱 정보 가져옴). 토큰 유효일 뿐 **online 아님**.
- **client initialized** 도 됨(gw2 3개 확인). 하지만 그 다음 **"awaiting gateway readiness"에서 멈춤** — Discord WSS gateway **READY 이벤트를 못 받음** → presence 안 뜸.
- gw1 봇은 client init → READY → online. gw2 봇은 client init → awaiting readiness(멈춤). WSS close code(4004/4014)는 없음.
- 단계: starting provider → channels resolved → **probe resolved**(토큰OK) → **client initialized as <appid>**(WSS 시작) → **awaiting gateway readiness** → [READY] → online. gw2는 READY 직전 멈춤.

## 해결 방향 (미확정 — Discord 측)
- READY 못 받는 원인 후보: ①Discord IDENTIFY rate limit(같은 IP 다수 봇 동시 연결) ②Privileged Intent(Presence/Server Members) 미승인 ③봇이 길드 미초대. 로그론 close code 없어 추가 구분 불가.
- C3PO/Joi/KITT는 P-225 "미충원" 봇 → Discord 개발자 포털 Intent 승인 + 봇 서버 초대 점검 필요(대표님 영역).

## 재발 방지 (영구)
- **봇 online 보고 전 반드시 실제 확인**: ①대표님 Discord 화면 멤버목록 ②또는 봇에게 메시지 보내 응답. `channels status --probe`의 "connected/works"·"probe resolved" 로그를 online으로 보고 금지.
- "awaiting gateway readiness"가 봇별 마지막 로그면 = **online 아님**(READY 대기 중). gw1 정상 봇과 로그 단계 비교.

## 관련
- [[pitfall-243-gw1-restart-breaks-gw2-websocket-specialist-bots-down]] (gw2 봇 다운 사고)
- [[pitfall-225-openclaw-12agents-film-rename-scaling]] (C3PO/Joi/KITT 미충원)
- [[pitfall-245-openclaw-codex-harness-model-must-be-codex-provider]] (gw2 primary codex/gpt-5.5 401 부작용 — 롤백)
