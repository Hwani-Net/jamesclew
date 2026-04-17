---
type: pitfall
id: P-030
title: "/ultrareview를 무료로 오인하여 pipeline-run에 의존"
tags: [pitfall, jamesclew]
---

# P-030: /ultrareview를 무료로 오인하여 pipeline-run에 의존

- **발견**: 2026-04-17
- **증상**: v2.1.111 신규 `/ultrareview`를 기본 품질 검수 도구로 pipeline-run에 편입했으나 대표님이 "체험권 3회 + 유료"를 확인
- **원인**: 공식 changelog·docs에서 과금 정책을 명시 안 함. 웹 검색으로도 확정 못 함. 대표님 실제 환경이 Evidence-First
- **해결**: pipeline-run을 codex-rotate.sh + curl :4141 GPT-4.1로 되돌림. /ultrareview는 "선택적 유료"로 표시
- **재발 방지**: Claude Code 신규 스킬 도입 전 실제 환경에서 호출해 과금·제한 확인. 공식 docs만 신뢰하지 말 것
