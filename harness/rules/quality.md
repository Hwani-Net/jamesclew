# Quality Rules

## Verification
코드 변경 후 테스트 실행. 빌드 성공 확인 후 커밋.
태스크를 complete로 표시하기 전 반드시 검증.

## Post-Deploy Verification (필수)
배포(`firebase deploy`, `gh-pages`, 등) 실행 후 반드시:
1. 라이브 URL에 HTTP 200 응답 확인 (index, sitemap, 주요 페이지)
2. 검증 통과 시에만 대표님께 결과 보고
3. 검증 실패 시 자동 롤백 또는 즉시 수정 후 재배포
배포 후 검증 없이 보고하면 안 됨. Hook이 자동 검증을 강제함.

## Image & Link Verification (필수)
블로그/앱의 이미지·링크 삽입 시 반드시:
1. 캡처 우선순위: og:image CDN 800x800 (1순위) → expect MCP(mcp__expect__screenshot) (2순위) → agent-browser CDP (3순위)
2. 제조사 공식 이미지 사용 금지 — 쿠팡 제품 페이지 썸네일만 사용
3. 저장 후 Read 도구로 이미지 내용을 직접 확인 (HTTP 200만으로 검증 완료 판단 금지)
4. 파일 확장자와 실제 포맷 일치 확인 (PNG를 .jpg로 저장하면 브라우저에서 깨짐)
5. Opus+Sonnet 서브에이전트 교차 검증으로 이미지-제품 매칭 확인
6. **같은 글 내 이미지 크기 통일** — 소스 해상도가 달라도 CSS로 표시 크기 고정 (현재 500px center). 새 캡처 시 800x800 우선
7. loading="lazy" 사용 금지 (PITFALLS P-001)
8. 배포 후 agent-browser로 전체 페이지 이미지 로드 확인 (naturalWidth > 0)
9. **대표 이미지 적합성 검증** — Vision으로 "이 이미지가 해당 항목의 대표 사진으로 적절한가?" 확인. 제품이면 정면 제품샷, 장소면 외관/간판이 보여야 함. 복도/주방/배경 사진은 FAIL.
10. **링크 유효성 주기적 검증** — 배포 시 전체 외부 링크(쿠팡, 다나와 등) HTTP 응답 확인. 404/301/만료 감지 시 gbrain pitfall 기록 + 자동 수정.

## Multi-Pass Review Protocol (콘텐츠 품질 강제)
결과물(블로그 글, 디자인, 코드)이 대표님께 보고되기 전 다단계 검토를 거침.
같은 관점으로 반복 검토하면 3~5회에서 포화 → **매 패스마다 관점이 달라야 함.**

### 콘텐츠(블로그 글) 검토 패스
| Pass | 관점 | 검토 항목 | 통과 기준 |
|------|------|----------|----------|
| 1 | 구조 | H2/H3 계층, 도입-본문-결론 흐름, 글 길이 | 구조 점수 8/10+ |
| 2 | SEO | 키워드 밀도, 메타 디스크립션, 내부링크, FAQ | 핵심 키워드 3회+, FAQ 2개+ |
| 3 | 독자 관점 | AI냄새 제거, 자연스러운 도입, 공감 포인트 | "AI가 쓴 것 같다" 느낌 0 |
| 4 | 사실 검증 | 가격, 스펙, 링크 유효성, 날짜 정확성 | 오류 0건 |
| 5 | 이미지/미디어 | 제품 썸네일 존재, alt 태그, 포맷 일치 | 모든 제품에 이미지 |
| 6 | 경쟁 대비 | 상위 블로그 대비 차별점, 정보 밀도 | 차별 포인트 1개+ |

### 멀티라운드 루프 (10회+ 개선 강제)
1패스 통과만으로 끝내지 않음. **전체 패스를 라운드 단위로 반복:**

```
라운드 1: Pass 1→2→3→4→5→6 순차 검토. FAIL 발견 시 즉시 수정
라운드 2: Pass 1→6 전체 재검토 (라운드 1 수정이 다른 패스를 깨뜨릴 수 있음)
  ...반복...
라운드 N: 6개 패스 전체 PASS → 완료
```

- **최소 2라운드** 필수 (1라운드 전체 PASS여도 2라운드 확인)
- 라운드 간 수정이 발생하면 카운터 리셋 → 다시 2라운드
- 각 라운드에서 **외부 검증 신호**(Playwright 렌더링, 실제 URL 접속, 이미지 Read 확인)를 1개 이상 포함해야 포화 방지
- 포화 감지: 2라운드 연속 수정 0건이면 완료로 판정

### 코드 검토 패스
| Pass | 관점 | 검토 항목 |
|------|------|----------|
| 1 | 기능 | 테스트 통과, 빌드 성공 |
| 2 | 보안 | OWASP Top 10, 시크릿 노출 |
| 3 | 성능 | 불필요한 반복, 메모리 누수, 번들 크기 |
| 4 | UX/접근성 | 전 버튼·링크 동작 확인, 네비게이션 흐름, 폼 입력·에러 처리, 접근성(a11y) |
| 5 | 사용자 페인포인트 | "이 화면에서 사용자가 막히는 곳은?" 관점, 불편사항 gbrain pitfall 기록 |

**Pass별 추가 감지 항목 (#10, #16, #20 방지):**
- **에러 억제 감지 (#10)**: git diff에서 try-catch 추가 + 기존 에러 핸들링 삭제, console.error→console.log 변경, throw 제거 패턴 발견 시 FAIL. "에러를 숨기지 말고 제대로 처리하라"
- **로컬 최적화 감지 (#20)**: 새 기능 구현 후 "코드 존재 ≠ 시스템 연결" 확인 필수. 라우트 등록, 미들웨어 연결, 메뉴/네비게이션 링크, import 경로가 실제 동작하는지 E2E로 검증
- **아키텍처 호환성 (#16)**: 교차검수 시 "이 변경이 다른 서비스/모듈에 영향을 주는가?" 항목 필수. API 응답 형식 변경, DB 스키마 변경, 공유 타입 변경은 영향 범위를 명시

### 디자인 검토 패스
| Pass | 관점 | 검토 항목 |
|------|------|----------|
| 1 | 레이아웃 | 그리드 정렬, 여백 일관성, 반응형 |
| 2 | 타이포그래피 | 계층 구조, 가독성, 폰트 일관성 |
| 3 | 시각적 완성도 | 이미지 품질, 색상 일관성, 다크모드 |
| 4 | 인터랙션 | hover 효과, 전환 애니메이션, 접근성 |
| 5 | 렌더링 검증 | expect MCP 풀페이지 스크린샷(mcp__expect__screenshot), 모바일/데스크톱 |

## Test Manipulation Guard [hook 강제: test-manipulation-guard.sh]
테스트 파일만 수정하고 소스를 안 고치는 패턴(#15 테스트 조작) 자동 감지.
- 테스트 파일(*.test.*, *.spec.*, __tests__/) 수정 시 소스 파일 수정 여부 교차 확인
- 테스트만 수정 + 소스 0개 → "테스트 조작 ALERT" 경고 주입
- 테스트 수정 > 소스 수정 → "테스트 조작 WARN" 경고 주입
- 금지: assertion 약화, mock 과다 사용, try-catch로 에러 숨기기, assertTrue(true)

## Change Tracker & Scope Guard [hook 강제: change-tracker.sh]
세션 내 모든 파일 변경을 추적하고 범위 이탈을 감지.
- 매 Write/Edit 후 변경 파일을 session_changes.log에 기록
- 50개 이상 파일 수정 시 스코프 크리프 경고 주입 (50/100/200 단계)
- CWD와 다른 드라이브의 파일 수정 시 "잘못된 파일?" 경고
- 세션 종료 시 변경 파일 전체 목록 확인 가능

## Regression Guard (회귀 방지) [hook 강제: regression-guard.sh]
파일 수정 시 의도하지 않은 회귀를 자동 감지.
- Write/Edit 후 git diff에서 삭제량이 추가량의 2배 이상 + 10줄 초과 → 경고 주입
- 수정 요청 시 Edit(부분 수정) 우선. Write(전체 덮어쓰기)는 최소화
- 과거 버전 복원(git checkout, 백업 복사) 시 반드시 현재 diff와 비교 후 진행
- 회귀 감지 시 gbrain에 pitfall 기록 (아래 절차 참조)

## PITFALLS Auto-Record (피드백 → 실수 기록 자동화) [hook 강제: user-prompt.ts]
대표님 지적 → 에이전트 동의 시 gbrain에 pitfall-NNN-{slug} 형식으로 즉시 기록.
- user-prompt.ts가 피드백 패턴 감지 시 PITFALLS 기록 지시를 자동 주입
- 기록 필수 항목: 증상, 원인, 해결, 재발 방지
- **기록 절차**:
  1. `gbrain query "증상키워드"` 로 유사 항목 확인
  2. 신규면: `D:/jamesclew/harness/pitfalls/pitfall-NNN-{slug}.md` 파일 작성
  3. `gbrain import D:/jamesclew/harness/pitfalls/` 실행
  (주의: `gbrain put --content` 는 multi-line 깨짐 — 절대 사용 금지)
- 기록하지 않으면 forgot_record 패턴으로 재감지 → 반복 지적

## Parallel Agent Safety (#14)
병렬 에이전트 운영 시 git 충돌 방지:
- Agent 도구의 `isolation: "worktree"` 옵션 사용 (Claude Code 내장)
- 브랜치별 1 에이전트 원칙 (동일 브랜치 2개 worktree 금지)
- 공유 리소스(DB, 포트, .env) 격리 필수
- Agent Teams + worktree 병렬 운영 가능 (v2.1.107+)
- `EnterWorktree(path: "existing/worktree")` — v2.1.105+에서 기존 worktree로 재진입 가능. 에이전트 재시작 시 유용
- **서브에이전트 MCP 도구 상속** (v2.1.101+): `Agent(model: "sonnet")` 호출 시 동적으로 추가된 MCP 도구(stitch, korean-law 등)도 자동 상속됨. 별도 전달 불필요.

## Self-Healing
1. 에러 메시지 정독 2. 근본 원인 파악 3. 수정 적용
4. 검증 5. 실패 시 3회 대안 시도 6. 3회 실패 후 보고

## Commits
Conventional Commits (영어). 논리적 단위 1커밋.

## Design Doc Sync (필수)
하네스(hooks, rules, settings.json)를 추가/수정하면 반드시 설계 문서도 동시에 업데이트:
- 설계 문서: `$OBSIDIAN_VAULT/01-jamesclaw/harness/harness_design.md` (env: OBSIDIAN_VAULT)
- 변경 이력 테이블에 날짜, 변경 내용, 근거 기록
- 설계 문서와 실제 구현이 불일치하면 안 됨
