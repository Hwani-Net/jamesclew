---
slug: pitfall-120-bash-start-flag-windows
title: "Windows start.exe /B 플래그를 bash에서 호출 시 'B:/' 경로로 오해석"
date: 2026-05-09
tags: [pitfall, windows, bash, start, copilot-api]
---

# 증상
bash 셸에서 `start "" /B copilot-api start --port 4141 &` 실행 시 Windows 파일 탐색기 다이얼로그 "B:/ 시스템이 지정된 드라이브를 찾을 수 없습니다" 발생. cmd.exe 좀비 프로세스 잔존 (사용자 확인 안 누르면 영구 점유).

# 원인
Git Bash / MSYS는 `/B` 같은 Windows 스타일 플래그를 자동으로 POSIX 경로로 변환 (MSYS path translation). `start.exe`에 전달될 때 `/B` → `B:/` 또는 `B:\` 로 변환되어 첫 번째 파일/디렉토리 인자로 해석됨. 결과: `cmd.exe /c start "" B:/ copilot-api ...` — Windows가 `B:/`를 열려고 시도 → 드라이브 없음 → 다이얼로그.

# 해결
**금지**: bash에서 Windows `start /B`, `start /MIN` 등 슬래시 플래그 직접 사용

**권장 (1순위)**: bash 네이티브 백그라운드
```bash
nohup copilot-api start --port 4141 > /tmp/copilot.log 2>&1 &
```

**권장 (2순위)**: PowerShell 경유
```bash
powershell.exe -Command "Start-Process -WindowStyle Hidden copilot-api -ArgumentList 'start','--port','4141'"
```

**권장 (3순위)**: MSYS path translation 비활성화
```bash
MSYS_NO_PATHCONV=1 cmd.exe //c "start /B copilot-api start --port 4141"
```
(`//c` 슬래시 두 개로 escape, `/B`도 자동 변환 차단)

# 재발 방지
- bash 셸에서 Windows `.exe` 호출 시 슬래시 플래그(`/B`, `/MIN`, `/WAIT` 등)는 **MSYS 경로 변환 위험** 항상 인지
- 백그라운드 프로세스는 **bash native `nohup ... &`** 우선 사용
- 의도치 않은 cmd.exe 좀비 발견 시: `wmic.exe process where "name='cmd.exe'" get ProcessId,CommandLine` 으로 명령어 라인 확인 후 `taskkill.exe //PID <pid> //F`

# 자체 검증
- 본 사례 직접 재현 (2026-05-09 22:xx, JamesClaw 세션)
- WMI 추적으로 PID 69184의 CommandLine = `cmd.exe /c start "" B:/ copilot-api start --port 4141` 확인
- `/B` → `B:/` 변환 입증
