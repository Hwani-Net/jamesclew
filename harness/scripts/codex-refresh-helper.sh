#!/usr/bin/env bash
# codex-refresh-helper.sh — Codex 6계정 토큰 갱신 보조 스크립트
# Usage:
#   bash codex-refresh-helper.sh check          # 만료 여부만 확인
#   bash codex-refresh-helper.sh prepare N      # 계정 N 갱신 준비 (rm auth)
#   bash codex-refresh-helper.sh save N         # 계정 N OAuth 후 저장 (cp)
#   bash codex-refresh-helper.sh verify         # 6계정 rotate ping 검증
# PITFALL: codex logout 절대 사용 금지 (서버 OAuth revoke로 백업본 무효화).
#          rm ~/.codex/auth.json 만 사용. 참조: pitfall-069.

set -euo pipefail

ACCOUNTS_DIR="$HOME/.codex-accounts"
AUTH="$HOME/.codex/auth.json"
ROTATE="D:/jamesclew/harness/scripts/codex-rotate.sh"
CMD="${1:-help}"
N="${2:-}"

case "$CMD" in
  check)
    echo "=== Codex 만료 감지 ==="
    OUT=$(codex exec "say ping" 2>&1 | head -5)
    if echo "$OUT" | grep -qE "401|invalid_request|refresh token has already been used|signing in again"; then
      echo "EXPIRED — 갱신 필요"
      echo "  현재 auth.json mtime: $(stat -c '%y' "$AUTH" 2>/dev/null || echo 'absent')"
      echo "  account 백업 mtime  : $(stat -c '%y' "$ACCOUNTS_DIR/account1.json" 2>/dev/null || echo 'absent')"
      exit 1
    fi
    echo "OK — 토큰 유효"
    exit 0
    ;;

  prepare)
    [ -z "$N" ] && { echo "Usage: prepare <1-6>" >&2; exit 2; }
    [[ "$N" =~ ^[1-7]$ ]] || { echo "ERROR: N must be 1-7" >&2; exit 2; }
    echo "=== 계정 $N 갱신 준비 ==="
    if [ -f "$AUTH" ]; then
      rm "$AUTH"
      echo "rm $AUTH (logout 사용 안 함 — 서버 revoke 회피)"
    fi
    echo ""
    echo "다음 명령을 직접 실행하세요:"
    echo "  codex login"
    echo "(브라우저가 열리면 ChatGPT 계정 $N 으로 로그인 후 승인)"
    echo ""
    echo "OAuth 완료 후 다음 명령으로 백업 저장:"
    echo "  bash $0 save $N"
    ;;

  save)
    [ -z "$N" ] && { echo "Usage: save <1-6>" >&2; exit 2; }
    [[ "$N" =~ ^[1-7]$ ]] || { echo "ERROR: N must be 1-7" >&2; exit 2; }
    [ ! -f "$AUTH" ] && { echo "ERROR: $AUTH 없음. 먼저 codex login 실행." >&2; exit 1; }
    OUT=$(codex exec "say ping" 2>&1 | head -3)
    if echo "$OUT" | grep -qE "401|invalid_request"; then
      echo "ERROR: 새 토큰도 401. codex login 다시 시도 필요." >&2
      exit 1
    fi
    mkdir -p "$ACCOUNTS_DIR"
    cp "$AUTH" "$ACCOUNTS_DIR/account$N.json"
    echo "✅ 계정 $N 저장: $ACCOUNTS_DIR/account$N.json ($(stat -c '%s' "$ACCOUNTS_DIR/account$N.json")B)"
    echo ""
    NEXT=$((N + 1))
    if [ "$NEXT" -le 7 ]; then
      echo "다음 계정: bash $0 prepare $NEXT"
    else
      echo "🎉 7계정 갱신 완료. 검증: bash $0 verify"
    fi
    ;;

  verify)
    echo "=== 7계정 rotate ping 검증 ==="
    PASS=0
    FAIL=0
    for i in 1 2 3 4 5 6 7; do
      ACCT="$ACCOUNTS_DIR/account$i.json"
      [ ! -f "$ACCT" ] && { echo "  account$i: MISSING"; FAIL=$((FAIL+1)); continue; }
      cp "$ACCT" "$AUTH"
      OUT=$(codex exec "say pong" 2>&1 | head -3)
      if echo "$OUT" | grep -qE "401|invalid_request"; then
        echo "  account$i: FAIL (401)"
        FAIL=$((FAIL+1))
      else
        echo "  account$i: PASS"
        PASS=$((PASS+1))
      fi
    done
    echo ""
    echo "결과: PASS $PASS / FAIL $FAIL"
    [ "$FAIL" -eq 0 ] && exit 0 || exit 1
    ;;

  help|*)
    cat <<EOF
codex-refresh-helper.sh — Codex 6계정 갱신 보조

명령:
  check         만료 여부 확인 (exit 1 = 만료)
  prepare N     계정 N 갱신 준비 (1-6) — rm auth.json
  save N        OAuth 후 백업 저장 — cp auth.json → account\$N.json
  verify        6계정 rotate ping 검증

순서: prepare 1 → codex login → save 1 → prepare 2 → codex login → save 2 → ... → verify

PITFALL: codex logout 사용 금지 (서버 토큰 revoke). rm만 사용.
참조: D:/jamesclew/harness/pitfalls/pitfall-069-codex-logout-revokes-server-token.md
EOF
    ;;
esac
