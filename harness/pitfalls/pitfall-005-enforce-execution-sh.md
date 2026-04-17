---
type: pitfall
id: P-005
title: "enforce-execution.sh가 완료 보고를 미래 선언으로 오탐"
tags: [pitfall, jamesclew]
---

# P-005: enforce-execution.sh가 완료 보고를 미래 선언으로 오탐

- **발견**: 2026-04-05
- **증상**: "설계 문서 현행화 완료" 같은 과거 보고에서 Stop hook이 block
- **원인**: "진행합니다/반영합니다" 패턴이 현재형 보고도 매칭
- **해결**: 패턴을 미래형만 잡도록 변경 ("~하겠습니다/~하겠")
- **재발 방지**: hook 패턴 변경 시 과거/현재/미래 시제 모두 테스트
