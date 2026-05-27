---
id: PITFALL-227
title: "Vercel external rewrite의 `:path*` 와일드카드가 trailing slash path 매칭 실패"
date: 2026-05-26
session: gpt-korea-showcase-v2-reviews-proxy
keywords: [vercel, rewrite, external, path-wildcard, trailing-slash, regex, NOT_FOUND]
related: [pitfall-223, pitfall-224, pitfall-225, pitfall-226]
---

# PITFALL-227: Vercel external rewrite의 `:path*` 와일드카드가 trailing slash path 매칭 실패

## 증상

Vercel `vercel.json` 의 external rewrite 사용 시 `:path*` 네임드 파라미터로 작성한 패턴이 destination에 path를 제대로 forwarding하지 못함. 응답 헤더에 `X-Vercel-Error: NOT_FOUND` 표시.

```bash
# 설정
"rewrites": [
  {"source": "/reviews/:path*", "destination": "https://multi-blog-personal.web.app/:path*"}
]

# 결과
$ curl -sI "https://gpt-korea.com/reviews/airfryer-large-oven-2026-05-07/"
HTTP/1.1 404 Not Found
X-Vercel-Error: NOT_FOUND
Content-Length: 79

# 그러나 destination 직접 접근은 정상
$ curl -sI "https://multi-blog-personal.web.app/airfryer-large-oven-2026-05-07/"
HTTP/1.1 200 OK
Content-Length: 30053
```

특히 path 끝에 trailing slash가 있거나 path에 한글/특수문자가 있을 때 매칭이 안 됨. 영문 path + trailing slash 조합도 동일 실패.

## 원인 (Root Cause)

Vercel rewrites의 `:path*` 네임드 와일드카드 파라미터가 external destination 으로의 forwarding 시 다음 케이스에서 source 매칭에 실패:

1. **Trailing slash 포함** path (예: `/reviews/foo/`)
2. **다중 segment + slash** 조합 (예: `/reviews/2026-04-12-foo-bar/`)
3. **한글/UTF-8 segment** (URL-encoded여도 동일)

Vercel 공식 docs (`/docs/routing/rewrites`)는 `:path*` 가 external rewrite와 호환된다고 명시하지만, 실측 결과 위 케이스에서 source 매칭 자체가 안 됨 (`X-Vercel-Error: NOT_FOUND` = rewrite 적용 전 단계에서 filesystem 매칭 실패 후 즉시 404 반환).

정확한 내부 동작은 비공개이나, 추정 원인:
- `:path*` 의 internal regex 변환이 multi-segment + trailing slash 조합에서 backtrack 실패
- Vercel router가 external destination을 special handling 하면서 named param expansion이 누락

## 해결 (Resolution)

`:path*` 대신 **정규식 capture group `(.*)` + `$1` 참조** 사용:

```json
// BEFORE (실패)
"rewrites": [
  {"source": "/reviews/:path*", "destination": "https://multi-blog-personal.web.app/:path*"}
]

// AFTER (성공)
"rewrites": [
  {"source": "/reviews/(.*)", "destination": "https://multi-blog-personal.web.app/$1"}
]
```

`(.*)` 는 일반 정규식 capture group이라 trailing slash·특수문자·multi-segment 모두 그리디 매칭. `$1` 으로 destination에서 expand하면 정확히 forwarding.

검증:
```bash
$ curl -sI "https://gpt-korea.com/reviews/airfryer-large-oven-2026-05-07/"
HTTP/1.1 200 OK
Content-Length: 30053

$ curl -sI "https://gpt-korea.com/reviews/2026-04-12-2026-공기청정기-추천-비교/"
HTTP/1.1 200 OK
Content-Length: 17228
```

## 재발 방지 (Prevention)

1. **External rewrite 작성 시 기본값으로 정규식 `(.*)` + `$1` 사용**. `:path*` 는 same-application rewrite (자기 프로젝트 내부) 에만 사용.
2. **Vercel rewrite 작성 후 검증 필수**:
   - destination 직접 200 OK 확인
   - rewrite 경유 path 200 OK 확인
   - trailing slash 포함/제외 두 케이스 모두 테스트
   - 한글/특수문자 segment 테스트 (해당 시)
3. **응답 헤더 `X-Vercel-Error`** 확인이 1차 진단. `NOT_FOUND` 면 rewrite source 매칭 실패, `FUNCTION_INVOCATION_FAILED` 면 destination 자체 문제.
4. **여러 rewrite 패턴 동시 정의 시 순서 중요**. exact match (`/reviews`) 가 wildcard 패턴 (`/reviews/(.*)`) 보다 위에 배치.

## 관련

- [[pitfall-223-vercel-commit-email-github-mismatch]] — Vercel deployment blocked 시리즈
- [[pitfall-224-vercel-github-repo-not-connected]] — Vercel-GitHub 연동
- [[pitfall-225-vercel-deployment-protection-sso-unknown]] — Deployment Protection
- [[pitfall-226-vercelignore-sensitive-files-build-cache]] — .vercelignore 표준
- Vercel docs: `/docs/routing/rewrites` — "Using regular expressions" 섹션
- Vercel docs: `/docs/routing/rewrites` — "Wildcard path forwarding" 섹션

## 발견 일자, 세션

- **날짜**: 2026-05-26
- **세션**: GPT-KOREA showcase v2 + /reviews 인덱스 페이지 작성 후 sub-path proxy 검증
- **프로젝트**: `D:/gpt-korea/` (gpt-korea.com)
- **proxy target**: `https://multi-blog-personal.web.app/` (smartreview Firebase Hosting)
- **검증 환경**: Vercel CLI 41.x, Hobby plan, 28개 폴더 중 18개 유니크 리뷰 페이지
