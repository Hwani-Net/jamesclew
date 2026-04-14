# 세션 요약: MultiBlog Dashboard MVP (M1+M2)

> 날짜: 2026-04-13 | 주제: MultiBlog Dashboard 구현 (M1 즉시발행 + M2 3플랫폼+모니터링)

## 핵심 성과

### 1. 프로젝트 생성 (D:/MoneyAgent/dashboard/)
- Next.js 16 + React 19 + TypeScript + Tailwind 4 + shadcn/ui
- Firebase 클라이언트 SDK (multi-blog-personal 프로젝트)
- 35개 소스 파일, 빌드 성공

### 2. M1: 즉시 발행 완성
- **대시보드 메인** — KPI 카드(총 발행/성공률/플랫폼/오늘 발행) + 실시간 발행 내역
- **Tiptap 에디터** — 리치 텍스트 + 플랫폼 선택(N/T/B) + 태그 입력 + 발행하기
- **Publish API** (`/api/publish`) — 네이버(CDP)/티스토리(Playwright)/Blogger(REST API) 병렬 발행
- **Publisher 인터페이스** — `PublishInput/PublishResult` 표준 타입
- **Firebase Auth** — Google 로그인 + AuthGuard
- **Firestore 실시간** — `publishing_jobs` 컬렉션 onSnapshot 구독

### 3. M2: 3플랫폼 + 모니터링 완성
- **Blogger API Publisher** — REST API v3, OAuth2 토큰
- **큐 페이지** — 필터 탭(전체/성공/실패/대기), 플랫폼별 상태 확장, 상대 시간
- **설정 페이지** — 플랫폼 연결 상태, 세션 갱신 버튼, 계정 관리
- **세션 갱신 API** (`/api/refresh-session`) — refresh-session.ts spawn
- **Firestore 보안 규칙** — owner-only 접근 + 복합 인덱스 배포 완료

### 4. 인프라
- Firebase 프로젝트: `multi-blog-personal`
- Firestore rules + indexes 배포 완료
- `.firebaserc`, `firebase.json` 설정 완료

## 아키텍처

```
dashboard/
├── src/
│   ├── app/
│   │   ├── page.tsx          # 대시보드 (KPI + 발행 내역)
│   │   ├── editor/page.tsx   # Tiptap 에디터 + 발행
│   │   ├── queue/page.tsx    # 발행 대기열/이력
│   │   ├── settings/page.tsx # 플랫폼 설정 + 세션 관리
│   │   ├── login/page.tsx    # Google 로그인
│   │   └── api/
│   │       ├── publish/route.ts         # 멀티 플랫폼 발행 API
│   │       └── refresh-session/route.ts # 쿠키 갱신 API
│   ├── lib/
│   │   ├── firebase.ts       # Firebase 클라이언트 (lazy init)
│   │   └── publishers/       # 플랫폼별 발행 모듈
│   │       ├── types.ts      # PublishInput/Result/Job 타입
│   │       ├── naver.ts      # CDP + Python 스크립트
│   │       ├── tistory.ts    # Playwright + TinyMCE
│   │       ├── blogger.ts    # REST API v3
│   │       └── index.ts      # 라우터
│   ├── hooks/
│   │   ├── use-publish-jobs.ts  # Firestore 실시간 구독
│   │   └── use-publish.ts      # 발행 액션
│   ├── contexts/auth-context.tsx
│   └── components/ (sidebar, app-shell, auth-guard, ui/)
└── firestore.rules, firestore.indexes.json, firebase.json
```

## 다음 세션 작업 (M3)
1. Firebase Auth Google provider 활성화 (콘솔에서 수동)
2. E2E 발행 테스트 (로그인 → 에디터 → 발행 → 대시보드 확인)
3. 예약 발행 스케줄러 (Firebase Functions cron)
4. 실패 시 자동 재시도 + 텔레그램 알림
5. Blogger OAuth2 토큰 발급 + 갱신 플로우
