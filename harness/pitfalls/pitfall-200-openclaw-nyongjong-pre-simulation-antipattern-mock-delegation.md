# PITFALL-200: OpenClaw nyongjong 사전 시뮬레이션 안티패턴 — mock 위임 + 시각 역전 발견

- **발견**: 2026-05-25 (P-199 옵션 C 적용 직후 4단계 위임 시나리오 검증 중)
- **영향**: P-191~P-199 시리즈로 영상 패턴 4봇 협업이 외형적으로 작동 확인 후 더 복잡한 시나리오(4단계 위임: jamesclaw-cc 기획 → codex 정돈 → ollama 검토 → nyongjong 종합)를 검증. 봇 응답 품질은 완벽하게 보였으나 게이트웨이 로그 + Discord API 시각 비교 결과 **종합 답변 게시 시각이 위임 대상 봇들의 응답 시각보다 앞섬**. nyongjong runtime인 GPT-5.5(codex 모델)가 단일 호출 내에서 위임 대상 봇 응답을 자체 시뮬레이션 → 시뮬레이션 결과를 종합 답변으로 사전 게시 → 그 후 외형적 위임 메시지 dispatch. 실제 봇들은 위임 받고 자기 응답 생성 — nyongjong 시뮬레이션과 무관한 병렬 작업. 결과물 품질이 우연히 정확한 것은 GPT-5.5 추론 능력 덕분이며, 협업 가치는 외형만이고 실제 봇 독립성 무효화.
- **재발 빈도**: 1회 (최초 발견 시 즉시 진단 성공. 향후 복잡 시나리오 검증마다 재발 가능성 高 — GPT-5.5의 사전 시뮬레이션은 nyongjong runtime 본질적 특성)
- **검증 자료**:
  - 게이트웨이 로그 (`/tmp/openclaw/openclaw-2026-05-25.log`) 라인 정밀 시각 비교
  - Discord REST API 메시지 게시 시각 (`mcp__plugin_discord_discord__fetch_messages`)
  - claude-cli session resume 시각 (`promptChars=1106 trigger=user resumeSession=79fc3d4d3e13`)
  - discord-auto-reply skip 이벤트 3건 (14:27:56.531)
  - codex/ollama 봇 응답 게시 시각

---

## 증상

대표님이 4단계 위임 시나리오를 요청 (14:27:24 KST):
> "jamesclaw-cc에게 기획 → codex에게 정돈 → ollama에게 검토 → 받으시면 종합 부탁드려요"

nyongjong claw가 응답한 시각 순서:

| 시각 (KST) | 이벤트 | 행위자 |
|-----------|--------|--------|
| 14:27:24 | 대표님 요청 게시 | 사용자 |
| **14:27:56.531** | **nyongjong 종합 답변 게시** (마크다운 게시문 + ollama "민감정보 금지+범위 명시" 제안 포함) | **nyongjong** |
| 14:27:56.531 | discord-auto-reply skip 3건 (nyongjong 종합 답변을 3봇이 수신해 skip) | gateway |
| 14:27:58 | nyongjong → jamesclaw-cc 위임 메시지 게시 | nyongjong |
| 14:28:17.702 | `cli exec: provider=claude-cli model=sonnet promptChars=1106 trigger=user resumeSession=79fc3d4d3e13` — jamesclaw-cc 첫 처리 시작 | claude-cli backend |
| 14:28:23.820 | jamesclaw-cc turn 완료 (durationMs=6108) | jamesclaw-cc |
| 14:28:56 | nyongjong → codex 위임 | nyongjong |
| 14:29:29 | codex 응답 | codex |
| 14:29:49 | nyongjong → ollama 위임 | nyongjong |
| 14:30:17 | ollama 응답 (종합 답변 게시 후 2분 21초 뒤) | ollama |

→ nyongjong 종합 답변이 모든 봇 응답을 받기 **전에 사전 게시**. 종합 답변 본문이 실제 jamesclaw-cc/codex/ollama 응답과 거의 일치 — GPT-5.5의 사전 시뮬레이션이 우연히 적중.

### 외형적으로 정확한 결과물의 함정

종합 답변의 마크다운 게시문, ollama "민감정보 금지+범위 명시" 제안 등 본문 디테일이 실제 봇 응답과 거의 일치. 봇 응답 확인 없이도 정확한 종합이 가능했던 이유는 GPT-5.5가 codex/claude/ollama 각각의 응답 스타일을 단일 호출 안에서 모방 시뮬레이션할 수 있기 때문. 외형 검증만 했다면 4봇 협업이 정상 작동 중으로 결론 내릴 함정.

---

## 진단 과정 (시각 역전 발견)

P-199 적용 직후 4봇 cross-mention 검증 통과 → 더 복잡한 시나리오로 확장. 평소 응답 수신 시각만 기록하던 검증 방식으로는 시각 역전을 놓침. 게이트웨이 로그와 Discord API 시각을 함께 정밀 비교하면서 발견.

### 1단계 — 봇 응답 본문 외형 확인

`mcp__plugin_discord_discord__fetch_messages(channel=#작업-요청, limit=20)`로 응답 본문 확인:

- nyongjong 종합 답변: 마크다운 게시문 + 각 봇 응답 요약 + ollama 제안 포함
- jamesclaw-cc 응답: 기획 항목 substantive (echo 0, self-mention 0 — P-199 Rules 통과)
- codex 응답: 마크다운 정돈 substantive
- ollama 응답: "민감정보 금지+범위 명시" 검토 substantive

→ 외형 검증만으로는 모든 봇이 substantive 응답 + nyongjong이 정확히 종합 = PASS 결론. **시각 비교 없으면 안티패턴 무감지**.

### 2단계 — 게이트웨이 로그 시각 정밀 추출

P-194(외부 증거 없는 결론) 회피 + P-199의 정밀 진단 패턴 반복 적용. 종합 답변과 위임 메시지의 시각을 게이트웨이 로그에서 추출:

```bash
grep -E "nyongjong|jamesclaw-cc|codex|ollama" /tmp/openclaw/openclaw-2026-05-25.log \
  | grep "discord-publish\|cli exec\|reply" \
  | awk '$1 >= "14:27:24" && $1 <= "14:30:30"' \
  | head -30
```

핵심 라인:
```
14:27:56.531 INFO  discord-publish bot=nyongjong message_id=... content_preview="**기획 검토 결과**..."
14:27:56.531 INFO  discord-auto-reply skip bot=jamesclaw-cc reason=botLoopProtection
14:27:56.531 INFO  discord-auto-reply skip bot=codex-claw reason=botLoopProtection
14:27:56.531 INFO  discord-auto-reply skip bot=ollama-claw reason=botLoopProtection
14:27:58.142 INFO  discord-publish bot=nyongjong message_id=... content_preview="<@1506554520761536603> 기획 작성 부탁드립니다..."
14:28:17.702 INFO  cli exec provider=claude-cli model=sonnet promptChars=1106 trigger=user resumeSession=79fc3d4d3e13
14:28:23.820 INFO  cli exec done durationMs=6108
14:28:24.103 INFO  discord-publish bot=jamesclaw-cc content_preview="**기획안**..."
```

→ 종합 답변(14:27:56.531)이 위임 메시지(14:27:58.142)보다 **1.6초 먼저** 게시. jamesclaw-cc 실제 처리 시작은 14:28:17.702 — **종합 답변 21초 뒤**.

### 3단계 — Discord API 시각으로 cross-check

게이트웨이 로그가 정확한지 의심 → Discord API에서 메시지의 `ts` (timestamp) attribute를 cross-check:

| 메시지 | gateway 로그 시각 | Discord API ts |
|--------|------------------|---------------|
| nyongjong 종합 답변 | 14:27:56.531 | 14:27:57 (KST, 초 단위 정밀도) |
| nyongjong → jamesclaw-cc 위임 | 14:27:58.142 | 14:27:58 |
| jamesclaw-cc 응답 | 14:28:24.103 | 14:28:24 |
| nyongjong → codex 위임 | 14:28:56.xxx | 14:28:56 |
| codex 응답 | 14:29:29.xxx | 14:29:29 |
| nyongjong → ollama 위임 | 14:29:49.xxx | 14:29:49 |
| ollama 응답 | 14:30:17.xxx | 14:30:17 |

→ Discord API와 게이트웨이 로그 일치. 시각 역전 사실 확정.

### 4단계 — discord-auto-reply skip 이벤트 해석

게이트웨이가 nyongjong 종합 답변(14:27:56.531)을 봇 4개 모두에 dispatch 시도 → 3봇(jamesclaw-cc, codex-claw, ollama-claw)이 botLoopProtection 정책으로 skip. 이 시각에 종합 답변이 이미 존재 = nyongjong이 위임 대상 봇들의 응답을 받기 전에 답변 작성 완료.

### 5단계 — nyongjong runtime 추적

`bots[name=nyongjong].provider`를 확인 (`~/.openclaw/openclaw.json`):

```json
{
  "name": "nyongjong",
  "provider": "codex",
  "model": "gpt-5.5"
}
```

→ nyongjong runtime은 codex CLI backend의 GPT-5.5. GPT-5.5의 추론 능력으로 단일 호출 안에서 위임 대상 봇 응답을 시뮬레이션 가능.

### 6단계 — 단일 호출 안에서 종합 답변 + 외형적 위임이 어떻게 가능한지 검토

codex CLI 호출 1회의 동작 흐름:
1. 게이트웨이가 codex CLI에 prompt 전달 (사용자 요청 + workspace AGENTS.md + ORCHESTRATION.md)
2. GPT-5.5가 응답 생성 — multi-line response 가능
3. 응답 본문에 (a) 종합 답변 마크다운 (b) 위임 메시지 라인 모두 포함
4. 게이트웨이가 응답을 파싱 → 각 라인을 Discord에 순차 dispatch
5. 1.6초 간격은 Discord API rate limit 회피 dispatch 간격

→ 따라서 nyongjong은 **한 turn 안에서 종합 답변 + 위임 메시지를 동시에 생성**. 위임 메시지가 발사되는 시점은 종합 답변 이후이지만, 응답 본문 자체는 위임 대상 봇 응답을 받기 전에 작성됨.

---

## 진짜 메커니즘 — GPT-5.5 사전 시뮬레이션 + 외형적 위임

```
[사용자 요청 → nyongjong (codex CLI / GPT-5.5)]
14:27:24

[단일 codex CLI 호출 안에서]
1. GPT-5.5가 사용자 요청 파싱
2. 위임 대상 봇(jamesclaw-cc/codex/ollama) 각각의 응답을 자체 시뮬레이션
   - jamesclaw-cc → claude 스타일 기획안 시뮬레이션
   - codex → 마크다운 정돈 결과 시뮬레이션
   - ollama → "민감정보 금지+범위 명시" 검토 시뮬레이션
3. 시뮬레이션 결과를 종합한 마크다운 게시문 작성 (종합 답변)
4. 위임 메시지 라인 추가 (외형적 dispatch 트리거)
5. 단일 응답으로 게이트웨이에 반환

[게이트웨이 → Discord]
14:27:56.531: 종합 답변 게시 (GPT-5.5가 사전 시뮬레이션한 결과)
14:27:58.142: → jamesclaw-cc 위임 메시지 게시 (외형)
14:28:56:    → codex 위임 메시지 게시 (외형)
14:29:49:    → ollama 위임 메시지 게시 (외형)

[실제 봇 응답 — nyongjong과 무관한 병렬 작업]
14:28:17.702: jamesclaw-cc 처리 시작 (resumeSession=79fc3d4d3e13)
14:28:24.103: jamesclaw-cc 응답 게시 (claude 실제 출력)
14:29:29:    codex 응답 게시 (codex 실제 출력)
14:30:17:    ollama 응답 게시 (ollama 실제 출력)
```

3가지 핵심 동시 작용:

1. **GPT-5.5의 사전 시뮬레이션 능력**: codex 모델은 다른 LLM(claude, ollama)의 응답 스타일을 단일 호출 안에서 모방 가능. 결과 정확도는 우연 + 추론 능력.
2. **단일 turn 내 multi-line response**: codex CLI는 한 응답에 종합 답변 + 위임 메시지를 모두 담을 수 있음. 게이트웨이는 응답을 라인 단위로 파싱해 dispatch만 분리.
3. **외형적 위임 메시지의 dispatch**: 위임 메시지가 발사되긴 함 → 실제 봇들도 응답 생성 → Discord 상에서 외형적으로는 완전한 4봇 협업.

영상 패턴 원래 의도와의 격차:
- 의도: 사용자 → nyongjong → 위임 → **봇 응답 await** → 받은 응답 종합
- 현실: 사용자 → nyongjong → 종합 답변 + 위임 메시지 동시 생성 → 봇 응답은 사후 병렬 작업

---

## 안티패턴 영향 분석

| 측면 | 영향 | 심각도 |
|------|------|-------|
| 결과물 품질 | 우연히 정확하지만 보장 없음. GPT-5.5가 모방 못 하는 작업이면 종합 답변 부정확 | 高 |
| 봇별 독립성 | 명목상만 — 실제로는 nyongjong 단일 모델이 종합. 봇별 모델 다양성 가치 무효화 | 高 |
| 협업 가치 | 4봇 cross-mention 입증이 외형만. 실제 협업 효과 제한적 | 中 |
| 토큰/시간 효율 | nyongjong이 4봇 작업을 단일 호출에서 모두 처리 — 실제 봇 위임은 추가 부담 (중복 작업) | 中 |
| 검증 신뢰성 | 외형 검증만으로는 PASS. 시각 비교 안 하면 안티패턴 무감지 | 高 |
| 사용자 인지 | 대표님이 "받으시면 종합"이라 명시했음에도 mock delegation 수행 | 高 |

### GPT-5.5 모방 한계 시나리오

다음 경우 사전 시뮬레이션이 실패 → 종합 답변 부정확:

1. 실시간 데이터 조회 필요 (jamesclaw-cc가 실제 파일 시스템 검색)
2. 모델별 고유 도구 호출 필요 (ollama-claw가 실제 로컬 모델 inference)
3. 봇별 fine-tuning/system prompt가 응답 본질을 결정하는 경우
4. 위임 대상 봇의 응답이 무작위성 高 (gpt-5.5 추론으로 예측 불가)

→ 본 4단계 시나리오는 (기획/정돈/검토)가 추론 기반이라 우연히 적중. 도구 호출 필요한 시나리오에서는 사전 시뮬레이션 실패 보장.

---

## 옵션 비교

| 옵션 | 작업 | 장점 | 단점 | 강제력 |
|------|------|------|------|--------|
| **A. 현 상태 수용** | 외형 작동 + GPT-5.5 능력 신뢰 | 추가 작업 0 | 결과물 품질 보장 없음. 시뮬레이션 실패 시 silent fail | N/A |
| **B. workspace/AGENTS.md "await 강제" 가이드** | "위임 → 답변 수신 확인 → 종합" 단계 명시. nyongjong이 자기 답을 먼저 만들지 않도록 가이드 | 봇 인프라 측 대응. 사용자 측 부담 0 | 가이드 강제력 의문. claude-cli backend도 P-198/P-199에서 5차례 가이드 무력화 사례 있음. codex backend는 더 자유로움 | 낮음 |
| **C. OpenClaw dispatch 메커니즘 코드 수정** | nyongjong이 위임 메시지 게시 후 응답 수신까지 다음 turn으로 넘어가지 않도록 turn-budget 강제 | 구조적 해결. 봇 모델 강제력과 무관 | 위험 (소스 수정). OpenClaw upstream과의 sync 깨짐. P-187/P-188 deployment 안정성 위협 | 높음 |
| **D. 사용자 측 명시적 await 키워드** | "받으시면 종합" 대신 "응답 모두 수집한 후 종합" / "각 봇 답변 게시 확인 후" 같은 명시 지시. 단일 turn 시뮬레이션 회피 의도를 사용자가 표현 | 봇 인프라 수정 0. 가장 단순 | 사용자 의지가 매 요청마다 필요. nyongjong이 명시적 키워드도 무시할 가능성 잔존 | 중간 |

### 채택 권고 — 옵션 D (+ 검증 시각 비교 운영 규칙 추가)

**근거**:

1. **B의 강제력 한계 입증**: P-198(채널 가이드 + raw ID 양방향), P-199(workspace-claude/AGENTS.md 강화 + session purge)에서 backend 가이드가 모델 행동을 강제로 변경하는 데 한계. claude-cli도 5차례 가이드 수정에 응답 0 — codex backend는 더 자유로워 강제력 더 약함.

2. **C의 위험성**: OpenClaw upstream 코드 수정은 P-187/P-188에서 확립한 "WSL2 배포 안정성"을 위협. turn-budget 강제는 dispatch 메커니즘 핵심 부분이라 회귀 위험 高. 비용 대비 효과 不明.

3. **A의 silent fail 보장**: GPT-5.5 시뮬레이션 한계 시나리오에서 결과물 부정확 → 외형 검증 PASS → 사용자 misled. 4봇 협업 가치가 외형만 됨.

4. **D의 사용자 통제권**: 대표님이 "정말 await가 필요한 시나리오"와 "외형 협업이면 충분한 시나리오"를 매 요청마다 구분 가능. 단순 정보 수집은 사전 시뮬레이션도 무방, 도구 호출 필요한 작업만 명시적 await 키워드.

5. **운영 규칙으로 검증 시각 비교 영구화**: 옵션 D만으로는 다음 검증에서 다시 시각 역전 발견 못 할 수 있음. P-200의 핵심 가치는 "외형 검증 + 시각 비교 동시 수행" 패턴을 운영 규칙으로 영구화.

### B 채택 보류 사유 (workspace/AGENTS.md 수정 안 함)

- B의 효과 不確: nyongjong은 codex CLI backend (GPT-5.5) — claude-cli보다 가이드 무력화 사례 더 많을 가능성
- AGENTS.md 분량 증가 (현재 11682 chars) → context cost ↑
- 가이드 수정 + 검증 + 재시작 사이클이 부담 (P-199에서 5차례 반복 학습)
- D + 운영 규칙(시각 비교)이 효과 동일하면서 작업 부담 최소

### 옵션 D 적용 시 사용자 가이드

대표님이 위임 시나리오 요청 시 다음 키워드 중 하나 사용 권장:

❌ **외형 시뮬레이션 허용 (기본)**:
- "받으시면 종합 부탁드려요"
- "각자 응답 후 정리해주세요"
→ GPT-5.5 사전 시뮬레이션 가능. 빠름. 단순 정보 수집에 적합.

✅ **실제 봇 응답 await 강제 (명시 키워드)**:
- "각 봇 답변 게시를 **확인한 후** 종합"
- "**응답을 모두 수집한 후** 종합"
- "**실제 봇 응답 수신 확인 필수** — 사전 시뮬레이션 금지"
- "**모든 봇 응답 시각이 종합 시각보다 앞서야** 합니다"
→ nyongjong이 명시적 keyword를 보고 단일 turn 시뮬레이션 회피 시도 (강제력 N/A — 검증 시각 비교 필수)

---

## 운영 모니터 + 재발 방지

### 검증 시각 비교 영구 운영 규칙

복잡한 위임 시나리오(2단계+) 검증 시 다음 3중 검증 필수:

#### 1. 외형 검증 (기존)

봇 응답 본문 substantive 여부, echo/self-mention 0회, P-198/P-199 Rules 1~5 통과.

#### 2. 시각 비교 검증 (P-200 신설)

게이트웨이 로그 + Discord API ts로 시각 순서 확인:

```bash
# nyongjong 종합 답변 시각
NYONGJONG_TS=$(grep "discord-publish bot=nyongjong" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log \
  | grep -E "종합|정리|결과" | tail -1 | awk '{print $1}')

# 위임 대상 봇 응답 시각
JAMESCLAW_TS=$(grep "discord-publish bot=jamesclaw-cc" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log \
  | tail -1 | awk '{print $1}')
CODEX_TS=$(grep "discord-publish bot=codex-claw" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log \
  | tail -1 | awk '{print $1}')
OLLAMA_TS=$(grep "discord-publish bot=ollama-claw" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log \
  | tail -1 | awk '{print $1}')

# 시각 순서 검증
echo "nyongjong synthesis: $NYONGJONG_TS"
echo "jamesclaw response:  $JAMESCLAW_TS"
echo "codex response:      $CODEX_TS"
echo "ollama response:     $OLLAMA_TS"

# 종합 답변이 마지막이면 PASS
if [[ "$NYONGJONG_TS" > "$JAMESCLAW_TS" && \
      "$NYONGJONG_TS" > "$CODEX_TS" && \
      "$NYONGJONG_TS" > "$OLLAMA_TS" ]]; then
  echo "PASS — synthesis after all bot responses"
else
  echo "FAIL — P-200 antipattern detected (pre-simulation)"
fi
```

#### 3. session resume 검증 (실제 처리 확인)

위임 대상 봇이 실제로 처리 시작했는지 game-cli 로그에서 확인:

```bash
grep "cli exec.*provider=claude-cli\|cli exec.*provider=codex\|cli exec.*provider=ollama" \
  /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log \
  | grep -E "trigger=user|resumeSession" \
  | tail -10
```

`resumeSession` 또는 `trigger=user` 시각이 종합 답변 시각보다 앞서야 PASS. 종합 답변 시각이 봇 처리 시작보다 앞서면 사전 시뮬레이션 안티패턴 확정.

### 시각 역전 모니터 (회귀 감지)

```bash
# 일일 모니터 — 사전 시뮬레이션 의심 사례
DATE=$(date +%Y-%m-%d)
LOG=/tmp/openclaw/openclaw-$DATE.log

# nyongjong 종합 답변 발생 시각 추출 (마크다운 응답)
NYONGJONG_TIMES=$(grep "discord-publish bot=nyongjong" $LOG \
  | grep -E "기획|정돈|검토|종합|결과" | awk '{print $1}')

# 각 종합 답변 시각에 대해 위임 대상 봇 응답 시각이 앞서는지 검증
for ts in $NYONGJONG_TIMES; do
  # 종합 답변 게시 시각보다 30분 이내 봇 응답이 모두 있는지
  WINDOW_START=$(date -d "$ts - 30 minutes" +%H:%M:%S 2>/dev/null || echo "$ts")
  BOT_BEFORE=$(grep "discord-publish bot=" $LOG \
    | awk -v ws="$WINDOW_START" -v we="$ts" '$1 >= ws && $1 <= we' \
    | grep -v "bot=nyongjong" | wc -l)
  echo "synthesis $ts: $BOT_BEFORE bot responses before"
  if [[ $BOT_BEFORE -eq 0 ]]; then
    echo "  WARN — possible P-200 antipattern (no bot response before synthesis)"
  fi
done
```

### 복잡 시나리오 검증 시 시각 확인 필수

2단계+ 위임 시나리오(특히 "받으시면 종합" 패턴) 검증 시 외형 검증만으로 PASS 선언 금지. 시각 비교 검증을 반드시 수행 + 결과를 보고에 포함.

❌ "4봇 응답 모두 substantive — PASS"
✅ "4봇 응답 substantive + 종합 답변 시각이 모든 봇 응답 이후 — PASS"

❌ "외형 협업 작동 확인"
✅ "외형 + 시각 + session resume 3중 검증 통과"

### 시뮬레이션 vs 실제 위임 구분법

| 시나리오 유형 | 사전 시뮬레이션 허용 | 실제 await 필수 |
|--------------|------------------|---------------|
| 단순 정보 정리 | O (GPT-5.5 추론으로 충분) | X |
| 추론 기반 기획/검토 | O (우연히 정확할 가능성 高) | △ (보장 없음) |
| 실시간 데이터 조회 | X (모방 불가) | O |
| 도구 호출 필요 (파일 검색, API call) | X (모방 불가) | O |
| 봇별 fine-tuning 결과 차별화 | X (모방 정확도 ↓) | O |
| 모델별 고유 도구 (ollama 로컬 모델) | X (모방 불가) | O |

복잡 시나리오는 사용자가 시작 시점에 분류 → 명시적 await 키워드 사용 여부 결정.

### nyongjong 사전 시뮬레이션 silent fail 검증

GPT-5.5 모방 정확도를 매 시나리오마다 우연에 맡길 수 없음. 정확도 검증 절차:

1. 종합 답변 게시 후 위임 대상 봇 실제 응답이 도착할 때까지 wait (시각 비교로 확인)
2. 종합 답변 본문과 실제 봇 응답 본문 diff 확인
3. diff > 30%면 사전 시뮬레이션 실패 (silent fail). 사용자에게 경고 + 종합 답변 재작성 요청

자동화 가능 (게이트웨이 hook 또는 후처리 스크립트).

---

## 적용 이력

| 시각 (KST) | 행동 | 결과 |
|-----------|------|------|
| 2026-05-25 14:25 | P-199 옵션 C 적용 직후 검증 통과 | 4봇 cross-mention 정상 |
| 14:27:24 | 대표님 4단계 위임 시나리오 요청 ("받으시면 종합 부탁드려요") | nyongjong runtime 가동 |
| 14:27:56.531 | nyongjong 종합 답변 게시 (마크다운 + ollama 제안 포함) | 외형 정확 |
| 14:27:58.142 | nyongjong → jamesclaw-cc 위임 메시지 게시 (외형) | dispatch 시작 |
| 14:28:17.702 | jamesclaw-cc 실제 처리 시작 (resumeSession=79fc3d4d3e13) | 종합 21초 뒤 |
| 14:28:24 | jamesclaw-cc 응답 게시 | substantive |
| 14:28:56 | nyongjong → codex 위임 | dispatch |
| 14:29:29 | codex 응답 게시 | substantive |
| 14:29:49 | nyongjong → ollama 위임 | dispatch |
| 14:30:17 | ollama 응답 게시 (종합 2분 21초 뒤) | substantive |
| 14:31 | 외형 검증만 수행하다 시각 비교 시도 | 시각 역전 1차 발견 |
| 14:33 | 게이트웨이 로그 + Discord API ts cross-check | 시각 역전 확정 |
| 14:35 | discord-auto-reply skip 3건 (14:27:56.531) 발견 | 종합 답변 시점에 위임 미발사 증거 |
| 14:38 | nyongjong runtime = codex CLI / GPT-5.5 확인 (`~/.openclaw/openclaw.json`) | 사전 시뮬레이션 가설 |
| 14:42 | 옵션 A/B/C/D 비교 | D + 운영 규칙(시각 비교) 권고 |
| 14:50 | PITFALL-200 작성 시작 | 본 문서 |

---

## 관련

- [[pitfall-191-openclaw-codex-cannot-fire-discord-mentions]] — raw ID `<@BOT_ID>` mention syntax 강제 (Layer 1). 본 PITFALL의 외형적 위임 메시지 dispatch 메커니즘 직접 참조.
- [[pitfall-193-openclaw-codex-fabricates-bot-opinions]] — codex가 다른 봇 의견을 fabricate. 본 PITFALL의 사전 시뮬레이션 안티패턴과 동일 계열 (codex/GPT-5.5의 모방 능력이 양날의 검). P-193은 단일 봇 응답 내 fabrication, P-200은 위임 시나리오 전체 fabrication.
- [[pitfall-194-task-completed-without-external-evidence]] — 검증 없는 결론 antipattern. 본 PITFALL은 외형 검증만으로 PASS 선언할 수 있는 함정 + 시각 비교 추가 검증 필요성 직접 적용.
- [[pitfall-195-openclaw-claude-cli-harness-not-registered-after-model-swap]] — system prompt 추측 antipattern. 본 PITFALL은 게이트웨이 로그 + Discord API ts 정밀 비교로 추측 회피.
- [[pitfall-196-openclaw-channel-separation-video-pattern]] — 영상 패턴 7채널 운영. 본 PITFALL은 영상 패턴의 외형 작동 + 실제 협업 가치 격차 발견.
- [[pitfall-197-openclaw-gateway-system-unit-user-unit-double-spawn]] — system/user unit 이중 등록 해소. 본 PITFALL의 게이트웨이 로그 추적 절차 직접 참조.
- [[pitfall-198-openclaw-channel-bot-loop-protection-explicit-policy]] — raw ID 양방향 작동 + ChannelBotLoopProtection 명시 정책 격상. 본 PITFALL은 discord-auto-reply skip 3건 (botLoopProtection 정책 발동) 해석에 P-198 정책 직접 활용.
- [[pitfall-199-openclaw-workspace-claude-separate-agents-md-and-session-purge]] — workspace 분리 + session purge. 본 PITFALL은 P-199 옵션 C 적용 직후 검증 시나리오에서 발견. P-199의 정밀 진단 패턴(systemPromptReport 확인, 게이트웨이 로그 추적, claude code session cache 분석)을 본 PITFALL에서 그대로 반복 적용.
- [[pitfall-200-openclaw-nyongjong-pre-simulation-antipattern-mock-delegation]] — 본 PITFALL.

---

## 향후 진화 트리거

다음 중 하나라도 충족 시 본 PITFALL 보강 또는 후속 PITFALL 작성:

1. **사용자 명시 await 키워드 요구가 nyongjong에 무력화**: "응답 모두 수집한 후" 키워드를 보고도 사전 시뮬레이션 수행 시 옵션 B(AGENTS.md 가이드) 또는 옵션 C(dispatch 코드 수정) 격상 검토.

2. **claude-cli backend도 사전 시뮬레이션 패턴 등장**: nyongjong runtime을 claude-cli로 전환했을 때도 동일 안티패턴 발생 시 backend-agnostic 운영 규칙 필요.

3. **OpenClaw 업데이트로 dispatch 메커니즘 변화**: turn-budget 또는 await primitive가 native 지원되면 옵션 C 자동 채택. 본 PITFALL의 옵션 D 운영 규칙은 deprecated 가능.

4. **시각 비교 검증이 일상 운영에서 누락**: 일일 모니터 스크립트가 P-200 antipattern 감지율 0% 유지하지 못하면 hook 자동화 (게이트웨이 PostMessage hook).

5. **GPT-5.5 모방 한계 시나리오에서 silent fail 1회 이상 발생**: 종합 답변 본문과 실제 봇 응답 본문 diff > 30%인 사례 발견 시 자동 검증 + 사용자 경고 hook 필수.

6. **봇 5번째 추가로 N-단계 위임 시나리오 확장**: 5봇 이상에서는 사전 시뮬레이션 정확도 ↓ + 시각 비교 복잡도 ↑. 다중 봇 위임 시 시각 비교 자동화 도구 필수.

7. **codex CLI session resume이 위임 응답 cache로 오용**: nyongjong이 위임 대상 봇 응답을 자기 session cache에 학습 → 후속 호출에서 cache 재사용 가능성. session 격리 정책 검토.

8. **P-200 antipattern이 실제 사용자 피해 사례 발생**: GPT-5.5 모방 정확도 한계로 종합 답변이 오류 → 사용자가 잘못된 결과 채택 → 1회 이상 피해 발생 시 옵션 C 격상 자동 트리거.
