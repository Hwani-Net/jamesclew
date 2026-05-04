# P-114: state 파일 freshness 미검증 + transcript path 추측 — stale 데이터 신뢰

- **발견**: 2026-05-04 (대표님 직접 지적: "현재 컨텍스트 62%인데 왜 30%로 알고있어?")
- **프로젝트**: 하네스 자체 (telegram-notify.sh + context_usage.txt)
- **사건 요약**: dialectic-pattern-extractor 도입 후 보고에서 "컨텍스트 30%"라 명시했으나 대표님 statusline 실측은 62%. 실측 결과 `~/.harness-state/context_usage.txt`가 11시간 전 stale 값. 또한 잘못된 transcript(다른 프로젝트의 8% 값)를 추출. **state 파일 mtime 검증 없이 값을 신뢰**한 것이 직접 원인. P-014(학습 데이터 의존)·P-111(코드 존재 ≠ 동작) 변형.

## 증상

1. **state 파일 mtime 검증 없이 값 신뢰**: `cat context_usage.txt`로 30 받고 그대로 보고. 마지막 수정이 11시간 전인지 검증 안 함.
2. **transcript path 추측**: telegram-notify.sh `get_context()` fallback이 `ls -t ~/.claude/projects/*/*.jsonl | head -1`로 **모든 프로젝트의 최신** 가져옴. 현재 세션과 다른 프로젝트 transcript를 잡으면 잘못된 컨텍스트 % 산출.
3. **SessionStart 시 context_usage.txt 자동 갱신 분기 부재**: telegram-notify.sh의 get_context() 호출은 heartbeat의 특정 이벤트 분기에서만 발동. 새 세션 시작 시 자동 갱신 보장 없음.
4. P-112(컨텍스트 잔량 검증 없이 작업 미루기)와 비슷하나 더 심각: 수치 자체가 거짓이었음.

## 원인

1. **state 파일은 신뢰 가능한 원자(atomic) 데이터로 가정** — 그러나 공급원 hook의 발동 빈도가 보장 안 되면 stale 가능
2. **transcript path 추측 fallback** — PWD 기반 정확 식별 없이 "가장 최신" 가져옴. 다른 프로젝트의 transcript와 충돌
3. **freshness invariant 부재** — "이 파일은 N분 이내 갱신된 값이어야 한다" 같은 명시적 약속 없음
4. **메타 hook(harness-self-audit)의 한계 재확인**: 4단계 검증(등록/존재/입력/실행)에 **5단계 freshness**가 없음. 파일 존재만 보고 PASS

## 해결

### 즉시 (이번 세션)

1. **telegram-notify.sh `get_context()` 수정**: PWD 기반 정확한 프로젝트 transcript 식별
   ```bash
   CWD_KEY=$(echo "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's|:|--|g; s|/|--|g; s|^-*||')
   PROJECT_TRANSCRIPT_DIR="$HOME/.claude/projects/$CWD_KEY"
   TRANSCRIPT=$(ls -t "$PROJECT_TRANSCRIPT_DIR"/*.jsonl 2>/dev/null | head -1)
   ```
   기존 `ls -t */jsonl` fallback은 secondary로 강등.

2. **context_usage.txt 즉시 재갱신**: heartbeat 1회 강제 호출.

### 구조적 (다음 세션)

#### state 파일 freshness 메타데이터

`~/.harness-state/<file>` 외에 freshness invariant 표:

```yaml
# state-freshness.yaml
context_usage.txt:
  max_age_seconds: 600  # 10분 이상이면 stale, 사용 금지
  writer: telegram-notify.sh:get_context
  read_check: 사용 전 mtime 비교
5h_usage.txt:
  max_age_seconds: 600
  writer: telegram-notify.sh:save_last_usage
build_detected:
  max_age_seconds: 86400
  writer: build-detector.sh
```

#### harness-self-audit.sh 6단계 (P-114 추가)

기존 5단계 (등록/존재/입력/실행/협력) → **6단계 freshness** 추가:
- state 파일 mtime이 max_age_seconds 초과면 ISSUES로 보고
- writer hook이 실제로 발동했는지 last_usage 같은 마커로 검증

#### 모든 state 파일 read 코드에 mtime 검증 강제

```bash
# 안전 패턴 (예시)
read_state_freshness() {
  local FILE="$1" MAX_AGE="$2"
  [ ! -f "$FILE" ] && return 1
  local MTIME=$(stat -c %Y "$FILE" 2>/dev/null || stat -f %m "$FILE")
  local AGE=$(($(date +%s) - MTIME))
  if [ "$AGE" -gt "$MAX_AGE" ]; then
    echo "[stale] $FILE 갱신 ${AGE}s 전 (max ${MAX_AGE}s) — 재추출 필요" >&2
    return 2
  fi
  cat "$FILE"
}
```

## 재발 방지

1. **이 PITFALL을 SessionStart에 surface**: P-014, P-111, P-112와 함께
2. **컨텍스트/사용량 보고 전 의무 freshness check**:
   - mtime이 10분 초과 → "stale, 재계산 필요" 명시
   - 또는 transcript에서 즉시 직접 추출 (실측 우선)
3. **Remote agent prompt 업데이트** — daily audit이 state 파일 freshness 검증 항목 추가

## 관련 PITFALL

- P-014: 학습 데이터 의존 금지 — state 파일 신뢰도 같은 패턴
- P-111: 코드 존재 ≠ 코드 동작 — state 파일 존재 ≠ 신선
- P-112: 컨텍스트 잔량 검증 없이 작업 미루기 — 수치 자체가 거짓이면 더 심각
- P-113: path 불일치 dead code — writer/reader 일치만 검증, freshness는 검증 안 함

## 적용 위치

- 모든 state 파일 read 코드
- 컨텍스트/사용량 보고 일반
- harness-self-audit.sh 6단계 검증 도입 시
- Remote agent daily audit prompt
