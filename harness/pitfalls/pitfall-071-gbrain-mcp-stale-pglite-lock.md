---
slug: pitfall-071-gbrain-mcp-stale-pglite-lock
title: "gbrain MCP 서버 disconnect 후 PGLite lock 점유 — CLI gbrain query timeout"
date: 2026-04-26
tier: raw
tags:
  - pitfall
  - gbrain
  - mcp
  - pglite
  - lock
related:
  - pitfall-050
versions:
  - "gbrain 0.10.2"
  - "Claude Code 2.1.120"
---

# 증상

`gbrain query <키워드>` 명령이 `GBrain: Timed out waiting for PGLite lock.` 으로 timeout.
`gbrain stats`, `gbrain list` 등 모든 read 명령 동일.

`claude mcp get gbrain` 결과는 `Status: ✓ Connected`로 표시되어 정상으로 보이나,
실제 MCP 도구(mcp__gbrain__query 등)는 session reminder에 "MCP server disconnected" 표시.

# 원인

PGLite는 single-writer 제약 (file-based lock).
gbrain MCP 서버(stdio mode, `~/.bun/bin/gbrain.exe`)가 hang 또는 partial-disconnect 상태로
PGLite connection을 점유한 채 잔존 → CLI gbrain CLI(`/c/Users/AIcreator/AppData/Roaming/npm/gbrain`)가
lock 대기 → timeout.

Claude Code v2.1.x는 stdio MCP가 list_tools 응답을 못 줄 때 도구 schema는 disconnected로 표시하지만
프로세스 자체는 cleanup 안 함 (자동 reset 미구현).

`postmaster.pid`의 `-42`는 PGLite stub PID (in-memory). 실제 OS PID 아니라 직접 추적 불가.

# 해결

gbrain MCP 서버 프로세스를 강제 종료 → 다음 호출 시 자동 재spawn:

```bash
# Windows Git Bash
cmd //c "taskkill /IM gbrain.exe /F"

# 1초 대기 후 CLI 재시도
sleep 1
gbrain query "<키워드>"
```

다음 `gbrain` 호출 시 새 PGLite connection으로 정상 동작.

검증: pitfall-067/069/070 검색 시 relevance 0.85+ 1순위 반환 확인.

# 재발 방지

- 새 세션 시작 시 SessionStart hook으로 gbrain 프로세스 health check 후 stale 시 자동 kill 권장 (v12 후보)
- `claude mcp restart gbrain` 같은 명령이 v2.1.121+에서 추가되면 그 명령으로 cleanup
- gbrain CLI 명령이 timeout 시 즉시 본 PITFALL 슬러그(pitfall-071) 매칭하여 복구
- 임시 SessionStart hook 후보:
  ```bash
  # ~/.claude/hooks/gbrain-mcp-health.sh
  if ! timeout 3 gbrain stats >/dev/null 2>&1; then
    cmd //c "taskkill /IM gbrain.exe /F" 2>/dev/null
  fi
  ```

# 검증 데이터 (2026-04-26 09:53)

복구 전:
- `gbrain stats` / `gbrain query` 모두 timeout
- `claude mcp get gbrain`: Connected

복구 명령: `cmd //c "taskkill /IM gbrain.exe /F"` → "PID 48412 종료" 출력

복구 후:
- `gbrain stats`: Pages 1267, Chunks 3031, Embedded 2975
- `gbrain query "FKH undefined"`: pitfall-067 1순위 (0.879)
- `gbrain query "codex logout"`: pitfall-069 1순위 (0.857)
- `gbrain query "statusline opus"`: pitfall-070 1순위 (0.859)
