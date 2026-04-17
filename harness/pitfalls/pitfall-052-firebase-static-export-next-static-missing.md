# P-052: Firebase Static Export — _next/static 미포함

**증상**: Firebase Preview 배포 후 CSS 없이 plain HTML만 렌더. 텍스트는 보이지만 스타일 전무.

**원인**: Next.js `output: 'standalone'` 빌드 후 `out/` 폴더 수동 구성 시 `.next/static`을 `out/_next/static`으로 복사하지 않으면 CSS/JS 자산 경로 `/_next/static/...`가 404.

**해결**:
```bash
mkdir -p out/_next
cp -r .next/static out/_next/static
firebase hosting:channel:deploy ...
```

**검증**: `curl -s -o /dev/null -w "%{http_code}" {DEPLOY_URL}/_next/static/chunks/*.css` → 200 확인 후 배포 완료 처리.

**재발 방지**: Next.js + Firebase 배포 스크립트에 static 복사 단계 필수 포함. `package.json`에 deploy script 추가:
```json
"deploy:preview": "next build && mkdir -p out/_next && cp -r .next/static out/_next/static && firebase hosting:channel:deploy preview --expires 7d"
```
