# P-239: openclaw agent --deliver가 legacy config 경고로 Discord 미도달 — main 직접 push fallback

- **발견**: 2026-05-31 (서큘레이터/88·창문형/89 발행 보고 시)
- **영향**: P-222-A "발행 후 Discord #작업-요청 보고"가 silent fail. exit 0 + stdout 정상처럼 보이나 채널 미도달 → premature_conclusion 위험.

## 증상
- `wsl -d Ubuntu -e bash -c 'openclaw agent --agent main -m "..." --deliver --channel discord'` 실행 → exit code 0.
- stdout = legacy config 경고 6줄만, agent 응답 텍스트 0줄.
- `fetch_messages(채널 1508275532851183727)` 실측 → 보고 메시지가 **채널에 없음**. 최근 메시지는 직전 이동식(87) 보고에서 멈춤.

## 근본 원인 (실측 + 추정)
- stdout 경고: `agents.defaults.agentRuntime is ignored; set models.providers.<provider>.agentRuntime ... Run "openclaw doctor --fix"`.
- legacy config key(`agents.defaults.agentRuntime`)가 무시되면서 agent runtime이 제대로 안 잡혀 **agent turn 자체가 안 돌거나 deliver 단계 누락** (응답 0줄이 근거). 경고 메시지는 "still run with invalid config"라 했으나 deliver는 실패.
- 원인 미확정 — legacy config 또는 P-229 계열 harness 문제 가능. `openclaw doctor --fix` 미적용 상태가 1차 용의.

## 해결 (검증완료 fallback)
1. **즉시 fallback**: main 세션이 discord MCP `reply(chat_id=채널ID, text=...)`로 **직접 push**. 이번에 성공(id 1510484053617545246). 이전 이동식 보고도 "me"(main)가 직접 보냈음 — 이미 검증된 경로.
2. **근본 수정 후속**: `wsl -d Ubuntu -e bash -c 'openclaw doctor --fix'` → `openclaw config validate`로 legacy key 정리 → agent --deliver 재검증.
3. **검증 강제**: deliver 호출 후 **반드시 `fetch_messages`로 채널 도달 실측** (exit 0/stdout만 믿지 말 것). 미도달 시 즉시 reply 직접 push.

## 재발 방지
- P-222-A 보고는 **deliver 성공을 stdout exit code로 판정 금지** — Discord fetch_messages 실측이 유일한 증거 (Discord search API 미노출이라 fetch가 유일 확인 경로).
- openclaw agent --deliver는 legacy config/harness 상태에 취약 → **main 세션 직접 reply push가 더 신뢰성 높음**. P-222-A "worker 직접 push 금지"는 deliver 정상 작동 전제 — deliver 실패 시 main push가 정당한 fallback.
- 봇 deliver 무응답(stdout 응답 0줄) = agent turn 실패 신호. P-229 진단(claude 봇 Discord 실측) 절차 준용.

## 관련
- [[pitfall-229-openclaw-claude-cli-harness-bug]] (agent harness/config 취약성)
- [[pitfall-238-openclaw-cdp-tinymce-source-paste-escape]] (같은 세션 발행 파이프라인)
- CLAUDE.md P-222-A (발행 후 Discord 보고 의무)
