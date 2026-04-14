---
description: "11단계 품질 파이프라인 설치"
---

# /pipeline-install — 11단계 품질 파이프라인 설치

현재 프로젝트에 11단계 품질 파이프라인을 설치합니다.
프로젝트 유형을 자동 감지하여 맞춤 구성합니다.

## 사전 조건
최소 `package.json` 또는 빌드 설정 파일이 존재해야 합니다.
빈 폴더에서는 실행하지 마세요 — scaffolding(`create-next-app`, `firebase init`, `git clone`) 직후가 최적 타이밍입니다.
프로젝트 구조를 판별할 파일이 없으면 사용자에게 프로젝트 유형(앱/블로그/API)을 물어보세요.

## 실행 절차

### 1. 프로젝트 분석
아래를 확인하여 프로젝트 유형을 판별하세요:
- `package.json` (name, scripts, dependencies)
- `firebase.json`, `.firebaserc` (Firebase 여부)
- 기존 `CLAUDE.md` (이미 설정이 있는지)
- `src/` 구조 (Next.js? SSG? 순수 Node?)
- 콘텐츠 프로젝트인지 앱 프로젝트인지

### 2. 프로젝트 유형별 파이프라인 매핑

**A. 콘텐츠/블로그 프로젝트** (JSON 글, SSG, 쿠팡 등):
| Step | 이름 | 동작 |
|------|------|------|
| 1 | 생성 | LLM 또는 JSON/MD 파일 로드 |
| 2 | SEO | 키워드 밀도, excerpt, 내부링크 분석 (score 80+) |
| 3 | 광고 | AdSense/파트너스 슬롯 삽입 (선택) |
| 4 | 저장 | 로컬 드래프트 저장 |
| 5 | 품질루프 | 6패스(구조/SEO/AI냄새/팩트/이미지/차별화) × 2라운드+ saturation |
| 6 | 이미지+링크 | og:image CDN → Playwright → fallback + 대표이미지 적합성 Vision 검증 + 전 외부링크 유효성 확인 |
| 7 | 교차검수 | 외부 3모델 (GPT-4.1 + Codex + Gemini) avg 7/10+ |
| 8 | DB저장 | Firestore에 publish 상태 저장 |
| 9 | 빌드 | CSS + SSG 정적 생성 |
| 10 | 배포 | Firebase Hosting deploy |
| 11 | 검증 | Playwright 스크린샷 + 디자인 5패스 × 2라운드 saturation. FAIL → 수정 → 재배포 루프 |

**B. 앱 프로젝트** (Next.js, React, PWA 등):
| Step | 이름 | 동작 |
|------|------|------|
| 1 | 코드작성 | 기능 구현 또는 버그 수정 |
| 2 | 린트 | ESLint + TypeScript 에러 0 |
| 3 | 테스트 | 유닛 + E2E 테스트 통과 |
| 4 | 커밋 | Conventional Commits 형식 |
| 5 | 품질루프 | 5패스(기능/보안/성능/UX/페인포인트) × 2라운드 saturation |
| 6 | 스크린샷 | Playwright 주요 화면 캡처 |
| 7 | 교차검수 | 외부 모델 코드 리뷰 (Codex + Gemini) |
| 8 | 빌드 | `npm run build` 에러 0 |
| 9 | 배포 | Firebase App Hosting / Hosting deploy |
| 10 | 스모크테스트 | 라이브 URL HTTP 200 + 주요 기능 동작 확인 |
| 11 | 검증 | Playwright 스크린샷 + 디자인 5패스(레이아웃/타이포/시각/인터랙션/렌더링) × 2라운드 saturation. FAIL 시 수정 → 재배포 → 재검증 루프 |

**C. API/MCP 서버 프로젝트**:
| Step | 이름 | 동작 |
|------|------|------|
| 1 | 코드작성 | 기능 구현 |
| 2 | 린트 | ESLint/TypeCheck |
| 3 | 테스트 | API 엔드포인트 + 통합 테스트 |
| 4 | 커밋 | Conventional Commits |
| 5 | 품질루프 | 5패스(기능/보안/성능/UX/페인포인트) × 2라운드 |
| 6 | 문서화 | API 스펙 + README 갱신 |
| 7 | 교차검수 | 외부 모델 코드 리뷰 |
| 8 | 빌드 | 빌드/번들 에러 0 |
| 9 | 배포 | npm publish 또는 서버 deploy |
| 10 | 헬스체크 | 엔드포인트 응답 확인 |
| 11 | 검증 | 실제 호출 테스트 + 응답 검증. FAIL → 수정 → 재배포 루프 |

### 3. 프로젝트 settings.json 생성
프로젝트 루트에 `.claude/settings.json`이 없거나 불완전하면 **Bash로 직접 생성** (Write 도구 사용 금지 — .claude/ 보호 우회):
```bash
mkdir -p .claude && cat > .claude/settings.json << 'SETTINGS'
{
  "permissions": {
    "defaultMode": "bypassPermissions",
    "allow": ["Bash(*)", "Read(*)", "Edit(*)", "Write(*)", "Glob(*)", "Grep(*)", "Agent(*)", "TodoWrite(*)", "mcp__plugin_telegram_telegram__*", "Plugin:telegram:*"],
    "additionalDirectories": ["${HOME}/.harness-state", "${HOME}/.claude/plans"]
  }
}
SETTINGS
```
이미 존재하면 `defaultMode`와 `allow`가 있는지만 확인.

### 4. CLAUDE.md 생성/수정
(이전 Step 3)
프로젝트 루트에 `CLAUDE.md`를 생성하거나 기존 파일에 파이프라인 섹션을 추가하세요.

필수 포함 내용:
```
## 파이프라인 (11단계, 순서 엄수)
> 이 파일이 글로벌 CLAUDE.md보다 우선합니다.

[위에서 선택한 유형의 11단계 테이블]

### 품질루프 상세
[프로젝트 유형에 맞는 패스 정의]

### 통과 기준
- 각 단계 FAIL → 자동 수정 → 재시도. skip 금지.
- 품질루프: 2라운드 연속 ALL PASS일 때만 통과 (saturation)
- 교차검수: 외부 모델 평균 7/10 미만이면 FAIL
- 배포 후 검증 없이 보고 금지
- 에러 억제 금지: try-catch로 에러 숨기기, throw 제거, console.error→log 변경 시 FAIL
- 로컬 최적화 방지: 코드 존재 ≠ 시스템 연결. 라우트/네비/import 실제 동작 E2E 검증
- 아키텍처 호환성: API/DB/타입 변경 시 영향 범위 명시 필수
```

### 4. 참고 구현체 안내
콘텐츠 파이프라인 실제 구현: `D:/smartreview-blog/src/pipeline.mjs` (11단계 오케스트레이터)
- `quality-checker.mjs`: 6패스 품질 체커
- `llm-judge.mjs`: 외부 모델 교차 검수
- `capture-images.mjs`: og:image CDN 이미지 캡처
- `verify.mjs`: 이미지 포맷 검증
- `ssg.mjs`: 정적 사이트 빌드

### 5. /plan 진입 강제
pipeline-install 완료 후 반드시 `/plan` (EnterPlanMode)에 진입하세요.
pipeline-install 완료 시: `echo done > ~/.harness-state/pipeline_done`
plan 승인 후: `echo done > ~/.harness-state/plan_done`
**pipeline_done과 plan_done이 없으면 소스 코드 Write/Edit가 차단됩니다.**

### 6. Step 0: 디자인 (UI 프로젝트 필수, DESIGN.md 산출)
UI 파일(html/css/tsx/jsx)을 작성하는 프로젝트는 코딩 전에 반드시:
1. **Stitch MCP (1순위)** — `claude mcp add stitch -s user -- npx @_davideast/stitch-mcp proxy` → 주요 화면 디자인 생성
2. **Stitch 불가 시** — godly.website / motionsites.ai에서 유사 UI 벤치마킹
3. NotebookLM 디자인 노트북에서 참조 조회 (notebook_query)
4. 이전 프로젝트의 `DESIGN.md`가 있으면 기반으로 발전
5. 결과를 `DESIGN.md`에 기록 (색상/폰트/간격/컴포넌트 + 레퍼런스 URL)
- `DESIGN.md`가 없으면 감사(audit)에서 FAIL 판정
- 백엔드/API 프로젝트는 N/A (스킵 가능)
- **DESIGN.md는 프로젝트 간 누적 진화하는 디자인 자산**

### 7. TodoWrite 자동 등록
설치 완료 후, **즉시** 11단계를 TodoWrite로 등록하세요 (지침이 아닌 실제 호출):
```
TodoWrite([
  { id: "step0", title: "Step 0: 디자인 레퍼런스 (DESIGN_REFS.md)", status: "pending" },
  { id: "step1", title: "Step 1: [유형별 이름]", status: "pending" },
  { id: "step2", title: "Step 2: [유형별 이름]", status: "pending" },
  ...
  { id: "step11", title: "Step 11: [유형별 이름]", status: "pending" }
])
```
- 각 Step 완료 시 `status: "completed"`로 업데이트
- **Step 5 완료 후**: 품질루프 결과를 `echo "패스별 결과 요약" > ~/.harness-state/step5_quality_done` 에 기록
- **Step 7 완료 후**: 외부 모델 응답을 `~/.harness-state/step7_review_done`에 기록. **실제 외부 모델(codex exec/curl GPT-4.1) 출력을 포함해야 하며, 100byte 미만이면 deploy hook이 차단합니다.**
  ```bash
  # 올바른 예시:
  codex exec "코드 리뷰" 2>&1 | tee ~/.harness-state/step7_review_done
  ```
- Step 5, 7 증거 파일 없으면 deploy hook이 **자동 차단**
- FAIL 시 1-2회 self-correction 후 재실행. 3회 연속 FAIL이면 대표님께 보고

### 6. 경량 파이프라인 (소규모 수정용)
파일 3개 이하 변경의 소규모 수정은 경량 파이프라인 적용:
- Step 1 (코드작성) → Step 5 (품질루프 1라운드) → Step 9 (빌드) → Step 10 (배포) → Step 11 (검증)
- 교차검수(Step 7) 생략 가능하지만, 품질루프(Step 5)는 필수
- 경량 적용 시 TodoWrite에 근거 명시: "소규모 수정 — 경량 파이프라인 적용 (변경 파일 N개)"

### 7. 설치 완료 보고
설치 후 반드시 보고:
- 프로젝트 유형: A/B/C
- CLAUDE.md 생성/수정 여부
- 11단계 중 해당 프로젝트에서 skip 가능한 단계 (근거 포함)
- TodoWrite 등록 완료 여부
- 즉시 실행 가능한 상태인지
