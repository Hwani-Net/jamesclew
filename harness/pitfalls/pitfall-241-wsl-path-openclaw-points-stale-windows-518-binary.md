# P-241: WSL `openclaw` 명령이 Windows stale 5.18 바이너리를 가리킴 → 모든 수동 CLI 오작동 (P-239/240 오진의 진짜 원인)

- **발견**: 2026-05-31 (봇 자율진행 "0%" 오진을 추적하다 발견)
- **영향**: WSL에서 친 `openclaw cron list / agent / doctor / --deliver`가 전부 **낡은 Windows 5.18 바이너리**로 실행됨. 5.27용 config를 "invalid"로 오판, agent turn "0줄", deliver Discord 미도달 → **봇 자율진행이 죽은 것처럼 보였으나 실제로는 멀쩡**. P-239(deliver 실패)·P-240(자율 0%)의 진짜 원인이 이것.

## 증상
- `wsl ... openclaw cron list` → `Invalid config at openclaw.json: codex.baseUrl/models, anthropic.baseUrl Invalid input`
- `wsl ... openclaw agent --agent claude -m "..."` → stdout 0줄 (응답 없음)
- `wsl ... openclaw agent --deliver --channel discord` → exit 0, legacy 경고만, **Discord 채널 미도달**(fetch_messages 실측)
- `wsl ... openclaw doctor` → legacy key migration 제안 + hang

## 근본 원인 (실측)
- `which -a openclaw` (WSL `bash -c`) = **`/mnt/c/Users/AIcreator/AppData/Roaming/npm/openclaw`** (Windows npm, May 19, **5.18**).
- `wsl -e bash -c`의 PATH는 Windows PATH를 append → `/mnt/c/.../npm`이 `/home/creator/.npm-global/bin`보다 먼저 잡혀 **Windows 5.18 바이너리 실행**.
- 실제 gateway(systemd) = `/usr/bin/node /home/creator/.npm-global/lib/node_modules/openclaw/dist/index.js` = **WSL 5.27** (정상).
- 즉 **gateway 5.27 ↔ 수동 CLI 5.18** 버전 불일치. 5.18로 5.27 config(anthropic.models 등록형) 읽으니 schema 불일치로 invalid 오판.
- `openclaw --version`(PATH) = 2026.5.18 / `npm ls -g openclaw` = 2026.5.27 / `/home/creator/.npm-global/bin/openclaw --version` = 2026.5.27.

## 검증 (봇 살아있음 증거)
- `node /home/creator/.npm-global/lib/node_modules/openclaw/dist/index.js agent --agent claude -m "..."` → EVE **"응답 정상 확인했습니다"** 정상 turn.
- `journalctl --user -u openclaw-gateway.service` → claude-opus-4-8/sonnet-4-6 live session turn이 heartbeat/user trigger로 계속 발생(durationMs, rawLines=13). 13:36 user trigger = 위 테스트가 실제 처리됨.
- `node ... cron list` → cron 4개 정상 조회(contest 09:00 ok, Memory Dreaming 03:00 ok). config invalid 안 나옴.

## 해결 (영구)
1. **WSL openclaw 호출은 반드시 5.27 절대경로**:
   - `/home/creator/.npm-global/bin/openclaw <cmd>` 또는
   - `node /home/creator/.npm-global/lib/node_modules/openclaw/dist/index.js <cmd>` (가장 안전 — bin 스크립트도 PATH 의존 회피)
   - ⚠️ **그냥 `openclaw <cmd>` 금지** (Windows 5.18로 감).
2. 근본 정리(선택, 신중): `.bashrc`에 `export PATH=/home/creator/.npm-global/bin:$PATH` 또는 `alias openclaw=/home/creator/.npm-global/bin/openclaw`. 단 다른 도구 PATH 영향 검토 후.
3. Windows의 stale 5.18 npm openclaw 제거 검토 (`/mnt/c/.../AppData/Roaming/npm/openclaw`) — WSL 운영에 불필요하면.

## 재발 방지
- **P-218 확장**: WSL OpenClaw 작업은 절대경로뿐 아니라 **5.27 바이너리 절대경로** 명시 필수. `openclaw` 단독 명령은 Windows stale을 호출하는 함정.
- **봇 무응답/ config invalid 진단 시 1순위 = 바이너리 버전 확인** (`which -a openclaw` + `--version`). config 손상으로 단정 금지(P-240 오진 교훈).
- 봇 "active"·자율진행 판정은 **gateway 로그(journalctl)의 turn 발생**으로 — CLI 응답 0줄을 봇 죽음으로 오판 금지(잘못된 바이너리일 수 있음).

## 관련 (정정)
- [[pitfall-239-openclaw-agent-deliver-legacy-config-discord-undelivered]] — deliver 실패의 진짜 원인은 config가 아니라 stale 5.18 바이너리. 정정.
- [[pitfall-240-main-session-became-worker-not-auditor-bot-autonomy-dead]] — "자율 0%·config 손상"은 오진. 인프라는 살아있음. 단 "main이 감사자여야 한다"는 역할 교훈은 유효.
- [[pitfall-229-openclaw-522-harness-bug-527-recovery]] — 5.27 복구 후 Windows 5.18 잔존이 PATH 함정 유발.
