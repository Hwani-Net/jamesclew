# P-056: TaskCreate 후 TaskUpdate 누락 (pending으로 방치)

- **발견**: 2026-04-18
- **세션**: docs 사용설명서 생성 작업
- **심각도**: Mid

## 증상
TaskCreate로 작업 5개(#12~#16)를 생성하고 실제 작업(벤치마킹·맵핑·뼈대설계·섹션작성·검수)을 전부 완료했으나 `TaskUpdate`로 상태를 `completed` 전환하지 않고 5개 모두 `pending`으로 방치. 대표님이 "진행중이야?"로 한 번, "5 task 만들고 왜 진행 안해?"로 두 번 지적한 후에야 일괄 업데이트.

## 원인
1. TaskCreate 호출 시 `TaskUpdate`/`TaskList` 도구를 같은 턴에 로드하지 않음 (deferred tool 상태). 상태 전환 직전까지 도구 접근 없음.
2. 실제 작업 진행을 "완료"로 인식했지만 task 레코드의 상태는 별도 관리 대상으로 취급하지 않음.
3. system reminder가 여러 차례 "TaskUpdate 사용 권고"를 주입했으나 무시. 실행 증거(도구 호출)가 없어 hook이 잡지 못함.

## 해결
5개 task 모두 `status: completed`로 일괄 업데이트. TaskUpdate 도구는 ToolSearch로 1회 로드 후 병렬 5회 호출.

## 재발 방지
1. **TaskCreate와 TaskUpdate 쌍 로드 강제**: TaskCreate 호출 시 같은 턴에서 `ToolSearch("select:TaskUpdate,TaskList")`로 미리 로드.
2. **상태 전환 타이밍 고정**:
   - 작업 시작 직전 → `in_progress`
   - 실제 산출물 생성/도구 실행 완료 직후 → `completed` (배치로 모아두지 말 것)
3. **세션 종료 직전 TaskList 호출**: `pending`/`in_progress` 잔존 여부 확인 후 정리.
4. **hook 제안 (선택)**: Stop hook의 `stop-dispatcher.sh`에 "TaskList에 pending 있는데 completed 전환 없이 세션 종료" 감지 로직 추가 가능.

## 관련
- P-020: Ghost Mode "할까요" 반복 (선언-미실행 패턴). 본 pitfall은 유사하나 대상이 task 상태 레코드라는 점에서 별개 유형.
- P-005: enforce-execution.sh 미래 선언 오탐. 실행은 했지만 기록을 안 한 본 케이스와는 반대 방향 문제.
