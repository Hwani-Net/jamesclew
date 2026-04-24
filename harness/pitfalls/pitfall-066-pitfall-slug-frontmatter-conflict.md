---
title: pitfall 파일의 frontmatter slug 필드가 gbrain import를 차단
date: 2026-04-24
severity: P1
project: harness
tags: [gbrain, frontmatter, slug, import, pitfall]
---

## 증상
`gbrain import D:/jamesclew/harness/pitfalls/` 실행 시 5건 이상 skip:
```
Skipped harness\pitfalls\pitfall-048-....md:
  Frontmatter slug "pitfall-048-..." does not match path-derived slug
  "harness/pitfalls/pitfall-048-..." (from harness\pitfalls\pitfall-048-....md).
  Remove the frontmatter "slug:" line or move the file.
```
실제 pitfall 기록이 gbrain 에 저장되지 않아 **검색 불가** 상태.

## 원인
- 구 gbrain(0.9.x) 스타일의 frontmatter `slug:` 필드가 pitfall 템플릿에 포함됨
- gbrain 0.10.x 는 **경로에서 slug 를 자동 유도** — frontmatter 에 명시된 slug 와 경로 유도값이 다르면 충돌로 판정
- 템플릿 갱신 시 기존 파일들의 slug 필드를 제거하지 않음

## 영향
- 대표님·에이전트가 `gbrain query "증상키워드"` 로 검색해도 pitfall-048/049/050/059/060 이 나오지 않음
- Search-Before-Solve 원칙 작동 안 함 → 동일 실수 재발 가능

## 해결
- 해당 5개 파일에서 `slug:` 라인 제거
- `gbrain import` 재실행하여 skip=0 확인

## 재발 방지
1. pitfall 템플릿에서 `slug:` 필드 제외 (경로 기반 자동 유도)
2. `gbrain import` 출력에 `Skipped` 가 한 건이라도 있으면 hook 이 경고 주입
3. 하네스 install.sh 에 pitfalls/*.md 의 frontmatter slug 검출 + 자동 수정 단계 추가
