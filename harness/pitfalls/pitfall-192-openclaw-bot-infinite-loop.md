# P-192: OpenClaw 3봇 무한 대화 루프 (alias fallback + allowBots=true 조합)

- **발견**: 2026-05-20
- **영향**: 3봇이 서로 멘션 응답하며 무한 핑퐁. 대표님 개입까지 중단 불가. API/토큰 무제한 소모 위험.

## 증상

대표님이 의견 질문 1회 → 뇽죵 응답에 `@jamesclaw-cc @ollama claw` 포함 → 두 봇 응답 → 응답에 `@nyongjong claw` 포함 → 뇽죵 또 응답 → 무한.

스크린샷에서 수백 줄 봇끼리 대화 확인됨.

## 원인 (3 요소 결합)

1. **P-191 Layer 2 alias fallback**: 봇이 응답 본문에 평문 "@jamesclaw-cc" 써도 다른 봇이 트리거됨
2. **`allowBots: true`** in OpenClaw guild config: 봇 → 봇 메시지 차단 안 됨 (의도된 협업 위해 켰음)
3. **ORCHESTRATION §5 사이클 제한 = LLM 텍스트 지시만**: 코드 레벨 강제력 없음. codex/gemma4가 무시 가능.

## 해결 (P-192 Layer 코드 강제)

### 두 relay (`jamesclaw-cc-relay`, `ollama-relay`) `shouldRespond` 함수 강화

```javascript
async function shouldRespond(msg) {
  // ... 기존 ALLOWED·자기 자신 체크 ...

  // P-192_LOOP_GUARD: 평문 alias 매칭은 사람이 보낸 메시지에서만 (봇 무시)
  const ALIAS_MENTIONED = !msg.author.bot && ALIAS_LIST.some(a => msg.content.toLowerCase().includes(a));

  // ... mention/role/reply 체크 ...

  // P-192_LOOP_GUARD: 직전 5 메시지 중 사람 1명도 없으면 응답 거부
  const recent = await msg.channel.messages.fetch({ limit: 5, before: msg.id });
  const allBots = recent.size >= 3 && recent.every(m => m.author.bot);
  if (allBots) { return false; }

  return true;
}
```

### 작동 원리

- **봇이 평문 "@jamesclaw-cc" 써도** 무반응 (alias는 사람용)
- **봇이 real ID-mention `<@1506554520761536603>` 사용** → 협업 트리거 (의도된 사용)
- **연속 5 메시지가 모두 봇이면** 추가 응답 차단 (사람 없는 채널에서 자기들끼리 떠들면 정지)

## 검증 (대표님 테스트 필요)

1. 대표님이 `@nyongjong claw 의견 질문` → 뇽죵이 `<@1506554520761536603>` real mention → james 응답
2. james 응답이 평문 "@nyongjong claw" 포함해도 뇽죵 트리거 안 됨 (봇 → 봇 평문 무시)
3. 만약 ID-mention 체인이 사람 없이 5회 이상 이어지면 자동 정지

## 비상 정지 절차

```bash
wsl -d Ubuntu sh -c "systemctl --user stop openclaw-gateway.service jamesclaw-cc-relay.service ollama-relay.service"
```

## 재발 방지

- 새 봇 추가 시 `shouldRespond`에 동일 P-192 guard 적용 필수
- `allowBots: true` 운영 시 반드시 코드 레벨 사이클 제한 (LLM 지시만으로는 불충분)
- 의견·합의 패턴 도입 시 사전 무한루프 시뮬레이션 — alias 트리거가 봇 응답에 들어갈 가능성 검토

## 관련

- [[pitfall-191-openclaw-codex-cannot-fire-discord-mentions]] — Layer 2 alias 도입의 부작용
- ORCHESTRATION.md §5 (사이클 제한) — 텍스트 지시 보강 layer로 유지
- AGENTS.md §1-A·1-B (의견 질문 협업 트리거) — 코드 가드와 병행
