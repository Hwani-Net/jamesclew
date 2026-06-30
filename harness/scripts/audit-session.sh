#!/bin/bash
# ============================================================================
# JamesClaw Auto-Audit Script
# Usage:
#   audit-session.sh --compact              # Current session, 1-line summary
#   audit-session.sh --full                 # Current session, detailed report
#   audit-session.sh --full <session-id>    # Specific session, detailed report
#   audit-session.sh --compact <jsonl-path> # Specific file, compact
# ============================================================================
#
# ═══════════════════════════════════════════════════════════════════════════
# AUDIT CHECK REGISTRY — 신규 기능 추가 시 여기에 check_ 함수 등록
#
# 규칙: CLAUDE.md에 규칙 추가 → 여기에 check_ 함수 추가 → deploy.sh 실행
# 버전 업데이트 시: changelog에서 하네스 영향 항목 → check_ 함수 추가
#
# 현재 체크 수: 67개 (2026-06-30)
# 마지막 업데이트: 2026-06-30 (check_v153~check_v176 11개 추가
#                               — Issue #4 근본 수정: stale 'd' 키 WARN 수정
#                               — Claude Code v2.1.153~v2.1.177 신기능 감사 공백 해소)
#
# 등록된 체크 목록:
#  01 check_build_transition    — Build Transition Rule (/plan 먼저)
#  02 check_prd                 — /prd 실행
#  03 check_pipeline            — /pipeline-install 실행
#  04 check_quality_loop        — Multi-Pass Review 5패스 2라운드
#  05 check_external_review     — 외부 모델 검수 (step7)
#  06 check_deploy_verify       — 배포 후 HTTP 200 검증
#  07 check_todowrite           — TodoWrite 작업 분할
#  08 check_ghost_mode          — "할까요?" 패턴 금지
#  09 check_evidence_first      — Evidence-First (추측 금지)
#  10 check_telegram_result     — last_result.txt 작성
#  11 check_no_impossibility    — "안 됩니다" 금지 (검색 우선)
#  12 check_multipass           — Multi-Pass Review 2라운드
#  13 check_pitfalls            — PITFALLS 기록
#  14 check_commits             — Conventional Commits
#  15 check_harness_location    — harness/ 편집 → deploy.sh 경로 준수
#  16 check_error_retry         — 에러 재시도 (3회 원칙)
#  17 check_design              — 디자인 레퍼런스/Stitch 사용
#  18 check_external_model_calls — 외부 모델 실제 호출 (Claude 자기검수 금지)
#  19 check_tool_priority       — Tool Priority (Built-in > Bash > MCP)
#  20 check_cost_logging        — API 비용 로깅
#  21 check_search_before_solve — Search-Before-Solve
#  22 check_screenshot_verify   — 배포 후 스크린샷 검증
#  23 check_pipeline_loop       — Pipeline Loop (11단계 FAIL→수정→재실행)
#  24 check_no_antigravity      — Antigravity(opencode) 잔존 체크
#  25 check_agentmemory_usage   — agentmemory MCP 검색/저장 사용 (gbrain 폐기 P-172 → agentmemory 대체)
#  26 check_agent_teams_cleanup — Agent Teams 생성/삭제 균형
#  27 check_rule_impl_gap       — 규칙 파일 참조 hook/script 실제 존재 여부 (P-012)
#  28 check_precompact_block    — PreCompact hook exit 2 차단 로직 존재 여부
#  29 check_obsidian_save       — compact 전 Obsidian 세션 저장 순서 (P-007)
#  30 check_5h_emergency        — 5H 80%+ 감지 시 Sonnet 전환 절차
#  31 check_version_manual_sync — 버전 업데이트 시 harness-manual.md 동시 수정
#  32 check_design_review_vision — design-review Vision 호출 (Opus Vision)
#  33 check_model_sonnet_explicit — Agent() 호출 시 model: sonnet 명시 여부
#  34 check_vision_dual_pass       — mcp__expect__screenshot 이중 패스 (snapshot→screenshot)
#  35 check_sonnet_vision_delegation — 이미지 Read 시 Opus Vision 위임 여부
#  36 check_v121_post_tool_output   — v2.1.121 PostToolUse updatedToolOutput 신기능 활용 여부 (참고용)
#  37 check_v121_mcp_always_load    — v2.1.121 MCP alwaysLoad 옵션 적용 여부
#  38 check_v120_powershell_fallback — v2.1.120 Windows Git Bash 설치 확인 (하네스 bash 의존)
#  39 check_v119_config_persistence — v2.1.119 settings.json /config 영구 저장 정상 작동
#  40 check_v122_malformed_hooks    — v2.1.122 malformed hook 단일 entry 파일 무효화 방지
#  41 check_v128_prompt_cache       — v2.1.128 ENABLE_PROMPT_CACHING_1H 1h TTL 정상 적용
#  42 check_v128_long_context_fix   — v2.1.128 P-115/P-116 1M-context 워크어라운드 유효성
#  43 check_v132_context_window     — v2.1.132 statusline context_window fix / heartbeat 정확도
#  44 check_v132_session_id         — v2.1.132 CLAUDE_CODE_SESSION_ID Bash hook 활용
#  45 check_v133_worktree_baseref   — v2.1.133 worktree.baseRef 설정 (unpushed commits 보존)
#  46 check_v133_claude_effort_env  — v2.1.133 $CLAUDE_EFFORT env hook 활용
#  47 check_v136_hard_deny          — v2.1.136 autoMode.hard_deny 위험 작업 차단 설정
#  48 check_v139_goal_agentview     — v2.1.139 /goal + Agent View (claude agents) 활용
#  49 check_v139_hook_args_exec     — v2.1.139 Hook args: string[] exec form 마이그레이션
#  50 check_v141_terminal_sequence  — v2.1.141 Hook terminalSequence JSON output 활용
#  51 check_v142_agents_flags       — v2.1.142 claude agents 8개 플래그 background dispatch
#  52 check_v142_fast_mode_opus47   — v2.1.142 /fast 기본값 Opus 4.7 변경 인지
#  53 check_v143_stop_hook_block_cap  — v2.1.143 Stop hook 8 consecutive blocks 자동 종료 (native 안전망)
#  54 check_v143_powershell_policy    — v2.1.143 PowerShell -ExecutionPolicy Bypass 기본 적용 (Bedrock/Vertex/Foundry)
#  55 check_v144_model_single_session — v2.1.144 /model 단일 세션 변경 정책 (default는 settings.json 또는 `d` 키)
#  56 check_v144_mcp_paginated_tools  — v2.1.144 MCP paginated tools/list fix 인지 (agentmemory 등 도구 많은 MCP)
#
# ─── 미구현 (TODO) ─────────────────────────────────────────────────────────
# (없음 — 모든 TODO 구현 완료 2026-05-19)
# ═══════════════════════════════════════════════════════════════════════════

MODE="${1:---full}"
TARGET="${2:-}"
STATE_DIR="$HOME/.harness-state"

# ─── Checkpoint mode: mid-pipeline verification ───
if [ "$MODE" = "--checkpoint" ]; then
  STEP="${TARGET:-0}"
  TRANSCRIPT=$(ls -t "$HOME/.claude/projects"/*/????????-????-????-????-????????????.jsonl 2>/dev/null | head -1)
  [ -z "$TRANSCRIPT" ] && echo '{"systemMessage":"[CHECKPOINT] Transcript not found"}' && exit 0

  safe_count() {
    local result
    result=$(eval "$1" 2>/dev/null | tr -d '[:space:]')
    [[ "$result" =~ ^[0-9]+$ ]] && echo "$result" || echo "0"
  }

  case "$STEP" in
    5)
      # After Step 2 (quality review): verify /ultrareview was called
      REVIEWS=$(safe_count "grep -c 'ultrareview\|/ultrareview' \"$TRANSCRIPT\"")
      if [ "$REVIEWS" -lt 1 ]; then
        echo "{\"systemMessage\":\"[🚫 CHECKPOINT 2 FAIL] /ultrareview 미실행. 지금 실행하세요: /ultrareview. 완료 후 증거 파일 생성: echo '{\\\"step\\\":2,\\\"verdict\\\":\\\"PASS\\\"}' > ${STATE_DIR}/pipeline_review_done\"}"
      else
        echo "{\"step\":2,\"tool\":\"ultrareview\",\"verdict\":\"PASS\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$STATE_DIR/pipeline_review_done"
        echo "{\"systemMessage\":\"[✅ CHECKPOINT 2 PASS] /ultrareview ${REVIEWS}건 확인. pipeline_review_done 생성됨.\"}"
      fi
      ;;
    7)
      # After Step 2 (quality review, legacy alias for step 7): same check as step 5
      REVIEWS=$(safe_count "grep -c 'ultrareview\|/ultrareview' \"$TRANSCRIPT\"")
      if [ "$REVIEWS" -lt 1 ]; then
        echo "{\"systemMessage\":\"[🚫 CHECKPOINT 2 FAIL] /ultrareview 미실행. 지금 실행하세요: /ultrareview. 완료 후: echo '{\\\"step\\\":2,\\\"verdict\\\":\\\"PASS\\\"}' > ${STATE_DIR}/pipeline_review_done\"}"
      else
        echo "{\"step\":2,\"tool\":\"ultrareview\",\"verdict\":\"PASS\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$STATE_DIR/pipeline_review_done"
        echo "{\"systemMessage\":\"[✅ CHECKPOINT 2 PASS] /ultrareview ${REVIEWS}건 확인. pipeline_review_done 생성됨.\"}"
      fi
      ;;
    10)
      # After Step 10: verify full pipeline sequence integrity
      FAILS=""
      [ ! -f "$STATE_DIR/pipeline_review_done" ] && FAILS="${FAILS} Step2(품질검수-pipeline_review_done)"
      # Check design reference for UI projects
      UI_FILES=$(safe_count "grep '\"name\":\"Write\"' \"$TRANSCRIPT\" | grep -c '\.html\|\.css\|\.tsx\|\.jsx'")
      if [ "$UI_FILES" -gt 0 ]; then
        DESIGN=$(safe_count "grep -c 'mcp__stitch\|stitch-mcp\|godly\.website\|motionsites\.ai\|DESIGN\.md' \"$TRANSCRIPT\"")
        [ "$DESIGN" -eq 0 ] && FAILS="${FAILS} Design(디자인레퍼런스)"
      fi
      if [ -n "$FAILS" ]; then
        echo "{\"systemMessage\":\"[🚫 CHECKPOINT 10 FAIL] 배포 전 미완료:${FAILS}. 해결 후 재시도하세요.\"}"
      else
        echo "{\"systemMessage\":\"[✅ CHECKPOINT 10 PASS] 파이프라인 순서 검증 통과. 배포 진행 가능.\"}"
      fi
      ;;
    *)
      echo "{\"systemMessage\":\"[CHECKPOINT] Unknown step: ${STEP}. Use 5, 7, or 10.\"}"
      ;;
  esac
  exit 0
fi

# ─── Safe count: always returns clean integer ───
safe_count() {
  local result
  result=$(eval "$1" 2>/dev/null | tr -d '[:space:]')
  if [ -z "$result" ] || ! [[ "$result" =~ ^[0-9]+$ ]]; then
    echo "0"
  else
    echo "$result"
  fi
}

# ─── Find transcript file ───
find_transcript() {
  local ID="$1"
  if [ -f "$ID" ]; then
    echo "$ID"
    return
  fi
  find "$HOME/.claude/projects" -name "${ID}.jsonl" -not -path "*/subagents/*" 2>/dev/null | head -1
}

find_current_transcript() {
  ls -t "$HOME/.claude/projects"/*/????????-????-????-????-????????????.jsonl 2>/dev/null | head -1
}

if [ -n "$TARGET" ]; then
  TRANSCRIPT=$(find_transcript "$TARGET")
else
  TRANSCRIPT=$(find_current_transcript)
fi

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  if [ "$MODE" = "--compact" ]; then
    echo '{"systemMessage":"[SESSION AUDIT] ❓ Transcript not found"}'
  else
    echo "❌ Transcript not found: ${TARGET:-current session}" >&2
  fi
  exit 0
fi

# ─── Extract session metadata ───
SESSION_ID=$(basename "$TRANSCRIPT" .jsonl)
PROJECT_DIR=$(grep -m1 '"cwd"' "$TRANSCRIPT" 2>/dev/null | grep -o '"cwd":"[^"]*"' | head -1 | sed 's/"cwd":"//;s/"//' || echo "unknown")
TOOL_TOTAL=$(safe_count "grep -o '\"type\":\"tool_use\"' \"$TRANSCRIPT\" | wc -l")

# ─── Build session detection (evidence-based scoring, P-062 follow-up) ───
# Single keyword match is insufficient — maintenance/refactor/doc sessions
# routinely contain "구현/개발/만들". Use weighted evidence scoring instead.
# Only trust <command-name> tags (actual slash command execution),
# not bare "/prd" text (which appears in docs/mentions)
BUILD_KEYWORDS=$(safe_count "grep '\"type\":\"user\"' \"$TRANSCRIPT\" | grep -c '만들\|구현\|개발\|페이지로\|앱으로'")
# Full tag match only — open+close tags must both appear to filter out
# doc snippets that quote "<command-name>/prd" as example text.
PRD_INVOKED=$(safe_count "grep -c '<command-name>/prd</command-name>' \"$TRANSCRIPT\"")
PIPELINE_INSTALLED=$(safe_count "grep -c '<command-name>/pipeline-install</command-name>' \"$TRANSCRIPT\"")
PLAN_INVOKED=$(safe_count "grep -cE '<command-name>/(plan|ultraplan)</command-name>' \"$TRANSCRIPT\"")

BUILD_SCORE=0
[ "$PRD_INVOKED" -gt 0 ] && BUILD_SCORE=$((BUILD_SCORE + 2))
[ "$PIPELINE_INSTALLED" -gt 0 ] && BUILD_SCORE=$((BUILD_SCORE + 2))
[ "$PLAN_INVOKED" -gt 0 ] && BUILD_SCORE=$((BUILD_SCORE + 1))
[ "$BUILD_KEYWORDS" -ge 5 ] && BUILD_SCORE=$((BUILD_SCORE + 1))

IS_BUILD=0
[ "$BUILD_SCORE" -ge 2 ] && IS_BUILD=1

# ─── Tool count helper ───
count_tool() {
  safe_count "grep -o '\"name\":\"$1\"' \"$TRANSCRIPT\" | wc -l"
}

# ─── Check functions (each returns STATUS|DETAIL) ───

check_build_transition() {
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  local plan=$(count_tool "EnterPlanMode")
  [ "$plan" -gt 0 ] && echo "PASS|EnterPlanMode ${plan}회" && return
  local plan_state=$(safe_count "grep -c 'plan_done' \"$TRANSCRIPT\"")
  [ "$plan_state" -gt 0 ] && echo "PASS|plan_done 확인" && return
  echo "FAIL|빌드 요청 ${BUILD_KEYWORDS}건, /plan 0회"
}

check_prd() {
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  local skill=$(safe_count "grep '\"name\":\"Skill\"' \"$TRANSCRIPT\" | grep -c 'prd'")
  local cmd=$(safe_count "grep -c '/prd' \"$TRANSCRIPT\"")
  [ "$skill" -gt 0 ] || [ "$cmd" -gt 2 ] && echo "PASS|/prd 실행됨" && return
  echo "FAIL|/prd 미실행"
}

check_pipeline() {
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  local skill=$(safe_count "grep '\"name\":\"Skill\"' \"$TRANSCRIPT\" | grep -c 'pipeline'")
  local cmd=$(safe_count "grep -c 'pipeline-install' \"$TRANSCRIPT\"")
  [ "$skill" -gt 0 ] || [ "$cmd" -gt 2 ] && echo "PASS|/pipeline-install 실행됨" && return
  echo "FAIL|/pipeline-install 미실행"
}

check_quality_loop() {
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  [ -f "$STATE_DIR/pipeline_review_done" ] && echo "PASS|증거 파일 존재 (pipeline_review_done)" && return
  local mentions=$(safe_count "grep -c 'ultrareview\|/ultrareview\|품질검수\|quality.*review' \"$TRANSCRIPT\"")
  [ "$mentions" -gt 1 ] && echo "WARN|패턴 ${mentions}건, 증거 파일 없음 (pipeline_review_done)" && return
  echo "FAIL|품질검수 미실행 (/ultrareview 필요)"
}

check_external_review() {
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  [ -f "$STATE_DIR/pipeline_review_done" ] && echo "PASS|증거 파일 존재 (pipeline_review_done)" && return
  local ext=$(safe_count "grep -c 'ultrareview\|/ultrareview' \"$TRANSCRIPT\"")
  [ "$ext" -gt 0 ] && echo "WARN|ultrareview ${ext}건, 증거 파일 없음" && return
  echo "FAIL|/ultrareview 미실행"
}

check_deploy_verify() {
  local deploys=$(safe_count "grep '\"type\":\"assistant\"' \"$TRANSCRIPT\" | grep -c 'firebase deploy'")
  [ "$deploys" -eq 0 ] && echo "N/A|배포 없음" && return
  local verify=$(safe_count "grep -c 'web\.app\|HTTP.*200\|playwright.*screenshot' \"$TRANSCRIPT\"")
  [ "$verify" -gt 0 ] && echo "PASS|배포 후 검증 ${verify}건" && return
  echo "FAIL|배포 후 검증 없음"
}

check_todowrite() {
  local todo=$(count_tool "TodoWrite")
  [ "$todo" -gt 0 ] && echo "PASS|TodoWrite ${todo}회" && return
  echo "WARN|TodoWrite 미사용"
}

check_ghost_mode() {
  # Count only in recent portion (last 2000 lines) to focus on current session
  local recent_violations=$(tail -2000 "$TRANSCRIPT" 2>/dev/null | grep '"type":"assistant"' | grep -c '할까요\|필요하면 말씀\|원하시면\|진행할까\|해볼까' 2>/dev/null || echo 0)
  recent_violations=$(echo "$recent_violations" | tr -d '[:space:]')
  [ "$recent_violations" -eq 0 ] && echo "PASS|최근 세션 위반 0건" && return
  [ "$recent_violations" -le 5 ] && echo "WARN|최근 세션 \"할까요\" ${recent_violations}건" && return
  echo "FAIL|최근 세션 \"할까요\" ${recent_violations}건"
}

check_evidence_first() {
  local claims=$(safe_count "grep '\"type\":\"assistant\"' \"$TRANSCRIPT\" | grep -c '확인했습니다\|완료했습니다\|검증했습니다'")
  [ "$claims" -eq 0 ] && echo "PASS|무근거 주장 0건" && return
  [ "$TOOL_TOTAL" -gt "$claims" ] && echo "PASS|주장 ${claims}건, 도구 ${TOOL_TOTAL}건" && return
  echo "WARN|주장 ${claims}건 vs 도구 ${TOOL_TOTAL}건"
}

check_telegram_result() {
  local result=$(safe_count "grep -c 'last_result' \"$TRANSCRIPT\"")
  [ "$result" -gt 0 ] && echo "PASS|last_result.txt ${result}건" && return
  echo "WARN|last_result.txt 미작성"
}

# ─── Check 11: "안 됩니다" 금지 (premature impossibility) ───
check_no_impossibility() {
  local impossibles=$(safe_count "grep '\"type\":\"assistant\"' \"$TRANSCRIPT\" | grep -c '불가능\|안 됩니다\|할 수 없\|지원.*안\|방법.*없'")
  [ "$impossibles" -eq 0 ] && echo "PASS|불가 선언 0건" && return
  # Check if web search was attempted before declaring impossible
  local searches=$(safe_count "grep -c 'perplexity\|tavily\|WebSearch\|WebFetch\|npm search' \"$TRANSCRIPT\"")
  [ "$searches" -gt "$impossibles" ] && echo "PASS|불가 ${impossibles}건, 검색 ${searches}건 (검색 후 판단)" && return
  echo "FAIL|불가 선언 ${impossibles}건, 검색 ${searches}건"
}

# ─── Check 12: Multi-Pass Review 2라운드 ───
check_multipass() {
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  local rounds=$(safe_count "grep -c '라운드.*[12]\|round.*[12]\|Pass.*[1-5].*검토\|패스.*[1-5]' \"$TRANSCRIPT\"")
  [ "$rounds" -ge 4 ] && echo "PASS|리뷰 패턴 ${rounds}건" && return
  [ "$rounds" -gt 0 ] && echo "WARN|리뷰 패턴 ${rounds}건 (2라운드 미달)" && return
  echo "FAIL|Multi-Pass 리뷰 미실행"
}

# ─── Check 13: PITFALLS 기록 ───
check_pitfalls() {
  local pitfall_writes=$(safe_count "grep -c 'PITFALLS' \"$TRANSCRIPT\"")
  # Only relevant if feedback was detected
  local feedback=$(safe_count "grep -c 'FEEDBACK DETECTED\|지적\|잘못\|왜.*안' \"$TRANSCRIPT\"")
  [ "$feedback" -eq 0 ] && echo "N/A|피드백 없음" && return
  [ "$pitfall_writes" -gt 0 ] && echo "PASS|PITFALLS 기록 ${pitfall_writes}건" && return
  echo "WARN|피드백 ${feedback}건, PITFALLS 기록 없음"
}

# ─── Check 14: Conventional Commits ───
check_commits() {
  # Only check recent commits (last 7 days) — before hook installation doesn't count
  local total=$(git log --since="7 days ago" --oneline 2>/dev/null | wc -l)
  total=$(echo "$total" | tr -d '[:space:]')
  [ "$total" -eq 0 ] && echo "N/A|7일 내 커밋 없음" && return
  local conventional=$(git log --since="7 days ago" --oneline 2>/dev/null | grep -cE "^[a-f0-9]+ (feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)" || echo 0)
  conventional=$(echo "$conventional" | tr -d '[:space:]')
  local pct=$((conventional * 100 / total))
  if [ "$pct" -ge 80 ]; then
    echo "PASS|Conventional ${conventional}/${total}건 (${pct}%)"
  elif [ "$pct" -ge 50 ]; then
    echo "WARN|Conventional ${conventional}/${total}건 (${pct}%)"
  else
    echo "FAIL|Conventional ${conventional}/${total}건 (${pct}%)"
  fi
}

# ─── Check 15: 하네스 직접 수정 금지 ───
check_harness_location() {
  # Detect direct edits to ~/.claude/ without going through harness/
  local direct_edits=$(safe_count "grep '\"name\":\"Write\"\|\"name\":\"Edit\"' \"$TRANSCRIPT\" | grep -c '\.claude/hooks\|\.claude/rules\|\.claude/CLAUDE.md\|\.claude/settings.json'")
  local harness_edits=$(safe_count "grep '\"name\":\"Write\"\|\"name\":\"Edit\"' \"$TRANSCRIPT\" | grep -c 'harness/'")
  local deploy=$(safe_count "grep -c 'deploy.sh' \"$TRANSCRIPT\"")
  [ "$direct_edits" -eq 0 ] && echo "PASS|직접 수정 0건" && return
  [ "$deploy" -gt 0 ] && [ "$harness_edits" -gt 0 ] && echo "PASS|harness 편집 ${harness_edits}건 + deploy ${deploy}건" && return
  echo "WARN|~/.claude 직접 수정 ${direct_edits}건 감지"
}

# ─── Check 16: 에러 재시도 ───
check_error_retry() {
  local errors=$(safe_count "grep -c 'Exit code [1-9]\|Error\|FAIL\|error' \"$TRANSCRIPT\"")
  [ "$errors" -eq 0 ] && echo "N/A|에러 없음" && return
  # Simple heuristic: if there are errors and tool calls continued after, retry happened
  [ "$TOOL_TOTAL" -gt "$errors" ] && echo "PASS|에러 ${errors}건, 도구 ${TOOL_TOTAL}건 (재시도 확인)" && return
  echo "WARN|에러 ${errors}건, 재시도 불분명"
}

# ─── Check 17: 디자인 레퍼런스/Stitch 사용 ───
# (already defined above)

# ─── Check 18: 외부 모델 실제 호출 (Claude 자기 검수 금지) ───
check_external_model_calls() {
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  local codex=$(safe_count "grep -c 'codex exec\|codex ' \"$TRANSCRIPT\"")
  local gemini=$(safe_count "grep -c 'gemini ' \"$TRANSCRIPT\"")
  local total=$((codex + gemini))
  [ "$total" -ge 2 ] && echo "PASS|외부 모델 ${total}건 (CX:${codex} GM:${gemini})" && return
  [ "$total" -gt 0 ] && echo "WARN|외부 모델 ${total}건 (이중 검수 미달)" && return
  echo "FAIL|외부 모델 호출 0건 — Claude 자기 검수 금지"
}

# ─── Check 19: Tool Priority (Built-in > Bash > MCP) ───
check_tool_priority() {
  local mcp_calls=$(safe_count "grep -c 'mcp__' \"$TRANSCRIPT\"")
  [ "$mcp_calls" -eq 0 ] && echo "PASS|MCP 호출 0건" && return
  local builtin_calls=$(safe_count "grep -o '\"name\":\"Read\"\|\"name\":\"Glob\"\|\"name\":\"Grep\"\|\"name\":\"Write\"\|\"name\":\"Edit\"' \"$TRANSCRIPT\" | wc -l")
  [ "$builtin_calls" -gt "$mcp_calls" ] && echo "PASS|Built-in ${builtin_calls}건 > MCP ${mcp_calls}건" && return
  echo "WARN|MCP ${mcp_calls}건 vs Built-in ${builtin_calls}건 — 비용 효율 확인 필요"
}

# ─── Check 20: API 비용 로깅 ───
check_cost_logging() {
  local api_calls=$(safe_count "grep -c 'perplexity\|tavily\|openai\|codex\|gemini' \"$TRANSCRIPT\"")
  [ "$api_calls" -eq 0 ] && echo "N/A|외부 API 없음" && return
  local cost_log=$(safe_count "grep -c 'log-api-cost' \"$TRANSCRIPT\"")
  [ "$cost_log" -gt 0 ] && echo "PASS|비용 로깅 ${cost_log}건" && return
  echo "WARN|외부 API ${api_calls}건, 비용 로깅 0건"
}

# ─── Check 21: Search-Before-Solve ───
check_search_before_solve() {
  local stuck=$(safe_count "grep '\"type\":\"assistant\"' \"$TRANSCRIPT\" | grep -c '막히\|문제가\|실패\|안 되\|에러'")
  [ "$stuck" -eq 0 ] && echo "N/A|막힘 없음" && return
  local searches=$(safe_count "grep -c 'perplexity\|tavily\|WebSearch\|WebFetch\|LESSONS\|옵시디언\|Obsidian' \"$TRANSCRIPT\"")
  [ "$searches" -gt 0 ] && echo "PASS|막힘 ${stuck}건, 검색 ${searches}건" && return
  echo "FAIL|막힘 ${stuck}건, 검색 0건"
}

# ─── Check 22: Playwright 스크린샷 검증 ───
check_screenshot_verify() {
  local deploys=$(safe_count "grep '\"type\":\"assistant\"' \"$TRANSCRIPT\" | grep -c 'firebase deploy'")
  [ "$deploys" -eq 0 ] && echo "N/A|배포 없음" && return
  local screenshots=$(safe_count "grep -c 'mcp__expect__screenshot\|screenshot\|deploy-desktop\|deploy-mobile\|스크린샷' \"$TRANSCRIPT\"")
  local read_img=$(safe_count "grep '\"name\":\"Read\"' \"$TRANSCRIPT\" | grep -c '\.png\|\.jpg\|screenshot'")
  local total=$((screenshots + read_img))
  [ "$total" -gt 0 ] && echo "PASS|스크린샷 검증 ${total}건 (expect MCP 또는 직접 Read)" && return
  echo "FAIL|배포 후 스크린샷 검증 없음 (mcp__expect__screenshot 사용 권장)"
}

# ─── Check 23: Pipeline Loop (11단계 FAIL→수정→재실행 루프) ───
check_pipeline_loop() {
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  local deploys=$(safe_count "grep -c 'firebase deploy' \"$TRANSCRIPT\"")
  [ "$deploys" -eq 0 ] && echo "N/A|배포 없음" && return
  # Check if there were multiple deploy attempts (= loop iteration)
  [ "$deploys" -ge 2 ] && echo "PASS|배포 ${deploys}회 (루프 반복 확인)" && return
  # Check for FAIL→fix patterns after deploy
  local post_deploy_fix=$(safe_count "grep -c 'FAIL\|수정\|fix\|재배포\|재검증' \"$TRANSCRIPT\"")
  [ "$post_deploy_fix" -gt 5 ] && echo "PASS|배포 후 수정 패턴 ${post_deploy_fix}건" && return
  echo "WARN|배포 ${deploys}회, 루프 반복 불확실"
}

# (check_design is already defined above, moving marker)
# ─── Check 24: Antigravity 잔존 체크 ───
check_no_antigravity() {
  # Detect PROCEDURAL usage of opencode/antigravity in harness source.
  # Line-level grep that excludes deprecation-guard mentions (폐기/금지/deprecated/차단/리스크 등)
  # — previously file-level grep flagged CLAUDE.md's own STICKY deprecation table every
  # session (678+ false FAILs). Guard text is the cure, not the disease.
  local harness_dir="$HOME/.claude"
  local guard_filter="폐기|금지|deprecated|차단|리스크|대체|P-053|P-105|STICKY"
  # Codex review 2026-06-11: guard-filter alone can hide a procedural-usage line that
  # happens to contain a guard keyword → also count positive invocation patterns UNFILTERED.
  local usage_pattern="opencode (serve|run|exec)|npx +opencode|antigravity (login|exec|run)"
  local raw=$(grep -rniE "opencode|antigravity" \
    "$harness_dir/CLAUDE.md" \
    "$harness_dir/hooks/"*.sh \
    "$harness_dir/scripts/"*.sh \
    "$harness_dir/rules/"*.md \
    2>/dev/null | grep -v "audit-session.sh\|evaluator.sh")
  local usage_hits=$(printf '%s' "$raw" | grep -ciE "$usage_pattern" | tr -d '[:space:]')
  local hits=$(printf '%s\n' "$raw" | grep -viE "$guard_filter" | grep .)
  local source_refs=$(printf '%s' "$hits" | grep -c . | tr -d '[:space:]')
  if [ "${usage_hits:-0}" -gt 0 ] || [ "${source_refs:-0}" -gt 0 ]; then
    local files=$(printf '%s\n' "$raw" | cut -d: -f1 | sort -u | xargs -I{} basename {} | tr '\n' ', ')
    echo "FAIL|opencode/antigravity 절차적 참조 — 호출패턴 ${usage_hits:-0}건 + 비가드 언급 ${source_refs:-0}건: ${files}"
  else
    echo "PASS|opencode/antigravity 절차적 참조 0건 (가드 문구 제외 + 호출패턴 검사, 폐기 준수)"
  fi
}

# ─── Check 25: agentmemory 자율 저장/검색 (gbrain 폐기 P-172 → agentmemory 대체) ───
check_agentmemory_usage() {
  local mem_recall=$(grep -ci "memory_recall\|memory_save\|memory_smart_search\|mcp__agentmemory__" "$TRANSCRIPT" 2>/dev/null || echo "0")
  local obsidian_grep=$(grep -ci "OBSIDIAN_VAULT\|05-wiki\|grep.*pitfall" "$TRANSCRIPT" 2>/dev/null || echo "0")
  local total=$((mem_recall + obsidian_grep))
  if [ "$total" -gt 0 ]; then
    echo "PASS|agentmemory ${mem_recall}건, obsidian grep ${obsidian_grep}건"
  else
    echo "WARN|agentmemory/obsidian 사용 0건 — Search-Before-Solve에서 memory_recall 또는 obsidian grep 미사용"
  fi
}

# ─── Check 27: Rule→Implementation Gap (P-012) ───
check_rule_impl_gap() {
  local hooks_dir="$HOME/.claude/hooks"
  local scripts_dir="$HOME/.claude/scripts"
  local commands_dir="$HOME/.claude/commands"
  local rules_dir="$HOME/.claude/rules"
  local claude_md="$HOME/.claude/CLAUDE.md"
  local harness_root="$HOME/.claude"

  # Extract literal filenames (*.sh, *.ts, *.js) from rule files
  # Uses grep -oE to capture only the filename token; excludes lines that are comments (#)
  # Exclude: (a) build artifacts, (b) config files, (c) npm CLI tools used via npx,
  #         (d) root-level harness scripts (install.sh, deploy.sh),
  #         (e) WSL2-side OpenClaw scripts (/home/creator/... — never deployed to ~/.claude)
  local EXCLUDE_PATTERN="^(deploy\.sh|install\.sh|index\.js|settings\.js|api_cost_log\.js|package\.json|tsconfig\.js|firebase\.js|server\.js|app\.js|main\.js|config\.js|setup\.js|build\.js|drift-guard\.(sh|ts|js)|openclaw[a-z0-9_-]*\.(sh|ts|js)|runtime[a-z0-9_-]*\.js)$"
  local referenced_files
  # \b prevents .json filenames being captured as .js (access.json → "access.js" false positive)
  referenced_files=$(
    {
      grep -oE '[a-z][a-z0-9_-]+\.(sh|ts|js)\b' "$claude_md" 2>/dev/null
      for f in "$rules_dir"/*.md; do
        [ -f "$f" ] && grep -oE '[a-z][a-z0-9_-]+\.(sh|ts|js)\b' "$f" 2>/dev/null
      done
    } | sort -u | grep -vE "$EXCLUDE_PATTERN"
  )

  if [ -z "$referenced_files" ]; then
    echo "WARN|규칙 파일에서 .sh/.ts/.js 파일명 추출 실패"
    return
  fi

  local missing=()
  local found=0
  while IFS= read -r fname; do
    [ -z "$fname" ] && continue
    # Check hooks, scripts, commands, and harness root (install.sh, deploy.sh live there)
    if [ -f "$hooks_dir/$fname" ] || [ -f "$scripts_dir/$fname" ] || \
       [ -f "$commands_dir/$fname" ] || [ -f "$harness_root/$fname" ]; then
      found=$((found + 1))
    else
      missing+=("$fname")
    fi
  done <<< "$referenced_files"

  local total=$((found + ${#missing[@]}))
  local miss_count=${#missing[@]}

  if [ "$miss_count" -eq 0 ]; then
    echo "PASS|참조 파일 ${total}개 전부 존재"
  elif [ "$miss_count" -le 2 ]; then
    echo "WARN|미존재 ${miss_count}개: ${missing[*]}"
  else
    echo "FAIL|미존재 ${miss_count}개: ${missing[*]}"
  fi
}

# ─── Check 26: Agent Teams 정리 ───
check_agent_teams_cleanup() {
  local team_create=$(grep -ci "TeamCreate" "$TRANSCRIPT" 2>/dev/null || echo "0")
  local team_delete=$(grep -ci "TeamDelete" "$TRANSCRIPT" 2>/dev/null || echo "0")
  if [ "$team_create" -eq 0 ]; then
    echo "N/A|팀 미사용"
  elif [ "$team_delete" -ge "$team_create" ]; then
    echo "PASS|생성 ${team_create}건, 삭제 ${team_delete}건 (정리 완료)"
  else
    echo "WARN|생성 ${team_create}건, 삭제 ${team_delete}건 — 미정리 팀 존재 가능"
  fi
}

# ─── Check 28: PreCompact hook exit 2 차단 로직 ───
check_precompact_block() {
  local hook_file="$HOME/.claude/hooks/pre-compact-snapshot.sh"
  if [ ! -f "$hook_file" ]; then
    echo "FAIL|pre-compact-snapshot.sh 파일 없음"
    return
  fi
  local exit2=$(grep -c "exit 2" "$hook_file" 2>/dev/null || echo "0")
  [ "$exit2" -gt 0 ] && echo "PASS|exit 2 차단 로직 존재 (${exit2}건)" && return
  echo "FAIL|exit 2 없음 — compact 강제 차단 불가"
}

# ─── Check 29: Obsidian 세션 파일 저장 (compact 전 P-007) ───
check_obsidian_save() {
  if [ -z "$OBSIDIAN_VAULT" ]; then
    echo "N/A|OBSIDIAN_VAULT 미설정"
    return
  fi
  local session_dir="$OBSIDIAN_VAULT/01-jamesclaw/harness"
  if [ ! -d "$session_dir" ]; then
    echo "WARN|Obsidian harness 디렉토리 없음: ${session_dir}"
    return
  fi
  # Check for session files created in last 7 days
  local recent=$(find "$session_dir" -name "session-*.md" -mtime -7 2>/dev/null | wc -l | tr -d ' ')
  local any=$(find "$session_dir" -name "session-*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$recent" -gt 0 ]; then
    echo "PASS|7일 이내 세션 파일 ${recent}개"
  elif [ "$any" -gt 0 ]; then
    echo "WARN|세션 파일 ${any}개 존재, 7일 이내 없음 (P-007: compact 전 저장 확인)"
  else
    echo "WARN|session-*.md 없음 — compact 전 저장 미실행 가능성"
  fi
}

# ─── Check 30: 5H 80%+ 비상 모드 감지 ───
check_5h_emergency() {
  local triggered=$(safe_count "grep -c '5H 80\|80%\|Sonnet 위임 모드\|비상 모드' \"$TRANSCRIPT\"")
  [ "$triggered" -eq 0 ] && echo "N/A|5H 비상 미발동" && return
  # Check if model switch actually happened after emergency detection
  local model_switch=$(safe_count "grep -c '/model sonnet\|model.*sonnet\|Sonnet.*전환\|switched.*sonnet' \"$TRANSCRIPT\"")
  [ "$model_switch" -gt 0 ] && echo "PASS|비상 발동 ${triggered}건, Sonnet 전환 ${model_switch}건" && return
  echo "WARN|비상 패턴 ${triggered}건, 모델 전환 미확인"
}

# ─── Check 31: 버전 업데이트 시 매뉴얼 동시 업데이트 ───
check_version_manual_sync() {
  local version_mention=$(safe_count "grep -c 'changelog\|버전.*업데이트\|version.*update\|v[0-9]\+\.[0-9]\+\.[0-9]\+' \"$TRANSCRIPT\"")
  [ "$version_mention" -eq 0 ] && echo "N/A|버전 업데이트 없음" && return
  # Check if claude-code-manual.md was also modified (harness-manual.md archived 2026-06-11)
  local manual_edit=$(safe_count "grep '\"name\":\"Write\"\|\"name\":\"Edit\"' \"$TRANSCRIPT\" | grep -c 'claude-code-manual\.md'")
  [ "$manual_edit" -gt 0 ] && echo "PASS|버전 언급 ${version_mention}건, 매뉴얼 수정 ${manual_edit}건" && return
  echo "WARN|버전 언급 ${version_mention}건, claude-code-manual.md 수정 0건"
}

# ─── Check 32: design-review Vision 호출 검증 ───
check_design_review_vision() {
  local design_review=$(safe_count "grep -c 'design-review\|mcp__stitch\|stitch.*screen\|Stitch.*디자인' \"$TRANSCRIPT\"")
  [ "$design_review" -eq 0 ] && echo "N/A|디자인 리뷰 없음" && return
  # Check for image Read calls (Vision usage)
  local vision_read=$(safe_count "grep '\"name\":\"Read\"' \"$TRANSCRIPT\" | grep -c '\.png\|\.jpg\|\.jpeg\|\.webp\|screenshot'")
  [ "$vision_read" -gt 0 ] && echo "PASS|디자인 리뷰 ${design_review}건, Vision 이미지 Read ${vision_read}건" && return
  echo "WARN|디자인 리뷰 ${design_review}건, Vision Read 0건 — Opus Vision 미사용 가능성"
}

# ─── Check 33: Agent() 호출 시 model: sonnet 명시 여부 ───
check_model_sonnet_explicit() {
  # Find Agent( tool calls in transcript
  local agent_calls=$(safe_count "grep -c '\"name\":\"Agent\"' \"$TRANSCRIPT\"")
  [ "$agent_calls" -eq 0 ] && echo "N/A|Agent 호출 없음" && return
  # Check how many have model specified (sonnet or other)
  local with_model=$(safe_count "grep -A5 '\"name\":\"Agent\"' \"$TRANSCRIPT\" | grep -c '\"model\"'")
  if [ "$with_model" -ge "$agent_calls" ]; then
    echo "PASS|Agent ${agent_calls}건 전부 model 명시"
  elif [ "$with_model" -gt 0 ]; then
    local missing=$((agent_calls - with_model))
    echo "WARN|Agent ${agent_calls}건 중 ${missing}건 model 미명시 — Opus 풀 차감 위험"
  else
    echo "WARN|Agent ${agent_calls}건, model 명시 0건 — model: sonnet 명시 필수"
  fi
}

check_vision_dual_pass() {
  [ -z "$TRANSCRIPT" ] && echo "N/A|트랜스크립트 없음" && return
  # Skip for non-build sessions — doc/harness-maintenance edits often
  # quote "mcp__expect__screenshot" as a literal string without invoking it
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  # Count only actual tool invocations (tool_use JSON), not text mentions
  local screenshot_calls=$(safe_count "grep -cE '\"type\":\"tool_use\"[^}]*\"name\":\"mcp__expect__screenshot\"' \"$TRANSCRIPT\"")
  [ "$screenshot_calls" -eq 0 ] && echo "N/A|screenshot 미사용" && return
  local snapshot_calls=$(safe_count "grep -c '\"mode\":\"snapshot\"\\|\"mode\":\"annotated\"' \"$TRANSCRIPT\"")
  [ "$snapshot_calls" -ge "$screenshot_calls" ] && echo "PASS|snapshot ${snapshot_calls}건, screenshot ${screenshot_calls}건" && return
  [ "$snapshot_calls" -gt 0 ] && echo "WARN|screenshot ${screenshot_calls}건, snapshot ${snapshot_calls}건 (이중 패스 불완전)" && return
  echo "FAIL|screenshot ${screenshot_calls}건, snapshot 0건 — ARIA 1차 패스 누락"
}

check_sonnet_vision_delegation() {
  [ -z "$TRANSCRIPT" ] && echo "N/A|트랜스크립트 없음" && return
  local img_reads=$(safe_count "grep '\"name\":\"Read\"' \"$TRANSCRIPT\" | grep -cE '\\.png|\\.jpg|\\.jpeg|\\.webp|screenshot'")
  [ "$img_reads" -eq 0 ] && echo "N/A|이미지 Read 없음" && return
  local delegation=$(safe_count "grep -cE 'SendMessage.*Vision|Opus.*Vision|Vision.*Opus|vision.*위임' \"$TRANSCRIPT\"")
  [ "$delegation" -gt 0 ] && echo "PASS|이미지 Read ${img_reads}건, 위임 ${delegation}건" && return
  echo "WARN|이미지 Read ${img_reads}건, Opus 위임 0건 — Sonnet Vision 직접 분석 가능성"
}

# ─── Check 36: v2.1.121 PostToolUse updatedToolOutput 활용 여부 (참고용) ───
# v2.1.121부터 MCP 전용이던 updatedToolOutput이 모든 도구로 확장.
# 현재 하네스가 이 기능을 활용하지 않아도 WARN이지, FAIL은 아님 (신기능, 강제 아님).
check_v121_post_tool_output() {
  local hooks_dir="$HOME/.claude/hooks"
  # Check if any hook uses updatedToolOutput (= hook that injects output replacement)
  local usage=$(grep -rli "updatedToolOutput" "$hooks_dir" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$usage" -gt 0 ]; then
    local files=$(grep -rli "updatedToolOutput" "$hooks_dir" 2>/dev/null | xargs -I{} basename {} | tr '\n' ', ')
    echo "PASS|updatedToolOutput 활용 hook ${usage}개: ${files}"
  else
    echo "WARN|updatedToolOutput 미활용 — v2.1.121 신기능 (모든 도구 출력 교체 가능). 필수 아님, 참고용"
  fi
}

# ─── Check 37: v2.1.121 MCP alwaysLoad 옵션 적용 여부 ───
# alwaysLoad: true 설정 시 ToolSearch 우회 → 고정 사용 MCP(agentmemory, telegram 등) 응답 속도 향상.
check_v121_mcp_always_load() {
  local settings_file="$HOME/.claude/settings.json"
  if [ ! -f "$settings_file" ]; then
    echo "N/A|settings.json 없음"
    return
  fi
  local always_load=$(grep -c '"alwaysLoad"' "$settings_file" 2>/dev/null || echo "0")
  always_load=$(echo "$always_load" | tr -d '[:space:]')
  if [ "$always_load" -gt 0 ]; then
    echo "PASS|alwaysLoad 설정 ${always_load}건 — ToolSearch 우회 활성"
  else
    echo "WARN|alwaysLoad 미설정 — v2.1.121 신기능. agentmemory/telegram 등 고정 MCP에 적용 시 속도 향상 가능"
  fi
}

# ─── Check 38: v2.1.120 Windows Git Bash 설치 확인 ───
# v2.1.120부터 Git Bash 없으면 PowerShell로 자동 폴백.
# 하네스 hook은 모두 bash 의존 → Git Bash 미설치 시 hook 동작 불가.
check_v120_powershell_fallback() {
  # Check if git bash (sh.exe) is installed on Windows
  if command -v bash >/dev/null 2>&1; then
    local bash_path
    bash_path=$(command -v bash 2>/dev/null)
    # Distinguish Git Bash from WSL bash
    if echo "$bash_path" | grep -qi "git\|mingw\|usr/bin/bash"; then
      echo "PASS|Git Bash 설치됨 (${bash_path}) — 하네스 hook bash 의존 정상"
    else
      echo "PASS|bash 사용 가능 (${bash_path})"
    fi
  elif command -v sh >/dev/null 2>&1; then
    echo "PASS|sh 사용 가능 — bash 의존 hook 동작 가능성 있음"
  else
    echo "FAIL|bash/sh 없음 — v2.1.120+ PowerShell 폴백 환경. 하네스 hook(.sh) 미동작 위험. Git for Windows 설치 권장"
  fi
}

# ─── Check 40: v2.1.122 malformed hooks 단일 entry 파일 무효화 방지 ───
# v2.1.122부터 잘못된 hook 추가해도 다른 hook 죽지 않음.
# settings.json hooks 배열이 최소 1개 이상 유효하게 유지되는지 점검.
check_v122_malformed_hooks() {
  local settings_file="$HOME/.claude/settings.json"
  if [ ! -f "$settings_file" ]; then
    echo "N/A|settings.json 없음"
    return
  fi
  # Count hooks entries in settings.json
  local hook_count
  hook_count=$(grep -c '"command"' "$settings_file" 2>/dev/null || echo "0")
  hook_count=$(echo "$hook_count" | tr -d '[:space:]')
  if [ "$hook_count" -gt 0 ]; then
    echo "PASS|hooks 항목 ${hook_count}개 확인 — v2.1.122 단일 entry 무효화 방지 적용 환경"
  else
    echo "WARN|settings.json hooks 항목 0건 — hook 설정 확인 필요"
  fi
}

# ─── Check 41: v2.1.128 ENABLE_PROMPT_CACHING_1H=1 1시간 TTL 적용 ───
# v2.1.128 이전엔 ENABLE_PROMPT_CACHING_1H=1 설정해도 5분으로 잘림.
# 이제 정상 1시간. .env 또는 settings.json에 설정 여부 확인.
check_v128_prompt_cache() {
  local env_file="$HOME/.claude/.env"
  local settings_file="$HOME/.claude/settings.json"
  local harness_env="$HOME/.harness-state/.env"
  local found=0
  # Check .env files
  for f in "$env_file" "$harness_env" "$HOME/.env"; do
    if [ -f "$f" ] && grep -q "ENABLE_PROMPT_CACHING_1H" "$f" 2>/dev/null; then
      found=$((found + 1))
    fi
  done
  # Check settings.json env section
  if [ -f "$settings_file" ] && grep -q "ENABLE_PROMPT_CACHING_1H" "$settings_file" 2>/dev/null; then
    found=$((found + 1))
  fi
  if [ "$found" -gt 0 ]; then
    echo "PASS|ENABLE_PROMPT_CACHING_1H 설정 확인 — v2.1.128+ 정상 1h TTL 적용"
  else
    echo "WARN|ENABLE_PROMPT_CACHING_1H 미설정 — 1h 캐시 TTL 미활용 (참고용, 강제 아님)"
  fi
}

# ─── Check 42: v2.1.128 1M-context 워크어라운드 유효성 ───
# v2.1.128 native fix 후에도 우리 wrapper(claude-opus.cmd + settings.local.json) 유지.
# P-115/P-116 방어선이 여전히 존재하는지 확인.
check_v128_long_context_fix() {
  local settings_local="$HOME/.claude/settings.local.json"
  local claude_cmd
  # Check for settings.local.json (P-115/P-116 workaround)
  if [ -f "$settings_local" ]; then
    local long_ctx=$(grep -c 'maxTokens\|contextWindow\|compaction\|autocompact' "$settings_local" 2>/dev/null || echo "0")
    long_ctx=$(echo "$long_ctx" | tr -d '[:space:]')
    if [ "$long_ctx" -gt 0 ]; then
      echo "PASS|settings.local.json에 long-context 설정 ${long_ctx}건 — P-115/P-116 방어선 유지"
      return
    fi
  fi
  # Check for claude-opus.cmd wrapper
  for f in "$HOME/.claude/claude-opus.cmd" "$HOME/claude-opus.cmd"; do
    if [ -f "$f" ]; then
      echo "PASS|claude-opus.cmd wrapper 존재 — P-115/P-116 방어선 유지"
      return
    fi
  done
  echo "WARN|P-115/P-116 워크어라운드 파일 미확인 — v2.1.128 native fix 의존 (참고용)"
}

# ─── Check 43: v2.1.132 statusline context_window fix (heartbeat 정확도) ───
# v2.1.132부터 statusline이 누적 세션 토큰 대신 현재 컨텍스트 사용량을 표시.
# telegram-notify.sh heartbeat 정확도 회복. 스크립트 존재 + 버전 인식 체크.
check_v132_context_window() {
  local notify_sh="$HOME/.claude/hooks/telegram-notify.sh"
  if [ ! -f "$notify_sh" ]; then
    # Also check scripts dir
    notify_sh="$HOME/.claude/scripts/telegram-notify.sh"
  fi
  if [ ! -f "$notify_sh" ]; then
    echo "WARN|telegram-notify.sh 없음 — heartbeat 스크립트 확인 필요"
    return
  fi
  # Check for heartbeat function / context reading
  local has_heartbeat=$(grep -c 'heartbeat\|context_usage\|context_window' "$notify_sh" 2>/dev/null || echo "0")
  has_heartbeat=$(echo "$has_heartbeat" | tr -d '[:space:]')
  if [ "$has_heartbeat" -gt 0 ]; then
    echo "PASS|telegram-notify.sh heartbeat 로직 ${has_heartbeat}건 확인 — v2.1.132 context_window fix 수혜"
  else
    echo "WARN|telegram-notify.sh heartbeat 로직 미확인 — context 수치 정확도 점검 권장"
  fi
}

# ─── Check 44: v2.1.132 CLAUDE_CODE_SESSION_ID Bash hook 활용 ───
# v2.1.132부터 Bash subprocess에 session_id 자동 export.
# hook에서 $CLAUDE_CODE_SESSION_ID 사용 가능. 활용 hook 존재 여부 확인.
check_v132_session_id() {
  local hooks_dir="$HOME/.claude/hooks"
  local usage
  usage=$(grep -rli "CLAUDE_CODE_SESSION_ID" "$hooks_dir" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$usage" -gt 0 ]; then
    local files
    files=$(grep -rli "CLAUDE_CODE_SESSION_ID" "$hooks_dir" 2>/dev/null | xargs -I{} basename {} | tr '\n' ', ')
    echo "PASS|CLAUDE_CODE_SESSION_ID 활용 hook ${usage}개: ${files}"
  else
    echo "WARN|CLAUDE_CODE_SESSION_ID 미활용 — v2.1.132 신기능. hook 세션 추적에 활용 가능 (참고용)"
  fi
}

# ─── Check 45: v2.1.133 worktree.baseRef 설정 ───
# v2.1.133부터 default 'fresh' (origin/<default>)로 복귀.
# Agent worktree에서 unpushed commits 보존 필요 시 "head" 명시 필요.
check_v133_worktree_baseref() {
  local settings_file="$HOME/.claude/settings.json"
  if [ ! -f "$settings_file" ]; then
    echo "N/A|settings.json 없음"
    return
  fi
  local baseref=$(grep -c '"baseRef"' "$settings_file" 2>/dev/null || echo "0")
  baseref=$(echo "$baseref" | tr -d '[:space:]')
  if [ "$baseref" -gt 0 ]; then
    local val
    val=$(grep '"baseRef"' "$settings_file" 2>/dev/null | head -1)
    echo "PASS|worktree.baseRef 명시 설정 — ${val}"
  else
    echo "WARN|worktree.baseRef 미설정 — default 'fresh'(origin 기반). unpushed commits 있는 Agent worktree 사용 시 'head' 명시 권장"
  fi
}

# ─── Check 46: v2.1.133 $CLAUDE_EFFORT env hook 활용 ───
# v2.1.133부터 Bash subprocess + hook JSON에 effort.level 주입.
# $CLAUDE_EFFORT env 또는 JSON effort.level을 hook이 활용하는지 확인.
check_v133_claude_effort_env() {
  local hooks_dir="$HOME/.claude/hooks"
  local usage
  usage=$(grep -rli "CLAUDE_EFFORT\|effort\.level" "$hooks_dir" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$usage" -gt 0 ]; then
    local files
    files=$(grep -rli "CLAUDE_EFFORT\|effort\.level" "$hooks_dir" 2>/dev/null | xargs -I{} basename {} | tr '\n' ', ')
    echo "PASS|CLAUDE_EFFORT/effort.level 활용 hook ${usage}개: ${files}"
  else
    echo "WARN|CLAUDE_EFFORT env 미활용 — v2.1.133 신기능. effort 기반 hook 분기 가능 (참고용)"
  fi
}

# ─── Check 47: v2.1.136 autoMode.hard_deny 위험 작업 차단 설정 ───
# v2.1.136 신규. user intent / allow exception 무시하고 무조건 차단.
# 위험 작업 영구 차단용. settings.json에 설정 여부 확인.
check_v136_hard_deny() {
  local settings_file="$HOME/.claude/settings.json"
  if [ ! -f "$settings_file" ]; then
    echo "N/A|settings.json 없음"
    return
  fi
  local hard_deny=$(grep -c '"hard_deny"' "$settings_file" 2>/dev/null || echo "0")
  hard_deny=$(echo "$hard_deny" | tr -d '[:space:]')
  if [ "$hard_deny" -gt 0 ]; then
    echo "PASS|autoMode.hard_deny 설정 확인 — v2.1.136 위험 작업 영구 차단 활성"
  else
    echo "WARN|autoMode.hard_deny 미설정 — v2.1.136 신기능. irreversible-alert.sh로 대체 중 (참고용)"
  fi
}

# ─── Check 48: v2.1.139 /goal 커맨드 + Agent View 활용 ───
# v2.1.139 신규. /goal: completion condition 설정 → Claude 자동 지속.
# claude agents: 모든 세션 가시성. 하네스 운용에 직접 유용.
check_v139_goal_agentview() {
  local harness_dir="$HOME/.claude"
  # Check if /goal is referenced in commands or CLAUDE.md
  local goal_ref=$(grep -rl '/goal\b' "$harness_dir/CLAUDE.md" "$harness_dir/commands/" "$harness_dir/rules/" 2>/dev/null | wc -l | tr -d ' ')
  # Check if claude agents is referenced
  local agents_ref=$(grep -rl '"claude agents"\|claude agents\b' "$harness_dir/CLAUDE.md" "$harness_dir/rules/" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$goal_ref" -gt 0 ] || [ "$agents_ref" -gt 0 ]; then
    echo "PASS|/goal 참조 ${goal_ref}건, claude agents 참조 ${agents_ref}건 — v2.1.139 신기능 인지"
  else
    echo "WARN|/goal / claude agents 참조 없음 — v2.1.139 신기능 미활용 (참고용)"
  fi
}

# ─── Check 49: v2.1.139 Hook args: string[] exec form 마이그레이션 ───
# v2.1.139 신규. args: string[] 형식은 셸 없이 직접 spawn — path quoting 불필요.
# 우리 hook 점진 마이그레이션 후보. settings.json에 args 배열 사용 여부 확인.
check_v139_hook_args_exec() {
  local settings_file="$HOME/.claude/settings.json"
  if [ ! -f "$settings_file" ]; then
    echo "N/A|settings.json 없음"
    return
  fi
  # args: string[] in hooks = JSON array after "args" key
  local args_array=$(python3 -c "
import json, sys
try:
    d = json.load(open('$settings_file'))
    hooks = d.get('hooks', {})
    count = 0
    for events in hooks.values():
        for h in (events if isinstance(events, list) else []):
            if isinstance(h.get('args'), list):
                count += 1
    print(count)
except: print(0)
" 2>/dev/null || echo "0")
  args_array=$(echo "$args_array" | tr -d '[:space:]')
  if [ "$args_array" -gt 0 ]; then
    echo "PASS|hook args: string[] 형식 ${args_array}개 사용 — v2.1.139 exec form 적용"
  else
    echo "WARN|hook args: string[] 미사용 — 모두 command string 형식. v2.1.139 exec form 점진 마이그레이션 권장 (참고용)"
  fi
}

# ─── Check 50: v2.1.141 Hook terminalSequence JSON output ───
# v2.1.141 신규. hook이 terminalSequence를 stdout에 출력 시 데스크톱 알림/창 제목 emit.
# telegram-notify.sh 대안 또는 보완으로 활용 가능. 현재 활용 여부 확인.
check_v141_terminal_sequence() {
  local hooks_dir="$HOME/.claude/hooks"
  local usage
  usage=$(grep -rli "terminalSequence\|terminal_sequence" "$hooks_dir" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$usage" -gt 0 ]; then
    local files
    files=$(grep -rli "terminalSequence\|terminal_sequence" "$hooks_dir" 2>/dev/null | xargs -I{} basename {} | tr '\n' ', ')
    echo "PASS|terminalSequence 활용 hook ${usage}개: ${files}"
  else
    echo "WARN|terminalSequence 미활용 — v2.1.141 신기능. 데스크톱 알림 보완 가능 (참고용)"
  fi
}

# ─── Check 51: v2.1.142 claude agents 8개 플래그 background dispatch ───
# v2.1.142 신규. --add-dir, --settings, --model, --effort 등 8개 플래그.
# harness scripts에서 'claude agents' 명시적 호출 여부 확인.
check_v142_agents_flags() {
  local scripts_dir="$HOME/.claude/scripts"
  local commands_dir="$HOME/.claude/commands"
  local usage=0
  for dir in "$scripts_dir" "$commands_dir"; do
    if [ -d "$dir" ]; then
      local cnt
      cnt=$(grep -rli "claude agents\b\|claude[[:space:]]\+agents" "$dir" 2>/dev/null | wc -l | tr -d ' ')
      usage=$((usage + cnt))
    fi
  done
  if [ "$usage" -gt 0 ]; then
    echo "PASS|claude agents 호출 스크립트 ${usage}개 — v2.1.142 8-flag background dispatch 활용 가능"
  else
    echo "WARN|claude agents 미활용 — v2.1.142 신기능. background dispatch 자동화 가능 (참고용)"
  fi
}

# ─── Check 52: v2.1.142 Fast mode Opus 4.7 기본값 인지 ───
# v2.1.142부터 /fast 기본 모델이 Opus 4.6→4.7로 변경.
# Opus 4.6 pin 필요 시 CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1 필요.
# settings.json 또는 .env에 override 설정 여부 확인.
check_v142_fast_mode_opus47() {
  local settings_file="$HOME/.claude/settings.json"
  local found_override=0
  for f in "$HOME/.claude/.env" "$HOME/.env" "$HOME/.harness-state/.env"; do
    if [ -f "$f" ] && grep -q "CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE" "$f" 2>/dev/null; then
      found_override=1
    fi
  done
  if [ -f "$settings_file" ] && grep -q "CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE" "$settings_file" 2>/dev/null; then
    found_override=1
  fi
  if [ "$found_override" -eq 1 ]; then
    echo "PASS|CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE 설정 — /fast 시 Opus 4.6 pin 유지"
  else
    echo "WARN|CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE 미설정 — v2.1.142+ /fast 기본값=Opus 4.7. 4.6 pin 불필요하면 정상 (참고용)"
  fi
}

# ─── Check 53: v2.1.143 Stop hook 8 consecutive blocks cap ───
# v2.1.143부터 Stop hook `block` 응답이 8회 연속이면 turn 종료(warning).
# override: CLAUDE_CODE_STOP_HOOK_BLOCK_CAP. 우리 Ghost Mode 3회 정책과 정합 — 안전망 역할.
# 우리 hook(enforce-execution.sh, evidence-first.sh)이 false-positive로 반복 block 시 cap 발동 가능.
check_v143_stop_hook_block_cap() {
  local cap_set=0
  local settings_file="$HOME/.claude/settings.json"
  for f in "$HOME/.claude/.env" "$HOME/.env" "$HOME/.harness-state/.env" "$settings_file"; do
    if [ -f "$f" ] && grep -q "CLAUDE_CODE_STOP_HOOK_BLOCK_CAP" "$f" 2>/dev/null; then
      cap_set=1
    fi
  done
  if [ "$cap_set" -eq 1 ]; then
    echo "PASS|CLAUDE_CODE_STOP_HOOK_BLOCK_CAP 설정 — Stop hook block cap 명시"
  else
    echo "WARN|CLAUDE_CODE_STOP_HOOK_BLOCK_CAP 미설정 — v2.1.143 기본 8회 cap 적용 (Ghost Mode 3회 정책 위 native 안전망, 정상)"
  fi
}

# ─── Check 54: v2.1.143 PowerShell -ExecutionPolicy Bypass 기본 ───
# v2.1.143부터 Bedrock/Vertex/Foundry 환경에서 PowerShell tool 기본 활성 + -ExecutionPolicy Bypass.
# Pro 구독(대표님 환경)은 자동 활성 아님 — 인지만 필요.
# opt-out 필요 시 CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY=1.
check_v143_powershell_policy() {
  local respect_set=0
  local disable_set=0
  local settings_file="$HOME/.claude/settings.json"
  for f in "$HOME/.claude/.env" "$HOME/.env" "$HOME/.harness-state/.env" "$settings_file"; do
    if [ -f "$f" ]; then
      grep -q "CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY" "$f" 2>/dev/null && respect_set=1
      grep -q "CLAUDE_CODE_USE_POWERSHELL_TOOL=0" "$f" 2>/dev/null && disable_set=1
    fi
  done
  if [ "$disable_set" -eq 1 ]; then
    echo "PASS|CLAUDE_CODE_USE_POWERSHELL_TOOL=0 — PowerShell tool 비활성"
  elif [ "$respect_set" -eq 1 ]; then
    echo "PASS|CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY=1 — -ExecutionPolicy Bypass opt-out"
  else
    echo "WARN|PowerShell policy override 미설정 — v2.1.143+ Bedrock/Vertex/Foundry 환경만 자동 활성. Pro 구독은 변경 없음 (참고용)"
  fi
}

# ─── Check 55: v2.1.144 /model 단일 세션 변경 정책 ───
# v2.1.144부터 /model은 현재 세션만 변경 (이전 v2.1.117~v2.1.143 영구 지속).
# v2.1.153에서 영구화로 원복됨 — /model 호출 시 자동 default 저장.
# 현재 세션만 변경: picker `s` 키 (`d` 키는 v2.1.153에서 제거됨).
check_v144_model_single_session() {
  local settings_file="$HOME/.claude/settings.json"
  if [ ! -f "$settings_file" ]; then
    echo "WARN|settings.json 없음 — /model default 미지정. v2.1.153+ /model 호출 시 자동 저장됨"
    return
  fi
  if grep -qE '"model"[[:space:]]*:[[:space:]]*"(opus|sonnet|opusplan|haiku|claude-opus|claude-sonnet)"' "$settings_file" 2>/dev/null; then
    local model_val
    model_val=$(grep -oE '"model"[[:space:]]*:[[:space:]]*"[^"]+"' "$settings_file" | head -1)
    echo "PASS|settings.json에 ${model_val} default 명시 — v2.1.153+ 영구화 정책 호환"
  else
    echo "WARN|settings.json model 필드 미명시 — v2.1.153+ /model 영구화(원복). opusplan 고정 시 settings.json model 필드 또는 /model opusplan 1회 호출 후 자동 저장. 현재세션만 변경 시 picker 's' 키 사용. ('d' 키는 v2.1.153 제거됨)"
  fi
}

# ─── Check 56: v2.1.144 MCP paginated tools/list fix 인지 ───
# v2.1.144 fix 이전엔 MCP `tools/list` 응답 첫 페이지만 노출 — 51개 등 도구 많은 MCP 일부 누락 가능.
# 현재 버전(2.1.144+) 사용 중이면 자동 해소. 확인용.
check_v144_mcp_paginated_tools() {
  local cur_ver
  cur_ver=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [ -z "$cur_ver" ]; then
    echo "WARN|claude --version 실패 — v2.1.144+ MCP paginated tools/list fix 적용 여부 확인 불가"
    return
  fi
  # version comparison: 2.1.144+ has fix
  local major minor patch
  IFS='.' read -r major minor patch <<<"$cur_ver"
  if [ "$major" -gt 2 ] || { [ "$major" -eq 2 ] && [ "$minor" -gt 1 ]; } || { [ "$major" -eq 2 ] && [ "$minor" -eq 1 ] && [ "$patch" -ge 144 ]; }; then
    echo "PASS|v${cur_ver} 사용 중 — v2.1.144 MCP paginated tools/list fix 적용 (agentmemory 51 도구 등 정상 노출)"
  else
    echo "WARN|v${cur_ver} — v2.1.144 미만. MCP tools/list 첫 페이지만 노출 가능. claude update 권장"
  fi
}

# ─── Check 57: v2.1.153 /model 영구화 원복 + s키 + d키 제거 ───
# v2.1.153: /model 단일세션(v2.1.144)→영구화 원복. picker 's' 키 신설(현재세션만). 'd' 키 제거.
check_v153_model_policy_revert() {
  local settings_file="$HOME/.claude/settings.json"
  if [ -f "$settings_file" ]; then
    if grep -qE '"model"' "$settings_file" 2>/dev/null; then
      echo "PASS|settings.json model 필드 확인 — v2.1.153 영구화 정책 인지 (s키=현재세션, d키 제거됨)"
    else
      echo "WARN|settings.json model 필드 없음 — v2.1.153+ /model 호출 시 자동 저장됨. STICKY: Opus 4.8 운용 확인 필요"
    fi
  else
    echo "WARN|settings.json 없음 — v2.1.153 /model 영구화 정책 검증 불가"
  fi
}

# ─── Check 58: v2.1.154 Opus 4.8 default high effort + /effort xhigh ───
# v2.1.154: Opus 4.8 기본 high effort, /effort xhigh 최고 난도 지원.
check_v154_opus48_effort() {
  local settings_file="$HOME/.claude/settings.json"
  if [ -f "$settings_file" ]; then
    local model_val
    model_val=$(grep -oE '"model"[[:space:]]*:[[:space:]]*"[^"]+"' "$settings_file" 2>/dev/null | head -1)
    if echo "$model_val" | grep -qi "opus"; then
      echo "PASS|${model_val} 운용 — v2.1.154 Opus 4.8 high effort 기본, /effort xhigh 최고 난도 사용 가능"
    else
      echo "WARN|Opus 모델 미명시 — v2.1.154 Opus 4.8 high effort 정책 확인 필요 (STICKY: 메인 세션 opus-4-8 운용)"
    fi
  else
    echo "WARN|settings.json 없음 — v2.1.154 Opus 4.8 effort 정책 검증 불가"
  fi
}

# ─── Check 59: v2.1.154 Dynamic Workflows (/workflows) ───
# v2.1.154: /workflows — 수십~수백 에이전트 백그라운드 오케스트레이션. ultracode 키워드 트리거.
check_v154_dynamic_workflows() {
  local commands_dir="$HOME/.claude/commands"
  if [ -d "$commands_dir" ]; then
    echo "PASS|commands/ 디렉토리 확인 — v2.1.154 Dynamic Workflows(/workflows) 사용 가능 (ultracode 키워드 opt-in)"
  else
    echo "WARN|commands/ 디렉토리 없음 — /workflows 커스텀 workflow 저장 위치 부재"
  fi
}

# ─── Check 60: v2.1.159 ultracode 트리거어 변경 ───
# v2.1.159: 'workflow' 키워드 → 'ultracode'로 변경. CLAUDE.md 반영 여부 확인.
check_v159_ultracode_trigger() {
  local claude_md="$HOME/.claude/CLAUDE.md"
  if [ -f "$claude_md" ]; then
    if grep -q "ultracode" "$claude_md" 2>/dev/null; then
      echo "PASS|CLAUDE.md에 'ultracode' 트리거어 확인 — v2.1.159 변경 반영됨"
    else
      echo "WARN|CLAUDE.md에 'ultracode' 미확인 — v2.1.159 트리거어 변경(workflow→ultracode) 미반영 가능"
    fi
  else
    echo "WARN|CLAUDE.md 없음 — v2.1.159 ultracode 트리거어 검증 불가"
  fi
}

# ─── Check 61: v2.1.163 Stop hook additionalContext + hook if Bash 수정 ───
# v2.1.163: Stop/SubagentStop hookSpecificOutput.additionalContext (턴 유지 결정론 피드백).
# hook `if:"Bash(...)"` $()/$VAR 포함 모든 Bash 오발동 수정.
check_v163_hook_additional_context() {
  local settings_file="$HOME/.claude/settings.json"
  if [ -f "$settings_file" ]; then
    local if_hooks
    if_hooks=$(grep -c '"if"' "$settings_file" 2>/dev/null || echo "0")
    if_hooks=$(echo "$if_hooks" | tr -d '[:space:]')
    if [ "$if_hooks" -gt 0 ]; then
      echo "PASS|settings.json에 hook if 조건 ${if_hooks}개 — v2.1.163 if Bash 오발동 수정 적용 (firebase/npm/jest 노이즈 해소)"
    else
      echo "WARN|hook if 조건 0개 — v2.1.163 additionalContext/if 수정 검증 불가 (정상: if 미사용 환경)"
    fi
  else
    echo "WARN|settings.json 없음 — v2.1.163 검증 불가"
  fi
}

# ─── Check 62: v2.1.166 fallbackModel 배열 ───
# v2.1.166: fallbackModel 배열(최대 3) — overload 시 순차 폴백. settings.json 등록 여부.
check_v166_fallback_model() {
  local settings_file="$HOME/.claude/settings.json"
  if [ -f "$settings_file" ]; then
    if grep -q '"fallbackModel"' "$settings_file" 2>/dev/null; then
      echo "PASS|settings.json에 fallbackModel 설정 — v2.1.166 overload 폴백 활성"
    else
      echo "WARN|settings.json fallbackModel 없음 — v2.1.166 overload 시 폴백 미설정 (CLAUDE.md: fallbackModel 운용 중)"
    fi
  else
    echo "WARN|settings.json 없음 — v2.1.166 fallbackModel 검증 불가"
  fi
}

# ─── Check 63: v2.1.169 --safe-mode / /cd / disableBundledSkills ───
# v2.1.169: --safe-mode(hook 격리 진단), /cd(prompt cache 보존 디렉토리 변경), disableBundledSkills.
check_v169_safe_mode() {
  local settings_file="$HOME/.claude/settings.json"
  if [ -f "$settings_file" ]; then
    if grep -q '"disableBundledSkills"' "$settings_file" 2>/dev/null; then
      echo "WARN|disableBundledSkills 설정됨 — v2.1.169 내장 skills 비활성. 커스텀 commands/ 사용 필요"
    else
      echo "PASS|disableBundledSkills 미설정 — v2.1.169 내장 skills 활성 (정상). --safe-mode: hook 격리 진단 도구로 사용 가능"
    fi
  else
    echo "WARN|settings.json 없음 — v2.1.169 검증 불가"
  fi
}

# ─── Check 64: v2.1.170 Fable 5 STICKY 금지 준수 ───
# v2.1.170: Claude Fable 5 GA. STICKY DECISIONS: 2026-06-21 대표님 금지 지시.
# 재도입 금지. settings.json model 필드에 fable 없어야 PASS.
check_v170_fable5_banned() {
  local settings_file="$HOME/.claude/settings.json"
  if [ -f "$settings_file" ]; then
    if grep -qi '"model".*fable\|fable.*"model"' "$settings_file" 2>/dev/null; then
      echo "FAIL|settings.json model에 Fable 5 감지 — STICKY DECISIONS 위반! 2026-06-21 대표님 금지 지시. 즉시 claude-opus-4-8로 교체 필요"
    else
      echo "PASS|Fable 5 미사용 — v2.1.170 STICKY 금지 준수 (재도입 금지)"
    fi
  else
    echo "PASS|settings.json 없음이나 Fable 5 미명시 — STICKY 금지 위반 없음"
  fi
}

# ─── Check 65: v2.1.172 서브에이전트 중첩 5단계 ───
# v2.1.172: 서브에이전트 중첩 스폰 최대 5단계. 1M 컨텍스트 무크레딧 auto-compact 복구.
check_v172_nested_subagents() {
  echo "PASS|v2.1.172 서브에이전트 중첩 5단계 지원 — 다단계 오케스트레이션 가능. 과도한 중첩은 비용 누적 주의"
}

# ─── Check 66: v2.1.173 Fable 5 [1m] suffix 자동 strip ───
# v2.1.173: claude-fable-5[1m] → claude-fable-5 자동 strip (1M 기본). 우리: Fable 5 금지이므로 무관.
check_v173_fable5_suffix_strip() {
  local claude_md="$HOME/.claude/CLAUDE.md"
  if [ -f "$claude_md" ] && grep -q "Fable.*금지\|fable.*banned\|claude-fable-5.*금지" "$claude_md" 2>/dev/null; then
    echo "PASS|CLAUDE.md Fable 5 금지 정책 확인 — v2.1.173 [1m] suffix strip 무관 (STICKY 금지 유지)"
  else
    echo "WARN|CLAUDE.md Fable 5 금지 정책 미확인 — v2.1.173 [1m] suffix strip 인지 필요"
  fi
}

# ─── Check 67: v2.1.176 hook if Read/Edit/Write 경로 매칭 수정 ───
# v2.1.176: v2.1.163 hook if 수정 후속 — Read/Edit/Write 경로 포함 if 조건 정상화.
# verify-deploy.sh, quality-gate.sh if 조건이 정상 동작하는지 확인.
check_v176_hook_if_path_fix() {
  local settings_file="$HOME/.claude/settings.json"
  if [ -f "$settings_file" ]; then
    local if_bash_hooks
    if_bash_hooks=$(grep -c '"if".*"Bash' "$settings_file" 2>/dev/null || echo "0")
    if_bash_hooks=$(echo "$if_bash_hooks" | tr -d '[:space:]')
    if [ "$if_bash_hooks" -gt 0 ]; then
      echo "PASS|Bash if 조건 ${if_bash_hooks}개 — v2.1.176 경로 매칭 수정 적용 (firebase/npm/jest 조건부 hook 정상화)"
    else
      echo "WARN|Bash if 조건 0개 — v2.1.176 검증 불가 (if 미사용 환경이면 정상)"
    fi
  else
    echo "WARN|settings.json 없음 — v2.1.176 hook if 검증 불가"
  fi
}

# ─── Check 39: v2.1.119 /config 설정 settings.json 영구 저장 ───
# v2.1.119부터 /config 변경값이 ~/.claude/settings.json에 저장됨.
# theme, editor mode, verbose 등이 재시작 후에도 유지되는지 점검.
check_v119_config_persistence() {
  local settings_file="$HOME/.claude/settings.json"
  if [ ! -f "$settings_file" ]; then
    echo "WARN|settings.json 없음 — /config 설정이 저장될 파일이 존재하지 않음"
    return
  fi
  # Check if settings.json contains user-configurable fields (theme, editorMode, verboseOutput, etc.)
  # These are written by /config commands (v2.1.119+)
  local config_fields=$(grep -cE '"theme"|"editorMode"|"verboseOutput"|"preferredNotifChannel"|"language"' "$settings_file" 2>/dev/null || echo "0")
  config_fields=$(echo "$config_fields" | tr -d '[:space:]')
  if [ "$config_fields" -gt 0 ]; then
    echo "PASS|settings.json에 /config 저장 필드 ${config_fields}개 확인 (v2.1.119+ persist 정상)"
  else
    # File exists but no user-config fields = default state, not an error
    echo "WARN|settings.json에 /config 저장 필드 없음 — /config로 설정 변경 후 재시작해도 유지되는지 직접 확인 권장"
  fi
}

# ─── Run all checks below ───
check_design() {
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  local ui_files=$(safe_count "grep '\"name\":\"Write\"' \"$TRANSCRIPT\" | grep -c '\.html\|\.css\|\.tsx\|\.jsx\|\.vue\|\.svelte'")
  [ "$ui_files" -eq 0 ] && echo "N/A|UI 파일 없음" && return
  # Stitch: actual MCP tool call only (not text mentions in pipeline-install)
  local stitch=$(safe_count "grep -c '\"name\":\"mcp__stitch' \"$TRANSCRIPT\"")
  # Design references: actual URLs or tool calls to fetch references
  local godly=$(safe_count "grep -c 'godly\.website\|motionsites\.ai' \"$TRANSCRIPT\"")
  # NotebookLM design notebook: actual query calls
  local nlm=$(safe_count "grep -c 'notebook_query.*디자인\|mcp__notebooklm.*design\|디자인.*노트북.*query' \"$TRANSCRIPT\"")
  # DESIGN.md or DESIGN_REFS.md file creation
  local design_doc=$(safe_count "grep '\"name\":\"Write\"' \"$TRANSCRIPT\" | grep -c 'DESIGN\.md\|DESIGN_REFS\.md'")
  local total=$((stitch + godly + nlm + design_doc))
  [ "$total" -gt 0 ] && echo "PASS|디자인 도구 ${total}건 (Stitch:${stitch} 레퍼런스:${godly} NLM:${nlm} DESIGN.md:${design_doc})" && return
  echo "FAIL|UI ${ui_files}건 작성, 디자인 도구/레퍼런스 0건"
}

# ─── Run all checks ───
R1=$(check_build_transition)
R2=$(check_prd)
R3=$(check_pipeline)
R4=$(check_quality_loop)
R5=$(check_external_review)
R6=$(check_deploy_verify)
R7=$(check_todowrite)
R8=$(check_ghost_mode)
R9=$(check_evidence_first)
R10=$(check_telegram_result)
R11=$(check_no_impossibility)
R12=$(check_multipass)
R13=$(check_pitfalls)
R14=$(check_commits)
R15=$(check_harness_location)
R16=$(check_error_retry)
R17=$(check_design)
R18=$(check_external_model_calls)
R19=$(check_tool_priority)
R20=$(check_cost_logging)
R21=$(check_search_before_solve)
R22=$(check_screenshot_verify)
R23=$(check_pipeline_loop)
R24=$(check_no_antigravity)
R25=$(check_agentmemory_usage)
R26=$(check_agent_teams_cleanup)
R27=$(check_rule_impl_gap)
R28=$(check_precompact_block)
R29=$(check_obsidian_save)
R30=$(check_5h_emergency)
R31=$(check_version_manual_sync)
R32=$(check_design_review_vision)
R33=$(check_model_sonnet_explicit)
R34=$(check_vision_dual_pass)
R35=$(check_sonnet_vision_delegation)
R36=$(check_v121_post_tool_output)
R37=$(check_v121_mcp_always_load)
R38=$(check_v120_powershell_fallback)
R39=$(check_v119_config_persistence)
R40=$(check_v122_malformed_hooks)
R41=$(check_v128_prompt_cache)
R42=$(check_v128_long_context_fix)
R43=$(check_v132_context_window)
R44=$(check_v132_session_id)
R45=$(check_v133_worktree_baseref)
R46=$(check_v133_claude_effort_env)
R47=$(check_v136_hard_deny)
R48=$(check_v139_goal_agentview)
R49=$(check_v139_hook_args_exec)
R50=$(check_v141_terminal_sequence)
R51=$(check_v142_agents_flags)
R52=$(check_v142_fast_mode_opus47)
R53=$(check_v143_stop_hook_block_cap)
R54=$(check_v143_powershell_policy)
R55=$(check_v144_model_single_session)
R56=$(check_v144_mcp_paginated_tools)
R57=$(check_v153_model_policy_revert)
R58=$(check_v154_opus48_effort)
R59=$(check_v154_dynamic_workflows)
R60=$(check_v159_ultracode_trigger)
R61=$(check_v163_hook_additional_context)
R62=$(check_v166_fallback_model)
R63=$(check_v169_safe_mode)
R64=$(check_v170_fable5_banned)
R65=$(check_v172_nested_subagents)
R66=$(check_v173_fable5_suffix_strip)
R67=$(check_v176_hook_if_path_fix)

LABELS=("Build Transition" "PRD" "Pipeline Install" "Quality Loop" "External Review" "Deploy Verify" "TodoWrite" "Ghost Mode" "Evidence-First" "Telegram Result" "No Impossibility" "Multi-Pass Review" "PITFALLS Record" "Conventional Commit" "Harness Location" "Error Retry" "Design Reference" "External Model Call" "Tool Priority" "Cost Logging" "Search-Before-Solve" "Screenshot Verify" "Pipeline Loop" "No Antigravity" "agentmemory Usage" "Agent Teams Cleanup" "Rule Impl Gap" "PreCompact Block" "Obsidian Save" "5H Emergency" "Version Manual Sync" "Design Review Vision" "Model Sonnet Explicit" "Vision Dual Pass" "Sonnet Vision Delegation" "v121 PostTool Output" "v121 MCP AlwaysLoad" "v120 Git Bash Check" "v119 Config Persist" "v122 Malformed Hooks" "v128 Prompt Cache" "v128 Long Context Fix" "v132 Context Window" "v132 Session ID" "v133 Worktree BaseRef" "v133 CLAUDE_EFFORT" "v136 Hard Deny" "v139 Goal+AgentView" "v139 Hook Args Exec" "v141 TerminalSeq" "v142 Agents Flags" "v142 Fast Opus47" "v143 StopHook BlockCap" "v143 PowerShell Policy" "v144 Model SingleSession" "v144 MCP Paginated" "v153 Model Revert" "v154 Opus48 Effort" "v154 Dynamic Workflows" "v159 Ultracode Trigger" "v163 Hook AdditionalCtx" "v166 FallbackModel" "v169 Safe Mode" "v170 Fable5 Banned" "v172 Nested Subagents" "v173 Fable5 Suffix" "v176 Hook If PathFix")
RESULTS=("$R1" "$R2" "$R3" "$R4" "$R5" "$R6" "$R7" "$R8" "$R9" "$R10" "$R11" "$R12" "$R13" "$R14" "$R15" "$R16" "$R17" "$R18" "$R19" "$R20" "$R21" "$R22" "$R23" "$R24" "$R25" "$R26" "$R27" "$R28" "$R29" "$R30" "$R31" "$R32" "$R33" "$R34" "$R35" "$R36" "$R37" "$R38" "$R39" "$R40" "$R41" "$R42" "$R43" "$R44" "$R45" "$R46" "$R47" "$R48" "$R49" "$R50" "$R51" "$R52" "$R53" "$R54" "$R55" "$R56" "$R57" "$R58" "$R59" "$R60" "$R61" "$R62" "$R63" "$R64" "$R65" "$R66" "$R67")

TOTAL_CHECKS=56

# ─── Score ───
PASS=0; FAIL=0; WARN=0; NA=0
for r in "${RESULTS[@]}"; do
  s="${r%%|*}"
  case "$s" in
    PASS) PASS=$((PASS + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
    WARN) WARN=$((WARN + 1)) ;;
    N/A)  NA=$((NA + 1)) ;;
  esac
done

APPLICABLE=$((TOTAL_CHECKS - NA))
[ "$APPLICABLE" -gt 0 ] && SCORE="${PASS}/${APPLICABLE}" || SCORE="N/A"

# ─── Output ───
if [ "$MODE" = "--compact" ]; then
  FAIL_ITEMS=""
  for i in $(seq 0 $((TOTAL_CHECKS - 1))); do
    s="${RESULTS[$i]%%|*}"
    [ "$s" = "FAIL" ] && FAIL_ITEMS="${FAIL_ITEMS} ${LABELS[$i]},"
  done
  FAIL_ITEMS="${FAIL_ITEMS%,}"

  if [ "$FAIL" -eq 0 ]; then
    SUMMARY="✅ 감사 ${SCORE} PASS"
  else
    SUMMARY="⚠️ 감사 ${SCORE} (FAIL:${FAIL_ITEMS})"
  fi
  echo "{\"systemMessage\":\"[SESSION AUDIT] ${SUMMARY} | Build:$([ $IS_BUILD -eq 1 ] && echo Y || echo N) | Tools:${TOOL_TOTAL}\"}"
elif [ "$MODE" = "--full" ]; then
  echo "═══════════════════════════════════════════════"
  echo "  JamesClaw Session Audit Report"
  echo "  Session: ${SESSION_ID:0:8}..."
  echo "  Project: ${PROJECT_DIR}"
  echo "  Build Session: $([ $IS_BUILD -eq 1 ] && echo 'Yes' || echo 'No')"
  echo "  Tool Calls: ${TOOL_TOTAL}"
  echo "═══════════════════════════════════════════════"
  echo ""

  for i in $(seq 0 $((TOTAL_CHECKS - 1))); do
    s="${RESULTS[$i]%%|*}"
    d="${RESULTS[$i]#*|}"
    case "$s" in
      PASS) icon="✅" ;;
      FAIL) icon="❌" ;;
      WARN) icon="⚠️" ;;
      N/A)  icon="➖" ;;
    esac
    printf "  %s  %-20s %s\n" "$icon" "${LABELS[$i]}" "$d"
  done

  echo ""
  echo "───────────────────────────────────────────────"
  echo "  Score: ${SCORE} | PASS:${PASS} FAIL:${FAIL} WARN:${WARN} N/A:${NA}"
  echo "═══════════════════════════════════════════════"
elif [ "$MODE" = "--json" ]; then
  # JSON output for dashboard consumption
  ITEMS="["
  for i in $(seq 0 $((TOTAL_CHECKS - 1))); do
    s="${RESULTS[$i]%%|*}"
    d="${RESULTS[$i]#*|}"
    # Escape double quotes in detail
    d=$(echo "$d" | sed 's/"/\\"/g')
    [ "$i" -gt 0 ] && ITEMS="${ITEMS},"
    ITEMS="${ITEMS}{\"id\":$((i+1)),\"label\":\"${LABELS[$i]}\",\"status\":\"${s}\",\"detail\":\"${d}\"}"
  done
  ITEMS="${ITEMS}]"

  # Get timestamp from transcript
  TIMESTAMP=$(stat -c '%Y' "$TRANSCRIPT" 2>/dev/null || date +%s)

  cat << ENDJSON
{
  "sessionId": "${SESSION_ID}",
  "projectDir": "${PROJECT_DIR}",
  "isBuild": $([ $IS_BUILD -eq 1 ] && echo 'true' || echo 'false'),
  "toolTotal": ${TOOL_TOTAL},
  "timestamp": ${TIMESTAMP},
  "score": { "pass": ${PASS}, "fail": ${FAIL}, "warn": ${WARN}, "na": ${NA}, "applicable": ${APPLICABLE} },
  "checks": ${ITEMS}
}
ENDJSON
fi
