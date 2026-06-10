# P-229: OpenClaw 5.22 claude-cli harness 미등록 버그 → 5.27 업그레이드 복구 (전체 체인)

- **발견/복구**: 2026-05-30 (장시간 디버깅 세션)
- **영향**: claude 기반 봇(JARVIS=opus-4-8, EVE=sonnet-4-6) Discord 응답 **완전 불가**. gpt-5.5 봇(TARS 등)은 정상.

## 증상
- Discord 메시지 처리 시: `MissingAgentHarnessError: Requested agent harness "claude-cli" is not registered`
- heartbeat cli exec는 성공(별도 cliBackend 경로) → 혼란 유발. Discord user 메시지만 harness registry 거쳐 실패.
- 부수 증상: 대표님 평문에 "EVE 입력 중" typing 표시 (실제 EVE는 exec 0, 응답 0 — 순수 표시 노이즈. main 실패 fallback과 무관하게 EVE account가 메시지 수신 시 typing 발동).

## 근본 원인 (코드 확인)
- OpenClaw 2026.5.22: anthropic plugin이 `registerCliBackend`만 호출, **`registerAgentHarness("claude-cli")` 누락** (릴리즈 버그).
- acpx는 전용 등록 코드 있어 정상, claude-cli만 누락 → `selectAgentHarnessDecision`에서 throw.
- 5.22는 5/25 00:44 **자동 업데이트**로 설치됨 (시한폭탄).

## 배제된 것들 (헛다리 — 시간 낭비)
- config(streaming/typing) 변경·롤백 → 무관 (버전 버그라 config 무의미)
- gateway 재시작 4회 / gw2 중지 / 5.22 clean reinstall → 전부 무효 (같은 버전 같은 버그)
- claude 바이너리 (`claude --print` 정상), cliBackends 설정, gateway 경합 → 전부 정상

## 복구 (검증됨)
1. **5.27 업그레이드**: `npm install -g openclaw@2026.5.27` → harness 등록됨.
2. **모델 등록 (5.27 신규 의무)**: 5.27은 `models.providers.anthropic.models[]`에 사용 모델 명시 요구 (5.22는 안 함). 정확한 형식:
   ```json
   {"id":"claude-opus-4-8","name":"claude-opus-4-8","reasoning":true,
    "input":["text","image"],"contextWindow":200000,"contextTokens":200000,
    "maxTokens":8192,"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},
    "api":"anthropic-messages"}
   ```
   - ⚠️ `api` 값은 **"anthropic-messages"** (not "anthropic"). 유효값: openai-completions/openai-responses/anthropic-messages/google-generative-ai/ollama 등.
   - `name` 필드 필수 (없으면 "name: Invalid input").
3. **gw2 top-level token 제거**: 5.27이 top-level `channels.discord.token`을 "default" account로 처리 → gw2 secrets에 없어 "token unavailable" 크래시. gw2 config에서 top-level `token`/`applicationId`/`defaultTo` 제거.
4. **systemd reset-failed**: 5회 startup 실패 시 "Start request repeated too quickly"로 포기 → `systemctl --user reset-failed <svc>` 후 start.

## 검증
- JARVIS "복구완료"/"대표님 안녕하십니까 🦑" 정상 응답. opus exec 3, 모든 error 0.
- EVE typing 노이즈는 무시 결정 (기능 영향 0, JARVIS 정상).

## 재발 방지 (영구)
- **OpenClaw 버전 자동 업데이트 = 시한폭탄.** 안정 버전 고정 검토 (npm 글로벌이라 자동 업데이트 위험).
- 버전 업 후 반드시 **claude 봇 Discord 응답 실측** (heartbeat 성공에 속지 말 것 — Discord user 메시지만 harness 경유).
- 새 OpenClaw 버전 도입 시 `providers.<provider>.models[]` 등록 의무 여부 확인 (5.27부터 의무화).
- 봇 무응답 진단 순서: ① harness 에러 ② model 에러 ③ startup invalid(config 스키마) ④ systemd 카운터 — 로그 `journalctl --user -u openclaw-gateway.service`에서 정확한 에러 문구 확인 후 타겟 수정 (재시작 난사 금지 — 하향 나선).

## 관련
- [[pitfall-226-openclaw-native-2gateway-split]] — gw2 구조 (top-level token 함정)
- [[pitfall-224-wsl2-instance-idle-timeout-gateway-death]]
- CLAUDE.md STICKY DECISIONS P-229
