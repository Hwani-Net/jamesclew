---
description: "세션 하네스 준수 감사"
---

# /audit — 세션 하네스 준수 감사

현재 또는 특정 세션의 하네스 규칙 준수 여부를 자동 감사합니다.

## 사용법
- `/audit` — 현재 세션 감사 (full 모드)
- `/audit <session-id>` — 특정 세션 감사

## 실행 절차

### 1. 감사 스크립트 실행
```bash
bash ~/.claude/scripts/audit-session.sh --full $ARGUMENTS
```

### 2. 결과 해석
스크립트가 10개 항목을 체크하고 PASS/FAIL/WARN/N/A를 판정합니다:

| # | 항목 | 빌드 세션만 |
|---|------|-----------|
| 1 | Build Transition (/plan 진입) | ✅ |
| 2 | PRD 실행 | ✅ |
| 3 | Pipeline Install | ✅ |
| 4 | Step 5 품질루프 | ✅ |
| 5 | Step 7 외부 검수 | ✅ |
| 6 | 배포 후 검증 | 배포 시만 |
| 7 | TodoWrite 사용 | |
| 8 | Ghost Mode 준수 | |
| 9 | Evidence-First 준수 | |
| 10 | 텔레그램 결과 알림 | |

### 3. FAIL 항목 분석
FAIL 항목이 있으면 원인을 분석하고:
- 현재 세션이면 즉시 보완 가능한 항목 안내
- 과거 세션이면 PITFALLS 기록 여부 확인
- 반복 패턴이면 하네스 규칙 강화 제안

### 4. 체크포인트 모드 (파이프라인 중간 검증)
파이프라인 실행 중 단계 완료 시 체크포인트를 실행합니다:
```bash
bash ~/.claude/scripts/audit-session.sh --checkpoint 5   # Step 5 품질루프 후
bash ~/.claude/scripts/audit-session.sh --checkpoint 7   # Step 7 외부검수 후
bash ~/.claude/scripts/audit-session.sh --checkpoint 10  # Step 10 배포 전
```
- PASS → 다음 단계 진행 + 증거 파일 자동 생성
- FAIL → prescriptive 에러 메시지 (구체적 해결 명령 포함)
- FAIL 시 1-2회 self-correction 후 재실행

### 5. 결과 보고
감사 결과를 대표님께 테이블 형태로 보고합니다.
점수(N/22)와 함께 개선 필요 항목을 구체적으로 안내합니다.
