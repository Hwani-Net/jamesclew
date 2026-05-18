---
slug: pitfall-122-shared-component-fix-misses-inline-duplicates
title: "공통 컴포넌트 fix 시 인라인 중복 케이스 누락 (1장 검증으로 단정)"
date: 2026-05-07
severity: medium
category: incomplete-fix
tags:
  - shared-component
  - inline-duplicate
  - partial-fix
  - sample-of-one-bias
related:
  - pitfall-120-http-200-equals-functional-fallacy
---

# pitfall-122 — 공통 컴포넌트 fix 시 인라인 중복 케이스 누락

## 증상

CSS 비율/스타일 버그 fix 시 공통 컴포넌트(예: `QuizCard`)만 수정하고 라이브 1장 검증으로 "전체 fix 완료" 단정. 실제로는 동일 패턴이 다른 페이지에 인라인 JSX로 중복 존재 → 그 케이스 미수정 → CEO가 다른 화면에서 같은 버그 재발견.

## 원인

1. **단일 샘플 검증 편향 (sample of 1)**: 1장 ok면 5장 모두 ok 가정. 컴포넌트 명칭이 같아도 페이지마다 인라인 JSX 케이스 가능
2. **grep 범위 부족**: fix 후 `grep "h-56"` 같은 동일 패턴 전체 검색 안 함
3. **5종 quiz 모두 검증 안 함**: kpop만 시각 확인 → seoul-date는 인라인 결과 카드라 별도 fix 필요

K-Mate 사례 (2026-05-07):
- `components/QuizCard.tsx` `h-56` → `aspect-[4/5]` 수정
- 5종 quiz/game 결과 카드가 모두 QuizCard 공유한다고 가정
- 실제로는 `app/game/seoul-date/page.tsx:371` 에 동일 `h-56` 인라인 JSX
- CEO가 seoul-date 결과 보고 "여전히 잘림" 재지적

## 해결

### 즉시 행동 (이번 fix)
- 같은 패턴 grep 전체 `app/` 검색 → 인라인 케이스 동시 fix
- 다른 quiz 4종 (kdrama-hero, mbti-kpop, korean-fortune) 도 결과 카드 인라인 여부 확인
- fix 후 5종 모두 시각 검증

### 일반화
**fix 후 같은 클래스명·패턴 grep 전체 검색이 의무**. 1장 검증으로 단정 X.

## 재발 방지 — Pre-fix grep 의무

```bash
# 변경 대상 패턴 grep — 다른 위치 중복 없는지 확인
Grep(pattern: "<수정 전 패턴>", path: "<프로젝트 루트>", output_mode: "files_with_matches")
# 모든 매칭 위치에서 일괄 fix
```

또는 fix 후:
```bash
Grep(pattern: "<수정 전 패턴>")  # 0건이어야 PASS
```

### 트리거 키워드
- "공통 컴포넌트 공유"
- "한 곳만 수정해도 전부 적용"
- "같은 패턴" — 검증 안 했으면 위험

이런 가정 하면 grep 의무.

### 시각 검증 다중 샘플

5종 페이지가 같은 컴포넌트 사용 주장 시 → 최소 2~3 페이지 시각 검증으로 가정 검증.

## 참고

- 발생 세션: 2026-05-07 K-Mate Phase 5 quiz 결과 카드 잘림 fix
- CEO 피드백: "왜 나는 여전히 잘린 카드가 보이지?"
- 직전 보고: "5종 quiz 모두 동일 QuizCard 컴포넌트 공유 → 일괄 fix 적용됨" (잘못된 단정)
- 실제: seoul-date는 인라인 결과 카드라 미적용
- 관련 PITFALL: pitfall-120 (단일 샘플 검증 편향)
