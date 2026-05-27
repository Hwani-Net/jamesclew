#!/bin/bash
# DEPRECATED 2026-05-19 (P-172): gbrain 폐기. 이 스크립트는 실행하지 마십시오. 역사 참조용 보존.
# 일회성 헬퍼: .env-keys → gbrain config (키 노출 차단)
# 사용 후 삭제 권장. 단독 실행만, 다른 hook 의존성 없음.
set -e

KEY_FILE="${1:-D:/jamesclew/.env-keys}"
if [ ! -f "$KEY_FILE" ]; then
  echo "ERROR: $KEY_FILE not found" >&2
  exit 1
fi

KEY=$(grep '^OPENAI_API_KEY=' "$KEY_FILE" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'" | tr -d '\r')
if [ -z "$KEY" ]; then
  echo "ERROR: OPENAI_API_KEY empty in $KEY_FILE" >&2
  exit 1
fi
case "$KEY" in
  sk-*) echo "format OK (sk-prefix, length=${#KEY})";;
  *) echo "ERROR: unexpected key format" >&2; exit 1;;
esac

# 영구 저장 — stdout/stderr 모두 차단 (P-leak 재발 방지)
gbrain config set openai_api_key "$KEY" > /dev/null 2>&1
echo "gbrain config set: exit=$?"

# 마스킹 검증
gbrain config show 2>&1 | grep -E "openai_api_key|engine" | head -3

# 키 유효성 (HTTP code만)
export OPENAI_API_KEY="$KEY"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
  https://api.openai.com/v1/embeddings \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"text-embedding-3-small","input":"test"}')
echo "OpenAI embeddings HTTP: $HTTP  (200=OK, 401=auth, 429=quota)"
