---
type: pitfall
id: P-020
title: "Ghost Mode \"할까요\" 패턴 반복 (23건/세션)"
tags: [pitfall, jamesclew]
---

# P-020: Ghost Mode "할까요" 패턴 반복 (23건/세션)

- **발견**: 2026-04-14
- **증상**: /audit에서 Ghost Mode FAIL — "할까요", "하시겠습니까", "진행하시겠습니까" 패턴 23건 감지. stop hook이 매번 차단하지만 발생 자체가 지속
- **원인**: 위험 판단 시 확인 요청 습관. 특히 git rebase, 삭제, 설치 등 비가역 작업에서 발생
- **해결**: stop-dispatcher.sh가 실시간 차단 중. 비가역 작업도 origin 미push 상태면 안전하므로 즉시 실행
- **재발 방지**: "비가역 판단 기준"을 명확히 — origin에 push되지 않은 로컬 커밋은 자유롭게 조작 가능. push된 히스토리만 확인 필요
