---
slug: pitfall-169-cdp-chrome-auto-restart
date: 2026-05-19
severity: high
tags: [chrome-cdp, autonomy, openclaw, infrastructure]
related:
  - "[[pitfall-168-autonomous-decision-policy]]"
  - "[[pitfall-167-context-anxiety-flow-break]]"
---

# P-169 — CDP 9222 차단 시마다 대표님 호출 — 자율 Chrome 재시작 인프라 필요

## 증상
- Chrome CDP 9222 끊김 때마다 대표님께 "재시작 + 준비됨" 요청 반복
- 대표님 지적 (2026-05-19): "매번 이렇게 차단 되었다고 나에게 해달라고 하면 어떻게 하니? 자동화가 가능해?"
- 진정한 OpenClaw 자율 에이전트 기반 미흡

## 원인
- Chrome 9222 모드 재시작이 PowerShell 수동 명령에 의존
- 매 작업 사이클마다 (대표님이 평소 Chrome 사용 후) 9222 모드 꺼짐 → 자동화 불가
- 자동 시작 스크립트 부재
- SessionStart hook 또는 자동화 작업 전 CDP ping → 재시작 자동화 없음

## 해결 (2026-05-19 구축)
1. `harness/scripts/start-cdp-chrome.ps1` 자동 시작 스크립트 신설:
   - `Test-NetConnection 9222` ping → 이미 살아있으면 skip
   - 기존 `chrome.exe` 모두 종료 (user-data-dir 잠금 회피)
   - `--remote-debugging-port=9222 --user-data-dir=$env:LOCALAPPDATA\Google\Chrome\User Data` 로 Chrome 시작
   - partners.coupang.com 자동 첫 탭
   - 최대 15초 대기로 포트 살아날 때까지 polling
2. 자동화 작업 전 메인이 자동 호출:
   ```bash
   powershell -ExecutionPolicy Bypass -File D:/jamesclew/harness/scripts/start-cdp-chrome.ps1
   ```
3. 평소 Chrome 작업과 같은 user-data-dir 사용 → 로그인 세션 유지 (대표님 1회 로그인이면 영구)

## 재발 방지
- 자동화 hook 또는 SessionStart에서 `start-cdp-chrome.ps1` 자동 호출 (대표님 안 깨움)
- 다음 단계: cdp_ping_then_start() 헬퍼 함수 또는 PreToolUse hook으로 cdp-* 스크립트 실행 전 자동 ping → 재시작
- 매 Chrome 재시작이 대표님의 다른 Chrome 작업을 인터럽트하는 부작용 — 별도 user-data-dir로 분리 검토 (단 로그인 별도 필요)
- 자율 진화 OS Phase 2(Activepieces)에 통합 검토 — 매 작업 사이클 자동 시작

## 효과 검증 (2026-05-19)
- 9222 포트 끊긴 상태에서 메인이 `start-cdp-chrome.ps1` 호출 → 자동 재시작 → partners.coupang.com 로그인 상태 유지 → 12번째 키워드(창문형 에어컨) 5개 추출 무중단 진행
- 대표님 호출 0회로 12번째 페이지 발행 완료
