---
description: "초안 → Firebase Hosting 자동 발행"
---

# /blog-publish — 초안 → Firebase Hosting 자동 발행

`/blog-review` PASS 또는 수동 승인된 초안을 Firebase Hosting에 발행합니다.

## 사용법
- `/blog-publish` — `status.json`이 `ready`인 최신 초안 자동 선택
- `/blog-publish MultiBlog/drafts/2026-04-12-keyword/` — 특정 초안 지정

## 산출물
- `MultiBlog/published/{slug}/index.html` — 발행된 HTML
- `MultiBlog/published/{slug}/meta.json` — 발행 메타데이터 (URL, 발행일, 버전)
- Firebase Hosting 라이브 URL

## 실행 절차

### Phase 0: 사전 검증
- status.json이 `ready` 또는 `approved`인지 확인
- draft.md와 meta.json 존재 확인
- 이미지 파일 존재 확인 (있으면 포함, 없으면 placeholder)

### Phase 1: 마크다운 → HTML 변환 파이프라인

#### 1-A. 입력/출력 명세

| 항목 | 경로 |
|------|------|
| 입력: 마크다운 | `MultiBlog/drafts/{slug}/draft.md` |
| 입력: 메타데이터 | `MultiBlog/drafts/{slug}/meta.json` (SEO 필드) |
| 입력: 상태 | `MultiBlog/drafts/{slug}/status.json` (status=ready/complete) |
| 출력: HTML | `MultiBlog/public/{slug}/index.html` |
| 출력: 발행 메타 | `MultiBlog/public/{slug}/meta.json` |

슬러그 = 드래프트 디렉토리명 (예: `2026-04-12-2026-로봇청소기-추천-비교`)

#### 1-B. 도구

- **`marked`** (npm global) — CommonMark 호환 MD→HTML 변환
- **Node.js** 내장 `fs`, `path` — 파일 읽기/쓰기
- 프레임워크 없음 (Next.js/Astro 불필요)

#### 1-C. SEO 메타태그 매핑

frontmatter YAML(`---` 블록)에서 추출:

| frontmatter 필드 | HTML 태그 |
|----------------|-----------|
| `title` | `<title>`, `<meta property="og:title">`, `<meta name="twitter:title">` |
| `description` | `<meta name="description">`, `<meta property="og:description">` |
| `keywords` (배열) | `<meta name="keywords">` (쉼표 연결) |
| `date` | `<meta property="article:published_time">` |

meta.json의 `seo.meta_description`이 존재하면 frontmatter description을 덮어씀 (더 정확하게 검증된 값).

#### 1-D. 특수 태그 변환 규칙

```
[IMAGE:name]
  → <figure class="post-image">
      <img src="/images/name.webp"
           alt="name (이미지)"
           width="800" height="600"
           onerror="this.style.display='none'">
    </figure>
  (실제 이미지 파일이 없으면 onerror로 조용히 숨김)

[INTERNAL_LINK:topic]
  → <a href="#" class="internal-link" data-topic="topic">topic</a>
  (슬러그 매핑은 Phase 2에서 확장 예정)
```

#### 1-E. HTML 템플릿 구조

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{title}} | 스마트리뷰</title>
  <meta name="description" content="{{description}}">
  <meta name="keywords" content="{{keywords}}">
  <!-- OG -->
  <meta property="og:type" content="article">
  <meta property="og:title" content="{{title}}">
  <meta property="og:description" content="{{description}}">
  <meta property="og:url" content="https://smartreview-kr.web.app/{{slug}}/">
  <meta property="og:site_name" content="스마트리뷰">
  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{{title}}">
  <meta name="twitter:description" content="{{description}}">
  <!-- Published time -->
  <meta property="article:published_time" content="{{date}}">
  <!-- Canonical -->
  <link rel="canonical" href="https://smartreview-kr.web.app/{{slug}}/">
  <!-- 최소 스타일 -->
  <style>
    body{max-width:800px;margin:0 auto;padding:1rem 1.5rem;font-family:
      -apple-system,BlinkMacSystemFont,'Noto Sans KR',sans-serif;
      line-height:1.7;color:#1a1a1a}
    h1{font-size:1.8rem;line-height:1.3;margin-bottom:0.5rem}
    h2{font-size:1.4rem;margin-top:2.5rem;border-bottom:2px solid #eee;padding-bottom:0.3rem}
    h3{font-size:1.15rem;margin-top:1.8rem}
    figure.post-image{margin:1.5rem 0;text-align:center}
    figure.post-image img{max-width:100%;height:auto;border-radius:8px}
    a{color:#0055cc}
    a.internal-link{color:#0077aa;text-decoration:underline dotted}
    .post-meta{color:#666;font-size:0.875rem;margin-bottom:2rem}
    @media(max-width:600px){body{padding:1rem}}
  </style>
</head>
<body>
  <header>
    <nav><a href="https://smartreview-kr.web.app/">← 스마트리뷰 홈</a></nav>
  </header>
  <main>
    <article>
      <p class="post-meta">{{date}} | 스마트리뷰</p>
      {{content}}
    </article>
  </main>
  <footer>
    <p style="color:#888;font-size:0.8rem;margin-top:3rem;border-top:1px solid #eee;padding-top:1rem">
      © 스마트리뷰 — 본 콘텐츠는 쿠팡파트너스 활동의 일환으로 수수료를 받을 수 있습니다.
    </p>
  </footer>
</body>
</html>
```

#### 1-F. 변환 실행 명령

```bash
bash harness/scripts/blog-publish.sh MultiBlog/drafts/{slug}/
```

스크립트가 아래를 자동 처리:
1. frontmatter 파싱 (title / description / keywords / date)
2. meta.json에서 seo.meta_description 추출 (description 덮어씀)
3. `[IMAGE:*]`, `[INTERNAL_LINK:*]` 치환
4. marked로 MD→HTML 변환
5. 템플릿에 주입 → `MultiBlog/public/{slug}/index.html` 저장

### Phase 2: Firebase Deploy
```bash
# 빌드된 HTML을 Firebase Hosting에 배포
firebase deploy --only hosting:blog --project smartreview-blog
```

### Phase 3: 발행 후 검증 (필수)
1. 라이브 URL HTTP 200 확인
2. og:title, og:description 메타태그 존재 확인
3. 본문 텍스트 렌더링 확인 (빈 페이지 감지)
4. 이미지 로드 확인
5. 검증 실패 시 자동 롤백

### Phase 4: 상태 업데이트
```json
// status.json
{ "status": "published", "publishedAt": "...", "url": "https://..." }
```

## 에러 처리
- Firebase CLI 미설치 → `npm install -g firebase-tools`
- 인증 실패 → 대표님에게 `firebase login` 요청
- 빌드 실패 → 에러 로그 + 에스컬레이션
