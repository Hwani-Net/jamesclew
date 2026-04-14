# Session 2026-04-08 — Multi Blog Phase 1 Alpha 진입

> 세션명: blog-auto (원래 blou-auto → /rename blog-auto) | 프로젝트: Multi Blog 개인용 멀티 블로그 통합 발행 도구
> 작업 디렉토리: `E:/AI_Programing/blog-auto/MultiBlog/`

## 1. 세션 목적
1인 운영자(대표님)가 blog-auto가 생성한 글을 WordPress + Blogger + 네이버 + 티스토리 + 개인 블로그 5개 플랫폼에 **한 번에 발행**하는 개인용 데스크톱 도구 구축.

## 2. 주요 산출물 (11 라운드 자율 진행)

### 2.1 기획 문서 5종 (옵시디언 동기화 완료)
- `PRD.md` **v2.0** (25.5KB) — SaaS → 개인용 도구 피벗, BYOC v3, 9 결정사항 확정
- `PLAN.md` (20.7KB) — T1~T15 구현 플랜 + 크리티컬 패스 + PoC 5~7일 사전 계획
- `DESIGN.md` (13.2KB) — 디자인 토큰 + 컴포넌트 인벤토리 + 9 화면 명세
- `research/CRITICAL_FINDING_BYOC_PIVOT.md` — Anthropic/Google 명시 금지 → 개인용 도구 피벗 결정
- `research/POC_RESULTS.md` — PoC 1~4 결과

### 2.2 Phase 0 PoC 완료 4건
| PoC | 결과 |
|-----|------|
| 1. AI CLI 호출 인터페이스 매핑 | Claude 2.1.92 / Codex 0.98.0 / Gemini 0.35.0 / opencode 1.3.0 — 5종 헤드리스 호출 작동 확인 |
| 2. Playwright 네이버/티스토리 봇 차단 회피 | 사용자 본인 Chrome CDP attach 전략 확정 (`chromium.connectOverCDP`) |
| 3. Tauri sidecar 헬퍼 | Rust helper-daemon + Node.js Playwright sub-sidecar 아키텍처 |
| 4. CLI ToS 법무 검토 | Anthropic 2026-02-19 / Google 명시 금지 → **(C) 개인용 도구 피벗** (vendor "personal use" 허용 범위) |

### 2.3 실제 인프라 (Live)
- **Firebase 프로젝트**: `multi-blog-personal` (https://console.firebase.google.com/project/multi-blog-personal/overview)
- **Firebase Web App**: `1:109289390873:web:14057650a053613a163b88` (Auth + Firestore + Storage SDK config)
- **Firebase 설정 5종**: `firebase.json`, `.firebaserc`, `firestore.rules` (deny-by-default), `firestore.indexes.json`, `storage.rules`
- **Tauri v2 데스크톱 앱**: `MultiBlog/app/`, productName "Multi Blog", identifier `kr.aicreator.multiblog`, 1280x800
- **Tauri dev 윈도우 띄우기 성공**: multi-blog.exe PID 53068 32MB, HTTP 200 localhost:3000
- **Stitch 디자인 시스템**: `projects/14652388482304775067` + `assets/7708101689804681370` (Indigo/Lime/Slate Dark/Inter/ROUND_TWELVE)

### 2.4 Rust 소스 1,383 라인 (5 파일, cargo check 통과, cargo test 5/5 통과)
| 파일 | 라인 | 책임 |
|------|------|------|
| `helper.rs` | 619 | BYOC v3 — CliAdapter trait + 4 어댑터 (Claude/Codex/Gemini/opencode) + LlmRouter 계층 fallback + FirestorePoller reqwest 실제 구현 (GET/PATCH) + classify_task + HelperError→PublishError 자동 변환 |
| `publish.rs` | 483 | T8 발행 엔진 — PublishAdapter trait + WordpressAdapter(REST + Application Password + canonical 메타) + BloggerAdapter(Google OAuth + posts.insert) + Naver/Tistory/Personal stub + **5 단위 테스트 통과** |
| `import.rs` | 234 | T7 blog-auto import — frontmatter parser + 디렉토리 워커 + SHA-256 dedup + 2 Tauri commands |
| `lib.rs` | 41 | Tauri 메인 + 모듈 등록 + 6 commands + tracing logger |
| `main.rs` | 6 | entry (`multi_blog_lib::run`) |

Cargo.toml 의존성 25개: tauri v2, tauri-plugin-shell, tokio[full], reqwest[json+rustls], serde, serde_json, serde_yaml, sha2, chrono, tracing, tracing-subscriber, async-trait, which, thiserror, anyhow

### 2.5 Next.js 16 Frontend (`app/web/`)
- **10 static pages** (next build exit 0): `/`, `/byoc`, `/editor`, `/login`, `/queue`, `/settings`, `/stats`, `/_not-found`
- **Sidebar Client Component** (`components/sidebar.tsx`) — `usePathname` + `next/link` 자동 active 감지
- **shadcn/ui 8 컴포넌트**: button/card/progress/dialog/tabs/badge/input/label (Tailwind 4 호환)
- **Firebase SDK 초기화**: `lib/firebase.ts` (Auth/Firestore/Storage)
- **Tauri invoke 통합**: BYOC `helper_validate_clis`, Settings `publish_validate_wordpress`
- **TipTap 3.22.2 설치됨** (에디터 통합은 Phase 1 남은 작업)

### 2.6 Stitch 디자인 화면 9/9 추출 (`MultiBlog/design/`, 180KB HTML)
1. `multi-blog-dashboard-main.html` (18KB)
2. `multi-blog-content-editor.html` (17.9KB)
3. `byoc-chain-editor.html` (19.5KB)
4. `statistics-dashboard.html` (22.6KB)
5. `multi-blog-mobile-home.html` (15.4KB)
6. `publish-target-modal.html` (17.6KB)
7. `settings-platforms.html` (16.2KB)
8. `blog-import-console.html` (20.8KB)
9. `multi-pass-review-results.html` (18.9KB)

**Stitch 사용 패턴 확정** (중요 노하우):
```bash
# 1. generate_screen_from_text 호출 (timeout 메시지는 무시)
# 2. 시스템이 응답을 ~/.claude/projects/.../tool-results/mcp-stitch-*.txt로 자동 저장
# 3. jq로 추출
jq -r '.outputComponents[0].design.screens[0].htmlCode.content' "$FILE" > design/screen.html
```
`list_screens`는 재시작 후에도 빈 응답 (MCP 버그). 응답 파일 jq 추출이 유일 작동법.

## 3. 하네스 신규 기능

### 3.1 자동 세션 rename hook (`post-edit-dispatcher.sh` + `user-prompt.ts`)
- PRD.md/PLAN.md 작성 감지 → 디렉토리 슬러그 자동 추출 → `~/.harness-state/session_rename_pending.txt` 저장
- 다음 user prompt 시 user-prompt.ts가 읽고 클로드에게 "/rename <slug> 안내" 주입
- deploy 완료, 활성화됨

### 3.2 PITFALLS P-012 신규 기록
**declare_no_execute 패턴 반복** — "진행합니다" 선언 후 응답 종료 패턴. 응답 종료 전 "방금 선언한 다음 작업의 도구 호출이 이 응답 안에 있는가?" 자체 점검 룰 확립.

## 4. 핵심 결정 사항 (2026-04-08 확정)
1. ✅ **개인용 데스크톱 도구** (옵션 C, SaaS 피벗 철회)
2. ✅ **로컬 헬퍼 = C 하이브리드** (Tauri + PWA Service Worker, Firestore 큐 폴링)
3. ✅ **Firebase single-tenant** (본인 GCP 프로젝트)
4. ✅ **결제·MAU·팀 기능 제거**
5. ✅ **BYOC v3 — 5개 CLI 모두 V1 활성** (Claude/Codex/Gemini/opencode/API 키)
6. ✅ **다중 계정 로테이션 + 계층적 fallback 체인**
7. ✅ **사용자 본인 Chrome CDP attach** (Playwright 전략)
8. ✅ **Tauri sidecar 아키텍처** (Rust + Node.js sub-sidecar)
9. ✅ **Next.js 16 + React 19 + Tailwind 4 + shadcn/ui**

## 5. Phase 진척률

| Phase | 상태 | 완성도 |
|-------|------|------|
| **Phase 0 PoC** | ✅ 4/4 PoC 완료 + 인프라 골격 | **100%** |
| **Phase 1 알파** (본인 매일 사용) | 🟡 UI 보이지만 실제 발행 0 | **약 20%** |
| **Phase 2 지인 옵션** | ⏳ | 0% |
| **Phase 3 오픈소스 옵션** | ⏳ | 0% |

### 5.1 T1~T15 진척
- T1 Firebase 셋업: 30% (프로젝트+config ✅, Auth/Emulator ❌)
- T2 디자인: 100% ✅
- T3 데이터 모델/KMS: 0%
- T4 OAuth/BYOC UI: 25% (일부 Client Component + invoke)
- T5 네이버/티스토리 자격증명 UI: 0%
- T6 마크다운 에디터: 10% (textarea mock)
- T7 import: 40% (파서 ✅, Storage upload ❌)
- T8 발행 엔진: 50% (WP/Blogger 코드 + 5 unit test, 실제 호출 미검증)
- T9 Playwright 워커: 0%
- T10 발행 큐: 30% (FirestorePoller reqwest 실제 구현, 실제 폴링 미가동)
- T11 통합 대시보드: 25% (UI + Tauri invoke 일부)
- T12 통계 수집: 5%
- T13 모바일 PWA: 0%
- T14 E2E 테스트: 0%
- T15 Tauri 패키징: 10%

## 6. 미완료 TODO — Phase 1 알파 GA 남은 경로

### 6.1 즉시 필요 (본인 사용 시작 최소 조건)
1. **sidebar.tsx 메뉴에 /editor, /login 링크 추가**
2. **publish.rs에 `publish_post_to_wordpress` Tauri command 추가** (검증 ≠ 발행)
3. **TipTap 에디터 `/editor`에 실제 통합** (현재 textarea mock)
4. **Settings WordPress "연결 테스트" 실제 호출 검증** (Tauri webview에서)
5. **WordPress 첫 글 E2E 발행 시나리오** — 에디터→발행 버튼→invoke→WP REST POST→본인 블로그 확인

### 6.2 그 다음 필요
6. Firestore posts/publishJobs 실시간 구독 (onSnapshot)
7. Firebase Auth 로그인 후 /login 리다이렉트 처리
8. Java PATH 새 shell 활성화 → Firebase Emulator 첫 부팅
9. helper.rs `publish_dispatcher` 실제 구현 (classify_task → 실제 publish 호출)
10. Blogger Google OAuth flow 구현

### 6.3 Phase 1 완성 조건
11. 네이버 블로그 Playwright CDP attach 워커 (T9 시작)
12. 티스토리 Playwright 워커
13. 시차 발행 Cloud Tasks 큐 연결 (T10)
14. blog-auto 출력 폴더 워치 + Storage 이미지 업로드 (T7 확장)
15. 단일 플랫폼 + 멀티 플랫폼 E2E 2개 시나리오 검증

## 7. 환경 점검
- node v22.17.0, pnpm 10.14.0, cargo 1.88.0, firebase CLI 15.11.0, gcloud SDK 556.0.0
- JDK 21 winget 설치 완료 (새 shell에서 PATH 적용 필요 → Firebase Emulator 부팅 가능)
- 하네스 자동 rename hook 활성화
- Stitch MCP reconnect 후 응답 파일 jq 패턴 확립

## 8. 다음 세션 재개 방법
```bash
cd E:/AI_Programing/blog-auto/MultiBlog
cat PRD.md | head -50            # 프로젝트 context 복구
ls design/*.html                 # Stitch 화면 9종 확인
cd app && firebase use           # multi-blog-personal 확인
cd src-tauri && cargo check      # 1,383 라인 Rust 컴파일 검증
cd ../web && pnpm build          # 10 routes 검증
pnpm tauri dev                   # 윈도우 띄우기
```

## 9. 옵시디언 사본 위치
`C:/Users/AIcreator/Obsidian-Vault/02-projects/MultiBlog/`
- PRD.md, PLAN.md, DESIGN.md, POC_RESULTS.md, CRITICAL_FINDING_BYOC_PIVOT.md
- `design/` (9종 HTML 사본)
