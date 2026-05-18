---
slug: pitfall-165-firebase-korean-slug-404
date: 2026-05-18
severity: medium
tags: [firebase-hosting, korean-slug, deployment, 404]
related: [[pitfall-164-coupang-partners-link-silent-fail]]
---

# P-165 — Firebase Hosting 한글 슬러그 개별 폴더 라이브 404

## 증상
- MultiBlog `public/2026-05-07-선풍기-추천-서큘레이터/` 폴더: 로컬에 index.html + meta.json + images/ 모두 정상 존재
- `firebase deploy --only hosting` 로그: "found 34 files, release complete"
- 라이브 `https://multi-blog-personal.web.app/2026-05-07-선풍기-추천-서큘레이터/` → **404** Not Found (Content-Length 21,376 = Firebase 기본 404 페이지)
- **다른 한글 페이지(가성비-모니터 등)는 200 정상** — 같은 한글 패턴인데 시범 페이지만 무시됨

## 시도 무효 처리 4건 (2026-05-18)
1. NFC 정규화 (Python unicodedata `is_nfc=True` 확인) → 무효
2. 폴더 삭제 + 재생성 (Python shutil) → 무효
3. firebase deploy 재실행 → 무효
4. firebase 캐시 시간 5분+ 경과 → 무효

## 원인 (가설, 미확인)
- Firebase Hosting의 한글 URL 처리에 폴더 단위 결정성 부족
- NTFS 한글 메타데이터(파일 시스템 레벨 인코딩) 차이 가능
- Firebase deploy의 incremental 동기화에서 특정 폴더만 누락
- 정확한 원인은 Firebase 콘솔의 hosted files 목록 직접 확인 필요 (대표님 행동 필요 영역)

## 해결 (우회)
- **영문 슬러그로 마이그레이션** (2026-05-18 채택)
- 같은 콘텐츠를 `public/fan-circulator-2026-05-07/` 폴더에 복사 + 같은 firebase deploy → **200 OK 즉시**
- index.html 안의 self-reference URL(og:url, canonical 등)을 영문 슬러그로 갱신
- 한글 슬러그 폴더는 라이브에 안 보이지만 보존 (역사)

## 재발 방지
- MultiBlog 모든 신규 발행 페이지는 **영문 슬러그 우선** (`{topic-keywords}-{date}` 형식)
- SEO 측면: 한국어 검색은 본문 콘텐츠에 의존, 슬러그 영문이어도 검색 노출 영향 미미
- 9개 페이지 신규 발행 (2026-05-18): 모두 영문 슬러그로 통일 — 100% 200 OK 확보
- 한글 슬러그 사용 시 사전 검증 절차 — Firebase 콘솔 hosted files 직접 확인 후에만

## 관련 발견
- 다른 한글 페이지(예: 2026-04-12-2026-공기청정기-추천-비교)는 정상 동작 — 즉 한글 자체는 차단되지 않음
- 특정 폴더만의 미스터리 — Firebase Hosting 내부 인코딩/캐싱 버그 의심
- 대표님이 시간 여유 있을 때 Firebase 콘솔 직접 확인하면 정확한 원인 파악 가능
