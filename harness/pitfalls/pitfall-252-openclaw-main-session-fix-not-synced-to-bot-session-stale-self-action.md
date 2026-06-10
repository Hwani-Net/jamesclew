# P-252: 메인 세션이 OpenClaw 인프라를 고쳐도 봇(JARVIS) 세션은 stale 인식 → 봇이 잘못된 자율 행동(불필요 대행·중복 수정)

- **발견**: 2026-06-02 (대표님 "JARVIS 봇이 TARS 차단이라는데 무슨 말?" — 메인은 이미 고쳤는데 봇은 차단으로 인지)
- **영향**: TARS는 실제 정상인데 JARVIS 봇이 "TARS 차단→EVE 대행"으로 헛돌고, 메인이 이미 한 플러그인 정렬을 EVE에 중복 위임하려 함. 자율 사이클 토큰·시간 낭비 + 대표님 혼란.

## 증상
- 메인 세션(Claude Code)이 WSL에서 직접 `@openclaw/codex` 5.28 설치+gateway restart로 TARS 복구 + echo/date 실증 통과(22:07).
- **그런데 JARVIS 봇(22:03 Discord)은 "TARS 차단 상태라 EVE가 대행"이라 판단** → 6/1~6/2 TARS relay 차단 시절 컨텍스트를 그대로 보유.
- JARVIS 봇 메시지 자체가 모순: "TARS 차단 상태"라면서 끝줄엔 "relay 차단 없음 — 직전 critic0 차단 정황 미재현". JARVIS가 제안한 해결책(플러그인 5.28 정렬+gateway 재시작)은 **메인이 이미 codex에 한 것과 동일**.

## 근본 원인
- **메인 세션 ↔ 봇 세션은 별도 컨텍스트.** 메인이 WSL CLI로 인프라를 고쳐도, 돌고 있는 봇 세션(JARVIS cron/continuation)은 그 변경을 **자동으로 알지 못한다.** 봇은 자기 마지막 인식(TARS 차단)으로 자율 판단 계속.
- 즉 인프라 수정의 "사실"과 봇의 "인식"이 분리됨 → 봇이 stale 전제로 잘못된 자율 행동(불필요 대행, 이미 한 작업 중복 지시).

## 해결 (검증 중)
- **메인이 인프라 변경 후 봇 세션에 명시적으로 알린다**: `openclaw agent --agent main --channel discord --deliver -m "[메인→JARVIS 인식 갱신] <무엇을 왜 어떻게 고쳤고 실증 결과는 무엇> → 따라서 <봇이 바꿔야 할 인식/행동>"`.
- 이번: TARS 복구(원인=플러그인 버전, 조치=5.28+restart, 실증=tars-now-ok/체인) + "EVE 대행·중복 정렬 불필요, discord/acpx는 작동 중이라 의도적 보류" 주입.

## 재발 방지 (영구 규칙)
- **메인 세션이 OpenClaw 봇 인프라(플러그인/config/gateway/relay)를 수정하면, 끝에 반드시 JARVIS 봇 세션에 변경 사실 + 실증 + 봇이 갱신할 인식을 메시지로 동기화한다.** 안 하면 봇이 stale 전제로 헛돈다.
- 봇이 "X 차단/고장"이라 주장해도 **메인의 실측(`openclaw agent --agent X -m echo`)이 우선** — 봇 인식은 시점차로 틀릴 수 있음. 봇 보고를 현재 사실로 단정 금지.
- 역방향도 주의: 봇이 자율로 인프라를 고치면(EVE 위임 등) 메인이 모를 수 있음 — 변경은 한 곳(메인)으로 집중하거나 양방향 통지.

## 관련
- [[pitfall-251-openclaw-528-codex-plugin-518-stale-worker-blocked-relay-unavailable]] (이번에 메인이 고친 실제 내용)
- [[pitfall-246-openclaw-probe-resolved-not-equal-online-presence]] (봇 상태 보고 ≠ 실제, 실측 우선 동일 교훈)
