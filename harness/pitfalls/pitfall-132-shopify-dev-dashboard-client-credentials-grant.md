---
slug: pitfall-132-shopify-dev-dashboard-client-credentials-grant
title: "Shopify Dev Dashboard 앱은 atkn_/shpat_ 직접 사용 X — client credentials grant로 24h access_token 교환 필수"
date: 2026-05-08
tags: [shopify, oauth, authentication, dev-dashboard, client-credentials]
severity: high
related: [pitfall-131-korean-ui-english-menu-mismatch]
---

## 증상
Shopify Custom App에서 발급받은 토큰(`atkn_...` 또는 `shpat_...`)을 `X-Shopify-Access-Token` 헤더에 직접 넣어 Admin API 호출 → HTTP 401:

```
{"errors":"[API] Invalid API key or access token (unrecognized login or wrong password)"}
```

## 원인
2026년 1월 1일부로 Shopify가 **Custom App UI deprecated**, Dev Dashboard로 마이그레이션. 인증 방식 근본 변경:

| 방식 | 토큰 prefix | 발급 위치 | 사용 |
|---|---|---|---|
| **레거시 Custom App** | `shpat_...` | Admin → Apps → Develop apps → Install app → API credentials | X-Shopify-Access-Token 헤더 직접 |
| **Dev Dashboard 앱 (현재)** | (UI에 토큰 없음) | client_id + client_secret을 token endpoint에서 exchange | 24h 짜리 access_token을 X-Shopify-Access-Token 헤더 |
| **App Automation Token** | `atkn_...` | Dev Dashboard → 설정 → 앱 자동화 토큰 | **CI/CD 별개 용도** — Admin API 직접 호출 X |

`atkn_` prefix는 자동화/배포 파이프라인 용 토큰이고 Admin API 직접 호출에 사용 불가. 잘못 사용하면 401.

## 해결 — Client Credentials Grant
```python
# 1) access_token 교환
POST https://{shop}.myshopify.com/admin/oauth/access_token
Content-Type: application/x-www-form-urlencoded
grant_type=client_credentials&client_id={CLIENT_ID}&client_secret={CLIENT_SECRET}

# 응답
{"access_token": "...", "token_type": "Bearer", "expires_in": 86400}

# 2) 받은 access_token으로 Admin API 호출
GET https://{shop}.myshopify.com/admin/api/2026-04/shop.json
X-Shopify-Access-Token: {access_token}
```

토큰 24h 유효 → 만료 5분 전 캐시 갱신 패턴 권장.

**제약**: client credentials grant는 앱과 store가 같은 Shopify Organization에 있어야 동작.

## 필요한 값
| 키 | 출처 |
|---|---|
| `SHOPIFY_STORE_DOMAIN` | `*.myshopify.com` |
| `SHOPIFY_CLIENT_ID` | Dev Dashboard → 앱 → 설정 → 자격 증명 → 클라이언트 ID |
| `SHOPIFY_CLIENT_SECRET` | Dev Dashboard → 앱 → 설정 → 자격 증명 → 암호 [👁 표시] (`shpss_` prefix) |

## 재발 방지
- Shopify 도구 작성 시: `SHOPIFY_APP_AUTOMATION_TOKEN`(`atkn_`)을 X-Shopify-Access-Token에 사용 금지
- `client_id + client_secret` 보유 → access_token broker 함수(`get_access_token()`) 통해서만 호출
- Dev Dashboard로 이관된 SaaS는 인증 흐름이 client credentials grant로 바뀌었을 가능성 항상 의심
- 토큰 prefix로 종류 식별: `shpat_`(레거시), `shpss_`(client secret), `atkn_`(automation), `shpca_`(custom)

## 관련 사례 (2026-05-08)
- Connect AI shopify 에이전트 첫 셋업에서 `atkn_` 토큰 직접 사용 → 401 fail
- shopify_account.py에 client credentials grant flow + 24h cache 추가 후 즉시 통과
- PawTech Store(rmaszz-d0.myshopify.com) shop.json 핑 OK, product_list 200 OK
