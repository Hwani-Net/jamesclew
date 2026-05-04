---
slug: pitfall-085-browser-permission-popup-blind-spot
tags: [pitfall, browser-automation, claude-in-chrome, computer-use, permission-popup]
date: 2026-04-30
project: 영상제작 (ChatGPT UI 9컷 자동화)
---

# P-085: 자동 다운로드 실패 시 브라우저 권한 팝업 의심 우선

- **발견**: 2026-04-30
- **프로젝트**: 영상제작 ChatGPT UI 스토리보드 9컷 자동 다운로드
- **심각도**: MEDIUM (사용자 시간 낭비 + 신뢰 손상)

## 증상
- claude-in-chrome으로 ChatGPT UI 자동화 중 CUT01/CUT02는 자동 다운로드 성공, CUT03부터 실패
- 나는 "Chrome user gesture 부족 → 보안 차단"으로 단정하고 수동 다운로드 대안 제시
- 실제로는 Chrome이 "이 사이트가 여러 파일을 자동으로 다운로드하려고 합니다 — 허용/차단" 팝업을 띄움
- 대표님이 처음에는 못 봤다가 발견하여 허용 → 권한 허용 후 자동 다운로드 정상 작동

## 원인
1. claude-in-chrome / expect MCP는 페이지 내부 DOM만 인식. **브라우저 chrome (탭/주소창/팝업)/native 다이얼로그는 desktop-control만 인식 가능**
2. 추측만으로 "Chrome 보안 정책" 단정 → 검증 없는 진단
3. desktop-control(computer use) 도구를 "적재적소" 활용 못 함

## 해결
- claude-in-chrome 자동 다운로드 실패 시 **첫 행동**: `mcp__desktop-control__computer(action: "get_screenshot")`으로 **전체 모니터 화면 캡처** → 권한 팝업/다이얼로그 직접 인식
- 적재적소에 도구 분리:
  - 페이지 내부 자동화: claude-in-chrome / expect MCP
  - **브라우저 chrome / 권한 팝업 / 다이얼로그 / OS 레벨 알림**: desktop-control (computer use)
- 다운로드 N회 연속 시 Chrome이 "여러 파일 자동 다운로드" 권한 팝업 자동 표시 → desktop-control screenshot으로 감지 후 "허용" 버튼 좌표 클릭
- 자동화 시작 전 desktop-control screenshot으로 화면 사전 점검 권장
- 사용자에게 묻기 **전에** desktop-control 시도

## 재발 방지 체크리스트
- [ ] claude-in-chrome 작업 시작 시 사전 안내: "권한 팝업 뜨면 desktop-control로 자동 처리 시도"
- [ ] 다운로드 실패 시 즉시 desktop-control screenshot
- [ ] 보안 정책 단정 전에 화면 점검 필수
- [ ] 페이지 외부 UI는 desktop-control 전용 인식

## 메모리 연동
- `feedback_browser_permission_popup.md` (memory)
