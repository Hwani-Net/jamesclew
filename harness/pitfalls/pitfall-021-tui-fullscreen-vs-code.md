---
type: pitfall
id: P-021
title: "/tui fullscreen VS Code 터미널에서 크래시"
tags: [pitfall, jamesclew]
---

# P-021: /tui fullscreen VS Code 터미널에서 크래시

- **발견**: 2026-04-16
- **증상**: `/tui fullscreen` 실행 시 세션 다운. Antigravity(VS Code 통합 터미널)에서 발생
- **원인**: VS Code 터미널이 synchronized output 미지원. /tui fullscreen이 이 기능에 의존
- **해결**: VS Code 터미널에서는 `/tui default` 사용. fullscreen은 Windows Terminal에서만
- **재발 방지**: 터미널 호환성 확인 — `TERM_PROGRAM=vscode`이면 /tui fullscreen 사용 금지
