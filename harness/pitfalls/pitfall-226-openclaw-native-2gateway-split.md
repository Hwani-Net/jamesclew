# P-226: OpenClaw 8봇 단일 gateway event-loop 과부하 → 네이티브 2-gateway 분리

- **발견/작업**: 2026-05-29
- **영향**: 8봇 단일 gateway가 startup 시 auth pre-warm 103초 + eventLoopMax 44초 블록 → 봇 무응답(다운처럼). 재시작마다 ~2분 dead-window.

## 증상
- `provider auth state pre-warmed in 103622ms eventLoopMax=44627.4ms` — 단일 Node event-loop가 8봇 auth/codex-app-server 동시 기동에 103초 굶음.
- 그 창에서 JARVIS·EVE 무응답. EVE가 "대답하려다 차단된 것처럼" 끊김.
- `fetch timeout ... timer delayed 9249ms, likely event-loop starvation`.

## 원인
단일 Node 프로세스(gateway)가 8개 Discord account + codex/claude CLI app-server를 한 event-loop에서 처리 → CPU/이벤트루프 포화. 8봇이 스케일 한계 초과.

## 해결 — 네이티브 2 gateway 분리 (Docker 불필요)

WSL에 Docker 미설치 + 컨테이너 codex/claude 인증 난제 → **네이티브 2번째 gateway**가 동급 부하분산 + 저위험.

### 핵심 메커니즘: `openclaw --profile <name>`
- `~/.openclaw-<name>/`에 config/state/secrets 격리 (`OPENCLAW_STATE_DIR`/`OPENCLAW_CONFIG_PATH`).
- codex/claude 인증(`~/.codex`,`~/.claude`)은 `$HOME`이라 프로필 무관 공유.

### 구성
- gw1 (default, :18789): main/claude/codex/ollama = JARVIS/EVE/TARS/Data (코어)
- gw2 (`--profile pro`, :18790, `~/.openclaw-pro`): hermes/kitt/c3po/joi = FRIDAY/KITT/C3PO/Joi (전문)

### 구축 단계 (검증됨)
1. `~/.openclaw-pro/openclaw.json` = main deep copy → accounts/agents/bindings를 전문4로 필터 + `gateway.port=18790` + `secrets.providers.localfile.path=~/.openclaw-pro/secrets.local.json`.
2. `~/.openclaw-pro/secrets.local.json` = 필요 토큰만 (전문4 토큰 + gateway_auth + codex/ollama key), chmod 600.
3. **main config에서 전문4 account/agent/binding 제거** (안 하면 같은 토큰 두 gateway 연결 → 토큰전쟁 P-197).
4. **⚠️ 결정적 함정 — npm 플러그인 심링크**: non-bundled 플러그인(discord/codex/acpx)은 `~/.openclaw/npm/node_modules/@openclaw/`에 있음. profile은 `~/.openclaw-pro/npm/`에서 찾아 **discord 플러그인 미로드**(2 plugins만: anthropic,memory-core) → 봇 0 연결. 해결: `ln -sfn ~/.openclaw/npm ~/.openclaw-pro/npm`.
5. **포트 충돌 회피**: browser 플러그인이 127.0.0.1:18791 바인딩 → 두 gateway 충돌. gw2에서 `plugins.entries.browser.enabled=false` (+ canvas/phone-control/talk-voice/device-pair/file-transfer). **⚠️ `plugins.allow`는 줄이지 말 것** — allow를 축소하면 discord 로딩이 깨짐. allow는 main과 동일하게 두고 entries로만 비활성.
6. systemd user 서비스 `openclaw-gateway-pro.service`: `ExecStart=%h/.npm-global/bin/openclaw --profile pro gateway --port 18790` + READY timeout env + enable --now.
7. gw1 재시작 + gw2 start.

## 검증
- gw2 pre-warm **17초** (103→17), eventLoopMax **2.6초** (44→2.6).
- gw1 pre-warm 84초, eventLoopMax 8초 (claude-cli opus+sonnet 스핀업이 무거워 잔존).
- gw2 전문4 전원 client initialized. gw1에서 전문봇 연결 0 (토큰전쟁 없음). 양쪽 starvation 0.

## 재발 방지 / 운영
- 봇 추가 시 어느 gateway에 둘지 결정 + 해당 profile config에만 등록 (양쪽 등록 금지 = 토큰전쟁).
- gw2 재시작: `systemctl --user restart openclaw-gateway-pro.service`.
- 새 non-bundled 플러그인 추가 시 심링크라 자동 공유됨.
- gw1이 여전히 무거우면(claude-cli) JARVIS/EVE를 추가 분리 검토.

## 관련
- [[pitfall-225-openclaw-12agents-film-rename-scaling]] — 8봇 스케일 한계 발견
- [[pitfall-224-wsl2-instance-idle-timeout-gateway-death]]
- [[pitfall-197-openclaw-duplicate-instance-sigterm-loop]] — 토큰전쟁(중복 등록)
