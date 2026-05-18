# 자동화 전용 Chrome 9222 시작 스크립트 (P-169)
# 평소 Chrome 작업 인터럽트 회피 — 별도 user-data-dir 사용
# 사용: powershell -ExecutionPolicy Bypass -File harness/scripts/start-cdp-chrome.ps1

$cdpDir = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$port = 9222

# 이미 9222 포트 열려있으면 skip
$check = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
if ($check) {
    Write-Host "ALREADY_RUNNING port=$port"
    exit 0
}

# 기존 chrome.exe 전부 종료 (user-data-dir 잠금 회피)
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# CDP 모드로 Chrome 시작
$chromePath = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromePath)) {
    $chromePath = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
}
if (-not (Test-Path $chromePath)) {
    Write-Host "ERR_CHROME_NOT_FOUND"
    exit 1
}

$argList = @(
    "--remote-debugging-port=$port",
    "--user-data-dir=$cdpDir",
    "https://partners.coupang.com/"
)
Start-Process -FilePath $chromePath -ArgumentList $argList

# 포트 살아날 때까지 대기 (최대 15초)
$tries = 0
while ($tries -lt 15) {
    Start-Sleep -Seconds 1
    $ok = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($ok) {
        Write-Host "STARTED port=$port tries=$tries"
        exit 0
    }
    $tries++
}
Write-Host "TIMEOUT port=$port"
exit 2
