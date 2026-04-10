# JamesClaw — PITFALLS.md

> 반복된 실수와 함정의 구조화된 기록. "흉터 조직".
> **새 함정 발견 즉시 추가.** self-evolve.sh가 패턴 분석 시 참조.

---

## [P-001] loading="lazy"가 headless 브라우저에서 이미지 로드 차단

- **발견**: 2026-04-05
- **증상**: agent-browser에서 naturalWidth > 0 체크 시 첫 이미지만 로드, 나머지 0
- **원인**: loading="lazy"가 스크롤 이벤트 없이는 이미지를 로드하지 않음. scrollTo()도 lazy trigger 불충분
- **해결**: 전체 42개 img 태그에서 loading="lazy" 제거
- **재발 방지**: CLAUDE.md + smartreview-blog CLAUDE.md에 loading="lazy" 사용 금지 규칙

---

## [P-002] 쿠팡 이미지 캡처 시 UI 오버레이(하트/공유 버튼) 포함

- **발견**: 2026-04-05
- **증상**: 제품 이미지에 쿠팡 하트/공유 아이콘이 함께 캡처됨
- **원인**: Playwright screenshot clip이 제품 이미지 영역만 잡지만 오버레이 UI가 위에 떠있음
- **해결**: og:image 메타태그에서 CDN URL 추출 → 800x800 직접 다운로드 (UI 없음)
- **재발 방지**: capture-images.mjs에 og:image 방식을 1순위로 적용

---

## [P-003] 쿠팡 제품 ID가 다른 모델을 가리킴

- **발견**: 2026-04-05
- **증상**: ainic-isa7(단일바스켓)의 제품 ID가 듀얼바스켓 모델 페이지로 연결
- **원인**: 블로그 글 작성 시 쿠팡 URL을 잘못 매칭하거나, 쿠팡이 제품 페이지를 변경
- **해결**: Opus+Sonnet 서브에이전트 교차 검증으로 발견. 검색으로 정확한 제품 찾아 재캡처
- **재발 방지**: 이미지 캡처 후 반드시 Vision 교차 검증 (Pass 5b)

---

## [P-004] Firestore ↔ 로컬 JSON 불일치로 빌드에 변경 미반영

- **발견**: 2026-04-05
- **증상**: 로컬 JSON 수정했는데 빌드된 HTML에 반영 안 됨
- **원인**: SSG가 Firestore에서 읽어오는 구조. 로컬 JSON만 수정하면 Firestore는 구버전 유지
- **해결**: JSON 수정 후 반드시 createPost()로 Firestore 동기화
- **재발 방지**: 빌드 전 Firestore sync를 파이프라인에 필수 단계로 포함

---

## [P-005] enforce-execution.sh가 완료 보고를 미래 선언으로 오탐

- **발견**: 2026-04-05
- **증상**: "설계 문서 현행화 완료" 같은 과거 보고에서 Stop hook이 block
- **원인**: "진행합니다/반영합니다" 패턴이 현재형 보고도 매칭
- **해결**: 패턴을 미래형만 잡도록 변경 ("~하겠습니다/~하겠")
- **재발 방지**: hook 패턴 변경 시 과거/현재/미래 시제 모두 테스트

---

## [P-006] agent-browser 기본 모드로 쿠팡 Access Denied

- **발견**: 2026-04-05
- **증상**: agent-browser --headed --profile로도 쿠팡 접근 불가
- **원인**: 쿠팡이 Chromium 자동화 감지 (navigator.webdriver 등)
- **해결**: Playwright launchPersistentContext + --disable-blink-features=AutomationControlled
- **재발 방지**: 쿠팡 접근 시 반드시 Playwright 또는 og:image CDN 방식 사용

---

## [P-007] compact 후 세션 요약 저장하면 의미 없음

- **발견**: 2026-04-05
- **증상**: compact 후 옵시디언 세션 요약을 저장하려 했으나 원본 맥락이 이미 압축됨
- **원인**: compact가 맥락을 압축하므로 이후에는 상세 내용을 복원할 수 없음
- **해결**: compact 전(60-65% 시점)에 저장 작업을 먼저 실행
- **재발 방지**: user-prompt.ts 60% 트리거 + PreCompact hook에 자동 snapshot

---

## [P-008] 세션 Context %를 읽을 방법이 없다고 잘못 보고

- **발견**: 2026-04-05
- **증상**: "제가 직접 확인할 수 있는 방법이 없다"고 텔레그램 보고
- **원인**: user-prompt.ts가 매 턴마다 context_window 데이터를 받고 있었는데, 파일에 저장하지 않아 다른 도구에서 접근 불가. 방법이 없는 게 아니라 저장 로직이 없었을 뿐
- **해결**: user-prompt.ts에 context_pct, context_tokens를 state 파일에 기록하도록 추가
- **재발 방지**: "방법이 없다" 전에 데이터 흐름을 추적. hook이 받는 데이터를 파일로 저장하면 다른 도구에서 읽을 수 있음

---

## [P-009] 5H/7D Usage 캐시 stale 상태 미감지

- **발견**: 2026-04-05
- **증상**: 5H 40%, 7D 36%를 실제 수치로 보고했지만, 캐시가 2시간 전 데이터. resets_at 시간이 이미 지남
- **원인**: 캐시 TTL(30분) 만료 + throttle(10분) 내 재시도 불가 → stale 캐시를 그대로 사용
- **해결**: 캐시 삭제 후 다음 statusline 호출에서 갱신
- **재발 방지**: usage 보고 시 resets_at 시간을 현재시각과 비교. 지났으면 "stale 데이터" 명시

---

## [P-010] MCP 연결 끊김 시 재연결 시도 없이 바로 대체 수단 전환

- **발견**: 2026-04-05
- **증상**: lazy-mcp가 "Connection closed" 에러 반환. 바로 WebSearch로 전환하여 진행
- **원인**: MCP 끊김 = 일시적 장애일 수 있음. 재연결(reconnect) 시도 없이 포기한 것은 도구 활용 미숙
- **해결**: 대표님이 수동으로 MCP reconnect 처리
- **재발 방지**: MCP 연결 끊김 시 ① `claude mcp remove + add`로 reconnect ② invoke 재시도 ③ 그래도 실패 시에만 curl 직접 호출. WebSearch/researcher 서브에이전트로 우회하는 것은 최후 수단.
- **2회 재발 (2026-04-05)**: 같은 세션에서 lazy-mcp 끊김 시 reconnect 없이 바로 curl 직접 호출로 우회. P-010 교훈을 따르지 않음.

---

## [P-011] crossReview 텍스트 제한으로 외부 모델이 미완성 글로 오판

- **발견**: 2026-04-05
- **증상**: 파이프라인 Step 7에서 3개 모델 모두 "글이 잘림, 미완성"으로 FAIL 판정 (6/10)
- **원인**: crossReview 함수가 `substring(0, 3000)`으로 본문을 잘라서 전달. 4311자 글이 3000자에서 "추천 대"로 끊김
- **해결**: 텍스트 제한 3000→5000자로 확대
- **재발 방지**: 글 작성 시 목표 글자수(4000-5000자)와 crossReview 제한을 같이 관리. 5000자 이상 글이 나올 경우 제한 추가 확대 필요

## [P-012] 외부 모델 로테이션 규칙만 존재, 구현 없음

- **발견**: 2026-04-10
- **증상**: Codex 429 한도 초과 시 수동으로 Antigravity 전환 필요. evaluator.sh에 `codex exec` 하드코딩, 재시도/로테이션 로직 0
- **원인**: architecture.md와 qa.md에 "Codex → Antigravity → Gemini 로테이션" 규칙만 명시. 실제 스크립트(evaluator.sh)에는 codex 단일 호출만 구현
- **해결**: evaluator.sh Phase 2에 3단계 자동 로테이션 구현 (codex → opencode → codex_backoff). 429/timeout 패턴 감지 → 자동 전환 + 실패 로그 기록
- **재발 방지**: 규칙 추가 시 구현 코드도 동시 작성. "규칙 vs 구현" 갭을 /audit 체크리스트에 추가
