---
title: P-108 카탈로그 0순위 망각 — 결제/마케팅 디테일로 선이탈
date: 2026-05-04
project: AI_Programing/Shopify
type: pitfall
tags: [sequence_violation, premature_optimization, catalog_first]
---

# P-108: 카탈로그 단계 미완성에 결제/마케팅 단계로 선이탈

## 증상
rmaszz-d0 매출 0인 상태에서 대표님께 "Q1 결제 PG 블로커, Q2 Klaviyo/TikTok 우선순위, Q3 cron 자산 처리"를 결정 게이트로 제시. 대표님 지적: "제일 중요한게 뭐야? 상품 추가해서 판매할 수 있는 상황을 만드는 게 가장 중요한 거 아니야?"

검증: Shopify Admin API `/products/count.json` 호출 결과 — **active 1개, draft 13개, archived 0개**. 판매 가능 상품 1개가 매출 0의 진짜 원인. 결제 PG·이메일 마케팅·트래픽 자동화 전부 후순위.

## 원인
1. memory `project_direction.md`에 **"카탈로그 → 트래픽 → 전환 순서"**가 명시되어 있었으나 researcher 결과에 휘둘려 트래픽/전환 단계 항목으로 결정 게이트 구성
2. 제안 전 `products/count.json` (active 기준) 단순 검증을 하지 않음 — 1회 curl이면 끝났던 사실
3. researcher가 "Klaviyo 무료 연동"·"TikTok Shop"을 우선순위 1·2로 제시했고 이를 그대로 옮김. researcher의 권고가 카탈로그 검증 없이 후속 단계로 점프한 것을 검증하지 않음

## 해결 (2026-05-04 적용)
Shopify 프로젝트 모든 제안 전 의무 체크:
1. `curl -H "X-Shopify-Access-Token: $TOKEN" "https://$SHOP/admin/api/2026-04/products/count.json?status=active"` 호출
2. active < 5 → **카탈로그 단계 외 어떤 제안도 차단**. 결제/광고/이메일/SEO/CRO 모두 후순위
3. active >= 5 + 주문 0 → 트래픽 단계 진입 가능
4. 주문 >= 1 → 전환 단계 진입 가능

## 재발 방지
- 트리거 키워드 감지 시 자동 검증 모드:
  - "결제", "PG", "Klaviyo", "TikTok", "광고", "Meta CAPI", "ROAS", "이메일 자동화", "SEO" → active 제품 수 우선 확인
- researcher 위임 프롬프트에 "현재 active 제품 수 = N개. N < 5면 카탈로그 단계 권고만 반환할 것" 명시
- 결정 게이트 제시 전 self-challenge: "이 제안이 매출 0 → 1원의 가장 짧은 경로인가?"

## 누적 패턴
- premature_conclusion: 12회 + 2회(P-107, P-108) = 14회
- sequence_violation: 신규 카운트 시작
- 같은 세션에서 P-107(researcher 무비판 전달) + P-108(순서 위반) 연속 발생 — researcher 결과를 결정 게이트로 옮길 때 이중 검증 필수

## 관련 PITFALL
- P-107 (researcher 무비판 전달) — 같은 세션, 동일 뿌리(researcher 결과 검증 부재)
- 메모리 `project_direction.md` (10일 전, 카탈로그 → 트래픽 → 전환) — 명시된 규칙을 어김
