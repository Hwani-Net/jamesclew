# 자격증명 발급 가이드 (2026-05-07)

펫용품 D2C 사업 (GPT-KOREA) 운영을 위한 외부 서비스 자격증명 발급 절차.

## 저장 표준

모든 키는 **`D:/jamesclew/.env-keys`** (글로벌) 또는 **프로젝트별 `.env`** (로컬)에 저장.
- 글로벌(.env-keys): Shopify, mem0, Klaviyo 등 여러 프로젝트 공유 가능한 것
- 프로젝트(.env): 단일 프로젝트 전용 (Firebase 서비스 계정 등)

---

## 1. Shopify Admin API ⭐ 1순위

### 발급 절차 (15-20분)

1. **Shopify Admin 로그인**: `https://{your-store}.myshopify.com/admin`
2. 좌측 사이드바 하단 **Settings** → **Apps and sales channels**
3. **Develop apps** 클릭 → "Allow custom app development" 활성화 (처음만)
4. **Create an app** → 이름: `JamesClaw Connect AI`
5. **Configuration** 탭 → **Configure Admin API scopes**
6. **필수 권한 6종 체크**:
   - `read_orders`, `write_orders` (주문 자동화)
   - `read_products`, `write_products` (상품 자동 등록)
   - `read_customers` (고객 분석)
   - `read_inventory`, `write_inventory` (재고 동기화)
   - `read_fulfillments` (배송 추적)
   - `read_themes` (스토어 디자인 진단)
7. **Save** → **Install app**
8. **API credentials** 탭에서 발급된 토큰 확인:
   - `Admin API access token` (`shpat_xxxxxxxxxxxxx` 형식, 1회만 표시 — 즉시 복사)
   - `API key` + `API secret key`

### 저장

`D:/jamesclew/.env-keys`에 추가:
```env
SHOPIFY_STORE_DOMAIN=your-store.myshopify.com
SHOPIFY_ACCESS_TOKEN=shpat_xxxxxxxxxxxxx
SHOPIFY_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SHOPIFY_API_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SHOPIFY_API_VERSION=2026-04
```

### 검증

```bash
# 스토어 정보 조회 (200이면 성공)
curl -s -o /dev/null -w "%{http_code}" \
  "https://${SHOPIFY_STORE_DOMAIN}/admin/api/${SHOPIFY_API_VERSION}/shop.json" \
  -H "X-Shopify-Access-Token: ${SHOPIFY_ACCESS_TOKEN}"
```

### 해소되는 차단

- 신상품 자동 등록 (Designer 시안 → 상품 페이지)
- 리뷰 자동 수집 + UGC 캠페인
- 주문 fulfilled +7일 후 리뷰 요청 이메일
- 재고 부족 알림 + 자동 발주
- 고객 RFM 분석

---

## 2. mem0 API (Connect AI 메모리 레이어)

### 발급 절차 (5분)

1. `https://app.mem0.ai` 접속 → Google 또는 GitHub 로그인
2. 우측 상단 프로필 → **API Keys**
3. **Create new key** → 이름: `JamesClaw Connect AI`
4. 발급된 `m0sk_xxxxxxxxxxxxx` 즉시 복사 (1회만 표시)

### 저장

```env
MEM0_API_KEY=m0sk_xxxxxxxxxxxxx
MEM0_USER_ID=jamesclaw
```

### 검증

```bash
curl -s -X POST https://api.mem0.ai/v1/memories/ \
  -H "Authorization: Token ${MEM0_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"test"}],"user_id":"jamesclaw"}'
```

200 응답 + memory id 반환되면 성공.

---

## 3. Klaviyo (이메일 마케팅)

### 발급 절차 (10분)

1. `https://www.klaviyo.com` 가입 (Shopify 연동 무료 플랜 가능)
2. **Settings** → **API Keys** → **Create Private API Key**
3. 권한: `Profiles: Read/Write`, `Events: Read/Write`, `Lists: Read/Write`, `Templates: Read`
4. `pk_xxxxxxxxxxxxx` 복사

### 저장

```env
KLAVIYO_PRIVATE_API_KEY=pk_xxxxxxxxxxxxx
KLAVIYO_PUBLIC_API_KEY=PUBKEY
```

### 검증

```bash
curl -s "https://a.klaviyo.com/api/lists/" \
  -H "Authorization: Klaviyo-API-Key ${KLAVIYO_PRIVATE_API_KEY}" \
  -H "revision: 2024-10-15"
```

---

## 4. GA4 Measurement Protocol

### 발급 절차 (5분)

1. `https://analytics.google.com` → 펫 D2C 속성 선택
2. **관리** → **데이터 스트림** → 웹 스트림 클릭
3. **Measurement Protocol API secrets** → **만들기**
4. `Measurement ID` (`G-XXXXXXXXXX`) + `API Secret` 복사

### 저장

```env
GA4_MEASUREMENT_ID=G-XXXXXXXXXX
GA4_API_SECRET=xxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 5. Naver SearchAdvisor API (블로그 SEO)

### 발급 절차 (10분)

1. `https://searchadvisor.naver.com` 로그인 (네이버 계정)
2. 사이트 등록 (smartreview-kr.web.app)
3. 사이트 소유 확인 (HTML 파일 또는 메타태그)
4. **API 사용 신청** → 발급 대기 (영업일 1-2일)
5. 발급된 키를 .env에 저장

### 저장

```env
NAVER_SEARCHADVISOR_KEY=xxxxxxxxxx
NAVER_CLIENT_ID=xxxxxxxxxx
NAVER_CLIENT_SECRET=xxxxxxxxxx
```

(NAVER_CLIENT_ID/SECRET은 이미 .env-keys에 보유)

---

## 6. Firebase 서비스 계정 (추가 프로젝트용)

### 발급 절차 (10분)

1. `https://console.firebase.google.com` → 프로젝트 선택
2. **프로젝트 설정** → **서비스 계정** 탭
3. **새 비공개 키 생성** → JSON 다운로드
4. 안전한 위치(`D:/jamesclew/secrets/firebase-{project}.json`)에 저장

### 저장

```env
FIREBASE_PROJECT_ID=your-project
GOOGLE_APPLICATION_CREDENTIALS=D:/jamesclew/secrets/firebase-{project}.json
```

---

## 일괄 검증 스크립트

발급 완료 후:
```bash
bash D:/jamesclew/harness/scripts/verify-credentials.sh
```

각 서비스에 ping 테스트하여 OK/FAIL 표시.

---

## 발급 진행 권장 순서

1. **Shopify** (오늘) — 매출 직결
2. **mem0** (5분) — Connect AI 즉시 강화
3. **Klaviyo** (선택) — Shopify Flow 자동화 시
4. 나머지는 필요 시
