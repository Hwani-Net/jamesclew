# /blog-review — 품질 게이트 7단계 + AI냄새 검사 + SEO 점수

`/blog-generate`로 생성된 초안을 발행 전 자동 검증하는 품질 게이트.
expect MCP 7단계 + 외부 모델 AI냄새 교차검수 + SEO 분석.

## 사용법
- `/blog-review` — `status.json`이 `draft`인 최신 초안 자동 선택
- `/blog-review MultiBlog/drafts/2026-04-11-keyword/` — 특정 초안 지정

## 산출물
- `MultiBlog/drafts/{slug}/quality-report.json` — 검증 결과 전체
- `MultiBlog/drafts/{slug}/status.json` — `ready` (통과) 또는 `failed` (실패)
- `MultiBlog/reports/quality-summary.json` — 누적 통계 업데이트

## 실행 절차

### Phase 1: 프리뷰 렌더링 (expect MCP 7단계)

로컬 프리뷰 서버가 필요. Next.js dev 서버 또는 간단 HTTP 서버 사용.

**1-1. 프리뷰 서버 기동**
```bash
# 초안을 프리뷰할 수 있는 환경 확인
# 방법 A: Next.js 앱에 draft 주입 후 dev 서버
cd MultiBlog/app/web && pnpm dev &
# 방법 B: 마크다운을 HTML로 변환 후 간단 서버
npx marked draft.md -o preview.html && npx serve .
```
프리뷰 URL 확보: `http://localhost:3000/preview/{slug}` 또는 `http://localhost:3000/preview.html`

**1-2. expect MCP 7단계 실행**
```
Step 1: mcp__expect__open → 프리뷰 URL 로드
Step 2: mcp__expect__screenshot → 렌더링 확인
  - 빈 페이지 감지: 스크린샷 Read 후 Opus Vision으로 "이 페이지가 정상 렌더링되었는가?" 판단
  - 에러 페이지 감지: "404", "Error", "Not Found" 텍스트 존재 여부
Step 3: mcp__expect__network_requests → 실패 리소스 0건
  - 404, 혼합 콘텐츠(http→https), CORS 에러 필터링
Step 4: mcp__expect__console_logs → error 레벨 0건
  - warning은 로그만, error는 FAIL
Step 5: mcp__expect__performance_metrics → LCP < 2.5s, CLS < 0.1
Step 6: mcp__expect__accessibility_audit → critical 위반 0건
Step 7: mcp__expect__close → 세션 정리
```

각 Step 결과를 `quality-report.json`의 `expectGates[]`에 기록:
```json
{ "step": 1, "name": "open", "pass": true, "detail": "200 OK, 1.2s" }
```

**프리뷰 서버 없는 경우 (Phase 0.5 최소 모드)**:
expect MCP 7단계를 스킵하고 Phase 2~4만 실행. `quality-report.json`에 `"expectSkipped": true` 기록.
발행 후 post-deploy 검증(T18)에서 라이브 URL로 7단계 실행.

### Phase 2: AI 냄새 검사 (외부 모델 교차검수)

**2-1. Antigravity 검사**
```bash
DRAFT=$(cat "MultiBlog/drafts/{slug}/draft.md")
opencode run -m "anthropic/claude-sonnet-4-20250514" "다음 블로그 글이 AI가 쓴 것처럼 느껴지는 부분을 지적하라. 각 부분에 대해 이유를 설명하고, 전체 AI 생성 확률을 0~100 점수로 평가하라. 점수만 마지막 줄에 'SCORE: NN' 형식으로 출력.

---
$DRAFT"
```
출력에서 `SCORE: NN` 파싱 → `aiSmell.antigravity` 필드에 기록.

**2-2. 벤치마크 비교 평가 (단독 평가보다 우선)**
```bash
# Step 1: 같은 키워드 상위 인간 블로그 2개를 Tavily extract로 수집
# Step 2: 인간 글 + 우리 글을 함께 제시하여 비교 평가
bash harness/scripts/codex-rotate.sh "아래 글A는 인간 블로거가 쓴 상위 랭킹 블로그 글이다. 글C는 평가 대상이다.
글C가 글A와 비교하여 자연스러움, 톤, 문체에서 어떤 차이가 있는지 분석하라.
평가 기준: 종결어미 다양성, 개인 경험 구체성, 독자 대화감, 스펙vs상황 비율, 전체 자연스러움(0~100).
마지막 줄에 'SCORE: NN' 형식으로 점수 출력. 개선 포인트 3가지 구체적 지적.

=== 글A (인간) ===
{tavily_extract로 수집한 인간 블로그 본문}

=== 글C (평가 대상) ===
$(cat MultiBlog/drafts/{slug}/draft.md)"
```
출력에서 `SCORE: NN` 파싱 → `aiSmell.benchmark` 필드에 기록.
**인간 블로그 수집 실패 시**: Tavily search → extract 재시도. 실패 시 단독 평가로 폴백.

**2-3. 최종 AI냄새 점수 산출**
```
기본: benchmark 점수 사용 (0~100, 높을수록 자연스러움)
- > 65: PASS ✅
- 50~65: WARN ⚠️ (통과하지만 /blog-fix 권고)
- < 50: FAIL ❌

폴백 (벤치마크 불가 시): 단독 평가 (antigravity + codex) / 2
- < 30: PASS, 30~50: WARN, > 50: FAIL
```
⚠️ 단독 평가는 한국어 블로그에 대해 정확도가 낮음 (78~86 고정 범위 관찰). 벤치마크 비교를 우선 사용할 것.

**외부 CLI 실패 시**: codex-rotate.sh가 6계정 로테이션 + gemma4 폴백 자동 처리.

### Phase 3: SEO 점수 검사

Opus 또는 Sonnet 서브에이전트가 초안을 직접 분석:

```
체크리스트:
□ 핵심 키워드 본문 3회+ 출현 (Grep으로 카운트)
□ 메타 디스크립션 120~155자 (frontmatter에서 추출)
□ H2 최소 3개, H3 계층 구조 (마크다운 파싱)
□ 내부링크 2개+ (마크다운 링크 카운트)
□ FAQ 섹션 2개+ 질문-답변 쌍
□ 이미지 alt 태그 전수 (마크다운 이미지 문법 확인)
□ 본문 2,000자+ (wc -m)
```

각 항목 PASS/FAIL → `quality-report.json`의 `seo` 필드에 기록.
6/7 이상 PASS → SEO 통과. 5 이하 → FAIL.

### Phase 4: 이미지 검증

**4-1. 이미지 파일 존재 + HTTP 확인**
```bash
# 로컬 이미지 파일 존재 확인
ls MultiBlog/drafts/{slug}/images/
# 원본 URL HTTP 200 확인 (meta.json에서 URL 추출)
curl -sI "{original_url}" | head -1
```

**4-2. Opus Vision 주제 매칭**
```
각 이미지를 Read 도구로 직접 확인:
- "이 이미지가 '{키워드}' 블로그 글의 대표 사진으로 적합한가?"
- 제품이면 정면 제품샷, 장소면 외관/간판 필수
- 복도/주방/배경 사진 → FAIL
```

**4-3. 중복 체크**
동일 블로그 내 기존 이미지와 시각적 중복 없는지 확인.

### Phase 5: PITFALLS 규칙 체크

```bash
# PITFALLS.md에서 콘텐츠 관련 규칙 추출
cat ~/.claude/PITFALLS.md
```
각 P-NNN 규칙에 대해 초안 위반 여부 자동 검사:
- P-001: loading="lazy" 사용 여부
- 기타 콘텐츠 관련 규칙

### Phase 6: 결과 집계 + 판정

**6-1. quality-report.json 생성**
```json
{
  "slug": "...",
  "timestamp": "...",
  "expectGates": [...],
  "aiSmell": { "antigravity": 25, "codex": 20, "final": 22, "verdict": "PASS" },
  "seo": { "keywordCount": 5, "metaDesc": 142, "h2Count": 4, ... , "verdict": "PASS" },
  "images": { "count": 4, "allValid": true, "topicMatch": true, "verdict": "PASS" },
  "pitfalls": { "violations": [], "verdict": "PASS" },
  "overall": "PASS"
}
```

**6-2. 상태 전환**
- 전체 PASS → `status.json`을 `{ "status": "ready" }`로 업데이트
- 1개라도 FAIL → `status.json`을 `{ "status": "failed", "failedGates": [...] }`로 업데이트

**6-3. 결과 보고**
```
✅ /blog-review 완료 — PASS
📄 "{제목}"
🤖 AI냄새: 22/100 (PASS) — Antigravity 25, Codex 20
🔍 SEO: 6/7 통과 — 키워드 5회, FAQ 3개
🖼️ 이미지: 4/4 검증 완료
➡️ 다음: /blog-publish 로 발행

또는

❌ /blog-review 완료 — FAIL
📄 "{제목}"
🤖 AI냄새: 55/100 (FAIL) — Antigravity 60, Codex 50
🔍 SEO: 4/7 통과 — 내부링크 부족, FAQ 부족
➡️ 다음: /blog-fix 로 자동 수정
```

**6-4. 하네스 증거 기록**
```bash
echo "blog-review: {slug} | overall={verdict} | aiSmell={score} | seo={pass}/{total} | $(date)" >> ~/.harness-state/last_result.txt
```

### Phase 7: 누적 통계 업데이트

`MultiBlog/reports/quality-summary.json` 갱신:
```json
{
  "totalReviewed": 15,
  "firstPassRate": 0.80,
  "avgAiSmellScore": 28,
  "avgSeoScore": 5.8,
  "escalationRate": 0.05,
  "lastUpdated": "..."
}
```

## 판정 임계값 (조정 가능)

`MultiBlog/config/quality-thresholds.json`에서 로드:
```json
{
  "aiSmell": { "pass": 30, "warn": 50 },
  "seoMinPass": 5,
  "keywordMinCount": 3,
  "metaDescRange": [120, 155],
  "minH2": 3,
  "minFaq": 2,
  "minInternalLinks": 2,
  "minWordCount": 2000
}
```

## 에러 처리
- expect MCP 서버 미응답 → Phase 1 스킵, Phase 2~4만 실행
- 외부 CLI 전체 실패 → Sonnet 서브에이전트 교차검수로 임시 대체
- SCORE 파싱 실패 → 정규식 `SCORE:\s*(\d+)` 재시도 3회, 실패 시 50점 (보수적)
