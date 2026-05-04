# P-113: path 불일치로 인한 dead code — 외부 검수도 효과(path 일치) 검증 누락

- **발견**: 2026-05-04 (Remote agent harness-audit-daily 첫 실행 결과 분석 중)
- **프로젝트**: 하네스 자체 (harness-self-audit + Remote agent 통합 검증)
- **사건 요약**:
  P-111 audit 후 작성한 `build-detector.sh`가 사실상 동작 중이었으나, Remote agent가 finding #4에서 "user-prompt.ts에 이미 같은 기능 있음 → build-detector.sh 중복 → 기능 정상"이라 결론. 검증 결과 **세 코드(user-prompt.ts / enforce-build-transition.sh / build-detector.sh)가 같은 파일명 다른 path를 사용**하여 user-prompt.ts의 build_detected 생성 코드는 4/17부터 dead code였음. 외부 모델(Remote Sonnet)도 path 일치 + 효과(읽는 hook이 실제로 그 파일을 인식) 단계를 검증 안 함.

## 증상

1. **같은 기능을 두 곳에서 다른 path로 구현**:
   - user-prompt.ts line 376: `${STATE_DIR}/build_detected` (STATE_DIR = `~/.harness-state`)
   - enforce-build-transition.sh line 38: `$STATE_DIR/build_detected` (STATE_DIR = `~/.harness-state/build-$PROJECT_HASH`)
   - 두 코드의 STATE_DIR 정의가 달라 같은 파일명이지만 실제 경로 충돌
2. **로컬 P-111 audit이 path 불일치를 못 잡음** — 메타 hook은 "파일 존재 + 분기 진입"만 검증, 두 hook 간 path 매칭은 검증 안 함
3. **외부 모델(Remote agent) 정적 분석도 path 검증 누락** — "user-prompt.ts에 build_detected 생성 코드 있음 → 기능 정상"으로 빠른 결론. 실제 path가 enforce-build-transition.sh와 일치하는지 grep 검증 안 함
4. **결과**: 4/17~5/4 동안 user-prompt.ts의 build_detected 생성은 effectively dead. enforce-build-transition.sh는 그 파일 못 찾아 항상 early-exit.

## 원인

1. **STATE_DIR 정의 분산**: hook마다 STATE_DIR을 자기 컨텍스트에서 정의. PROJECT_HASH 사용 여부가 hook마다 다름. 일관성 없음.
2. **외부 검수의 4단계 검증 부족**:
   - Remote agent: 등록 ✓ 존재 ✓ 코드 분기 ✓ — 그러나 **path 일치 + 실 효과**까지 검증 X
   - "기능 정상"이라는 결론을 grep만으로 도출
3. **P-111 메타 hook의 한계**:
   - hook 단위 검증 (각 hook이 발동하는가)
   - hook 간 협력 검증 부재 (A가 만든 파일을 B가 정확히 읽는가)
4. **path 의존성 매트릭스 미등록**: 어떤 hook이 어떤 path의 파일을 쓰고, 어떤 hook이 같은 path를 읽는지의 매트릭스 없음

## 해결

### 즉시 (이번 세션)

1. user-prompt.ts line 376 dead code 제거 (P-113 주석으로 교체)
2. build-detector.sh가 정확한 path로 build_detected 생성 (enforce-build-transition.sh와 일치) — 이미 작성됨

### 구조적 (다음 세션)

#### Path 의존성 매트릭스 명시

```
# state-file-deps.yaml (또는 harness/docs/state-deps.md)

5h_usage.txt:
  writer: telegram-notify.sh:save_last_usage (line ~89)
  readers: [emergency-mode-check.sh, self-evolve-trigger.sh]
  path: ~/.harness-state/5h_usage.txt

context_usage.txt:
  writer: telegram-notify.sh:get_context (line ~225)
  readers: [self-evolve-trigger.sh]
  path: ~/.harness-state/context_usage.txt

build_detected:
  writer: build-detector.sh
  readers: [enforce-build-transition.sh]
  path: ~/.harness-state/build-{PROJECT_HASH}/build_detected
  note: PROJECT_HASH = md5sum($PWD) | cut -c1-8

pitfall_pending.json:
  writer: pitfall-auto-record.sh
  readers: [pitfall-auto-record-stop.sh]
  path: ~/.harness-state/pitfall_pending.json
```

#### harness-self-audit.sh 강화 (5단계로)

기존 4단계 (등록/존재/입력/실행) → 5단계 추가:
- **5. 협력 (cooperation)**: writer hook이 만드는 path와 reader hook이 읽는 path가 일치하는가. state-file-deps 기반 검증.

#### Remote agent prompt 강화

audit-daily routine prompt에 추가:
```
finding이 "기능 정상" 또는 "중복" 결론일 경우, 반드시 reader hook의 path와
writer hook의 path를 grep으로 비교 검증. STATE_DIR 정의 차이 의심.
"같은 파일명 = 같은 path"가 아닐 수 있음.
```

## 재발 방지

1. 이 PITFALL을 SessionStart hook에서 surface: P-014, P-082, P-103, P-111, P-112와 함께
2. **새 hook 작성 시 의무 체크리스트**:
   - 의존하는 state 파일의 정확한 path 명시 (writer 코드 위치 + 변수 정의)
   - state-file-deps.yaml에 등록
   - harness-self-audit.sh에 5번째 단계(협력) 검증 추가
3. **Remote agent finding의 "기능 정상" 결론 받을 때 의무 검증**:
   - 결론 자체를 신뢰하지 말 것
   - reader path == writer path? grep 명령으로 직접 확인

## 관련 PITFALL

- P-014: 학습 데이터 의존 금지 (외부 모델 결론도 검증 필수)
- P-103: 검증을 사용자 시점에 떠넘긴 declare-no-execute (외부 모델도 동일 패턴 가능)
- P-111: 코드 존재 ≠ 코드 동작 (4단계 검증 누락) — P-113은 변형 (5번째 협력 단계 누락)
- P-112: 컨텍스트 잔량 검증 없이 작업 미루기

## 적용 위치

- 모든 hook 페어(writer-reader) 관계
- Remote agent / 외부 모델의 "기능 정상" 결론 검토
- harness-self-audit.sh 5단계 검증 도입 시
- state-file-deps.yaml 작성 시
