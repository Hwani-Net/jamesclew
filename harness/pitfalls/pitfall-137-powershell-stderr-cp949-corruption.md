---
slug: pitfall-137-powershell-stderr-cp949-corruption
title: Connect AI extension의 PowerShell 호출 시 한국어 stderr가 cp949로 출력되어 UTF-8 디코딩 깨짐
date: 2026-05-08
tags: [connect-ai, powershell, encoding, cp949, utf-8, runCommandCaptured, korean-locale]
severity: medium
---

# Connect AI extension의 PowerShell 호출 시 한국어 stderr가 cp949로 출력되어 UTF-8 디코딩 깨짐

## 증상
- Connect AI Developer/Researcher 에이전트가 PowerShell 명령 실행 후 stderr가 깨진 문자로 표시:
  ```
  [31;1m�Ű� ������ �����Ƿ� ������ ó���� �� �����ϴ�.[0m
  ```
- 진짜 메시지: "매개 변수가 많으므로 명령을 처리할 수 없습니다."
- LLM이 깨진 메시지를 보고 명령 실수를 수정하지 못함 → 무한 retry 루프

## 원인
1. Windows 한국어 로캘 (Active Code Page 949 = cp949)
2. PowerShell은 console output을 cp949로 인코딩
3. Connect AI extension의 `runCommandCaptured` (line 15201) 가 stdout/stderr를 UTF-8로 디코딩
4. cp949 → UTF-8 디코딩 mismatch → 깨진 문자

## 검증된 측정 결과
| 명령 prefix | stderr 결과 |
|------------|-----------|
| `chcp 65001` | ❌ 여전히 깨짐 (PowerShell은 chcp 무시) |
| `[Console]::OutputEncoding=[Text.Encoding]::UTF8` | ✅ 정상 한국어 출력 |
| `pwsh -NoProfile` (PowerShell 7) | ✅ 영어 출력 (locale 따름) |

따라서 fix는 PowerShell `-Command` 인자 시작에 `[Console]::OutputEncoding=[Text.Encoding]::UTF8;[Console]::InputEncoding=[Text.Encoding]::UTF8;` 주입.

## 해결 (P11 patch)
**대상**: `~/.antigravity/extensions/connectailab.connect-ai-lab-2.89.58-universal/out/extension.js` line 15201 `runCommandCaptured` 함수.

함수 본문 시작에 wrap 로직 주입:
```javascript
/* PATCH v7.2: PowerShell stderr UTF-8 wrap */
if (typeof cmd === "string" && /^\s*powershell(\.exe)?\s/i.test(cmd)) {
  cmd = cmd.replace(
    /(-Command\s+)("|')?/i,
    "$1$2[Console]::OutputEncoding=[Text.Encoding]::UTF8;[Console]::InputEncoding=[Text.Encoding]::UTF8;"
  );
}
```

**자동 보존**: `D:/jamesclew/harness/scripts/connect-ai-adapter/repatch-extension.ps1` v7.2 — P11 idempotent 체크 + 자동 재적용. Antigravity 자동 update 시 재발해도 1시간 cron이 복구.

## 재발 방지 체크리스트
1. **모든 외부 명령 spawn 시 인코딩 명시** (PowerShell 외 다른 셸도 마찬가지)
2. **Windows 시스템 로캘 변경 (UTF-8) 권장** — 시스템 전역 fix:
   - 설정 → 시간 및 언어 → 언어 및 지역 → 관리 언어 설정 → 시스템 로캘 변경 → "세계 언어 지원을 위해 Unicode UTF-8 사용" 체크
   - 단, 일부 레거시 앱 깨짐 위험
3. **`runCommandCaptured` 같은 spawn wrapper에 자동 인코딩 처리** — 이번 P11 패치 패턴 따라 다른 셸(cmd, bash)도 추가 가능
4. **Connect AI LLM이 PowerShell 한국어 stderr 받으면 자동 stuck** — 향후 LLM에 "stderr 깨지면 인코딩 문제 의심" 지침 추가

## 관련 PITFALL
- pitfall-129 windows-cp949-stdout-reconfigure (Python 측 cp949)
- pitfall-130 silent-stderr-spawn-debugging (extension spawn stderr 누락)
- pitfall-131 korean-ui-english-menu-mismatch (LLM 환경 모름)

## 관련 파일
- `C:/Users/AIcreator/.antigravity/extensions/connectailab.connect-ai-lab-2.89.58-universal/out/extension.js` (line 15201~15207)
- `D:/jamesclew/harness/scripts/connect-ai-adapter/repatch-extension.ps1` (v7.2, P11 블록)

## 인용 (대표님 원문)
> "야. ceo대답이 자꾸 이상한 언어로 나오잖아."
