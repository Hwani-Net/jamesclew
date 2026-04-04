# JamesClaw Agent — Quick Install

## 1. Prerequisites

```bash
winget install OpenJS.NodeJS.LTS
```

```bash
npm install -g bun
```

```bash
winget install Python.Python.3.11
```

```bash
winget install Git.Git
```

```bash
npm install -g @anthropic-ai/claude-code
```

```bash
npm install -g firebase-tools
```

```bash
npm install -g @perplexity-ai/mcp-server
```

```bash
npx playwright install chromium
```

---

## 2. Reset (Clear existing config)

```bash
mkdir -p ~/.claude/backups/pre-jamesclaw-$(date +%Y%m%d)
```

```bash
cp ~/.claude/CLAUDE.md ~/.claude/backups/pre-jamesclaw-$(date +%Y%m%d)/ 2>/dev/null; cp ~/.claude/settings.json ~/.claude/backups/pre-jamesclaw-$(date +%Y%m%d)/ 2>/dev/null; cp -r ~/.claude/rules/ ~/.claude/backups/pre-jamesclaw-$(date +%Y%m%d)/ 2>/dev/null; cp -r ~/.claude/hooks/ ~/.claude/backups/pre-jamesclaw-$(date +%Y%m%d)/ 2>/dev/null
```

```bash
rm -f ~/.claude/CLAUDE.md ~/.claude/settings.json
```

```bash
rm -rf ~/.claude/rules/ ~/.claude/hooks/ ~/.claude/agents/ ~/.claude/scripts/
```

```bash
claude mcp list 2>/dev/null | grep -oP '^\S+' | while read name; do claude mcp remove "$name" 2>/dev/null; done
```

---

## 3. Install

```bash
git clone https://github.com/Hwani-Net/jamesclew.git D:/jamesclew
```

```bash
cd D:/jamesclew && bash harness/scripts/reset-and-install.sh
```

---

## 4. API Keys

### Tavily

```bash
cat > ~/.claude/tavily-keys.json << 'EOF'
["tvly-YOUR-KEY-1", "tvly-YOUR-KEY-2"]
EOF
```

### OpenRouter (optional)

```bash
cat > ~/.claude/openrouter-keys.json << 'EOF'
["sk-or-YOUR-KEY"]
EOF
```

### Telegram

```bash
nano ~/.claude/hooks/telegram-notify.sh
```

> `FALLBACK_TOKEN` and `FALLBACK_CHAT_ID` values need to be set.

### Blog Pipeline

```bash
cp D:/jamesclew/pipelines/blog/.env.example D:/jamesclew/pipelines/blog/.env
```

```bash
nano D:/jamesclew/pipelines/blog/.env
```

---

## 5. Auth & Plugins

```bash
firebase login
```

```bash
gcloud auth login
```

```bash
gcloud auth application-default login
```

```bash
claude plugin install telegram@claude-plugins-official
```

```bash
claude plugin install awesome-statusline@awesome-claude-plugins
```

---

## 6. Verify

```bash
claude mcp list
```

```bash
ls ~/.claude/hooks/
```

```bash
bash ~/.claude/hooks/telegram-notify.sh heartbeat "Install complete"
```
