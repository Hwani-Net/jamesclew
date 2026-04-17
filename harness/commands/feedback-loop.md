---
name: feedback-loop
description: 배포 후 프로덕션 피드백 수집·집계 → 에이전트 개선 태스크 자동 생성
triggers:
  - /feedback-loop
args:
  - name: project
    description: Firebase 프로젝트 ID (미입력 시 .firebaserc에서 자동 탐지)
    required: false
  - name: date
    description: 피드백 기준 날짜 (YYYY-MM-DD, 미입력 시 오늘)
    required: false
---

# /feedback-loop — 프로덕션 피드백 수집 스킬

배포 후 24시간 또는 7일 시점에 Firebase · GA4 · Search Console · 에러 로그를 수집하고,
임계치 미달 항목은 **개선 태스크**로 자동 등록합니다.

## 실행 흐름

### Step 1. 프로젝트 식별

```bash
# Firebase 프로젝트 ID 탐지
PROJECT_ID=$(cat .firebaserc 2>/dev/null | grep -oP '"default"\s*:\s*"\K[^"]+' || echo "")
if [ -z "$PROJECT_ID" ]; then
  echo "[feedback-loop] .firebaserc 없음 — 수동 입력 필요"
  # → 수동 입력 섹션 진행
fi

# Hosting 도메인 목록
firebase hosting:sites:list --project "$PROJECT_ID" 2>/dev/null || true
```

### Step 2. Google Analytics 4 수집

**방법 A — GA4 Data API (권장)**

```bash
# 사전 조건: gcloud CLI 인증, GA4 Property ID 환경변수
# export GA4_PROPERTY_ID=properties/XXXXXXXXX

DATE_FROM=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)
DATE_TO=$(date +%Y-%m-%d)

curl -s -X POST \
  "https://analyticsdata.googleapis.com/v1beta/${GA4_PROPERTY_ID}:runReport" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d "{
    \"dateRanges\": [{\"startDate\": \"${DATE_FROM}\", \"endDate\": \"${DATE_TO}\"}],
    \"metrics\": [
      {\"name\": \"sessions\"},
      {\"name\": \"averageSessionDuration\"},
      {\"name\": \"bounceRate\"},
      {\"name\": \"screenPageViews\"}
    ],
    \"dimensions\": [{\"name\": \"pagePath\"}]
  }" | jq '.rows[] | {page: .dimensionValues[0].value, sessions: .metricValues[0].value, avgDuration: .metricValues[1].value, bounceRate: .metricValues[2].value}'
```

**방법 B — 수동 입력 (GA4 API 미설정 시)**

아래 항목을 GA4 콘솔(analytics.google.com)에서 복사:
- 세션 수, 평균 세션 시간, 이탈률, 상위 5 페이지

### Step 3. Google Search Console 수집

```bash
# export GSC_SITE_URL=https://your-site.web.app

curl -s -X POST \
  "https://searchconsole.googleapis.com/webmasters/v3/sites/$(python3 -c "import urllib.parse; print(urllib.parse.quote('${GSC_SITE_URL}', safe=''))")/searchAnalytics/query" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d "{
    \"startDate\": \"${DATE_FROM}\",
    \"endDate\": \"${DATE_TO}\",
    \"dimensions\": [\"query\"],
    \"rowLimit\": 10
  }" | jq '.rows[] | {query: .keys[0], clicks: .clicks, impressions: .impressions, ctr: .ctr, position: .position}'
```

**수동 입력 (미설정 시)**: Search Console → 검색 결과 → 상위 10 쿼리 복사

### Step 4. 콘솔 에러 수집

```bash
# Sentry (설정된 경우)
if [ -n "$SENTRY_AUTH_TOKEN" ] && [ -n "$SENTRY_ORG" ] && [ -n "$SENTRY_PROJECT" ]; then
  curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
    "https://sentry.io/api/0/projects/${SENTRY_ORG}/${SENTRY_PROJECT}/issues/?limit=5&query=is:unresolved" \
    | jq '.[] | {title: .title, count: .count, firstSeen: .firstSeen}'
else
  echo "[feedback-loop] Sentry 미설정 — Firebase Crashlytics 또는 수동 수집"
  # Firebase Crashlytics: 콘솔 → Crashlytics → 최근 이슈 수동 기록
fi
```

### Step 5. 결과 집계 및 임계치 판단

```bash
OUTPUT_DIR="docs"
mkdir -p "$OUTPUT_DIR"
DATE_TAG=$(date +%Y-%m-%d)
OUTPUT_FILE="${OUTPUT_DIR}/feedback-${DATE_TAG}.md"

cat > "$OUTPUT_FILE" << FEEDBACK_EOF
# Feedback Report — ${DATE_TAG}

## 수집 범위: ${DATE_FROM} ~ ${DATE_TO}

## GA4 지표
| 지표 | 값 | 임계치 | 판정 |
|------|-----|--------|------|
| 평균 세션 시간 | {AVG_DURATION}초 | ≥ 30초 | {PASS/FAIL} |
| 이탈률 | {BOUNCE_RATE}% | ≤ 80% | {PASS/FAIL} |
| 총 세션 | {SESSIONS} | — | — |

## Search Console
| 쿼리 | 클릭 | 노출 | CTR | 순위 |
|------|------|------|-----|------|
{쿼리 데이터}

## 에러 로그
{에러 목록 또는 "에러 없음"}

## 개선 필요 항목
{임계치 미달 목록}
FEEDBACK_EOF

echo "[feedback-loop] 저장 완료: $OUTPUT_FILE"
```

### Step 6. 임계치 미달 → 개선 태스크 자동 생성

아래 조건 중 하나라도 해당하면 TodoWrite로 태스크 생성:

| 임계치 | 조건 | 태스크 내용 |
|--------|------|-----------|
| 평균 세션 시간 | < 30초 | "체류 시간 개선: 콘텐츠 보완 또는 페이지 로드 최적화" |
| 이탈률 | > 80% | "이탈률 개선: 히어로 섹션 또는 CTA 재설계" |
| Search Console 클릭 | 상위 키워드 0건 | "SEO 개선: 타겟 키워드 재설정 + 메타 태그 보강" |
| 에러 이슈 | 1건 이상 | "프로덕션 에러 수정: {에러 제목}" |

```bash
# TodoWrite 예시 (에이전트가 판단하여 실행)
# TodoWrite(title="체류 시간 개선", priority="high", context="평균 ${AVG}초 < 30초 임계치")
```

## 수동 입력 섹션 (API 미연결 시)

GA4/Search Console API 인증이 없는 경우:

```
GA4 수동 입력:
- 평균 세션 시간: ___초
- 이탈률: ___%
- 총 세션: ___
- 상위 페이지: ___

Search Console 수동 입력:
- 총 클릭: ___
- 총 노출: ___
- 상위 쿼리: ___
```

에이전트가 수동 값을 입력받아 Step 5 판단 수행.

## 수집 주기 안내

- **배포 후 24시간**: `bash $HOME/.claude/scripts/feedback-loop-run.sh 1d`
- **배포 후 7일**: `bash $HOME/.claude/scripts/feedback-loop-run.sh 7d`
- Remote Trigger 등록: `/schedule "feedback-loop 7d" --cron "0 9 * * 1"` (매주 월 9시)

## 환경변수 요구사항

| 변수 | 용도 | 필수 |
|------|------|------|
| `GA4_PROPERTY_ID` | GA4 Data API | GA4 연동 시 |
| `GSC_SITE_URL` | Search Console API | GSC 연동 시 |
| `SENTRY_AUTH_TOKEN` | Sentry 에러 수집 | Sentry 사용 시 |
| `SENTRY_ORG` | Sentry 조직 | Sentry 사용 시 |
| `SENTRY_PROJECT` | Sentry 프로젝트 | Sentry 사용 시 |

gcloud 인증: `gcloud auth application-default login`
