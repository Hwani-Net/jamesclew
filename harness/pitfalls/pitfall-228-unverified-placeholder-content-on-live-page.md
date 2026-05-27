---
id: PITFALL-228
title: "라이브 페이지에 검증 없는 placeholder 콘텐츠 발행 (og:image 위조 + 추측 기반 서비스 설명)"
date: 2026-05-26
session: gpt-korea-showcase-v2-services-thumbnail
keywords: [placeholder, content-verification, og-image, service-card, evidence-first, P-014]
related: [pitfall-220, pitfall-227]
---

# PITFALL-228: 라이브 페이지에 검증 없는 placeholder 콘텐츠 발행

## 증상

오늘 세션에서 두 가지 anti-pattern이 라이브 페이지에 동시 노출:

### 증상 1 — og:image 메타태그 신뢰성 가정
`/reviews` 인덱스 페이지 카드 18개 중 13개에서 Firebase 페이지의 `<meta property="og:image">` URL을 그대로 사용. 그러나 실제 검증 결과 **7개의 og:image URL이 Firebase 측에서 404** (파일이 deploy되지 않거나 deploy 후 삭제).

```bash
# og:image 메타태그 존재 확인 → ✅
$ curl -s ".../airfryer-large-oven-2026-05-07/" | grep -A 1 og:image
property="og:image"
content="https://multi-blog-personal.web.app/.../images/필립스-hd9285.jpg"

# 실제 파일 존재 확인 → 케이스마다 다름
$ curl -sI ".../images/필립스-hd9285.jpg"       → 200 OK
$ curl -sI ".../images/air-purifier-overview-2026.webp"   → 404
```

결과: 라이브 페이지에 broken image 7개 노출.

### 증상 2 — 서비스 카드 설명을 추측으로 작성
메인 페이지 3개 서비스 카드 (의원다나와 / 혜택알리미 / bite-log) 설명을 **서비스 이름만 보고 추측**으로 작성하여 라이브 발행. 실제 PRD/소스 코드 검증 없음.

| 카드 | 발행된 잘못된 설명 | 실제 정체 |
|---|---|---|
| 의원다나와 | "동네 병원·의원 진료비 비교" | 2026 지방선거 후보 다나와 (정치 의원) |
| bite-log | "AI 식단 영양 분석" | 낚시 입질 기록 + 포인트 추천 (Android 앱) |
| 혜택알리미 | (대체로 정확) | 정부 지원금 3초 자격 판정 |

대표님 지적 ("이미 완성된 서비스인데 설명이 다 잘못됐다") 받기 전까지 잘못된 정보가 라이브 노출됨.

## 원인 (Root Cause)

1. **og:image 신뢰**: meta tag 존재 = 파일 존재로 자동 가정. Firebase처럼 동적/SSG 환경에서는 meta tag와 실제 파일 deploy가 불일치할 수 있음 (배포 후 파일명 변경, 폴더 구조 변경, 빌드 누락 등).

2. **서비스 이름의 의미론적 추측**:
   - "의원다나와" → "병원/의원" (의료) 로 자동 매핑. 실제는 "의원" = 국회의원/지방의원 (정치).
   - "bite-log" → "bite = 입에 무는 것 = 음식 = 식단" 로 자동 매핑. 실제는 "bite = 낚시 입질".
   - 한국어/영어 단어의 다의성 무시.

3. **Evidence-First 룰 위반** (CORE RULES #3): 도구 출력 증거 없이 추측으로 콘텐츠 작성. PRD.md, README.md, package.json 등 1차 소스를 확인하지 않음.

## 해결 (Resolution)

### og:image 검증
13개 src 모두 HEAD 요청으로 200/404 분류:
- 6개 OK → 유지
- 3개 → 영문 slug 폴더에 같은 이미지 있음, 경로 변경으로 살림
- 4개 → 페이지 본문에 실제 이미지 없음, placeholder 복원

최종: 9 img + 9 placeholder = 18 카드.

### 카드 설명 정정
각 서비스 폴더의 PRD/NORTH_STAR/README 1차 소스를 Read로 직접 확인 후 카드 설명·태그·아이콘·상태 배지 모두 교체.

```
의원다나와: PRD.md 첫 25줄 → "2026 지방선거 후보 다나와. 내 주소 기반 7개 선거..."
혜택알리미: NORTH_STAR.md 첫 20줄 → "3초 만에 자격 판정. 광고 없는 알림..."
bite-log: fish-log/package.json + 폴더 구조 → "낚시 입질 한 번 한 번을 기록..."
```

## 재발 방지 (Prevention)

### og:image / 외부 리소스 URL 사용 규칙
1. **meta tag URL을 외부 자원 src로 사용 전 반드시 HEAD 요청 검증**:
   ```bash
   for url in <후보_URL_목록>; do
     curl -sI -o /dev/null -w "%{http_code} $url\n" "$url"
   done | grep -v "^200"
   ```
2. 검증 실패한 URL은 placeholder fallback. 절대 빈 src 또는 broken URL 라이브 발행 금지.
3. CMS/SSG 환경에서는 og:image와 실제 파일 deploy가 dual-track. 둘 다 확인.

### 콘텐츠 placeholder 발행 금지
1. **서비스/제품/엔티티 설명을 추측으로 작성 금지**. 이름의 의미론적 매핑은 hint일 뿐 사실 아님.
2. 다음 1차 소스를 **반드시 Read로 확인** 후 작성:
   - 프로젝트 폴더의 `PRD.md`, `NORTH_STAR.md`, `README.md`
   - `package.json` 의 `name`, `description`
   - 폴더 내 디자인 시안 (`DESIGN.md`)
   - 코드 첫 import / route 정의 (어떤 도메인인지 단서)
3. 1차 소스 부재 시 **대표님께 즉시 확인 요청**. placeholder 추측으로 발행 금지.
4. `Evidence-First` 룰 (CORE RULES #3) — 도구 출력 증거 없이 콘텐츠 발행 금지.

### 검증 체크리스트 (라이브 발행 직전 강제)
- [ ] 모든 외부 이미지 URL HEAD 요청 200 확인
- [ ] 모든 외부 링크 (CTA, 카드 링크) HEAD/GET 응답 확인
- [ ] 모든 entity 설명이 1차 소스 (PRD/README/code)와 일치 확인
- [ ] grep으로 placeholder 토큰 (`lorem`, `TODO`, `FIXME`, `placeholder`) 0건 확인
- [ ] 한국어/영어 다의어 (의원/bite/run/study 등) 의미 검증

## 관련

- [[pitfall-220-openclaw-benchmark-name-only-citation-antipattern]] — 벤치마크 이름만 차용하는 anti-pattern (오늘 사례와 동일 family: 검증 없는 콘텐츠 발행)
- [[pitfall-227-vercel-external-rewrite-path-wildcard-trailing-slash]] — 오늘 같은 세션, 다른 이슈
- Evidence-First (CORE RULES #3): 도구 출력 증거 없이 보고/콘텐츠 발행 금지
- P-014: 학습 데이터 의존 금지, 현재 시각 기준 최신 데이터 확인

## 발견 일자, 세션

- **날짜**: 2026-05-26
- **세션**: GPT-KOREA showcase v2 — 서비스 카드 콘텐츠 정정 + /reviews 인덱스 썸네일 정정
- **프로젝트**: D:/gpt-korea/ (gpt-korea.com)
- **잘못된 정보 라이브 노출 기간**: 약 6시간 (Stitch v2 deploy 시점부터 정정 발견까지)
- **발견 트리거**: 대표님 직접 지적 ("이미 완성된 서비스인데 설명이 다 잘못됐다")
- **재발 방지 강도**: 가장 높음 (자율 인프라 라이브 발행 가드에 통합 필요)
