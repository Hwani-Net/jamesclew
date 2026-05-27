# P-184: OpenClaw v2026.5.18 Native Windows에서 Discord guild channel 응답 불안정 (30초 timeout 후 backoff cycle)

- **발견**: 2026-05-20
- **정정**: 2026-05-20 (최초 진단 "영구 차단" → "OS-specific 불안정성"으로 수정)
- **영향**: Native Windows에서 Discord guild channel 응답이 매우 불안정. 짧은 ready window에서만 간헐 응답. WSL2 환경에서는 완전 해결.

## 증상

- Discord 봇 setup 완료 (Privileged Intents ON, OAuth invite, channels add, plugins.entries.discord.enabled, pairing approve, owner 등록)
- 봇이 Discord 앱에서 online 표시
- 첫 DM은 pairing code 응답 (one-shot pre-ready code path)
- DM은 P-186 fix 후 정상 응답 (pairing flow + REST API, WS READY 무관)
- **Guild channel inbound 메시지 매우 불안정**: 로그에 30초 timeout 반복, 드물게만 응답
- 로그 패턴:
  ```
  discord: gateway opened but did not reach READY within 30000ms; reconnecting with backoff
  discord client initialized as <id>; awaiting gateway readiness
  ```
  → 30초 timeout 후 channel exit → auto-restart cycle 반복
- **예외 사례 (2026-05-20 04:03 / 04:05 KST)**: backoff 이후 짧은 ready window에서 채널 응답 확인됨 ("수정됨" 표시 = tool 호출 흔적). 즉, "영구 차단"은 부정확한 진단이었음.

## 원인

Discord plugin 코드 `formatDiscordStartupStatusMessage`:
```javascript
if (params.gatewayReady) return `logged in to discord${identitySuffix}`;
return `discord client initialized${identitySuffix}; awaiting gateway readiness`;
```

`params.gatewayReady` flag가 Native Windows에서 30초 이내 `true`에 도달하지 못하는 경우가 대부분. plugin 내부 비동기 promise (`discordVoiceRuntimePromise`, `discordProviderSessionRuntimePromise`) 또는 ready event handler가 불안정하게 트리거됨. 정식 message handler는 readiness 필요 → 30초 타임아웃 시 미활성화. backoff 후 retry 사이클에서 아주 드물게 ready 도달 → 그 window에서만 응답 가능.

OpenClaw 시작 화면에 `"Windows detected - OpenClaw runs great on WSL2! Native Windows might be trickier"` 명시.

## ⚠️ 진단 오류 인정 (2026-05-20 정정)

최초 진단에서 "영구 차단"으로 단정한 것은 부정확하였습니다. 실제로는:
- Native Windows에서도 04:03/04:05 KST에 채널 응답 사례가 확인됨
- 단, 동작 조건이 매우 협소하고 재현 불안정 — 실용적으로 신뢰하기 어려움
- 올바른 진단: **OS-specific 불안정성** (WSL2 대비 채널 응답률 현저히 낮음)

## 동작 가능 / 불안정 path 분리 (2026-05-20 검증)

| Path | WS READY 의존 | Native Windows | WSL2 Ubuntu |
|------|--------------|---------------|-------------|
| DM 봇 응답 | ❌ (pairing flow + REST) | ✓ 안정 (P-186 fix 후) | ✓ 안정 |
| TUI / Web UI 대시보드 채팅 | ❌ (직접 gateway WS) | ✓ 안정 | ✓ 안정 |
| 봇 자체 outbound 채널 메시지 | ❌ (REST API) | ✓ 안정 | ✓ 안정 |
| **Guild channel inbound 메시지** | ✓ (MESSAGE_CREATE event) | ⚠️ 간헐 (매우 불안정) | ✅ 안정 |
| Guild slash command (`/skill`) | ✓ (INTERACTION_CREATE) | ⚠️ 추정 불안정 (미검증) | ✅ 추정 안정 |

## 해결

- **A. WSL2 전환 (권장 — 검증 완료)**: [[pitfall-187-openclaw-wsl2-deployment-success]] 참조. 09:22 멘션 → 09:23 즉시 응답 확인. tool 사용 + 합니다체 + "대표님" 호칭 + 🦞 이모지 정상.
- B. OpenClaw GitHub Issues 보고 + 다음 버전 대기
- C. Plugin 코드 직접 패치 (minified, 업데이트 시 깨짐 — 비권장)

## 재발 방지

- 신규 Windows native 도구 도입 시 cross-platform 지원 코드 명시 확인 (.cmd 분기 + 비동기 promise resolution)
- OpenClaw 비슷한 도구는 "Windows runs great on WSL2" 같은 경고 즉시 정독
- 초기 진단에서 "영구 차단" 같은 단정 표현 사용 전 충분한 검증 필요 — 간헐 동작이 "차단"으로 오해될 수 있음

## 관련

- [[pitfall-185-openclaw-anthropic-plugin-cmd-enoent]]
- [[pitfall-186-openclaw-codex-binary-env-var-fix]]
- [[pitfall-187-openclaw-wsl2-deployment-success]] ← 해결책
- [[pitfall-188-openclaw-wsl2-deployment-complete-2026-05-20]] ← WSL2 완전 운영 절차 + 함정 5종
- OpenClaw 매뉴얼: docs.openclaw.ai/channels/discord
