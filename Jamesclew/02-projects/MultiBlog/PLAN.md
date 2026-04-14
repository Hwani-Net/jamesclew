# Multi Blog 구현 플랜 (PLAN.md)

> 작성일: 2026-04-07 | 기반: PRD v1.0 | T1~T15 구현 플랜

## 사전 PoC 필요 항목 (T1 이전, 약 5~7일)

PRD R7~R8 및 오픈 질문에서 식별한 고위험 미지수를 T1 진입 전에 해소한다. 이 PoC가 실패하면 BYOC 전략 자체를 재검토해야 하므로 절대 건너뛰지 말 것.

1. **AI CLI 호출 인터페이스 매핑 PoC** (2일)
   - Claude Code: `claude` CLI의 stdin/stdout 모드, `claude-agent-sdk` Python/TS, headless 모드(`--print`) 검증
   - Codex CLI: ChatGPT Plus 계정으로 OAuth 후 stdin 호출, 응답 포맷 정규화 가능 여부
   - Gemini CLI: `gemini` CLI headless 호출, Google AI Pro 토큰 갱신 주기
   - Antigravity, opencode: 공식 호출 모드 존재 여부, 없으면 V1 제외 결정
   - **산출물**: 어댑터 인터페이스 표 (CLI별 명령·환경변수·exit code·rate limit 응답 시그니처)

2. **Playwright 네이버/티스토리 봇 차단 회피 PoC** (2일)
   - playwright-extra + stealth 플러그인 + persistent context (사용자별 user-data-dir)
   - 네이버 SmartEditor iframe 진입 → JSON 페이로드 직접 주입 vs UI 시뮬레이션 비교
   - 티스토리 OpenAPI 종료 후 글쓰기 페이지 DOM 안정성, 캡차 트리거 임계
   - **산출물**: 100회 반복 발행 성공률 측정 + 차단 트리거 패턴 문서

3. **Tauri + Firestore 큐 폴링 헬퍼 프로토타입** (1.5일)
   - Tauri 2.x에서 Firebase Admin SDK Rust 바인딩 또는 REST 폴링
   - 헬퍼가 PWA Service Worker와 BroadcastChannel/IPC 동기화
   - 모바일 트리거 → Firestore 큐 → 데스크톱 헬퍼 픽업 → CLI 호출 → 결과 push 사이클 측정 (목표 < 5초)
   - **산출물**: 동작 영상 + 헬퍼 바이너리 50MB 이하 검증

4. **각 CLI ToS 법무 검토** (병렬, 비동기)
   - Anthropic, OpenAI, Google ToS에서 "CLI 토큰을 외부 호출 라우터에서 재사용" 조항 확인
   - 한 CLI라도 명시적 금지면 해당 어댑터 V1 제외, 나머지로 시작

---

## T1: Firebase 프로젝트 + Auth + Firestore + Hosting 셋업
- **목표**: 멀티 환경(dev/stg/prod) Firebase 프로젝트와 Next.js 14 PWA 기본 골격을 구동 가능 상태로 만든다.
- **전제 조건**: 사전 PoC 완료, Google Cloud 결제 계정, 도메인(`multiblog.kr` 가칭)
- **세부 단계**:
  1. Firebase 프로젝트 3개 생성 (`mb-dev`, `mb-stg`, `mb-prod`), 리전 `asia-northeast3`(서울) 고정
  2. Firebase CLI + `firebase init` (Hosting, Firestore, Functions, Emulators, Storage)
  3. Next.js 14 App Router + TypeScript + Tailwind + `next-pwa` 스캐폴드, `output: 'export'` 또는 Functions SSR 결정
  4. Firebase Auth 활성화: Google, GitHub, Kakao(커스텀 토큰 경유) 프로바이더
  5. `.env.local` + `firebase.json` + `firestore.rules` 초기값 (deny-all → 점진 개방)
  6. GitHub Actions: PR마다 `mb-dev` Hosting Channel 배포, main merge 시 stg
  7. Sentry, Firebase Analytics SDK 설치
- **산출물 / DoD**:
  - `https://mb-dev.web.app`에서 "Hello Multi Blog" 페이지 + Google 로그인 동작
  - Firestore Emulator 로컬 구동 확인
  - CI 그린, PR 프리뷰 URL 자동 생성
- **기술 스택 결정**: Next.js 14, next-pwa, Firebase SDK v10, Firebase Functions Gen2, pnpm, Turborepo(모노레포: web/functions/helper)
- **예상 위험·주의사항**: Functions Gen2는 `asia-northeast3` 일부 트리거 미지원 → 트리거 종류별 리전 분리 필요. Kakao OAuth는 Firebase 미지원 → Functions에서 customToken 발급 라우트 필요.

---

## T2: 디자인 시스템 + DESIGN.md (Stitch)
- **목표**: 다크모드 우선 디자인 토큰과 핵심 화면 6종을 확정해 이후 UI 태스크를 막힘없이 진행한다.
- **전제 조건**: T1
- **세부 단계**:
  1. blog-auto 워크스페이스 기존 DESIGN.md 검토 → 토큰 상속 가능 여부 판단
  2. Stitch MCP로 디자인 시스템 생성 (Indigo #4F46E5 / Lime #84CC16 / Slate #0F172A)
  3. 화면 생성: 로그인, 통합 대시보드, 에디터, 발행 대상 선택 모달, 모바일 PWA 홈, 계정 연동(특히 BYOC AI CLI 체인 드래그&드롭)
  4. linear.app, supabase.com 벤치마킹 캡처 → 모션·간격 토큰 조정
  5. shadcn/ui + Radix 기반 컴포넌트 라이브러리 선택, 토큰 매핑
  6. `MultiBlog/DESIGN.md` 작성: 토큰표, 컴포넌트 인벤토리, 화면별 와이어
- **산출물 / DoD**: DESIGN.md, Stitch 프로젝트 URL, Figma-like 화면 6종, 디자인 토큰 JSON
- **기술 스택 결정**: shadcn/ui, Radix UI, Tailwind, Stitch MCP, Lucide 아이콘
- **위험**: BYOC 체인 UI는 신규 패턴이라 벤치마킹 부재 → MVP는 단순 정렬 리스트로 시작.

---

## T3: 사용자/계정/플랫폼 자격증명 데이터 모델 + 보안 룰 + KMS 암호화
- **목표**: 사용자·플랫폼 계정·발행 큐·LLM 계정의 Firestore 스키마와 보안 모델을 확정한다.
- **전제 조건**: T1
- **세부 단계**:
  1. Firestore 컬렉션 설계:
     - `users/{uid}`, `users/{uid}/platforms/{platformId}`, `users/{uid}/llmChains/{chainId}`, `users/{uid}/llmAccounts/{accountId}`
     - `posts/{postId}`, `publishJobs/{jobId}`, `publishJobs/{jobId}/targets/{targetId}`
     - `taskQueue/{taskId}` (헬퍼 폴링 대상)
  2. Firestore Rules: uid 일치 검증, KMS 암호화 필드는 클라이언트 직접 read 금지(서버 함수 경유)
  3. GCP KMS 키링 생성 (`mb-credentials`), Functions 서비스 계정에 `cloudkms.cryptoKeyEncrypterDecrypter` 부여
  4. `encryptCredential`/`decryptCredential` Functions 작성 (envelope encryption)
  5. **중요 결정**: AI CLI OAuth 토큰은 Firestore 절대 미저장. 메타데이터(닉네임·모델·우선순위·사용량)만 저장
  6. TypeScript 타입(`@multiblog/schema`) 패키지로 web/functions/helper 공유
- **산출물 / DoD**: `schema.ts`, `firestore.rules`, KMS 암복호화 단위 테스트 통과, 권한 매트릭스 문서
- **기술 스택 결정**: Firestore, GCP KMS, Zod 스키마 검증
- **위험**: Rules 복잡도 증가 → 통합 테스트(`@firebase/rules-unit-testing`) 필수.

---

## T4: OAuth 통합 + BYOC 멀티 AI CLI 라우터
- **목표**: 사용자 로그인, 플랫폼 OAuth, BYOC 체인 UI까지 단일 태스크로 끝낸다(가장 큰 태스크, 7~10일).
- **전제 조건**: T3, 사전 PoC 1
- **세부 단계**:
  1. Firebase Auth 통합 (Google/GitHub/Kakao customToken 라우트)
  2. 플랫폼 OAuth: Google(Blogger scope `https://www.googleapis.com/auth/blogger`), WordPress.com REST OAuth (refresh token 저장은 KMS 암호화)
  3. BYOC 메타데이터 모델 확정: `llmAccount {provider, model, alias, priority, status, usageToday, resetAt}`, `llmChain {steps:[{provider, accountIds[]}]}`
  4. BYOC 등록 UI: CLI별 "헬퍼에서 토큰 가져오기" 버튼 → 헬퍼가 로컬에서 OAuth 수행 후 메타데이터만 Firestore 업로드
  5. 체인 편집기: dnd-kit 드래그&드롭, 계층 추가/삭제, 라운드로빈 vs LRU 토글
  6. 사용량 표시: 헬퍼가 30초마다 `llmAccounts/{id}.usage` 업데이트, UI 실시간 구독
  7. **라우터 코어** (`@multiblog/llm-router` 패키지): 호출 시 체인 순회 → 헬퍼 RPC `invokeLLM(chainId, prompt)` → 헬퍼가 적절 계정 선택·CLI 실행·rate limit 시 다음 계정 fallback → 결과 스트리밍 반환
  8. 사용자 직접 API 키 fallback 입력 (KMS 저장)
- **산출물 / DoD**:
  - 로그인 → BYOC 화면에서 Claude Code 계정 3개 + Codex 2개 + Gemini 4개 등록
  - 체인 변경 → DB 반영 → 헬퍼 RPC 통해 실제 LLM 호출 성공
  - 한 계정 강제 rate limit → 자동 다음 계정 전환 로그 확인
- **기술 스택 결정**: dnd-kit, Tauri IPC(`@tauri-apps/api`), 헬퍼 ↔ 웹은 로컬 HTTP(127.0.0.1) + 짝짓기 토큰
- **위험**: CLI마다 OAuth 흐름이 다름 → 어댑터 패턴 강제. R7 ToS 변경 모니터링 필요.

---

## T5: 네이버/티스토리 자격증명 입력 UI + 안전 저장
- **목표**: 사용자 ID/PW를 안전하게 받아 Playwright 워커가 사용할 수 있게 한다.
- **전제 조건**: T3
- **세부 단계**:
  1. 자격증명 입력 폼 (마스킹, 클립보드 자동 클리어)
  2. Functions `saveCredential` → KMS 암호화 → Firestore 저장
  3. 저장된 자격증명은 Functions 또는 Tauri 헬퍼만 복호화 가능 (옵션 토글: "내 PC에서만 발행" → 로컬 전용 IndexedDB 암호화)
  4. 약관 동의 체크박스: "본인 계정·본인 IP에서만 사용 동의"
  5. 자격증명 유효성 사전 검증 워커 (헬퍼가 헤드리스 로그인 1회 시도)
- **산출물 / DoD**: 자격증명 저장→검증 OK 표시→Playwright 워커가 실제 사용 가능
- **기술 스택 결정**: GCP KMS, Web Crypto API(로컬 모드), Tauri secure storage
- **위험**: R1 (계정 정지). 사용자 IP 우선 사용 정책으로 완화.

---

## T6: 마크다운 에디터 + 플랫폼별 변환 어댑터
- **목표**: 단일 마크다운 원본을 4종 포맷(WP Gutenberg JSON, 네이버 SmartEditor JSON, 티스토리 HTML, Blogger HTML)으로 손실 없이 변환한다.
- **전제 조건**: T2
- **세부 단계**:
  1. 에디터: TipTap(ProseMirror) 또는 Milkdown 선정. Markdown source-of-truth + WYSIWYG 토글
  2. 이미지 업로드 → Firebase Storage → CDN URL
  3. 변환 어댑터 패키지 `@multiblog/converters`:
     - `toGutenberg(md)` → block JSON
     - `toSmartEditor(md)` → SmartEditor 3.0 컴포넌트 트리 (PoC 결과 기반)
     - `toTistoryHtml(md)` → sanitized HTML + style 인라인
     - `toBloggerHtml(md)` → blogger 호환 HTML
  4. 표·코드블록·이미지 사이즈·캡션 보존 단위 테스트 30+ 케이스
  5. 미리보기 탭(플랫폼별 렌더링 시뮬레이션)
- **산출물 / DoD**: 각 포맷별 골든 파일 테스트 통과, 미리보기 화면 동작
- **기술 스택 결정**: TipTap, remark/rehype, DOMPurify
- **위험**: 네이버 SmartEditor 페이로드 포맷이 비공개 → PoC2 결과에 의존. 실패 시 Playwright 페이스트 폴백.

---

## T7: blog-auto 출력 import 어댑터
- **목표**: blog-auto 출력 폴더(50건+)를 일괄 import해 50건 큐를 만든다.
- **전제 조건**: T6
- **세부 단계**:
  1. blog-auto 출력 스키마 조사 (frontmatter + 본문 + meta.json)
  2. 데스크톱 헬퍼에 폴더 워처(notify-rs) 추가
  3. 변경 감지 → 메타 파싱 → Firestore `posts` 업로드(이미지는 Storage)
  4. 웹 UI "Import" 화면: 드래그&드롭, 미리보기 리스트, 일괄 큐 등록 버튼
  5. 중복 hash 체크 (제목+첫 200자 SHA-256)
- **산출물 / DoD**: blog-auto 50건 폴더 → 30초 안에 50건 posts 생성
- **기술 스택 결정**: notify-rs(Rust), gray-matter, sharp(이미지 리사이즈)
- **위험**: 대용량 이미지 일괄 업로드 시 Storage 비용 → 사전 압축.

---

## T8: 발행 엔진 - WordPress REST + Blogger API v3 워커
- **목표**: API 플랫폼 발행 성공률 99% 달성.
- **전제 조건**: T4
- **세부 단계**:
  1. Cloud Functions Gen2 워커 `publishWordpress`, `publishBlogger` (최대 540s 타임아웃)
  2. WordPress REST: `/wp-json/wp/v2/posts` + 미디어 업로드 + 카테고리/태그/canonical 메타
  3. Blogger API v3: `posts.insert` + label + customMetaData
  4. 멱등성: `jobId` 기반 dedup, 재시도 시 기존 post 업데이트
  5. 에러 분류: 4xx(영구실패) vs 5xx/network(재시도) → 큐 정책 결정
  6. 통합 테스트: 테스트 WP/Blogger 계정으로 매일 자동 발행 검증
- **산출물 / DoD**: 100건 발행 테스트 99건 성공, 실패 1건 재시도 성공
- **기술 스택 결정**: Functions Gen2, axios, googleapis SDK
- **위험**: WP 사용자별 권한·플러그인 충돌. canonical 플러그인 부재 시 헤더 직접 삽입.

---

## T9: Playwright 워커 - 네이버 + 티스토리
- **목표**: 봇 차단율 5% 미만으로 안정 발행.
- **전제 조건**: T5, 사전 PoC 2
- **세부 단계**:
  1. Tauri 헬퍼에 Playwright 번들(또는 사용자 PC Chromium 재사용)
  2. playwright-extra + stealth, 사용자별 `user-data-dir`
  3. 네이버 워커: 로그인 → SmartEditor iframe → PoC2 페이로드 주입 또는 UI 시뮬
  4. 티스토리 워커: 로그인 → 글쓰기 → HTML 모드 페이스트 → 카테고리/태그 셀렉트
  5. 휴먼 패턴: 랜덤 딜레이 200~1500ms, 마우스 이동 곡선
  6. 캡차 감지 → 작업 일시정지 + 사용자 알림 (PWA 푸시)
  7. 결과(URL/스크린샷)를 Firestore 잡 결과로 보고
- **산출물 / DoD**: 100회 발행 95회 성공, 차단 5회 자동 백오프 후 사용자 알림
- **기술 스택 결정**: Playwright, playwright-extra, stealth, Tauri sidecar
- **위험**: 네이버/티스토리 DOM 변경 → 매주 통합테스트 + 어댑터 버전 핀.

---

## T10: 발행 큐 시스템 + 시차 발행 + canonical 삽입
- **목표**: SEO 보호 시차 발행 엔진 완성.
- **전제 조건**: T8, T9
- **세부 단계**:
  1. `publishJobs` + `targets` 모델 구현, target별 `tier(1/2/3)` + `scheduledAt`
  2. Cloud Tasks 큐 3개: `tier1-immediate`, `tier2-2h`, `tier3-24h`
  3. 발행 잡 생성 시 Tier 1 즉시 큐, Tier 2/3는 +2h/+24h 스케줄
  4. canonical URL 결정 로직: Tier 1 발행 결과 URL → Tier 2/3 메타에 자동 삽입
  5. API 플랫폼은 Functions가 직접 처리, 네이버/티스토리는 `taskQueue` Firestore 도큐먼트 생성 → 헬퍼가 폴링·실행·결과 보고
  6. 재시도 정책: exponential backoff, 최대 5회
  7. 50건 일괄 큐 등록 + 예약 패턴("매일 9시/18시") 분배
- **산출물 / DoD**: 1건 글이 정확히 0/120/1440분 간격으로 5플랫폼 발행 + canonical 정확
- **기술 스택 결정**: Cloud Tasks, Firestore triggers, dayjs(timezone)
- **위험**: 모바일 트리거 시 헬퍼 오프라인 → 큐 보류 + 푸시 알림.

---

## T11: 통합 대시보드 (데스크톱)
- **목표**: 발행 상태·큐·재시도·플랫폼 헬스를 한 화면에서.
- **전제 조건**: T10
- **세부 단계**:
  1. 대시보드 레이아웃: 좌측 사이드바(발행/큐/통계/설정), 메인 카드 그리드
  2. 실시간 잡 상태 테이블 (Firestore onSnapshot)
  3. 큐 뷰: 예약 시각순, 드래그로 재정렬, 일괄 취소
  4. 실패 잡 재시도 버튼 + 에러 로그 모달
  5. 헬퍼 연결 상태 인디케이터 (온라인/오프라인/마지막 핑)
- **산출물 / DoD**: 진행 중 5플랫폼 발행이 실시간 진행바로 보임
- **기술 스택 결정**: TanStack Table, Recharts, shadcn/ui
- **위험**: onSnapshot 비용 → 페이지네이션·인덱스 설계 필수.

---

## T12: 통계 수집 모듈
- **목표**: 4 플랫폼 PV/UV를 단일 대시보드로 통합.
- **전제 조건**: T10
- **세부 단계**:
  1. Google Analytics Data API v1 (워드프레스/블로거/개인 블로그용) — 사용자 OAuth scope 추가
  2. 네이버 애널리틱스: 공식 API 부재 → 헬퍼가 Playwright로 일 1회 스크래핑
  3. 티스토리 통계: 동일하게 헬퍼 스크래핑
  4. `stats/{date}/{platform}` 일별 집계 저장
  5. 어제/오늘/7일/30일 차트, 플랫폼별 비교
  6. Best/Worst 글 자동 추출
- **산출물 / DoD**: 대시보드에서 4 플랫폼 통계가 단일 차트로 표시
- **기술 스택 결정**: GA Data API, Recharts
- **위험**: 스크래핑 차단 → 빈도 1회/일로 제한, 실패 시 수동 입력 폴백.

---

## T13: 모바일 PWA 대시보드
- **목표**: 시나리오 2(지하철 통계 확인) 완성.
- **전제 조건**: T11
- **세부 단계**:
  1. next-pwa manifest, 아이콘, splash, offline fallback
  2. 모바일 우선 레이아웃: 어제 발행 카드 → 탭 → 상세
  3. 푸시 알림(Firebase Messaging): 발행 완료, 차단 알림, BYOC rate limit
  4. 모바일에서 발행 트리거 → Firestore taskQueue → 데스크톱 헬퍼 픽업 흐름 검증
  5. 오프라인 큐: 작성 중 글 IndexedDB 저장
- **산출물 / DoD**: iOS Safari/Android Chrome에서 홈화면 추가 + 푸시 수신
- **기술 스택 결정**: next-pwa, Workbox, Firebase Messaging
- **위험**: iOS PWA 푸시 제약 → Web Push 16.4+ 요구 안내.

---

## T14: E2E 테스트 - Alpha 시나리오 5종
- **목표**: Alpha 진입 전 핵심 시나리오 자동 검증.
- **전제 조건**: T11, T12, T13
- **세부 단계**:
  1. Playwright 테스트 환경 (테스트용 WP/Blogger/네이버/티스토리 계정 분리)
  2. 시나리오 1: 단일 글 5플랫폼 발행
  3. 시나리오 2: 시차 발행 (Tier 1/2/3 시간 mock)
  4. 시나리오 3: blog-auto 50건 import + 큐
  5. 시나리오 4: 모바일 통계 확인
  6. 시나리오 5: 봇 차단 시뮬→복구
  7. CI Nightly 실행, 결과 Slack 알림
- **산출물 / DoD**: 5 시나리오 그린, 실패 시 영상 아카이브
- **기술 스택 결정**: Playwright Test, GitHub Actions
- **위험**: 실계정 사용 비용 → 격리된 테스트 워크스페이스 필수.

---

## T15: 결제 + 약관 + Public Beta 배포
- **목표**: 유료 결제 활성화하고 Public Beta 오픈.
- **전제 조건**: T14
- **세부 단계**:
  1. Stripe + 토스페이먼츠 듀얼 통합 (사용자 통화·국가 기반 분기)
  2. Firestore `subscriptions/{uid}`, webhook 처리 Functions
  3. 무료 티어 enforcement: 월 10건 카운터 + 발행 시 Functions 차단
  4. 약관/개인정보/환불 정책 페이지, 각 AI CLI ToS 동의 체크박스
  5. 가격 페이지 (Free / Pro ₩19,900 / Business ₩49,900)
  6. 베타 가입 페이지 + 대기자 명단 → 500명 한도 자동 활성화
  7. prod 환경 마이그레이션, 도메인 연결, status page
  8. 모니터링: Sentry, Firebase Performance, BigQuery export
- **산출물 / DoD**: 결제→구독 활성→발행 한도 해제까지 E2E, prod 배포 완료
- **기술 스택 결정**: Stripe Checkout, 토스페이먼츠 결제창 v2, Statuspage
- **위험**: 듀얼 결제 webhook 동기화 → 단일 진실 소스(`subscriptions`) 강제.

---

## 크리티컬 패스

```
T1 ─┬─ T2 ──────────────── T6 ── T7 ──────────────┐
    ├─ T3 ─┬─ T4 ── T8 ──┐                       │
    │      └─ T5 ── T9 ──┴─ T10 ── T11 ── T13 ──┴─ T14 ── T15
    │                              └─ T12 ──────┘
```

- **최장 경로**: T1 → T3 → T5 → T9 → T10 → T11 → T13 → T14 → T15 (Playwright 안정화가 가장 큰 리스크)
- **병렬 가능**:
  - T2와 T3는 T1 직후 동시 시작
  - T4(BYOC, OAuth)와 T5(네이버 자격) 동시
  - T8(API 워커)과 T9(Playwright 워커) 동시
  - T11/T12/T13는 T10 직후 3트랙 병렬
- **블로커 후보**: T9(Playwright)와 T4(BYOC OAuth). 둘 다 PoC 결과에 의존.

---

## 권장 시작 순서 (1주차 Sprint)

**전제**: 사전 PoC 1주가 이미 끝났다고 가정.

| Day | 작업 | 담당 트랙 |
|-----|------|----------|
| D1 | T1 Firebase 3환경 + Next.js 스캐폴드 + CI | 인프라 |
| D2 | T1 Auth(Google/GitHub) + Hosting Channel + Sentry | 인프라 |
| D2~D3 | T2 Stitch 디자인 시스템 + DESIGN.md 초안 | 디자인 |
| D3~D5 | T3 데이터 모델 + Rules + KMS 암복호화 Functions | 백엔드 |
| D4~D7 | T4 시작 — Firebase Auth + Google/Kakao + BYOC 메타데이터 모델 | 풀스택 |
| D5~D7 | Tauri 헬퍼 골격(폴링 + IPC) — T4와 병렬 | 데스크톱 |

**1주차 종료 시점 DoD**: 로그인 → 빈 대시보드 진입 → 데이터 모델 확정 → BYOC 등록 화면 wireframe 동작 → 헬퍼가 Firestore 큐 폴링 성공.

---

## 핵심 인사이트 3가지

1. **사전 PoC 5~7일이 전체 일정을 좌우한다.** Playwright 차단 회피와 AI CLI 호출 인터페이스 매핑이 실패하면 BYOC와 네이버/티스토리 발행이 무너지므로 T1 이전에 반드시 검증한다.
2. **T4(BYOC 멀티 CLI 라우터)가 가장 큰 단일 태스크이며 시장 차별화의 90%를 책임진다.** 어댑터 패턴 + 로컬 헬퍼 RPC + Firestore에는 토큰 절대 미저장 원칙을 코드 레벨에서 강제해야 R7/R8 리스크가 통제된다.
3. **크리티컬 패스는 T9(Playwright)다.** API 플랫폼(T8)은 비교적 안정적이지만 네이버/티스토리 자동화는 매주 깨질 수 있으므로 T14 E2E 테스트를 nightly로 돌려 회귀 감지 루프를 일찍부터 가동해야 GA 일정이 지켜진다.
