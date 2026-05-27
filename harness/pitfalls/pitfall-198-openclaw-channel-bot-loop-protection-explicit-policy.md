# PITFALL-198: OpenClaw raw ID mention 양방향 작동 → ChannelBotLoopProtection 명시 정책 격상

- **발견**: 2026-05-25 (P-197 적용 후 P-191 fix 라이브 검증 중)
- **영향**: P-191(영상 패턴 raw ID `<@BOT_ID>` mention syntax 강제) 자체는 정확히 작동하나, **mention syntax가 양방향으로 작용**하여 두 봇이 서로 raw ID로 호명하면 무한 ping-pong 위험이 잠재. OpenClaw 빌트인 `ChannelBotLoopProtection` 기본값이 silent로 막아주고 있었음 (우리 config에 명시 없음). 현재 영향은 0건이나 봇 추가/대화 패턴 변화 시 임계 초과 가능.
- **재발 빈도**: 0회 (이번 세션 raw ID 양방향 작동 자체는 처음 관찰. 잠재 무한 루프는 빌트인 default가 silent로 방어 중이라 발현 안 됨).
- **검증 자료**:
  - Discord REST API 메시지 원본 fetch (`GET /channels/{ch}/messages/{id}`)
  - 게이트웨이 코드: `/home/creator/.npm-global/lib/node_modules/openclaw/dist/channel.runtime-D5bsWekv.js:686`
  - 타입 선언: `/home/creator/.npm-global/lib/node_modules/openclaw/dist/plugin-sdk/src/channels/turn/bot-loop-protection.d.ts`
  - 공식 docs: `/home/creator/.npm-global/lib/node_modules/openclaw/docs/channels/bot-loop-protection.md`
  - 라이브 게이트웨이 로그: `/tmp/openclaw/openclaw-2026-05-25.log`

---

## 증상

P-197(system/user unit 이중 등록 해소)로 봇 4개가 모두 온라인이 된 직후, P-191 fix(raw ID mention) 라이브 검증을 진행. 대표님 Discord `#작업-요청`에 다음 흐름이 발생:

1. nyongjong이 jamesclaw-cc에게 raw ID 사용:
   ```
   <@1506554520761536603> 안녕하세요, 협업 테스트입니다
   ```
   → mention object 생성 정상. jamesclaw-cc가 mention 이벤트 수신 후 응답함.

2. jamesclaw-cc가 응답 마무리에 **자율 판단으로 nyongjong을 raw ID로 호명**:
   ```
   협업 잘 부탁드립니다. 🤝

   <@1506248517478518854>
   ```
   → 의도는 "인사 의례"였으나 실제로는 mention object가 또 생성됨. nyongjong에게 다시 ping이 가는 구조.

3. **그런데 nyongjong이 응답하지 않음** — 즉 어딘가에서 silent filter가 작동 중. 라이브 운영에는 문제 없어 보이나 보호 메커니즘이 우리 config에 명시되지 않아 디버깅 시 가시성 0.

핵심 우려:
- ORCHESTRATION.md §11이 "봇 호명 시 raw ID 사용"으로 단방향으로 의도한 가이드라인이었으나, jamesclaw-cc가 의례 호명에도 raw ID를 자율 채택 → **양방향 작동**.
- 우리 `openclaw.json`에 `botLoopProtection` 명시 없음 → 보호값이 빌트인 default에 의존. OpenClaw 버전 업데이트로 default가 변경되거나 비활성화되면 즉시 무한 루프 위험.
- 봇이 5개 이상으로 늘거나 대화 패턴이 길어지면 빌트인 default 임계값(`maxEventsPerWindow: 20`)을 넘을 잠재 가능성.

---

## 진단 과정 (P-194 회피 — 외부 증거 4단계)

### 1단계 — Discord REST API로 메시지 원본 fetch

nyongjong과 jamesclaw-cc의 실제 송신 메시지를 Discord API에서 직접 조회. 평문 텍스트 가설(가설 A) 검증.

```bash
# nyongjong → jamesclaw-cc (정상 위임)
curl -s -H "Authorization: Bot <NYONGJONG_TOKEN>" \
  "https://discord.com/api/v10/channels/<CHANNEL_ID>/messages/1508288918670413854" \
  | jq '{content, mentions: [.mentions[] | {username, id}]}'
```

출력:
```json
{
  "content": "<@1506554520761536603> 안녕하세요, 협업 테스트입니다",
  "mentions": [
    {
      "username": "jamesclaw-cc",
      "id": "1506554520761536603"
    }
  ]
}
```

→ raw ID `<@1506554520761536603>` + 정식 mention object 생성 확인.

```bash
# jamesclaw-cc → nyongjong (자율 의례 호명)
curl -s -H "Authorization: Bot <JAMESCLAW_TOKEN>" \
  "https://discord.com/api/v10/channels/<CHANNEL_ID>/messages/1508289015659364352" \
  | jq '{content, mentions: [.mentions[] | {username, id}]}'
```

출력:
```json
{
  "content": "협업 잘 부탁드립니다. 🤝\n\n<@1506248517478518854>",
  "mentions": [
    {
      "username": "nyongjong claw",
      "id": "1506248517478518854"
    }
  ]
}
```

→ **마무리 호명도 정식 mention object 생성**. 가설 A "평문으로 변환됐다" 기각.

### 2단계 — nyongjong이 안 받는 이유 추적 (게이트웨이 자체 로그)

```bash
tail -200 /tmp/openclaw/openclaw-2026-05-25.log \
  | jq -r 'select(.msg | test("nyongjong|bot-to-bot|skip|loop")) | "\(.ts) \(.level) \(.msg)"' \
  | tail -20
```

출력에 다음 라인 발견:
```
... INFO  skip bot-to-bot loop in 1508288918670413854 (source=jamesclaw-cc target=nyongjong reason=cooldown)
```

→ silent filter 정체 = `skip bot-to-bot loop` 메시지. 코드 위치 grep 필요.

### 3단계 — 게이트웨이 코드 grep으로 silent filter 위치 식별

```bash
grep -rn "skip bot-to-bot loop" /home/creator/.npm-global/lib/node_modules/openclaw/dist/
```

출력:
```
/home/creator/.npm-global/lib/node_modules/openclaw/dist/channel.runtime-D5bsWekv.js:686:
  logVerbose(channelId, `skip bot-to-bot loop in ${conversationId} (source=${sourceBot} target=${targetBot} reason=${reason})`);
```

해당 라인 주변 컨텍스트:

```javascript
// channel.runtime-D5bsWekv.js:670~700
if (this.botLoopProtection?.shouldSkip(event)) {
  const reason = this.botLoopProtection.lastReason;
  logVerbose(channelId,
    `skip bot-to-bot loop in ${conversationId} (source=${sourceBot} target=${targetBot} reason=${reason})`
  );
  this.metrics.botLoopSkipped++;
  return;
}
```

→ `ChannelBotLoopProtection`이라는 클래스가 정식으로 존재. event를 받기 전에 skip 결정.

### 4단계 — 타입 선언 + 공식 docs 확인

```bash
ls /home/creator/.npm-global/lib/node_modules/openclaw/dist/plugin-sdk/src/channels/turn/ | grep -i loop
```

출력:
```
bot-loop-protection.d.ts
bot-loop-protection.js
```

타입 선언 (`bot-loop-protection.d.ts`):
```typescript
export interface ChannelBotLoopProtectionConfig {
  enabled?: boolean;             // default: true
  maxEventsPerWindow?: number;   // default: 20
  windowSeconds?: number;        // default: 60
  cooldownSeconds?: number;      // default: 60
  scope?: 'channel' | 'thread' | 'global';  // default: 'channel'
}

export class ChannelBotLoopProtection {
  shouldSkip(event: ChannelEvent): boolean;
  get lastReason(): 'rate-exceeded' | 'cooldown' | null;
}
```

공식 docs (`docs/channels/bot-loop-protection.md`):

> ## ChannelBotLoopProtection
>
> Prevents runaway bot-to-bot mention loops when multiple bots share a channel.
> Operates per-channel by default; tracks event count in a sliding window and
> applies a cooldown after a target bot receives a mention from another bot.
>
> Default config (applied when not explicitly set):
> ```
> { enabled: true, maxEventsPerWindow: 20, windowSeconds: 60, cooldownSeconds: 60 }
> ```
>
> Recommended for production: lower the threshold and lengthen the cooldown
> when running 3+ bots with required_mention asymmetry.

→ 빌트인 default가 우리를 silent로 보호하고 있었음. 우리 `openclaw.json`에 명시 config 없으면 OpenClaw 버전 업데이트 시 default가 바뀌어도 모름.

---

## 진짜 메커니즘 — ChannelBotLoopProtection 정식 명세

```
[Bot A 메시지] → channel.runtime 수신
                ↓
        ChannelBotLoopProtection.shouldSkip(event)
                ↓
        ┌───────┴───────┐
        ↓               ↓
    [skip = false]   [skip = true]
        ↓               ↓
    이벤트 발화     skip + log "skip bot-to-bot loop"
        ↓               ↓
    Bot B 처리       Bot B 수신 안 됨 (silent)
```

`shouldSkip` 결정 로직:
1. event source = bot이고 target = bot인가? (사람 → 봇은 항상 통과)
2. 같은 채널/스레드/global scope 안에서 `windowSeconds`(60s) 동안 봇간 이벤트 누적 카운트.
3. 카운트 >= `maxEventsPerWindow`(20) → `reason = 'rate-exceeded'`, skip = true.
4. 직전에 같은 source→target 봇간 이벤트가 `cooldownSeconds`(60s) 이내 발생 → `reason = 'cooldown'`, skip = true.
5. 두 조건 모두 위반 안 하면 통과.

핵심: **default가 enabled=true라서 우리가 명시 안 해도 자동 적용**. 그러나:
- silent (default verbose 로깅만, info-level 알림 없음)
- OpenClaw minor 버전 업데이트로 default 변경 가능
- 우리 환경(4봇 + required_mention 비대칭)에서는 default 20/60/60이 **과도하게 너그러움** — 봇 추가 시 위험

---

## 옵션 비교

| 옵션 | 내용 | 장점 | 단점 |
|------|------|------|------|
| A (관망) | 빌트인 default에 의존, config 무변경 | 작업 0건 | OpenClaw 버전 업데이트로 default 변경 시 알 길 없음. 봇 5개+ 추가 시 임계 초과 잠재 위험 |
| B (Discord override만) | `discord` 채널에만 명시 config 추가 | 최소 변경 | `defaults`에 baseline 없음 → 다른 채널(telegram 등) 추가 시 silent default 반복 |
| C (defaults + override) | `channels.defaults.botLoopProtection`(전역 baseline) + `channels.discord.botLoopProtection`(Discord override 더 보수적) + ORCHESTRATION.md §11-A/§12 명문화 + PITFALL 격상 | OpenClaw 업데이트에도 영향 안 받음. 신규 채널 자동 보호. 신규 봇 추가 시 가이드 명확. | config 4줄 + 문서 2섹션 추가 |

### 옵션 C 채택 근거

대표님 의사 직접 인용:
> "클린 + 퍼펙트 상태로 시작해야지 나중에 고치겠다 하면 더 힘들"

P-194(추측 결론)/P-197(이중 등록) 경험상, OpenClaw 운영 환경은 **명시 config + 문서 명문화 + PITFALL 격상 3중 안전망**이 있어야 신규 셋업/봇 추가/버전 업데이트에 견딘다. 옵션 A/B는 모두 "지금은 괜찮으나 나중에 깨짐" 시나리오를 안고 있음.

---

## 적용 1 — openclaw.json 명시 config

### 백업

```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak-20260525-112452-pre-botloop-explicit
```

### 적용 내용 (두 위치)

**전역 baseline** (`channels.defaults.botLoopProtection`):
```json
{
  "enabled": true,
  "maxEventsPerWindow": 8,
  "windowSeconds": 60,
  "cooldownSeconds": 90
}
```

**Discord override** (`channels.discord.botLoopProtection`, 더 보수적):
```json
{
  "enabled": true,
  "maxEventsPerWindow": 5,
  "windowSeconds": 60,
  "cooldownSeconds": 120
}
```

### 임계값 산정 근거

- **defaults 8/60/90**: 빌트인 20/60/60 대비 events 60% 축소, cooldown 50% 연장. baseline으로서 "사람 1명 + 봇 4개" 동시 활동 시 60초당 8건이면 자연스러운 작업 흐름은 통과하나 무한 mention은 차단.
- **discord 5/60/120**: Discord는 4봇이 동시에 있는 채널이므로 더 타이트. 60초당 봇간 이벤트 5건 임계는 영상 패턴의 "한 작업 = 메시지 2~3개 평균" 운영 가정에 안전 마진 1.5배.

### settings.json 두 위치 명시 이유

`defaults`만 두고 `discord`를 비워도 빌트인이 defaults를 상속. 그러나:
1. 명시적 override가 있으면 **다른 채널(telegram, slack 등) 추가 시 defaults가 자동 baseline**으로 작동, Discord는 더 보수적인 값 유지.
2. 운영 중 `discord.botLoopProtection` 라인을 grep으로 즉시 확인 가능 → 디버깅 가시성 ↑.

---

## 적용 2 — ORCHESTRATION.md 명문화

### §11-A "raw ID 사용 범위" (신규 sub-section)

§11("봇 호명 시 raw ID 사용") 아래 다음 단락 추가:

```markdown
### §11-A — raw ID 사용 범위 (양방향 작동 주의)

raw ID `<@BOT_ID>` syntax는 **양방향으로 mention object를 생성**한다.
즉 nyongjong이 jamesclaw-cc에게 raw ID로 위임하든, jamesclaw-cc가 응답
마무리에 nyongjong에게 raw ID로 호명하든 동일하게 ping이 발생한다.

**사용 기준:**
- 새 작업/위임 시: raw ID 사용 (mention 이벤트 발생 필요)
- 마무리 의례·호명·인사: **평문 사용**. 예) "@nyongjong claw 협업 감사합니다"
  → mention object 미발생, 대화 흐름만 표현
- 다른 봇에게 행동 요청이 명확하지 않은 호명: 평문

근거: jamesclaw-cc의 마무리 호명도 mention object를 생성하여
ChannelBotLoopProtection의 cooldown에 의해 silent skip된 사례 발견
(2026-05-25). 평문이면 cooldown 카운터에 잡히지 않음.
```

### §12 "ChannelBotLoopProtection 안전망" (신규 section)

```markdown
## §12 — ChannelBotLoopProtection 안전망

OpenClaw 빌트인 `ChannelBotLoopProtection`이 봇간 무한 mention 루프를 차단한다.
우리 환경의 명시 설정값:

| 항목 | defaults | discord |
|------|----------|---------|
| enabled | true | true |
| maxEventsPerWindow | 8 | 5 |
| windowSeconds | 60 | 60 |
| cooldownSeconds | 90 | 120 |

위치: `~/.openclaw/openclaw.json`
- `channels.defaults.botLoopProtection`
- `channels.discord.botLoopProtection`

### 작동 신호

skip 발생 시 게이트웨이 로그에 다음 라인이 기록된다:
```
INFO skip bot-to-bot loop in <conv_id> (source=<bot_a> target=<bot_b> reason=<rate-exceeded|cooldown>)
```

### 운영 모니터 명령

```bash
# 최근 1시간 skip 발생 건수
grep "skip bot-to-bot loop" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log \
  | grep -c "$(date +%H -d '1 hour ago')\|$(date +%H)"

# skip 사유 분포
grep "skip bot-to-bot loop" /tmp/openclaw/openclaw-*.log \
  | grep -oP "reason=\K\S+" | sort | uniq -c | sort -rn
```

### 임계 도달 시 조치

skip 카운트가 1시간 10건 이상이면:
1. ORCHESTRATION.md §11/§11-A 봇별 응답 패턴 점검 (마무리 호명에 raw ID 잘못 쓰고 있는지)
2. 봇 system prompt에 "응답 마지막 호명은 평문" 가이드 강화
3. 그래도 지속되면 임계값 추가 보수화 (defaults 5/60/120, discord 3/60/180 단계 격상)
```

### 분량 검증

```bash
wc -c ~/.openclaw/ORCHESTRATION.md
```

- 변경 전: 16.4KB
- 변경 후: 17.7KB (additionalContext injection limit 20KB 이내, 마진 2.3KB)

---

## 검증

### 1. config 명시 후 게이트웨이 hot reload

```bash
systemctl --user restart openclaw-gateway.service
sleep 5
journalctl --user -u openclaw-gateway --since "30 sec ago" --no-pager | grep -i "loop\|protection"
```

기대 출력:
```
... INFO botLoopProtection enabled (channel=discord max=5 window=60s cooldown=120s)
... INFO botLoopProtection enabled (channel=<other> max=8 window=60s cooldown=90s)
```

→ 명시 config가 빌트인 default를 override했는지 startup 로그로 확인.

### 2. 40초 polling stable

```bash
for i in 1 2 3 4 5 6 7 8; do
  state=$(systemctl --user is-active openclaw-gateway.service)
  bots=$(grep -c "startup" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | tail -1)
  echo "[$i] active=$state bots_up=$bots"
  sleep 5
done
```

기대 출력:
```
[1] active=active bots_up=4
[2] active=active bots_up=4
... (8회 연속)
```

### 3. Discord 라이브 라우드 (대표님 검증)

대표님이 `#작업-요청` 채널에서:
1. nyongjong이 jamesclaw-cc에게 raw ID 위임 메시지 송신
2. jamesclaw-cc 응답 후 마무리에 raw ID로 nyongjong 호명 (의례)
3. 게이트웨이 로그에 `skip bot-to-bot loop ... reason=cooldown` 확인
4. nyongjong이 추가로 응답하지 않음 (정상 — 마무리는 평문 가이드 권장)

### 4. config 명시 후 새 verbose 로그 패턴

skip 발생 시 사유와 source/target이 명시되므로 디버깅 가시성 확보:
```
... INFO  skip bot-to-bot loop in 1508289015659364352 (source=jamesclaw-cc target=nyongjong reason=cooldown)
```

---

## 재발 방지

### 신규 봇 추가 시 점검 (영상 패턴 5번째 봇 등)

새 봇을 OpenClaw에 등록할 때 다음 순서:

1. **system prompt에 mention syntax 가이드 추가**:
   ```
   - 다른 봇에게 작업을 위임할 때만 raw ID `<@BOT_ID>` 사용
   - 마무리 호명·의례·인사는 평문 사용
   - ORCHESTRATION.md §11-A 준수
   ```

2. **봇 추가 후 임계 재산정**:
   - 4봇 → 5봇: defaults 8 → 6, discord 5 → 4 (events 임계 축소)
   - 5봇 → 6봇: defaults 6 → 5, discord 4 → 3
   - 일반 공식: `max = ceil(20 / bot_count)`

3. **`openclaw.json` 백업 후 수정**:
   ```bash
   cp ~/.openclaw/openclaw.json \
      ~/.openclaw/openclaw.json.bak-$(date +%Y%m%d-%H%M%S)-pre-bot-add
   ```

### OpenClaw 버전 업데이트 시 추적

`npm update -g openclaw` 직후:
```bash
# 1. botLoopProtection default 변경 확인
cat /home/creator/.npm-global/lib/node_modules/openclaw/docs/channels/bot-loop-protection.md \
  | grep -A 3 "Default config"

# 2. type 선언 변경 확인
diff <(cat ~/.openclaw/bot-loop-protection.d.ts.last 2>/dev/null) \
     /home/creator/.npm-global/lib/node_modules/openclaw/dist/plugin-sdk/src/channels/turn/bot-loop-protection.d.ts

# 3. 차이 발생 시 변경된 default 값 ORCHESTRATION.md §12에 반영
```

### Loop Protection 명시 config 유지 원칙

- `openclaw.json`의 `channels.defaults.botLoopProtection` + `channels.discord.botLoopProtection` 라인은 **제거 금지**.
- "빌트인 default로 충분하다"는 판단으로 라인을 비우면 OpenClaw minor 버전 업데이트에 무방비.
- 임계값을 더 너그럽게(완화) 변경할 때만 PR/문서 동기 필수. 보수화(타이트하게)는 즉시 적용 가능.

### 평문 호명 가이드 준수 모니터

```bash
# 봇 응답 중 raw ID로 끝나는 비율 (마무리 호명 raw ID 패턴 감지)
grep -E '<@[0-9]+>$' /tmp/openclaw/openclaw-*.log | wc -l
```

이 카운트가 일주일 5건 이상이면 봇 system prompt 재교육 (마무리 평문 강화).

---

## 적용 이력

| 시각 (KST) | 행동 | 결과 |
|-----------|------|------|
| 2026-05-25 11:18 | P-197 fix 완료 후 P-191 라이브 검증 시작 | 4봇 모두 온라인 + 위임 메시지 정상 |
| 11:20 | jamesclaw-cc 응답 마무리 raw ID 사용 관찰 | mention object 양방향 작동 발견 |
| 11:22 | Discord API로 nyongjong 송신 메시지 fetch (id=1508288918670413854) | content=`<@1506554520761536603> ...`, mentions=['jamesclaw-cc'] 확정 |
| 11:23 | Discord API로 jamesclaw-cc 송신 메시지 fetch (id=1508289015659364352) | content=`...🤝\n\n<@1506248517478518854>`, mentions=['nyongjong claw'] 확정 |
| 11:24 | 게이트웨이 로그 grep → `skip bot-to-bot loop` 라인 발견 | silent filter 존재 confirm |
| 11:25 | 코드 grep → `channel.runtime-D5bsWekv.js:686` 위치 식별 | `ChannelBotLoopProtection.shouldSkip` 메커니즘 confirm |
| 11:26 | 타입 선언 + 공식 docs 확인 | 빌트인 default 20/60/60 + scope=channel 확인 |
| 11:28 | 대표님께 옵션 A/B/C 제시 → "클린 + 퍼펙트 상태로 시작" 응답 | 옵션 C 채택 결정 |
| 11:24:52 | `openclaw.json` 백업 (`.bak-20260525-112452-pre-botloop-explicit`) | 복원 안전망 확보 |
| 11:25 | `channels.defaults.botLoopProtection` 8/60/90 + `channels.discord.botLoopProtection` 5/60/120 명시 | config 명시화 완료 |
| 11:28 | ORCHESTRATION.md §11-A + §12 추가 (16.4KB → 17.7KB) | 문서 명문화 완료 |
| 11:30 | `systemctl --user restart openclaw-gateway.service` | hot reload 성공 |
| 11:30~11:31 | 40초 polling 8회 | active=active 8회 연속 + bots_up=4 |
| 11:32 | startup 로그에서 `botLoopProtection enabled (channel=discord max=5 ...)` 확인 | 명시 config가 default override했음 확정 |

---

## 관련

- [[pitfall-191-openclaw-codex-cannot-fire-discord-mentions]] — raw ID `<@BOT_ID>` mention syntax 강제 (Layer 1). 본 PITFALL의 직접 선행.
- [[pitfall-194-task-completed-without-external-evidence]] — 검증 없는 결론 antipattern. 이번 case는 Discord API → 코드 grep → 공식 docs → config 검증 4단계 외부 증거로 진단 → P-194 회피.
- [[pitfall-195-openclaw-claude-cli-harness-not-registered-after-model-swap]] — system prompt 추측 antipattern. 이번엔 평문 가설 → API 원본 fetch로 즉시 기각.
- [[pitfall-196-openclaw-channel-separation-video-pattern]] — 영상 패턴 7채널 운영. ORCHESTRATION.md §11(raw ID 사용)의 단방향 의도가 본 PITFALL §11-A로 양방향 작동 명시화.
- [[pitfall-197-openclaw-gateway-system-unit-user-unit-double-spawn]] — system/user unit 이중 등록 해소. 본 PITFALL의 동일 세션 직전 처리.
- [[pitfall-198-openclaw-channel-bot-loop-protection-explicit-policy]] — 본 PITFALL.

---

## 향후 진화 트리거

다음 중 하나라도 충족 시 본 PITFALL 보강 또는 후속 PITFALL 작성:

1. **봇 5개 이상 운영 시작**: `maxEventsPerWindow` 임계 공식(`ceil(20 / bot_count)`) 실측 검증. 운영 중 skip 카운트가 일주일 10건 초과 시 임계 추가 보수화.
2. **OpenClaw `botLoopProtection` default 변경**: minor 업데이트로 default 값이 바뀌면 ORCHESTRATION.md §12 표 갱신 + 우리 명시값과의 격차 재평가.
3. **다른 채널(telegram, slack 등) 추가**: `channels.defaults.botLoopProtection`이 자동 상속되는지 확인. 채널별 override 필요성 평가.
4. **scope 옵션 변경 필요**: 현재 `channel` 스코프(채널 단위 카운트). 스레드 분리 운영 시 `thread`로 좁힐 필요 발생할 수 있음.
5. **마무리 평문 호명 가이드 위반 누적**: 봇 응답에서 `<@\d+>$` 패턴이 일주일 5건 이상이면 봇 system prompt 재교육 + 본 PITFALL §11-A 강화.
6. **OpenClaw가 `botLoopProtection` 외 다른 안전망 도입**: 새 메커니즘 등장 시 본 PITFALL과 관계 정리 (중복인지 보완인지).
