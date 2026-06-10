# P-228: OpenClaw JARVIS(opus) thinking 본문 노출 + 중복 출력

- **발견**: 2026-05-29
- **영향**: JARVIS 응답에 extended thinking 텍스트가 그대로 노출 + draft-preview 스트리밍이 thinking 포함 partial을 반복 edit → "같은 답변 몇 번씩 중복"처럼 보임. 대표님 가독성·신뢰 저하.

## 증상
- 응답 본문에 "_승인 방식 확정 감사합니다. 이건 *Thinking* 승인 방식 확정 감사합니다..." — thinking 텍스트가 최종 메시지에 섞임 + 같은 문장 반복.
- "JARVIS님이 입력하고 있어요…"가 계속 뜨며 중복 생성.
- (부수) "Tidepooling" 영어 코드네임 헤더 — 출처 불명(claude CLI 세션명 추정, 미해결).

## 원인 (소스 조사)
1. **thinking 노출**: `tui-LVkXuSWn.js:773` `if (showThinking && thinkingText) parts.push("[thinking]\n"+thinkingText)`. opus(thinkingDefault=medium)의 extended thinking 블록이 Discord 전송 텍스트에 포함. Discord 전용 thinking 억제 config 키 없음.
2. **중복/분할**: Discord 채널 플러그인이 `draftPreview/previewFinalization/progressUpdates=true`로 streaming live-preview. 생성 중 partial draft를 반복 edit → thinking 포함 중간본이 중복 노출.

## 해결 (검증됨)
**양쪽 gateway config 모두 적용**:
```json
// 1) thinking 노출 제거 — agents.list[main]
"thinkingDefault": "off"
// 2) draft-preview 스트리밍 끄기 — channels.discord
"channels": { "discord": { "streaming": { "mode": "off" } } }
```
- `streaming.mode` 키는 Mattermost 패턴(`channel-plugin-runtime` :264)이나 Discord에도 스키마가 수용(config valid + gateway active 확인). 거부 안 됨.
- gw1(`~/.openclaw/openclaw.json`) + gw2(`~/.openclaw-pro/openclaw.json`) 둘 다.

## 검증 (수정 후)
- TARS봇→@JARVIS 통제 테스트 후 #작업-요청 메시지 GET:
- JARVIS 응답 **thinking 노출 전부 False** ✅ (이전 "[thinking]"/"Thinking" 누출 사라짐).
- 같은 문장 반복 중복 사라짐. 메시지 여러 개는 긴 콘텐츠(제습기 비교 10L/16L/20L)의 정상 2000자 분할 (중복 아님).

## 트레이드오프 / 주의
- `thinkingDefault=off`는 opus 추론을 끔. JARVIS는 오케스트레이터(분배·조율 주역)라 deep reasoning 의존도 낮아 수용 가능. 깊은 판단은 팀원(EVE 등) 위임.
- thinking 필요한 봇(EVE 리서치 등)은 노출 관찰 시에만 개별 off — 기본은 유지.
- 긴 응답의 메시지 분할(2000자)은 Discord 제약이라 정상. "중복"(동일 문장 반복)과 구분할 것.

## 미해결
- "Tidepooling" 코드네임 헤더 출처 불명 (dist grep 0건, claude CLI 세션명 추정). 재관찰 시 추가 조사.

## 관련
- [[pitfall-227-openclaw-bot-name-dotted-mention-mismatch]]
- [[pitfall-226-openclaw-native-2gateway-split]] — 양쪽 gateway 동기 적용
