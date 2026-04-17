---
type: pitfall
id: P-031
title: "Git Bash에서 cmd /c npx 호출 시 /c가 C:/로 자동 변환"
tags: [pitfall, jamesclew]
---

# P-031: Git Bash에서 cmd /c npx 호출 시 /c가 C:/로 자동 변환

- **발견**: 2026-04-17
- **증상**: `claude mcp add wikipedia -s user -- cmd /c npx -y <pkg>` 실행 후 `claude mcp list`에 `cmd C:/ npx ...`로 등록됨 → Failed to connect
- **원인**: Git Bash(MSYS2)의 자동 경로 변환 기능이 POSIX 스타일 `/c`를 Windows 경로 `C:/`로 오인해서 바꿈
- **해결**: `MSYS_NO_PATHCONV=1 claude mcp add ... -- cmd /c npx ...` 로 prefix env var 적용
- **재발 방지**: Windows Git Bash에서 `claude mcp add --` 뒤에 Windows 절대경로/옵션 플래그가 오면 반드시 `MSYS_NO_PATHCONV=1` prefix 사용
