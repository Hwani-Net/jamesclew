---
id: pitfall-225
slug: vercel-deployment-protection-sso-unknown
date: 2026-05-26
severity: high
tags: [vercel, deployment-protection, sso, unknown-status, alias, hobby-plan]
---

# PITFALL-225: Vercel Deployment Protection(SSO)으로 UNKNOWN 상태 + alias 이전 차단

## 증상
`vercel ls --prod` 출력에서 새 배포가 `UNKNOWN` 상태로 표시되고 Duration이 `?`. `vercel inspect` 시 `status: UNKNOWN`, Build 시간 `. [0ms]` (정적 사이트이므로 빌드 불필요). 새 배포 URL 직접 접근 시 "Authentication Required" 로그인 페이지 표시. `gpt-korea.com` 같은 커스텀 도메인 alias가 자동으로 새 배포에 이전되지 않고 이전 READY 배포를 계속 가리킴.

## 원인
Vercel 프로젝트의 Deployment Protection 설정이 `"Vercel Authentication"` 켜진 상태인 경우, 새 배포 URL이 SSO(로그인) 뒤로 가려짐. Vercel API도 해당 배포를 READY로 판정하지 못해 alias 인계 로직이 동작하지 않음. Hobby 플랜에서 새 프로젝트 생성 시 Standard Protection이 자동 활성화될 수 있음.

## 해결
1. Vercel Dashboard → Settings → Deployment Protection
2. "Vercel Authentication" 섹션의 **"Require Log In" 토글 OFF**
3. 또는 드롭다운에서 **"Only Preview Deployments"** 선택 (Production은 공개, Preview만 보호)
4. Save 후 재배포 실행
5. 새 배포 `READY` 상태 확인 후 alias 이전 검증

## 재발 방지
- Vercel 프로젝트 생성 직후 반드시 Deployment Protection 설정 확인
- 정적 공개 사이트는 Authentication 불필요 — 사내 시스템·스테이징 환경에만 적용
- Hobby 플랜 Standard Protection 기본값 인지: 새 프로젝트마다 명시적으로 끄거나 "Only Preview"로 설정
- 배포 직후 `status: UNKNOWN` 이면 Deployment Protection 먼저 확인 (P-223, P-224 보다 먼저 점검)

## 관련
- PITFALL-223 (commit email 불일치 — UNKNOWN의 또 다른 원인)
- PITFALL-224 (GitHub 미연동)
- PITFALL-226 (.vercelignore 누락으로 UNKNOWN 유발)

## 발견 정보
- 발견: 2026-05-26 세션, GPT-KOREA showcase v2 배포 중
- 프로젝트: `D:/gpt-korea/`
