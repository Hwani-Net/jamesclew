# Quality Rules

## Verification
코드 변경 후 테스트 실행. 빌드 성공 확인 후 커밋.
태스크를 complete로 표시하기 전 반드시 검증.

## Post-Deploy Verification (필수)
배포(`firebase deploy`, `gh-pages`, 등) 실행 후 반드시:
1. 라이브 URL에 HTTP 200 응답 확인 (index, sitemap, 주요 페이지)
2. 검증 통과 시에만 대표님께 결과 보고
3. 검증 실패 시 자동 롤백 또는 즉시 수정 후 재배포
배포 후 검증 없이 보고하면 안 됨. Hook이 자동 검증을 강제함.

## Blog Image Verification (필수)
블로그 제품 이미지 삽입 시 반드시:
1. 쿠팡 제품 페이지 썸네일을 Playwright로 캡처 (제조사 이미지 사용 금지)
2. 각 제품을 별도 브라우저 인스턴스로 접속 (쿠팡 봇 차단 우회)
3. 저장 후 Read 도구로 이미지 내용을 직접 확인 (HTTP 200만으로 검증 완료 판단 금지)
4. 파일 확장자와 실제 포맷 일치 확인 (PNG를 .jpg로 저장하면 브라우저에서 깨짐)
5. 배포 후 Playwright fullPage 스크롤 스크린샷으로 5/5 렌더링 최종 확인

## Self-Healing
1. 에러 메시지 정독 2. 근본 원인 파악 3. 수정 적용
4. 검증 5. 실패 시 3회 대안 시도 6. 3회 실패 후 보고

## Commits
Conventional Commits (영어). 논리적 단위 1커밋.

## Design Doc Sync (필수)
하네스(hooks, rules, settings.json)를 추가/수정하면 반드시 설계 문서도 동시에 업데이트:
- 설계 문서: `C:/Users/AIcreator/Obsidian-Vault/01-jamesclaw/harness/harness_design.md`
- 변경 이력 테이블에 날짜, 변경 내용, 근거 기록
- 설계 문서와 실제 구현이 불일치하면 안 됨
