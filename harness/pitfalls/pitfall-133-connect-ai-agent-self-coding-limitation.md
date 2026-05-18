---
slug: pitfall-133-connect-ai-agent-self-coding-limitation
title: Connect AI 에이전트의 자기 코딩·환경 적응 한계
date: 2026-05-08
tags: [connect-ai, agent-architecture, antigravity, scope-misuse]
severity: medium
---

# Connect AI 에이전트의 자기 코딩·환경 적응 한계

## 증상
- 대표님이 developer 에이전트에게 "ANTHROPIC_API_KEY 사용처 조사 후 제거 절차 작성" 요청
- developer 에이전트가 60분짜리 분석 보고서 제출 (`gh secret list`, `git grep`, `rg`, `sudo grep`, `systemctl show-environment` 명령 나열)
- Connect AI 측 `_runShortcutTool`이 명령을 Windows에서 그대로 실행 → 전부 fail
  - `git grep` → not a git repository
  - `rg` → 'rg'은(는) 내부 또는 외부 명령... (Windows에 ripgrep 없음)
  - `sudo grep` → Sudo는 이 컴퓨터에서 사용하지 않도록 설정
  - `systemctl` → 명령어 자체 없음 (Linux 전용)
- 그런데 실제로 우리 시스템(Connect AI extension + tool-seeds 14개)은 ANTHROPIC API를 **단 한 번도 호출하지 않음** (Grep 검증: import anthropic 0건, Anthropic( 0건)
- 즉 60분짜리 분석은 **존재하지 않는 사용처를 추적하는 헛수고**

## 원인
Connect AI 에이전트의 본질적 구조:
1. **LLM 챗봇** (Antigravity 내장 Gemini/Claude) + **사전 시드된 Python 도구 호출자** (`_runShortcutTool` → `assets/tool-seeds/{agent}/{tool}.py`)
2. **자기 코드베이스를 읽지 못함** — extension.ts, tool-seeds 디렉토리 구조 모름
3. **환경 적응 불가** — Linux 명령을 Windows에서 그대로 추측 실행. PowerShell `Select-String`, `findstr`로 재작성 못 함
4. **새 도구 작성 불가** — 시드 파일이 없으면 호출 자체 불가. extension.ts에 등록 필요
5. **자기 실행 코드 수정 불가** — 보안상 의도적 제한

## 해결
역할 분담 명확화:
- **Connect AI 에이전트** = 자동화 트리거 + LLM 분석/보고
- **Claude Code (메타 에이전트)** = 새 시드 작성, extension.ts 패치, 환경 적응 명령, API 키 관리

이번 케이스 즉시 조치:
- `_agents/developer/config.md`, `_agents/ceo/config.md`에서 ANTHROPIC_API_KEY + CLAUDE_API_KEY 라인 제거 (Connect AI 코드/시드 어디에서도 호출 안 함)
- 환경변수가 단지 적혀만 있는 것은 보안 면적 낭비

## 재발 방지
1. **Connect AI에게 "코드 분석/시스템 조사" 위임 금지** — 같은 작업을 Claude Code로 직접 수행하는 것이 항상 빠름 (Grep/Read 도구 보유)
2. **에이전트 응답에 Linux 명령 나열되면 즉시 차단** — Windows 환경 무시 신호. 직접 PowerShell/findstr로 검증
3. **config.md에 환경변수 추가 시 "어디서 호출하는지" 코멘트 필수** — 미사용 키 누적 방지
4. **에이전트 한계 인지 체크리스트**:
   - [ ] 작업이 사전 시드된 도구로 가능한가? → Connect AI OK
   - [ ] 새 코드 작성 / 환경변수 편집 / git 조작이 필요한가? → Claude Code 직접
   - [ ] LLM의 명령어 추측이 환경에 맞는가? → 의심 시 Claude Code가 검증

## 관련 파일
- `D:/conneteailab/_tracking/connect-ai/src/extension.ts` (line 20609~ `_runShortcutTool`)
- `D:/conneteailab/_tracking/connect-ai/assets/tool-seeds/` (14개 시드, 모두 OpenAI/내부 LLM만 사용)
- `D:/conneteailab/_agents/developer/config.md`, `_agents/ceo/config.md` (환경변수 시크릿 보관)

## 인용 (대표님 원문)
> "connect ai 에게 openai api를 사용하랫더니 아래처럼 대답을해. 스스로 api키등을 셋팅하는건 아주 없는것 같아. 얘는 그냥 자동화만 할 수 있는거야? 스스로의 코딩은 할 수 없는거야?"

이 질문이 정확함. **Connect AI는 자동화 + 분석 보고 한정. 코딩·환경 셋팅은 Claude Code 영역.**
