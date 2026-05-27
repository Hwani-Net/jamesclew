# PITFALL-196: OpenClaw 4봇 channel separation — 영상 패턴 정확 매핑 (UsT1-E1Txyo 33:46)

- **발견**: 2026-05-25 03:00 KST
- **영향**: P-191(봇간 멘션 실패)의 진짜 root cause. 4봇은 영상 패턴과 동일하지만 **단일 채널 운영**으로 mention 폭주 + required_mention 비대칭 효과 무효화.
- **재발 빈도**: P-194(추측 결론) 분석 과정에서 3회 재발 — 매번 대표님이 raw 증거(영상 다이어그램, 픽셀 매핑)로 교정.
- **검증 자료**:
  - 자막 원본: `C:/temp/yt-openclaw/transcript-final.txt` (1486줄, yt-dlp 한국어 자동자막)
  - 픽셀 매핑: `C:/temp/yt-openclaw/frame-33-46.png`, `crop-center.png`, `crop-participants-flow.png`
  - 영상: https://www.youtube.com/watch?v=UsT1-E1Txyo (33:46~34:10)

---

## 증상

P-191 "OpenClaw codex 봇이 다른 봇을 텍스트 `@이름`으로 멘션해도 mention 이벤트 미발생"의 **표면적 원인은 raw ID syntax 누락**이었음. 그러나 P-191 Layer 1/2 fix를 적용한 뒤에도:

1. 4봇이 한 채널 안에서 동시에 발화하여 mention 폭주 발생
2. nyongjong(`requireMention=false`)이 모든 메시지에 반응 → 다른 3봇의 응답까지 받아 무한 처리 루프
3. 사용자 관점에서 "누가 어떤 작업을 하고 있는지" 분간 불가
4. required_mention 비대칭 설계의 이점(채널 환기, mute, 작업 단위 분리)이 모두 사라짐

즉 **P-191은 mention syntax 문제이지만, 그것을 fix해도 운영 구조가 무너지는 새 문제가 드러남**. 채널 단일성이 영상 패턴의 핵심 누락 지점.

---

## 핵심 단서 — 영상 다이어그램 33:46

대표님이 영상 33:46 캡쳐를 제시했고, 자체 픽셀 매핑(`crop-center.png`)으로 검증한 결과 다이어그램의 실제 구성은 다음과 같음:

### 다이어그램 좌측 — Discord 서버 "AI 작업실"

```
# 채널 (7개)
  공지사항
  작업-요청
  작업-진행중       ← 현재 표시 중
  작업-완료
  리뷰-요청
  리뷰-완료
  자료실

# 스레드 (3개, 예시)
  작업-진행중 스레드 1
  작업-진행중 스레드 2
  작업-요청 스레드 1
```

### 다이어그램 가운데 — "작업-진행중" 채널 채팅 예시

```
나          10:15  "신규 기능 기획안 초안 부탁해요."
Claude BOT  10:16  "기획 방향과 구조를 정리했습니다."
                   📄 기획안_초안.md
OpenClaw BOT 10:18 "기획안을 바탕으로 기술 설계 및 구현을 진행하겠습니다."
                   📄 설계_초안.md
나          10:22  "좋아요! 구현 진행 후 리뷰 요청할게요."
```

### 다이어그램 우측 — 참여자 5명

| 참여자 | 색상 | 라벨 |
|--------|------|------|
| 나 | 녹색 아바타 | (사용자) |
| OpenClaw | 빨간색 | BOT |
| Claude | 주황색 | BOT |
| Codex | 흰색 상자 | BOT |
| Reviewer | 녹색 | (사용자) |

### 다이어그램 우측 하단 — 협업 흐름 다이어그램

```
[작업 요청]
   요청을 채널에 등록
        ↓
[OpenClaw + Claude]
   병렬로 기획·구현 진행
        ↓
[리뷰 및 피드백]
   검토와 개선사항 반영
        ↓
[완료 및 아카이브]
   완료 채널로 이동
```

**즉 영상의 운영형 setup은 시연(2봇)과 다른 비전 구성**. 다이어그램은 **4봇 + 사용자 1 + 리뷰어 1 + 7채널 + 다중 스레드**로 구성됨. 시연부(27분~33분)의 2봇 설명은 minimal viable setup이고, 비전부(33:46~)가 운영형 작업실 구조의 정답.

---

## 분석 과정에서 P-194 3회 재발 (자백)

이번 PITFALL이 만들어지기까지 동일 세션에서 추측 기반 결론을 3회 반복해 대표님이 매번 raw 증거로 정정해 주셨음. P-194(검증 없는 완료 보고) 패턴과 정확히 일치.

### 1차 추측 — "JamesClaw 전환 권고"

- **추측 근거**: P-191/P-195 디버깅 1.5시간 지속, claude-cli harness 회귀, mention 라우팅 복잡. "Discord 자체가 부적합한가" 의심.
- **결론(잘못)**: "JamesClaw로 전환 권고 — Discord 폐기"
- **대표님 교정**: 영상 raw 노트(2026-05-20)와 자막을 보면 **영상이 Discord를 핵심 인프라로 입증**하고 있음. "영상은 Discord 사용 안 함"이라고 보고한 직전 발언은 거짓.
- **재검증**: yt-dlp로 자막 재다운로드(`transcript-final.txt`) → 27:00~33:40 = Discord setup 시연 + 33:42~ = 비전 다이어그램. Discord 폐기 권고 철회.

### 2차 추측 — "2봇 축소 권고"

- **추측 근거**: 자막 27:18 "오픈 클로우 봇이 따로 있어야 되고 클로드용이 따로 있어야 됩니다" + 33:21 "두 가지를 allowlist만 바꾸면 역할 교환" → 영상은 2봇 패턴이 정답이라고 단정.
- **결론(잘못)**: "4봇 → 2봇 축소. codex claw, ollama claw 비활성"
- **대표님 교정**: 영상 33:46 캡쳐 제시. "이건 너가 본 거랑 다르잖아?" — 4봇 다이어그램(OpenClaw + Claude + Codex + Reviewer + 사용자)이 있는데 자막만 보고 단정.
- **재검증**: `frame-33-46.png` 추출 → `crop-center.png` 픽셀 매핑 → **참여자 5명 / 봇 4개** 확인. 2봇 축소 권고 철회.

### 3차 결론 — "4봇 유지 + 채널/스레드 분리"

- **결론 근거**: 다이어그램 픽셀 매핑 + 자막 33:48 "채널들을 분리해서 여러분이 병렬로 여러 가지 동시에 여러 작업들을 시킬 수 있고" + 자막 31:48~32:08 "오픈 클러우드 채널마다 따로 이렇게 구별되어 있듯이 클러우드도 비슷한 세업이 필요" → 4봇 setup 자체는 영상과 동일, **단일 채널 운영이 영상에서 이탈한 변형**.
- **검증**: Discord REST API로 `~/.openclaw/discord/` 토큰 사용해 7채널 생성 시도 → 성공.
- **승인**: 대표님 — 이번엔 진짜 정답.

### 재발 신호 정리

| 회차 | 추측 | 정정 증거 |
|------|------|----------|
| 1 | "영상은 Discord 사용 안 함, JamesClaw 권고" | 자막 27:18~ Discord setup 전용 |
| 2 | "영상은 2봇 패턴, 4봇 축소 필요" | frame-33-46.png 다이어그램 4봇 |
| 3 | "4봇 유지 + 채널 분리" | (대표님 승인 — 정답) |

**모든 회차의 공통 안티패턴**: "결론" 단어 사용 전 외부 raw 증거(자막 timestamp 인용, 다이어그램 픽셀 매핑) 재확인 누락.

---

## 진짜 원인

영상 패턴을 layer로 분해하면:

| Layer | 영상 패턴 | 우리 환경 (수정 전) | 일치 여부 |
|-------|----------|---------------------|----------|
| 봇 수 | 4 (OpenClaw + Claude + Codex + Reviewer 형태) | 4 (nyongjong + jamesclaw-cc + codex + ollama) | ✅ 일치 |
| required_mention 비대칭 | OpenClaw=false, 나머지=true | nyongjong=false, 나머지=true | ✅ 일치 |
| cross-allowlist | 봇 ID 상호 등록 | P-191 fix로 등록 완료 | ✅ 일치 |
| Message Content Intent | 활성 | 활성 | ✅ 일치 |
| Read Message History | 활성 | 활성 | ✅ 일치 |
| Claude OAuth 방식 | claude CLI spawn | claude-cli runtime (P-195 회귀로 GPT-5.5 사용) | △ 부분 |
| **채널 분리** | **7채널 + 다중 스레드** | **단일 채널 `#test-multi` 운영** | ❌ **이탈** |
| **스레드 분리** | 작업 단위 1스레드 (자막 41:54) | 스레드 미사용 | ❌ **이탈** |

봇 setup은 영상과 동일하지만 **운영 구조의 channel separation 1개 layer만 누락**되어 P-191 fix의 효과가 단일 채널 mention 폭주에 묻혔던 것. 4봇 자체가 문제가 아니라 4봇을 한 채널에 몰아넣은 운영 변형이 문제.

자막 인용 (영상 31:48~32:08):
> "ACPX 그 세션도 되게 중요한데요. 클로드 벗이 어 서로 채널마다 그 컨텍스트가 섞이면 안 되잖아요. 오픈 클러우드 채널마다 따로 이렇게 구별되어 있듯이 클러우드도 비슷한 세업이 필요하고요. 그렇기 때문에 클라우드 쪽에서도 오픈 클로우의 제너럴 채널 그다음에 제가 프로젝트의 채널 그 기억들이 따로따로 이렇게 분리를 해 두셔야지 어 한 채널에서 하던 작업 맥락이 다른 채널로 섞이지 않습니다."

자막 인용 (영상 33:48~33:53):
> "채널들을 분리해서 여러분이 병렬로 여러 가지 동시에 여러 작업들을 시킬 수 있고"

자막 인용 (영상 41:54~42:11):
> "처음에 여러분들이 이제 새로운 작업을 시키신다 할 때는 무조건 저는 새 트레드를 여시는 것을 추천합니다. 절대 원래 있던 거 가셔 가지고 또 하시지 마시고요. 채널 하나에서 계속 말하는 것보다 작업 하나당 트레드를 여시고 거기서 시작을 하셔야 훨씬 깨끗한 컨텍스트로 시작을 할 수 있고 그리고 무엇보다 작업이 끝난 다음에이 트레드를 닫을 닫을 수가 있습니다."

→ 채널 = 프로젝트 단위, 스레드 = 작업 단위. 이게 영상 패턴의 운영 layer.

---

## 해결 (3-layer)

### Layer 1 — Discord REST API 채널 자동 생성

영상 다이어그램의 7채널을 동일 이름으로 우리 Discord 서버에 생성. Discord Developer Portal UI 수동 클릭 대신 Bot Token + REST API + `MANAGE_CHANNELS` 권한 사용.

```bash
# 사전 조건
# - ~/.openclaw/discord/bots/*.json 에 bot token 존재
# - bot이 서버에 MANAGE_CHANNELS 권한 부여됨 (OAuth2 grant 단계)

GUILD_ID="<우리 AI 작업실 서버 ID>"
BOT_TOKEN="<nyongjong bot token>"

# 채널 7개 생성 (영상 다이어그램과 동일 이름)
for name in 공지사항 작업-요청 작업-진행중 작업-완료 리뷰-요청 리뷰-완료 자료실; do
  curl -X POST "https://discord.com/api/v10/guilds/${GUILD_ID}/channels" \
    -H "Authorization: Bot ${BOT_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "User-Agent: DiscordBot (openclaw-relay, 1.0)" \
    -d "{\"name\":\"${name}\",\"type\":0}"
done
```

#### 주의사항 — REST API 함정

1. **User-Agent 헤더 필수**: 누락 시 Discord가 `400 Bad Request` 반환. `DiscordBot (<URL>, <version>)` 형식.
2. **MANAGE_CHANNELS 권한**: bot이 서버 초대 시 admin이 아니어도 OAuth scope에 명시 필요. 누락 시 `403 Missing Permissions`.
3. **rate limit**: 분당 50 req. 7채널 정도면 안전하지만 retry 로직은 별도 대비.
4. **type=0**: 텍스트 채널. 카테고리 채널은 type=4, voice는 type=2.
5. **channel ID 캡쳐**: API 응답의 `id` 필드를 즉시 `openclaw.json`에 매핑해야 함. 응답 없으면 Discord UI에서 채널 우클릭 → "ID 복사" (개발자 모드 활성 필요).

### Layer 2 — `openclaw.json` defaultTo 봇별 매핑

영상 다이어그램에서 각 봇의 발화 위치를 보면 역할별 채널 매핑이 자연스럽게 도출됨:

| 봇 | 영상 다이어그램 행동 | 우리 환경 봇 | defaultTo 채널 |
|----|---------------------|-------------|----------------|
| 사용자 | "신규 기능 기획안 초안 부탁해요" | (사람) | #작업-요청 |
| Claude (기획) | "기획 방향과 구조를 정리했습니다" | (영상 패턴 — 우리엔 별도 봇 없음. nyongjong이 겸임) | — |
| OpenClaw (구현) | "기술 설계 및 구현을 진행하겠습니다" | jamesclaw-cc, codex claw | #작업-진행중 |
| Reviewer | (협업 흐름의 "리뷰 및 피드백") | ollama claw | #리뷰-요청 |

`openclaw.json` patch:

```json
{
  "agents": {
    "main": {
      "discord": {
        "defaultTo": "#작업-요청"  // nyongjong = 사용자 진입점
      }
    },
    "jamesclaw-cc": {
      "discord": {
        "defaultTo": "#작업-진행중"
      }
    },
    "codex-claw": {
      "discord": {
        "defaultTo": "#작업-진행중"
      }
    },
    "ollama-claw": {
      "discord": {
        "defaultTo": "#리뷰-요청"
      }
    }
  }
}
```

**중요**: defaultTo가 채널 이름 기준이면 hot reload 후 channel ID resolve가 1초 정도 지연. 응답 lag 최소화하려면 raw channel ID로 등록:

```json
"defaultTo": "1508275532851183727"  // #작업-요청 raw ID
```

### Layer 3 — ORCHESTRATION.md §10 채널 가이드 + §11 raw ID mention syntax 강제

P-191 Layer 1(raw ID `<@USER_ID>` syntax 강제)의 재인용 + 영상 패턴 channel mapping 가이드 추가.

#### §10 (신설) — 채널/스레드 운영 가이드

```markdown
## §10 Channel / Thread Operation (영상 33:46 패턴)

### 채널 = 프로젝트 단위
- 공지사항: 봇 상태, 배포 알림, 시스템 메시지
- 작업-요청: 사용자가 새 작업을 등록하는 진입 채널 (nyongjong 수신)
- 작업-진행중: jamesclaw-cc, codex claw 실행 채널
- 작업-완료: 완료 보고, PR 링크 게시
- 리뷰-요청: ollama claw가 리뷰 진행
- 리뷰-완료: 리뷰 결과 아카이브
- 자료실: 영상, 캡쳐, 문서 첨부 보관

### 스레드 = 작업 단위
- 새 작업 시 무조건 새 스레드 생성 (`/thread <slug>`)
- 작업 완료 후 스레드 archive (7일)
- 한 스레드에서 한 작업만 — 컨텍스트 섞임 방지
- 영상 자막 41:54 인용: "작업 하나당 트레드를 여시고 거기서 시작을 하셔야 훨씬 깨끗한 컨텍스트로 시작을 할 수 있고"

### 봇별 진입 채널
- nyongjong (오케스트레이터, requireMention=false): #작업-요청
- jamesclaw-cc, codex claw (구현, requireMention=true): #작업-진행중
- ollama claw (리뷰, requireMention=true): #리뷰-요청
```

#### §11 (P-191 재인용 강화) — Raw ID Mention Syntax

```markdown
## §11 Cross-Bot Mention — Raw ID Syntax 필수

다른 봇 호출 시 평문 `@이름` 절대 금지. **반드시 raw ID 형식**.

| 봇 | 텍스트 alias (참고만) | 실제 mention syntax (필수) |
|----|----------------------|---------------------------|
| nyongjong claw | @nyongjong claw | <@1506248517478518854> |
| jamesclaw-cc | @jamesclaw-cc | <@1506554520761536603> |
| ollama claw | @ollama claw | <@1506595165475967016> |
| codex claw | @codex claw | <@1506xxxxxxx> |

이유: Discord SDK의 mention 이벤트는 `<@USER_ID>` 형식만 인식.
평문 `@이름`은 Role mention 또는 plain text로 처리되어 봇 무응답.

### Discord 사용자도 동일 규칙
- `@` 입력 → 드롭다운에서 **프로필 사진 있는 항목** 선택 (User mention)
- 프로필 사진 없는 "이 채널을 볼 수 있는 권한을 가진..." 항목 = Role mention (봇 무응답)
- raw ID `<@1506248517478518854>` 직접 타이핑도 가능
```

---

## 생성된 채널 ID

2026-05-25 03:00 KST에 Discord REST API로 생성한 7채널의 raw ID:

| 채널 | Raw ID |
|------|--------|
| 공지사항 | 1508275529164521514 |
| 작업-요청 | 1508275532851183727 |
| 작업-진행중 | 1508275536449896608 |
| 작업-완료 | 1508275540107202651 |
| 리뷰-요청 | 1508275543970414695 |
| 리뷰-완료 | 1508275550152691855 |
| 자료실 | 1508275553759658155 |

이 ID들은 `openclaw.json`의 `agents.*.discord.defaultTo`와 `allowlist.channels[]`에 raw 값으로 등록해야 hot reload 후 1초 지연 없음.

### 백업

- 패치 전 `openclaw.json` 백업: `~/.openclaw/openclaw.json.bak-20260525-030000-pre-channel-separation`
- ORCHESTRATION.md 백업: `~/.openclaw/agents/main/ORCHESTRATION.md.bak-20260525-030000-pre-channel-separation`

---

## 재발 방지

### 영상 분석 시 transcript-only 금지

- transcript만 읽고 결론 내리면 다이어그램·시각 슬라이드의 핵심 정보를 놓침
- 영상 핵심 슬라이드(시각 도표, 다이어그램)는 yt-dlp + ffmpeg로 frame 추출 → Opus Vision으로 픽셀 단위 매핑
- 절차:
  ```bash
  # 1. 영상 다운로드 (HD)
  yt-dlp -f "bestvideo[height<=1080]+bestaudio" -o "video.%(ext)s" "<URL>"
  
  # 2. 핵심 timestamp frame 추출 (예: 33:46)
  ffmpeg -ss 00:33:46 -i video.mp4 -vframes 1 -q:v 2 frame-33-46.png
  
  # 3. Opus Vision으로 직접 Read (Sonnet Vision 금지 — P-055)
  # Read("C:/temp/yt-openclaw/frame-33-46.png")
  ```

### "raw에 저장했다" ≠ "정확히 저장했다"

- 노트 자체가 부정확할 수 있음을 항상 의심
- 작성 당시 누락된 정보가 노트 신뢰성을 깨뜨림 (1차 노트 2026-05-20이 영상 절반 누락한 사례)
- raw 노트 진입 후 6주 이상 경과 시 노트 vs 원본 재검증 권장

### 단일 채널 4봇 = 운영 안티패턴

- 4봇을 한 채널에 두면 mention 폭주 + required_mention 비대칭 효과 사라짐
- 봇 N개일 때 채널 분리는 필수 (영상 패턴: 4봇 → 7채널)
- 새 봇 추가 시 즉시 점검 항목:
  1. 다른 채널이 필요한가? (역할별 진입점 분리)
  2. 다른 봇과의 cross-allowlist 매핑 추가?
  3. defaultTo 채널 명시?

### P-194 재발 신호

- "결론" 단어 사용 전 **외부 raw 증거 재확인** 강제
- raw 증거 = 자막 timestamp 인용 / 스크린샷 픽셀 매핑 / 코드 git diff / HTTP 응답 본문
- 추측·정황으로 결론 내리고 대표님에게 보고 → P-194 카운터 +1

### 영상 자료 보존

이번 분석에서 사용한 영상 자료는 다음 위치에 보존됨 (다음 세션이 재검증 가능):

| 파일 | 위치 |
|------|------|
| 자막 final | `C:/temp/yt-openclaw/transcript-final.txt` |
| 자막 raw SRT | `C:/temp/yt-openclaw/video.ko.srt` |
| HD frame (33:46) | `C:/temp/yt-openclaw/frame-33-46.png` |
| HD frame (33:52) | `C:/temp/yt-openclaw/frame-33-52.png` |
| Center crop (다이어그램) | `C:/temp/yt-openclaw/crop-center.png` |
| Left agents crop | `C:/temp/yt-openclaw/crop-left-agents.png` |
| Participants flow | `C:/temp/yt-openclaw/crop-participants-flow.png` |
| 채널 분리 슬라이드 | `C:/temp/yt-openclaw/hd-frame-22-scaled.png` |
| 클립 (33:46~33:52) | `C:/temp/yt-openclaw/clip-33-46.mp4` |

---

## 적용 이력

| 시각 (KST) | 행동 | 결과 |
|-----------|------|------|
| 2026-05-25 02:00 | 1차 추측 "JamesClaw 전환 권고" | 대표님 정정 — Discord 폐기 X |
| 02:19 | 1차 raw 노트 백업 (`.bak-20260525-021900-pre-rewrite`) | — |
| 02:25 | 자막 재다운로드 (yt-dlp `transcript-final.txt`) | 27:00~52:30 풀 자막 확보 |
| 02:40 | 2차 추측 "2봇 축소" | 대표님이 33:46 캡쳐 제시 → 정정 |
| 02:50 | ffmpeg frame 추출 + 픽셀 매핑 | 4봇 다이어그램 확인 |
| 03:00 | Discord REST API로 7채널 생성 | 채널 ID 7개 확보 |
| 03:05 | `openclaw.json` defaultTo 패치 | hot reload 적용 |
| 03:10 | ORCHESTRATION.md §10/§11 추가 | — |
| 03:12 | gateway 재시작 → 4봇 모두 오프라인 발견 → PITFALL-197 진입 (system/user unit 이중 운영 SIGTERM 무한 루프) | ⚠️ 회귀 |
| 03:15 | 본 PITFALL 작성 시작 | — |
| 03:30 | PITFALL-197 fix 완료 (system unit 제거 → user unit 단독 운영) | ✅ |
| 03:35 | 1차 라이브 테스트: #작업-요청에 "테스트" → nyongjong "대표님, 수신 정상입니다." | ✅ 통과 |
| 03:38 | 2차 라이브 테스트: nyongjong → `<@CLAUDE_BOT_ID>` raw ID mention → claude claw 정상 응답 (cross-mention 작동 = P-191 완전 해결 입증) | ✅ 통과 |

---

## 관련

- [[pitfall-184-openclaw-windows-discord-readiness]] — Discord WSL2 deployment 사전 조건
- [[pitfall-188-openclaw-wsl2-deployment-complete-2026-05-20]] — WSL2 OpenClaw deployment 완료 보고
- [[pitfall-190-openclaw-ollama-claw-cloud-model]] — 4번째 봇(ollama claw) 추가
- [[pitfall-191-openclaw-codex-cannot-fire-discord-mentions]] — raw ID syntax 문제 (이번 PITFALL의 표면적 원인)
- [[pitfall-194-task-completed-without-external-evidence]] — 검증 없는 결론 보고 패턴 (이번 PITFALL 분석 과정에서 3회 재발)
- [[pitfall-195-openclaw-claude-cli-harness-not-registered-after-model-swap]] — claude-cli 회귀로 nyongjong primary GPT-5.5 사용 중
- ORCHESTRATION.md §10 (채널/스레드 운영 가이드), §11 (raw ID mention syntax)
- 영상: https://www.youtube.com/watch?v=UsT1-E1Txyo (33:46 다이어그램)
- raw 노트 (재작성됨): `$OBSIDIAN_VAULT/05-wiki/concepts/2026-05-20-openclaw-claude-codex-tikitaka-video.md`
- 1차 raw 노트 (폐기, 백업): `$OBSIDIAN_VAULT/05-wiki/concepts/2026-05-20-openclaw-claude-codex-tikitaka-video.md.bak-20260525-021900-pre-rewrite`

---

## 향후 진화 트리거

다음 중 하나라도 충족 시 본 PITFALL 보강 또는 후속 PITFALL 작성:

1. **8번째 봇 추가**: 채널 7개로 부족 → 추가 채널 설계 필요. 영상 패턴은 7채널이 상한이라 확장 시 자체 결정 필요.
2. **스레드 자동 archive 누락 발견**: Discord 기본 7일 archive 미설정 → 작업 중간에 스레드 사라짐. (영상 자막 42:56 인용: "저는 이거 7일로 7일이 맥스인데 7일로 바꿔 두시는 거 추천하고요")
3. **mention 폭주 재발**: 채널 분리 후에도 한 채널에 봇 3개 이상 동시 발화 → §10 가이드 재점검.
4. **봇 역할 변경**: ollama claw 외 다른 봇이 리뷰 담당하게 되면 defaultTo 매핑 갱신.
5. **JamesClaw 전환 결정**: Discord에서 텔레그램/Slack 등으로 이동하면 본 PITFALL은 archive하고 새 플랫폼용 PITFALL 작성.
