---
type: pitfall
id: P-038
title: "Google Cloud Console OAuth UI 2025 개편 — OAuth 동의 화면 → Google 인증 플랫폼"
tags: [pitfall, jamesclew]
---

# P-038: Google Cloud Console OAuth UI 2025 개편 — OAuth 동의 화면 → Google 인증 플랫폼

- **발견**: 2026-04-17
- **증상**: 구버전 가이드(External + 테스트 사용자) 따라가다 Step 3 막힘. 실제 화면은 브랜딩/대상/클라이언트 탭 구조
- **원인**: Google이 2025년 중반 OAuth consent screen을 Google 인증 플랫폼으로 개편. 탭 구조로 분리
- **해결**: 새 가이드: Google 인증 플랫폼 → 클라이언트 → 데스크톱 앱. 프로덕션 단계 프로젝트면 테스트 사용자 생략 가능
- **재발 방지**: Google/Anthropic/MS 콘솔 가이드 작성 전 실제 URL로 현재 UI 확인 (자주 개편됨)
