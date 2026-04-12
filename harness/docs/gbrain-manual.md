# GBrain 사용 매뉴얼

> 버전: 0.9.0 | 출처: https://github.com/garrytan/gbrain | 작성일: 2026-04-12

---

## 1. 개요

**GBrain**은 AI 에이전트를 위한 영구 개인 지식 베이스(Personal Knowledge Base) 시스템입니다. Garry Tan(Y Combinator 대표)이 직접 설계·운용 중인 오피니언드 시스템으로, 실전 배포 환경에서 14,700개 이상의 브레인 파일, 40개 이상의 스킬, 20개 이상의 cron 작업이 연속 실행된 검증된 패턴입니다.

### 왜 유용한가

기존 RAG 시스템은 쿼리마다 문서에서 지식을 재도출합니다. GBrain은 다릅니다. 에이전트가 대화할 때마다 사람·회사·미팅·아이디어 페이지를 자동으로 업데이트하고 교차 참조를 유지합니다. **지식이 복리로 누적됩니다.** 몇 주 후에는 해당 사람을 언급하는 것만으로도 풍부한 이력이 자동으로 딸려옵니다.

핵심 장점:
- **서버 없음**: PGLite(WASM 기반 Postgres 17.5)로 로컬에서 즉시 실행
- **하이브리드 검색**: 벡터 + 키워드 + RRF(Reciprocal Rank Fusion) 결합
- **30개 이상의 MCP 도구**: Claude Code, Cursor, Windsurf에 즉시 연결
- **자동 엔티티 감지 + 백링크**: 사람/회사 이름을 언급하면 자동으로 페이지 연결
- **마크다운 기반 brain repo**: git으로 관리 가능한 인간 가독 형식

---

## 2. 설치

### 사전 요구사항

| 항목 | 필수 여부 | 설명 |
|------|----------|------|
| **Bun 런타임** | 필수 | JavaScript/TypeScript 실행 환경 |
| OpenAI API 키 | 선택 | 벡터 임베딩용 (`text-embedding-3-large`) |
| Anthropic API 키 | 선택 | 검색 쿼리 확장용 |
| Supabase 계정 | 선택 | 1,000개 이상 페이지 시 관리형 Postgres |

### 설치 명령어

```bash
# 글로벌 설치 (bun 런타임 필수)
bun add -g github:garrytan/gbrain

# 설치 확인
gbrain --version
```

### ClawHub 플러그인으로 설치 (OpenClaw/Hermes 에이전트 환경)

```bash
# clawhub CLI 사용 시
clawhub install gbrain
```

> package.json의 `openclaw.pluginApi >= 2026.4.0` 호환성이 명시되어 있습니다.

---

## 3. 핵심 기능

### 3.1 저장소 엔진 (플러그어블)

| 엔진 | 설명 | 사용 시점 |
|------|------|----------|
| **PGLite** (기본) | WASM 기반 임베디드 Postgres. 서버 불필요 | 1,000개 이하 파일 |
| **Postgres + pgvector** | Supabase 또는 자체 호스팅 | 1,000개 이상, 멀티 디바이스 |

### 3.2 검색 시스템

- **벡터 검색**: OpenAI `text-embedding-3-large` 임베딩 기반 시맨틱 검색
- **키워드 검색**: pg_trgm 기반 전문 검색
- **하이브리드 RRF**: 두 결과를 Reciprocal Rank Fusion으로 재랭킹
- **멀티쿼리 확장**: LLM이 검색어를 자동으로 확장하여 recall 향상
- **3티어 청킹**: 재귀(recursive) → 시맨틱(semantic) → LLM 가이드

### 3.3 데이터 모델

MECE(상호배타·전체포괄) 디렉토리 구조로 지식을 저장합니다:

```
brain/
├── people/        # 사람 페이지 (1인 1파일 원칙)
├── companies/     # 회사 페이지
├── deals/         # 딜/투자 페이지
├── meetings/      # 미팅 기록
├── projects/      # 프로젝트
├── concepts/      # 아이디어/개념
├── inbox/         # 미분류 (스키마 진화 신호)
├── sources/       # 원본 소스 (불변)
└── RESOLVER.md    # 분류 결정 트리
```

**페이지 구조 (2레이어)**:
- **라인 위 (Compiled Truth)**: 현재 상태 요약, 오픈 스레드, 교차 참조 — 항상 최신으로 덮어씀
- **라인 아래 (Timeline)**: 날짜순 증거 로그 — 추가 전용(append-only), 절대 수정하지 않음

### 3.4 MCP 서버 (30개 이상 도구)

Claude Code, Cursor, Windsurf, Claude Desktop 등 MCP 호환 클라이언트에 즉시 연결 가능합니다.

---

## 4. 사용법

### 4.1 초기화

```bash
# PGLite로 로컬 brain 생성 (가장 빠름, 서버 불필요)
gbrain init

# Supabase 연결 (1,000개 이상 파일 환경)
gbrain init --supabase

# 커스텀 Postgres 연결
gbrain init --url "postgresql://user:pass@host:5432/dbname"
```

### 4.2 지식 가져오기

```bash
# 마크다운 파일 디렉토리 인덱싱
gbrain import ~/Documents/notes/

# 실시간 동기화 (파일 변경 감지)
gbrain sync --repo ~/brain-repo --watch

# 스테일 파일 임베딩 재생성
gbrain embed --stale
```

### 4.3 검색 및 쿼리

```bash
# 키워드 검색
gbrain search "OpenAI funding round"

# 시맨틱 하이브리드 쿼리 (가장 강력)
gbrain query "이 회사의 최근 동향은?"

# 특정 슬러그 페이지 읽기
gbrain get people/sam-altman

# 통계 확인
gbrain stats
```

### 4.4 페이지 작성/수정

```bash
# 페이지 생성 또는 업데이트
gbrain put people/john-doe "# John Doe\n\nYC W24 창업자..."

# 백링크 검사 및 수정
gbrain backlinks --fix

# 페이지 품질 린트 (LLM 아티팩트, 날짜 오류 감지)
gbrain lint
```

### 4.5 엔진 마이그레이션

```bash
# PGLite → Supabase 마이그레이션
gbrain migrate --to supabase

# Supabase → PGLite 롤백
gbrain migrate --to pglite
```

### 4.6 MCP 서버 실행

```bash
# stdio MCP 서버 시작
gbrain serve

# 설정 검증
gbrain doctor --json

# 사용 가능한 인테그레이션 목록
gbrain integrations list
```

---

## 5. 설정

### 5.1 환경 변수

```bash
# 임베딩 생성용 (선택, 있으면 벡터 검색 활성화)
OPENAI_API_KEY=sk-...

# 검색 쿼리 확장용 (선택)
ANTHROPIC_API_KEY=sk-ant-...

# Supabase 연결 (엔진을 postgres로 설정 시)
DATABASE_URL=postgresql://...
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

### 5.2 MCP 클라이언트 설정

**Claude Code** (`~/.claude/settings.json`에 추가):

```json
{
  "mcpServers": {
    "gbrain": {
      "command": "gbrain",
      "args": ["serve"]
    }
  }
}
```

**Claude Desktop** (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "gbrain": {
      "command": "gbrain",
      "args": ["serve"]
    }
  }
}
```

**원격 HTTP 터널 방식** (Claude Desktop 또는 Perplexity):

```bash
# ngrok 또는 cloudflared로 터널 생성
gbrain serve --http 3000
cloudflared tunnel --url http://localhost:3000
```

### 5.3 권장 brain 구조

```
~/brain/
├── RESOLVER.md         # 분류 결정 트리 (에이전트가 첫 번째로 읽음)
├── people/
│   └── README.md       # "무엇이 여기 들어오는가" 정의
├── companies/
│   └── README.md
├── meetings/
│   └── README.md
├── inbox/              # 미분류 임시 보관
└── sources/            # 원본 소스 (불변)
```

---

## 6. 우리 하네스와의 통합

### 6.1 JamesClaw 아키텍처에서의 위치

gbrain은 JamesClaw 하네스의 **장기 기억 레이어**로 활용할 수 있습니다. 현재 하네스가 세션 기억을 Obsidian Vault에 저장하는 구조를 보완하여, 검색 가능한 구조화 지식 베이스로 확장합니다.

```
현재 메모리 레이어:
  세션 메모리 → ~/.claude/projects/.../memory/MEMORY.md
  장기 저장  → Obsidian Vault (~/Obsidian-Vault/)

gbrain 추가 시:
  세션 메모리 → 기존 유지
  장기 저장  → Obsidian Vault (기존 유지)
  검색 가능 KB → GBrain (신규) ← 에이전트가 질문 전에 먼저 조회
```

### 6.2 MCP 연동 방법

```bash
# 1. gbrain MCP 서버를 Claude Code에 온디맨드로 추가
claude mcp add gbrain -- gbrain serve

# 2. 기존 brain repo 인덱싱 (Obsidian Vault)
gbrain import "C:/Users/AIcreator/Obsidian-Vault/"

# 3. 인덱싱 후 Claude Code에서 즉시 사용 가능
# → MCP 도구로 gbrain_search, gbrain_query 등 30개 도구 접근
```

> **주의**: 현재 CLAUDE.md 아키텍처 규칙에 따라, 상시 로드 도구는 50개 이하를 유지해야 합니다. gbrain MCP(30개 이상 도구)는 작업 완료 후 `claude mcp remove gbrain`으로 제거하는 **온디맨드 방식**을 권장합니다.

### 6.3 Brain-Agent 루프 적용

JamesClaw 하네스의 Ghost Mode 원칙과 gbrain의 "Brain-First Lookup" 원칙을 결합합니다:

```
기존 플로우:
  대표님 요청 → 에이전트 즉시 실행

gbrain 통합 플로우:
  대표님 요청
    → gbrain query (사람/회사/프로젝트 관련 시)
    → 관련 컨텍스트 로드
    → 에이전트 실행
    → 새로운 정보 gbrain put으로 기록 (자동화 가능)
```

### 6.4 hooks 연동 예시

`post-edit-dispatcher.sh`에서 중요 정보 자동 기록:

```bash
# 블로그 글 발행 후 gbrain에 기록
gbrain put projects/smartreview-blog-$(date +%Y%m%d) \
  "# SmartReview 블로그 발행\n\n날짜: $(date)\n키워드: $KEYWORD\n URL: $LIVE_URL"
```

### 6.5 외부 모델 라우팅 통합

CLAUDE.md의 모델 라우팅 규칙과 gbrain의 Sub-Agent Model Routing 가이드가 동일한 원칙을 따릅니다. gbrain의 `docs/guides/sub-agent-routing.md`를 참조하면 비용 최적화된 모델 선택 기준을 강화할 수 있습니다.

### 6.6 비용 고려사항

| 기능 | 비용 |
|------|------|
| PGLite 로컬 실행 | 무료 |
| OpenAI 임베딩 (`text-embedding-3-large`) | ~$0.13/M 토큰 |
| Anthropic 쿼리 확장 | Sonnet 기준 API 비용 |
| Supabase (1,000페이지 이상) | $25/월~ |

> 임베딩 없이도 키워드 검색은 동작합니다. `OPENAI_API_KEY` 미설정 시 벡터 검색 비활성화, 키워드 검색만 사용됩니다.

---

## 참고 링크

| 문서 | URL |
|------|-----|
| GitHub 리포 | https://github.com/garrytan/gbrain |
| Skillpack (에이전트 레퍼런스 아키텍처) | `docs/GBRAIN_SKILLPACK.md` |
| 권장 스키마 | `docs/GBRAIN_RECOMMENDED_SCHEMA.md` |
| 엔진 비교 | `docs/ENGINES.md` |
| 레시피 (음성/이메일/트위터) | `recipes/` 디렉토리 |
| MCP 클라이언트 설정 | `docs/mcp/` 디렉토리 |
