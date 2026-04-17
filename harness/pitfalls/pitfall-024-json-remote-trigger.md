---
type: pitfall
id: P-024
title: "\"캐시 갱신해\" 지시를 로컬 JSON으로만 해석 (클라우드 Remote Trigger 누락)"
tags: [pitfall, jamesclew]
---

# P-024: "캐시 갱신해" 지시를 로컬 JSON으로만 해석 (클라우드 Remote Trigger 누락)

- **발견**: 2026-04-16
- **증상**: 대표님 "캐시 갱신해, 다음 리셋은 19시" 지시에 `~/.harness-state/next-reset.json`만 편집. 실제 Claude Code 클라우드 Remote Trigger(`claude-5h-reset-ping`)는 **disabled 상태**로 방치. 대표님이 "claude code cloud 예약 작업"이라고 재확인 후에야 인지
- **원인**: 하네스에 존재하는 Reset Ping 시스템(Anthropic 서버 RemoteTrigger)을 범위에서 제외. 로컬 JSON 파일 갱신 = 캐시 동기화로 오해석. CronList/RemoteTrigger list를 우선 확인하지 않음
- **해결**: RemoteTrigger(action: list)로 실제 등록 확인 → 5H trigger enabled=true로 update. next_run_at 19:01 KST 검증
- **재발 방지**: "캐시 갱신" / "예약 작업" / "리셋 ping" / "cron" 키워드 감지 시 **RemoteTrigger list 우선 확인**. 로컬 파일 수정 전에 클라우드 상태 점검. CLAUDE.md 또는 /audit 체크 추가 검토
