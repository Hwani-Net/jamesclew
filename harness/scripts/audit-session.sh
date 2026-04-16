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
# 현재 체크 수: 33개 (2026-04-15)
# 마지막 업데이트: 2026-04-15 (check_precompact_block~check_model_sonnet_explicit 추가 — TODO 6개 구현)
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
#  25 check_gbrain_usage        — gbrain 검색/저장 사용
#  26 check_agent_teams_cleanup — Agent Teams 생성/삭제 균형
#  27 check_rule_impl_gap       — 규칙 파일 참조 hook/script 실제 존재 여부 (P-012)
#  28 check_precompact_block    — PreCompact hook exit 2 차단 로직 존재 여부
#  29 check_obsidian_save       — compact 전 Obsidian 세션 저장 순서 (P-007)
#  30 check_5h_emergency        — 5H 80%+ 감지 시 Sonnet 전환 절차
#  31 check_version_manual_sync — 버전 업데이트 시 harness-manual.md 동시 수정
#  32 check_design_review_vision — design-review Vision 호출 (Opus Vision)
#  33 check_model_sonnet_explicit — Agent() 호출 시 model: sonnet 명시 여부
#
# ─── 미구현 (TODO) ─────────────────────────────────────────────────────────
# (없음 — 모든 TODO 구현 완료 2026-04-15)
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
      # After Step 5: verify quality loop was done properly
      ROUNDS=$(safe_count "grep -c '라운드\|round\|Pass.*[1-5]' \"$TRANSCRIPT\"")
      if [ "$ROUNDS" -lt 4 ]; then
        echo "{\"systemMessage\":\"[🚫 CHECKPOINT 5 FAIL] 품질루프 증거 부족 (패턴 ${ROUNDS}건, 최소 4건 필요). 5패스 × 2라운드를 실제로 수행하세요. 완료 후: echo done > ${STATE_DIR}/step5_quality_done\"}"
      else
        echo "done" > "$STATE_DIR/step5_quality_done"
        echo "{\"systemMessage\":\"[✅ CHECKPOINT 5 PASS] 품질루프 ${ROUNDS}건 확인. step5_quality_done 생성됨.\"}"
      fi
      ;;
    7)
      # After Step 7: verify external model was ACTUALLY called
      GPT41=$(safe_count "grep -c 'localhost:4141\|gpt-4.1' \"$TRANSCRIPT\"")
      CODEX=$(safe_count "grep -c 'codex exec' \"$TRANSCRIPT\"")
      TOTAL=$((GPT41 + CODEX))
      if [ "$TOTAL" -lt 2 ]; then
        echo "{\"systemMessage\":\"[🚫 CHECKPOINT 7 FAIL — 1회차] 외부 모델 실제 호출 ${TOTAL}건 (최소 2건 필요: GPT-4.1 + codex). 지금 실행하세요:\\n1. curl -s http://localhost:4141/v1/chat/completions -d '{...}' 로 GPT-4.1 코드 리뷰\\n2. codex exec \\\"코드 리뷰 요청\\\"\\n완료 후: bash ~/.claude/scripts/audit-session.sh --checkpoint 7\"}"
      else
        echo "done" > "$STATE_DIR/step7_review_done"
        echo "{\"systemMessage\":\"[✅ CHECKPOINT 7 PASS] 외부 모델 ${TOTAL}건 (GPT41:${GPT41} CX:${CODEX}). step7_review_done 생성됨.\"}"
      fi
      ;;
    10)
      # After Step 10: verify full pipeline sequence integrity
      FAILS=""
      [ ! -f "$STATE_DIR/step5_quality_done" ] && FAILS="${FAILS} Step5(품질루프)"
      [ ! -f "$STATE_DIR/step7_review_done" ] && FAILS="${FAILS} Step7(외부검수)"
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

# ─── Build session detection ───
BUILD_KEYWORDS=$(safe_count "grep '\"type\":\"user\"' \"$TRANSCRIPT\" | grep -c '만들\|구현\|개발\|페이지로\|앱으로'")
IS_BUILD=0
[ "$BUILD_KEYWORDS" -gt 0 ] && IS_BUILD=1

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
  [ -f "$STATE_DIR/step5_quality_done" ] && echo "PASS|증거 파일 존재" && return
  local mentions=$(safe_count "grep -c '품질루프\|quality.*loop\|5패스\|5-pass' \"$TRANSCRIPT\"")
  [ "$mentions" -gt 3 ] && echo "WARN|패턴 ${mentions}건, 증거 파일 없음" && return
  echo "FAIL|품질루프 미실행"
}

check_external_review() {
  [ "$IS_BUILD" -eq 0 ] && echo "N/A|비빌드 세션" && return
  [ -f "$STATE_DIR/step7_review_done" ] && echo "PASS|증거 파일 존재" && return
  local ext=$(safe_count "grep -c 'localhost:4141\|gpt-4.1\|codex exec\|codex ' \"$TRANSCRIPT\"")
  [ "$ext" -gt 0 ] && echo "WARN|외부 모델 ${ext}건, 증거 파일 없음" && return
  echo "FAIL|외부 검수 0회"
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
  local gpt41=$(safe_count "grep -c 'localhost:4141\|gpt-4.1' \"$TRANSCRIPT\"")
  local codex=$(safe_count "grep -c 'codex exec\|codex ' \"$TRANSCRIPT\"")
  local gemini=$(safe_count "grep -c 'gemini ' \"$TRANSCRIPT\"")
  local total=$((gpt41 + codex + gemini))
  [ "$total" -ge 2 ] && echo "PASS|외부 모델 ${total}건 (GPT41:${gpt41} CX:${codex} GM:${gemini})" && return
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
  local screenshots=$(safe_count "grep -c 'screenshot\|deploy-desktop\|deploy-mobile\|스크린샷' \"$TRANSCRIPT\"")
  local read_img=$(safe_count "grep '\"name\":\"Read\"' \"$TRANSCRIPT\" | grep -c '\.png\|\.jpg\|screenshot'")
  local total=$((screenshots + read_img))
  [ "$total" -gt 0 ] && echo "PASS|스크린샷 검증 ${total}건" && return
  echo "FAIL|배포 후 스크린샷 검증 없음"
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
  # Check if opencode/antigravity references remain in HARNESS SOURCE CODE (not old transcripts)
  local harness_dir="$HOME/.claude"
  # Exclude self (audit-session.sh, evaluator.sh) to avoid self-reference false positives
  local source_refs=$(grep -rli "opencode\|antigravity" \
    "$harness_dir/CLAUDE.md" \
    "$harness_dir/hooks/"*.sh \
    "$harness_dir/scripts/"*.sh \
    "$harness_dir/rules/"*.md \
    2>/dev/null | grep -v "audit-session.sh" | grep -v "evaluator.sh" | wc -l)
  source_refs=$(echo "$source_refs" | tr -d '[:space:]')
  if [ "$source_refs" -gt 0 ]; then
    local files=$(grep -rli "opencode\|antigravity" \
      "$harness_dir/CLAUDE.md" \
      "$harness_dir/hooks/"*.sh \
      "$harness_dir/scripts/"*.sh \
      "$harness_dir/rules/"*.md \
      2>/dev/null | grep -v "audit-session.sh" | grep -v "evaluator.sh" | xargs -I{} basename {} | tr '\n' ', ')
    echo "FAIL|소스 코드에 opencode/antigravity 참조 ${source_refs}건: ${files}"
  else
    echo "PASS|소스 코드에 opencode/antigravity 참조 0건 (폐기 준수)"
  fi
}

# ─── Check 25: gbrain 자율 저장/검색 ───
check_gbrain_usage() {
  local gbrain_query=$(grep -ci "gbrain query\|gbrain search\|mcp__gbrain__query\|mcp__gbrain__search" "$TRANSCRIPT" 2>/dev/null || echo "0")
  local gbrain_put=$(grep -ci "gbrain put\|mcp__gbrain__put_page" "$TRANSCRIPT" 2>/dev/null || echo "0")
  if [ "$gbrain_query" -gt 0 ] || [ "$gbrain_put" -gt 0 ]; then
    echo "PASS|검색 ${gbrain_query}건, 저장 ${gbrain_put}건"
  else
    echo "WARN|gbrain 사용 0건 — Search-Before-Solve에서 gbrain query 미사용"
  fi
}

# ─── Check 27: Rule→Implementation Gap (P-012) ───
check_rule_impl_gap() {
  local hooks_dir="$HOME/.claude/hooks"
  local scripts_dir="$HOME/.claude/scripts"
  local rules_dir="$HOME/.claude/rules"
  local claude_md="$HOME/.claude/CLAUDE.md"

  # Extract literal filenames (*.sh, *.ts, *.js) from rule files
  # Uses grep -oE to capture only the filename token; excludes lines that are comments (#)
  # Exclude known non-hook/non-script filenames (general references, config files, build artifacts)
  local EXCLUDE_PATTERN="^(deploy\.sh|index\.js|settings\.js|api_cost_log\.js|package\.json|tsconfig\.js|firebase\.js|server\.js|app\.js|main\.js|config\.js|setup\.js|build\.js)$"
  local referenced_files
  referenced_files=$(
    {
      grep -oE '[a-z][a-z0-9_-]+\.(sh|ts|js)' "$claude_md" 2>/dev/null
      for f in "$rules_dir"/*.md; do
        [ -f "$f" ] && grep -oE '[a-z][a-z0-9_-]+\.(sh|ts|js)' "$f" 2>/dev/null
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
    if [ -f "$hooks_dir/$fname" ] || [ -f "$scripts_dir/$fname" ]; then
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
  # Check if harness-manual.md was also modified
  local manual_edit=$(safe_count "grep '\"name\":\"Write\"\|\"name\":\"Edit\"' \"$TRANSCRIPT\" | grep -c 'harness-manual\.md'")
  [ "$manual_edit" -gt 0 ] && echo "PASS|버전 언급 ${version_mention}건, 매뉴얼 수정 ${manual_edit}건" && return
  echo "WARN|버전 언급 ${version_mention}건, harness-manual.md 수정 0건"
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
R25=$(check_gbrain_usage)
R26=$(check_agent_teams_cleanup)
R27=$(check_rule_impl_gap)
R28=$(check_precompact_block)
R29=$(check_obsidian_save)
R30=$(check_5h_emergency)
R31=$(check_version_manual_sync)
R32=$(check_design_review_vision)
R33=$(check_model_sonnet_explicit)

LABELS=("Build Transition" "PRD" "Pipeline Install" "Quality Loop" "External Review" "Deploy Verify" "TodoWrite" "Ghost Mode" "Evidence-First" "Telegram Result" "No Impossibility" "Multi-Pass Review" "PITFALLS Record" "Conventional Commit" "Harness Location" "Error Retry" "Design Reference" "External Model Call" "Tool Priority" "Cost Logging" "Search-Before-Solve" "Screenshot Verify" "Pipeline Loop" "No Antigravity" "gbrain Usage" "Agent Teams Cleanup" "Rule Impl Gap" "PreCompact Block" "Obsidian Save" "5H Emergency" "Version Manual Sync" "Design Review Vision" "Model Sonnet Explicit")
RESULTS=("$R1" "$R2" "$R3" "$R4" "$R5" "$R6" "$R7" "$R8" "$R9" "$R10" "$R11" "$R12" "$R13" "$R14" "$R15" "$R16" "$R17" "$R18" "$R19" "$R20" "$R21" "$R22" "$R23" "$R24" "$R25" "$R26" "$R27" "$R28" "$R29" "$R30" "$R31" "$R32" "$R33")

TOTAL_CHECKS=33

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
