# /blog-generate — 키워드 → SEO 리서치 → 초안 생성 → 팩트 검증 → 이미지 선택

키워드 1개를 받아 블로그 글 초안을 자동 생성하는 Skills-First 파이프라인.
Claude Max 구독 내 실행. 추가 인프라 비용 없음.

## 사용법
- `/blog-generate "키워드"` — 키워드로 블로그 글 초안 생성
- `/blog-generate "키워드" --platform wp,naver,tistory` — 플랫폼 지정 (기본: 전체)
- `/blog-generate "키워드" --tone casual` — 톤 지정 (기본: professional)

## 산출물
- `MultiBlog/drafts/{date}-{slug}/draft.md` — 마크다운 초안
- `MultiBlog/drafts/{date}-{slug}/meta.json` — SEO 메타, 이미지 URL, 생성 로그
- `MultiBlog/drafts/{date}-{slug}/status.json` — 상태 (`draft` → `/blog-review`가 전환)
- `MultiBlog/drafts/{date}-{slug}/images/` — 다운로드된 이미지

## 실행 절차

### Phase 1: SEO 키워드 리서치

**1-1. SERP 분석 (Tavily search MCP)**
```
Tavily search: search_depth="basic", max_results=5
쿼리: "{키워드} 블로그" 또는 "{키워드} 추천 2026"
수집: 상위 5개 URL, 제목, 메타 디스크립션, 주요 H2 구조
```

**1-2. 관련 키워드 클러스터 (Perplexity search MCP)**
```
Perplexity search: "{키워드} 관련 검색어 AND 자주 묻는 질문"
수집: relatedKeywords[], questions[] (FAQ 소스)
```

**1-3. 경쟁 콘텐츠 분석**
- 상위 3개 URL을 Tavily extract로 본문 수집
- H2/H3 구조, 글 길이, 이미지 수, FAQ 여부 분석
- 차별화 포인트 1개 이상 식별

**1-4. SEO 데이터 집계**
```json
{
  "primaryKeyword": "...",
  "relatedKeywords": ["...", "..."],
  "questions": ["...", "..."],
  "serpMeta": [{"url": "...", "title": "...", "h2s": [...]}],
  "competitorAvgLength": 2500,
  "differentiationPoint": "..."
}
```
이 데이터를 `meta.json`의 `seo` 필드에 저장.

### Phase 2: 초안 생성 (멀티모델 오케스트레이션)

**2-1. 프롬프트 구성**
Opus가 SEO 데이터 기반으로 프롬프트를 설계:
```
[구조 제약]
- H2 최소 3개, H3로 세분화
- FAQ 섹션 2개+ 질문-답변 쌍 (Phase 1에서 수집한 questions 활용)
- 본문 2,000자+ (경쟁사 평균 이상)
- 메타 디스크립션 120~155자
- 핵심 키워드 본문 3회+ 자연 삽입
- 내부링크 2개+ 삽입 위치 표시 ([INTERNAL_LINK:주제])
- 이미지 삽입 위치 표시 ([IMAGE:설명])

[톤 가이드]
- 1인칭 경험 기반 서술 ("직접 사용해본 결과...")
- AI 클리셰 금지: "다양한", "혁신적인", "획기적인", "~에 대해 알아보겠습니다"
- 구어체 자연스러움. 블로그 독자와 대화하는 느낌.
- 구체적 수치/사례 우선. 추상적 설명 최소화.

[차별화]
- Phase 1에서 식별한 차별화 포인트 반영
- 경쟁사가 다루지 않은 각도 1개 이상
```

**2-2. Sonnet 서브에이전트 초안 작성**
```
Agent(model: sonnet, prompt: "위 프롬프트로 블로그 글 마크다운 초안 작성. frontmatter(title, description, keywords, date) 포함.")
```
- 타임아웃 3분. 실패 시 다음 모델로 fallback.

**2-3. Fallback 체인**
1순위: Sonnet 서브에이전트 (`Agent(model: sonnet)`)
2순위: Codex CLI (`codex exec "..."`)
3순위: Gemini CLI (`gemini -p "..."`) — 설치 확인 후
4순위: Gemma 4 로컬 (`curl localhost:11434/api/generate`)

성공한 모델을 `meta.json`의 `generator` 필드에 기록.

### Phase 3: 팩트 검증

**3-1. 수치/날짜/스펙 추출**
Opus가 초안에서 검증 가능한 주장을 추출:
- 가격, 출시일, 스펙 수치, 통계, 순위
- 각 주장에 대해 `[VERIFY: "주장 내용"]` 태그 부여

**3-2. 원문 대조 (Tavily extract)**
```
각 [VERIFY] 항목에 대해:
1. Tavily extract로 권위 소스(공식 사이트, 위키, 뉴스) 원문 수집
2. 초안 내용과 대조
3. 일치 → 태그 제거
4. 불일치 → 자동 수정 시도. 수정 불가 → [FACT_CHECK] 태그로 변환
5. 검증 불가 → 해당 문장 삭제 또는 "확인 필요" 표시
```

**3-3. 검증 로그 기록**
`meta.json`의 `factCheck` 필드에 검증 결과 배열 저장.

### Phase 4: 이미지 선택

**4-1. 이미지 소스 수집**
초안의 `[IMAGE:설명]` 위치마다:
```
1순위: 관련 URL의 og:image 메타태그 (curl -sI → og:image CDN URL)
2순위: Tavily extract로 제품 페이지 썸네일 수집
3순위: 검색 결과 이미지 (저작권 주의 — 제품 공식 이미지만)
```

**4-2. 이미지 검증**
- HTTP 200 확인 (`curl -sI {url}`)
- Opus Vision으로 주제 매칭 확인 (`Read` 도구로 이미지 직접 확인)
- 파일 확장자-실제 포맷 일치 확인
- loading="lazy" 금지 (P-001)

**4-3. 이미지 다운로드 + 삽입**
```bash
curl -o "MultiBlog/drafts/{date}-{slug}/images/{n}.jpg" "{url}"
```
초안의 `[IMAGE:설명]`을 실제 마크다운 이미지 문법으로 교체:
```markdown
![{alt}](images/{n}.jpg)
```

### Phase 5: 저장 + 완료

**5-1. 파일 저장**
```
MultiBlog/drafts/{date}-{slug}/
├── draft.md          — 완성된 마크다운 초안
├── meta.json         — SEO 데이터, 생성 로그, 팩트 검증, 이미지 매핑
├── status.json       — { "status": "draft", "createdAt": "...", "generator": "..." }
└── images/           — 다운로드된 이미지 파일
```

**5-2. 결과 보고**
대표님께 터미널 또는 텔레그램으로 요약:
```
✅ /blog-generate 완료
📄 "{제목}" (2,450자)
🔍 SEO: 키워드 "{키워드}" 5회, FAQ 3개, 내부링크 2개
🖼️ 이미지 4장 (검증 완료)
⚠️ 팩트 체크 미확인 1건: [내용]
📁 MultiBlog/drafts/{date}-{slug}/
➡️ 다음: /blog-review 로 품질 검증
```

**5-3. 하네스 증거 기록**
```bash
echo "blog-generate: {slug} | {generator} | {wordcount}자 | $(date)" >> ~/.harness-state/last_result.txt
```

## 품질 기준 (Phase 완료 조건)
- [ ] 본문 2,000자+ (경쟁사 평균 이상)
- [ ] H2 3개+, FAQ 2개+
- [ ] 핵심 키워드 3회+ 자연 삽입
- [ ] 메타 디스크립션 120~155자
- [ ] 이미지 alt 태그 전수
- [ ] 팩트 검증 통과 또는 미확인 항목 명시
- [ ] AI 클리셰 0개 (Phase 2 톤 가이드 준수)
- [ ] 생성 시간 < 5분

## 에러 처리
- MCP 호출 실패 → 3회 재시도 후 해당 Phase 스킵 + 로그 기록
- CLI fallback 전체 실패 → 대표님 보고 (텔레그램 또는 터미널)
- 이미지 다운로드 실패 → placeholder 삽입 + [IMAGE_FAILED] 태그
