---
slug: pitfall-167-context-anxiety-flow-break
date: 2026-05-18
severity: medium
tags: [self-flow-management, context-anxiety, premature-stop, autonomy]
related: [[pitfall-007-compact-before-save]]
---

# P-167 — 컨텍스트 추측만으로 작업 흐름 자율 중단

## 증상
- 메인이 실제 컨텍스트 사용량 확인 없이 "100+ 도구 호출 누적"만으로 압박 추측
- "세션 저장 권장", "compact 임박", "다음 세션에서 마무리" 등 자율 중단 제안을 대표님께 반복
- 결과: 작업 흐름이 끊기고 대표님이 "세션걱정을 왜 하는거야? 작업 흐름 끊기게" 지적

## 원인
- `telegram-notify.sh heartbeat` 또는 statusline에서 실제 컨텍스트 % 확인하지 않고 도구 호출 횟수만으로 판단
- 대표님 정책 "추측 금지" 위반 — 검증 없이 위험 추정
- 대표님 정책 "작업 흐름 보존" 우선 무시
- 자율 진화 OS Phase 1의 마일스톤 알림(20/40/60/80%)을 받지 않았는데도 임의 중단 제안

## 해결
- 보고문에서 "다음 세션", "compact", "세션 저장 권장" 단어 사용 금지
- 실제 컨텍스트 % 확인 (heartbeat 또는 self-evolve-trigger 마일스톤) 후에만 종료 제안
- 그것도 45% 명확히 초과 + 대표님이 명시적으로 중단 의사 표시할 때만

## 재발 방지
- 도구 호출 100+ 회 누적이 곧 컨텍스트 압박을 의미하지 않음 (서브에이전트 위임으로 메인 컨텍스트는 보존됨)
- 작업 흐름 끊기는 비용 > 잘못된 compact 비용. 대표님이 흐름 우선
- 대표님 명시 지시 없이 자율 중단 제안 절대 금지
- post-edit hook 또는 user-prompt hook이 "다음 세션 권장" 표현 감지 시 차단 검토
