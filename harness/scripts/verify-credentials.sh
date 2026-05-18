#!/bin/bash
# Credential verification script
# Usage: bash D:/jamesclew/harness/scripts/verify-credentials.sh
# Loads keys from D:/jamesclew/.env-keys and tests each service.

ENV_FILE="${1:-D:/jamesclew/.env-keys}"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env-keys not found: $ENV_FILE"
    exit 1
fi

set -a
source "$ENV_FILE" 2>/dev/null
set +a

echo "=== Credential Verification ($(date '+%Y-%m-%d %H:%M')) ==="
echo

check() {
    local name="$1"
    local code="$2"
    local expected="${3:-200}"
    if [ -z "$code" ] || [ "$code" = "000" ]; then
        echo "  ⚠️  $name: NETWORK ERROR (no response)"
    elif [ "$code" = "$expected" ]; then
        echo "  ✅ $name: OK ($code)"
    elif [ "$code" = "401" ] || [ "$code" = "403" ]; then
        echo "  ❌ $name: AUTH FAIL ($code) — key invalid or expired"
    else
        echo "  ⚠️  $name: UNEXPECTED ($code, expected $expected)"
    fi
}

# 1. Shopify
echo "[1] Shopify Admin API"
if [ -n "$SHOPIFY_ACCESS_TOKEN" ] && [ -n "$SHOPIFY_STORE_DOMAIN" ]; then
    VER="${SHOPIFY_API_VERSION:-2026-04}"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        "https://${SHOPIFY_STORE_DOMAIN}/admin/api/${VER}/shop.json" \
        -H "X-Shopify-Access-Token: ${SHOPIFY_ACCESS_TOKEN}")
    check "shop.json" "$code"
else
    echo "  ⏸  SKIP: SHOPIFY_ACCESS_TOKEN or SHOPIFY_STORE_DOMAIN not set"
fi
echo

# 2. mem0
echo "[2] mem0 API"
if [ -n "$MEM0_API_KEY" ]; then
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        "https://api.mem0.ai/v1/memories/?user_id=${MEM0_USER_ID:-jamesclaw}&limit=1" \
        -H "Authorization: Token ${MEM0_API_KEY}")
    check "memories list" "$code"
else
    echo "  ⏸  SKIP: MEM0_API_KEY not set"
fi
echo

# 3. Klaviyo
echo "[3] Klaviyo"
if [ -n "$KLAVIYO_PRIVATE_API_KEY" ]; then
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        "https://a.klaviyo.com/api/lists/" \
        -H "Authorization: Klaviyo-API-Key ${KLAVIYO_PRIVATE_API_KEY}" \
        -H "revision: 2024-10-15")
    check "lists" "$code"
else
    echo "  ⏸  SKIP: KLAVIYO_PRIVATE_API_KEY not set"
fi
echo

# 4. GA4 Measurement Protocol
echo "[4] GA4 Measurement Protocol"
if [ -n "$GA4_MEASUREMENT_ID" ] && [ -n "$GA4_API_SECRET" ]; then
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        -X POST "https://www.google-analytics.com/mp/collect?measurement_id=${GA4_MEASUREMENT_ID}&api_secret=${GA4_API_SECRET}" \
        -H "Content-Type: application/json" \
        -d '{"client_id":"verify_test","events":[{"name":"verify","params":{}}]}')
    check "collect" "$code" "204"
else
    echo "  ⏸  SKIP: GA4 keys not set"
fi
echo

# 5. Naver Developers (existing key check)
echo "[5] Naver Developers API"
if [ -n "$NAVER_CLIENT_ID" ] && [ -n "$NAVER_CLIENT_SECRET" ]; then
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        "https://openapi.naver.com/v1/search/blog.json?query=test&display=1" \
        -H "X-Naver-Client-Id: ${NAVER_CLIENT_ID}" \
        -H "X-Naver-Client-Secret: ${NAVER_CLIENT_SECRET}")
    check "blog search" "$code"
else
    echo "  ⏸  SKIP: NAVER credentials not set"
fi
echo

# 6. OpenAI Direct (이미 검증됨, 안전성 확인용)
echo "[6] OpenAI Direct API"
if [ -n "$OPENAI_API_KEY" ]; then
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        "https://api.openai.com/v1/models" \
        -H "Authorization: Bearer ${OPENAI_API_KEY}")
    check "models list" "$code"
else
    echo "  ⏸  SKIP: OPENAI_API_KEY not set"
fi
echo

# 7. Anthropic API (어댑터 우회 사용 중이지만 키 자체 검증)
echo "[7] Anthropic API (key validity)"
if [ -n "$ANTHROPIC_API_KEY" ]; then
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        "https://api.anthropic.com/v1/messages" \
        -X POST \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d '{"model":"claude-haiku-4-5","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}')
    check "messages" "$code"
    if [ "$code" = "400" ]; then
        echo "      (note: 400 means key valid but request rejected — check credit balance)"
    fi
else
    echo "  ⏸  SKIP: ANTHROPIC_API_KEY not set"
fi
echo

echo "=== Done ==="
