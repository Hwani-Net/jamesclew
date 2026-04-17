# P-043: reviewer 2차 재검증 PASS 시 qa SendMessage 누락 — R4.5 규칙 구멍

> type: pitfall | id: P-043 | date: 2026-04-18 | tags: pitfall, agent-team, sendmessage, reviewer, qa

## [P-043] reviewer 2차 재검증 PASS 판정 후 qa 호출 SendMessage 누락 + qa FAIL 보고 후 dev SendMessage 누락

**재발 기록**:
- 2026-04-18 01:04 kanban-pwa: reviewer 2차 PASS → qa SendMessage 누락 (20분 정지)
- 2026-04-18 01:38 kanban-pwa: qa FAIL 5건 → dev SendMessage 누락 (7분+ 정지) — 동일 패턴 **동일 세션 2번째**

**공통 패턴**:
teammate가 **대기 주 대상(dev/qa) SendMessage는 skip하고 team-lead 보고만** 수행.
- reviewer: "qa 진입 승인" team-lead에만
- qa: "FAIL 수정 요청" team-lead에만

→ **대상 teammate가 영구 대기**. director 수동 개입 없으면 전체 루프 정지.

- **발견**: 2026-04-18 (v8 kanban-pwa 실측 중)
- **재발 출처**: GAP-V5-N3 (reviewer/qa가 대상 teammate에 SendMessage 누락)
- **증상**:
  1. reviewer 1차 리뷰: P0 발견 → dev에 수정 요청 SendMessage + team-lead 보고 (R4.5 **정상 준수**)
  2. dev P0 수정 완료 → reviewer에 재검증 요청
  3. reviewer 2차 재검증: P0 0건, 수정 PASS 확인
  4. reviewer가 **team-lead에만 "P0 재검증 PASS — 수정 확인 완료"** 보고
  5. reviewer idle (summary 비어있음)
  6. **qa.json inbox 파일 자체가 생성 안 됨** — qa는 한 번도 메시지 수신 못함
  7. 20분+ 루프 정지

- **원인**:
  - R4.5 규칙 "판정 시 대상 teammate + team-lead 둘 다 SendMessage"가 "1차 P0 발견" 케이스에 치우쳐 작동
  - **"다단계 재검증에서 최종 PASS → qa 진입"** 케이스는 프롬프트 예시에 명시되어 있지만 reviewer가 해석 차이
  - reviewer 심리: "1차에 이미 qa 진입을 거부했고 2차는 그 거부를 해소한 것 → team-lead에 보고가 주 의무"로 오인
  - 결과: team-lead 보고만 하고 qa SendMessage 누락

- **해결 (즉시)**:
  - director가 qa.json 비어있음 감지 시 직접 SendMessage로 우회 진입 지시

- **재발 방지 (v9 수정)**:
  1. reviewer 프롬프트에 **"재검증 PASS = 반드시 qa에 SendMessage 실제 호출"** 굵게 명시
  2. reviewer idle 직전 자가점검: "내가 PASS 판정했다면 qa SendMessage 호출 내역이 이번 턴에 있는가?"
  3. R4.5 예시에 "1차 P0" + "2차 재검증 PASS" 두 케이스 분리 명시
  4. 또는 director가 3~5분 이상 qa idle 없으면 자동 개입하는 watchdog 추가
