---
slug: pitfall-129-windows-cp949-stdout-reconfigure
title: "Windows cp949 콘솔에서 ✓/✅/⚠️ 등 유니코드 print 시 UnicodeEncodeError"
date: 2026-05-08
tags: [python, windows, encoding, cp949, connect-ai]
severity: high
---

## 증상
Connect AI extension(또는 Windows PowerShell/cmd) 한국어 환경에서 Python 도구 실행 시:

```
UnicodeEncodeError: 'cp949' codec can't encode character '✓' in position 25: illegal multibyte sequence
```

`✓`(U+2713), `✅`(U+2705), `⚠️`(U+26A0+FE0F), `❌`(U+274C), `─`(U+2500), `…`(U+2026) 등을 print하면 한국어 Windows 기본 콘솔 인코딩(cp949)이 인코딩 못 해 즉시 종료. Connect AI 패널에는 stderr Traceback이 cp949로 또 깨져서 `✓`, `❶❶s` 같은 이중 깨짐이 표시됨.

## 원인
- Windows 한국어 로캘의 `sys.stdout.encoding`은 기본적으로 `cp949`
- cp949는 BMP 외/일부 기호 미지원
- Python 3.7+ stdout/stderr는 텍스트 모드 TextIOWrapper인데, 인코딩이 cp949로 고정되어 있으면 utf-8 문자 인코딩 시 예외
- Connect AI extension은 도구 stdout을 그대로 패널에 표시하므로 도구 종료 + 깨짐 둘 다 노출

## 해결
스크립트 최상단(첫 import 직후)에 stdout/stderr를 utf-8로 reconfigure:

```python
import os, json, sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
```

- Python 3.7+ 필요 (TextIOWrapper.reconfigure)
- 호출자(extension) 변경 없이 도구 측에서 자체 보정
- `errors="replace"`로 reconfigure 실패 케이스(예: 파이프된 binary stdout) 안전 fallback
- 환경변수 `PYTHONIOENCODING=utf-8`도 동작하지만 Connect AI 호출 환경 보장 어려움 → 스크립트 내부 보정이 더 견고

## 재발 방지
- ConnectAI `_agents/*/tools/*.py` 신규 생성 시 stdout reconfigure 블록 템플릿 강제
- 검증: `chcp 949 + PYTHONIOENCODING 비움 + python tool.py` → exit 0 + 한글/이모지 정상
- 일괄 패치는 PowerShell `-Command` 인자에 escape 지옥 → 임시 `.py` 분리 (이번 사고에서 PowerShell `\"` escape가 sub-bash 래퍼에서 깨져 빈 문자열 인자로 패치됨)

## 적용 이력 (2026-05-08)
13개 도구 파일 일괄 패치 완료:
- secretary/tools/google_calendar_write.py
- editor/tools/{music_to_video, music_generate, music_studio_setup}.py
- youtube/tools/{competitor_brief, auto_planner, trend_sniper, telegram_notify, channel_full_analysis, my_videos_check, comment_harvester, youtube_account}.py
- secretary/tools/telegram_setup.py

검증: 13/13 syntax OK, cp949 콘솔에서 깨짐 없이 출력 확인.
