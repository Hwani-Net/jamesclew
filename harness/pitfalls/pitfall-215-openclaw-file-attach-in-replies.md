---
title: pitfall-215 — OpenClaw 산출물 메시지에 파일 attach가 없으면 사용자가 다운로드/검토 마찰을 겪는다
slug: pitfall-215-openclaw-file-attach-in-replies
date: 2026-05-26
type: pitfall
tags:
  - openclaw
  - discord
  - file-attach
  - mcp-reply
  - p205
severity: medium
related:
  - pitfall-205-openclaw-project-isolation-thread-per-project
  - pitfall-208-openclaw-p199-vs-discord-2000-char-limit-conflict
---

# pitfall-215 — 산출물은 본문 텍스트가 아니라 첨부 파일로 보내야 한다

## 증상

OpenClaw nyongjong이 산출물(블로그 v3.md / 슬라이드 deck / 영상 스크립트 / 분석 보고서 등)을 thread 본문에 그대로 붙여 보낸 사례가 누적됐다.

증거:
- Discord 2000자 제한(P-208)에 부딪혀 본문이 잘림 → 일부 산출물 손실
- 사용자가 파일을 별도로 받으려면 봇에게 "파일로 보내줘" 추가 요청 필요
- 사용자가 산출물 버전 추적 곤란 (v1, v2, v3 본문이 모두 같은 thread에 줄줄이 누적)
- 마스터 채널(#작업-완료, #자료실)에 다시 attach 요청 시 사이클 추가 필요

P-205 "thread per project"로 격리는 했지만 thread 안 본문 텍스트만으로 산출물 전달 시 사용자 마찰이 컸다.

## 원인

Discord MCP `mcp__plugin_discord_discord__reply`는 `files: [절대경로]` 파라미터로 attach를 지원하는데, nyongjong이 이 파라미터를 일관되게 사용하지 않았다.

봇 입장에서 "본문에 코드 블록으로 붙이면 즉시 보인다"는 가시성이 매력적이었고, 결과적으로 2000자 제한 / 버전 추적 / 다운로드 마찰이 누적됐다.

## 해결

P-215 규칙으로 영구화한다.

1. **thread 안 산출물 메시지 형식**:
   ```
   📄 <filename> (산출물 v<N>) - <내용 요약 1줄>
   ```
   + `files: [<절대경로>]` 강제.
2. **본문 텍스트 vs 파일 attach 기준**:
   - 본문 ≤ 1500자: 본문 + attach 동시 가능
   - 본문 > 1500자: attach 강제 + 본문은 "v<N> 산출물 첨부. 핵심 요약 3줄: ..." 형태로 압축
3. **버전 표기**: 파일명에 v<N> 또는 timestamp 포함 (예: `blog-제습기-v13.md`, `shorts-day2-script-20260526.md`)
4. **마스터 채널 추가 attach** (P-205 보완):
   - thread 안 진행 산출물: 모두 attach (P-215)
   - 발행 가능 판정(외부 모델 PASS + 사용자 승인) 후에만 #자료실에 동일 파일 mirror attach
   - 단순 중간 산출물은 #자료실에 보내지 않음 (잡음 방지)
5. **attach 실패 시 fallback**:
   - 파일 크기 > 25MB: 분할 또는 URL 첨부 (Google Drive / Dropbox)
   - 봇 권한 부족: 사용자에게 "attach 권한 확인 필요" 메시지 + 본문 fallback
   - MCP 에러: 본문 fallback + 다음 사이클에서 재시도

## 재발 방지

- `/home/creator/.openclaw/workspace/AGENTS.md`에 `File Attach in Replies (P-215)` 섹션 추가.
- nyongjong 시스템 프롬프트에 "산출물 = files attach 강제" 룰 추가.
- jamesclaw-cc 메인 세션 CLAUDE.md "핵심 정책"에 P-215 한 줄 추가됨 (2026-05-26).
- 검증 스크립트: `/home/creator/.openclaw/workspace/scripts/openclaw-p215-attach-audit.js` (thread 안 산출물 message 중 `files=[]` 비율 측정, exit-0 JSON).

## 안티패턴

- 산출물을 본문 코드 블록으로 붙이고 attach 생략 → 2000자 잘림
- 매 사이클마다 같은 파일을 #자료실에 mirror → 잡음
- 봇이 thread 안 attach + 마스터 채널 attach + #자료실 attach 3중 발송 → 채널 잡음 폭증
- 파일명에 버전 없음 → 사용자가 어느 버전인지 추적 불가
- 본문 텍스트 없이 attach만 보냄 → 사용자가 다운로드 전까지 내용 미리보기 불가

## 검증 명령

```bash
# attach 비율 측정
node /home/creator/.openclaw/workspace/scripts/openclaw-p215-attach-audit.js \
  --thread <thread_id> --window 24h

# 마스터 채널 mirror 정책 위반 감지
node /home/creator/.openclaw/workspace/scripts/openclaw-p215-master-mirror-audit.js \
  --channel-id 1508275553759658155 --window 24h
```

## Discord MCP 실측 결과 (2026-05-26)

`mcp__plugin_discord_discord__reply`의 `files: [절대경로]` 파라미터는 schema에 명시되어 있다 (max 10 files, 25MB each). 실제 inbound 메시지 컨텍스트에서만 호출 가능하며, outbound-only 권한 실측은 봇에게 직접 명령을 내려 진행해야 한다.

봇 권한 자체는 OpenClaw discord access.json의 7채널 모두 등록되어 있으며 (확인됨, 2026-05-26 08:21 JST), MCP 도구의 attach 지원도 schema-level 확인됐다.

## 영상 패턴 출처

UsT1-E1Txyo 영상에서 "에이전트가 산출물을 첨부 파일로 깔끔하게 전달한다" 패턴 등장. 본문 텍스트만 보낸 영상의 안티 사례와 대비된다.

## 관련

- [[pitfall-205-openclaw-project-isolation-thread-per-project]] — thread per project 격리
- [[pitfall-208-openclaw-p199-vs-discord-2000-char-limit-conflict]] — 2000자 제한
- [[pitfall-214-openclaw-autonomous-continuation-prompt-overnight]] — 자율 사이클 + attach 결합
