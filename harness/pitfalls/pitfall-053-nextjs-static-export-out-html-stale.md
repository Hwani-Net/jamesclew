# P-053: Next.js standalone 빌드 — out/index.html 구버전 유지

**증상**: `npm run build` 후 `_next/static` 복사 + Firebase 재배포해도 라이브 사이트가 이전 UI를 서빙.

**원인**: `out/` 폴더의 HTML 파일들은 자동으로 갱신되지 않음. `_next/static`(CSS/JS) 만 교체하면 HTML은 구버전 구조(사이드바 없음 등)를 그대로 참조.

**해결**:
```bash
rm -rf out
npm run build
mkdir -p out/_next
cp .next/server/app/index.html out/index.html
cp -r .next/server/app/login out/login
cp -r .next/server/app/patterns out/patterns
cp -r .next/server/app/sessions out/sessions
cp -r .next/static out/_next/static
firebase hosting:channel:deploy ...
```

**검증**: `grep "Live Feed\|GAP Patterns" out/index.html` — 신규 컴포넌트 내용 확인 후 배포.

**재발 방지**: `package.json`에 deploy script 추가:
```json
"deploy:preview": "rm -rf out && next build && node scripts/build-static.js && firebase hosting:channel:deploy preview --expires 7d"
```
