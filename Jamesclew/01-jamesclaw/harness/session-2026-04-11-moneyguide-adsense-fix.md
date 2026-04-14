# Session: MoneyAgent — moneyguide.one AdSense 수정 + 도구 매뉴얼 체계화

**날짜**: 2026-04-10 ~ 04-11
**프로젝트**: D:/MoneyAgent (moneyguide-kr)
**커밋**: `179d20e` (master)

---

## 세션 개요
- moneyguide.one AdSense "가치가 별로 없는 콘텐츠" 거절 → 8가지 수정 후 재심사 준비 완료
- MCP/Plugin/Skill 전체 도구 매뉴얼 체계화 (75도구+17스킬)
- NotebookLM MCP 제거 → CLI 통일 (도구 14개 절감)
- expect 풀 검증 패턴 확립 (7단계)

## 핵심 성과

### moneyguide.one AdSense 수정 (8가지)
1. SPA→SSG 전환: Puppeteer prerender 57개 정적 HTML
2. 중복 slug 정리: 71→47개
3. 하드코딩 텍스트 동적화: 카테고리별 전문가팁/핵심정리
4. sitemap 재생성: 28→57개 URL
5. About 페이지 E-E-A-T 강화
6. 썸네일 전수 교체: 47개 아티클 전부 고유 Unsplash 이미지 (46개 ID 200 검증)
7. 개인정보처리방침 보강: 6→11항목 (보유기간, 파기절차, 이용자 권리 등)
8. 면책조항 보강: 3→8항목 (AI 콘텐츠 고지, 광고/제휴 공개 등)

### 접근성 개선
- 텍스트 대비율 WCAG AA 수정 (slate-300→500 등)
- 키보드 포커스 인디케이터 추가
- aside aria-label, 이메일 aria-label 추가
- 접근성 위반 52→35건 (-17건, 남은 건 AdSense iframe false positive)

### 성능
- FCP 1196ms, LCP 1196ms, CLS 0.015, TTFB 325ms — 전부 Good

### 도구 매뉴얼 체계화
- 8개 매뉴얼 파일 생성 (memory/reference_*.md)
- expect, Perplexity, Tavily, NotebookLM, Telegram, Stitch, Excalidraw+PDF, Skills
- NotebookLM Agent Harness Blueprint에 소스 8개 추가 완료 (nlm CLI 경유)

### 인프라 개선
- NotebookLM MCP 제거 → nlm CLI 통일 (인증 안정화 + 도구 14개 절감)
- Gemma 4 로컬을 Antigravity 폴백으로 설정 (토큰 절약)
- expect 배포 후 검증 7단계 패턴 확립

### 병렬 완료
- kmong-register-package.md: 크몽 복사-붙여넣기 등록 패키지
- tistory-posts/2026-04-10.md + naver-posts/2026-04-10.md: 블로그 콘텐츠
- seo-research/2026-04-11.md: 내일용 SEO 키워드+아웃라인

## PITFALLS 신규
- P-013: 배포 후 시각적 검증 미실시 — 썸네일 중복 미감지
- P-014: Antigravity 차단 시 Sonnet 대체 → 토큰 절약 무의미 → Gemma 4 폴백
- P-015: 검증 완료 후 브라우저 미종료 + 완료 보고 누락

## 다음 세션 작업
1. **MultiBlog 품질 발행 시스템 PRD** — E:/AI_Programing/blog-auto/MultiBlog/ 새 세션에서 /prd
   - 기존 MultiBlog PRD를 확장: 발행 자동화 + 품질 검수 루프
   - 핵심: 자동 리서치→생성→발행→expect 검증→교차검수→PITFALLS 체크→텔레그램 보고
2. 크몽 서비스 등록 (대표님 수동, 패키지 준비 완료)
3. AdSense 검토 요청 (대표님 수동)
4. moneyguide-kr git push (대표님 확인 후)

## 피드백 기록
- 말투 자연스럽게 (딱딱한 보고체 금지)
- 교차검수 폴백: Codex→Antigravity→Gemma 4 로컬→Sonnet(최후)
- NotebookLM 인증: refresh_auth→nlm CLI 경유→nlm login 순서
- expect 도구 8개 전부 활용 (screenshot만 쓰지 말고 console_logs+performance+a11y까지)
