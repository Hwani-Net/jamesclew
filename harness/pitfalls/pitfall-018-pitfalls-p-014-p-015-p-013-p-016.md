---
type: pitfall
id: P-018
title: "PITFALLS 번호 누락 — P-014/P-015 미기록 (P-013→P-016 점프)"
tags: [pitfall, jamesclew]
---

# P-018: PITFALLS 번호 누락 — P-014/P-015 미기록 (P-013→P-016 점프)

- **발견**: 2026-04-16
- **증상**: managed-agent-manual.md에서 P-014/P-015 참조하지만 PITFALLS.md에 실제 기록 없음. P-013 → P-016 점프
- **원인**: 해당 세션에서 매뉴얼은 작성했으나 PITFALLS 기록을 빠뜨림. P-014, P-015는 영구히 누락된 채로 남음
- **해결**: 소급 기록 (이 항목 P-018로 갭 자체를 문서화). 향후 P-014, P-015 슬롯은 비워둠
- **재발 방지**: user-prompt.ts의 forgot_record 패턴 감지 + 감사 체크에서 번호 연속성 검증
