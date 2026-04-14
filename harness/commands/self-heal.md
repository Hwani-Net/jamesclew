---
description: "Self-Healing 빌드 — 3 에이전트 경쟁 수정 + 테스트 승자 선택"
user_invocable: true
---

# /self-heal — 버그 수정 토너먼트

3개 서브에이전트가 각각 다른 접근법으로 버그를 수정.
테스트를 통과한 가장 작은 diff만 적용.

## 사용법
- `/self-heal <버그 설명>` — 현재 프로젝트에서 버그 수정 토너먼트 실행
- `/self-heal <버그 설명> --test <테스트 커맨드>` — 커스텀 테스트 명령 지정

## 실행 절차

### Phase 0: 사전 분석 (Lead/Opus)
1. 버그 설명 파싱 + 관련 파일 탐색
2. 테스트 커맨드 결정:
   - `--test` 지정 시 그대로 사용
   - package.json에 test script 있으면 `npm test`
   - 없으면 `npm run build` (빌드 성공 = 통과)
3. 현재 git 상태 확인 (clean 필수, dirty면 stash)

### Phase 1: 3-Way 경쟁 수정 (병렬 서브에이전트)

**Agent A — Minimal Fix (worktree 격리)**
```
Agent(model: sonnet, isolation: "worktree", prompt: "
버그: {description}
접근법: 최소 변경. 버그 원인 라인만 수정. 리팩토링 금지.
테스트: {test_command} 실행하여 통과 확인.
결과 보고: PASS/FAIL + diff 줄 수 + 수정 파일 목록")
```

**Agent B — Refactor Fix (worktree 격리)**
```
Agent(model: sonnet, isolation: "worktree", prompt: "
버그: {description}
접근법: 근본 원인 리팩토링. 같은 버그 재발 방지 구조 개선.
테스트: {test_command} 실행하여 통과 확인.
결과 보고: PASS/FAIL + diff 줄 수 + 수정 파일 목록")
```

**Agent C — Defensive Fix (worktree 격리)**
```
Agent(model: sonnet, isolation: "worktree", prompt: "
버그: {description}
접근법: 방어적 코딩. 입력 검증 + 에러 핸들링 추가. 엣지케이스 커버.
테스트: {test_command} 실행하여 통과 확인.
결과 보고: PASS/FAIL + diff 줄 수 + 수정 파일 목록")
```

3개 모두 `isolation: "worktree"`로 격리 — main 브랜치 안전.

### Phase 2: 승자 선택 (Lead/Opus)

**선택 기준 (우선순위):**
1. 테스트 통과 여부 (FAIL은 탈락)
2. diff 크기 (작을수록 우선)
3. 수정 범위 (좁을수록 우선)

**결과 매트릭스:**
| 상황 | 결정 |
|------|------|
| 1개만 PASS | 해당 fix 적용 |
| 2-3개 PASS | 가장 작은 diff 적용 |
| 모두 FAIL | GPT-4.1에 3개 실패 분석 의뢰 → 대표님 보고 |
| 동점 (diff 크기 같음) | Minimal > Refactor > Defensive 순 |

### Phase 3: 적용 + 검증

1. 승자 worktree에서 변경사항 추출: `git diff`
2. main 브랜치에 패치 적용: `git apply`
3. 테스트 재실행 (main에서 확인)
4. PASS → 커밋. FAIL → 롤백 + 보고.

### Phase 4: 보고

```
✅ Self-Heal 완료
🐛 버그: {description}
🏆 승자: Agent A (Minimal Fix)
📊 결과: A=PASS(+3/-1) | B=PASS(+15/-8) | C=FAIL
🔧 적용: {파일 목록}
✅ 테스트: {test_command} PASS
```

## 핵심 규칙
1. **worktree 격리 필수** — main 브랜치를 절대 더럽히지 않음
2. **테스트가 판사** — 사람 판단 아닌 테스트 결과로만 승패 결정
3. **최소 변경 우선** — 같은 결과면 작은 diff가 더 안전
4. **모두 실패 = 에스컬레이션** — 무리하게 수정하지 않음
5. **Evidence-First** — 3개 에이전트의 diff와 테스트 출력 모두 표시
