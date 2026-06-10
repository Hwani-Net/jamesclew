# P-240: main 세션이 "봇 자율진행 감사자"여야 하는데 "직접 실행 일꾼"이 됨 + 봇 자율진행 config 손상으로 0%

- **발견**: 2026-05-31 (대표님 지적: "너는 결과물 내는 게 목표가 아니라 discord 봇들이 자율진행 티키타카 제대로 하는지 감사하는 역할인데 왜 자꾸 니가 일을 하려고해? 목표는 openclaw 방식 discord가 완전자율로 내 개입 없이 7/24 작업하는 것")
- **영향**: 프로젝트 목표를 근본적으로 오해. 발행 결과물(서큘레이터/창문형 글)을 main이 직접 만들고 직접 검수·E2E까지 함 → 대표님이 이미 보유한 "claude 발행 프로젝트"를 중복 수행. 진짜 목표(OpenClaw 봇 무인 자율 루프)는 손도 안 댐.

## 증상 (역할 혼동)
- main(나)이 직접: HTML 변환 + 이미지 생성 + Firebase deploy + claude-in-chrome 발행 + 미리보기 검증 + Discord 보고 + codex critic 구동 + EVE 봇 일일이 지시 + expect E2E.
- 봇을 "구동"할 때조차 main이 매 단계 수동 지시 = 자율이 아니라 원격조종.
- 대표님 개입 0 무인 루프는 **한 번도 달성 못 함**.

## 근본 원인 2가지
### A. 역할 오해 (반복 패턴 declare_no_execute의 변형 — "내가 다 한다")
- 목표 재정의: **OpenClaw Discord 봇들 = 글감선정→작성→검수→수정→발행→보고를 대표님 개입 0으로 24/7 무한 자율 티키타카하는 시스템.**
- **main 세션 = 그 자율 티키타카가 제대로 도는지 감사(audit)하는 역할.** 직접 일꾼 아님.
- 발행 프로젝트는 이미 claude(main)로 보유 중 → 그걸 또 하는 건 목표가 아님.

### B. 봇 자율진행 인프라가 실제로 죽어있음 (감사로 발견)
- `systemctl --user is-active openclaw-gateway(.pro).service` = active (프로세스만 떠있음, uptime 20h)
- **`openclaw agent --agent claude/main` → stdout 0줄** = agent turn 자체가 안 돎 (EVE 검수 구동 0줄, main --deliver Discord 미도달=P-239)
- **`openclaw cron list` 실패** → `Invalid config at openclaw.json`:
  - `models.providers.codex.baseUrl: Invalid input` / `codex.models: Invalid input` (codex provider가 `{apiKey}` 만 있고 baseUrl·models 누락)
  - `models.providers.anthropic.baseUrl: Invalid input`
- `openclaw doctor` 도 invalid config로 hang.
- 즉 **config invalid → 모든 agent turn + cron(자율 트리거) 전멸 → 봇 자율진행 0%.** 봇들이 "살아있는 것처럼" 보였지만 실제 작업 수행 불가. P-229 계열(provider config 손상) 재발/변형.

## 해결 (방향 — 수정은 P-229 봇 전멸 위험이라 대표님 승인 후)
1. **역할 재정립**: main은 감사자. 직접 발행/검수/E2E 금지. 봇이 하게 만들고 그 흐름을 관찰·진단·복구만.
2. **자율 인프라 복구 (근본 차단점)**: openclaw.json provider config 정상화 — codex provider에 baseUrl/models 복원, anthropic baseUrl 정정. `openclaw config validate` 통과 → `openclaw agent` turn 정상 → `openclaw cron list` 가능.
3. **진짜 자율 트리거 확립**: cron 안티패턴(P-206) 회피하고 message-stream trigger(P-206)로 봇 루프 기동 → 봇끼리 글감→작성→critic→수정→발행→보고 티키타카가 main 개입 없이 도는지 감사.
4. **감사 지표**: Discord 채널에서 봇간(JARVIS↔EVE↔TARS↔Data) 메시지 흐름이 main 구동 없이 발생하는가 / cron·trigger가 발화하는가 / agent turn 응답 비0줄인가 / deliver 채널 도달(fetch_messages 실측)인가.

## 재발 방지
- main 세션은 OpenClaw 작업에서 **실행자 아니라 감사자**. "발행해줘" 류도 봇 자율 루프에 태우고 main은 결과 흐름만 감사. 직접 손대면 목표(무인 자율) 미달성을 가림.
- 봇 "active" = 자율 작동 아님. **agent turn 응답 줄수 + cron list 성공 + Discord 봇간 자율 메시지**가 진짜 작동 증거.
- config 수정은 봇 8개 영향(P-229) — invalid 항목 정밀 확인 후 최소 변경, 대표님 승인.

## 관련
- [[pitfall-239-openclaw-agent-deliver-legacy-config-discord-undelivered]] (같은 config 손상의 deliver 증상)
- [[pitfall-229-openclaw-claude-cli-harness-bug]] (provider config 등록/손상)
- [[pitfall-206-openclaw-cron-fire-error-auto-disable-without-fallback]] (자율 트리거 = message stream)
- CLAUDE.md §"활성 자율 인프라" P-201/P-214 (멀티봇 자율진행 설계)
