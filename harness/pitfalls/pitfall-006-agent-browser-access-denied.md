---
type: pitfall
id: P-006
title: "agent-browser 기본 모드로 쿠팡 Access Denied"
tags: [pitfall, jamesclew]
---

# P-006: agent-browser 기본 모드로 쿠팡 Access Denied

- **발견**: 2026-04-05
- **증상**: agent-browser --headed --profile로도 쿠팡 접근 불가
- **원인**: 쿠팡이 Chromium 자동화 감지 (navigator.webdriver 등)
- **해결**: Playwright launchPersistentContext + --disable-blink-features=AutomationControlled
- **재발 방지**: 쿠팡 접근 시 반드시 Playwright 또는 og:image CDN 방식 사용
