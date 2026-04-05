#!/usr/bin/env bun
// ============================================================================
// SESSION START HOOK - Inject session primer + core rules
// Hook: SessionStart (startup|resume)
//
// 1. Memory server에서 과거 맥락 검색 + 주입
// 2. CLAUDE.md 핵심 규칙을 면책 조항 없이 직접 주입
// ============================================================================

const MEMORY_API_URL = process.env.MEMORY_API_URL || 'http://localhost:8765'
const TIMEOUT_MS = 5000

// Core rules injected WITHOUT "may or may not be relevant" disclaimer
const CORE_RULES = `[CORE RULES - ALWAYS ACTIVE]
1. 즉시실행. "할까요?" 금지. 선언했으면 같은 응답에서 도구 호출까지 완료.
2. "안 됩니다" 금지 — 웹 검색 + 3회 시도 + 대안 2개 후에만 불가 판정.
3. Evidence-First — 증거(도구 출력) 없이 상태 보고 금지. 추측 금지.
4. Search-Before-Solve — 막히면 LESSONS_LEARNED, 옵시디언, 이전 세션에서 먼저 검색.
5. 완성형까지 반복 — Multi-Pass Review 최소 2라운드. 검수는 외부 모델(Antigravity + Codex) 위임.
6. Built-in > Bash > MCP (비용순). 하네스는 D:/jamesclew/harness/ → deploy.sh.
7. 컨텍스트 20%마다 외부 모델 검수 + Self-Evolving Loop 자동 트리거.`

const STATE_DIR = `${process.env.HOME || process.env.USERPROFILE}/.claude/hooks/state`

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

async function main() {
  if (process.env.MEMORY_CURATOR_ACTIVE === '1') return

  try {
    const inputText = await new Promise<string>((resolve) => { let data = ''; process.stdin.on('data', (chunk: Buffer) => { data += chunk.toString() }); process.stdin.on('end', () => resolve(data)) })
    const input = JSON.parse(inputText)

    const sessionId = input.session_id || 'unknown'
    const cwd = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd()
    const projectId = getProjectId(cwd)

    // Get session primer from memory system
    const result = await httpPost(`${MEMORY_API_URL}/memory/context`, {
      session_id: sessionId,
      project_id: projectId,
      current_message: '',
      max_memories: 0,
    })

    // Register session
    await httpPost(`${MEMORY_API_URL}/memory/process`, {
      session_id: sessionId,
      project_id: projectId,
      metadata: { event: 'session_start' },
    })

    // Load evolution history for session start warning
    let evolveWarning = ''
    try {
      const fs = require('fs')
      const feedbackLog = `${STATE_DIR}/feedback_log.jsonl`
      if (fs.existsSync(feedbackLog)) {
        const lines = fs.readFileSync(feedbackLog, 'utf8').trim().split('\n')
        const count = lines.length
        if (count > 0) {
          // Count patterns
          const patterns: Record<string, number> = {}
          for (const line of lines) {
            try {
              const entry = JSON.parse(line)
              const p = entry.prompt || ''
              if (/말만|선언|실행.*안/.test(p)) patterns['declare_no_execute'] = (patterns['declare_no_execute'] || 0) + 1
              if (/검증|팩트|못.*한다/.test(p)) patterns['premature_conclusion'] = (patterns['premature_conclusion'] || 0) + 1
              if (/검수|검토|건너뛰/.test(p)) patterns['skip_review'] = (patterns['skip_review'] || 0) + 1
            } catch {}
          }
          const top = Object.entries(patterns).sort((a, b) => b[1] - a[1]).slice(0, 3)
          if (top.length > 0) {
            evolveWarning = `[⚠️ EVOLUTION WARNING] 이전 세션 피드백 ${count}건. 반복 패턴: ${top.map(([k, v]) => `${k}(${v}회)`).join(', ')}. 이 패턴을 이번 세션에서 반복하지 마세요.`
          }
        }
      }
      // Reset context milestone for new session
      const milestoneFile = `${STATE_DIR}/context_milestone`
      fs.writeFileSync(milestoneFile, '0')
    } catch {}

    // Output: core rules + evolution warning + primer
    const primer = result.context_text || ''
    const output = [CORE_RULES]
    if (evolveWarning) output.push(evolveWarning)
    if (primer) output.push(primer)

    console.log(output.join('\n\n'))

  } catch {
    // Still inject core rules even if memory server is down
    console.log(CORE_RULES)
  }
}

main()
