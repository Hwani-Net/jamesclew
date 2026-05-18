# P-152: tavily-rotator currentKeyIndex가 메모리 변수 — MCP 재시작 시 0으로 리셋

- **발견**: 2026-05-15
- **영향**: Tavily MCP 호출이 사실상 1번째 키만 사용. 1번 키 소진 시 432 반복 → 다른 5개 키 완전 idle.

## 증상

- 6개 API 키 보유했음에도 1번 키만 소진/탈진 상태.
- Tavily MCP 호출 시 `usage_limit_reached` 또는 HTTP 432.
- `~/.harness-state/`에 회전 상태 파일 없음 (그동안 한 번도 회전 안 됨).

## 원인 (2-layer)

1. **상태 영속성 부재**: `tavily-rotator.mjs`의 `currentKeyIndex`가 메모리 전역 변수. MCP 서버가 rotator 프로세스를 재시작하면 (timeout, restart, 새 세션 등) 매번 0으로 리셋. 1번 키가 432를 반환해도 인덱스 증가 후 즉시 프로세스 종료 → 다음 호출 시 또 인덱스 0.
2. **status 432 미감지** (P-057 재발 메커니즘): 회전 트리거가 `[429, 402]` 뿐 — Tavily 일부 플랜은 한도 초과 시 **432**를 반환. 코드가 못 잡고 정상 응답으로 처리.

두 결함이 결합되어 "1번 키만 영원히 쓰임" 패턴 고착.

## 해결

`harness/scripts/tavily-rotator.mjs` 수정 (2026-05-15):

1. **파일 영속화**: `loadIndex()` / `saveIndex()` 도입 → `~/.harness-state/tavily-rotation-index.json`에 인덱스 저장. 시작 시 파일에서 읽음.
2. **status code 확장**: `ROTATE_STATUSES = {401, 402, 403, 429, 432}` 집합 사용.
3. **200 body usage_limit 매칭**: 일부 응답이 200으로 오면서 본문에 `usage limit` 문자열 포함 → response를 clone 후 peek하여 회전.
4. **atomic write** (Codex 검수 권고 반영): `STATE_FILE.{pid}.tmp` 작성 → `renameSync`로 원자적 교체. 다중 프로세스 race 방지.
5. **에러 핸들링 강화**: 빈 catch 제거, 모든 예외에 `console.error` 명시.

## 재발 방지

- 코드 주석에 `(P-152)` 명시.
- 후속: 상태 파일 mtime + 키별 사용 카운터를 텔레그램 hook으로 주간 보고 (선택). 미구현.
- 회전 트리거 status code 변경 시 P-057과 본 슬러그 모두 갱신.

## 검증

- `node --check tavily-rotator.mjs`: PASS.
- Codex 외부 검수 (2026-05-15): race condition 1건 지적 → atomic rename으로 fix 적용 후 OK.
- 배포 후 1주 모니터링: `~/.harness-state/tavily-rotation-index.json` mtime이 갱신되는지, 키별 분산 사용 되는지.

## 관련

- [[pitfall-057-tavily-rotator-432-miss]] (1차 fix — status code 누락)
