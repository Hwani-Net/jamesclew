---
id: pitfall-223
slug: vercel-commit-email-github-mismatch
date: 2026-05-26
severity: high
tags: [vercel, github, git, deploy, email, commit-author]
---

# PITFALL-223: Vercel 배포 차단 — commit email이 GitHub 계정과 불일치

## 증상
Vercel 대시보드에 "Deployment Blocked: The deployment was blocked because the commit email X could not be matched to a GitHub account" 에러 표시. 모든 신규 배포가 `UNKNOWN` 상태로 고정되며 영원히 진행되지 않음. Vercel CLI는 "Building..." 표시 후 무한 대기 상태로 빠짐.

## 원인
`git config user.email` 이 GitHub 계정에 등록되지 않은 이메일로 설정된 경우 발생. 예시: `ai.developer@example.com` 같은 placeholder, 또는 다른 사람의 이메일 주소. Vercel은 보안상 commit author email이 연결된 GitHub 계정에 등록된 이메일 주소와 일치해야 배포를 허용함.

## 해결
1. `git config user.email` 로 현재 설정 확인
2. `git config user.email "GitHub_등록된_이메일"` 로 올바른 이메일로 교체
3. 기존 잘못된 커밋 author 재작성:
   ```bash
   git rebase HEAD~N --exec "git commit --amend --reset-author --no-edit"
   ```
   (N = 잘못된 이메일로 작성된 커밋 수)
4. `git push --force-with-lease` 로 GitHub history 정리
5. Vercel 대시보드에서 새 배포 트리거 또는 `vercel --prod` 재실행

## 재발 방지
- 새 프로젝트 시작 시 반드시 `git config user.email` 확인 (글로벌 설정과 다를 수 있음)
- 시스템 reminder의 `userEmail` 필드는 다른 사람 메일일 수 있으므로, 검증 없이 자동으로 git config에 사용 금지
- 대표님 본인 메일 후보:
  - `stayicon@gmail.com` — Vercel 사용자명 stayicon-4768 과 매칭
  - `hwanizero01~03@gmail.com` — Hwani-Net org 매칭 가능
  - `dlwptjq2@gmail.com` — 동생 계정, git config에 절대 사용 금지
- Vercel 프로젝트 연동 직후 테스트 배포로 email 매칭 확인

## 관련
- PITFALL-224 (Vercel-GitHub repo 미연동)
- PITFALL-225 (Deployment Protection SSO 차단)

## 발견 정보
- 발견: 2026-05-26 세션, GPT-KOREA showcase v2 배포 중
- 프로젝트: `D:/gpt-korea/`
