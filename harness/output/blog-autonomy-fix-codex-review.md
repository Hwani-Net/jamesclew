# 설계 교차검토 — blog-autonomy-fix-design-2026-06-04

검토일: 2026-06-04
검토 모델: codex(gpt-5.5) — 2회 timeout(exit 124, 30s), gemma4 — Ollama 미응답(exit 7). **sonnet-fallback** 직접 적대적 분석 (CLAUDE.md 임시 허용 조항 적용)

---

## A (loop-gate hard-gate): REVISE

**이슈 1 — 기존 호출자 수정 범위 미명시**
`evaluate()` 파라미터가 추가되면 기존 호출자(모든 봇 액션 진입점)가 `imageRenderVerified` 인수를 명시 전달해야 함. 전달 생략 시 `undefined` → 콘텐츠 판별 정규식 히트 여부와 무관하게 차단 위험. 설계에 "기존 호출자 수정 범위" 명시 필요.

**이슈 2 — 정규식 적용 필드 미명시**
`payload/label`이 구체적으로 어떤 필드인지(payload.label? payload.task? message.content?) 설계에 없음. 구현자가 잘못된 필드 선택 시 false positive/negative 제어 불가.

**이슈 3 — "글" 토큰 false positive**
`/blog|발행|publish|draft|초안|글|포스팅/i` 중 "글" 단독 2바이트는 과도하게 일반적. 비콘텐츠 작업의 label에도 "글자", "logging" 등으로 히트 가능. → `\b글\b` 또는 "기사|포스트|글쓰기|작성" 등으로 좁혀야.

**이슈 4 — "draft" false positive**
git commit subject, API draft status, "draft PR" 등 비발행 맥락에서 충돌 가능.

**누락 false negative**: "게시", "기사", "article", "content", "콘텐츠", "업로드" 미포함.

---

## B (발행 결재 포맷): APPROVE (조건부)

설계 자체는 합리적. 단, **A의 imageRenderVerified=true가 결재 push 전제조건**인데 이 의존성이 코드에서 강제되는지 미명시. A 미완성 상태에서 B만 배포 시 이미지 미검증 콘텐츠가 결재까지 도달 가능 → **적용 순서(A→B)를 코드 레벨에서도 assert 필요**.

승인 문구 파싱("발행해"/"승인"/"publish")은 적절. "발행해요"/"승인합니다" 형태 변형 대응은 선택사항.

---

## C (cron watchdog): REVISE

**이슈 1 — race condition: jobs-state.json 동시 쓰기**
3분 watchdog과 cron runner가 동일 파일을 concurrent 접근. atomic write(임시파일 → rename) 또는 파일 락(flock 등) 없으면 상태 불일치 발생.

**이슈 2 — debounce 상태 휘발**
debounce 10분 상태가 메모리 내 관리 시 watchdog 재시작마다 즉시 재시도 가능 → 서비스 재시작 루프에서 폭주. 파일(`~/.harness-state/cron-retry-debounce.json`)로 debounce 상태 영속화 필요.

**이슈 3 — one-shot 패턴 누락**
`day\d/once/-at-` 중 `once` 토큰이 과도하게 일반적("oncall-check" 등 상시 cron 매칭 가능). 날짜 기반 타임스탬프 패턴(`\d{4}-\d{2}-\d{2}`, `\d{8}`)이 more reliable한 at-time 식별자임.
`-at` 단수(후행 없음), `_at_` 언더스코어 형태 미포함.

**이슈 4 — A 미배포 시 C의 콘텐츠 cron 재시도 경로**
콘텐츠 발행 cron이 error 상태일 때 C가 재시도하면 A 게이트 없이 이미지 미검증 발행 가능. **C 배포 전 A 완료 필수** (설계 적용순서 A→C도 명시 필요).

---

## 누락 엣지케이스

1. **imageRenderVerified 타입 가드**: 문자열 "true"/"false" 입력 시 boolean 비교 오작동 → strict boolean 타입 체크
2. **결재 채널 push 실패 시 C의 fallback**: Discord API 오류 시 max 3회 error cron이 그냥 방치됨. 로컬 로그 + 다음 스캔 재시도 여부 미명시
3. **동일 cron 재시도 중 새 에러 발생**: 재시도 1회 중에 새 error 판정이 들어오면 카운터 증가 여부 (중복 카운트 방지 필요)
4. **watchdog 자체 crash**: 3분 timer가 watchdog JS 오류로 멈추면 모니터링 사각지대. 헬스체크 없음

---

## 적용 전 필수 수정

1. **A**: `evaluate()` 호출자 수정 범위 명시 + 정규식 적용 필드 명시 + "글" 토큰을 `\b글\b` 또는 더 구체적 토큰으로 교체
2. **C**: debounce 상태 파일 영속화 + jobs-state.json atomic write 명시 + one-shot 패턴에 `\d{8}|\d{4}-\d{2}-\d{2}` 추가
3. **배포 순서 강제**: A→B, A→C 의존성을 코드 assert 또는 배포 스크립트 게이트로 강제

B는 A 의존성 assert 추가 후 APPROVE 가능.
