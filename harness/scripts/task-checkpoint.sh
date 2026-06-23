#!/usr/bin/env bash
# task-checkpoint.sh — 장기작업 스텝 체크포인트/재개 프리미티브 (rules/durable-execution.md)
# PASS 스텝은 불변(Reins P-256): 재개 시 재실행하지 않는다. 순수 bash + coreutils, 의존성 0.
#
# 사용:
#   task-checkpoint.sh init <id> "<goal>" "step1,step2,step3"
#   task-checkpoint.sh step-done <id> <N> <name> <PASS|FAIL> ["state요약"]
#   task-checkpoint.sh resume-point <id>     # -> "N:이름" | DONE | NO_TASK
#   task-checkpoint.sh status <id>           # -> "x/total done, cursor=N"
set -euo pipefail
ROOT="${HARNESS_STATE:-$HOME/.harness-state}/tasks"
cmd="${1:-}"; id="${2:-}"; dir="$ROOT/$id"

case "$cmd" in
  init)
    mkdir -p "$dir"
    printf '%s\n' "${3:-}" > "$dir/goal.txt"
    printf '%s' "${4:-}" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' > "$dir/steps.txt"
    echo 0 > "$dir/cursor"
    echo "init $id ($(wc -l < "$dir/steps.txt" | tr -d ' ') steps, cursor=0)"
    ;;
  step-done)
    n="${3:?need step index N}"; name="${4:-}"; st="${5:-PASS}"
    mkdir -p "$dir"
    printf 'status=%s\nname=%s\nts=%s\nstate=%s\n' "$st" "$name" "$(date -Iseconds 2>/dev/null || date)" "${6:-}" > "$dir/step-$n.done"
    if [ "$st" = "PASS" ]; then
      cur="$(cat "$dir/cursor" 2>/dev/null || echo 0)"
      [ "$((n+1))" -gt "$cur" ] && echo "$((n+1))" > "$dir/cursor"
      echo "step $n PASS -> cursor=$(cat "$dir/cursor")"
    else
      echo "step $n FAIL (cursor 불변, 재개 시 이 스텝부터 재시도)"
    fi
    ;;
  resume-point)
    [ -f "$dir/cursor" ] || { echo "NO_TASK"; exit 0; }
    cur="$(cat "$dir/cursor")"
    name="$(sed -n "$((cur+1))p" "$dir/steps.txt" 2>/dev/null || true)"
    if [ -z "$name" ]; then echo "DONE"; else echo "$cur:$name"; fi
    ;;
  status)
    [ -f "$dir/cursor" ] || { echo "NO_TASK"; exit 0; }
    done_n="$(ls "$dir"/step-*.done 2>/dev/null | wc -l | tr -d ' ')"
    total="$(wc -l < "$dir/steps.txt" 2>/dev/null | tr -d ' ')"
    echo "$done_n/$total done, cursor=$(cat "$dir/cursor")"
    ;;
  get-state)
    # 완료 스텝의 저장된 state(재개 핸들) 회수 — 재개가 위치뿐 아니라 작업을 잇도록
    [ -d "$dir" ] || { echo "NO_TASK"; exit 0; }
    if [ -n "${3:-}" ]; then
      cat "$dir/step-${3}.done" 2>/dev/null || echo "NO_STEP $3"
    else
      for f in "$dir"/step-*.done; do [ -f "$f" ] && { echo "== $(basename "$f") =="; cat "$f"; }; done
    fi
    ;;
  *)
    echo "usage: task-checkpoint.sh init|step-done|resume-point|status|get-state <id> [N]" >&2
    exit 1
    ;;
esac
