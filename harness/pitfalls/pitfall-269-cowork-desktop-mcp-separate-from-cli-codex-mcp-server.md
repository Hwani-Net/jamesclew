---
slug: pitfall-269-cowork-desktop-mcp-separate-from-cli-codex-mcp-server
title: "Cowork(데스크톱 앱)에서 codex 안 잡힘 — CLI와 MCP 설정 표면이 다름 + codex는 셸 호출이라 MCP 아님"
symptom: "Claude Desktop Cowork 세션에서 ToolSearch 'codex' → 매칭 0. CLI에선 codex가 작동하는데 Cowork엔 안 보임."
tags: [cowork, claude-desktop, mcp, codex, mcp-server, windows, surface-separation]
date: 2026-06-15
severity: low
related: [pitfall-082-deferred-to-user-without-attempting-direct-action]
---

## 증상

Claude Desktop의 Cowork 세션에서 codex를 외부검수에 쓰려는데 `ToolSearch "codex"`가 0건. "CLI엔 codex 붙어있는데 왜 Cowork엔 안 보이지?"

## 원인 (실측 확정)

두 가지가 겹침:

1. **표면 분리**: Cowork(데스크톱 앱)와 Claude Code(CLI)는 **MCP 설정 파일이 다름**.
   - CLI: `~/.claude.json` (+ 프로젝트 `.mcp.json`)
   - 데스크톱 앱: `%APPDATA%/Claude/claude_desktop_config.json` (Windows: `C:/Users/<user>/AppData/Roaming/Claude/`)
   - CLI에 `claude mcp add`로 붙인 건 CLI 에이전트 전용 — Cowork에 자동 안 넘어옴.
   - 실측: 데스크톱 앱 설정의 `"mcpServers": {}` **완전히 비어 있었음**.

2. **codex는 애초에 MCP가 아님 (우리 하네스 기준)**: 우리는 codex를 `codex exec "..."` **셸 CLI 호출**(Bash 도구)로 씀 — MCP 서버로 등록한 적 없음. 그래서 CLI/Cowork **어느 ToolSearch에도 "도구"로 안 잡히는 게 정상**. CLI에서 "작동"하는 건 MCP라서가 아니라 Bash로 바이너리를 직접 부르기 때문.

## 해결

codex CLI는 **MCP 서버 모드를 지원**한다 (`codex mcp-server` — "Start Codex as an MCP server (stdio)", codex-cli 0.131.0 확인). 데스크톱 앱 설정에 등록하면 Cowork에 codex 도구로 노출됨.

`claude_desktop_config.json`의 `mcpServers`에 추가:
```json
"mcpServers": {
  "codex": { "command": "cmd", "args": ["/c", "codex", "mcp-server"] }
}
```

- **Windows 필수**: `cmd /c` 경유. npm 글로벌 bin의 `.cmd` 래퍼는 CreateProcess가 직접 실행 못 함 → cmd.exe가 PATH에서 resolve. (`npx` 기반 MCP도 동일 패턴 `cmd /c npx ...`.)
- **더 견고한 형태 (신규 PC 권장, codex 검수 제안)**: Claude Desktop이 PATH를 덜 상속하는 환경 대비 **full-path**로:
  ```json
  "codex": { "command": "cmd", "args": ["/c", "C:\\Users\\<user>\\AppData\\Roaming\\npm\\codex.cmd", "mcp-server"] }
  ```
  PATH 상속이 정상이면 `cmd /c codex`로 충분(실측 ROUNDTRIP-OK). 깨지면 full-path로 교체.
- 전제: `~/.codex/auth.json` 인증 유효해야 호출 시 작동 (먼저 `codex login` 검증).
- 적용 후 **앱 완전 종료(트레이 Quit) → 재실행** 필요. 창만 닫으면 미반영.
- **검증 완료 2026-06-15**: `cmd /c codex mcp-server` 등록 → 재시작 후 `mcp__codex__codex`/`codex-reply` 노출 + 실호출 ROUNDTRIP-OK. 클로버 없이 잔존.

## 재발 방지

- **⚠️ 클로버 주의**: 이 파일은 앱이 `preferences`까지 직접 관리한다(세션 상태 포함). 앱이 켜진 채 외부에서 `mcpServers`만 수정하면, 앱이 종료/설정변경 시 in-memory 스냅샷으로 **덮어써 `{}`로 되돌릴 수 있음**. 안전 순서: **앱 완전 종료 → 설정 편집 → 재실행**. 켜진 채 편집했다면 종료 후 재확인(날아갔으면 재적용).
- "X가 CLI엔 되는데 Cowork엔 안 됨" 류는 **표면별 설정 파일이 다름**을 먼저 의심. CLI=`~/.claude.json`, 데스크톱=`claude_desktop_config.json`.
- 동생 PC 세팅 시 동일 적용 — 단 codex auth는 각자 계정(P-265 토큰전쟁과 무관, codex는 Discord 봇 아님).
