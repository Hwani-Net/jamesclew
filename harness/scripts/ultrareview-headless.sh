#!/bin/bash
# ultrareview-headless.sh — Non-interactive ultrareview wrapper (2026-05-07 신설)
#
# Claude Code v2.1.120+의 `claude ultrareview [target]` CLI 서브커맨드를 래핑.
# CI/scripts/Remote agent에서 PR 또는 현재 브랜치 리뷰를 자동 실행.
# 결과를 JSON으로 저장하여 후속 자동 분석/PITFALL 기록에 활용.
#
# 사용법:
#   ./ultrareview-headless.sh                 # 현재 브랜치 리뷰
#   ./ultrareview-headless.sh 123             # PR #123 리뷰
#   ./ultrareview-headless.sh https://github.com/owner/repo/pull/123
#   ./ultrareview-headless.sh --out result.json
#
# ⚠️ /ultrareview는 체험권 3회 후 과금. 자동화 호출 빈도 주의.
# 기본 외부 검수는 무료 모델(Codex + GPT-4.1) 사용. 본 스크립트는 예산 여유 시에만.

set -euo pipefail

TARGET=""
OUT_FILE=""
EXTRA_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --out)
      OUT_FILE="$2"
      shift 2
      ;;
    --out=*)
      OUT_FILE="${1#--out=}"
      shift
      ;;
    --help|-h)
      head -25 "$0" | grep -E "^#" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$1"
      else
        EXTRA_ARGS+=("$1")
      fi
      shift
      ;;
  esac
done

if ! command -v claude >/dev/null 2>&1; then
  echo "[ultrareview-headless] claude CLI not found in PATH" >&2
  exit 127
fi

VER=$(claude --version 2>/dev/null | head -1 | awk '{print $1}')
case "$VER" in
  2.1.12[0-9]|2.1.13[0-9]|2.1.1[4-9][0-9]|2.[2-9].*|[3-9].*) ;;
  *)
    echo "[ultrareview-headless] requires Claude Code v2.1.120+. Found: $VER" >&2
    exit 1
    ;;
esac

# Build command — JSON output to stdout for capture
CMD=(claude ultrareview)
[ -n "$TARGET" ] && CMD+=("$TARGET")
CMD+=(--json)
[ ${#EXTRA_ARGS[@]} -gt 0 ] && CMD+=("${EXTRA_ARGS[@]}")

echo "[ultrareview-headless] invoking: ${CMD[*]}" >&2

if [ -n "$OUT_FILE" ]; then
  if "${CMD[@]}" > "$OUT_FILE" 2>/dev/null; then
    echo "[ultrareview-headless] saved JSON → $OUT_FILE" >&2
    echo "$OUT_FILE"
    exit 0
  else
    echo "[ultrareview-headless] ultrareview failed (exit non-zero)" >&2
    exit 2
  fi
else
  "${CMD[@]}"
  exit $?
fi
