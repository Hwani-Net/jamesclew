---
type: pitfall
id: P-040
title: "gbrain pglite WASM Aborted — Windows 경로 형식 + 패키지 오염"
tags: [pitfall, jamesclew]
---

# P-040: gbrain pglite WASM Aborted — Windows 경로 형식 + 패키지 오염

- **발견**: 2026-04-17
- **증상**: gbrain query/list/init 모두 Aborted 에러
- **원인 (복합)**: 1) bun install -g gbrain이 npm GPU JS 라이브러리 설치 (실제는 github:garrytan/gbrain) 2) pglite WASM이 Windows C:\ 경로 처리 못함, /c/Users/... Git Bash 경로만 동작 3) 기존 brain.pglite도 구버전 호환성 문제
- **해결**: github:garrytan/gbrain 직접 클론 + npm global 복사. gbrain init --pglite --path "/c/Users/..." 필수. config.json도 /c/ 형식. gbrain put은 stdin 안 됨, --content 필수
- **재발 방지**: bun install -g gbrain 금지. database_path는 /c/Users/... 형식. import 스크립트는 Python subprocess 사용
