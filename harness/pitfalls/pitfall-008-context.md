---
type: pitfall
id: P-008
title: "세션 Context %를 읽을 방법이 없다고 잘못 보고"
tags: [pitfall, jamesclew]
---

# P-008: 세션 Context %를 읽을 방법이 없다고 잘못 보고

- **발견**: 2026-04-05
- **증상**: "제가 직접 확인할 수 있는 방법이 없다"고 텔레그램 보고
- **원인**: user-prompt.ts가 매 턴마다 context_window 데이터를 받고 있었는데, 파일에 저장하지 않아 다른 도구에서 접근 불가. 방법이 없는 게 아니라 저장 로직이 없었을 뿐
- **해결**: user-prompt.ts에 context_pct, context_tokens를 state 파일에 기록하도록 추가
- **재발 방지**: "방법이 없다" 전에 데이터 흐름을 추적. hook이 받는 데이터를 파일로 저장하면 다른 도구에서 읽을 수 있음
