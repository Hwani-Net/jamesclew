---
type: pitfall
id: P-019
title: "gbrain PGLite DB 손상 — missing chunk 에러"
tags: [pitfall, jamesclew]
---

# P-019: gbrain PGLite DB 손상 — missing chunk 에러

- **발견**: 2026-04-14
- **증상**: `gbrain query` 실행 시 `missing chunk number 0 for toast value` PostgreSQL 에러. 검색 불가
- **원인**: PGLite(WASM Postgres)가 대량 import + embed 후 toast 테이블 불일치. 동시 접근 또는 비정상 종료 가능성
- **해결**: `rm -rf ~/.gbrain/brain.pglite` → `gbrain init --pglite` → `gbrain import` → `gbrain embed --all` 재구축
- **재발 방지**: gbrain DB 손상 시 즉시 재초기화. compact hook에서 gbrain 에러 감지 시 자동 reinit 검토
