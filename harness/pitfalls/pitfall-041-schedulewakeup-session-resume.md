---
type: pitfall
id: P-041
title: "ScheduleWakeup + 백그라운드 Bash는 세션 종료/재시작 시 모두 중단"
tags: [pitfall, jamesclew]
---

# P-041: ScheduleWakeup + 백그라운드 Bash는 세션 종료/재시작 시 모두 중단

- **발견**: 2026-04-17
- **증상**: Wan 1.3B 추론 작업을 Sonnet에 백그라운드 위임 + ScheduleWakeup으로 4분 후 결과 확인 예약. 세션이 도중에 resume(SessionStart:resume hook 발동)되면서 mp4 미생성. 예약된 wakeup도 fire 안 됨
- **원인**:
  1. **ScheduleWakeup**은 세션이 활성 상태로 idle일 때만 fire. Claude Code 프로세스 종료/재시작 시 예약 큐 무효화됨
  2. **백그라운드 Bash (`run_in_background: true`)**도 Claude Code 프로세스에 종속. 프로세스 종료 시 자식 프로세스도 SIGKILL
  3. **Subagent 백그라운드 위임**도 동일 — Sonnet agent가 호출한 Python 스크립트는 Claude Code 종료 시 같이 죽음
- **해결**:
  1. **장시간 (10분+) 추론 작업**: foreground 동기 실행 (`run_in_background: false`) + 충분한 timeout (`timeout: 900000`)
  2. **OS-level 작업 분리**: `nohup python script.py &` 또는 Windows Task Scheduler로 Claude Code 외부에서 실행
  3. **결과 파일 폴링**: 동기 대기 대신 결과 파일 존재 + mtime 비교로 진행 상황 확인
  4. ScheduleWakeup은 짧은 idle 작업 (몇 분 이내 + 세션 활성 보장 시)에만 사용
- **재발 방지**:
  - 5분+ 백그라운드 작업 위임 전 "세션이 그동안 활성 유지될 수 있는가?" 자문
  - claude-mcp 재연결, 사용자 일시 자리 비움, 자동 슬립 등 모두 세션 종료 트리거
  - 안전한 패턴: foreground 실행 + timeout 600000+ / OS cron / 결과 파일 폴링
