---
name: Session 2026-04-03 Full Record
description: 하네스 대규모 업그레이드 세션 — 전체 작업 기록, 의사결정 근거, 다음 세션 컨텍스트
session_id: 0e3788e1-822a-4d07-8414-cd4c7a0b4ff4
date: 2026-04-03
---

# 세션 2026-04-03 전체 기록

## 세션 시작 상태
- Claude Code 2.1.90, Opus 4.6 (1M context), Claude Max 플랜
- D:/jamesclew 작업 디렉토리 (git 미초기화 상태)
- Phase 1 하네스 일부 미적용 상태

## 완료 작업 (시간순)

### 1. 하네스 Phase 1 미적용 항목 수정
- PreToolUse/PostToolUse hook: jq → grep 패턴 매칭으로 교체 (Windows jq 의존 제거)
- deny list: `*|*curl*`, `*|*wget*`, `*&&*rm -rf*`, `*;*rm -rf*` 4개 패턴 추가
- effortLevel "max" 제거 → 자율 선택 (대표님 지시)

### 2. Hook 버그 수정
- Usage API 429: `/api/oauth/usage` 엔드포인트가 Claude Max에서 persistent 429 반환 (Anthropic #30930)
  - 해결: 1분 캐시 + API 실패 시 "?" 표시 (0% 대신)
- Reload 중복 메시지: Stop + SessionStart 동시 발생 → 15초 디바운스 추가
- Stop hook: `telegram-notify.sh stop`으로 통합
- 텔레그램 알림에 컨텍스트 사용량 표시 추가 (🧠 Context: 310K/31%)
  - 트랜스크립트의 `cache_read_input_tokens`에서 추출

### 3. 플러그인 복원
- awesome-statusline 재설치 (5H/7D 바 표시)

### 4. 페르소나 시스템 구축
#### 조사 결과
- 업계 프레임워크 6개 비교: OpenClaw, Xtensio, NNGroup, Synthetic Users, Character Card V2, Growth Memo
- MCP 후보 5개 실제 클론/빌드 → **2개가 hallucination** (seanshin0214/persona-mcp, mickdarling/persona-mcp-server는 존재하지 않음)
- 실제 존재 확인된 것: pidster/persona-mcp(5★), okkimus/stakeholder-mcp(1★)

#### 설치 완료
- **persona-mcp v0.3.1**: npm 안정 버전, Windows `import.meta.url` 경로 불일치 래퍼(start.mjs) 제작
- **stakeholder-mcp**: Windows 경로 수정 (`import.meta.url.pathname` 슬래시 문제), OpenRouter 7키 로테이션 LLM 클라이언트 구현
- OpenRouter 키 7개 등록 (`~/.claude/openrouter-keys.json`)
- 모델 배정: Tech Lead/DevOps(Claude Haiku), PM/UX(Qwen 3.6), Security(GPT-OSS), End Users(Nemotron/Llama)

#### 페르소나 사용 구조 (의사결정)
- persona-mcp = 라우터 (어떤 전문가에게 물어볼지 판단)
- stakeholder-mcp = 실행 (외부 LLM이 다른 역할로 응답)
- JamesClaw 정체성 고정 — 페르소나는 자문위원, 나는 실행자
- Custom Agent가 Custom Skill보다 하네스 원칙(자율수행, Ghost Mode)에 부합

### 5. 옵시디언 71개 페르소나 보강
- 보강 템플릿 설계: +5개 섹션 (목표, 제약조건, 사용 맥락, 대표 발화, 말투 강화)
- 핵심 8개 수동 보강: DevOps, PM, 엄격 평가자, 60대 시니어, 보안 엔지니어, SaaS CFO, 법무 변호사, 충동구매족
- 나머지 63개 AI 스크립트 자동 보강 (OpenRouter Qwen 3.6, 에러 0)
- SaaS CFO를 stakeholder-mcp에 동적 등록 → 실제 상담 테스트 성공

### 6. 하네스 설계 재구성 (리서치 기반)
#### 구 원칙 → 신 원칙
| 구 원칙 | 신 원칙 | 근거 |
|---------|---------|------|
| MCP 최대 3개 | Tool 50개 이하 | 230+에서 Explore 실패, 50~100 안전 (GitHub #38928) |
| ~21K/cycle | 삭제 | 시스템 오버헤드만 24K (GitHub #42452) |
| effortLevel "max" | 자율 선택 | 단순 작업에 토큰 낭비 |
| Perplexity 딥리서치 | 검색만 | Opus가 더 강력, API 비용 96% 절감 |

#### Tool 최적화 (66 → 50)
- stitch-mcp 온디맨드 전환 (-12)
- Perplexity search만 허용 (-3)
- persona-mcp get-adoption-metrics deny (-1)

### 7. Hallucination 방지 3계층 구현
#### 1계층: SubagentStop command hook (verify-subagent.sh)
- GitHub repo 404 확인 (URL + 이름만 패턴)
- npm 패키지 404 확인
- PyPI 패키지 404 확인
- 단축 URL 자동 경고
- Rate limit 403/429 시 안전 중단
- 네트워크 실패 시 "VERIFICATION SKIPPED" 경고

#### 2계층: PreToolUse command hook (verify-memory-write.sh)
- 메모리/옵시디언 파일 쓰기 전 URL 검증 → deny 차단

#### 3계층: CLAUDE.md 행동 규칙
- HALLUCINATION WARNING 수신 시 절대 그대로 전달 금지
- Hook이 잡지 못하는 패턴: 도구명만 언급, 실제 repo에 가짜 기능, 단축 URL

#### 검증 결과
- 11개 테스트 시나리오 통과, 오탐 0건
- 외부 모델(Tech Lead, DevOps) bypass 벡터 분석 → 5개 발견, 가능한 것 수정
- **prompt hook(LLM 기반)은 효과 없음으로 제거** — curl 404가 100% 정확

### 8. Quality Gate 구현
- PostToolUse (Write|Edit): 코드 파일 변경 시 dirty 기록
- PreToolUse (Bash): git commit 시 dirty + 테스트 미실행 → additionalContext 경고 주입
- PostToolUse (Bash): 테스트 명령어 성공 시 dirty 초기화
- exit code 2 버그 때문에 deny 대신 경고 방식 채택

### 9. Custom Agents 구현
- researcher.md: Sonnet, anti-hallucination 규칙 내장, 2개 소스 교차 확인
- code-reviewer.md: Sonnet, 읽기 전용, 보안/버그/성능/유지보수 체크리스트
- content-writer.md: Opus, Phase 2 수익 파이프라인용, 한국 시장 SEO

### 10. Git 저장소 구성
- D:/jamesclew를 하네스 소스 코드 저장소로 초기화
- harness/deploy.sh: D:/jamesclew/harness/ → ~/.claude/ 배포
- settings.json의 API 키는 플레이스홀더로 교체
- File Location Rules: ~/.claude/에 직접 생성 금지, 반드시 D:/jamesclew/harness/ 경유

### 11. 외부 모델 전수검사
- Tech Lead + DevOps + SaaS CFO 3개 모델 병렬 감사
- Critical: effortLevel "max" 잔존 → 제거
- Critical: API 키 평문 → Claude Code 구조적 한계, git에는 플레이스홀더
- High: verify-subagent.sh fail-open → 네트워크 실패 경고 추가

### 12. 메모리/피드백 기록
- feedback_effort_level.md: 자율 선택
- feedback_quality_first.md: 시간/컨텍스트 핑계 금지, 학습데이터 의존 금지
- feedback_file_location.md: D:/jamesclew/harness/ 경유 필수

## 대표님 핵심 피드백 (다음 세션에서 반드시 준수)
1. **effortLevel 고정 금지** — 난이도에 따라 자율 선택
2. **품질 최우선** — 시간/컨텍스트 핑계로 타협 금지, 학습데이터 의존 금지
3. **파일 위치** — D:/jamesclew/harness/에서 편집, ~/.claude/에 직접 생성 금지
4. **Perplexity** — 검색(search)만, 분석은 Opus가 수행
5. **Firebase 호스팅** — 모든 웹 프로젝트 Firebase 기반, WordPress 사용 안 함
6. **hallucination** — 서브에이전트 결과 검증 필수, HALLUCINATION WARNING 무시 금지

## 다음 세션 TODO
1. **Phase 2 수익 파이프라인 착수** — Firebase + SSG 블로그 (WordPress 대신)
2. 하네스 동작 검수 (Phase 2 진행하면서 동시에)
3. 나머지 하네스 개선: Usage 80%+ 자동 행동, 관찰성/audit 로깅

## 현재 파일 구조
```
D:/jamesclew/                    ← Git 저장소 (소스 코드)
├── harness/
│   ├── CLAUDE.md
│   ├── settings.json (키 플레이스홀더)
│   ├── deploy.sh
│   ├── hooks/ (telegram-notify, verify-subagent, verify-memory-write, quality-gate)
│   ├── rules/ (architecture, quality, security)
│   ├── scripts/ (tavily-rotator, enhance-personas)
│   └── agents/ (researcher, code-reviewer, content-writer)
├── pipelines/                   ← Phase 2 (진행 중)
│   └── blog/
└── README.md

C:/Users/AIcreator/.claude/      ← 배포 대상 (실제 작동)
├── settings.json (실제 키)
├── hooks/, rules/, agents/, scripts/
├── mcp-servers/ (persona-mcp-v2, stakeholder-mcp)
├── openrouter-keys.json, tavily-keys.json
└── projects/d--jamesclew/memory/

C:/Users/AIcreator/Obsidian-Vault/
├── 01-jamesclaw/harness/ (설계 문서)
└── 03-knowledge/personas/ (71개 페르소나)
```

## Git 커밋 히스토리
```
12d6002 feat: add custom agents (researcher, code-reviewer, content-writer)
2d39977 feat: add quality gate hook for test enforcement
bbc5f26 fix: address audit findings from external model review
f740ae6 docs: add file location rules to CLAUDE.md
7f1f718 feat: initial JamesClaw harness repository
```
