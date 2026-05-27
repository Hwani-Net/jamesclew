---
id: pitfall-226
slug: vercelignore-sensitive-files-build-cache
date: 2026-05-26
severity: medium
tags: [vercel, vercelignore, env, security, build-output, static-site]
---

# PITFALL-226: .vercelignore 누락으로 .env 노출 + 빌드 캐시 충돌

## 증상
Vercel CLI 업로드 시 `.env` 같은 민감 파일이 함께 업로드됨. 이전 빌드 캐시 `.vercel/output/static/` 폴더가 deployment에 포함되어 Build Output API v3 모드와 충돌. UNKNOWN status 또는 빌드 혼선 발생. 업로드 크기가 비정상적으로 크게 나타남 (정적 HTML만인데 10MB+).

## 원인
`.vercelignore` 파일에 `.env`, `.vercel`, `*.py`, `node_modules` 등 비-웹 자산이 누락되면 모든 파일이 업로드 대상이 됨. 특히 `.vercel/output/` 은 CLI가 로컬 빌드 후 생성하는 캐시 디렉토리인데, 이것이 함께 업로드되면 Vercel이 Build Output API 모드를 트리거해 배포가 예상치 않게 동작할 수 있음. `.env` 파일 노출 시 보안 사고로 이어질 수 있어 severity medium이지만 실질적으로 high에 가까움.

## 해결
`.vercelignore` 표준 항목 적용:

```
node_modules
.git
.vercel
.env
.env.*
*.py
*.md
_agents
developer
sessions
docs
scripts
.pytest_cache
.github
.vscode
!vercel.json
!package.json
```

적용 후 재배포 시 업로드 크기가 정상 범위(수백 KB 이하)로 줄어드는지 확인.

## 재발 방지
- 새 Vercel 정적 사이트 프로젝트마다 위 `.vercelignore` 표준 템플릿 복사 적용
- 첫 `vercel deploy` 전 반드시 `.vercelignore` 점검 (체크리스트 항목)
- 업로드 크기가 정적 HTML 프로젝트인데 5MB 초과 시 `.vercelignore` 부족 의심
- `.env` 파일이 노출된 것이 확인되면 즉시 해당 secret rotate
- `vercel deploy` 출력의 "Uploading..." 단계에서 파일 수와 크기 확인하는 습관

## 관련
- PITFALL-225 (UNKNOWN status의 또 다른 원인)
- Vercel Build Output API 충돌 문서: `https://vercel.com/docs/build-output-api`

## 발견 정보
- 발견: 2026-05-26 세션, `D:/gpt-korea/` 배포 중 463B~10.8MB 업로드 크기 변동 추적 중 발견
- 프로젝트: `D:/gpt-korea/`
