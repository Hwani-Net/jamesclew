# P-258: OpenClaw v2026.6.1 업데이트 — hooks.enabled: true 시 hooks.token 필수 (gateway startup_failed)

- **발견**: 2026-06-08
- **영향**: OpenClaw v2026.6.1 업데이트 후 gateway 즉시 startup_failed. 9봇 전부 사망.

## 증상

- `systemctl --user status openclaw-gateway.service` → `failed (Result: exit-code)`, duration 3s
- 로그: `Gateway failed to start: hooks.enabled requires hooks.token. Run openclaw gateway status --deep for diagnostics.`
- 이전 버전(5.x~6.0.x)에서는 정상 작동하던 config가 갑자기 실패

## 원인

OpenClaw v2026.6.1에서 **보안 요구사항 신설**: `hooks.enabled: true`일 때 반드시 `hooks.token`도 설정해야 gateway 시작 허용.

이전 버전에서 `hooks.token`이 없어도 `hooks.enabled: true` 허용하던 것을 강제 검증으로 바꿈.

우리 `openclaw.json`에 `hooks.enabled: true`는 있었으나 `hooks.token`이 없는 상태 → startup 즉시 exit-code=1.

## 해결

1. **토큰 생성**:
   ```bash
   openssl rand -hex 32
   ```

2. **`openclaw.json` hooks 섹션에 직접 추가** (secrets.local.json 자동 매핑은 이 케이스에서 미작동):
   ```json
   {
     "hooks": {
       "internal": { "enabled": true, "entries": {...} },
       "enabled": true,
       "token": "<generated-hex-32>"
     }
   }
   ```

3. **`systemctl --user reset-failed openclaw-gateway.service` 후 start**

4. **검증**: `channels status` → 9봇 connected 확인

## 주의

- `secrets.local.json`에 `hooks_token` 키 추가만으로는 안 됨 (openClaw secrets auto-mapping이 이 케이스에서 작동 안 함)
- 직접 `openclaw.json`의 `hooks.token` 필드에 값 넣어야 함
- `hooks.token`은 외부 HTTP 훅 엔드포인트 인증용 (내부 hooks는 `hooks.internal`로 별도 제어)

## 재발 방지

- OpenClaw 버전 업데이트 후 gateway startup_failed → **즉시 로그에서 `hooks.enabled requires hooks.token` 확인**
- 업데이트 시 stability bundle 확인: `/home/creator/.openclaw/logs/stability/`
- 버전 업 후 30초 내 `systemctl is-active` 체크하는 습관

## 관련

- [[pitfall-229-openclaw-522-claude-cli-harness-bug-527-recovery]] — 버전 업 후 봇 무응답 (다른 케이스)
- [[pitfall-249-openclaw-528-agentruntime-key-removed-gateway-crash]] — 버전 업으로 config 키 제거
- CLAUDE.md P-229 "OpenClaw 자동 업데이트=시한폭탄, 버전 업 후 claude 봇 Discord 실측 필수"
