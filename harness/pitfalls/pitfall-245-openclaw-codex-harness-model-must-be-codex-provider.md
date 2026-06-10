# P-245: openclaw codex harness "does not support gpt-5.5" = model을 codex/gpt-5.5로 (openai/gpt-5.5 아님)

- **발견/해결**: 2026-06-01 (봇 online인데 응답 불가 진단)
- **영향**: codex 봇(TARS 등)이 Discord 연결(online)은 되나 메시지 응답 완전 불가.

## 증상
- codex 봇 핑 → `GatewayClientRequestError: Requested agent harness "codex" does not support openai/gpt-5.5 (provider is not one of: codex)`
- gateway 로그: `[diagnostic] lane task error: ... harness "codex" does not support openai/gpt-5.5`
- probe/connected는 정상 → online으로 보여 오인하기 쉬움

## 근본 원인 (실측)
- 봇 model이 `openai/gpt-5.5`(**openai** provider)인데 agentRuntime은 `codex`. codex harness는 **codex provider 모델만** 받음.
- `openclaw models list` 확인 → `codex/gpt-5.5`(codex provider, text+image 266k)가 **별도로 존재**. `openai/gpt-5.5`(text 195k)와 다른 모델.

## 해결 (검증됨)
1. 봇 model `openai/gpt-5.5` → **`codex/gpt-5.5`**
2. `agents.defaults.models`에 `"codex/gpt-5.5": {"agentRuntime": {"id": "codex"}}` 추가
3. config **hot-reload**(파일 저장 시 자동, restart 불필요 — `[reload] config hot reload applied`)
- 검증: gw1 TARS `--agent codex` 핑 → "정상 작동 중" 응답. 재부팅 후에도 config 유지.

## 잔여 함정 (gw2 profile pro)
- gw2 봇(c3po/joi/kitt)은 같은 수정 후 **401 Unauthorized**(`Missing bearer, url: api.openai.com/v1/responses`). codex CLI(appServer) 안 거치고 openai api 직접 호출 = c3po agent 인증/세션 차이.
- gw1은 OAuth(`~/.codex/auth.json` home 공유)로 codex CLI 경유 성공. gw2 c3po는 미충원 봇이라 후순위.

## 재발 방지
- codex 봇 "does not support" 시 → `node .../index.js models list`로 codex provider 모델명 확인 후 model 교체. **추측 수정 금지**(P-229 교훈 — 정확한 에러 문구 + 타겟 수정).
- 봇 model 일괄 변경 시 봇별(P-225 캐릭터 매핑) 확인: codex계(TARS/FRIDAY) = `codex/gpt-5.5`, claude계(EVE/TRON) = `anthropic/claude-sonnet-4-6`, opus(JARVIS) = `claude-opus-4-8`. 일괄 sed 금지(claude4 봇을 codex로 잘못 바꾸는 사고).

## 관련
- [[pitfall-229-openclaw-522-harness-bug-527-recovery]] (5.27 모델 등록 의무)
- [[pitfall-241-wsl-path-openclaw-points-stale-windows-518-binary]] (5.27 절대경로)
- [[pitfall-244-wsl2-hcs-service-unavailable-hypervisorlaunchtype-missing]] (같은 세션 WSL2 다운)
