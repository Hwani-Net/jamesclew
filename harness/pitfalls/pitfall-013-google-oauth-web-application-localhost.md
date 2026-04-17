---
type: pitfall
id: P-013
title: "Google OAuth \"Web application\" 타입 클라이언트는 localhost redirect 불가"
tags: [pitfall, jamesclew]
---

# P-013: Google OAuth "Web application" 타입 클라이언트는 localhost redirect 불가

- **발견**: 2026-04-13
- **증상**: Blogger OAuth2 토큰 발급 시 `400 redirect_uri_mismatch`. `http://localhost`, `http://localhost:8090`, OOB(`urn:ietf:wg:oauth:2.0:oob`) 전부 실패
- **원인**: OAuth 클라이언트가 "웹 애플리케이션" 타입으로 생성됨. Web 타입은 정확한 redirect URI 등록 필수 + OOB는 2022년 deprecated. "데스크톱 앱" 타입만 localhost 자동 허용
- **해결**: Google Cloud Console에서 "데스크톱 앱" 타입 OAuth 클라이언트 신규 생성 → client_id/secret 교체 → `InstalledAppFlow.run_local_server()` 정상 동작
- **재발 방지**: Google OAuth 클라이언트 생성 시 CLI/스크립트용은 반드시 "데스크톱 앱" 타입 선택. "웹 애플리케이션"은 브라우저 콜백이 있는 웹앱 전용
