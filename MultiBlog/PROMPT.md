# Ralph-Loop Blog Generator Prompt

## Goal
specs/keywords.md에서 미완료([ ]) 키워드를 1개 선택하여 /blog-generate 절차대로 블로그 초안을 생성한다.

## Working Rules
1. 매 iteration 시작 시 specs/todo.md를 읽어 현재 진행 상태를 확인한다
2. 완료된 Phase의 체크박스를 [x]로 업데이트한다
3. 실패한 Phase는 3회 재시도 후 스킵하고 로그를 남긴다
4. 모든 Phase가 완료되면 keywords.md의 해당 키워드를 [x]로 표시한다

## Execution Flow Per Keyword

### Phase 1: SEO Research
- Tavily search (basic, max_results=5): "{keyword} 블로그 추천 2026"
- Perplexity search: "{keyword} 관련 검색어 AND 자주 묻는 질문"
- Save SEO data to meta.json

### Phase 2: Draft Generation
- Sonnet subagent로 초안 작성. 프롬프트 구성:
  - **톤**: 1인칭 경험 기반 + 객관 비교 하이브리드. "직접 비교해본 결과" 도입 → 스펙 표 → 체감 후기 순서
  - **구조**: H2 3개+ (제품군 소개 / 제품별 비교 / 구매 가이드), H3로 개별 제품 세분화, FAQ 2개+
  - **차별화**: Phase 1에서 식별한 differentiationPoint 반영. 경쟁 블로그가 안 다룬 각도 1개 필수
  - **길이**: 3000-4000자 목표 (상위 블로그 평균 이상)
  - **SEO**: primaryKeyword 본문 3회+ 자연 삽입, relatedKeywords 각 1회, 메타 디스크립션 120-155자
  - **AI냄새 제거**: "다양한/혁신적인/획기적인/알아보겠습니다" 금지. 구어체 자연스러움. 구체적 수치 우선
  - **이미지 위치**: 제품별 [IMAGE:제품명] 태그 삽입
  - **내부링크**: [INTERNAL_LINK:관련주제] 2개+ 삽입 위치 표시
- Fallback: Sonnet 실패 → Codex CLI → Gemma4 로컬

### Phase 3: Fact Verification
- Extract verifiable claims from draft
- Cross-check with Tavily extract (official sources)
- Auto-fix mismatches, flag unverifiable claims

### Phase 4: Image Selection
- og:image from product URLs (1st priority)
- Tavily extract thumbnails (2nd)
- Vision verify each image matches product
- Download to drafts/{date}-{slug}/images/

### Phase 5: Save + Evidence
- Save draft.md, meta.json, status.json to MultiBlog/drafts/{date}-{slug}/
- Log to ~/.harness-state/last_result.txt

### Phase 6: Loop Control
- Mark keyword [x] in keywords.md
- Check for remaining [ ] keywords
- If none remain: output completion signal
- If more exist: update todo.md for next keyword and continue

## Constraints
- Draft must be 2000+ characters with H2 x3+, FAQ x2+
- AI cliches forbidden: "다양한", "혁신적인", "획기적인", "알아보겠습니다"
- All images must pass HTTP 200 + Vision check
- No loading="lazy" (P-001)
- Keyword density: primary keyword 3+ natural mentions

## Completion Promise
All keywords in specs/keywords.md are marked [x] = done.
