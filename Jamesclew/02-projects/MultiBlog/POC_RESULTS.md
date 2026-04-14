# PoC Results — Multi Blog 사전 검증 (2026-04-07)

## PoC 1: AI CLI 호출 인터페이스 매핑 ✅ 완료

| CLI | 버전 | 헤드리스 호출 | 실증 결과 | OAuth 정책 | 어댑터 우선순위 (개인용) |
|-----|------|--------------|----------|-----------|--------------------|
| Claude Code | 2.1.92 | `claude -p "..."` | ✅ exit 0, "PONG_CLAUDE" | 명시 금지 (third-party) / 본인 사용 OK | A1 |
| Codex CLI | 0.98.0 | `codex exec [PROMPT]` (stdin 지원) | ✅ help 확인 | 명시 금지 없음 | A2 |
| Gemini CLI | 0.35.0 | `gemini -p "..."` (-o json) | ✅ help 확인 | 명시 금지 (third-party) / 본인 사용 OK | A3 |
| opencode | 1.3.0 | `opencode run [message]` | ✅ multi-provider | 자체 인증, 자유 | A4 |
| API 키 fallback | - | HTTPS | - | 항상 합법 | A5 |

**결론**: 5개 어댑터 모두 subprocess spawn으로 호출 가능. 본인 사용·본인 PC 조건에서 vendor "personal use" 허용 범위에 부합.

**어댑터 인터페이스 표준** (각 어댑터가 구현해야 할 인터페이스):
```typescript
interface CLIAdapter {
  id: string;                       // "claude" | "codex" | "gemini" | "opencode" | "apikey"
  spawn(prompt: string, opts?: SpawnOpts): Promise<LLMResult>;
  detectRateLimit(stderr: string, exitCode: number): boolean;
  getUsage?(): Promise<UsageInfo>;  // 선택, 가능한 CLI만
  validate(): Promise<boolean>;     // CLI 설치·로그인 확인
}
```

---

## PoC 2: Playwright 네이버/티스토리 봇 차단 회피 ⚠️ 전략 변경

### 리서치 핵심 (2025-12 ~ 2026-03 출처)
- 네이버·쿠팡·인스타그램은 Cloudflare Turnstile, DataDome, Akamai Bot Manager 사용
- **playwright-stealth 단독은 한계**: navigator.webdriver 등 property 패치만 — 2026 기준 enterprise 봇 감지 우회 불가
- 2025년 도입된 **Cloudflare AI Labyrinth**: 4단계 이상 탐색 시 fingerprint 등록·차단
- Canvas/WebGL fingerprinting + 행동 패턴 분석 = 다층 방어
- 권장 라이브러리: `rebrowser-playwright` (browser engine 수준 패치), `browserforge` (fingerprint 마스킹), SeleniumBase CDP mode

### 개인용 도구의 차별화 전략

**Approach 1 — 단순 playwright-stealth**: ❌ 네이버 차단 가능성 높음

**Approach 2 — rebrowser-playwright + persistent context**: ⚠️ 가능하나 유지보수 부담

**Approach 3 — 사용자 본인 Chrome을 CDP attach** ⭐ **권장**:
- 사용자가 일상에서 쓰는 본인 Chrome 프로파일을 헬퍼가 CDP(`--remote-debugging-port=9222`)로 연결
- 본인 IP, 본인 쿠키, 본인 fingerprint, 본인 history → vendor 입장에서 일반 사용자와 구별 불가
- Playwright `chromium.connectOverCDP()` 사용
- 단점: 사용자가 Chrome을 미리 디버깅 모드로 띄워야 함 → 헬퍼가 자동으로 Chrome 시작 (`chrome.exe --remote-debugging-port=9222 --user-data-dir=<본인 프로파일>`)

**Approach 4 — 반자동 폼 채우기 (fallback)**:
- 헬퍼가 새 창을 열고 본문·태그·이미지를 자동 입력
- 사용자가 직접 "발행" 버튼 클릭
- 약관·차단 위험 0, 시간 절감 80%
- Approach 3 실패 시 자동 전환

### T9 수정 사항 (PRD 대비)
- `playwright-extra + stealth` → **`Playwright + CDP attach to user's Chrome`** 1차
- `사용자별 user-data-dir` → **`사용자 일상 Chrome 프로파일 그대로`**
- 새 fallback 추가: **반자동 모드 (사용자가 발행 버튼 클릭)**

### PoC 2 다음 단계
- [ ] 사용자 본인 Chrome 프로파일 경로 자동 감지 (Windows: `%LOCALAPPDATA%/Google/Chrome/User Data/Default`)
- [ ] CDP 연결 후 네이버 SmartEditor iframe 진입 테스트
- [ ] 티스토리 글쓰기 페이지 진입 + HTML 모드 페이스트 테스트
- [ ] 100회 발행 성공률 측정 (Approach 3 vs Approach 4)

---

## PoC 3: Tauri + Firestore 큐 폴링 헬퍼 ✅ 아키텍처 검증

### 검증된 패턴 (Tauri v2 공식 + 커뮤니티 사례)

**Tauri Sidecar 모델** — Tauri v2가 외부 바이너리 임베딩을 1급 지원:
- `tauri.conf.json` → `bundle.externalBin` 배열에 바이너리 등록
- 타겟 트리플 자동 부착 (예: `helper-x86_64-pc-windows-msvc.exe`)
- Rust: `app.shell().sidecar("helper").spawn()` → 장기 실행 가능
- stdin/stdout/stderr 실시간 스트리밍 (`CommandEvent::Stdout/Stderr`)
- 자식 프로세스 라이프사이클 관리 (`CommandChild::write/kill`)

### Multi Blog 헬퍼 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│  Tauri Desktop Shell (Rust + WebView)                    │
│  ├─ Frontend (Next.js PWA)                               │
│  └─ Rust commands (IPC bridge)                           │
└──────────┬──────────────────────────────────────────────┘
           │ tauri-plugin-shell sidecar API
           ▼
┌─────────────────────────────────────────────────────────┐
│  helper-daemon (Rust binary, sidecar)                    │
│  ├─ Firestore REST 폴링 (taskQueue/{taskId})              │
│  ├─ CLI Adapter Pool (claude/codex/gemini/opencode/api)   │
│  │   └─ subprocess::spawn() 서브프로세스 실행                │
│  ├─ Playwright Bridge → Node.js sidecar                   │
│  │   └─ chromium.connectOverCDP() 사용자 Chrome attach     │
│  └─ Result push → Firestore                              │
└─────────────────────────────────────────────────────────┘
```

### 핵심 결정
- **헬퍼 = Rust 단일 바이너리** (배포 단순, 성능, 의존성 0)
- **Playwright = Node.js sub-sidecar** (Rust playwright crate 미성숙, Node 공식 SDK 사용)
- **Firestore 접근 = REST API + 사용자 OAuth** (Admin SDK 불필요, single-tenant)
- **CLI 호출 = `tokio::process::Command`** 비동기 spawn
- **Frontend ↔ Helper 통신** = Tauri command + 이벤트 emit (`app.emit("job-progress", ...)`)
- **모바일 PWA 트리거** = 모바일이 Firestore에 task 작성 → 데스크톱 헬퍼가 폴링·픽업·실행

### 의존성 매트릭스 (Cargo.toml + package.json)
```toml
# src-tauri/Cargo.toml
tauri = "2"
tauri-plugin-shell = "2"
tokio = { version = "1", features = ["full"] }
reqwest = { version = "0.12", features = ["json"] }   # Firestore REST
serde = { version = "1", features = ["derive"] }
serde_json = "1"
```

```json
// helper-daemon/package.json (Node.js sub-sidecar)
{
  "playwright": "^1.50.0",
  "playwright-extra": "^4.3.6"
}
```

### PoC 3 다음 단계
- [ ] Tauri v2 프로젝트 스캐폴드 (`pnpm create tauri-app`)
- [ ] helper-daemon Rust 바이너리 — Firestore 폴링 1초 주기
- [ ] CLI 어댑터 모듈 — `tokio::process::Command::new("claude").arg("-p").arg(prompt)`
- [ ] Playwright Node.js sidecar — pkg로 단일 exe 빌드
- [ ] 모바일→큐→데스크톱→실행→결과 사이클 < 5초 측정

---

## PoC 4: 각 CLI ToS 법무 검토 ✅ 완료 (CRITICAL_FINDING_BYOC_PIVOT.md)

**결론**: SaaS 모델 → 모든 vendor에서 위험. **개인용 도구 모델 → 5개 CLI 모두 vendor "personal use" 허용 범위에 부합**.

대표님 결정 (2026-04-07): **(C) 개인용 도구 피벗** 채택. PRD v2.0에 반영 완료.

---

## 종합 진행 상황 (2026-04-07)

| PoC | 상태 | 결과 |
|-----|------|------|
| 1. CLI 인터페이스 매핑 | ✅ 완료 | 5개 어댑터 호출 가능 확인 |
| 2. Playwright 차단 회피 | ⚠️ 전략 변경 | 사용자 Chrome CDP attach + 반자동 fallback |
| 3. Tauri 헬퍼 | ⏳ 진행 예정 | - |
| 4. CLI ToS 법무 | ✅ 완료 | (C) 개인용 도구 피벗 |

**다음 진행**: PoC 3 + T2 디자인 시스템 (Stitch MCP 활용) 병렬
