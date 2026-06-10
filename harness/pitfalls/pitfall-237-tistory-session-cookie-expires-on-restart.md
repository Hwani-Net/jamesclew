# P-237: 티스토리 세션이 하루 만에 만료 — session cookie(expires=-1)라 browser/gateway 재시작 시 소멸

- **발견**: 2026-05-31 (이동식에어컨 글 발행 직전 auth/login 튕김)
- **영향**: openclaw browser 카카오 로그인이 재시작마다 풀림 → 무인 발행 반감. P-234의 "쿠키 수일~수주" 가정이 틀렸음.

## 증상
- 카카오 1회 로그인 후 P-234에서 "쿠키 영속" 검증했는데, 하루 뒤 발행 시 `/auth/login`으로 튕김.
- 쿠키 파일(__T_, __T_SECURE, kakao)은 **잔존**하는데 세션 무효.

## 근본 원인 (실측)
`openclaw browser cookies` JSON의 expires 필드 확인:
- `__T_`, `__T_SECURE` (.stayicon.tistory.com / .accounts.kakao.com / .www.tistory.com) = **expires=-1 → session cookie** (브라우저 프로세스 종료 시 소멸)
- TUID/UUID (.tiara) = expires=1814748037 (장기 persistent, 단 트래킹용이라 로그인 무관)
- 즉 **로그인 세션 쿠키가 session 타입**이라, openclaw browser/gateway가 재시작될 때마다 소멸.
- 이 세션에서 gateway를 여러 번 재시작(headful env 주입, 멀티봇 작업)했고 그때마다 Edge 프로세스 종료 → session cookie 소멸 → 로그인 풀림.
- P-234가 "stop/start 후 유지" 검증한 건 그 사이 프로세스가 session을 유지한 운/타이밍이었을 뿐, 근본은 session cookie라 영속 불가.

## 해결 (우선순위)
1. **재로그인 시 "로그인 상태 유지" 체크** → 카카오가 persistent 쿠키(장기 expires) 발급하면 재시작에도 유지. **(가설 — 재로그인 후 expires가 -1이 아닌 장기값으로 바뀌는지 실측 검증 필요)**
2. **browser/gateway 재시작 최소화** — 발행 작업 중엔 headful env 등 gateway 변경 금지.
3. **session cookie 추출 후 재주입** — `openclaw browser cookies`로 덤프 → 재시작 후 `cookies set`으로 복원 (자동화 가능하나 카카오 세션 검증 통과 여부 불확실).
4. 차선: 매 발행 전 로그인 상태 점검(navigate newpost → auth/login 여부) → 풀렸으면 재로그인 요청.

## 재발 방지
- P-234 "쿠키 수일~수주" 표현은 **session cookie 케이스에선 틀림** — 재시작마다 만료. P-234에 본 핀폴 링크.
- 발행 자동화 전 반드시 **로그인 상태 점검** 단계 삽입 (navigate → auth/login 감지 → 재로그인 게이트).
- gateway 재시작이 잦은 운영(멀티봇 headful)에선 session cookie 기반 로그인은 근본적으로 취약 → persistent 쿠키 확보(로그인 유지 체크)가 필수.

## 관련
- [[pitfall-234-openclaw-browser-headful-session-bot-autopublish]] (쿠키 영속 가정 정정)
- [[pitfall-230-blog-publish-firebase-image-pipeline]]
- ORCHESTRATION.md §14-B
