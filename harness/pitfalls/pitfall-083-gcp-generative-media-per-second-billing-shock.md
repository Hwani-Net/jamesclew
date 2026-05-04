# P-083: GCP Veo/Imagen 초당 과금 — 신규 GCP 프로젝트 단가 미검증으로 단발 호출 ₩48,321 폭증

- **발견**: 2026-04-30
- **프로젝트**: AI Project (ai-project-ce41f) — Vertex AI Studio에서 Veo 720p+오디오 비디오 생성 1회
- **사건 요약**: 대표님이 동영상 만드는 새 프로젝트로 Vertex AI Studio에서 Veo 비디오 1편(약 64-70초, 720p+오디오) 생성. 단발 호출 1회 = **₩48,321 청구**. KRW 임계값 ₩100,000 도달 → 자동 결제 시도 → Mastercard 거부(은행 계좌 해지) → 잔액 ₩117,420 누적 → 대표님이 "사용량 ₩2,500인데 왜 ₩100,000 청구?"라고 지적 → 추적 끝에 Veo 단발 호출이 원인으로 확정.

## 증상

1. **Generative Media API(Veo, Imagen, Lyria 등) 단발 호출 1회로 수만~수십만원 청구 발생**. 다른 GCP 서비스(Cloud Run, Storage 등)와 단가 차원이 다름.
2. **KRW 결제 계정 임계값 ₩100,000 도달 시 자동 결제 시도** — 카드 거부 시 잔액 누적 + 메일로 "결제 거부" 알림. 사용자는 "왜 갑자기 10만원?"으로 인지.
3. **신규 GCP 프로젝트 시작 시 예산 알림 미설정** — 사용자가 단가 모르는 상태에서 호출 → 사후 인지.
4. **Veo SKU는 Gemini API 산하로 묶여 표시** — 결제 보고서에서 "Gemini API"로만 보여 Veo 사용임을 즉시 식별 어려움. SKU별 그룹화로 들어가야 "Veo Generation 720p with Audio" 식별 가능.

## 원인

1. **Generative Media 단가 차원 인지 부족**:
   - Veo 3 720p+오디오: 약 **$0.40-0.50/초** (≈ ₩560-700/초)
   - 1분 비디오 = ₩33,600~₩42,000, 1분 30초 = ₩50,000+
   - Imagen, Lyria도 유사한 고비용 SKU
   - 일반 LLM(Gemini text)과 가격 차원 100배 차이
2. **새 GCP 프로젝트 시작 절차에 "예산 알림 설정" 단계 부재** — 0단계 체크리스트 누락
3. **Vertex AI Studio 웹 UI는 단가 사전 명시 약함** — 호출 버튼 옆에 예상 비용 명시되지 않거나 작은 글씨로 안내됨
4. **KRW 임계값 자동 청구 메커니즘 인지 부족** — Postpay threshold billing이 ₩100,000 도달 시 자동 카드 청구하는 구조를 사전에 모름

## 해결

### 새 GCP 프로젝트 시작 시 0단계 체크리스트 (필수)

1. **예산 알림 즉시 설정**:
   - `결제 > 예산 및 알림`에서 월 한도 설정
   - 권장 2단계: ₩30,000 (50% 알림) + ₩100,000 (90% 알림 + 자동 비활성화 옵션)
   - 가능하면 [Pub/Sub 트리거로 임계 도달 시 결제 자동 비활성화](https://cloud.google.com/billing/docs/how-to/notify) 설정
2. **Generative Media API SKU 단가 표 사전 조회**:
   - Veo 사용 전: [Vertex AI Pricing](https://cloud.google.com/vertex-ai/pricing#generative_ai_models) 단가 표 확인
   - 1초당 $X → 예상 길이 × $X × 환율 = 1회 호출 비용 계산
   - Pricing Calculator: <https://cloud.google.com/products/calculator>
3. **첫 호출은 최소 길이로 테스트** — Veo는 4-8초 등 짧은 길이로 단가 검증 후 본 호출
4. **결제 임계값 인지** — KRW 계정 ₩100,000 도달 시 자동 청구 시도. 카드 해지 상태면 잔액 누적

### Veo/Imagen 호출 전 의무 체크리스트

- [ ] Pricing Calculator로 예상 비용 산출 — 1회 호출이 ₩10,000 초과면 대표님 사전 승인
- [ ] 무료 티어(있을 경우) 또는 Antigravity 구독 등 대체 경로 우선 검토
- [ ] 결제 임계값 사전 인지 — KRW ₩100,000
- [ ] 첫 호출은 최소 파라미터(짧은 길이, 저해상도)로 단가 검증

## 재발 방지

1. **harness/CLAUDE.md Build Transition Rule 0단계에 추가**:
   ```
   - GCP 신규 프로젝트 시작 시: 결제 > 예산 및 알림 즉시 설정 (₩30K/₩100K 2단계)
   - Generative Media API(Veo/Imagen/Lyria) 호출 전: Pricing Calculator로 비용 산출 + 대표님 사전 승인 (₩10,000 초과 시)
   ```
2. **이 PITFALL을 새 세션에서 자동 surface**: gbrain query "gcp veo imagen vertex 단가" 시 P-083 우선 노출
3. **하네스 리뷰**: 새 프로젝트 0단계 체크리스트에 GCP 예산 알림 + Generative Media 단가 검증 항목이 없으면 enforce-build-transition.sh가 경고
4. **대안 경로 우선 정책**: Antigravity Veo 3.1 무료 호출 가능 시 Vertex AI Studio Veo 유료 호출 대신 Antigravity 우선 (P-082 #6, #7 재발 방지와 연계)

## 클레임/환불 절차 (사후 대응)

- Cloud Console → Support → 결제 지원 → "결제 관련 지원 받기" → AI 거절 → "사람 상담원과 채팅"
- 채팅 언어: 영어 24/7, 한국어 영업시간 제한
- 사람 상담원에게 1회성 굿윌 크레딧(one-time courtesy adjustment) 요청
- 신청 조건: 청구 발생 프로젝트의 결제 비활성화 (`gcloud billing projects unlink <PROJECT_ID>`) 후 신청 가능
- 처리 기간: 32시간 propagation + 48-72시간 검토 = 약 4-5일
- 케이스 ID 받아 추적 (예: 70720311)
- 일반적 결과: 30~70% 부분 크레딧

## 적용 위치

- 모든 GCP 신규 프로젝트 시작
- Vertex AI Studio / Veo / Imagen / Lyria / Generative Media API 호출 일반
- 결제 임계값(threshold billing) 메커니즘 인지 필요한 모든 KRW 계정
- Antigravity 등 무료 대체 경로가 있는 경우 우선순위 설정
