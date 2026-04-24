---
title: 이전 세션 좀비 팀이 TeamCreate를 차단
date: 2026-04-18
severity: P1
project: dashboard-saas-mvp
---

## 증상

TeamCreate 호출 시 "Already leading team {team-name}" 에러로 실패.
이전 세션에서 생성된 팀이 종료되지 않고 ~/.claude/teams/ 에 남아있음.

## 원인

Agent Teams 팀 디렉토리가 세션 종료 후에도 자동 삭제되지 않음.
디렉토리가 존재하면 TeamCreate가 중복 생성을 거부.

## 해결

```bash
# 1. 모든 teammate에게 shutdown_request SendMessage (있다면)
# 2. 팀 디렉토리 강제 삭제
rm -rf ~/.claude/teams/{team-name}
# 3. TeamDelete 호출
# 4. 재시도
```

## 재발 방지

1. 세션 시작 전 `ls ~/.claude/teams/` 확인 — 기존 팀 존재 시 삭제 먼저.
2. `/agent-team` 스킬 R8 스캐폴드에 "기존 팀 정리" 단계 추가 고려.
3. settings.json allowlist에 `rm -rf ~/.claude/teams/` 패턴 추가하여
   7시간 루프 중 자동 정리 승인 없이 가능하게 구성.
