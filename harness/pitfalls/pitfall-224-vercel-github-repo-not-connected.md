---
id: pitfall-224
slug: vercel-github-repo-not-connected
date: 2026-05-26
severity: medium
tags: [vercel, github, webhook, git, deploy, ci]
---

# PITFALL-224: Vercel-GitHub repo 미연동 — push해도 자동 배포 없음

## 증상
`git push` 후 Vercel에서 새 배포가 자동 생성되지 않음. Vercel CLI 직접 배포(`vercel --prod`)만 동작. Vercel 대시보드 Git Settings에 "This Project is not connected to a Git repository" 메시지 표시. GitHub Actions 연동 시에도 배포 트리거 미발화.

## 원인
Vercel 프로젝트가 GitHub repo와 webhook으로 연동되지 않은 상태. Vercel CLI로 프로젝트를 처음 생성(`vercel deploy`)하면 자동 webhook 연동이 이루어지지 않을 수 있음. 또는 과거에 연동했으나 repo 이전, 권한 변경 등으로 연동이 끊긴 상태.

## 해결
1. Vercel Dashboard 접속: `https://vercel.com/{team}/{project}/settings/git`
2. "Connect Git Repository" 섹션에서 해당 GitHub repo 옆 **Connect** 버튼 클릭
3. GitHub OAuth 권한 승인 (첫 연동 시)
4. 연동 직후엔 기존 push 이력에 대한 webhook이 없으므로, 빈 커밋으로 webhook 발화:
   ```bash
   git commit --allow-empty -m "chore: trigger vercel webhook"
   git push
   ```
5. Vercel 대시보드에서 새 배포가 생성되는지 확인

## 재발 방지
- Vercel 프로젝트 생성 직후 반드시 Git 연동 상태 확인: Dashboard → Settings → Git
- CLI로 처음 deploy할 때 `vercel link` 후 대시보드에서 GitHub 연동 별도 진행
- 신규 Vercel 프로젝트 체크리스트에 "Git connected: Y/N" 항목 추가
- 자동 배포 동작 확인은 dummy push로 반드시 검증

## 관련
- PITFALL-223 (commit email 불일치)
- PITFALL-225 (Deployment Protection SSO)

## 발견 정보
- 발견: 2026-05-26 세션, gpt-korea 프로젝트 배포 셋업 중
- 프로젝트: `D:/gpt-korea/`
