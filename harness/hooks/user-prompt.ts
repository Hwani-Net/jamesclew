#!/usr/bin/env bun
// ============================================================================
// USER PROMPT HOOK - Inject relevant memories + rule reminder
// Hook: UserPromptSubmit
//
// 1. Memory server에서 관련 기억 검색 + 주입
// 2. 매 10턴마다 핵심 규칙 리마인더 주입
// ============================================================================

const MEMORY_API_URL = process.env.MEMORY_API_URL || 'http://localhost:8765'
const TIMEOUT_MS = 5000
const STATE_DIR = `${process.env.HOME || process.env.USERPROFILE}/.claude/hooks/state`
const TURN_COUNTER_FILE = `${STATE_DIR}/turn_counter`

// Short reminder (low token cost, injected every 10 turns)
const RULE_REMINDER = `[RULE REMINDER] 선언-미실행 금지. 불확실하면 ⚠️. 추측 금지.`

function getProjectId(cwd: string): string {
  return cwd.split('/').pop() || 'default'
}

async function httpPost(url: string, data: object): Promise<any> {
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    })
    return response.ok ? response.json() : {}
  } catch {
    return {}
  }
}

function getTurnCount(): number {
  try {
    const fs = require('fs')
    if (fs.existsSync(TURN_COUNTER_FILE)) {
      return parseInt(fs.readFileSync(TURN_COUNTER_FILE, 'utf8').trim()) || 0
    }
  } catch {}
  return 0
}

function setTurnCount(n: number): void {
  try {
    const fs = require('fs')
    fs.mkdirSync(STATE_DIR, { recursive: true })
    fs.writeFileSync(TURN_COUNTER_FILE, String(n))
  } catch {}
}

async function main() {
  if (process.env.MEMORY_CURATOR_ACTIVE === '1') return

  try {
    const inputText = await Bun.stdin.text()
    const input = JSON.parse(inputText)

    const sessionId = input.session_id || 'unknown'
    const prompt = input.prompt || ''
    const cwd = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd()
    const projectId = getProjectId(cwd)

    // Increment turn counter
    const turnCount = getTurnCount() + 1
    setTurnCount(turnCount)

    // Query memory system for context
    const result = await httpPost(`${MEMORY_API_URL}/memory/context`, {
      session_id: sessionId,
      project_id: projectId,
      current_message: prompt,
      max_memories: 5,
    })

    // Track message
    await httpPost(`${MEMORY_API_URL}/memory/process`, {
      session_id: sessionId,
      project_id: projectId,
    })

    // Build output
    const parts: string[] = []

    // Memory context
    const context = result.context_text || ''
    if (context) parts.push(context)

    // Rule reminder every 10 turns
    if (turnCount % 10 === 0) {
      parts.push(RULE_REMINDER)
    }

    if (parts.length > 0) {
      // Output as UserPromptSubmit additionalContext
      const output = {
        hookSpecificOutput: {
          hookEventName: "UserPromptSubmit",
          additionalContext: parts.join('\n')
        }
      }
      console.log(JSON.stringify(output))
    }

  } catch {
    // Never crash
  }
}

main()
