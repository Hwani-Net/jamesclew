---
type: pitfall
id: P-033
title: "Tavily 로테이터 코드 수정 시 MCP 서버 재시작 필수"
tags: [pitfall, jamesclew]
---

# P-033: Tavily 로테이터 코드 수정 시 MCP 서버 재시작 필수

- **발견**: 2026-04-17
- **증상**: tavily-rotator.mjs에 432 처리 추가 후에도 "exceeds usage limit" 에러. 6키 중 5개 살아있는데 로테이션 안 됨
- **원인**: MCP 서버는 Claude Code 시작 시 한 번만 로드됨. 세션 중 파일 수정해도 실행 중 node 프로세스는 이전 버전 사용
- **해결**: 로테이터 수정 후 Claude Code CLI 재시작. 임시 대체는 DuckDuckGo/Wikipedia/WebSearch
- **재발 방지**: MCP 프록시 파일 수정 시 "재시작 필요" 경고 출력. session-start hook에서 mtime 비교 추가
