---
type: pitfall
id: P-002
title: "쿠팡 이미지 캡처 시 UI 오버레이(하트/공유 버튼) 포함"
tags: [pitfall, jamesclew]
---

# P-002: 쿠팡 이미지 캡처 시 UI 오버레이(하트/공유 버튼) 포함

- **발견**: 2026-04-05
- **증상**: 제품 이미지에 쿠팡 하트/공유 아이콘이 함께 캡처됨
- **원인**: Playwright screenshot clip이 제품 이미지 영역만 잡지만 오버레이 UI가 위에 떠있음
- **해결**: og:image 메타태그에서 CDN URL 추출 → 800x800 직접 다운로드 (UI 없음)
- **재발 방지**: capture-images.mjs에 og:image 방식을 1순위로 적용
