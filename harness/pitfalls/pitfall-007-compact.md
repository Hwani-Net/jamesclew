---
type: pitfall
id: P-007
title: "compact 후 세션 요약 저장하면 의미 없음"
tags: [pitfall, jamesclew]
---

# P-007: compact 후 세션 요약 저장하면 의미 없음

- **발견**: 2026-04-05
- **증상**: compact 후 옵시디언 세션 요약을 저장하려 했으나 원본 맥락이 이미 압축됨
- **원인**: compact가 맥락을 압축하므로 이후에는 상세 내용을 복원할 수 없음
- **해결**: compact 전(60-65% 시점)에 저장 작업을 먼저 실행
- **재발 방지**: user-prompt.ts 60% 트리거 + PreCompact hook에 자동 snapshot
