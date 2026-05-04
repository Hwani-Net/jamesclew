---
title: P-109 표준 SaaS/앱 비교 없이 자체 빌드 선택
date: 2026-05-04
project: AI_Programing/Shopify
type: pitfall
tags: [premature_engineering, vendor_compare_skipped, custom_build]
---

# P-109: 표준 SaaS/앱 비교 없이 자체 빌드 선택 (3-6개월 과투자)

## 증상
rmaszz-d0 Shopify 드랍쉬핑 자동화를 위해 Next.js 대시보드 + Vercel cron 7개 + 자동화 스크립트 10개 + DSers MCP를 자체 구현. 그러나 표준 경로는 "Shopify 앱 마켓플레이스에서 DSers 앱 클릭 1번"이며 재고/주문/import 모두 앱 1개가 처리. 대표님 지적: "다른데도 이렇게 어렵게 진행해?" 후 벤치마크 결과 — 인프라는 표준 대비 3-6개월 앞섰지만 매출 만드는 트래픽(TikTok/Email/Ads)은 0%.

## 원인
1. 신규 자동화 영역 진입 시 "표준 Shopify 앱이 이미 존재하는가?"를 확인 안 함
2. "코드로 만들면 더 잘 된다" 가정 (vendor lock-in 회피 명분이지만 실제는 표준 앱 무료 플랜으로 충분)
3. 대표님 메모리에 "벤치마킹: 돈 벌어주는 스파미"가 명시되어 있었으나 스파미 실제 운영 모델(코드 0, 앱 1개)을 검증하지 않음
4. researcher 권고를 "Shopify 앱 우선 검토"로 프롬프트에 넣지 않음

## 해결 (2026-05-04 적용)
신규 자동화 작업 진입 전 의무 체크리스트:
1. Shopify 앱 마켓플레이스에서 동일 기능 앱 검색 (앱이 있으면 자체 빌드 금지)
2. 한국/글로벌 벤치마크 채널 1개 이상 운영 모델 확인 (스파미/글로벌로드/dropshiplifestyle)
3. 자체 빌드 정당화 사유 3개 명시 (앱 부재 / 차별화 / 비용) — 부족하면 자체 빌드 금지
4. researcher 위임 시 "Shopify 앱 vs 자체 빌드 비교" 항목 명시적 요구

## 검증된 사실 (2026-05 표준 스택)
| 카테고리 | 표준 앱 | 가격 |
|---------|---------|------|
| 공급자/주문처리 | DSers (AliExpress 공식) | 무료 |
| 리뷰 | Loox / Judge.me | $5-15/월 |
| 이메일 | Klaviyo / Shopify Email | 무료 시작 |
| 전환 최적화 | Vitals (40 앱 통합) | $29.99/월 |

표준 1주차 워크플로우: 니치 → Dawn 무료 테마 → DSers 앱 import → TikTok 영상 → $5-10/일 광고. 코드 0줄.

## 재발 방지
- 트리거 키워드: "자동화 만들기", "cron 추가", "API 연동" 감지 시 "표준 앱 있나?" 자동 확인 모드
- Shopify 프로젝트 전용 hook 후보: PRD 작성 단계에서 Shopify 앱 마켓플레이스 검색 결과 첨부 강제
- 자체 빌드 사유에 "vendor lock-in 회피" 단독 사용 금지 (구체적 차별화 가치 없으면 무효 사유)

## 누적 패턴
- premature_engineering: 신규 (이번 첫 기록)
- 같은 세션 P-107(researcher 무비판) + P-108(순서 위반) + P-109(자체 빌드) 연쇄 — 모두 "검증 단계 생략"이 공통 뿌리
- 통합 슬러그 후보: "skip-verification-cascade" (이번 세션에서 3건 발생)

## 관련
- P-107 researcher uncritical relay
- P-108 sequence violation (catalog before payment)
- 메모리 `project_direction.md` (스파미 벤치마크 명시됨)
