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
