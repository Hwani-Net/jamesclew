#!/bin/bash
# progressive-summarize.sh — PostToolUse hook
# BASB Progressive Summarization: 06-raw/ / 05-wiki/sources/ 파일에 3줄 요약(summary:) 자동 주입
# Trigger: mcp__perplexity__* | mcp__tavily__* | Write(raw 경로 대상)
# Order: wiki-raw-save.sh 이후 실행

LOG="$HOME/.harness-state/progressive-summarize.log"
mkdir -p "$HOME/.harness-state"

INPUT=$(cat 2>/dev/null)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

VAULT="${OBSIDIAN_VAULT:-C:/Users/AIcreator/Obsidian-Vault}"

# --- Determine target file ---
TARGET_FILE=""

case "$TOOL_NAME" in
  mcp__perplexity__*|mcp__tavily__*)
    # Search known raw dirs for most recently modified .md (within 60s)
    TARGET_FILE=$(python3 -c "
import os, time, glob

vault = r'$VAULT'
search_dirs = [
    vault + '/06-raw',
    vault + '/05-wiki/sources',
]

now = time.time()
best = None
best_mtime = 0

for d in search_dirs:
    if not os.path.isdir(d):
        continue
    for f in glob.glob(d + '/*.md'):
        mt = os.path.getmtime(f)
        if now - mt <= 60 and mt > best_mtime:
            best_mtime = mt
            best = f

# Fallback: newest .md regardless of time
if not best:
    for d in search_dirs:
        if not os.path.isdir(d):
            continue
        files = [(os.path.getmtime(f), f) for f in glob.glob(d + '/*.md')]
        if files:
            files.sort(reverse=True)
            if files[0][0] > best_mtime:
                best_mtime = files[0][0]
                best = files[0][1]

if best:
    print(best)
" 2>/dev/null)
    ;;
  Write)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    if echo "$FILE_PATH" | grep -qE "(06-raw|05-wiki.sources)/"; then
      TARGET_FILE="$FILE_PATH"
    fi
    ;;
esac

[ -z "$TARGET_FILE" ] && exit 0
[ ! -f "$TARGET_FILE" ] && exit 0

# --- Delegate everything to Python to avoid encoding issues ---
python3 - "$TARGET_FILE" "$LOG" <<'PYEOF'
import sys, os, json, re, time, traceback

# Windows stdout encoding fix
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
sys.stderr.reconfigure(encoding='utf-8', errors='replace')

target = sys.argv[1]
log_path = sys.argv[2]

def log(msg):
    with open(log_path, 'a', encoding='utf-8') as f:
        f.write(f"[progressive-summarize] {msg}\n")

# Skip if summary already exists
try:
    with open(target, 'r', encoding='utf-8') as f:
        content = f.read()
except Exception as e:
    log(f"read error: {e}")
    sys.exit(0)

if 'summary:' in content:
    log(f"skip (already has summary): {os.path.basename(target)}")
    sys.exit(0)

# Extract body (skip frontmatter)
fm_pattern = re.compile(r'^---\n.*?---\n', re.DOTALL)
# Try frontmatter strip; if no frontmatter, use full content as body
if fm_pattern.match(content):
    body = fm_pattern.sub('', content).strip()
else:
    body = content.strip()

body = body[:3000]
prompt = (
    "다음 문서를 한국어 3줄로 요약하라. "
    "1줄=핵심 주장, 2줄=근거/데이터, 3줄=나에게 의미. "
    "3줄 외 다른 출력 금지:\n\n" + body
)

summary = None
model_used = None

# --- Attempt 1: copilot-api (GPT-4.1) ---
try:
    import urllib.request
    payload = json.dumps({
        "model": "gpt-4.1",
        "messages": [{"role": "user", "content": prompt}]
    }).encode('utf-8')
    req = urllib.request.Request(
        'http://localhost:4141/v1/chat/completions',
        data=payload,
        headers={'Content-Type': 'application/json'},
        method='POST'
    )
    with urllib.request.urlopen(req, timeout=20) as r:
        resp = json.loads(r.read().decode('utf-8'))
        candidate = resp.get('choices', [{}])[0].get('message', {}).get('content', '')
        if candidate.strip():
            summary = candidate.strip()
            model_used = 'gpt-4.1'
except Exception as e:
    log(f"gpt-4.1 failed: {e}")

# --- Attempt 2: Ollama gemma4:e4b ---
if not summary:
    try:
        payload2 = json.dumps({
            "model": "gemma4:e4b",
            "prompt": prompt,
            "stream": False
        }).encode('utf-8')
        req2 = urllib.request.Request(
            'http://localhost:11434/api/generate',
            data=payload2,
            headers={'Content-Type': 'application/json'},
            method='POST'
        )
        with urllib.request.urlopen(req2, timeout=60) as r2:
            resp2 = json.loads(r2.read().decode('utf-8'))
            candidate2 = resp2.get('response', '').strip()
            if candidate2:
                summary = candidate2
                model_used = 'gemma4:e4b'
    except Exception as e:
        log(f"ollama gemma4 failed: {e}")

if not summary:
    log(f"both models failed, skip: {os.path.basename(target)}")
    sys.exit(0)

# Collapse to pipe-separated single line, sanitize quotes
summary_line = summary.replace('\n', ' | ').replace('"', "'").strip()
# Limit length
if len(summary_line) > 500:
    summary_line = summary_line[:497] + '...'

# Inject summary: prepend a frontmatter block if none exists
fm_match = re.match(r'^(---\n)(.*?)(---\n)', content, re.DOTALL)
if fm_match:
    fm_body = fm_match.group(2)
    if 'summary:' in fm_body:
        log(f"skip duplicate inject: {os.path.basename(target)}")
        sys.exit(0)
    new_fm_body = fm_body.rstrip('\n') + f'\nsummary: "{summary_line}"\n'
    new_content = fm_match.group(1) + new_fm_body + fm_match.group(3) + content[fm_match.end():]
else:
    # No frontmatter — prepend minimal block
    if 'summary:' in content[:200]:
        log(f"skip duplicate inject (no-fm): {os.path.basename(target)}")
        sys.exit(0)
    new_content = f'---\nsummary: "{summary_line}"\n---\n\n' + content

with open(target, 'w', encoding='utf-8') as f:
    f.write(new_content)

log(f"success model={model_used} chars={len(summary_line)} file={os.path.basename(target)}")
PYEOF

exit 0
