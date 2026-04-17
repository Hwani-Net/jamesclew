---
type: pitfall
id: P-035
title: "Meta Developer 등록 이메일 코드 차단 — 평소 사용하지 않는 기기 보안 락"
tags: [pitfall, jamesclew]
---

# P-035: Meta Developer 등록 이메일 코드 차단 — 평소 사용하지 않는 기기 보안 락

- **발견**: 2026-04-17
- **증상**: developers.facebook.com 등록 Contact info 단계 이메일 코드 입력 정상이나 "평소에 사용하지 않는 기기" 팝업으로 차단
- **원인**: Meta 보안 정책상 "신뢰 기기"에서만 Developer 등록 완료 허용. 새 Chrome 프로필/IP/대량 로그인이 트리거
- **해결**: 24-48시간 동일 기기에서 일반 Facebook 사용으로 신뢰 점수 누적 후 재시도. 즉시 우회 경로 없음
- **재발 방지**: 새 Meta 계정/Developer 등록 전 1일+ 일반 활동 먼저. SMS 실패 보고 시 실제 원인 구분(SMS/이메일/기기 락)
