---
id: PITFALL-230
title: "Firebase App Hosting GitHub auto-trigger 후 무한 대기 / silent failure — CLI 진단 불가"
date: 2026-05-27
session: gpt-korea-services-deploy-multi
keywords: [firebase, app-hosting, github-trigger, silent-failure, cli-limitation]
related: [pitfall-227, pitfall-229]
---

# PITFALL-230: Firebase App Hosting GitHub trigger 후 빌드 무한 대기 / silent failure

## 증상

Firebase App Hosting backend (예: `benefitbell-web`)가 GitHub repo와 연동되어 있고 push가 정상 완료되었음에도, **공개 URL이 무기한 404**. CLI 로 빌드 상태/로그를 조회하려 해도 다음 명령 부재:
- `firebase apphosting:rollouts:list` → `is not a Firebase command`
- `firebase apphosting:builds:list` → `is not a Firebase command`
- `firebase apphosting:rollouts --help` → firebase 기본 도움말 출력 (즉 서브커맨드 자체 미존재)

### 오늘 세션 실측

```bash
$ firebase apphosting:backends:list --project=ai-project-ce41f
benefitbell-web | Hwani-Net-benefitbell | https://benefitbell-web--ai-project-ce41f.asia-east1.hosted.app | asia-east1 | 2026-04-30 01:51:13

$ git log -1 --format='%h %ai' origin/main
568e15e 2026-04-28  # 마지막 push 약 1개월 전

$ git commit --allow-empty -m "trigger rollout" && git push origin main
6446fcda → 6446fcda main -> main

$ # 20분 대기 후
$ curl -sI "https://benefitbell-web--ai-project-ce41f.asia-east1.hosted.app/"
HTTP/1.1 404 Not Found
```

- backend 메타데이터 (`backends:list`) 만 조회 가능, **rollout 상태/로그 조회 불가**
- GitHub push 후 자동 trigger 가 정말 실행됐는지조차 CLI에서 확인 불가능
- 1개월 동안 404 지속 = 이전 push 들도 모두 실패했거나 첫 rollout 자체가 미생성

## 원인 (Root Cause)

### Firebase CLI 한계
2026-05 기준 Firebase CLI v15.11.0 의 `apphosting` 서브커맨드는 backend 관리 (create/list/get) 만 지원하고 **rollout 단위 조작은 미구현**. 공식 docs 에는 `firebase apphosting:rollouts:create` 같은 명령이 언급되어 있으나 실제로 동작하지 않음 (alpha/preview 단계 가능성).

### GitHub auto-trigger 의 불투명성
GitHub push → Firebase App Hosting 자동 trigger 동작 여부, build 시작 여부, build 실패 사유 모두:
- CLI 미지원
- Firebase Console > App Hosting > backend 상세 페이지에서만 확인 가능
- gcloud Cloud Build logs (App Hosting 내부적으로 Cloud Build 사용) 직접 조회 가능하나 권한/네이밍 어려움

### 결과
**자율 진행 시 (대표님 부재) Firebase App Hosting 배포 진단·복구 불가**. Vercel 처럼 `vercel ls --prod`, `vercel inspect`, `vercel logs` 같은 도구 부재.

## 해결 (Resolution)

### 즉시 진단 (대표님 또는 인간 개입 필요)
1. https://console.firebase.google.com/project/ai-project-ce41f/apphosting
2. backend `benefitbell-web` 클릭
3. **"Rollouts" 탭** → 각 rollout 의 status (Building / Failed / Succeeded) + Build log 링크 확인
4. Failed 면 → Cloud Build log URL 클릭 → 실제 에러 메시지

### 빌드 실패 흔한 원인 (Firebase App Hosting + Next.js 16)
- `apphosting.yaml` 에서 Secret Manager 참조 (`secret: KEY_NAME`) 했는데 GCP Secret Manager 에 등록 안 됨 → 빌드 시 환경변수 미주입 → next build 실패
- `output: standalone` 설정 누락 (App Hosting 은 standalone 모드 필요)
- node_modules 누락 또는 package-lock.json 충돌
- Cloud Build IAM 권한 누락

### 우회 (자율 진행)
Firebase App Hosting 빌드 디버깅이 자율 불가능하면 → **Vercel separate** 으로 fallback:
1. Vercel CLI 로 새 프로젝트 link
2. Firebase Secrets 가 필요한 환경변수는 별도 등록 (Vercel Dashboard > Environment Variables) — 대표님 액션 필요
3. Vercel 은 SSR Next.js native 지원 + CLI 진단 풍부

## 재발 방지 (Prevention)

1. **신규 Firebase App Hosting 프로젝트 채택 전 결정 기준**:
   - 자율 진행이 필요한가? → **No, Vercel 권장**
   - Cloud Secret Manager + GCP IAM 통합 필수인가? → Yes 면 Firebase App Hosting, 단 대표님 직접 모니터링 필수
2. **혜택알리미 사례에서 배운 점**:
   - Firebase App Hosting 이 잘 동작 안 하면 디버깅 비용 (시간/컨텍스트) >> Vercel 마이그레이션 비용
   - SSR Next.js 는 **Vercel 이 1순위**, Firebase App Hosting 은 "Cloud Secret Manager 의존성" 외에는 굳이 선택할 이유 없음
3. **CLI 진단 가능성을 도구 선택의 1순위 기준에 포함**:
   - `vercel ls/inspect/logs` ✅
   - `firebase apphosting:rollouts:list` ❌ (미구현)
   - CLI 부재 = 자율 진행 불가 = 대표님 부재 시간 낭비

### Codex 협의 시 명시
"SSR Next.js 배포 후보 — Vercel vs Firebase App Hosting" 같은 질문에서 **자율 진행 가능성 (CLI 진단 도구 유무)** 을 명시적 평가 축으로 포함.

## 관련

- [[pitfall-227-vercel-external-rewrite-path-wildcard-trailing-slash]] — Vercel 검증 사례
- [[pitfall-229-vercel-new-project-deployment-protection-auto-on]] — Vercel 신규 프로젝트 anti-pattern (Firebase 의 다른 anti-pattern과 대비)
- Firebase docs: `/docs/app-hosting/get-started`
- GCP Cloud Build: https://console.cloud.google.com/cloud-build/builds?project=ai-project-ce41f

## 발견 일자, 세션

- **날짜**: 2026-05-27
- **세션**: GPT-KOREA 서비스 다중 배포 (의원다나와 / 혜택알리미 / bite-log)
- **차단된 작업**: 혜택알리미 (naedon-finder/BenefitBell) Firebase App Hosting 배포
- **차단 사유**: GitHub push 후 자동 trigger 결과 진단 불가 → 빌드 미완 또는 silent failure 상태로 무기한 404
- **인계 사항**: 대표님이 Firebase Console 에서 직접 rollout 상태 확인 후 결정 (재시도 / Vercel 마이그레이션)
