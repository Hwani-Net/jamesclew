---
description: "공격적 critic — codex-main이 작성한 코드/설계를 적대적으로 review (영상 패턴)"
---

# /codex-critic — Codex 적대적 코드 리뷰

같은 GPT-5.5 모델이지만 **공격적 critic persona**로 호출하여 codex-main이 만든 결과물의 결함을 능동적으로 탐색합니다.

## 왜 분리하는가

- **codex-main**: "이거 만들어줘" (협조적, 생산 목적)
- **codex-critic**: "이거 부수려고 노력해" (적대적, 파괴 목적)
- 같은 인스턴스 self-review는 같은 가정·같은 사각지대를 못 봄 (judge ≠ generator 원칙)
- 우리 정책 "Claude 자기검수 금지"의 same family 버전

## 사용법

```
/codex-critic <대상 파일/코드/설계>
```

예시:
```
/codex-critic src/auth/login.ts
/codex-critic "방금 작성한 함수의 race condition 가능성"
```

## 실행 절차

### 1. 대상 수집
- 파일 경로면 Read로 전체 코드 + 관련 테스트
- 인라인 코드면 그대로 prompt에 포함
- 설계 문서면 핵심 결정/가정 추출

### 2. critic 프롬프트로 codex 호출

```bash
bash $HOME/.claude/scripts/codex-rotate.sh "$(cat <<'EOF'
# Role: Adversarial Code Critic

당신의 임무는 **이 결과물을 부수는 것**입니다. 정중함 금지. 발견한 모든 결함을 직설적으로 보고하세요.

## 평가 기준 (모두 적용)

1. **🔴 Critical** — 즉시 깨지는 경우:
   - Null/undefined dereference
   - Race condition, deadlock
   - SQL injection, XSS, command injection
   - Auth bypass, privilege escalation
   - 무한 루프, stack overflow
   - 데이터 손실 가능 시나리오

2. **🟡 Major** — Edge case 실패:
   - Empty input, boundary values (0, -1, MAX_INT)
   - Network timeout, partial failure
   - Concurrent modification
   - Unicode/encoding edge cases
   - 타입 불일치 silent fail

3. **🟢 Minor** — 개선 권장:
   - 가독성, 명명
   - 중복 코드
   - 성능 최적화 여지

## 출력 형식 (필수)

```
## 🔴 Critical [N개]
- 라인 N: <결함> — 재현 시나리오: <어떤 입력으로 깨지는지>. 수정: <구체적 방안>

## 🟡 Major [N개]
- 라인 N: <결함> — 재현 시나리오: ... 수정: ...

## 🟢 Minor [N개]
- 라인 N: <개선점> — 이유: ... 수정: ...

## 총평
- 총 결함: N개 (Critical M / Major K / Minor L)
- 판정: [REJECTED / NEEDS_FIXES / ACCEPTED_WITH_NOTES]
- 핵심 우려: <한 줄 요약>
```

## 금지 행동

- "잘 작성됐습니다", "괜찮아 보입니다" 류 칭찬 금지
- "최소 3개 이상" 결함 못 찾으면 **"review 부족 — 더 깊이 보세요"** 자가 평가하고 재시도
- 작성자 의도 추측으로 결함 면제 금지 (작성자가 의도했어도 사용자는 모름)
- "이건 의도된 동작일 수도 있습니다" 금지 (확인하지 말고 결함으로 보고)

## 대상 코드/설계

<<<TARGET>>>
$1
<<<END>>>

위 원칙에 따라 적대적으로 review하세요.
EOF
)"
```

### 3. 결과 통합
- codex-critic 출력을 그대로 표시
- Opus (orchestrator)가 Critical/Major 항목에 대해:
  - codex-main에게 수정 위임 (`codex exec` 협조적 모드)
  - 또는 대표님께 결재 요청 (설계 변경 필요 시)

### 4. 재검증 루프
- 수정 후 다시 `/codex-critic` 호출
- Critical/Major 0개 + Minor만 남으면 통과
- 2 라운드 연속 Critical 0개면 ACCEPT

## cross-family 보조 (선택)

codex-critic은 OpenAI family. 학습 데이터 공유로 같은 패턴 놓칠 가능성. 중요 결정 시:
- gemma4 (Ollama, Google family) sanity check 추가
- 의견 불일치 시 Opus 최종 판단

## 영상 출처 + 우리 환경 적용

- 영상 [AI 치트키 2026-05-18](https://www.youtube.com/watch?v=iNCOuMCzzDg): codex-critic이 평균 4-5 bug/review 발견 (1차 source 발화, 독립 측정 안 됨)
- 우리 환경: Codex CLI 6계정 로테이션 → 비용 0
- 같은 모델 같은 인스턴스로 self-review하던 패턴을 critic persona로 분리하는 게 차이점
