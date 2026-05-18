---
slug: pitfall-131-korean-ui-english-menu-mismatch
title: "한국어 UI 사용자에게 영문 메뉴명·deprecated 경로 안내로 매칭 실패"
date: 2026-05-08
tags: [ux, korean, navigation, shopify]
severity: medium
---

## 증상
Jamesclew가 사용자(한국어 UI)에게 화면 조작 절차를 안내할 때 영문 메뉴명("Settings → Apps and sales channels → Develop apps")으로 적어 매칭 실패. 또한 메뉴 자체가 deprecated된 옛 경로라 현재 UI에 존재하지 않음.

## 원인
1. 학습 데이터의 영문 문서가 우선 떠올라 메뉴명을 그대로 인용
2. 한국어 UI 사용자가 받는 화면 텍스트는 한국어(예: "앱", "앱 개발")
3. SaaS 제품(Shopify 등)의 메뉴 구조·이름이 자주 마이그레이션됨 → 학습 데이터의 경로가 현재 UI에 없음
4. 추측 안내 후 검증하지 않고 그대로 보고

## 해결
- 사용자가 한국어 UI 사용 중이면 **항상 한국어 메뉴명**으로 안내
- 정확한 라벨을 모르면: "스크린샷 한 번 더 부탁드립니다" 후 화면의 텍스트를 그대로 인용
- 외부 서비스 메뉴 안내 전: 최근 변경(deprecate·rebrand) 가능성 검색 또는 사용자 화면으로 확정
- 추측 메뉴명 사용 금지

## 재발 방지
- 외부 SaaS 화면 안내 시: 사용자 환경의 화면 텍스트 → 그 텍스트 그대로 인용
- 영문 메뉴명을 인용해야 하는 경우엔 명시적으로 "(영문 UI 기준)" 표기
- "Dev Dashboard로 이관" 같은 마이그레이션 단서가 화면에 보이면 그 단서를 우선 따름
- 같은 사용자에게 같은 절차를 두 번 이상 안내해야 한다면 첫 안내가 틀렸을 가능성 의심

## 관련 사례 (2026-05-08)
- Shopify Custom App access token 발급을 영문 경로(`Settings → Apps and sales channels → Develop apps → Develop apps → Custom App → API credentials`)로 안내
- 실제 화면: "앱 개발" 페이지 + "Dev Dashboard에서 앱 개발하기" 버튼 (Custom App UI 자체가 Dev Dashboard로 이관됨)
- 사용자 매칭 0건 → 즉시 정정 필요했음
