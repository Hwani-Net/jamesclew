---
type: pitfall
id: P-036
title: "영상 렌더 검증을 메타데이터만으로 판정 — 프레임 실측 없이 성공 보고"
tags: [pitfall, jamesclew]
---

# P-036: 영상 렌더 검증을 메타데이터만으로 판정 — 프레임 실측 없이 성공 보고

- **발견**: 2026-04-17
- **증상**: VideoStudio 첫 숏츠 렌더 후 "검증 완료" 보고. 대표님이 재생해보니 전부 [B-roll placeholder] 회색 텍스트만
- **원인**: 검증 범위가 파일 존재 + ffprobe 메타 + 빌드 로그에 국한. 프레임 시각 확인 안 함
- **해결**: 렌더 후 ffmpeg로 5초 간격 프레임 추출 + Read로 5장 이상 시각 검증. AI B-roll 없으면 "placeholder 상태" 명시
- **재발 방지**: regression-autotest.sh에 mp4 자동 프레임 추출 + Read 강제. 빌드 성공 ≠ 콘텐츠 품질
