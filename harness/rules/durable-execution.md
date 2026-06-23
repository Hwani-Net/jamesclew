# Durable Execution — 체크포인트-재개 (장기작업 stall 근본 처방)

등록일: 2026-06-22 (agent-os-landscape #1 격차 적용). 모델: Vercel eve / Workflow SDK, deer-flow.

## 문제 (우리 #1 격차)
장기작업(Ralph Loop·야간 자율 P-214·/agent-team·/pipeline-run·블로그 파이프라인)이 멈추거나 죽으면 **처음부터 재시작** = 토큰·시간 낭비 + 거짓 미완. 반복 사고: P-268(JARVIS idle stuck), P-236(자율진행 멈춤), P-224(WSL2 death). 현재는 watchdog 땜질(stuck-watchdog.timer·cron-retry)이지 **상태 보존 재개가 아님**.

## 모델 (eve / Workflow SDK)
모든 스텝을 이벤트로그에 기록 → 결정론적 재생으로 상태 복원 → **마지막 green 스텝부터 재개**(zero 아님). crash·cold-start·deploy 생존, 외부 대기(사람·API·webhook) 시 park 후 재개.

## JamesClaw 적용 (경량 파일 기반 — 과설계 금지 P-109/G2)
무거운 워크플로 엔진 도입 X. **파일 체크포인트 프리미티브**로 동일 효과:

- **태스크 디렉터리**: `$HARNESS_STATE(~/.harness-state)/tasks/<task-id>/`
  - `goal.txt` · `steps.txt`(스텝 1줄씩) · `cursor`(다음 실행 스텝 인덱스) · `step-<N>.done`(완료 스텝당 1파일: status/name/ts/state)
- **재개 규칙 (Reins 정합 P-256)**: **PASS(기계게이트 green) 스텝은 불변 — 재개 시 절대 재실행 안 함**("PASS는 불변"). 재개점 = `cursor` = 마지막 PASS 다음 스텝. FAIL이면 cursor 불변 → 그 스텝부터 재시도.
- **헬퍼**: `scripts/task-checkpoint.sh` (순수 bash, 의존성 0)
  - `init <id> "<goal>" "step1,step2,…"` — 태스크 생성, cursor=0
  - `step-done <id> <N> <name> <PASS|FAIL> ["state"]` — step-N.done 기록, PASS면 cursor=N+1
  - `resume-point <id>` — 다음 실행 스텝 `N:이름`(없으면 `DONE`, 미생성 `NO_TASK`)
  - `status <id>` — 완료/전체 + cursor
- **재개 트리거 (기존 watchdog 강화)**: `openclaw-stuck-watchdog`가 stuck 감지 시 단순 재poke 대신 `resume-point`로 **다음 스텝부터 재개** 지시.

## 적용처
- **Ralph Loop / 야간 자율(P-214)**: 사이클=스텝. PASS 사이클 step-done → 재시작 시 미완 사이클부터.
- **/agent-team · /pipeline-run**: 단계(planner→dev→review→qa)=스텝. 중단돼도 완료 단계 보존.
- **블로그 파이프라인**: generate→review→fix→publish (이미 status.json 부분 보유 → 본 프리미티브로 표준화).
- Reins 기계게이트가 곧 스텝 PASS 판정기(이미 보유) → 자연 결합, 추가 게이트 불필요.

## 단계적 도입 (12→45, 한 번에 풀엔진 X)
1. **(지금)** 프리미티브 `task-checkpoint.sh` + 본 설계 — 옵트인.
2. (다음) Ralph Loop·/pipeline-run·/agent-team에 체크포인트 호출 삽입.
3. (다음) watchdog 재개 연동 + 블로그 status.json 흡수.
→ 검증하며 확장.

## 도입 전제 (교차검수 반영 2026-06-22)
체크포인트는 **위치(cursor)만이 아니라 상태(state)를 이어야** 진짜 재개:
1. **상태 스레딩 필수**: 각 스텝은 PASS 시 **재개 가능한 상태 핸들**(산출물 경로·git 브랜치·plan id 등)을 `step-done`의 state 인자에 기록. 재개 측은 `get-state <id> <N>`으로 이전 스텝 산출물을 회수해 이어감. cursor만으론 "체크리스트 재개"일 뿐 "작업 재개"가 아님 — **Ralph Loop처럼 사이클이 self-contained면 cursor로 충분, /pipeline-run처럼 단계가 이전 산출물을 소비하면 state 필수.**
2. **동시성**: **task-id당 runner 1개**(오케스트레이터 보장). 동시 실행 시 cursor 경합 → 와이어링(2단계)에서 락(mkdir atomic) 추가.
3. **오케스트레이터 호출 경로(2단계 핵심)**: 각 스텝 진입 시 `resume-point` 확인 → cursor 미만 스텝은 **skip**(재실행 금지), cursor 스텝부터 실행. 이 가드 삽입이 없으면 본 프리미티브는 로거일 뿐. Ralph Loop/pipeline에 삽입이 2단계 작업.
4. **stale 정리**: DONE 또는 N일 경과 task 디렉터리 월 1회 prune.

## 관련
- [[agent-os-landscape]] #1 격차 · [[quality]] Reins(P-256, PASS 불변) · [[autonomous-evolution]]
- pitfalls: P-268·P-236·P-224(stall), P-214(야간 자율)
- 모델: vercel/eve, deer-flow (trend-watchlist)
