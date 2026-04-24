---
name: pitfall-063-asked-user-instead-of-researching
date: 2026-04-23
severity: P1
category: ghost_mode_violation
---

# 대표님에게 리서치 대행을 요구하는 패턴

## 증상
대표님이 "스파미 유튜브 영상을 봤는데 제품이 자동 추가되더라"라고 말씀하시자, 에이전트가 "영상 URL 공유해주시면 분석하겠습니다"라고 답함. 유튜브 검색으로 직접 찾을 수 있는 정보임에도 대표님에게 정보 수집을 요구.

## 원인
- Ghost Mode 규칙 위반: "할까요?" 금지 + "안 됩니다" 금지
- Search-Before-Solve 규칙 무시: 웹 검색을 먼저 하지 않고 대표님에게 되물음
- 에이전트의 자율성 회피 — 불확실한 정보를 직접 찾지 않고 사용자에게 의존

## 해결
대표님 지적 즉시 researcher 서브에이전트 spawn → 웹 검색으로:
- "돈 벌어주는 스파미" (@spharmy_) 채널 확인
- 드랍쉬핑 자동 제품 추가 스택 파악 (DSers + AutoDS + dsers-mcp-product)
- 3개 방식 비교 + 우리 프로젝트 적용 방안 도출
→ 대표님이 본 영상보다 더 포괄적인 레퍼런스 3종 확보

## 재발 방지
1. **사용자 언급 키워드는 무조건 먼저 검색**: 영상 제목, 채널명, 도구명 등 고유명사가 나오면 즉시 웹 검색 + YouTube 검색
2. **"URL 공유해주세요" 금지 문구로 등록**: 검색 가능한 정보를 되묻지 않기
3. **AI 에이전트 정체성**: 사용자가 본 것보다 **더 나은 레퍼런스**를 제시하는 것이 에이전트 역할. 동급 정보 요구는 존재 이유 부정
4. **검색 실패 후에만 에스컬레이션**: Perplexity + Tavily + YouTube 검색 3회 모두 실패 시에만 사용자에게 추가 정보 요청

## 관련 규칙
- CLAUDE.md Ghost Mode: "즉시 실행, 할까요? 금지"
- CLAUDE.md Autonomous Operation: "막히면 Perplexity/Tavily로 자체 조사"
- CLAUDE.md Search-Before-Solve: "막히면 LESSONS_LEARNED, 옵시디언, 이전 세션에서 먼저 검색"

## 유사 패턴
- declare_no_execute (이전 세션 4회)
- premature_conclusion (이전 세션 10회)
