---
description: "세션 행동 + Hook 인프라 + (옵션)외부 모델 통합 감사"
---

# /audit — 통합 하네스 감사 (v2 — 2026-05-04 P-111 audit 후속 업그레이드)

세션의 하네스 규칙 준수, 모든 hook의 동작 가능 여부, 그리고 (옵션) 외부 모델 종합 검수까지를 한 번에 실행합니다.

## 사용법
- `/audit` — 통합 감사 (Hook 인프라 + 세션 행동)
- `/audit --deep` — 통합 + 외부 모델(Codex + GPT-4.1) 종합 검수
- `/audit <session-id>` — 특정 세션 감사

## 실행 절차

### 0. Hook 인프라 메타 검증 (P-111 4단계)

모든 settings.json 등록 hook에 대해 (등록/존재/입력/실행) 4단계 자동 검증:

```bash
bash ~/.claude/hooks/harness-self-audit.sh
cat ~/.harness-state/hook_audit_report.txt
```

- 결과: `Total registered: N / PASS: M / ISSUES: K`
- ISSUES > 0이면 침묵 hook 후보 식별 → P-111 패턴 재발 의심

### 1. 세션 행동 감사 (기존 39 check)

```bash
bash ~/.claude/scripts/audit-session.sh --full $ARGUMENTS
```

10개 핵심 항목 + 29개 부가 항목:

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

### 2. (`--deep` 옵션) 외부 모델 종합 검수

세션 + Hook 인프라 결과를 Codex + GPT-4.1에 병렬 위임:

```bash
# 결과 텍스트 결합
REPORT=$(cat ~/.harness-state/hook_audit_report.txt; echo "---"; bash ~/.claude/scripts/audit-session.sh --compact)

# Codex 호출
codex exec "다음 감사 결과를 검토하고 (1) 가장 위험한 1-2건 (2) 미발견 가능 패턴 (3) 즉시 수정 권장 사항을 200자 이내 요약: $REPORT"

# GPT-4.1 호출 (병렬)
curl -s --max-time 30 localhost:4141/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"gpt-4.1\",\"messages\":[{\"role\":\"user\",\"content\":\"같은 프롬프트\"}]}"
```

두 모델 응답을 비교하여 다수결 권장 사항 도출.

### 3. 결과 해석

#### 3-1. Hook 인프라 (메타 hook 결과)
- PASS: 모든 hook 동작 가능 (P-111 패턴 없음)
- ISSUES: 침묵 hook 후보 — 즉시 점검 + 의존 state 파일 공급원 확인

#### 3-2. 세션 행동 (39 check)
- PASS: 규칙 준수
- FAIL: 위반 확인 → 즉시 보완 또는 PITFALL 기록 검토
- WARN: 부분 준수 — 다음 라운드 보강

#### 3-3. (`--deep`) 외부 모델 권장
- 두 모델 일치 → 즉시 진행
- 불일치 → Opus 최종 판단

### 4. 체크포인트 모드 (파이프라인 중간 검증)

```bash
bash ~/.claude/scripts/audit-session.sh --checkpoint 5   # Step 5 품질루프 후
bash ~/.claude/scripts/audit-session.sh --checkpoint 7   # Step 7 외부검수 후
bash ~/.claude/scripts/audit-session.sh --checkpoint 10  # Step 10 배포 전
```
- PASS → 다음 단계 진행 + 증거 파일 자동 생성
- FAIL → prescriptive 에러 메시지

### 5. 결과 보고

대표님께 통합 테이블 형태로 보고:

```
=== Harness Audit Result ===
Hook Infrastructure: M/N PASS, K ISSUES (메타 hook)
Session Behavior:    P/22 (39 check 중 핵심 10)
External Review (deep): Codex / GPT-4.1 권장 사항
Pitfall Triggered:   P-NNN, P-MMM 자동 기록됨
Next Auto-Audit:     다음 SessionStart 자동
```

## 주기 자동 실행

| 실행 시점 | 동작 |
|----------|------|
| **SessionStart** | `harness-self-audit.sh` 자동 (이미 등록됨, 2026-05-04~) |
| **수동 `/audit`** | 통합 감사 (세션 + 메타) |
| **`/audit --deep`** | + 외부 모델 종합 |
| **(옵션) cron** | `/schedule "harness-audit weekly" --cron "0 9 * * 1"` 등록 시 매주 월 9시 자동 |

## 관련 PITFALL (감사 누락 패턴)

- **P-111**: hook 파일 존재 ≠ 동작. 4단계 검증 필수 → `harness-self-audit.sh`로 영구 차단
- **P-112**: 컨텍스트 잔량 검증 없이 작업 미루기 → /audit 결과 보고 시 컨텍스트 % 첨부 의무
- **P-014**: 학습 데이터 의존 금지. 감사 결과는 실 도구 출력 기반

## 변경 이력

- **2026-05-04 v2**: P-111 audit 후속. 메타 hook 통합 + `--deep` 모드(외부 모델) 추가
- 2026-04-29: check_v121_*, check_v120_powershell_fallback, check_v119_config_persistence 추가 (39 check)
- 2026-04-17: 초기 작성 (10 핵심 check)
