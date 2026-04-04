# JamesClaw Agent — Setup Guide

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Node.js | 22+ | `winget install OpenJS.NodeJS.LTS` |
| Bun | 1.3+ | `npm install -g bun` |
| Git | 2.40+ | `winget install Git.Git` |
| Python 3 | 3.11+ | `winget install Python.Python.3.11` |
| Claude Code | latest | `npm install -g @anthropic-ai/claude-code` |
| Firebase CLI | 15+ | `npm install -g firebase-tools` |
| Playwright | latest | `npx playwright install chromium` |
| gcloud CLI | latest | https://cloud.google.com/sdk/docs/install |

---

## Step 1: Clone Repository

```bash
git clone https://github.com/<owner>/jamesclew.git D:/jamesclew
cd D:/jamesclew
```

---

## Step 2: Reset Existing Claude Config (Important!)

If the target machine already has Claude Code configured with different rules:

```bash
# Backup existing config (just in case)
mkdir -p ~/.claude/backups/pre-jamesclaw-$(date +%Y%m%d)
cp ~/.claude/CLAUDE.md ~/.claude/backups/pre-jamesclaw-$(date +%Y%m%d)/ 2>/dev/null
cp ~/.claude/settings.json ~/.claude/backups/pre-jamesclaw-$(date +%Y%m%d)/ 2>/dev/null
cp -r ~/.claude/rules/ ~/.claude/backups/pre-jamesclaw-$(date +%Y%m%d)/ 2>/dev/null
cp -r ~/.claude/hooks/ ~/.claude/backups/pre-jamesclaw-$(date +%Y%m%d)/ 2>/dev/null

# Remove all existing MCP servers
claude mcp list 2>/dev/null | grep -oP '^\S+' | while read name; do
  claude mcp remove "$name" 2>/dev/null
done

# Clear existing rules and hooks
rm -f ~/.claude/CLAUDE.md
rm -f ~/.claude/settings.json
rm -rf ~/.claude/rules/
rm -rf ~/.claude/hooks/
rm -rf ~/.claude/agents/
rm -rf ~/.claude/scripts/

echo "Reset complete."
```

---

## Step 3: Deploy Harness

```bash
cd D:/jamesclew
bash harness/deploy.sh
```

This copies all config files from `harness/` to `~/.claude/`:
- `CLAUDE.md` + `settings.json`
- `rules/` (quality, architecture, security)
- `hooks/` (9 shell/ts hooks)
- `scripts/` (tavily-rotator, persona-enhancer)
- `agents/` (code-reviewer, content-writer, researcher)

---

## Step 4: API Keys & Secrets

### 4a. Required Keys

Create these files with your API keys:

```bash
# Tavily API keys (rotation list)
cat > ~/.claude/tavily-keys.json << 'EOF'
["tvly-KEY1", "tvly-KEY2"]
EOF

# OpenRouter API keys (optional, for editor review fallback)
cat > ~/.claude/openrouter-keys.json << 'EOF'
["sk-or-KEY1", "sk-or-KEY2"]
EOF
```

### 4b. Telegram Notification

Edit `~/.claude/hooks/telegram-notify.sh` and set:
```bash
FALLBACK_TOKEN="your-telegram-bot-token"
FALLBACK_CHAT_ID="your-telegram-chat-id"
```

Or set environment variables:
```bash
export TELEGRAM_BOT_TOKEN="your-token"
export TELEGRAM_CHAT_ID="your-chat-id"
```

### 4c. Blog Pipeline .env

```bash
cp D:/jamesclew/pipelines/blog/.env.example D:/jamesclew/pipelines/blog/.env
# Then edit with actual values:
# FIREBASE_PROJECT_ID=smartreview-kr
# SITE_NAME=스마트리뷰
# SITE_URL=https://smartreview-kr.web.app
# ANTHROPIC_API_KEY=sk-ant-...
# PERPLEXITY_API_KEY=pplx-...
# TAVILY_API_KEY=tvly-...
```

---

## Step 5: MCP Servers

```bash
# Perplexity (always-on)
claude mcp add perplexity -s user -- node $(npm root -g)/@perplexity-ai/mcp-server/dist/index.js

# Tavily (always-on, with key rotation)
claude mcp add tavily -s user -- node ~/.claude/tavily-rotator.mjs

# Stitch (on-demand only, add when doing design work)
# claude mcp add stitch -s user -- npx @_davideast/stitch-mcp proxy
```

---

## Step 6: Plugins

```bash
# Telegram integration
claude plugin install telegram@claude-plugins-official

# Statusline
claude plugin install awesome-statusline@awesome-claude-plugins
```

---

## Step 7: Firebase Auth

```bash
firebase login
gcloud auth login
gcloud auth application-default login
gcloud config set project smartreview-kr
```

---

## Step 8: Obsidian Vault (Optional)

If using Obsidian for persona/knowledge management:

```
C:/Users/<USER>/Obsidian-Vault/
  01-jamesclaw/
    harness/         <- harness design docs, session summaries
    research/        <- tool selection, research results
  02-projects/       <- project-specific docs
  03-knowledge/
    personas/        <- editor/writer persona definitions
```

---

## Step 9: Verify Installation

```bash
# 1. Check Claude Code loads harness
claude --version

# 2. Check MCP servers
claude mcp list

# 3. Check hooks deployed
ls ~/.claude/hooks/

# 4. Test Telegram notification
bash ~/.claude/hooks/telegram-notify.sh heartbeat "Setup test from new machine"

# 5. Test blog build
cd D:/jamesclew/pipelines/blog
node -e "import('./src/ssg.mjs').then(m => m.buildSite([])).then(() => console.log('OK'))"
```

---

## File Structure Reference

```
D:/jamesclew/                          <- Source of truth
  harness/
    CLAUDE.md                          <- Agent identity & rules
    settings.json                      <- Permissions, hooks, plugins
    deploy.sh                          <- One-command deploy to ~/.claude/
    rules/
      architecture.md                  <- Tool selection, hosting policy
      quality.md                       <- Verification, deploy checks
      security.md                      <- Secret protection, deny list
    hooks/
      session-start.ts                 <- Core rules injection (SessionStart)
      user-prompt.ts                   <- Memory + rule reminder (UserPromptSubmit)
      telegram-notify.sh               <- Telegram alerts
      quality-gate.sh                  <- Pre-commit test enforcement
      loop-detector.sh                 <- Repetitive call detection
      irreversible-alert.sh            <- git push/rm -rf alerts
      verify-deploy.sh                 <- Post-deploy HTTP 200 check
      verify-memory-write.sh           <- Protected file guard
      verify-subagent.sh               <- Subagent output validation
    scripts/
      tavily-rotator.mjs               <- API key rotation
      enhance-personas.mjs             <- Persona enhancement
    agents/
      code-reviewer.md                 <- Code review subagent
      content-writer.md                <- Content creation subagent
      researcher.md                    <- Web research subagent
    keys/
      openrouter-keys.example.json     <- Template (no secrets)
      tavily-keys.example.json         <- Template (no secrets)
  pipelines/
    blog/
      src/                             <- SSG pipeline source
      .env                             <- Environment variables (gitignored)
      .firebaserc                      <- Firebase project config

~/.claude/                             <- Deployed config (generated by deploy.sh)
  CLAUDE.md, settings.json, hooks/, rules/, scripts/, agents/
  openrouter-keys.json                 <- Live API keys (not in repo)
  tavily-keys.json                     <- Live API keys (not in repo)
  projects/d--jamesclew/memory/        <- Auto-memory (session persistent)
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Hooks not running | `chmod +x ~/.claude/hooks/*.sh` |
| Bun hooks fail | `bun --version` must be 1.3+. `npm install -g bun` |
| Telegram not sending | Check FALLBACK_TOKEN/CHAT_ID in telegram-notify.sh |
| MCP tools not loading | Reload window after `claude mcp add` |
| PostCompact hook error | hookSpecificOutput not supported for PostCompact |
| Permission denied | Run `bash harness/deploy.sh` again |
| .env not loading | Must run pipeline from `pipelines/blog/` directory |

---

## Golden Rule

**Never edit `~/.claude/` directly.**
Always edit in `D:/jamesclew/harness/` then run `bash harness/deploy.sh`.
