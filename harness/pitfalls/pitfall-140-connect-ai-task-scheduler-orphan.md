---
slug: pitfall-140-connect-ai-task-scheduler-orphan
title: Connect AI 정리 시 Task Scheduler 작업 잔존 — vbs/Startup만 보고 놓침
date: 2026-05-10
tags: [connect-ai, cleanup, task-scheduler, autostart, decommission]
severity: high
---

# 증상
Connect AI extension 삭제 + 어댑터/watchdog 프로세스 kill + Windows Startup 폴더의 `connect_ai_adapter.vbs`를 `.disabled-cleanup`으로 비활성화 완료. 그런데도 텔레그램으로 healthcheck 실패 알림(`unhealthy attempt N — pid=None ... watchdog will spawn within 60s`)이 30분마다 계속 도착.

# 원인
자동시작 메커니즘이 **두 종류** 있는데 한 종류만 정리:
1. ✅ Windows Startup 폴더 `connect_ai_adapter.vbs` (이미 비활성화됨)
2. ❌ **Windows Task Scheduler `\JamesClaw\ConnectAI-Healthcheck`** (놓침 — 30분 cron으로 `D:\jamesclew\harness\scripts\connect-ai-adapter\healthcheck-and-self-heal.py` 발화)
3. ❌ **`\connect-ai-repatch-hourly`** (놓침 — 시간마다 확장 재패치 시도)

Task Scheduler는 Startup 폴더와 완전히 별도 메커니즘이라 vbs를 비활성화해도 영향 없음. healthcheck 스크립트는 자체적으로 텔레그램 토큰 로드 (`D:/conneteailab/_agents/secretary/tools/telegram_setup.json`) 후 `api.telegram.org/sendMessage` 직접 호출.

# 해결
```bash
# Task Scheduler 삭제 (PowerShell)
schtasks /delete /tn '\JamesClaw\ConnectAI-Healthcheck' /f
schtasks /delete /tn 'connect-ai-repatch-hourly' /f

# 스크립트 폴더 자체 무력화 (수동 호출 차단)
mv "D:/jamesclew/harness/scripts/connect-ai-adapter" \
   "D:/jamesclew/harness/scripts/connect-ai-adapter.disabled-cleanup-20260510"
```

# 재발 방지 — Decommission 체크리스트
시스템 제거 시 **모든 자동시작 메커니즘**을 동시에 점검해야 함. 한 곳만 보고 끝내면 안 됨:

| # | 메커니즘 | 점검 명령 |
|---|---|---|
| 1 | Windows Startup 폴더 | `ls "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"` |
| 2 | **Task Scheduler** (가장 자주 놓침) | `schtasks /query /fo LIST \| Select-String <키워드>` |
| 3 | Windows Service | `Get-Service \| Where Name -match <키워드>` |
| 4 | Registry Run keys | `Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run` |
| 5 | PowerShell profile | `cat $PROFILE` |
| 6 | Bash/Zsh init | `cat ~/.bashrc ~/.bash_profile ~/.zshrc` |
| 7 | VS Code/Antigravity 확장 백그라운드 | settings.json의 확장별 설정 |
| 8 | cron / systemd timer (linux/wsl) | `crontab -l; systemctl list-timers` |

PITFALL-122 패턴 재발(한 곳만 보고 다른 메커니즘 놓침). 다음 cleanup부터는 **위 8개 체크리스트 전체 점검 후 보고**.

# 관련
- pitfall-122 (decision-boundary): user vs external model vs self
- pitfall-138 (adapter-copilot-api-cascade-failure)
- pitfall-135 (llm-response-surrogate-pair-broken)
