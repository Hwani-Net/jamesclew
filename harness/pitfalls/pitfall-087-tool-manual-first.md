---
slug: pitfall-087-tool-manual-first
tags: [pitfall, manual-first, tool-research, knowledge-cutoff, model-version]
date: 2026-04-30
project: 영상제작 (도구 매뉴얼 정독 누락)
---

# P-087: 도구 사용 전 공식 매뉴얼 정독 필수 — 학습 데이터 의존 금지

- **발견**: 2026-04-30
- **프로젝트**: 영상제작 Phase 1/2 도구 선택
- **심각도**: HIGH (Phase 1 NG의 핵심 원인)

## 증상
1. **Phase 1**: 작가 PDF Bible만 보고 Seedance/Morphic 공식 매뉴얼 미정독 → multi-reference 9슬롯, last_image_url, seed 등 핵심 기능 누락 → 캐릭터 일관성 0% NG
2. **Phase 2 시작**: 학습 데이터(Aug 2025) 의존하여 Nano Banana = Gemini 2.5 Flash로 단정 → 대표님 지적 "최신 버전 사용해야 하는거 아니야?"
3. 실제로는 Nano Banana 2 (Gemini 3.1 Flash, 2026-02-26 출시), Nano Banana Pro (Gemini 3 Pro), ChatGPT Images 2.0 (gpt-image-2, 2026-04-21) 등 신버전 다수 존재
4. 작가 PDF "GPT 5.5 + Image 2" = ChatGPT UI에서 GPT-5.5 텍스트 + gpt-image-2 이미지 조합 (정확)

## 원인
1. CLAUDE.md "P-014 학습 데이터 의존 금지" 규칙 위반
2. 매뉴얼 정독을 "도구 사용 전 0단계"로 강제하지 않음
3. 작가 자료(PDF)만으로 도구 동작을 추정
4. 검색 이전에 결론 단정

## 해결
- 새 프로그램/도구(Seedance, Morphic, Veo, ChatGPT Image 2 등) 사용 전, **공식 매뉴얼/문서/API 레퍼런스를 우선 적재 후 정독**
- 정독 절차:
  1. 공식 문서 URL 식별 → curl/fetch로 적재 → references/manuals/{tool-name}.md 에 저장
  2. 정독 항목: 입력 슬롯, 파라미터 schema, 권장값, 알려진 한계, best practice, 예제 프롬프트
  3. 정독 결과를 작업 시작 전에 요약 보고
- 작가가 사용하는 도구라도 작가 PDF로는 도구 매뉴얼을 대체하지 못함 — 별도 정독 필요
- 학습 데이터 cutoff 인지: knowledge cutoff Aug 2025 < 현재 시점 시 항상 웹 검색으로 최신 버전 확인

## 재발 방지 체크리스트
- [ ] 새 도구 도입 전 references/manuals/ 적재 우선
- [ ] 모델/도구명 단정 전 웹 검색으로 최신 버전 확인
- [ ] CLAUDE.md "0단계 프로젝트 시작 시 사전 조회"의 외부 도구 버전 적용
- [ ] 작가 자료 인용 시에도 도구 매뉴얼 별도 검증

## 메모리 연동
- `feedback_manual_first.md` (memory)
- 기존: P-014 (학습 데이터 의존 금지)
