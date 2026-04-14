# /qa — 외부 모델 QA 루프

배포된 결과물을 **외부 모델(Codex/GPT-4.1/Gemini)이 사용자 관점**으로 평가하고,
지적 사항을 수정한 후 다시 평가받는 루프를 돌립니다.
외부 모델이 더 이상 지적할 것이 없을 때 완성.

## 핵심 원칙
- **외부 모델이 "문제 없음"이라 할 때까지 끝이 아닙니다.**
- **로컬에서 먼저 완성 → 배포는 1회 → 라이브 검증은 비교만.**

## 사용법
- `/qa https://example.web.app/` — 이미 배포된 URL QA
- `/qa` — 로컬부터 시작 (미배포 상태)

## 실행 절차

### Phase 1: 로컬 QA 루프 (배포 전)

**1-1. 로컬 서버 기동**
```bash
npx vite preview  # 또는 npx serve dist/
```

**1-2. 로컬 자동 스캔**
```
1. Playwright localhost 스크린샷 (데스크톱+모바일)
2. 모든 링크 유효성 (href="#" 감지, 외부 링크 HTTP 체크)
3. 모든 이미지 로드 확인
4. 주요 기능 동작 (버튼, 폼, 네비게이션)
```
- FAIL → 즉시 수정 (배포 없이 로컬에서 반복)

**1-3. 외부 모델 사용자 관점 평가 (Design Rubric 강제)**
스크린샷 + 소스코드 + **design_rubric.md**를 외부 모델에 전달:

```bash
# 라운드별 로테이션 — rubric을 프롬프트에 포함
RUBRIC=$(cat $HOME/.claude/rules/design_rubric.md)
codex exec "다음 웹앱을 Anthropic Design Rubric 기준으로 평가하라.

$RUBRIC

---
평가 대상: [URL / 스크린샷 설명]
소스코드 요약: [주요 파일 + 기능]

출력 형식 (JSON):
{
  \"consistency\": {\"score\": 0-10, \"reason\": \"...\"},
  \"originality\": {\"score\": 0-10, \"reason\": \"...\", \"ai_cliches\": [\"발견된 AI 클리셰\"]},
  \"polish\": {\"score\": 0-10, \"reason\": \"...\"},
  \"functionality\": {\"score\": 0-10, \"reason\": \"...\"},
  \"lowest_axis\": \"originality\",
  \"verdict\": \"PASS|REWORK|FAIL\",
  \"fixes\": [\"구체적 수정 방법 1\", \"...\"]
}

통과 기준: 4개 축 모두 8점 이상 = PASS, 5점 이하 1개라도 있으면 FAIL." 2>&1 | tee ~/.harness-state/qa_review.txt
```

**사용자 관점 추가 질문** (rubric 외):
1. 첫인상 — 뭘 해야 하는지 바로 알 수 있는가?
2. 네비게이션 — 모든 버튼/링크 동작하는가?
3. 모바일 — 모바일에서 사용 가능한가?

**1-4. 지적 사항 수정 → 재평가 루프**
```
┌─ 외부 모델: "버튼 X 안 됨, 색상 대비 부족"
│  에이전트: 로컬에서 수정 → 새 스크린샷
│  다른 외부 모델: 재평가 → "색상 OK, Footer 겹침"
│  에이전트: 로컬에서 수정 → 새 스크린샷
│  또 다른 외부 모델: "ALL PASS"
└─ → Phase 2로 진행
```

**로컬 루프 규칙:**
- 매 라운드 **다른 외부 모델** 로테이션 (Codex → GPT-4.1 → Gemini)
- 지적 사항은 **무조건 수정**. "의도된 것" 금지.
- **최대 10라운드**. 초과 시 대표님 보고.
- 외부 모델 2개 이상 ALL PASS → 로컬 QA 완료.

### Phase 2: 배포 (1회)
로컬 QA 완료 후 배포:
```bash
firebase deploy --only hosting
```

**배포 후 즉시 Evaluator 스크립트 실행** (Generator-Evaluator 분리):
```bash
bash $HOME/.claude/scripts/evaluator.sh https://PROJECT.web.app/
# 자동으로: Playwright 캡처 → Codex 등급 평가 → PASS/REWORK/FAIL 판정
# 결과: ~/.harness-state/evaluator_result.json
```

### Phase 3: 라이브 검증 (로컬↔라이브 비교)

**3-1. 라이브 자동 스캔**
```
1. 라이브 URL HTTP 200 체크
2. Playwright 라이브 스크린샷 (데스크톱+모바일)
3. 로컬 스크린샷과 라이브 스크린샷 비교
4. 라이브에서만 발생하는 문제 확인 (CDN 캐시, CORS, Auth 등)
```

**3-2. 차이점 발견 시**
```
┌─ 차이점: "로컬에선 OK인데 라이브에서 폰트 안 뜸"
│  에이전트: 로컬에서 수정 → 재배포 → 라이브 재확인
│  차이점: 없음 (로컬 = 라이브)
└─ → QA 완료
```
- 차이점이 없으면 **추가 배포 없이 완료**
- 차이점이 있으면 수정 → 재배포 (이때만 추가 배포)
- **최대 3회 재배포**. 초과 시 대표님 보고.

### Phase 4: QA 완료 보고
- Phase 1 라운드 수 + Phase 3 재배포 수
- 최종 외부 모델 평가 점수
- 최종 라이브 스크린샷 (데스크톱+모바일)
- `echo "QA 완료 — 로컬 N라운드, 배포 M회, 외부 모델 ALL PASS" > ~/.harness-state/last_result.txt`

### Phase 5: 대표님 최종 확인 (선택)
대표님이 추가 지적 시 로컬 수정 → 재배포 (외부 모델 재평가 불필요).
