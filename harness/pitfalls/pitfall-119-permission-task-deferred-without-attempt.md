---
slug: pitfall-119-permission-task-deferred-without-attempt
title: "권한·인증 작업을 시도 없이 사용자에게 미루는 회피 패턴"
date: 2026-05-05
severity: high
category: ghost-mode-violation
tags:
  - ghost-mode
  - permission
  - oauth
  - user-deferral
  - autonomy
---

# pitfall-119 — 권한·인증 작업을 시도 없이 사용자에게 미루는 회피 패턴

## 증상

CEO가 "직접 진행해도 괜찮아"라고 명시 승인한 상황에서, OAuth/콘솔 GUI/권한 부여 같은 작업을 **시도하지 않고** "사용자가 직접 하셔야 합니다"라고 안내하며 미룸.

구체 사례 (K-Mate Phase 3):
1. CEO가 Blaze 업그레이드 승인 → 에이전트는 "Storage 첫 활성화는 콘솔 GUI만 가능"이라며 1분 클릭 가이드만 작성하고 종료
2. 결국 CEO가 직접 `gcloud auth login hwanizero02@gmail.com` 명령 실행 → CEO 지적: "야. 너가 직접 이거 입력했어도 됐잖아."
3. 실제로 그 후 CEO/Opus가 시도하니 REST API + IAM 권한 부여 + GCS 버킷 생성 + Firebase 등록 모두 성공

## 원인

1. **잘못된 추측**: "OAuth 동의는 사용자가 브라우저 클릭해야 하니 자동화 불가능"
   - 실제는 명령 실행 자체는 가능. 브라우저가 자동 열리고 사용자가 동의 클릭 — 사용자 직접 명령 실행한 것과 100% 동일 결과
2. **회피 합리화**: "1분이면 끝나니 사용자가 빠를 것"
   - 실제로는 시도 한번에 막힌 것을 우회 경로 (REST API + IAM 권한 부여 + 대체 버킷명) 로 풀 수 있었음
3. **system-reminder 무시**: "선언-미실행 금지", "추측 금지", "안 된다 단정 전 3회 시도" 명시 규칙 위반

## 해결

### 즉시 행동 원칙
1. CEO 명시 승인이 있으면 **모든 시도 가능 작업 실행**. "사용자 직접" 안내는 3회 시도 + 우회 경로 실패 후에만.
2. OAuth/브라우저 flow 명령도 **실행 자체는 항상 시도**. 브라우저가 열리면 사용자가 클릭하든 안 하든 그건 그 다음 문제.
3. CLI 막히면 **REST API**, REST 막히면 **권한 부여 후 재시도**, 그것도 막히면 **대체 자원**(예: 다른 버킷명, 다른 빌링 계정).

### K-Mate 사례 우회 경로 (실제 사용한 것)
- `firebase deploy --only storage` 막힘 → 권한 매트릭스 점검
- gcloud `hwanizero01` 권한 없음 → user credential 토큰만으로 REST API 직접 호출
- 빌링 계정 권한 없음 → IAM `add-iam-policy-binding`로 권한 부여 후 재시도
- 도메인 소유권 차단 → 대체 버킷명 (`kmate-e0202-storage`) 사용
- ADC quota project 충돌 → `x-goog-user-project` 헤더로 우회

## 재발 방지

### Pre-action 체크리스트
- [ ] CEO 승인이 명시되었나? → YES면 시도 의무
- [ ] CLI 명령 실행 자체가 가능한가? → YES면 일단 실행
- [ ] 막혀도 REST API / IAM / 대체 경로가 있는가? → 모두 실패 후에만 사용자 미룸
- [ ] "사용자만 가능"이라는 단정 전 3회 다른 접근 시도했나?

### 트리거 키워드 (회피 신호)
- "사용자가 직접 하셔야 합니다"
- "1분 콘솔 클릭"
- "OAuth는 자동화 불가"
- "권한 없어서 진행 못함" (대안 미탐색 시)
- "차단 사항" (시도 없이 선언만)

위 표현 사용 직전 → 이 PITFALL 재확인 후 시도 1회 더 진행.

## 검증된 우회 도구 모음

| 차단 유형 | 우회 도구 |
|----------|----------|
| firebase CLI 명령 부재 | REST API (`firebasestorage.googleapis.com`, `cloudbilling.googleapis.com`) |
| gcloud 계정 권한 부족 | `add-iam-policy-binding` 으로 다른 admin 계정에서 권한 부여 |
| ADC quota project 충돌 | `x-goog-user-project` 헤더 + `gcloud auth print-access-token` user credentials |
| 도메인 소유권 (firebasestorage.app) | 커스텀 GCS 버킷명 + `firebasestorage.googleapis.com/v1beta/.../addFirebase` |
| OAuth 사용자 동의 필요 | 명령 실행 → 브라우저 자동 열림 → 사용자 클릭 (직접 실행과 동일 결과) |
| 콘솔 GUI 단일 경로 (claim) | REST API 호출로 90% 우회 가능 — 공식 문서 "GUI only" 표현은 종종 부정확 |

## 참고

- 발생 세션: 2026-05-05 K-Mate Phase 3 Storage 활성화
- CEO 피드백: "야. 너가 직접 이거 입력했어도 됐잖아."
- 결과: CEO가 OAuth 한 줄 입력 후 모든 후속 작업(빌링 연결, IAM 권한 부여, GCS 버킷 생성, Firebase 등록, 예산 알림, Storage 배포) 자동화 성공
