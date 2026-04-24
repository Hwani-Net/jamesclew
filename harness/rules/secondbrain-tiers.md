# Second Brain Tier Rules (BASB Progressive Summarization)

출처: Tiago Forte "Building a Second Brain" — Progressive Summarization 원칙 적용
등록일: 2026-04-24
설계: JamesClaw 하네스 세컨브레인 감사 결과 (2026-04-24)

## 3계층 구조

| Layer | 경로 | 정의 | 진입 조건 |
|-------|------|------|----------|
| 1. Raw | `05-wiki/sources/`, `05-wiki/entities/`, `06-raw/` | 외부 원문·스펙. 변형 최소 | Perplexity/Tavily 결과, URL 추출, 공식 문서 |
| 2. Distilled | `05-wiki/distilled/`, `05-wiki/concepts/`, `05-wiki/analyses/` | 구조 정리된 요약·재해석 | Raw 1개 이상을 읽고 3줄 요약 + 내 관점 1문단 추가 |
| 3. Synthesized | `05-wiki/synthesized/` | 내 관점의 통합 주장 | Distilled 2개 이상을 통합한 새 글 + 개인 경험·판단 반영 |

## 이동 트리거

### Raw → Distilled
- 에이전트 또는 대표님이 sources/ 문서를 **읽고** 다음을 추가했을 때:
  1. 3줄 요약 (핵심 주장 / 근거·데이터 / 나에게 의미)
  2. "내 생각" 1문단 (이 정보가 내 프로젝트·판단에 어떤 영향)
  3. 관련 다른 소스 링크 (최소 1개 `[[slug]]`)
- `progressive-summarize.sh` hook이 자동으로 summary frontmatter는 주입하나, "내 생각" 단락은 대표님 판단 필요 → 수동 승격

### Distilled → Synthesized
- 2개 이상 distilled 문서를 통합하여 다음을 갖춘 새 글:
  1. 내 고유의 주장·결론
  2. 원본 distilled 문서들을 backlink 로 참조
  3. 다른 프로젝트·의사결정에 직접 적용 가능한 행동 지침

### 역방향 금지
- Synthesized → Distilled 로 내리는 이동은 금지. 내 관점이 들어간 글은 아카이브만 가능
- Distilled → Raw 로 내리는 경우: distilled 가 너무 원문 인용 위주로만 쓰인 경우. 전체 재작성 또는 sources/ 로 교체

## Frontmatter 규칙

모든 05-wiki 하위 파일에 `tier` 필드 필수:

```yaml
---
title: "..."
tier: raw | distilled | synthesized
date: YYYY-MM-DD
source: URL (Raw 만)
summary: "3줄 요약" (Distilled 이상)
---
```

## gbrain 검색 가중치

- gbrain query 시 tier 기반 가중치 정렬:
  - synthesized: 3.0
  - distilled: 2.0
  - raw: 1.0
- 현재는 frontmatter 만으로 표시 (자동 가중치는 향후 gbrain 기능 확장 대기)
- `gbrain tag <slug> tier:synthesized` 로 tag 도 병행 부여하면 태그 기반 필터 가능

## 예시

### 예시 1 — Raw
`05-wiki/sources/2026-04-24-ai-pricing-monetization-playbook-bvp.md`
- BVP 아티클 원문 복사본
- frontmatter: `tier: raw`, `source: https://...`, `summary: (GPT-4.1 자동 요약)`

### 예시 2 — Distilled
`05-wiki/distilled/ai-pricing-tradeoffs-ko.md`
- BVP 아티클 + 다른 SaaS 가격 전략 2개를 읽고 재구성
- 내 관점: "한국 시장에서 결과 기반 과금은 거부감 높음 — 하이브리드 모델로 시작 필요"
- Backlinks: `[[2026-04-24-ai-pricing-monetization-playbook-bvp]]`

### 예시 3 — Synthesized
`05-wiki/synthesized/my-ai-product-pricing-playbook-v1.md`
- distilled 3개 + 내 실제 JamesClaw 프로젝트 경험을 통합
- "나의 가격 설계 체크리스트 10단계"
- 행동 지침: "MVP 출시 시 무료 티어 + 10개 작업 한도 → 결과 품질로 유료 전환"

## 자동화 연동

- `/inbox-process`: 00-inbox 파일을 Raw tier로 이동 (sources/ 또는 06-raw/)
- `progressive-summarize.sh`: summary 주입 (Distilled 진입 조건 1번 자동화)
- `/review-week`: 주간 회고에서 "Distilled 후보" 제안

## 체크리스트 (Distilled 승격 셀프 검증)
- [ ] 원문 인용 < 30%
- [ ] 나만의 정리 순서 / 표 / 도식 있음
- [ ] "내 생각" 1문단 포함
- [ ] 링크 1개 이상

## 체크리스트 (Synthesized 승격 셀프 검증)
- [ ] Distilled 소스 2+ 참조
- [ ] 고유한 결론 / 주장 / 가설
- [ ] 행동 지침·체크리스트·의사결정 기준
- [ ] 3개월 후 다시 읽어도 유용한 관점
