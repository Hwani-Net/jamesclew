# P-082: 사용자 직접 가능한 자동화 행동 시도 없이 위임 + 옵션 비용 미검증

- **발견**: 2026-04-29
- **프로젝트**: 영상제작 (Fal.ai admin lock 대응)
- **재발**: 2026-04-29 (Suno API 미존재 단정 + MCP 검색 미흡. Tavily 1회로 결론 — 실제로는 npm/GitHub에 Suno MCP 다수: `@yuezheng2006/suno-mcp-server` v0.3.2, `AceDataCloud/SunoMCP` 5⭐, `jchoi2x/suno-mcp` 등 9개+. ON-DEMAND MCP 룰 강제 미적용. 대표님 "mcp도 없고?"로 직접 지적)
- **재발 #2**: 2026-04-29 (Suno UI 4필드 안내 시 작가 PDF 명칭 그대로 복사 — 실제 v4.5-all 무료 UI에는 Negative Prompt 별도 필드 없음. "Exclude Styles" 토글이 Pro/Premier 전용. 대표님 "안내한 것과 실제 입력란 다른데?" 직접 지적. **도구 UI 실측 없이 문서 명칭 그대로 안내 = 재발 패턴**)
- **재발 #3**: 2026-04-29 (스토리보드 v1 9장 사이즈 portrait 1024x1536으로 생성. PDF 3부에 명시된 `aspect ratio 3:2, 1536x1024 landscape`를 Sonnet 위임 시 검증 안 함 + reference image 미첨부로 캐릭터 일관성 손실. 대표님 "기준의 스토리보드와 생성된 사이즈도 다르고" 직접 지적. **PDF 명시 검증 미흡 = 재발**)
- **재발 #4**: 2026-04-29 (Seedance 2.0 비디오 호출 시 reference에 `haechi-MASTER.png`(4-form-state 시트) 첨부. CUT01은 작가 의도가 STONE STATUE만이지만 reference의 살아있는 형태 MAIN이 우세하여 모델이 본모습 등장. 또한 Sonnet 위임 후 4컷 결과 검증 + 잔액 확인 안 함. cut-05 호출 시 402 크레딧 부족 발견. 대표님 "동상이 갈라져서 해치가 나와야 하는데 본모습이 먼저 서있다가 줌인되면서 동상으로 변하잖아" 직접 지적. **reference image 적합성 컷별 검증 + 잔액/진행 사후 확인 누락 = 재발**)
- **재발 #5**: 2026-04-29 (BytePlus Free Tier 발견 시 "Seedance 1.0 Pro 2M tokens 무료, 작가 도구 충실도 90%+"라 단정. 실제 검증 시 Seedance 2.0이 1.0 대비 결정적 차이: 멀티모달 통합 아키텍처 + multi-reference (이미지9+비디오3+오디오3) + **캐릭터 일관성 (작가 9컷 서하린 동일인물 보장의 핵심)** + native audio sync. 1.0 Pro는 reference-driven control 약해 우리 case 부적합. 대표님 "씨댄스 1.0과 2.0이 다르지 않다고? 2.0이 최근 미쳤다고 하는 이유가 따로 있는거 아니야?" 직접 지적. **모델 버전 차이 검증 없이 무료 옵션을 작가 충실 도구로 판단 = 재발**)
- **재발 #6**: 2026-04-29 (Replicate $20-30 추가 충전을 계속 권유. 실제로는 .env에 `GEMINI_API_KEY` + `GOOGLE_OAUTH_CLIENT_ID` + `GOOGLE_SECRET` 모두 등록되어 있고, gcloud CLI 인증된 계정 2개(hwanizero01, stayicon) + Antigravity 설치 확인됨. 즉 **Antigravity 구독 + Gemini API로 Veo 3.1 무료 호출 가능한데 검증 안 함**. 대표님 "antigravity의 구독 요금제가 있고, 그걸 활용하란 말이잖아. 왜 자꾸 충전하려고만해?" 직접 지적. **사용자 환경에 이미 등록된 API 키/구독 자산 검증 누락 + 외부 결제만 반복 안내 = 재발 (가장 자주 나타나는 패턴)**)
- **재발 #7**: 2026-04-29 (Veo 3.1 무료 한도 도달(9-10 호출/일) 후 "내일 한도 리셋 후 재실행"만 안내. 대표님 "안티그래비티 계정이 세개가 있는데 기다려?" 직접 지적. 즉 **3개 계정 활용으로 무료 한도 3배 가능했는데 다중 계정 활용 검증/제안 누락**. 대표님 보유 자산(Google 계정 3개 = Antigravity 구독 3개 = Gemini API 키 3개 발급 가능)을 인지 못 함. **사용자 보유 다중 계정 자산 활용 패턴 누락 = #6의 변형 재발**)

## 증상

1. **Fal.ai admin lock 발생**(2026-04-29). 대응으로 "support@fal.ai 이메일" 또는 "Discord/X 호소" 옵션을 안내하면서 **"대표님께서 직접 진행"** 으로 처리. expect MCP / claude-in-chrome으로 자동화 시도하지 않음.
2. **Suno 폴백 안내 시 "Pro $10/월"만 강조**. 무료 플랜(50 크레딧/일, 10곡/일)으로 충분히 가능한 사실 미검증. 대표님이 "또다시 충전하라는 말이야?"라고 의구심 표명.

## 원인

1. **위임 본능**: 사용자가 직접 할 수 있는 행동은 곧장 사용자 위임. 자동화 가능성(expect MCP, claude-in-chrome, browser cookies로 로그인 세션 활용 등) 능동 탐색 안 함.
2. **비용 검증 누락**: 도구 옵션 안내 시 "최저 무료 옵션 가능 여부" 사전 검증 안 함. 추측으로 결제 플랜만 안내.
3. **Tavily 회피**: 무료 플랜 한도 같은 단순 사실은 1회 검색으로 답나옴에도 검색 안 함.
4. **Evidence-First 위반**: 도구·결제 안내인데 도구 출력 없이 추측 보고.

## 해결

1. **사용자 위임 전 자동화 시도 체크리스트**:
   - expect MCP / claude-in-chrome으로 자동 입력 가능한가?
   - API direct call로 가능한가? (Fal.ai API에 contact endpoint 있을 수도)
   - 인증 필요 시 대표님 브라우저 쿠키 (cookies: true)로 세션 재사용 가능한가?
   - Discord webhook 직접 POST 가능한가?
2. **결제 옵션 안내 형식 강제**: "무료 플랜으로 X 가능 / Pro는 Y 추가 기능" 형식. 무조건 결제 옵션 단독 강조 금지.
3. **Tavily 1회 검색 필수**: 결제/플랜 언급 전 "도구명 free plan limit YYYY" 검색.

## 재발 방지

- 사용자에게 "직접 ~~ 하시면 됩니다" / "결제하시면 됩니다" 패턴 사용 전 위 체크리스트 강제
- 결제 옵션 언급 전 Tavily 1회 검색으로 무료 한도 검증
- expect MCP 도구 로드 후 fal.ai/discord/X 같은 사용자 행동 채널을 직접 접근해 자동화 가능성 평가

## 적용 위치

- 영상제작 프로젝트의 Fal.ai admin lock 대응
- 모든 사용자 위임 응답 일반
- 모든 결제·구독 옵션 안내 일반
