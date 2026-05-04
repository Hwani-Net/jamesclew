# Antigravity 누적 프로세스 정리 — 작업 스케줄러 1일 1회 실행 권장
# orphan(부모 종료된 자식) Antigravity 프로세스만 종료, 활성 메인 창은 보존

$ErrorActionPreference = "Continue"

$AllProcs = Get-Process -Name "Antigravity" -ErrorAction SilentlyContinue
if (-not $AllProcs) {
    Write-Host "[INFO] Antigravity not running."
    exit 0
}

$Total = $AllProcs.Count
Write-Host "[*] Antigravity total processes: $Total"

# MainWindowHandle != 0 = 활성 창. orphan은 MainWindowHandle = 0 + parent 죽음
$Active = $AllProcs | Where-Object { $_.MainWindowHandle -ne 0 }
$NoWin  = $AllProcs | Where-Object { $_.MainWindowHandle -eq 0 }

Write-Host "  Active windows: $($Active.Count)"
Write-Host "  No-window child procs: $($NoWin.Count)"

# 활성 창이 0개면 모두 orphan → 전체 정리
# 활성 창이 1개+ 면 보수적으로 진행 (자식 프로세스도 활성 창에 종속될 수 있음)
if ($Active.Count -eq 0 -and $NoWin.Count -gt 0) {
    Write-Host "[!] No active windows — killing $($NoWin.Count) orphan procs"
    $NoWin | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction Stop
            Write-Host "  killed PID $($_.Id)"
        } catch {
            Write-Host "  failed PID $($_.Id): $_" -ForegroundColor Yellow
        }
    }
} elseif ($NoWin.Count -gt 30) {
    Write-Host "[WARN] $($NoWin.Count) child procs but $($Active.Count) active window(s) — too many, partial cleanup"
    # 메모리 가장 적게 쓰는 절반만 종료 (zombie 추정)
    $kill = $NoWin | Sort-Object -Property WorkingSet | Select-Object -First ([math]::Floor($NoWin.Count / 2))
    $kill | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction Stop
            Write-Host "  killed PID $($_.Id) (WS=$([math]::Round($_.WorkingSet/1MB,1))MB)"
        } catch {}
    }
} else {
    Write-Host "[OK] No cleanup needed."
}

Write-Host "[DONE]"
