---
type: pitfall
id: P-010
title: "MCP 연결 끊김 시 재연결 시도 없이 바로 대체 수단 전환"
tags: [pitfall, jamesclew]
---

# P-010: MCP 연결 끊김 시 재연결 시도 없이 바로 대체 수단 전환

- **발견**: 2026-04-05
- **증상**: lazy-mcp가 "Connection closed" 에러 반환. 바로 WebSearch로 전환하여 진행
- **원인**: MCP 끊김 = 일시적 장애일 수 있음. 재연결(reconnect) 시도 없이 포기한 것은 도구 활용 미숙
- **해결**: 대표님이 수동으로 MCP reconnect 처리
- **재발 방지**: MCP 연결 끊김 시 ① `claude mcp remove + add`로 reconnect ② invoke 재시도 ③ 그래도 실패 시에만 curl 직접 호출. WebSearch/researcher 서브에이전트로 우회하는 것은 최후 수단.
- **2회 재발 (2026-04-05)**: 같은 세션에서 lazy-mcp 끊김 시 reconnect 없이 바로 curl 직접 호출로 우회. P-010 교훈을 따르지 않음.
