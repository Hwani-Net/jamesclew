# P-186: OpenClaw v2026.5.18 Native Windows에서 Codex runtime "Managed binary not found" 해결법

- **발견**: 2026-05-20
- **영향**: 이 fix 없이 OpenClaw가 codex runtime 호출 불가 (TUI · Discord 봇 응답 모두 차단)

## 증상

```
run error: Managed Codex app-server binary was not found for @openai/codex.
Reinstall or update OpenClaw, or run pnpm install in a source checkout.
Set plugins.entries.codex.config.appServer.command or OPENCLAW_CODEX_APP_SERVER_BIN to use a custom Codex binary.
```

추가로 로그에:
```
Codex agent harness failed; not falling back to embedded PI backend
lane task error: ... Managed Codex app-server binary was not found ...
```

## 원인

OpenClaw가 자체 bundled `@openai/codex` binary를 찾지 못함 (Native Windows npm 설치는 OpenClaw 패키지에 codex가 포함 안 됨). custom binary 등록 두 방법 중:

- ❌ `~/.openclaw/.env` 파일에 `OPENCLAW_CODEX_APP_SERVER_BIN=...` 작성: **daemon이 읽지 않음** (Scheduled Task 환경에서)
- ❌ `plugins.entries.codex.config.appServer.command`: config key는 매뉴얼이 인용한 정확한 path이지만 **단독으론 인식 안 됨** (또는 부분 인식)
- ✓ **`setx` 시스템 env var** + **`npm install -g @openai/codex` 재설치**: 둘 다 해야 daemon이 정상 인식

## 해결 (검증됨)

```powershell
# A. 시스템 환경변수 영구 등록 (관리자 권한 불필요)
setx OPENCLAW_CODEX_APP_SERVER_BIN "C:\Users\<USER>\AppData\Roaming\npm\codex.cmd"

# B. @openai/codex npm 글로벌 강제 재설치 (codex.cmd가 정상 OpenAI 패키지인지 보장)
npm install -g @openai/codex

# C. Gateway restart (새 env var 전달)
openclaw gateway restart
```

검증:
- TUI에서 메시지 입력 → 정상 응답
- Discord DM → 한국어/영어 응답 (자동 언어 감지)

## Discord WS READY 부수 발견

```
discord: gateway READY wait timed out after 15000ms; reconnecting with backoff (attempt 1)
```

이 메시지는 영구 결함 아님. 첫 시도 15초 timeout 후 **backoff reconnect로 자동 회복**. backoff 1-2회 후 정상 ready 도달. P-184 진단이 부정확했던 부분.

## 재발 방지

- OpenClaw 신규 설치 시 즉시 A+B+C 시퀀스 실행
- Native Windows에서는 config 파일보다 시스템 env var이 daemon에 더 안정적으로 전달됨
- "Managed binary not found" 에러는 `setx` 한 번이 모든 해결의 핵심

## 관련

- [[pitfall-184-openclaw-windows-discord-readiness]] — 부분 부정확 (영구 결함 아님, 정정)
- [[pitfall-185-openclaw-anthropic-plugin-cmd-enoent]] — anthropic plugin 한정 (codex 안 씀)
- OpenClaw 매뉴얼: docs.openclaw.ai/channels/discord

## 시간 분석

- 시도 횟수: 100+ 회 도구 호출
- 컨텍스트 낭비 패턴: 매뉴얼 미정독 → 추측·시도 → 같은 fail 반복 → 결국 매뉴얼 정독 → fix
- 교훈: **신규 도구 도입 시 매뉴얼 정독 (특히 troubleshooting + env var 섹션)이 첫 단계**
