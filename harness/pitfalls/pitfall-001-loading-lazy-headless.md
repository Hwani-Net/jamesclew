---
type: pitfall
id: P-001
title: "loading=\"lazy\"가 headless 브라우저에서 이미지 로드 차단"
tags: [pitfall, jamesclew]
---

# P-001: loading="lazy"가 headless 브라우저에서 이미지 로드 차단

- **발견**: 2026-04-05
- **증상**: agent-browser에서 naturalWidth > 0 체크 시 첫 이미지만 로드, 나머지 0
- **원인**: loading="lazy"가 스크롤 이벤트 없이는 이미지를 로드하지 않음. scrollTo()도 lazy trigger 불충분
- **해결**: 전체 42개 img 태그에서 loading="lazy" 제거
- **재발 방지**: CLAUDE.md + smartreview-blog CLAUDE.md에 loading="lazy" 사용 금지 규칙
