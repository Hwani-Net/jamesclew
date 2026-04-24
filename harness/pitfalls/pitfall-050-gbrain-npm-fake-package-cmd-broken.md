---
title: gbrain.cmd가 npm 동명 가짜 패키지 설치로 깨짐
date: 2026-04-18
severity: P1
project: harness
---

## 증상

`/mcp` 재연결 시 gbrain "Failed to connect".
`gbrain.cmd serve` 실행 시:
```
error: Module not found "C:\Users\AIcreator\AppData\Roaming\npm\node_modules\gbrain\src\cli.ts"
```

## 원인

1. Claude Code MCP 설정: `Command: gbrain.cmd serve`
2. `gbrain.cmd`는 `%npm_root%\node_modules\gbrain\src\cli.ts`를 bun으로 실행하는 shim
3. npm에 `gbrain`이라는 **별개의 패키지**(AI 라이브러리, src/cli.ts 없음)가 존재
4. `npm install -g gbrain` 또는 충돌로 이 가짜 패키지가 설치되면 shim 동작 불가
5. 실제 gbrain KB 툴은 `~/.bun/bin/gbrain.exe`에 bun으로 설치됨

## 해결

```bash
# 1. 현재 MCP 설정 제거
claude mcp remove "gbrain" -s user

# 2. bun 실행 파일로 재등록
claude mcp add gbrain -s user -- "C:/Users/AIcreator/.bun/bin/gbrain.exe" serve
```

## 재발 방지

- `claude mcp get gbrain`으로 Command 경로 주기적 확인
- `npm install -g gbrain` 절대 금지 (가짜 패키지 덮어씀)
- 설치는 항상 `bun install -g gbrain` 경유
