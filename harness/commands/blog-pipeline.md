---
description: "키워드 → 생성 → 검증 → 수정 → 발행 전체 파이프라인"
---

# /blog-pipeline — 키워드 → 생성 → 검증 → 수정 → 발행 전체 파이프라인

`/blog-generate` → `/blog-review` → `/blog-fix`(필요 시) 전체 사이클을 한 번에 실행.
`/loop`과 결합하면 크론 자동화 가능: `/loop 6h /blog-pipeline "키워드"`

## 사용법
- `/blog-pipeline "키워드"` — 단일 키워드 전체 파이프라인
- `/blog-pipeline "키워드1,키워드2,키워드3"` — 다중 키워드 순차 실행
- `/loop 6h /blog-pipeline "키워드"` — 6시간마다 자동 실행

## 실행 절차

### Step 1: /blog-generate
키워드로 초안 생성. 완료 후 `status.json` = `draft`.

### Step 2: /blog-review
품질 게이트 실행. 결과에 따라 분기:
- PASS → Step 4 (발행 준비)
- FAIL → Step 3

### Step 3: /blog-fix (조건부)
자동 수정 루프. 최대 3회. 결과에 따라 분기:
- 수정 성공 (ready) → Step 4
- 에스컬레이션 → 중단 + 텔레그램 보고

### Step 4: 발행 준비 완료
`status.json` = `ready`. 대표님께 보고:
```
✅ /blog-pipeline 완료
📄 "{제목}" — 발행 준비 완료
📊 AI냄새 {score}/100 | SEO {pass}/{total} | 이미지 {n}장
⏱️ 총 소요: {duration}
📁 MultiBlog/drafts/{slug}/
➡️ /blog-publish 로 발행 (수동) 또는 자동 발행 설정 시 즉시 발행
```

### Step 5: 다중 키워드 (쉼표 구분 시)
키워드를 `,`로 분리하여 Step 1~4를 순차 반복.
건당 30초 간격 (CLI rate limit 대비).

## 파이프라인 요약 리포트
모든 키워드 완료 후 종합 리포트:
```
📋 /blog-pipeline 종합 리포트
총 {n}건 | PASS {p}건 | FIX 후 PASS {f}건 | ESCALATED {e}건
평균 AI냄새: {avg}/100 | 평균 생성시간: {avg}분
```

## 에러 처리
- Step 1 실패 → 해당 키워드 스킵 + 다음 키워드 진행
- Step 3 에스컬레이션 → 해당 키워드 중단 + 다음 키워드 진행
- 전체 실패 → 텔레그램 종합 보고
