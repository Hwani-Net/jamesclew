---
slug: pitfall-146-lone-surrogate-json-api-error
title: "lone surrogate → API 400 invalid high surrogate in string"
symptom: "API Error: 400 The request body is not valid JSON: invalid high surrogate in string"
tags: [encoding, json, api, utf-16, surrogate]
date: 2026-05-11
---

## 증상
```
API Error: 400 The request body is not valid JSON: invalid high surrogate in string: line 1 column NNNNN (char NNNNN-1)
```
Claude Code 세션에서 파일 읽기 후 갑자기 발생. 이후 모든 턴에서 동일 에러 반복.

## 원인
세션 중 읽은 파일(또는 Bash 명령 출력)이 단독 UTF-16 서로게이트 문자(U+D800~U+DFFF)를 포함한 채 세션 JSONL 기록에 저장됨.
Claude Code가 API 요청 바디를 JSON으로 직렬화할 때, 단독 서로게이트는 유효한 JSON 문자열로 인코딩 불가 → 400 에러.

발생 경로:
- Windows에서 특정 앱(VS Code, Notion 등)이 UTF-16 BOM 또는 서로게이트 페어 절반만 파일에 저장
- Bash 명령 출력이 잘못된 인코딩 포함
- 컴팩션(compact) 후에도 기록에 잔존

## 해결
1. **즉시**: 해당 세션에서 `/clear` → 새 세션 시작
2. **파일 정리**: 의심 파일 python으로 스캔 후 제거
   ```python
   raw = open('file.md','rb').read()
   text = raw.decode('utf-8', errors='surrogatepass')
   bad = [(i, hex(ord(c))) for i,c in enumerate(text) if 0xD800 <= ord(c) <= 0xDFFF]
   # bad가 있으면:
   clean = text.encode('utf-8', errors='ignore').decode('utf-8')
   open('file.md','w',encoding='utf-8').write(clean)
   ```

## 재발 방지
- 한글 문서(.md, .txt) 읽기 전 인코딩 확인
- `errors='ignore'` 또는 `errors='replace'`로 읽은 뒤 저장하는 습관
- 에러 발생 즉시 `/clear` (같은 세션 계속 사용하면 모든 턴이 실패)
