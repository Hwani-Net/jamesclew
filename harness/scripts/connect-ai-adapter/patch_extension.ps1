# Connect AI Extension Patch — 2건 자동 + 1건 수동 안내
# Antigravity 확장 업데이트(v2.46.4+) 시 재실행 필요

$ErrorActionPreference = "Stop"

$ExtRoot = "$env:USERPROFILE\.antigravity\extensions"
$Files = Get-ChildItem -Path $ExtRoot -Recurse -Filter "extension.js" |
    Where-Object { $_.FullName -like "*connectailab.connect-ai-lab-*" }

if ($Files.Count -eq 0) {
    Write-Host "[ERR] Connect AI extension not found at $ExtRoot" -ForegroundColor Red
    exit 1
}

# 자동 패치 정의 (단일 라인 또는 작은 블록만)
$Patches = @(
    @{
        Name   = "PIN Gate Bypass (corporateUnlocked)"
        Needle = "corporateUnlocked=false"
        Patch  = "corporateUnlocked=true"
    },
    @{
        Name   = "Interview Wizard Skip (showInterviewCard)"
        Needle = "function showInterviewCard(){`r`n  bootEnsure();`r`n  bootRenderWizard(0);`r`n}"
        Patch  = "function showInterviewCard(){`r`n  return; /* PATCH: skip company-setup interview wizard */`r`n}"
    }
)

foreach ($f in $Files) {
    $path = $f.FullName
    Write-Host "`n[*] Patching: $path" -ForegroundColor Cyan

    $backup = "$($f.DirectoryName)\extension.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').js"
    Copy-Item $path $backup
    Write-Host "  [OK] Backup: $backup" -ForegroundColor Gray

    $content = Get-Content $path -Raw -Encoding UTF8
    $changed = $false

    foreach ($p in $Patches) {
        if ($content -match [regex]::Escape($p.Patch)) {
            Write-Host "  [SKIP] $($p.Name) — already patched." -ForegroundColor Yellow
            continue
        }
        if ($content -notmatch [regex]::Escape($p.Needle)) {
            # LF only (no CR) fallback for non-Windows line endings
            $needleLF = $p.Needle -replace "`r`n", "`n"
            if ($content -notmatch [regex]::Escape($needleLF)) {
                Write-Host "  [WARN] $($p.Name) — needle not found." -ForegroundColor Yellow
                continue
            }
            $content = $content -replace [regex]::Escape($needleLF), ($p.Patch -replace "`r`n", "`n")
        } else {
            $content = $content -replace [regex]::Escape($p.Needle), $p.Patch
        }
        Write-Host "  [OK] $($p.Name) — patched." -ForegroundColor Green
        $changed = $true
    }

    # 수동 패치 항목 안내 (멀티라인 정확 매칭이 PowerShell에서 깨지기 쉬움)
    if ($content -match 'err\?\.code === "EADDRINUSE"' -and `
        $content -notmatch 'EADDRINUSE.*return') {
        Write-Host "  [MANUAL] EADDRINUSE 다중 창 패치 필요 — 아래 절차:" -ForegroundColor Magenta
        Write-Host "    1. extension.js 열기 → 'EADDRINUSE' 검색" -ForegroundColor Gray
        Write-Host "    2. server.on('error', (err) => { ... }) 블록의 ternary를:" -ForegroundColor Gray
        Write-Host "       if (err?.code === 'EADDRINUSE') { return; }" -ForegroundColor Gray
        Write-Host "       const msg = ... 형태로 수정" -ForegroundColor Gray
    }

    if ($changed) {
        Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  [DONE] File saved." -ForegroundColor Green
    } else {
        Write-Host "  [INFO] No auto-patches applied." -ForegroundColor Gray
        Remove-Item $backup -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n[NEXT] Antigravity 모든 창에서 Ctrl+Shift+P -> 'Reload Window' 실행" -ForegroundColor Cyan
