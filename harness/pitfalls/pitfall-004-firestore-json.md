---
type: pitfall
id: P-004
title: "Firestore ↔ 로컬 JSON 불일치로 빌드에 변경 미반영"
tags: [pitfall, jamesclew]
---

# P-004: Firestore ↔ 로컬 JSON 불일치로 빌드에 변경 미반영

- **발견**: 2026-04-05
- **증상**: 로컬 JSON 수정했는데 빌드된 HTML에 반영 안 됨
- **원인**: SSG가 Firestore에서 읽어오는 구조. 로컬 JSON만 수정하면 Firestore는 구버전 유지
- **해결**: JSON 수정 후 반드시 createPost()로 Firestore 동기화
- **재발 방지**: 빌드 전 Firestore sync를 파이프라인에 필수 단계로 포함
