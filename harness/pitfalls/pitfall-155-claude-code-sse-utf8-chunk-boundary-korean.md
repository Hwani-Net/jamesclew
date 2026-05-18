---
title: pitfall-155 — Claude Code SSE 스트림이 한국어 UTF-8 3바이트를 청크 경계에서 깨뜨림
slug: pitfall-155-claude-code-sse-utf8-chunk-boundary-korean
date: 2026-05-16
tier: distilled
tags: [claude-code, korean, hangul, sse, streaming, utf-8, encoding, bug]
---

## 증상
Claude Code 응답 본문의 한국어가 자모 단위로 어긋나거나 영문자가 한글 자리에 끼어든다.
- "결정" → "겳정" (받침이 다른 글자로 변형)
- "대표님이 이미" → "대표님이h이미e" (공백/한글 자리에 ASCII 끼어듦)
- "이미" → "i미e"

일반 mojibake(`?`, `□`, `ÄÇ`)와 다른 양상. byte-level split + 잘못된 합성 패턴.

## 원인 (확정)
**Claude Code 클라이언트의 SSE(Server-Sent Events) 디코더가 UTF-8 multi-byte char를 청크 경계에서 분리해 잘못 합성.**

- 한국어 1글자 = UTF-8 3바이트 (예: `를` = `0xEB 0xA5 0xBC`)
- SSE 청크 경계에서 3바이트 중 일부가 다른 청크로 분리되면, 디코더가 첫 청크의 2바이트 + 다음 청크의 1바이트를 각각 잘못 디코딩
- 결과: U+FFFD 대체, 잘못된 받침, ASCII fallback
- **모델 출력은 정상**. 클라이언트(claude CLI) SSE 디코더 단의 결함

`AskUserQuestion` 도구 응답에서 특히 두드러진다 (issue #57981).

## 해결
`~/.claude/settings.json` env 영역에 다음 추가:
```json
"env": {
  "CLAUDE_CODE_FORCE_SYNC_OUTPUT": "1",
  "CLAUDE_CODE_NO_FLICKER": "0",
  ...
}
```
- `CLAUDE_CODE_FORCE_SYNC_OUTPUT=1` — v2.1.129 신설. 동기 출력 모드로 청크 경계 깨짐 회피 (CLAUDE.md에 이미 문서화됨)
- `CLAUDE_CODE_NO_FLICKER=0` — 새 렌더러 비활성화 (보조)

세션 재시작 필요 (env는 세션 시작 시점 로딩).

## 관련 GitHub Issues
- [#47013](https://github.com/anthropics/claude-code/issues/47013) Korean characters corrupted during streaming (U+FFFD replacement)
- [#45508](https://github.com/anthropics/claude-code/issues/45508) Streaming output corrupts CJK characters at UTF-8 chunk boundaries
- [#57981](https://github.com/anthropics/claude-code/issues/57981) Intermittent Korean syllable corruption in AskUserQuestion
- [#56917](https://github.com/anthropics/claude-code/issues/56917) Mixed CJK characters in Korean text
- [#40396](https://github.com/anthropics/claude-code/issues/40396) macOS+VSCode 한국어 응답 깨짐

## 재발 방지
1. 사용자가 "한국어가 깨진다" 보고하면 **즉시 모델 출력 단을 의심하지 말고 클라이언트 SSE 디코더 단을 확인**.
2. "결정→겳정"처럼 자모 합성이 어긋난 패턴은 **byte boundary split의 시그니처**. mojibake와 구분.
3. 터미널 코드페이지(chcp 949), CLAUDE.md 규칙을 1차 원인으로 단정하지 말 것 — 이번 진단에서 메인 Opus가 그렇게 단정해 대표님 정정을 받음.
4. 한국어 입력/복사 이슈(#42482, #38520)와 한국어 출력 깨짐 이슈(#47013, #45508)는 **별개 메커니즘**임을 구분.
5. 모델 출력 단계의 깨짐인지 클라이언트 단계의 깨짐인지 의심되면, 동일 텍스트를 `printf "..."`로 bash에서 직접 출력해 비교.

## 관련 pitfall
- [[pitfall-118-adapter-korean-stdout-encoding]]
- [[pitfall-148-korean-cwd-lone-surrogate-jsonl]]
- [[pitfall-142-adapter-stream-true-no-fallback-final-rootcause]]
