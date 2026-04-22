---
title: JamesClaw Agent Harness 사용설명서
type: overview
audience: all
---

# JamesClaw Agent Harness

JamesClaw는 Claude Code 위에서 동작하는 자율 실행 에이전트 하네스입니다. CLAUDE.md(규칙), hooks(자동 개입), commands(스킬), MCP(도구 확장)를 결합하여 에이전트가 품질 타협 없이 작업을 완수하도록 강제합니다. 단순한 프롬프트 모음이 아니라, 잘못된 행동을 사전 차단하고 검수를 자동화하는 인프라입니다.

## 핵심 철학

| 철학 | 의미 |
|------|------|
| **Ghost Mode** | "할까요?" 금지. 즉시 실행, 3회 재시도, 그래도 안 되면 보고. |
| **Evidence-First** | 도구 출력 증거 없이 보고 금지. 추측 금지. |
| **Generator != Evaluator** | 생성 모델이 자기 결과를 검수하지 않음. 외부 모델(Codex/GPT-4.1)이 검수. |
| **12→45 원칙** | MVP로 시작 → Multi-Pass Review로 빈틈 제거 → 엣지케이스·스케일로 확장. |
| **5H 보존** | 외부 모델(5H 0) > Sonnet 서브에이전트 > Opus 직접. 비용 순서대로 선택. |

---

## 문서 구조

```
harness/docs/
├── index.md                          ← 지금 읽는 문서 (개요)
├── changelog.md                      ← 하네스 변경 로그
│
├── getting-started/                  [Tutorial]
│   ├── quickstart.md                 ← 5분 설치 튜토리얼
│   ├── how-it-works.md               ← 하네스 작동 원리
│   └── install-windows.md            ← Windows 전용 설치
│
├── configure/                        [Reference]
│   ├── claude-md.md                  ← CLAUDE.md 섹션별 레퍼런스
│   ├── rules.md                      ← rules/ 파일별 레퍼런스
│   ├── settings.md                   ← settings.json 키별 레퍼런스
│   └── persona.md                    ← 페르소나 커스터마이즈
│
├── hooks/                            [Guide + Reference]
│   ├── hooks-guide.md                ← 훅 작성/디버깅 How-To
│   └── hooks-reference.md            ← 41개 hook 전체 레퍼런스
│
├── skills/                           [Guide + Reference]
│   ├── skills-guide.md               ← 슬래시 커맨드 작성 How-To
│   └── skills-reference.md           ← 21개 slash command 레퍼런스
│
├── multi-model/
│   └── routing.md                    ← 모델 라우팅 전략 Explanation
│
├── pitfalls/
│   └── index.md                      ← PITFALL 50개 (P-001~P-055, 결번 5개)
│
├── claude-code-manual.md             ← Claude Code v2.1.116 공식 매뉴얼 (로컬 신뢰 소스, 1240줄)
│
└── 레거시/특수 매뉴얼 (아카이브)
    ├── harness-manual.md             ← v1 단일 매뉴얼 (1024줄)
    ├── gbrain-manual.md              ← gbrain 지식베이스 전용
    ├── managed-agent-manual.md       ← Managed Agents API 전용
    ├── ralph-loop-manual.md          ← Ralph Loop 상세
    └── v2.1.*-upgrade-notes.md       ← 과거 버전 업그레이드 노트
```

---

## 이 문서를 읽는 순서

### 초보 (처음 설치)
1. `getting-started/quickstart.md` — 설치 및 검증
2. `getting-started/how-it-works.md` — 하네스가 뭘 하는지 이해
3. `configure/persona.md` — 호칭/톤 커스터마이즈

### 중급 (동작 커스터마이즈)
1. `configure/claude-md.md` — 규칙 섹션 이해
2. `configure/rules.md` — 품질·보안·디자인 기준 조정
3. `configure/settings.md` — hook 추가/수정
4. `skills/skills-reference.md` — 쓸 수 있는 슬래시 커맨드 파악

### 고급 (하네스 확장)
1. `hooks/hooks-guide.md` — 새 hook 작성 패턴
2. `skills/skills-guide.md` — 새 슬래시 커맨드 만들기
3. `multi-model/routing.md` — 외부 모델 라우팅 설계
4. `harness/hooks/` + `harness/commands/` 직접 수정 후 `bash harness/deploy.sh`

### 문제 해결
- `pitfalls/index.md` — 과거 실수 검색
- `hooks/hooks-reference.md` — 어떤 hook이 어떤 차단을 일으키는지

---

## 빠른 참조

| 작업 | 명령 |
|------|------|
| 설치 (interactive) | `bash harness/install.sh` |
| 설치 (자동) | `bash harness/install.sh --non-interactive` |
| 핫리로드 (페르소나 치환 없음) | `bash harness/deploy.sh` |
| 감사 실행 | `/audit` |
| 품질 파이프라인 | `/pipeline-run` |
| 외부 모델 QA | `/qa` |
| PRD 작성 | `/prd` |
| 컨텍스트 확인 | `telegram-notify.sh heartbeat` |
