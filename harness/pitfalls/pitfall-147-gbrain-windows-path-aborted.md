---
slug: pitfall-147-gbrain-windows-path-aborted
title: "gbrain PGLite Windows 경로 Aborted() 버그"
symptom: "gbrain 모든 명령에서 Aborted(). Build with -sASSERTIONS for more info."
tags: [gbrain, pglite, windows, bun, encoding, path]
date: 2026-05-11
---

## 증상
```
Aborted(). Build with -sASSERTIONS for more info.
```
gbrain query/import/init 모든 명령 실패. postmaster.pid 삭제해도 무관.

## 원인
Bun의 PGLite NodeFS가 경로를 잘못 변환:
- `C:/Users/...` → `C:\c\Users\...` (Aborted)  
- `/c/Users/...` → `C:\c\Users\...` (ENOENT)
- `C:\Users\...` (백슬래시) → 정상 동작

~/.gbrain/config.json의 database_path가 `C:/Users/...` (슬래시) 형식이면 PGLite WASM이 잘못된 경로로 접근 → 런타임 abort.

## 해결
1. DB를 백슬래시 경로에 새로 init:
   ```bash
   gbrain init --pglite --path "C:\Users\AIcreator\AppData\Roaming\gbrain\brain.pglite"
   ```
2. config.json이 자동으로 올바른 백슬래시 경로로 업데이트됨
3. 기존 데이터 재import:
   ```bash
   gbrain import D:/jamesclew/harness/pitfalls/ --no-embed
   ```

## 재발 방지
- gbrain init 시 반드시 `--path "C:\Users\..."` (백슬래시) Windows 경로 명시
- config.json database_path에 슬래시(`/`) 경로 금지
- DB 위치: `C:\Users\AIcreator\AppData\Roaming\gbrain\brain.pglite` (영구)
