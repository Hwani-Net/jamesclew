---
id: PITFALL-229
title: "Vercel 신규 프로젝트마다 Deployment Protection 자동 활성 → origin 401 (PITFALL-225 family 재발 패턴)"
date: 2026-05-27
session: gpt-korea-services-deploy-multi
keywords: [vercel, deployment-protection, sso, new-project, automation-needed, P-225-family]
related: [pitfall-225, pitfall-223]
---

# PITFALL-229: Vercel 신규 프로젝트 Deployment Protection 자동 활성

## 증상

Vercel CLI 또는 Dashboard 로 **신규 프로젝트 생성 시**, "Vercel Authentication" (Standard Protection / SSO) 가 **자동 활성** 상태로 출발. 결과: origin URL (`*-stayicon-gmailcoms-projects.vercel.app`) 에 직접 HTTP 요청하면 **401 Authentication Required** 반환.

### 오늘 세션 (2026-05-27) 실측 재발 사례

같은 패턴이 **연속 2개 신규 프로젝트**에서 재발:

1. **uiwon-danawa** (의원다나와) — 신규 Vercel 프로젝트 → origin 401 → 대표님 Dashboard에서 OFF → 정상 동작
2. **bite-log** (낚시 기록 앱) — 신규 Vercel 프로젝트 → origin 401 → 대표님 OFF 대기 중

PITFALL-225 (이미 기록된 anti-pattern) 와 동일 family. 하지만 PITFALL-225는 단일 프로젝트의 1회성 사고로 기록됨. **오늘 재발로 확인된 사실: 모든 신규 Vercel 프로젝트의 default 정책**.

## 원인 (Root Cause)

Vercel Hobby/Pro 플랜 모두 **프로젝트 생성 시 기본값** 으로 다음 설정 적용:
- `ssoProtection: { "deploymentType": "all" }` 또는 유사 정책
- "Vercel Authentication > Standard Protection" 토글 ON

이는 보안 디폴트 — 의도적 설정이지만, **public 서비스 배포에는 부적합**. CLI/API 어디서도 프로젝트 생성과 동시에 OFF 할 자동 옵션 없음.

### 영향
- gpt-korea.com rewrite proxy (`/uiwon-danawa`, `/bite-log` 등) 가 origin 401을 받아 401 응답 전파
- 사용자 / 검색 엔진 / 크롤러 모두 차단

## 해결 (Resolution)

### 수동 해결 (현재까지의 방법)
1. Vercel Dashboard → 프로젝트 → Settings → Deployment Protection
2. "Vercel Authentication" 섹션의 "Require Log In" 토글 **OFF**
3. Save → 즉시 적용 (재배포 불필요)

URL 패턴: `https://vercel.com/{team}/{project}/settings/deployment-protection`

### 자동화 검토 (향후 hook 또는 스크립트)
Vercel REST API 로 자동 OFF 가능성:
```
PATCH https://api.vercel.com/v9/projects/{id}
Body: {"ssoProtection": null}
Authorization: Bearer $VERCEL_TOKEN
```
주의: `$VERCEL_TOKEN` 필요. `~/.local/share/com.vercel.cli/auth.json` 또는 환경변수.

새 프로젝트 생성 직후 자동 호출하는 hook:
- `harness/scripts/vercel-disable-protection.sh` 신설 검토
- `vercel link` / `vercel deploy --first-time` 직후 trigger

### 임시 우회
- Vercel Authentication "Only Preview Deployments" 옵션 선택 → 커스텀 도메인 (gpt-korea.com) 에는 보호 없음, 프로젝트 *.vercel.app subdomain 은 보호 유지
- 단, rewrite proxy의 destination 이 *.vercel.app 이므로 이 옵션도 origin 401 동일 발생. **무효**.

## 재발 방지 (Prevention)

### 즉시 적용
1. **신규 Vercel 프로젝트 생성 직후 체크리스트**:
   - [ ] Dashboard → Settings → Deployment Protection → Vercel Authentication OFF
   - [ ] origin URL HEAD 요청 200 확인 후 다음 작업 진행
2. **Sub-agent 위임 시 명시**: "Vercel separate 배포는 Deployment Protection 자동 활성 — origin 401 가능성 보고 후 진행"
3. 메인 세션이 Vercel CLI deploy 후 origin URL HEAD 확인 자동화

### Long-term
- `harness/scripts/vercel-disable-protection.sh` 작성:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  project_id="$1"
  curl -sX PATCH "https://api.vercel.com/v9/projects/${project_id}" \
    -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"ssoProtection": null}'
  ```
- PostToolUse hook on Bash `vercel link --project` 패턴 매칭 → 자동 호출
- 단, `$VERCEL_TOKEN` 보관 필요 (1Password / 환경변수)

### 영구 정책 변경 시도
- Vercel team-level setting 확인 — team 단위로 default protection OFF 가능 여부 (Pro 플랜 이상일 수 있음)
- Hobby 플랜은 team setting 제한적

## 관련

- [[pitfall-225-vercel-deployment-protection-sso-unknown]] — 단일 프로젝트 사고로 기록. 본 PITFALL이 family 확장
- [[pitfall-223-vercel-commit-email-github-mismatch]] — Vercel 시리즈
- Vercel docs: `/docs/security/deployment-protection`

## 발견 일자, 세션

- **첫 발견**: 2026-05-26 (PITFALL-225, 단일 사고)
- **family 확정**: 2026-05-27 (uiwon-danawa + bite-log 연속 재발)
- **프로젝트**: D:/gpt-korea/ + E:/AI_Programing/{알고뽑자, BiteLog/fish-log}
- **재발 차단 강도**: 최고 (자동화 hook 필요)
