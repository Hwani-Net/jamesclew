# Autonomous Evolution Rules (v1.0)

등록일: 2026-04-25
출처: autonomous-harness-v1 PRD v1.1

---

## 개요

이 파일은 하네스 자율성 강화 기능 3종(P1~P3)의 동작 규칙을 정의한다.
hook 구현과 함께 읽어야 하며, hook 미등록 환경에서는 해당 규칙이 자동 미적용됨.

---

## P1 — PITFALL 자동 검증 루프 (pitfall-auto-record.sh)

### 트리거 조건
- UserPromptSubmit 이벤트에서:
  1. 사용자 메시지에 **지적 키워드** 포함: `다시는`, `하지마`, `하지 마`, `고쳐`, `문제`, `틀렸`, `잘못`
  2. 직전 Claude 응답에 **동의 키워드** 포함: `알겠습니다`, `기록하겠습니다`, `맞습니다`, `수정하겠습니다`
  3. 또는 사용자 메시지에 `기억해` / `저장해` 포함

### 실행 순서
1. `~/.harness-state/pitfall_recent.log` 에서 7일 이내 동일 키워드 확인
   - 존재 시: gbrain put 즉시 실행 후 종료
   - 신규: 2~5단계 진행
2. `gbrain query "<증상 키워드>"` 실행
3. 유사 항목 있으면: 기존 슬러그 보고 후 종료
4. 신규면: `harness/pitfalls/pitfall-NNN-{slug}.md` 생성
5. `gbrain import D:/jamesclew/harness/pitfalls/` 실행
6. `pitfall_recent.log` 에 타임스탬프(ISO-8601 UTC)+키워드 append
7. stdout 알림. TELEGRAM_BOT_TOKEN 설정 시 텔레그램 전송

### 제약
- TEST_HARNESS=1 환경에서는 실제 gbrain/텔레그램 호출 없이 stdout만 출력
- 무관 대화(날씨, 잡담)는 키워드 미감지로 hook 미발동 (false positive 방지)

---

## P2 — 5H 비상모드 자동 진입 (emergency-mode-check.sh)

### 쓰기 주체 분리
- `~/.harness-state/5h_usage.txt` **쓰기**: 기존 `telegram-notify.sh heartbeat` (Stop hook 기등록)
- `emergency-mode-check.sh`: 읽기만 수행. 파일 부재 시 skip

### 상태 전환 규칙
| 조건 | 이전 상태 | 결과 | 알림 |
|------|----------|------|------|
| usage >= 80% | normal | sonnet 기록 | 텔레그램 1회 |
| usage <= 60% | sonnet | normal 기록 | 텔레그램 1회 |
| 그 외 | 任意 | 변화 없음 | 없음 |

### 알림 중복 방지
- `emergency_mode.txt` 상태가 같으면 알림 발송하지 않음
- 상태 전환 시에만 알림 발송 (1회 원칙)

### SessionStart 배너
- `emergency_mode.txt == "sonnet"` 이면 세션 시작 시 배너 출력
- 구현: SessionStart hook에서 파일 확인 후 systemMessage 주입

---

## P3 — 작업 큐 자동 정렬 (task-queue-sort.sh)

### 우선순위 공식 (CLAUDE.md 동일)
```
점수 = 긴급도(0-3) + 수익영향(0-3) + 대표님대기(0-2) + ROI(효과/노력 0-3) - 리스크(0-2)
```

### 동점 정렬 순서
`bug` > `infra` > `revenue` > `feature` > `research`

### 트리거
- PostToolUse 이벤트: `tool_name == "TaskCreate"` 또는 `tool_name == "TodoWrite"`
- "작업 정렬해줘" / "큐 정렬" / "task sort" 포함 메시지: UserPromptSubmit에서 `task_queue_sorted.json` 내용 출력

### 출력 파일
`~/.harness-state/task_queue_sorted.json` — 정렬된 task 배열

### 엣지케이스
- task 0개: 빈 배열로 정상 종료 (오류 없음)
- TEST_HARNESS=1: 파일 쓰기 없이 stdout만 출력

---

## 공통 제약

- `~/.claude/` 직접 쓰기 금지 (실험 모드 — `D:/jamesclew/harness/`에만 작성)
- JS/TS/Node 사용 금지 (R11 P0)
- 모든 hook에 `[[ -n "$TEST_HARNESS" ]] && { ... exit 0; }` mock 분기 필수
- settings.json 등록: additive only — 기존 hook 보존, 같은 이벤트에 신규 항목 추가

---

---

## P4 — Obsidian Inbox 자동 분류 알림 (inbox-classifier.sh)

### 트리거 조건
- Stop 이벤트에서:
  1. `$OBSIDIAN_VAULT/00-inbox/` 파일 수 >= 10
  2. 동일 날짜(UTC) 중복 알림 없음 (24h 쿨다운)

### 실행 순서
1. `$OBSIDIAN_VAULT` 미설정 → exit 0 (skip)
2. TEST_HARNESS=1이면 `$FAKE_INBOX_COUNT` 사용, 아니면 실제 `ls -1 | wc -l`
3. count < 10 → exit 0
4. `~/.harness-state/inbox_last_notify` 파일의 날짜 == 오늘 → exit 0 (쿨다운)
5. 텔레그램 알림 발송 ("inbox N개 대기 중, /inbox-process 필요")
6. `inbox_last_notify` 갱신
7. exit 0

### 제약
- 파일 이동 금지 — 알림만 발송, 분류 작업 없음 (AC-4.3 false positive 0)
- TEST_HARNESS=1: 실제 텔레그램/파일 시스템 조작 없이 stdout만 출력
- OBSIDIAN_VAULT 미설정 시 조용히 skip, 에러 출력 없음

### R9 테스트 벡터
| 벡터 | 입력 | 기대 출력 |
|------|------|----------|
| TV-4A | `TEST_HARNESS=1 FAKE_INBOX_COUNT=5` | 알림 없음, exit 0 |
| TV-4B | `TEST_HARNESS=1 FAKE_INBOX_COUNT=11` (cooldown 없음) | mock 알림, exit 0 |
| TV-4C | `TEST_HARNESS=1 OBSIDIAN_VAULT=""` | skip 메시지 stdout, exit 0 |

---

## P5 — Self-Evolving Loop 자동 트리거 (self-evolve-trigger.sh)

### 트리거 조건
- Stop 이벤트에서:
  1. 컨텍스트 % >= 마일스톤(20/40/60/80) 최소 하나
  2. 해당 마일스톤 미처리 상태 (`last_evolve_milestone.txt` 비교)

### 컨텍스트 % 소스 우선순위 (BLOCKER-1 해결)
1. TEST_HARNESS=1 → `$FAKE_CONTEXT_PCT`
2. `$CLAUDE_CONTEXT` 환경변수 (Stop hook 자동 주입 시)
3. `~/.harness-state/context_usage.txt` (telegram-notify.sh done/start가 기록)
4. 위 모두 없으면 exit 0 (측정 불가, 조용히 skip)

### 실행 순서
1. 컨텍스트 % 추출 (위 우선순위)
2. 마일스톤(20,40,60,80) 계산 — PCT 이하 최대값
3. `last_evolve_milestone.txt` 비교 → 동일하면 exit 0
4. `curl -s --max-time 30 localhost:4141/v1/chat/completions` (GPT-4.1)
   - 실패 시: stderr에 "[self-evolve] copilot-api 미응답" 출력
5. 응답 stdout 출력
6. 텔레그램 전송 시도 (BLOCKER-2 해결)
   - 실패 시: stderr에 "[self-evolve] 텔레그램 전송 실패 — 알림 손실 허용" 출력
   - 어느 경우든 exit 0
7. `last_evolve_milestone.txt` 갱신

### 상태 파일
- `~/.harness-state/context_usage.txt` — 컨텍스트 % (정수, 선택적)
- `~/.harness-state/last_evolve_milestone.txt` — 마지막 처리 마일스톤 (정수)

### 제약
- 알림 인프라 장애(copilot-api/텔레그램 오프라인)가 hook 실패로 전파되면 안 됨 — exit 0 필수
- TEST_HARNESS=1: 실제 curl 호출 없이 stdout만 출력
- python3 미설치 환경: 응답 파싱 실패 허용, fallback 메시지 출력

### R9 테스트 벡터
| 벡터 | 입력 | 기대 출력 |
|------|------|----------|
| TV-5A | `TEST_HARNESS=1 FAKE_CONTEXT_PCT=19` | 아무 동작 없음, exit 0 |
| TV-5B | `TEST_HARNESS=1 FAKE_CONTEXT_PCT=21` (마일스톤 파일 없음) | mock 호출, 파일 생성, exit 0 |
| TV-5C | `TEST_HARNESS=1 FAKE_CONTEXT_PCT=22` (마일스톤 파일=20) | 호출 없음, exit 0 |

---

## 배포

```bash
# dry-run (실배포 금지)
bash D:/jamesclew/harness/deploy.sh --dry-run

# 실배포는 대표님 승인 후
# bash D:/jamesclew/harness/deploy.sh
```
