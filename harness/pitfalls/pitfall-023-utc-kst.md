---
type: pitfall
id: P-023
title: "리셋 시각을 UTC 그대로 제시 (KST 변환 누락)"
tags: [pitfall, jamesclew]
---

# P-023: 리셋 시각을 UTC 그대로 제시 (KST 변환 누락)

- **발견**: 2026-04-16
- **증상**: 대표님께 5H/7D 리셋 시각을 UTC 원본으로 보고 후 "저장은 UTC 유지 권장"이라고 판단 고수. 대표님이 "11am은 KST인가 UTC인가" 되물으며 KST 변환 누락을 지적
- **원인**: 내부 저장 정확성(UTC)과 사용자 표시 포맷(KST)을 혼동. Anthropic 서버 동기화 관점만 고려하고 사용자 UX 관점 생략
- **해결**: 저장은 UTC 유지(올바름). **표시는 항상 KST 기본**. `telegram-notify.sh`에 `fmt_kst()` helper 추가 + `fmt_usage`가 리셋 시각을 KST로 자동 부착. 오늘이면 `HH:MM KST`, 내일 이후면 `MM/DD HH:MM KST` 형식
- **재발 방지**: 사용자에게 노출되는 모든 시간 문자열은 로컬타임(KST) 우선. 응답에서 UTC 먼저 제시 금지. 저장 포맷(UTC)과 표시 포맷(KST) 분리 원칙
