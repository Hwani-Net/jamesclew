---
title: Tavily 로테이터가 HTTP 432(plan usage limit)를 감지 못해 키 로테이션 실패
tags: [tavily, rotation, mcp, http-status]
date: 2026-04-19
---

## 증상
Tavily MCP 호출 시 "This request exceeds your plan's set usage limit" 에러 반환.
6개 키 중 1개(Key 0)만 소진 상태인데 나머지 5개로 자동 전환되지 않음.

## 원인
`~/.claude/scripts/tavily-rotator.mjs` 가 `res.status === 429 || res.status === 402` 만 rotate 조건으로 검사.
Tavily는 플랜 한도 초과 시 **HTTP 432 (비표준 고유 코드)** 로 응답함. 432를 놓쳐서 첫 번째 exhausted 키에 갇힘.

## 해결
1. 로테이터 조건에 `432, 401, 403` 추가
2. 200 OK + body에 "exceeds your plan|usage limit|rate limit" 패턴이면 body 기반 rotate 추가
3. `~/.claude/tavily-rotator.mjs` (루트 복사본)도 동기화 필수

## 재발 방지
- API 공급자의 비표준 상태 코드(432 등) 사용 가능성을 항상 고려
- rotate 조건은 status + body 이중 검증
- 로테이터 수정 시 루트/scripts 양쪽 모두 동기화
- 에러 발생 시 "로테이터가 작동했는가?" 를 먼저 검증: 각 키 HTTP 코드 개별 테스트

## 진단 스니펫
```bash
for i in 0 1 2 3 4 5; do
  KEY=$(jq -r ".[$i]" ~/.claude/tavily-keys.json)
  CODE=$(curl -s --max-time 10 -X POST https://api.tavily.com/search \
    -H "Content-Type: application/json" \
    -d "{\"api_key\":\"$KEY\",\"query\":\"test query\",\"max_results\":3}" \
    -o /dev/null -w "%{http_code}")
  echo "Key $i: HTTP $CODE"
done
```
