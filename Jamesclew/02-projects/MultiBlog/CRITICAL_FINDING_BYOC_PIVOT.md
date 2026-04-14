# CRITICAL FINDING — BYOC 전략 수정 (v1 → v2)

> 작성일: 2026-04-07 | 출처: Anthropic 공식 ToS, Gemini CLI 공식 ToS, OpenAI Codex 공식 문서, 업계 사건 리포트

## 1. 결정적 사실

### Anthropic Claude Code (2026-01-09 ~ 2026-02-19)
- **OAuth 토큰 third-party 재사용 금지** 명시 (https://code.claude.com/docs/en/legal-and-compliance)
- 인용: *"Using OAuth tokens obtained through Claude Free, Pro, or Max accounts in any other product, tool, or service — including the Agent SDK — is not permitted and constitutes a violation of the Consumer Terms of Service."*
- **2026-01-09부터 서버 측 차단** 시작 (Claude Code 바이너리 spoof 감지)
- 사용자 계정 ban 사례: Max($200/월) 가입자가 third-party 사용 후 20분 내 ban
- opencode (56,000+ stars) 등 다수 도구가 영향, 2026-03-19 PR #18186로 Anthropic auth 제거
- Anthropic 직원 트윗: "personal use and local experimentation are fine. If building business → API key"
- 회색 지대: `claude -p` headless CLI 호출은 vendor가 OAuth를 통제하므로 더 방어 가능. 그러나 yage.ai 분석은 향후 차단 가능성 명시.

### Google Gemini CLI (https://geminicli.com/docs/resources/tos-privacy/)
- **명시 금지**: *"Directly accessing the services powering Gemini CLI using third-party software, tools, or services (for example, using OpenClaw with Gemini CLI OAuth) is a violation of applicable terms and policies. Such actions may be grounds for suspension or termination of your account."*
- FAQ: *"Using third-party software, tools, or services to harvest or piggyback on Gemini CLI's OAuth authentication... is a direct violation"*
- 권장: "use a Vertex AI or Google AI Studio API key" instead
- "harvest or piggyback" 표현은 OAuth 추출만이 아니라 CLI 우회까지 포함 해석 가능

### OpenAI Codex CLI (https://developers.openai.com/codex/auth)
- 공식 두 가지 인증: ChatGPT OAuth + API 키
- third-party 도구 사용을 명시적으로 금지하는 조항은 없음 (2026-04 기준)
- lumadock·OpenClaw 등 third-party 도구가 Codex OAuth를 사용하는 가이드 다수 존재
- evanZhouDev/openai-oauth 같은 비공식 프록시도 활동 중
- 위험: 트래픽 패턴 차이로 client ID 차단 가능
- ChatGPT Plus는 5시간 윈도우 + 주간 cap 제한
- 회색 지대지만 가장 자유로운 vendor

## 2. PoC 1 실증 결과 (2026-04-07 로컬 호출)

| CLI | 버전 | Headless 호출 | stdin/stdout | 결과 |
|-----|------|--------------|--------------|------|
| Claude Code | 2.1.92 | `claude -p "..."` | ✅ | exit 0, "PONG_CLAUDE" 정확 출력 |
| Codex CLI | codex-cli 0.98.0 | `codex exec [PROMPT]` 또는 stdin | ✅ | help 확인, 비대화 모드 존재 |
| Gemini CLI | 0.35.0 | `gemini -p "..."` | ✅ | JSON 출력 지원 (`-o json`) |
| opencode | 1.3.0 | `opencode run [message]` | ✅ | multi-provider, 자체 인증 |
| Antigravity | 미확인 | TBD | TBD | 추가 PoC 필요 |

## 3. 핵심 인사이트

1. **OAuth 토큰 직접 추출·저장은 모든 주요 vendor에서 금지** — PRD R5/R7 리스크가 현실화된 상태. PRD 원칙 ("토큰 SaaS 서버 저장 금지")는 정확했음.
2. **CLI subprocess spawn 모델은 다른 차원** — 사용자 PC에서 vendor 공식 CLI 바이너리가 OAuth를 처리. 외부 도구는 토큰을 본 적 없음. 사용자가 직접 CLI 쓰는 것과 동일한 행동.
3. **그러나 회색 지대** — vendor가 트래픽 패턴(빈도, 시간대, 도메인 시그니처)으로 감지·차단 가능.
4. **포지셔닝의 중요성** — "SaaS가 사용자 토큰을 빌려 쓴다" 가 아니라 "사용자 본인의 로컬 자동화 헬퍼" 로 포지셔닝해야 함. C 하이브리드 아키텍처가 이미 이 방향.

## 4. BYOC v2 — 수정된 전략

### 원칙
1. **OAuth 토큰 절대 추출·저장·중계 금지** (PRD v1 원칙 유지)
2. **공식 CLI subprocess spawn 모델로 전환** — 우리 헬퍼는 vendor CLI를 호출만, 토큰을 만지지 않음
3. **사용자 본인의 로컬 자동화 도구로 포지셔닝** — 클라우드 SaaS는 발행·통계·UI만 담당, LLM 호출은 100% 사용자 PC
4. **자동화 빈도 ordinary use 범위 유지** — 발행 1건당 LLM 호출 N회 상한, 일일 cap, 휴먼 패턴 시뮬
5. **API 키 fallback 상시 활성** — vendor가 차단·약관 강화 시 즉시 전환
6. **Vendor별 ToS 변경 모니터링** — 한 vendor가 명시 금지하면 해당 어댑터 즉시 비활성화

### 어댑터 우선순위 (V1 출시 시점)
| 우선순위 | CLI | 근거 |
|---------|-----|------|
| 1 | **Codex CLI** | 가장 자유로운 vendor, 명시 금지 없음 |
| 2 | **opencode** | multi-provider 지원, 자체 인증, Anthropic auth 자체 제거함 |
| 3 | **Claude Code** (`claude -p`만) | 회색 지대, 사용자 본인 PC에서만, 자동화 빈도 제한 |
| 4 | **Gemini CLI** (`gemini -p`만) | 회색 지대, 명시 금지 표현 강함, 가장 보수적 사용 |
| 5 | **사용자 직접 API 키** (Anthropic·OpenAI·Google·OpenRouter) | 항상 사용 가능 |

### 다중 계정 로테이션 + 계층적 fallback (PRD 원안 유지)
- 각 CLI별 N개 계정 등록 가능
- 한 계정 rate limit → 다음 계정 → 모든 계정 소진 → 다음 CLI로 fallback
- **단**: 동일 사용자가 여러 무료 계정을 만드는 행위가 vendor ToS의 "ordinary use" 가정 위반일 수 있음. 사용자에게 위험 고지 + 본인 책임 명시

## 5. 사용자 통보 사항 (대표님께)

1. **기술적으로 가능**: 각 CLI를 subprocess spawn 모델로 호출하면 단기적으로 작동
2. **법적 위험**: Anthropic·Google은 명시 금지 조항 보유. Codex/opencode는 회색
3. **장기 지속성 불확실**: 모든 vendor가 향후 트래픽 패턴 검증 강화 가능
4. **권장 출시 전략**:
   - **V1 GA**: Codex + opencode + 사용자 API 키 (3개 어댑터, 가장 안전)
   - **V1.1 옵트인**: Claude Code/Gemini CLI 어댑터 + 사용자 명시 동의 + 위험 고지
   - **항상**: API 키 fallback이 기본 경로
5. **마케팅 톤**: "사용자가 보유한 모든 AI CLI를 활용하는 로컬 자동화 헬퍼" — SaaS가 토큰을 가져간다는 인상 절대 금지

## 6. PRD 업데이트 필요 항목

- [x] 차별화 #8: BYOC v2 — CLI subprocess spawn 모델 명시
- [x] NFR LLM 라우팅: 어댑터 우선순위 표 추가
- [x] R7: vendor별 정책 차이 반영
- [x] R10 (신규): 자동화 빈도가 ordinary use 위반 시 차단 위험
- [x] T4 태스크: BYOC v2 어댑터 패턴 명시
- [x] 출시 전략: V1 GA 3개 어댑터로 축소, V1.1에서 옵트인 추가
