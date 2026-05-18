---
slug: pitfall-139-ps1-no-bom-cp949-mojibake-injection
title: PowerShell 스크립트 UTF-8 BOM 부재 → PS 5.1 cp949 read → 한국어 string literal mojibake → extension.js inject
date: 2026-05-09
tags: [powershell, utf-8, bom, cp949, mojibake, encoding, repatch, korean-locale]
severity: high
---

# ps1 UTF-8 BOM 부재로 PowerShell 5.1이 cp949로 read하여 한국어 prompt가 mojibake로 inject

## 증상
- Connect AI Chat의 autoCycle "You" 메시지에 깨진 한글:
  ```
  [?맺쏙 ?ㅎ씼?? ?끃옾 誘몃믯?????쌔꾈 吏곷瑚?쇕쩖?? researcher?ㅁ developer?맥퀼...
  ```
- 의도한 prompt: `[자율 사이클] 현재 미션을 한 스텝 진행하세요. researcher와 developer에게...`

## 원인 (인코딩 cascade)
1. `D:/jamesclew/harness/scripts/connect-ai-adapter/repatch-extension.ps1` 가 **UTF-8 BOM 없이 저장됨** (first 3 bytes = `# C` = ASCII)
2. PowerShell 5.1 (Windows 기본 + 한국어 로캘 cp949)이 BOM 없는 파일을 **cp949 코드 페이지로 read**
3. ps1 안의 한국어 string literal `'[자율 사이클]...'`이 cp949 byte sequence로 해석됨 → `$jsonPrompt` 변수가 깨진 byte 보유
4. `[System.IO.File]::WriteAllText($jsPath, $content, $utf8NoBom)` — UTF-8로 저장은 했지만 변수 값 자체가 이미 mojibake
5. extension.js에 inject된 PATCH v6.8 prompt가 깨진 한국어 byte sequence로 영구 저장
6. `runCorporatePromptExternal(prompt, model)` 호출 시 chat history에 깨진 문자열로 표시

## 검증된 측정
```
ps1 first 3 bytes hex: 232043 ("# C")  ← BOM 없음
PowerShell version:    5.1.26100.8115
extension.js line 28167 prompt:
  '[?먯쑉 ?ъ씠?? ?꾩옱 誘몄뀡?????ㅽ뀦 吏꾪뻾?섏꽭?? ...'  ← cp949→UTF-8 mojibake
```

## 해결 (2단계)

### Fix 1: ps1에 UTF-8 BOM 추가 (영구 — 다음 cron 사이클부터 정상)
```python
raw = ps1.read_bytes()
if raw[:3] != bytes.fromhex("efbbbf"):
    ps1.write_bytes(bytes.fromhex("efbbbf") + raw)
```
PowerShell 5.1은 BOM 발견 시 UTF-8로 read.

### Fix 2: extension.js 즉시 cleanup (현재 적용된 mojibake 정정)
line 28167의 깨진 prompt를 정상 한국어 string literal로 직접 교체. node --check PASS.

## 재발 방지 체크리스트
1. **모든 ps1 파일은 UTF-8 BOM 필수** — 한국어 string literal 포함 시
2. **검증 명령**: `python -c "print(open('file.ps1','rb').read()[:3].hex())"` → `efbbbf` 여야 함
3. **PowerShell 7 (pwsh) 사용 시 BOM 불필요** — UTF-8 default. 단 Windows 기본 PS 5.1 호환 위해 BOM 권장
4. **git commit 시 .gitattributes 설정**: `*.ps1 working-tree-encoding=UTF-8-BOM` 검토
5. **신규 ps1 작성 시 첫 commit에서 BOM 확인** — Cursor/VS Code의 "UTF-8" vs "UTF-8 with BOM" 명시

## 관련 PITFALL
- pitfall-137 powershell-stderr-cp949-corruption (P11 OutputEncoding wrap)
- pitfall-129 windows-cp949-stdout-reconfigure (Python 측)

## 관련 파일
- `D:/jamesclew/harness/scripts/connect-ai-adapter/repatch-extension.ps1` (BOM 추가됨)
- `C:/Users/AIcreator/.antigravity/extensions/connectailab.connect-ai-lab-2.89.58-universal/out/extension.js` (line 28167 cleanup)

## 인용 (대표님 원문)
> "이 알수없는 문자로 명령을 내렷던데 이건 뭐가 문제였어?"

대표님 화면 캡처가 결정적 단서. mojibake 패턴(`?먯쑉 ?ъ씠?`)이 cp949→UTF-8 mismatch 특유의 형태 → ps1 인코딩 추적 → BOM 부재 발견.
