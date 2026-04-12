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

<!-- TODO(human)
이 부분을 설계해 주세요.

핵심 결정:
1. 변환 도구 선택: SSG(Next.js/Astro) vs 경량(marked+handlebars) vs 기존 스마트리뷰 인프라 활용
2. SEO 메타태그 삽입 방식: meta.json에서 title/description/keywords 추출 → HTML head에 삽입
3. 템플릿 구조: 헤더/푸터/네비게이션 공통 레이아웃
4. [IMAGE:productname] 태그 → 실제 <img> 태그 변환 로직
5. [INTERNAL_LINK:topic] 태그 → 실제 <a> 태그 변환 로직
6. Firestore 연동 여부: HTML만 배포 vs Firestore에도 저장(검색/관리용)

작성할 내용:
- 변환 스크립트의 입력/출력 명세
- 사용할 npm 패키지 또는 도구
- HTML 템플릿 구조 (최소한의 레이아웃)
- SEO 태그 매핑 규칙

참고: 기존 스마트리뷰 블로그가 Firebase+Firestore SSG 기반이므로
기존 인프라를 재활용하면 빠릅니다.
-->

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
