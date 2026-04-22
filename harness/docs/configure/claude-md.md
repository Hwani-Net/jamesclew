---
title: CLAUDE.md 섹션별 레퍼런스
type: reference
diátaxis: Reference
source: D:/jamesclew/harness/CLAUDE.md
lines: 337
---

# CLAUDE.md 레퍼런스

소스: `D:/jamesclew/harness/CLAUDE.md` (337줄)
배포 경로: `~/.claude/CLAUDE.md`

`install.sh` 실행 시 `persona.yaml` 의 값(`agent_name`, `honorific` 등)이 sed 치환되어 배포됩니다. 소스를 직접 편집 후 `bash harness/install.sh --non-interactive` 로 재배포하십시오.

---

## 섹션 일람

| # | 섹션 | 요약 | 관련 hook |
|---|------|------|----------|
| 1 | **Identity** | 에이전트 이름, 호칭, 사고 방식 정의. 2수 앞을 읽는 천재형 참모 역할. | — |
| 2 | **Language** | 한국어 합니다체. 코드/커밋은 영어. 응답 간결화(결과·결정만 출력). | — |
| 3 | **Quality Standards** | 품질 최우선. 학습 데이터 의존 금지. 12→45 원칙. effortLevel 고정 금지. | post-edit-dispatcher.sh |
| 4 | **Ghost Mode** | 즉시 실행. "할까요?" 금지. 3회 재시도 후 보고. 하향 나선 금지. | stop-dispatcher.sh |
| 5 | **Auditability** | Evidence-First. gbrain 자율 저장. 자동 스킬 생성. 위키 소스 자동 저장. | stop-dispatcher.sh |
| 6 | **Autonomous Operation / 우선순위 공식** | `긴급도+수익영향+대표님대기+ROI-리스크` 점수 산정 후 정렬 실행. Multi-Pass Review 최소 2라운드. | — |
| 7 | **Build Transition Rule** | 빌드 요청 시 바로 코딩 금지. 복잡도별 plan 선택(`/ultraplan` 고복잡도 · `/plan` 중복잡도·오프라인 fallback · 저복잡도는 직접). `/deep-plan`은 deprecated(2026-04-21). 플랜 승인 게이트(`<!-- ANNOTATE-APPROVED -->` 헤더 필수). | enforce-build-transition.sh |
| 8 | **Telegram 알림** | 작업 완료 시 `last_result.txt` 저장 → Stop hook이 자동 전송. 텔레그램 요청→텔레그램 응답 원칙. | stop-dispatcher.sh, telegram-notify.sh |
| 9 | **Multi-Model Orchestration** | 작업 유형별 모델 라우팅. Sonnet/Codex/GPT-4.1/Gemma4/GLM-5.1. Agent Teams(v2.1.107+). HydraTeams 프록시(:3456). Advisor Loop. | — |
| 10 | **External Model CLI Reference** | Codex: `codex exec`. GPT-4.1: `curl localhost:4141`. Ollama: `:11434`. Monitor tool. HTTP hooks. defer 결정. | — |
| 11 | **브라우저 자동화 도구 우선순위** | 1순위 expect MCP → 2순위 claude-in-chrome → Playwright CLI 직접 호출 금지. Vision 이중 패스. | vision-routing-guard.sh, chrome-read-page-guard.sh |
| 12 | **Tool Priority** | 외부 모델 > Subagent > Built-in > Bash > MCP. 검수는 반드시 외부 모델. 자기 검수 금지. | — |
| 13 | **Quality Gates** | 코드→테스트→빌드→커밋. 배포→검증+외부 검수. 에러→gbrain pitfall 기록. | verify-deploy.sh, post-edit-dispatcher.sh |
| 14 | **5H Limit Optimization** | 외부 모델만 5H+7D 0 소비. Sonnet model 명시 필수. 80%+ 비상 모드. GPT 메인 전환 방법. | — |
| 15 | **Context & Session** | Opus 세션: 45%에 옵시디언 저장 후 `/compact`. Sonnet 세션: auto compact. 수치는 heartbeat로 확인. | precompact.sh |
| 16 | **Model Selection** | opusplan(권장) / opus / sonnet / GPT-4.1. Advisor API 참고. | — |
| 17 | **v2.1.112 신규** | `/less-permission-prompts`, `/ultrareview`. xhigh effort. PowerShell Tool. UI 단축키(`Ctrl+U/Y/L`). | — |
| 18 | **v2.1.113~114 신규** | 네이티브 바이너리. 서브에이전트 10분 stall 자동 실패. 보안 강화(exec wrapper deny). MCP concurrent-call fix. | — |
| 19 | **Prerequisites / Hosting / File Location / Project Override** | 필수 환경변수·CLI 목록. Firebase 전용 호스팅. 하네스 소스 경로. 프로젝트 루트 CLAUDE.md 우선 원칙. | — |

---

## 프로젝트 오버라이드

프로젝트 루트에 `CLAUDE.md` 가 존재하면 전역 규칙(`~/.claude/CLAUDE.md`)보다 우선 적용됩니다. 프로젝트별 예외를 두고 싶을 때 활용합니다.

```bash
# 예: D:/my-project/CLAUDE.md
# 이 파일이 있으면 해당 프로젝트에서는 이 규칙이 우선.
```

전역 규칙을 상속하면서 일부만 오버라이드하고 싶으면 `@global` 임포트를 사용합니다(Claude Code v2.1.100+).
