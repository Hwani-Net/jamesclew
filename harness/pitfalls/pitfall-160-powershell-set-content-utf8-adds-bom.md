---
title: pitfall-160 — PowerShell Set-Content -Encoding UTF8 + System.Text.Encoding::UTF8이 BOM을 추가해 JSON.parse 실패
slug: pitfall-160-powershell-set-content-utf8-adds-bom
date: 2026-05-17
tier: distilled
tags: [powershell, utf-8, bom, json, encoding, extension-patch, windows]
---

## 증상

PowerShell로 JSON 또는 JS 파일을 작성·수정한 뒤 Node.js/브라우저가 해당 파일을 읽으면:

```
Unexpected token '﻿', "﻿{ "n"... is not valid JSON
```

또는 VS Code Extension API가 `package.json` 로드 시 silent fail, 명령 등록 안 됨.

첫 3바이트 검증:
```bash
python -c "print(open('package.json','rb').read(3).hex())"
# efbbbf  ← BOM (U+FEFF의 UTF-8 인코딩)
```

## 원인

PowerShell 5.x의 두 가지 함수가 **기본적으로 BOM을 추가**한다:

1. **`Set-Content -Encoding UTF8`** — `utf8NoBOM`이 아닌 BOM 포함 UTF-8로 쓰기 (PowerShell 7+은 `utf8NoBOM` 기본이지만 PS5는 BOM)
2. **`[System.IO.File]::WriteAllText(path, content, [System.Text.Encoding]::UTF8)`** — `Encoding.UTF8`은 **`UTF8Encoding(true)`** 인스턴스 = preamble(BOM) 출력 활성화

JSON 표준(RFC 8259)은 BOM을 거부한다. Node.js의 `JSON.parse`, `JSON.parse(fs.readFileSync(...))`는 BOM이 있으면 `SyntaxError`.

## 해결

PowerShell에서 BOM 없는 UTF-8 쓰기:

### 방법 1 — `UTF8Encoding $false` 생성자
```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
```

### 방법 2 — PowerShell 7+ Set-Content
```powershell
Set-Content -Path $path -Value $content -Encoding utf8NoBOM
```

### 방법 3 — 사후 BOM 제거 (긴급 패치)
```python
with open(f, 'rb') as fh: data = fh.read()
if data.startswith(b'\xef\xbb\xbf'):
    with open(f, 'wb') as fh: fh.write(data[3:])
```

## 재발 방지

1. **PowerShell 스크립트로 JSON/JS 파일 작성 시 항상 BOM 없는 UTF-8 사용** — `New-Object System.Text.UTF8Encoding $false` 패턴 기본값으로.
2. **검증 패턴**: 작성 후 즉시 `(Get-Item $path).Length` 또는 Python `read(3).hex()` 로 BOM 확인. 첫 3바이트가 `efbbbf`면 즉시 정정.
3. **VS Code Extension 패치 시 특히 위험** — extension.js + package.json 둘 다 BOM 들어가면 extension 자체가 silent fail, 디버그 어렵다.
4. **Sonnet/Codex 서브에이전트에게 PowerShell 코드 작성 위임 시 명시적으로 "BOM 없는 UTF-8" 요구**. 기본값은 BOM 포함이라는 점을 prompt에 강조.

## 관련 실제 사례

2026-05-17 Connect AI Lab extension에 selectEngineProfile 명령 패치 시:
- `[System.IO.File]::WriteAllText(..., [System.Text.Encoding]::UTF8)` 사용
- 결과: package.json + extension.js 둘 다 BOM 추가됨
- Antigravity가 명령 등록 못 함 → Command Palette에 안 보임
- 증상: `Unexpected token '﻿', "﻿{ "n"... is not valid JSON`

## 관련 pitfall

- [[pitfall-148-korean-cwd-lone-surrogate-jsonl]] — UTF-8 인코딩 다른 결함
- [[pitfall-118-adapter-korean-stdout-encoding]]
