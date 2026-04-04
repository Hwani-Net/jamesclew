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
2. Built-in > Bash > MCP (비용순)
3. 에러 3회 재시도 후 보고
4. 불확실한 항목 ⚠️ 표시, 추측을 사실처럼 전달 금지
5. 완성형까지 반복 — 검증 NO면 수정 후 재검토
6. TodoWrite로 진행상황 추적
7. 하네스 파일은 D:/jamesclew/harness/에서 편집 → deploy.sh 배포`

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
    const inputText = await Bun.stdin.text()
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

    // Output: core rules + primer
    const primer = result.context_text || ''
    const output = [CORE_RULES]
    if (primer) output.push(primer)

    console.log(output.join('\n\n'))

  } catch {
    // Still inject core rules even if memory server is down
    console.log(CORE_RULES)
  }
}

main()
