# JamesClaw Agent — Quick Install

## 1. Prerequisites

```bash
winget install OpenJS.NodeJS.LTS && winget install Python.Python.3.11 && winget install Git.Git && npm install -g bun @anthropic-ai/claude-code firebase-tools @perplexity-ai/mcp-server && npx playwright install chromium
```

## 2. Reset + Install

```bash
git clone https://github.com/Hwani-Net/jamesclew.git D:/jamesclew && cd D:/jamesclew && bash harness/scripts/reset-and-install.sh
```

## 3. API Keys (edit values after paste)

```bash
echo '["tvly-YOUR-KEY"]' > ~/.claude/tavily-keys.json
```

```bash
echo '["sk-or-YOUR-KEY"]' > ~/.claude/openrouter-keys.json
```

```bash
cp D:/jamesclew/pipelines/blog/.env.example D:/jamesclew/pipelines/blog/.env && nano D:/jamesclew/pipelines/blog/.env
```

> Telegram: `nano ~/.claude/hooks/telegram-notify.sh` — set `FALLBACK_TOKEN` and `FALLBACK_CHAT_ID`

## 4. Auth + Plugins

```bash
firebase login && gcloud auth login && gcloud auth application-default login
```

```bash
claude plugin install telegram@claude-plugins-official && claude plugin install awesome-statusline@awesome-claude-plugins
```

## 5. Verify

```bash
claude mcp list && ls ~/.claude/hooks/ && bash ~/.claude/hooks/telegram-notify.sh heartbeat "Install complete"
```
