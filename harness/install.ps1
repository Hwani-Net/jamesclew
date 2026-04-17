# JamesClaw Agent — Windows PowerShell Installer
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1
#        powershell -ExecutionPolicy Bypass -File install.ps1 -NonInteractive

param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🤖 JamesClaw Agent — PowerShell Installer" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan

# ─── Paths ───
$ClaudeHome  = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME ".claude" }
$StateDir    = Join-Path $HOME ".harness-state"
$HarnessDir  = Join-Path $HOME ".harness"
$HarnessSrc  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$EnvFile     = Join-Path $HOME ".harness.env"
$PersonaFile = Join-Path $HarnessDir "persona.yaml"

Write-Host "📍 Platform: Windows"
Write-Host "📂 Harness source: $HarnessSrc"
Write-Host "📂 Claude home:    $ClaudeHome"
Write-Host "📂 State dir:      $StateDir"
Write-Host ""

# ─── Prerequisites ───
Write-Host "🔍 Checking prerequisites..."
$missing = @()
if (-not (Get-Command node -ErrorAction SilentlyContinue))   { $missing += "node (https://nodejs.org)" }
if (-not (Get-Command git -ErrorAction SilentlyContinue))    { $missing += "git" }
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { $missing += "claude CLI" }
if ($missing.Count -gt 0) {
    Write-Host "❌ Missing: $($missing -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "✅ node, git, claude found" -ForegroundColor Green
Write-Host ""

# ─── Prompt helpers ───
function Prompt-Default($label, $default) {
    if ($NonInteractive) { return $default }
    $v = Read-Host "  $label [$default]"
    if ([string]::IsNullOrWhiteSpace($v)) { return $default } else { return $v }
}
function Prompt-YesNo($label, $default) {
    if ($NonInteractive) { return $default }
    $hint = if ($default -eq "y") { "[Y/n]" } else { "[y/N]" }
    $v = Read-Host "  $label $hint"
    if ([string]::IsNullOrWhiteSpace($v)) { return $default }
    if ($v.ToLower() -match "^(y|yes)$") { return "y" } else { return "n" }
}
function Prompt-Secret($label) {
    if ($NonInteractive) { return "" }
    $sec = Read-Host "  $label (empty to skip)" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    return $plain
}

# ─── Persona ───
Write-Host "🎭 Persona setup" -ForegroundColor Yellow
$AgentName  = Prompt-Default "Agent name" "JamesClaw"
$Honorific  = Prompt-Default "How should the agent address you?" "대표님"
$Language   = Prompt-Default "Primary language (ko/en/ja/zh)" "ko"
$Tone       = Prompt-Default "Tone (formal/casual/witty)" "witty"
$StyleNotes = Prompt-Default "Style notes (user profile)" "초기 설계 중시, 검증 필수, 불확실한 정보는 솔직히 명시"
$Obsidian   = Prompt-Default "Obsidian vault path (empty to disable)" ""
Write-Host ""

# ─── Modules ───
Write-Host "🧩 Optional modules" -ForegroundColor Yellow
$ModTelegram = Prompt-YesNo "Telegram notifications" "n"
$ModObsidian = if ($Obsidian) { "y" } else { "n" }
$ModCodex    = Prompt-YesNo "Codex CLI (external code review)" "n"
$ModCopilot  = Prompt-YesNo "copilot-api (GPT-4.1 proxy on :4141)" "n"
$ModOllama   = Prompt-YesNo "Ollama local LLM fallback" "n"
Write-Host ""

Write-Host "🧩 MCP servers" -ForegroundColor Yellow
$McpPerplexity = Prompt-YesNo "Perplexity (web search)" "y"
$McpTavily     = Prompt-YesNo "Tavily (crawl+extract)" "y"
$McpStitch     = Prompt-YesNo "Stitch (Google UI designer)" "n"
$McpDesktop    = Prompt-YesNo "Desktop Control (computer use)" "n"
Write-Host ""

# ─── API keys ───
Write-Host "🔑 API keys" -ForegroundColor Yellow
$PplxKey = ""; $TvlyKey = ""; $TgToken = ""; $TgChat = ""; $OpenaiKey = ""
if ($McpPerplexity -eq "y") { $PplxKey   = Prompt-Secret "PERPLEXITY_API_KEY" }
if ($McpTavily -eq "y")     { $TvlyKey   = Prompt-Secret "TAVILY_API_KEY" }
if ($ModTelegram -eq "y")   {
    $TgToken = Prompt-Secret "TELEGRAM_BOT_TOKEN"
    $TgChat  = Prompt-Default "TELEGRAM_CHAT_ID" ""
}
if ($ModCodex -eq "y" -or $ModCopilot -eq "y") { $OpenaiKey = Prompt-Secret "OPENAI_API_KEY" }
Write-Host ""

# ─── Write files ───
# Reject symlinks/reparse points at target paths (TOCTOU guard)
foreach ($f in @($EnvFile, $PersonaFile, (Join-Path $ClaudeHome "CLAUDE.md"))) {
    if (Test-Path $f) {
        $attrs = (Get-Item $f -Force).Attributes
        if ($attrs -band [IO.FileAttributes]::ReparsePoint) {
            Write-Host "❌ Refusing to write: $f is a symlink/reparse point (TOCTOU risk)." -ForegroundColor Red
            exit 1
        }
    }
}
if (-not $HOME -or -not (Test-Path $HOME -PathType Container)) {
    Write-Host "❌ `$HOME is unset or invalid: '$HOME'" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $HarnessDir, $StateDir | Out-Null

@"
# JamesClaw env — generated by installer
PERPLEXITY_API_KEY=$PplxKey
TAVILY_API_KEY=$TvlyKey
OBSIDIAN_VAULT=$Obsidian
TELEGRAM_BOT_TOKEN=$TgToken
TELEGRAM_CHAT_ID=$TgChat
OPENAI_API_KEY=$OpenaiKey
"@ | Set-Content -Path $EnvFile -Encoding UTF8
# Restrict to current user only (Windows equivalent of chmod 600)
try {
    icacls $EnvFile /inheritance:r /grant:r "${env:USERNAME}:F" | Out-Null
} catch {
    Write-Host "   ⚠ Could not restrict $EnvFile permissions — review manually" -ForegroundColor Yellow
}
Write-Host "✅ Wrote $EnvFile (user-only ACL)"

@"
agent_name: "$AgentName"
honorific: "$Honorific"
language: "$Language"
tone: "$Tone"
style_notes: "$StyleNotes"
obsidian_vault: "$Obsidian"
"@ | Set-Content -Path $PersonaFile -Encoding UTF8
Write-Host "✅ Wrote $PersonaFile"

# ─── Deploy ───
Write-Host ""
Write-Host "🚀 Deploying harness..."
New-Item -ItemType Directory -Force -Path $ClaudeHome, "$ClaudeHome\hooks", "$ClaudeHome\rules", "$ClaudeHome\scripts", "$ClaudeHome\agents", "$ClaudeHome\commands" | Out-Null

# Render CLAUDE.md with persona substitutions (literal .Replace, NOT regex -replace)
# -replace treats args as regex and enables $1/$& backrefs → injection risk if user input contains $.
$claude = Get-Content -Raw -Path "$HarnessSrc\CLAUDE.md" -Encoding UTF8
$claude = $claude.Replace("대표님", $Honorific)
$claude = $claude.Replace("JamesClaw", $AgentName)
$claude = $claude.Replace("기본값: 초기 설계 중시, 검증 필수, 불확실한 정보는 솔직히 명시", "기본값: $StyleNotes")
$claude | Set-Content -Path "$ClaudeHome\CLAUDE.md" -Encoding UTF8

Copy-Item "$HarnessSrc\settings.json" "$ClaudeHome\settings.json" -Force
Copy-Item "$HarnessSrc\rules\*" "$ClaudeHome\rules\" -Recurse -Force
Copy-Item "$HarnessSrc\hooks\*" "$ClaudeHome\hooks\" -Recurse -Force
Copy-Item "$HarnessSrc\scripts\*" "$ClaudeHome\scripts\" -Recurse -Force
if (Test-Path "$HarnessSrc\agents")   { Copy-Item "$HarnessSrc\agents\*" "$ClaudeHome\agents\" -Recurse -Force }
if (Test-Path "$HarnessSrc\commands") { Copy-Item "$HarnessSrc\commands\*" "$ClaudeHome\commands\" -Recurse -Force }
# PITFALLS.md — DEPRECATED (2026-04-17): gbrain으로 완전 마이그레이션됨.
# 조회: gbrain query "키워드" / 기록: gbrain import D:/jamesclew/harness/pitfalls/
# if (Test-Path "$HarnessSrc\commands\PITFALLS.md") { Copy-Item "$HarnessSrc\commands\PITFALLS.md" "$ClaudeHome\commands\PITFALLS.md" -Force }
Write-Host "✅ Harness deployed"

# ─── External tools ───
Write-Host ""
Write-Host "🔧 Installing selected external tools..."
if ($ModCodex -eq "y")   { npm install -g "@openai/codex"; Write-Host "   ✓ codex" }
if ($ModCopilot -eq "y") { npm install -g copilot-api;     Write-Host "   ✓ copilot-api" }
if ($ModOllama -eq "y" -and -not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "   ⚠ Ollama not installed. Download: https://ollama.com/download"
}

# ─── MCP servers ───
Write-Host ""
Write-Host "🧩 Registering MCP servers..."
if ($McpPerplexity -eq "y") { claude mcp add perplexity -s user -- npx -y server-perplexity-ask 2>$null; Write-Host "   ✓ perplexity" }
if ($McpTavily -eq "y")     { claude mcp add tavily -s user -- node "$ClaudeHome\scripts\tavily-rotator.mjs" 2>$null; Write-Host "   ✓ tavily" }
if ($McpStitch -eq "y")     { claude mcp add stitch -s user -- npx -y "@_davideast/stitch-mcp" proxy 2>$null; Write-Host "   ✓ stitch" }

# ─── Done ───
Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🎉 Installation complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Add to your PowerShell profile (`$PROFILE):"
Write-Host "       Get-Content $EnvFile | ForEach-Object { if (`$_ -match '^([^=]+)=(.*)$') { [Environment]::SetEnvironmentVariable(`$Matches[1], `$Matches[2]) } }"
Write-Host "  2. Restart shell, then: claude"
Write-Host "  3. Verify: claude /audit"
Write-Host ""
Write-Host "  Persona:  $PersonaFile"
Write-Host "  Env keys: $EnvFile"
Write-Host ""
