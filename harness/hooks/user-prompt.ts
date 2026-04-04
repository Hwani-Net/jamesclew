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

    // Detect negative feedback patterns (Self-Evolving Loop: feedback → auto-record)
    const feedbackPatterns = [
      /왜.*안\s*해|또.*그러|몇\s*번|지적.*했/,       // "왜 안 해?", "또 그러네", "몇번이나"
      /검증.*안|확인.*안|팩트.*체크/,                  // "검증 안 하고", "팩트체크 안 하고"
      /말만.*하고|선언.*미실행|실행.*안/,              // "말만 하고", "실행 안 하고"
      /검수.*안|검토.*안|건너뛰/,                      // "검수 안 해?", "건너뛰고"
      /못.*믿|신뢰.*없|거짓/,                          // "못 믿겠", "신뢰 없"
    ]

    const isFeedback = feedbackPatterns.some(p => p.test(prompt))
    if (isFeedback) {
      // Log feedback to state file for later analysis
      const fs = require('fs')
      const feedbackLog = `${STATE_DIR}/feedback_log.jsonl`
      const entry = JSON.stringify({
        ts: new Date().toISOString(),
        prompt: prompt.substring(0, 200),
        turn: turnCount,
      })
      try {
        fs.appendFileSync(feedbackLog, entry + '\n')
      } catch {}
    }

    // Build output
    const parts: string[] = []

    // Memory context
    const context = result.context_text || ''
    if (context) parts.push(context)

    // If feedback detected, inject stronger reminder
    if (isFeedback) {
      parts.push('[⚠️ FEEDBACK DETECTED] 대표님이 문제를 지적했습니다. 추측하지 말고 검증하세요. 선언만 하지 말고 즉시 실행하세요. 안 된다고 단정하기 전에 웹 검색으로 확인하세요.')
    }

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
