# Security Rules

## Secret Protection
소스 코드에 시크릿 작성 금지. 환경변수($VAR) 사용.
.env, credentials, *.pem, *.key 파일 수정 금지 (hook이 차단).

## Destructive Operations
rm -rf, format, del /s/q → deny list에서 차단.
확실하지 않은 삭제/덮어쓰기 → 실행 전 확인.
