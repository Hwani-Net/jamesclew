---
description: "Plan 산출물에 대표님 인라인 주석을 수집·반영하는 반복 루프 (Boris Tane Annotate 방식). 최대 6회 수렴."
argument-hint: "<plan-file-path>"
allowed-tools: ["Read", "Edit", "Grep", "Bash"]
---

# /annotate-plan — Research-Plan-**Annotate**-Implement 품질 게이트

## When to use
`/plan` 또는 `/ultraplan` 산출물이 생성된 직후 **구현 시작 전** 필수 실행. 대표님이 플랜 문서에 라인별 이견·추가 요구·뉘앙스를 `<!-- 👉 ... -->` 형태로 주석 달면 에이전트가 이를 수집하여 플랜에 반영, 주석 제거 후 재제출. 정합성 수렴(주석 0개)까지 최대 6회 반복.

## Why this exists
현재 JamesClaw 하네스는 자동 검수(pipeline-run, 외부 LLM 3종, ultrareview)는 강력하나 **인간 판단 주입 게이트**가 약함. 플랜 오차가 구현 단계에서야 드러나 재작업 비용 증가. Annotate 루프는 플랜 승인 **전** 인간 판단을 세밀히 주입하는 공식 경로.

## Procedure

### 1단계 — 주석 수집
- 대표님이 전달한 플랜 파일(`$1`)을 Read
- `<!-- 👉 ... -->` 또는 `<!-- 대표님: ... -->` 패턴을 Grep으로 전부 추출
- 주석 0개면 "수렴 완료" 보고 후 종료 (다음 단계: 구현)

### 2단계 — 주석 분류
각 주석을 다음 카테고리로 분류:
| 카테고리 | 예시 |
|---|---|
| **변경 지시** | "이 섹션은 Firebase 대신 Cloudflare Workers로" |
| **추가 요구** | "이 API에 rate limiting 추가" |
| **뉘앙스 수정** | "우선순위를 SEO > UX로 변경" |
| **질문** | "왜 이 접근을 선택했나? 근거 명시" |
| **삭제** | "이 단계는 빼자 (이미 P-012에서 해결됨)" |

### 3단계 — 플랜 업데이트
- 각 주석의 요구를 반영하여 플랜 **직접 수정** (Edit 도구)
- 질문 카테고리는 플랜 하단 "Rationale" 섹션에 근거 추가
- **주석은 전부 제거** (다음 라운드에서 새 주석만 남도록)

### 4단계 — 변경 요약
- 수정한 섹션·라인 목록 표로 요약 (대표님에게 200자 이내)
- 반영 방식이 주석 의도와 다를 수 있는 항목은 근거 함께 명시

### 5단계 — 재제출 + 다음 주석 대기
- 업데이트된 플랜 파일 경로를 다시 대표님께 안내
- 대표님이 새 주석 달면 1단계로 돌아감

## Convergence rules
- **최대 6회 반복**. 6회차에도 주석이 있으면 Stop + 대표님에게 "수렴 실패, 플랜 전면 재설계 요청" 보고
- 주석 0개 달성 시 `docs/plan-*.md` 파일 상단에 `<!-- ANNOTATE-APPROVED: YYYY-MM-DD -->` 헤더 추가 → **Build Transition Rule이 이 헤더를 검증하여 구현 진입 허용**
- 주석 수렴 없이 구현 시작 시도 → Build Transition hook이 exit 2로 차단

## Output format
```markdown
## Annotate Round N

### 주석 수집: X건
- Line 42: 변경 지시 — "Firebase → Cloudflare Workers"
- Line 58: 추가 요구 — "rate limiting"
- ...

### 반영 변경
| Line | Before | After | 근거 |
|------|--------|-------|------|
| 42 | Firebase Hosting | Cloudflare Workers | 대표님 지시 |
| 58 | (추가) | Rate limit 100 req/min | 대표님 지시 |

### 다음 라운드
플랜 경로: `docs/plan-xxx.md`
추가 주석 달고 `/annotate-plan docs/plan-xxx.md` 재실행.
```

## Related
- `/plan` — 중복잡도 / 오프라인 플랜 (Claude 내장 Plan 모드, 로컬)
- `/ultraplan` — 고복잡도 병렬 플랜 (클라우드 VM, 3탐색+1비평)
- `/pipeline-run` — 구현 후 7단계 품질 검증
- ⚠️ `/deep-plan` — **deprecated (2026-04-21)**. 실체 없음 확인. 대체: `/pipeline-install` + `/annotate-plan` + `/qa` 조합
- Reference: [Boris Tane - Research/Plan/Annotate/Implement](https://boristane.com/blog/how-i-use-claude-code/)
