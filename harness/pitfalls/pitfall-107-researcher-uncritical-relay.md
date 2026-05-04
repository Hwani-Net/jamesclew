---
title: P-107 researcher 결과를 교차검증 없이 결정 게이트로 전달
date: 2026-05-03
project: AI_Programing/Shopify
type: pitfall
tags: [research, verification, premature_conclusion]
---

# P-107: researcher 결과를 교차검증 없이 결정 게이트로 전달

## 증상
researcher 서브에이전트가 "Shopify Payments 한국 미지원 → 홍콩/싱가포르 법인 설립 필요"라고 보고. Opus가 이를 그대로 받아 대표님께 "Q1: 결제 블로커 — 해외 법인 결정 필요"로 결정 게이트 제시. 대표님 지적 "해외 법인 없이도 가능하다는 말이 있는데 왜 이래?" 후 Tavily 직접 검색으로 사실 정정.

## 원인
1. researcher 결과의 **결정적 항목(블로커/법적/결제)**을 코드/공식 문서로 교차 검증하지 않음
2. "Shopify Payments 미지원" = "Shopify 결제 불가"로 의미 비약 (Eximbay/포트원/Stripe+EasyPie/PayPal 다수 우회 경로 존재 확인)
3. researcher 결과를 "검증된 데이터"로 라벨링했으나 실제로는 1차 출처 검증이 부재

## 해결 (2026-05-03 적용)
1. researcher 결과 중 **블로커/금지/불가 단정**이 포함된 항목은 즉시 Tavily/Perplexity로 1차 출처 확인
2. 출처가 영문 위주이면 한국어 출처(공식 PG사, 한국 블로그)도 병행
3. 대표님께 결정 게이트로 올리기 전에 "이 블로커가 실제 블로커인지" self-challenge 1회 의무

## 검증된 사실 (정정)
| 결제 옵션 | 한국 사업자 가능 | 출처 |
|----------|--------------|------|
| Shopify Payments | ❌ | help.shopify.com/ko/manual/payments/shopify-payments/supported-countries |
| Eximbay (Shopify 공식 파트너) | ✅ | support.eximbay.com, blog.naver.com/eximbay |
| 포트원 (PortOne) | ✅ | blog.portone.io/shopify_portone_payment_plugin/ — 글 제목 "해외법인 없이도 쇼피파이 결제 연동하는 팁" |
| Stripe + EasyPie | ✅ | blog.easypie.shop |
| PayPal | ✅ | Shopify 기본 통합 |

## 재발 방지
- researcher 프롬프트에 "각 단정 항목에 대해 반대 증거를 찾아보고 명시할 것" 추가
- 결정 게이트 제시 전 "self-challenge 1회 + Tavily 1회" 체크리스트
- 한국 시장 항목은 **반드시 한국어 1차 출처 1개 이상** 확보
- 트리거 키워드: "블로커", "불가능", "필요(설립/가입/허가)", "법적", "한국 미지원" 발견 시 자동 검증 모드

## 관련 PITFALL
- P-086 (검증 완료 + 가역적 = 묻지 말고 실행) — 이번은 반대 케이스 (검증 미완료에 결정 게이트 올림)
- premature_conclusion 패턴 누적 12회 + 1 = 13회
