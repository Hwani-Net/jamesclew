---
title: pitfall-157 — publisher 스크립트가 라이브 사이트가 안 읽는 collection에 write
slug: pitfall-157-publisher-collection-mismatch-with-live-site
date: 2026-05-17
tier: distilled
tags: [publisher, firestore, collection, schema-mismatch, dead-letter, archive-restore, dashboard]
---

## 증상

자율 사이클이 publisher.js를 매일 cron으로 호출해 글을 발행하는데, **라이브 사이트에 글이 0건 표시**. publisher.js는 성공 로그(`[publisher] enqueued`)를 찍고 Firestore write도 200 OK. 그러나 사이트에는 안 보임.

실측 사례:
- gpt-korea.com 라이브 사이트는 `D:/MoneyAgent/dashboard/src/app/api/scheduler/route.ts`에서 **`publishing_jobs`** collection만 query
- archive에서 복원된 `D:/gpt-korea/developer/code/publisher.js`는 **`posts`** collection에 write
- 즉 publisher.js가 쓴 글은 orphan documents — 사이트 코드가 그 collection을 모름

## 원인

1. **archive 시점의 publisher.js와 현재 라이브 dashboard의 collection 스키마가 다름**. 이전 버전 publisher.js는 `posts` 컬렉션이 라이브 데이터 소스였을 가능성. 그러나 새 dashboard(Next.js 16) 재작성 시 collection 이름이 `publishing_jobs` + status state machine으로 변경됨.
2. `firebase.json`에 functions 블록이 없어 기존 `weeklyBlogPost`/`publishBlogPost` Cloud Function 가정이 잘못된 추정이었음. 실제 라이브 발행 경로는 Cloud Scheduler `publish-scheduler` (09:00 KST daily) → `/api/scheduler` → publishing_jobs.
3. 어디에도 명시 안 된 인터페이스. 라이브 dashboard repo와 publisher.js repo가 분리돼 있어 collection 합의가 드리프트됨.

## 해결

**옵션 D-1 (publisher.js 라이브 시스템 정합)** — 실제 적용한 방식:

publisher.js의 write target과 필드를 라이브 시스템에 맞춤:
- collection: `posts` → **`publishing_jobs`**
- 필수 필드: `status="scheduled"`, `scheduledAt` (ISO-8601), `title`, `htmlContent`, `tags` (배열), `platforms` (배열), `thumbnail`, `retryCount` (string), `updatedAt`
- 기존 `posts` collection write 코드 **완전 제거** (orphan 방지)
- `DRY_RUN=true` 환경변수 추가 → 콘솔 출력만, write 안 함

대안:
- **D-2**: publisher.js 폐기 + writer 에이전트가 라이브 `/api/publish` 직접 호출 (즉시 발행)
- **D-3 (비추천)**: 라이브 사이트 코드를 양쪽 collection 모두 읽도록 확장 — 라이브 변경 위험

## 재발 방지

1. **publisher와 사이트가 별개 repo면 첫 검증은 collection 이름 일치 여부**. `firebase.json` 또는 사이트 `/api/scheduler` 류 route 코드에서 query collection 추출 → publisher.js write target과 대조.
2. 추정한 Cloud Function 존재(`weeklyBlogPost`) 같은 가정은 **firebase.json에 functions 블록이 없으면 무조건 부정**해야 함. gcloud functions list가 billing 차단으로 막혀도 firebase.json은 단정 가능.
3. archive에서 복원한 코드는 **6개월 이상 묵은 인터페이스 가정** 위험. 라이브 repo 직접 분석 우선.
4. publisher 단위 테스트에 "라이브 사이트가 읽는 collection에 doc이 쌓이는가" 검증 단계 추가. DRY_RUN 모드로 payload 형식만이라도 확인.

## 관련

- [[pitfall-156-agent-tool-hallucination-without-web-search]]
- gpt-korea decisions.md R-DEPLOY-2 (정정 기록)
