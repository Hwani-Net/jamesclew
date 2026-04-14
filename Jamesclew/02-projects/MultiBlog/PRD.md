# Multi Blog PRD

> 작성일: 2026-04-07 | 버전: **v3.0 (Quality Pipeline 추가)** | 작성자: JamesClaw Agent
>
> **v3.0 변경 요약 (2026-04-11)**: v2.0(개인용 도구 피벗) 전제를 유지하면서 **콘텐츠 생성 + 품질 게이트 + 자동 수정 루프** 3개 기능(F6~F8)을 V1 P0으로 추가. 대표님은 텔레그램으로 결과만 받고, 품질 실패 시에만 개입하는 구조. 기존 F6~F9(댓글·봇복구·팀·A/B)는 F9~F12로 번호 재부여. 핵심 문제 정의에 "AdSense 품질 기준 충족" 추가. Job Stories JS#6~JS#8 신규 추가. 리스크 R11~R12, 품질 KPI, NFR 품질 항목, 태스크 T16~T20 신규 추가.
>
> **v2.0 변경 요약 (2026-04-07)**: SaaS → **개인용 로컬 자동화 도구**로 피벗. 이유: PoC 1 결과 Anthropic·Google이 third-party OAuth 재사용을 명시 금지·서버 차단·계정 ban 사례 확인. 그러나 vendor 모두 "personal use and local experimentation"은 명시 허용. 본인 PC에서 본인이 운영하는 로컬 헬퍼로 정체성을 변경하면 5개 CLI 모두 합법 사용 가능. 결제·MAU·팀 기능 제거.

## 1. 배경 및 문제 정의

### 왜 만드는가?
1인 미디어·블로거가 트래픽과 수익을 늘리려면 워드프레스(구글), 네이버 블로그(네이버), 티스토리(다음+구글), 블로거(구글), 개인 블로그(SEO 자산) 같은 **이질적 플랫폼에 동시에 콘텐츠를 노출**해야 한다. 현실은 다음과 같다:

- **수동 복붙 1시간/포스트** — PostDot 가이드 기준 4개 플랫폼 1건 발행에 60~80분 소요
- **API 균열** — 티스토리는 2024-02, 네이버 블로그는 2020-05에 글쓰기 OpenAPI 종료. 자동화 도구 대부분이 "API 종료" 직격탄을 맞아 Selenium 의존 → 봇 차단·세션 만료에 취약
- **SEO 패널티 리스크** — Substack/LinkedIn처럼 canonical을 지원하지 않는 플랫폼에 동일 본문을 그대로 올리면 고권위 도메인이 원본을 추월. 대부분의 한국 자동 포스팅 도구는 canonical/시차 발행을 무시
- **통계·댓글이 분산** — 4개 플랫폼을 매일 4번 로그인해서 확인. 1인 운영자는 댓글 응대를 놓치면서 충성 독자를 잃는다
- **품질 유지 자동화 부재** — AI로 글을 대량 생성해도 AdSense 심사 기준(AI 냄새, 중복 콘텐츠, 이미지 품질, SEO 최소 요건)을 수작업으로 검증해야 함. 발행 후 깨진 이미지·콘솔 에러·LCP 초과를 사람이 직접 확인해야 하는 구조

### 시장 기회 (왜 지금인가)
- AI 콘텐츠 생성기(blog-auto, ChatGPT, Gemini)가 글 생산을 10배로 늘렸지만, **발행·운영 병목**이 그대로 → 자동화 SaaS 수요 폭증
- 기존 한국 도구는 일회성 패키지(GPT 포스트 팩토리 1.3M원) 또는 데스크톱 EXE(티워포스팅) 형태가 다수 → 클라우드 SaaS, 모바일 대시보드, 협업 기능이 약함
- 글로벌 도구(Buffer, Hootsuite)는 한국 플랫폼(네이버/티스토리/카카오) 미지원

### 해결하려는 핵심 문제 (1문장)
> **1인 블로거가 10분 안에 5개 이질적 블로그 플랫폼에 SEO를 보호하면서 AdSense 품질 기준을 충족하는 글을 생성·검증·발행하고, 한 화면에서 통계·댓글을 운영할 수 있게 한다.**

---

## 2. 사용자 페인포인트 심층 분석

> 출처: PostDot 가이드, AI자동화공장장 블로그, 티워포스팅 후기, ProBlogger·SEJ·MightyMinnow SEO 분석, 네이버/티스토리 공식 종료 공지

| # | 페인포인트 | 빈도 | 현재 대안 | 대안의 한계 |
|---|-----------|------|----------|-----------|
| P1 | 4대 플랫폼 수동 복붙 1시간 소요 | 매우 높음 (매일) | 직접 복붙, IFTTT/Zapier RSS 동기화 | RSS는 본문 일부만, 이미지·태그 깨짐 |
| P2 | 티스토리/네이버 자동화 봇 차단 | 높음 | Selenium 스크립트 | 캡차·세션 만료·IP 차단 빈발, 스크립트 유지보수 지옥 |
| P3 | 동일 본문 발행 → SEO 카니발라이제이션 | 높음 | "그냥 감수" | 권위 높은 플랫폼이 원본 추월, 트래픽 손실 |
| P4 | 플랫폼별 에디터 포맷 차이 (HTML vs SmartEditor) | 매우 높음 | 수동 변환 | 이미지 size, 표, 코드블록이 매번 깨짐 |
| P5 | 통계가 4곳에 분산 | 매일 | 각 사이트 수동 로그인 | 트렌드 한눈 파악 불가, 수익 분석 누락 |
| P6 | 댓글 응대 분산 → 응답 지연 | 매일 | 푸시 알림 4개 | 알림 누락, 톤 일관성 부족 |
| P7 | 발행 후 색인 요청·백링크 누락 | 매주 | 수동 Search Console | 시간 소모, 스팸 의심 |
| P8 | 일회성 패키지 가격 부담 (550K~1.3M원) | 진입 시 | 무료 RSS 도구 | 기능 부족 |
| P9 | 데스크톱 EXE만 지원 → 모바일·외부 작업 불가 | 매일 | 데스크톱만 사용 | 외출 중 포스팅 불가, 협업 불가 |
| **P10** | **AI 생성 콘텐츠 품질 수작업 검증** | **매일** | **수동 육안 확인** | **AdSense 심사 실패 리스크, AI 냄새 감지 불가, 발행 후 렌더링 오류 미감지** |

---

## 3. 경쟁사 벤치마킹

> 출처: 2025-12 ~ 2026-04 웹 리서치. 가격은 공식 페이지 표기 기준.

| 경쟁사 | 핵심 기능 | 강점 | 약점 | 가격 | 형태 |
|--------|----------|------|------|------|------|
| **PostDot** (postdot.kr) | 4대 플랫폼 AI 자동발행, 이미지 자동, SEO 최적화 | 한국 4대 플랫폼 모두 지원, 클라우드 SaaS | 무료 티어 없음, canonical 미언급, 댓글 통합 없음 | ₩55,000/월~ | SaaS |
| **GPT 포스트 팩토리** | 워드프레스/티스토리/N블로그 동시 발행, GPT-4·Gemini 글 생성 | 한국 SEO 프롬프트, 백링크 자동 | 일회성 거액 결제, 데스크톱, 업데이트 불투명 | ₩550K~1.3M (1회) | 데스크톱 |
| **티워포스팅** (tiwoposting.com) | 티스토리·워드프레스 RSS/주제 기반 발행, 텔레그램 알림 | 애드센스 승인 사례, 안정성 강조 | 네이버·블로거 미지원, 데스크톱 EXE, 기기 제한 | 6개월 ₩? / 3년 ₩? (티어형) | 데스크톱 |
| **빠글AI** | 한 글 → 다중 블로그 자동 포스팅, SEO 최적화 | 네이버 중심 강함, 애드센스 연동 | 글로벌 플랫폼 약함, UX 정보 부족 | 미공개 | SaaS |
| **AI자동화공장장 리포스트** | 워드프레스 → 네이버/다음/브런치/인스타 리포스트, 백링크 자동 | 워드프레스 원본 보호 모델 (SEO 친화) | 워드프레스 출발 강제, 양방향 X | 미공개 | 데스크톱 |
| **Buffer / Hootsuite** | 글로벌 소셜 + 일부 블로그 발행 | UI 성숙, 협업 강력 | 네이버/티스토리/카카오 미지원, 블로그는 부가 기능 | $6~$99/월 | SaaS |
| **BlogBowl** | 다국적 블로그 SaaS, 멀티 블로그 호스팅 + 자동화 | SEO·내부링크 자동 | 한국 플랫폼 미지원, 영문 UI | 미공개 | SaaS |
| **CrossXPost** | "한 클릭 다중 플랫폼 공유" 마이크로 SaaS | 단순함 | 영문 SNS 위주, 한국 블로그 미지원 | 저가 SaaS | SaaS |
| **ContentAtScale** | AI 글 생성 + AI 감지 우회, SEO 최적화 | AI 냄새 자체 감지·수정 내장 | 한국어 지원 미흡, 발행 연동 없음 | $250/월~ | SaaS |
| **Byword AI** | 배치 AI 글 생성 + 기본 WordPress 발행 | 저비용 배치 생성 | Trustpilot 2.8/5, 품질 편차 극심, 품질 게이트 없음 | $99~299/월 | SaaS |
| **SurferSEO** | SEO 콘텐츠 에디터, SERP 기반 키워드 밀도 | 실시간 SEO 점수, 경쟁사 분석 | 글 생성·발행 미지원, 고가 | $89/월~ | SaaS |
| **RankFlow** | WordPress 자동발행 + Schema 마크업 | 캐니발라이제이션 사전 차단 (유일) | WordPress 전용, UK 편향, 다국어 약함 | £29/월 | SaaS |
| **MarketMuse** | 주제 모델링 + 콘텐츠 품질 점수 | 주제 권위도 분석, 콘텐츠 갭 발견 | 자동 발행·품질 루프 없음, 고가 | $149/월~ | SaaS |

### 우리의 차별화 포인트
1. **SEO 보호 최우선** — canonical URL 자동 삽입 + 시차 발행(Tier 1 사이트 발행 후 N시간 뒤 Tier 2/3) + 발췌형 옵션. 경쟁사 거의 전무
2. **Playwright 안정화 풀** — Selenium 대신 stealth + 사용자별 persistent context + 자동 캡차 회피 워크플로우. 봇 차단 발생률 < 5% 목표
3. **클라우드 SaaS + 모바일 PWA** — 데스크톱 EXE 경쟁사 대비 어디서나 발행/모니터링
4. **통합 인박스** — 4대 플랫폼 댓글을 한 화면에서 받고 AI 추천 답변, 톤 일관성 유지
5. **무료 티어 (Freemium)** — 월 10건 무료. 유료 ₩19,900~₩49,900/월 (PostDot의 1/3 가격)
6. **blog-auto 파이프라인 직결** — 글 생성부터 발행까지 단일 워크플로우 (외부 도구는 분리됨)
7. **Firebase 풀스택** — Hosting + Firestore + Functions + Auth로 운영 비용 최소화
8. **⭐ BYOC v3 — 개인용 5-CLI Subprocess Spawn 라우터** (2026-04-07 SaaS→개인용 도구 피벗). 본인 PC에 설치된 **공식 vendor CLI 5종을 subprocess로 spawn**. OAuth 토큰은 헬퍼가 절대 만지지 않고 vendor CLI가 자체 처리. **V1부터 5개 어댑터 모두 활성화**: Claude Code(`claude -p`) + Codex CLI(`codex exec`) + Gemini CLI(`gemini -p`) + opencode CLI(`opencode run`) + 사용자 직접 API 키(fallback). **개인용 도구 정체성**으로 vendor의 "personal use and local experimentation" 허용 범위에 부합. 모델당 N개 계정 등록 → 라운드로빈 → 다음 모델 fallback (JamesClaw Tavily 6키 패턴). 본인 사용·본인 PC·ordinary use 빈도 준수. 경쟁사 전무 — 시장 최초
9. **⭐ 품질 파이프라인 내장 (v3.0 신규)** — ContentAtScale·SurferSEO·MarketMuse가 각각 담당하는 AI 냄새 감지 / SEO 최적화 / 콘텐츠 품질을 단일 파이프라인으로 통합. 실패 시 3회 자동 수정(모델 로테이션) + 텔레그램 에스컬레이션. 경쟁사 전무
10. **⭐ 발행 후 라이브 검증 — 시장 유일**: 경쟁사 전체가 발행 후 HTTP 확인·렌더링 검증·이미지 로드 확인 미제공. 우리는 expect 7단계 패턴으로 발행 즉시 자동 검증
11. **캐니발라이제이션 사전 차단**: 기존 URL과 코사인 유사도 0.85 이상이면 발행 차단 (RankFlow 외 경쟁사 없음)

---

## 4. 타겟 사용자

| 항목 | 내용 |
|------|------|
| **Primary** | **대표님 본인** — blog-auto 워크스페이스를 운영하는 1인. 워드프레스/네이버/티스토리/블로거/개인 블로그 다채널 운영 |
| **Secondary** | 친구·지인 블로거에게 셋업 가이드 공유 (옵션, 결제·서비스 운영 없음) |
| 사용 상황 | blog-auto가 글 생성 후 본인 PC에서 품질 검증·발행, 매일 아침 본인 노트북·모바일 PWA에서 통계 체크. **대표님은 텔레그램으로 결과만 받고 문제 있을 때만 개입** |
| 기존 대안 | blog-auto 출력 수동 복붙, ChatGPT 복붙 |
| 핵심 동기 | (1) blog-auto 파이프라인의 마지막 마일 자동화 (2) 본인이 보유한 모든 AI CLI 구독을 100% 활용 (3) 네이버/티스토리 시간 낭비 제거 (4) AdSense 심사 통과 품질 자동 보장 |
| 페르소나 | "JamesClaw 운영자(대표님): blog-auto·MultiBlog를 본인 PC에서 운영. 워드프레스+네이버+티스토리+블로거 동시 발행. Claude Max + ChatGPT Plus + Google AI Pro 구독 보유. 출퇴근 지하철에서 모바일 PWA로 통계 확인 원함. 품질 이슈는 텔레그램 알림으로만 받고 개입" |

---

## 5. Job Stories (JTBD)

1. **When** 새 글을 다 썼을 때, **I want to** 5개 플랫폼에 한 번에 발행하면서 SEO 패널티 없이 시차 발행되도록 하고 싶다, **so I can** 트래픽 분산 + 카니발라이제이션 회피
2. **When** 출근 지하철에서 시간이 날 때, **I want to** 모바일에서 어제 발행한 4개 플랫폼 트래픽·수익을 한 화면에서 보고 싶다, **so I can** 어떤 글이 잘 됐는지 즉시 판단
3. **When** 새 댓글이 달렸을 때, **I want to** 4개 플랫폼 댓글을 통합 인박스에서 받고 AI 추천 답변으로 빠르게 응대하고 싶다, **so I can** 충성 독자를 놓치지 않음
4. **When** blog-auto가 새 글 50건을 일괄 생성했을 때, **I want to** 일주일치를 자동으로 시간차 예약 발행하고 싶다, **so I can** 매일 손대지 않고 발행 빈도 유지
5. **When** 네이버/티스토리 봇 차단이 발생했을 때, **I want to** 자동으로 재시도되거나 원인 알림을 받고 싶다, **so I can** 끊김 없이 운영
6. **When** blog-auto가 10건의 글을 생성했을 때, **I want to** 각 글이 발행 전 AI 냄새·SEO 점수·이미지 품질 기준을 자동으로 통과하게 하고 싶다, **so I can** 수동 검토 없이 AdSense 승인 품질을 유지할 수 있다
7. **When** 품질 게이트가 실패했을 때, **I want to** 시스템이 서로 다른 AI 모델로 최대 3회 자동 수정을 시도하고 여전히 실패할 때만 내 텔레그램으로 에스컬레이션되게 하고 싶다, **so I can** 해결 가능한 문제에 방해받지 않을 수 있다
8. **When** 글이 플랫폼에 발행되었을 때, **I want to** 스크린샷·콘솔 오류·깨진 링크 확인이 자동으로 실행되고 싶다, **so I can** 실제 독자가 보기 전에 렌더링 문제를 잡을 수 있다

---

## 6. 기능 목록 (V1 = 8개)

| # | 기능명 | 우선순위 | Job Story | V1/V2 | Acceptance Criteria |
|---|--------|---------|-----------|-------|-------------------|
| **F1** | 멀티 플랫폼 통합 발행 엔진 | P0 | JS#1 | V1 | WordPress REST + Blogger API v3 (OAuth) + 네이버/티스토리 Playwright. 1건 글 → 5개 플랫폼 발행 성공률 ≥ 95%. 이미지·태그·카테고리 보존 |
| **F2** | 예약 발행 + SEO 시차 발행 | P0 | JS#1, JS#4 | V1 | Tier 정의 (1=원본 사이트, 2=2시간 뒤, 3=24시간 뒤). canonical URL 자동 삽입(가능 플랫폼). 50건 일괄 큐 등록 가능 |
| **F3** | 통합 대시보드 (발행 + 통계) | P0 | JS#2 | V1 | 발행 상태 표 (성공/실패/예약), 플랫폼별 일일 PV·UV (Google Analytics + 네이버 애널리틱스 + 티스토리 통계 스크래핑), 모바일 PWA |
| **F4** | 콘텐츠 에디터 + blog-auto 연동 | P0 | JS#4 | V1 | 마크다운 작성 → 플랫폼별 자동 변환 (네이버 SmartEditor JSON, 티스토리 HTML, 워드프레스 Gutenberg). blog-auto 출력물 직접 import |
| **F5** | 계정/플랫폼 연동 관리 | P0 | (전체) | V1 | **사용자 로그인**: Firebase Auth Google/GitHub/Kakao OAuth. **플랫폼 OAuth**: Google(Blogger), WordPress.com REST OAuth. **자격증명**: 네이버/티스토리는 ID/PW를 KMS 암호화 후 Firestore 저장. 다중 계정 지원 |
| **F6** | 콘텐츠 생성 파이프라인 | P0 | JS#6 | **V1** | 키워드 1개 입력 → 2,000자 이상 초안 글 생성 완료율 ≥ 95%. 생성된 글의 팩트 오류 ≤ 1건/글. 이미지 중복율 0%(같은 블로그 내). 초안 → 품질 게이트 전달까지 5분 이내 |
| **F7** | 품질 게이트 시스템 (7단계 검증) | P0 | JS#6, JS#8 | **V1** | 발행 전 7개 검증 항목 자동 통과: (1) HTTP 200 (2) 스크린샷 정상 렌더링 (3) 네트워크 에러 0 (4) 콘솔 에러 0 (5) LCP < 2.5s, CLS < 0.1 (6) 접근성 위반 critical 0 (7) AI 냄새 점수 < 30%. 전체 게이트 통과율 ≥ 80% (1차 시도 기준) |
| **F8** | 자동 수정 + 에스컬레이션 루프 | P0 | JS#7 | **V1** | 품질 게이트 실패 글의 자동 수정 성공률 ≥ 70% (3회 이내). 3회 실패 시 텔레그램 알림 도달까지 30초 이내. 에스컬레이션 메시지에 실패 원인·시도 내역·필요 판단 포함. 수정 후 재검증 시 새로운 품질 항목 regression 0건 |
| F9 | 통합 댓글 인박스 + AI 답변 | P1 | JS#3 | **V2** | 4대 플랫폼 댓글 폴링, AI 추천 답변, 톤 학습 |
| F10 | 봇 차단 자동 복구 | P1 | JS#5 | **V2** | 차단 감지 → 백오프 → IP 로테이션 → 알림 |
| F11 | 협업·팀 기능 | P2 | — | V2 | 여러 사용자, 권한, 승인 워크플로우 |
| F12 | A/B 제목 테스트 | P2 | — | V2 | 같은 글 제목 변형 발행 후 CTR 비교 |

⚠️ V1 F1~F8 (8개). F9~F12는 V2 백로그.

---

## 7. 유저 플로우

### 시나리오 1: 새 글 → 5개 플랫폼 동시 발행 (핵심)
```
[로그인] → [에디터] → [마크다운 작성/blog-auto import]
   → [발행 대상 선택: WP/Blogger/네이버/티스토리/개인]
   → [SEO 시차 옵션: 즉시 / 2시간 / 24시간]
   → [발행 버튼]
   → [실시간 진행바: WP ✅ → Blogger ✅ → 네이버 ⏳ → 티스토리 ⏳ → 개인 ✅]
   → [완료 알림 + 각 플랫폼 URL 리스트]
```
- 사용자가 보는 것: 진행바, 실패 시 즉시 재시도 버튼, canonical 자동 삽입 표시
- 사용자가 느끼는 것: "10분이면 끝난다" → 신뢰

### 시나리오 2: 모바일 통계 확인
```
[모바일 PWA 홈] → [어제 발행한 글 카드] → [플랫폼별 PV/수익 미니 차트]
   → [탭하면 상세] → [Best 글 1~3위 / Worst 글 알림]
```

### 시나리오 3: 50건 일괄 예약 (blog-auto 연동)
```
[blog-auto 출력 폴더 import] → [50건 미리보기 리스트]
   → [예약 패턴 선택: "매일 오전 9시·오후 6시"]
   → [SEO 시차 자동 적용]
   → [큐 확인 화면 → 25일치 예약 완료]
```

### 시나리오 4: 콘텐츠 생성 + 품질 루프 (신규, v3.0)
```
[키워드 입력 or blog-auto 초안 import]
   → [F6: 콘텐츠 생성 파이프라인]
      ├─ Tavily/Perplexity로 SEO 키워드 리서치
      ├─ BYOC CLI 풀(Claude/Codex/Gemini)로 글 생성
      ├─ 권위 소스 대조 팩트 검증
      └─ 이미지 선택: CDN og:image 우선, 중복 체크, 주제 매칭
   → [F7: 품질 게이트 7단계 검증]
      ├─ 1단계: 페이지 로드 (HTTP 200, DOM ready)
      ├─ 2단계: 시각/인터랙션 (Playwright 스크린샷)
      ├─ 3단계: 네트워크 안정성 (404, 혼합 콘텐츠)
      ├─ 4단계: 런타임 오류 (콘솔 오류 = 0)
      ├─ 5단계: 성능 (LCP < 2.5s, CLS < 0.1)
      ├─ 6단계: 접근성 (WCAG AA)
      ├─ 7단계: 세션 종료
      ├─ 콘텐츠 검사: AI 냄새 (Antigravity+Codex 교차)
      ├─ SEO 점수: 키워드 밀도·메타·내부 링크
      ├─ 이미지: 고유성·주제 일치·포맷 확인
      └─ PITFALLS 규칙 자동 체크
   → [PASS] → [F1/F2로 발행]
      └─ [FAIL] → [F8: 자동 수정 루프]
                     ├─ 1차 수정: 모델 A로 재작성
                     ├─ 2차 수정: 모델 B로 재작성
                     ├─ 3차 수정: 모델 C로 재작성
                     ├─ 각 수정 후 F7 재실행
                     ├─ PASS → 발행 진행
                     └─ 3회 모두 FAIL → 텔레그램 에스컬레이션
                                         (실패 내용 + 시도 이력 + 필요 결정사항)
```
- 대표님이 보는 것: 텔레그램으로 "10건 중 9건 자동 발행 완료, 1건 품질 기준 미달 — 검토 필요"
- 대표님이 느끼는 것: "손 안 대도 품질이 보장된다" → 신뢰

---

## 8. 디자인 방향 (DESIGN.md 산출 필수)

- **디자인 도구 우선순위**:
  1. Stitch MCP — 메인 대시보드/에디터/발행 화면 생성
  2. linear.app, supabase.com 대시보드 벤치마킹 (운영 SaaS 톤)
- **모바일 우선**: PWA 우선 (시나리오 2), 데스크톱은 반응형
- **톤/무드**: 미니멀 + 데이터 중심 + 약간의 친근함 (1인 운영자 친화)
- **색상**:
  - Primary: 짙은 인디고 (#4F46E5) — 신뢰
  - Accent: 라임 (#84CC16) — 발행 성공 피드백
  - Surface: Slate Dark (#0F172A) 다크모드 우선
- **참조 산출물**: `DESIGN.md` 별도 작성 (PRD 승인 후)
- **이전 프로젝트 DESIGN.md 참조**: blog-auto 워크스페이스 내 기존 DESIGN.md가 있으면 토큰 상속

---

## 9. 비기능 요구사항 (NFR)

| 항목 | 기준 |
|------|------|
| 로딩 속도 | 대시보드 초기 LCP < 2.0s, 발행 API 응답 < 3s (API 플랫폼) |
| 동시 접속 | V1 1,000 MAU, V2 10,000 MAU |
| 발행 성공률 | API 플랫폼 ≥ 99%, Playwright 플랫폼 ≥ 95% |
| 봇 차단율 | 네이버/티스토리 차단 < 5%/월 (사용자별) |
| 접근성 | WCAG 2.1 AA, 키보드 네비게이션 |
| 보안 | OAuth 2.0, Firestore Security Rules, 자격증명 KMS 암호화, GDPR/PIPA 준수 |
| 국제화 | V1 한국어 only, V2 영어 추가 |
| 가용성 | Firebase SLA 99.95%, 발행 작업은 멱등 (재시도 안전) |
| **LLM 호출 비용** | **BYOC v3 — 개인용 5-CLI Subprocess Spawn**. 헬퍼는 vendor 공식 CLI 바이너리를 spawn하고 stdin/stdout만 통신. OAuth 토큰은 헬퍼가 절대 만지지 않음. **개인용 도구 정체성**으로 vendor "personal use" 허용 범위 |
| **V1 어댑터 (5개 모두 활성)** | (1) Claude Code `claude -p` (2) Codex CLI `codex exec` (3) Gemini CLI `gemini -p` (4) opencode CLI `opencode run` (5) 사용자 직접 API 키 fallback |
| **V2 어댑터 후보** | Antigravity CLI, Cursor CLI, Aider, Continue.dev, Cody CLI, OpenRouter |
| LLM 적용 영역 | 글 변환·요약·canonical 메타 생성·태그 추천·SEO 키워드 추출·이미지 alt 생성·댓글 답변 추천(V2). 작업별 모델 선호도 설정 가능 (예: 글 변환=Claude, 요약=Gemini, SEO=Codex) |
| **다중 계정 로테이션** | 한 LLM 모델당 N개 계정(무료/유료 혼합) 등록 가능. 호출 시 라운드로빈 또는 LRU 분산. 한 계정 rate limit·할당 소진 → 같은 모델의 다음 계정으로 자동 전환. JamesClaw Tavily 6키 로테이션 패턴 차용 |
| **계층적 Fallback 체인** | 사용자가 모델 우선순위 체인 정의 (예: `Claude Code(계정1→2→3) → Codex(계정1→2) → Gemini(계정1→2→3→4) → opencode(계정1) → 사용자 API 키`). 한 계층 모든 계정 소진 시 다음 계층으로 자동 전환. 체인 끝까지 실패 시 사용자 알림 + 작업 큐 보류 |
| 라우팅 전략 | (1) 사용자 수동 선택, (2) 작업 유형별 자동 (글변환=Claude, SEO=Codex, 요약=Gemini), (3) 비용·속도 우선 분산, (4) 다중 계정 라운드로빈, (5) Rate limit·만료 시 계층적 fallback |
| 토큰 보관 | **SaaS 서버에 토큰 저장 절대 금지**. 사용자 로컬 헬퍼(C 하이브리드: 데스크톱 헬퍼 + PWA Service Worker + IndexedDB)에서만 보관·호출. 헬퍼가 Firestore 작업 큐를 폴링해 모바일 트리거도 처리 |
| 사용량 추적 | 계정별 호출 수·토큰 수·rate limit 잔량을 로컬 헬퍼가 추적. UI에서 "오늘 사용량 / 다음 리셋 시각" 표시. 무료 계정 효율 최대화 |
| **품질 게이트 SLA** | 7단계 검증 전체 완료 < 60초/건. 자동 수정 루프(3회) 전체 < 10분/건. 에스컬레이션 텔레그램 발송 지연 < 30초 |
| **모델 로테이션 원칙** | 자동 수정 루프에서 같은 모델을 연속 사용 금지 (동일 오류 반복 방지). 수정 1차·2차·3차 각각 다른 CLI 어댑터 배정. 실패 패턴이 같으면 즉시 다음 모델로 전환 |
| **품질 기준 설정** | AI 냄새 점수 임계값, SEO 키워드 밀도 최솟값, 이미지 고유성 해시 비교 기준을 Firestore에 저장. 대표님이 UI에서 조정 가능 |
| **콘텐츠 최소 품질** | 본문 800자(단어) 이상, AI 원본성 70%+, 내부링크 2개+, 이미지 alt 전수 |
| **캐니발라이제이션 방지** | 기존 발행 URL과 코사인 유사도 < 0.85 시에만 발행 허용 |

---

## 10. 성공 지표 (KPI)

**개인용 도구 KPI (SaaS 지표 제거)**

| 지표 | 목표 | 측정 |
|------|------|------|
| 평균 발행 시간 | < 10분 (수동 60분 → 90% 단축) | 발행 클릭~완료 timestamp 자체 로깅 |
| 발행 성공률 | API 99%, Playwright 95% | task_log 집계 |
| LLM 비용 | ₩0/월 (BYOC 100% 활용) | API 키 사용량 0 확인 |
| blog-auto 통합 | 50건 일괄 import 30초 이내 | 수동 측정 |
| 모바일 PWA 사용 | 주 3회 이상 본인 사용 | 자체 |
| 안정성 | 봇 차단 < 5%/월 | 헬퍼 로그 |
| **AI 냄새 통과율** | **≥ 90% (초안 1차 제출 기준)** | **F7 품질 게이트 로그** |
| **자동 수정 성공률** | **≥ 80% (3회 이내 자동 수정으로 통과)** | **F8 수정 루프 로그** |
| **에스컬레이션율** | **≤ 5% (전체 생성 글 대비 사람 개입 필요)** | **텔레그램 에스컬레이션 건수 / 전체 글 수** |
| **발행 후 품질 오류율** | **≤ 1% (콘솔 오류·깨진 링크·LCP 초과 발견)** | **F7 post-deploy 검증 로그** |

---

## 11. 리스크 및 오픈 질문

### 알려진 리스크
| # | 리스크 | 확률 | 영향 | 완화 전략 |
|---|--------|------|------|----------|
| R1 | 네이버/티스토리 약관 위반·봇 차단 → 사용자 계정 정지 | 높음 | 매우 높음 | 사용자 계정으로 사용자 IP에서 실행, 발행 빈도 제한, 약관 고지·동의, 휴먼 패턴 시뮬레이션 |
| R2 | 카카오/네이버 추가 차단 강화 | 중간 | 높음 | 멀티 자동화 전략 (Playwright + 모바일 앱 자동화 백업), 수동 발행 fallback |
| R3 | API 변경 (워드프레스 5.x → 6.x) | 낮음 | 중간 | 어댑터 패턴, 통합테스트 매주 |
| R4 | 중복 콘텐츠 SEO 패널티 | 중간 | 높음 | canonical 자동, 시차 발행, 발췌 모드 옵션 |
| R5 | OAuth 토큰 유출 | 낮음 | 매우 높음 | KMS 암호화, Firestore Rules, 토큰 회전 |
| R6 | 경쟁사 PostDot 가격 인하 | 중간 | 중간 | 무료 티어 + blog-auto 직결로 락인 |
| R7 | **확정 리스크** — Anthropic Claude(2026-02-19 명시 금지·서버 차단·계정 ban 사례), Google Gemini(명시 금지) 약관이 third-party OAuth 재사용을 금지 | **확정** | 높음 | V1 GA에서 Claude/Gemini 어댑터 제외(V1.1 옵트인), CLI subprocess spawn 모델로 토큰 미접촉, "사용자 본인의 로컬 헬퍼" 포지셔닝, 약관 변경 주간 모니터링, API 키 fallback 상시 |
| R8 | CLI 토큰 만료/회전·CLI 업데이트로 인터페이스 깨짐 | 높음 | 중간 | 멀티 CLI 라우팅 자동 fallback, 어댑터 버전 핀, 만료 사전 감지, 발행 큐는 LLM 호출과 분리 |
| R9 | CLI별 응답 품질·포맷 차이 | 중간 | 중간 | 작업별 모델 선호도 + 출력 정규화 레이어 + 결과 비교 |
| R10 | **CLI bridge도 vendor가 트래픽 패턴(빈도·시그니처)으로 차단 가능** | 중간 | 높음 | 자동화 빈도를 ordinary use 가정에 맞춰 제한(발행 1건당 LLM 호출 N회 cap, 일일 cap, 휴먼 패턴 시뮬), 동시 다중 계정 사용 시 사용자에게 위험 고지+본인 책임, 문제 발생 시 즉시 해당 어댑터 비활성화 |
| **R11** | **품질 게이트 오탐(False Positive) — 정상 글이 반복 실패** | 중간 | 중간 | 품질 임계값 UI 조정 가능. 3회 자동 수정 후 에스컬레이션 → 대표님이 임계값 재조정. 오탐 패턴은 PITFALLS 기록 후 임계값 자동 권고 |
| **R12** | **자동 수정 무한 루프 — 3회 수정 모두 실패 시 에스컬레이션 미발송** | 낮음 | 높음 | F8 루프에 타임아웃(10분) 강제. 타임아웃 또는 3회 초과 즉시 텔레그램 에스컬레이션. 에스컬레이션 발송 여부 Firestore에 상태 기록 후 확인 |

### 확정 결정 사항 (2026-04-07, 최종 v2.0)
- ✅ **개인용 데스크톱 도구** (옵션 (C) 채택) — SaaS·결제·MAU·팀 기능 전부 제거
- ✅ **로컬 헬퍼 = C 하이브리드** (Tauri 데스크톱 + PWA Service Worker, Firestore 큐 폴링)
- ✅ **Firebase = single-tenant** (대표님 본인 GCP 프로젝트). 모바일 PWA 동기화·통계 백업 용도
- ✅ **결제·구독 모델 제거** (개인용 도구라 불필요)
- ✅ **BYOC v3 — 5개 CLI 모두 V1부터 활성화** (Claude Code + Codex + Gemini + opencode + API 키 fallback). 개인용 도구라 vendor "personal use" 허용 범위에 부합
- ✅ **다중 계정 로테이션 + 계층적 fallback 체인** 유지
- ✅ **포지셔닝**: "blog-auto 워크스페이스의 멀티 블로그 발행 모듈, 개인용 로컬 자동화 헬퍼"
- ✅ **PoC 2 완료**: Playwright는 사용자 본인 Chrome CDP attach 모델 채택 (1차) + 반자동 폼 채우기 fallback (2차). playwright-stealth 단독은 네이버 우회 불가 (Cloudflare AI Labyrinth)
- ✅ **PoC 3 완료**: Tauri v2 sidecar 패턴 검증 — Rust helper-daemon + Node.js Playwright sub-sidecar + Firestore REST 폴링. tokio::process::Command로 CLI 어댑터 5종 호출
- ✅ **T2 진행 중**: Stitch MCP 프로젝트 생성됨 (ID `14652388482304775067`), 디자인 시스템 생성 중 (Indigo+Lime+Slate Dark, Inter, ROUND_TWELVE)

### 남은 오픈 질문 (구현 중 해결)
- [ ] 네이버 자동화 약관 검토 (법무 자문)
- [ ] 가격 모델 적정성: 무료 10건/월 + Pro ₩19,900 + Business ₩49,900
- [ ] 네이버/티스토리 통계 수집: 스크래핑 vs 수동 입력
- [ ] **각 CLI ToS 개별 검토** — Claude Code, Codex, Gemini CLI, Antigravity, opencode. 한 CLI 금지 시 해당 어댑터만 비활성화하고 나머지로 운영
- [ ] **각 CLI 호출 인터페이스 매핑** — stdin/stdout vs 공식 SDK vs 로컬 HTTP 모드. T1 직전 1주 PoC 필요
- [ ] **품질 게이트 임계값 초기값 결정** — AI 냄새 점수 기준, SEO 키워드 밀도 최솟값, 이미지 유사도 해시 임계값. PoC 5에서 10건 샘플로 보정 예정
- [ ] **Antigravity CLI 안정성** — `opencode serve` 불안정 이슈 재확인. AI 냄새 감지 패스에서 Codex만으로 충분한지 검토

---

## 12. 롤아웃 전략

**개인용 도구 단계 (SaaS 롤아웃 제거)**

| 단계 | 내용 | 통과 기준 |
|------|------|----------|
| Phase 0 (PoC) | PoC 1~5 검증 | CLI 5종 spawn 동작, Playwright 안정, Tauri 헬퍼 동작, 품질 게이트 10건 샘플 통과율 측정 |
| Phase 1 (개인 알파) | 대표님 본인이 매일 발행에 사용 | 1주간 매일 사용, 크리티컬 버그 0, 에스컬레이션율 < 10% |
| Phase 2 (지인 옵션) | 친구·지인에게 셋업 가이드 공유 (자가 설치) | 셋업 README + Tauri 빌드 배포 |
| Phase 3 (공개 옵션) | 오픈소스 GitHub 공개 (옵션) | 라이선스 결정, 약관 고지 README |

---

## 13. Out of Scope + 태스크 분해

### Out of Scope (V1에서 안 하는 것)
- ❌ 통합 댓글 인박스 (V2, F9로 이동)
- ❌ 봇 차단 자동 복구 (V2, F10으로 이동)
- ❌ A/B 제목 테스트 (V2, F12로 이동)
- ❌ 협업·팀 기능 (V2, F11로 이동)
- ❌ 인스타그램·페이스북·X 발행 (소셜은 별도 도구)
- ❌ 카페·DC인사이드 발행 (V2)
- ❌ 영어 UI (V2)
- ❌ 자체 호스팅 옵션
- ❌ 다국어 AI 냄새 감지 (V1 한국어만, 영어는 V2)
- ❌ 품질 게이트 결과 장기 리포트 (V1은 건별 로그만, 트렌드 분석은 V2)

### 태스크 분해 (V1, 20개 상한)

| # | 태스크 | 의존 | 기능 |
|---|--------|------|------|
| T1 | Firebase 프로젝트 + Auth + Firestore + Hosting 셋업 | — | 인프라 |
| T2 | 디자인 시스템·DESIGN.md 작성 (Stitch) | T1 | F3, F4 |
| T3 | 사용자/계정/플랫폼 자격증명 데이터 모델 + 보안 룰 + KMS 암호화 | T1 | F5 |
| T4 | OAuth + BYOC v3 어댑터: (a) Firebase Auth(Google/GitHub/Kakao 사용자 로그인) + (b) 플랫폼 OAuth(Google-Blogger, WordPress.com) + (c) **CLI Subprocess Spawn 라우터** — V1 GA: Codex CLI + opencode + API 키 어댑터 3종, 다중 계정 로테이션 + 계층적 fallback 체인 드래그&드롭 UI, 사용량·rate limit 표시. CLI subprocess 호출은 Tauri 헬퍼에서만 (토큰 미접촉). V1.1 옵트인: Claude/Gemini 어댑터 + 위험 고지 페이지 | T3 | F5, NFR-LLM |
| T5 | 네이버/티스토리 자격증명 입력 UI + 안전 저장 | T3 | F5 |
| T6 | 마크다운 에디터 + 플랫폼별 변환 어댑터 (WP Gutenberg, 네이버 SmartEditor JSON, 티스토리 HTML, Blogger HTML) | T2 | F4 |
| T7 | blog-auto 출력 import 어댑터 (파일 시스템 워처) | T6 | F4 |
| T8 | 발행 엔진: WordPress REST + Blogger API v3 워커 (Cloud Functions) | T4 | F1 |
| T9 | **Playwright 워커 v2 (PoC 2 결과)** — 1차: Node.js sub-sidecar로 사용자 본인 Chrome을 CDP attach (`chromium.connectOverCDP`) → 본인 IP·쿠키·fingerprint → vendor 감지 회피 / 2차 fallback: 반자동 폼 채우기(헬퍼가 입력, 사용자가 발행 클릭) / 네이버 SmartEditor + 티스토리 글쓰기 페이지 어댑터 | T5 | F1 |
| T10 | 발행 큐 시스템 (Firestore + Cloud Tasks) + 시차 발행 + canonical 삽입 | T8, T9 | F2 |
| T11 | 통합 대시보드: 발행 상태 + 큐 + 재시도 (데스크톱) | T10 | F3 |
| T12 | 통계 수집 모듈: GA4 (워드프레스/블로거), 네이버 애널리틱스 스크래핑, 티스토리 통계 스크래핑 | T10 | F3 |
| T13 | 모바일 PWA 대시보드 (반응형) | T11 | F3 |
| T14 | E2E 테스트: Alpha 시나리오 5개 (단일 발행, 시차 발행, 50건 큐, 모바일 통계, 봇 차단 복구) | T11, T12, T13 | 전체 |
| T15 | **개인용 도구 패키징** — Tauri 빌드 (Windows MSI), 본인용 셋업 가이드(README), 약관·CLI ToS 위험 고지 페이지, 친구·지인 배포용 자가 설치 스크립트, 본인 Firebase 프로젝트 연결 가이드 (single-tenant) | T14 | 출시 |
| **T16** | **콘텐츠 생성 파이프라인 (F6)** — Tavily/Perplexity SEO 키워드 리서치 모듈 + BYOC CLI 글 생성 오케스트레이터 + 권위 소스 팩트 검증 워커 + 이미지 선택 엔진 (og:image CDN 우선, perceptual hash 중복 체크, 주제 매칭 스코어) | T4, T7 | F6 |
| **T17** | **품질 게이트 7단계 엔진 (F7)** — expect MCP 7단계 통합 (open/screenshot/network_requests/console_logs/performance_metrics/accessibility_audit/close) + AI 냄새 검사 모듈 (Antigravity CLI + Codex CLI 교차 검수) + SEO 점수 검사 (키워드 밀도·메타·내부 링크) + 이미지 검증 (고유성·주제·포맷) + PITFALLS 규칙 자동 체크 | T4, T16 | F7 |
| **T18** | **자동 수정 + 에스컬레이션 루프 (F8)** — 수정 루프 오케스트레이터 (최대 3회, 회차별 다른 CLI 어댑터 배정) + 수정 후 F7 재실행 트리거 + 타임아웃(10분) 강제 종료 + 텔레그램 에스컬레이션 포매터 (실패 내용·시도 이력·필요 결정사항) | T17 | F8 |
| **T19** | **품질 설정 UI** — Firestore 품질 임계값 CRUD (AI 냄새 점수·SEO 밀도·이미지 유사도). 대시보드에 품질 게이트 결과 표시 (건별 로그, 통과/실패/수정 이력). 텔레그램 에스컬레이션 알림 설정 | T11, T18 | F7, F8 |
| **T20** | **품질 파이프라인 E2E 테스트** — PoC 5: 10건 샘플로 품질 게이트 임계값 보정. 자동 수정 루프 3회 시뮬레이션. 에스컬레이션 텔레그램 발송 확인. 발행 후 post-deploy 검증 통합 테스트 | T19 | F6, F7, F8 |

⚠️ 20개 상한 도달. F9~F12는 V2 백로그.

---

## Appendix: 핵심 출처
- [PostDot 4대 플랫폼 가이드](https://postdot.kr/blog/auto-posting-complete-guide) (2026-03)
- [티스토리 Open API 종료 공지](https://tistory.github.io/document-tistory-apis/) (2024-02)
- [네이버 블로그 OpenAPI 종료 공지](https://developers.naver.com/notice/article/7527) (2020-04)
- [SEO Cross-Posting Best Practices (MightyMinnow)](https://www.mightyminnow.com/2025/12/how-to-cross-post-your-content-safely-without-hurting-your-seo/) (2025-12)
- [GPT 포스트 팩토리 가격·기능](https://thousandstarrtehre.tistory.com/607) (2025-04)
- [티워포스팅](https://tiwoposting.com) (2025-06)
- [AI자동화공장장 리포스트](https://aifactoryman.com/20/?idx=56) (2025-12)
- [ContentAtScale AI Detection](https://contentatscale.ai) (2026-04)
- [SurferSEO Content Editor](https://surferseo.com) (2026-04)
- [MarketMuse Content Intelligence](https://www.marketmuse.com) (2026-04)
- [expect MCP 7-step pattern](~/.claude/projects/D--MoneyAgent/memory/reference_expect_tools.md) (내부 문서, moneyguide.one 검증 완료)
