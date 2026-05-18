---
slug: pitfall-141-schtasks-csv-korean-column-mismatch
title: schtasks /fo CSV가 한국어 시스템에서 컬럼명 매칭 실패 — /xml 또는 한국어 컬럼명 사용
date: 2026-05-10
tags: [windows, schtasks, locale, korean, debugging, decommission]
severity: high
---

# 증상
한국어 Windows에서 매시간 발화하는 Task Scheduler 작업을 찾기 위해 `schtasks /query /fo CSV /v | ConvertFrom-Csv | Where-Object { $_.'Repeat: Every' -eq '1:00:00' }`를 실행했으나 **결과 0건**. 그러나 실제로는 `\SmartReviewBlog-AutoPublish` task가 매시간 발화 중이었음. 이로 인해 Connect AI healthcheck 정리 진단이 1시간+ 지연됨 (대표님 텔레그램 알림 4회 추가 발생).

# 원인
한국어 Windows에서 `schtasks /query /fo CSV /v` 출력의 컬럼명이 **한국어로 표시됨**:
- `Repeat: Every` (영어 시스템) → `반복: 매` (한국어)
- `Last Run Time` → `마지막 실행 시간`
- `Next Run Time` → `다음 실행 시간`
- `Task To Run` → `실행할 작업`
- `Status` → `상태`

`ConvertFrom-Csv` 후 `$_.'Repeat: Every'` property 접근은 **null 반환**. 필터 조건이 모두 false → 매시간 task 0개로 잘못 보고됨.

# 해결
`/fo CSV` 대신 **`/fo XML`** 또는 task별 `/xml`을 사용하여 locale-independent 분석:

```powershell
# 잘못된 방법 (한국어 시스템에서 결과 0건)
schtasks /query /fo CSV /v | ConvertFrom-Csv | Where-Object { $_.'Repeat: Every' -eq '1:00:00' }

# 올바른 방법 1: /xml 옵션 + XML 파싱
$tasks = schtasks /query /fo CSV /nh | ConvertFrom-Csv -Header TaskName,Next,Status
foreach ($t in $tasks) {
    $xml = [xml](schtasks /query /tn $t.TaskName /xml | Out-String)
    if ($xml.Task.Triggers.InnerXml -match 'PT1H|PT60M') {
        Write-Host "HOURLY: $($t.TaskName)"
        Write-Host "  Action: $($xml.Task.Actions.Exec.Command)"
    }
}

# 올바른 방법 2: ScheduledTasks 모듈 (PowerShell 4.0+)
Get-ScheduledTask | Where-Object {
    $_.Triggers.Repetition.Interval -match 'PT1H|PT60M'
} | Select TaskName, TaskPath
```

XML 트리거 형식 (ISO 8601 duration):
- `PT1H` = 1시간
- `PT60M` = 60분
- `PT30M` = 30분
- `P1D` = 1일

# 재발 방지 — Locale-aware Diagnostic 체크리스트
한국어 Windows에서 시스템 진단 시 반드시:

1. **schtasks**: `/fo CSV` 대신 `/xml` 또는 `Get-ScheduledTask` 사용
2. **tasklist**: `/fo CSV`는 안전하지만 `/v` (verbose) 옵션의 컬럼명은 한국어
3. **Get-WmiObject**: 영어 property 이름 사용하므로 안전 (`Win32_Process` 등)
4. **netstat /n**: locale 영향 없음
5. **schtasks 작업명 검색 시**: 한국어 keyword와 영어 keyword 모두 시도. 또는 task 이름은 보통 영어로 등록되므로 TaskName 매칭 우선

# 관련
- pitfall-117 (powershell-encoding-cp949)
- pitfall-137 (powershell-stderr-cp949-corruption)
- pitfall-139 (ps1-no-bom-cp949-mojibake-injection)
- pitfall-140 (connect-ai-task-scheduler-orphan)
