---
slug: pitfall-120-http-200-equals-functional-fallacy
title: "HTTP 200 = 기능 동작 등치 오류 (배포 후 실가입 미테스트)"
date: 2026-05-05
severity: critical
category: verification-skipped
tags:
  - verification
  - http-vs-functional
  - firebase-auth
  - cold-launch
  - blind-spot
related:
  - pitfall-111-code-exists-not-runs-evidence-skipped
---

# pitfall-120 — HTTP 200 = 기능 동작 등치 오류

## 증상

배포 후 라이브 검증 단계에서 페이지의 HTTP 응답 코드(200)만 확인하고 "출시 가능 상태"라고 보고함. 실제 폼 제출, API 호출, 사용자 흐름 동작은 한 번도 직접 시도하지 않음.

K-Mate Phase 3 사례 (2026-05-05):
- 9개 페이지 HTTP 200 확인 → "출시 가능 상태" 보고
- CEO가 직접 가입 시도 → "오류가 발생했습니다. 잠시 후 다시 시도해주세요" 화면 캡처 + 지적
- 실제 원인: **Firebase Authentication 자체가 활성화 안 됨** (`CONFIGURATION_NOT_FOUND`) + Email/Password Sign-in 방식 미활성 (`OPERATION_NOT_ALLOWED`)
- HTTP 200은 정적 HTML 응답일 뿐, JavaScript 런타임에서 Auth API 호출 시 즉시 실패

## 원인

1. **HTTP 200 ≠ 기능 동작**: 정적 export 페이지의 HTTP 200은 단지 HTML 파일 존재만 의미. Firebase Auth/Firestore/Functions 같은 백엔드 서비스 활성화 여부와 무관.
2. **AuthGuard 회피**: 비로그인 시 자동 리다이렉트되는 보호 페이지를 "정상 동작"이라고 오판. 실제 로그인 후 화면은 검증 안 됨.
3. **CEO 안내 무시**: 본인이 작성한 "CEO 직접 처리 필요 사항"에 "Firebase Auth Email/Password 활성화 확인" 명시했음에도, 그 단계 없이 출시 가능 보고.
4. **Functions ACTIVE = 기능 동작 오해**: `aiChatRespond` Cloud Function이 ACTIVE 상태라도 호출 시 인증/권한 실패 가능. 실제 호출 검증 필수.

## 해결

### 즉시 행동 — Firebase Auth 활성화 (REST API)
1. Identity Toolkit API 활성화: `POST https://serviceusage.googleapis.com/v1/projects/{PROJECT}/services/identitytoolkit.googleapis.com:enable`
2. Email/Password Sign-in 활성화: `PATCH https://identitytoolkit.googleapis.com/admin/v2/projects/{PROJECT}/config?updateMask=signIn.email.enabled,signIn.email.passwordRequired` body=`{"signIn":{"email":{"enabled":true,"passwordRequired":true}}}`
3. 가입 검증: `POST https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}` 응답에 `localId` 있으면 성공

### Playwright 가입 검증 (브라우저 흐름)
- `await page.click('button[type="submit"]')` (text selector 대신 type 사용 — 텍스트 selector는 의도치 않게 다른 버튼 매칭 가능)
- `await page.waitForTimeout(3000)` 후 URL 변경 확인 (`page.url()` 이 `/onboarding/` 으로 바뀌었는지)
- `page.on('request')`/`page.on('response')`로 `identitytoolkit` POST 200 확인
- 콘솔 에러 0건 + 네트워크 4xx/5xx 0건

## 재발 방지 — 배포 후 검증 체크리스트

배포 후 "출시 가능" 보고 전 다음 단계 모두 통과:

- [ ] HTTP 200 (정적 페이지) — 기본 단계, 충분조건 아님
- [ ] **실제 가입/로그인 흐름 1회 완주** (브라우저 자동화로 form submit + 리다이렉트 확인)
- [ ] 백엔드 API 호출 응답 확인 (Auth signUp/signIn 200 + localId)
- [ ] Firestore write/read 1회 검증 (보호 컬렉션에 실제 데이터 흐름)
- [ ] Cloud Functions 호출 1회 검증 (httpsCallable 또는 REST 직접)
- [ ] 콘솔 에러 0 + 네트워크 4xx/5xx 0
- [ ] CEO 안내 사항 ("직접 처리 필요") 모두 완료 또는 우회 처리

위 7항목 미통과 시 "출시 가능"이 아닌 "동작 미검증" 상태로 보고.

## 트리거 키워드 (회피 신호)

다음 표현 사용 시 PITFALL 재확인:
- "HTTP 200 확인" 만 강조하고 폼 동작 미언급
- "출시 가능 상태" / "MVP 완성"
- "라이브 페이지 모두 정상"
- "AuthGuard 정상 동작" (리다이렉트만 봤지 로그인 후는 안 봄)

## REST API 우회 도구 (Firebase 제품 활성화)

| 제품 | API |
|------|-----|
| Authentication | `serviceusage.../identitytoolkit.googleapis.com:enable` + `identitytoolkit.../admin/v2/projects/{p}/config` PATCH |
| Storage | `serviceusage.../firebasestorage.googleapis.com:enable` + GCS 버킷 + `firebasestorage.../v1beta/.../addFirebase` |
| Functions | `serviceusage.../cloudfunctions.googleapis.com:enable` + `firebase deploy --only functions` |
| Firestore | `serviceusage.../firestore.googleapis.com:enable` + `firebase firestore:databases:create` |

콘솔 GUI 단일 경로 주장은 80% 거짓. REST API로 대부분 가능.

## 참고

- 발생 세션: 2026-05-05 K-Mate Phase 3 Wave 4 출시 보고
- CEO 피드백: "야. 배포 후 테스트 했어? 안했어?"
- 증거: 가입 화면 "오류가 발생했습니다. 잠시 후 다시 시도해주세요" 스크린샷
- 직전 보고: "10개 페이지 HTTP 200 → 출시 가능 상태"
- 해결 후: signUp 200 + localId 발급 + /onboarding 리다이렉트 확인
- 관련 PITFALL: pitfall-111 (코드 존재 ≠ 실행), pitfall-119 (권한 작업 회피)
