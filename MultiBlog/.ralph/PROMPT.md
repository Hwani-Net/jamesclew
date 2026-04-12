# Ralph-Loop Blog Pipeline — Self-Improving Generator

## Goal
Managed Agent로 블로그를 생성하고, Codex로 벤치마크 평가한 뒤, 점수가 목표 미달이면
피드백을 누적하여 다음 반복에서 시스템 프롬프트를 자동 개선한다.

## Completion Promise
`feedback-log.md`에 BENCHMARK_SCORE >= 70인 기록이 있으면 완료.

## 매 Iteration 실행 절차

### Step 0: 상태 확인
1. `feedback-log.md` 읽기 — 이전 반복의 점수와 피드백 확인
2. `specs/keywords.md`에서 미완료([ ]) 키워드 1개 선택
3. 이전 반복 피드백이 있으면 Step 1에서 시스템 프롬프트에 반영

### Step 1: 시스템 프롬프트 동적 생성
`harness/scripts/managed-blog-agent.py`의 BLOG_SYSTEM_PROMPT를 읽고,
`feedback-log.md`의 최근 피드백을 **Writing Style Rules 끝에 추가 규칙으로 삽입**.

```
기존 프롬프트 + "\n\n### 이전 반복 피드백 반영\n" + feedback-log.md의 최근 3개 피드백
```

수정된 프롬프트로 Agent를 update (agents.update) 또는 새로 생성.

### Step 2: Managed Agent 실행 (5H 0)
```bash
python3 harness/scripts/managed-blog-agent.py run "{keyword}"
```
- 결과: MultiBlog/drafts/{date}-{slug}/draft.md
- 실패 시 3회 재시도. 3회 실패 → 키워드 스킵 + 로그

### Step 3: Codex 벤치마크 비교 평가 (5H 0)
```bash
bash harness/scripts/codex-rotate.sh "다음 두 글을 비교하라...
글A: $(cat draft.md | head -80)
글B: (인간 블로거 참고글)
...SCORE: NN"
```
- SCORE 파싱 → 점수 기록

### Step 4: 피드백 누적
`feedback-log.md`에 추가:
```
## Iteration {N} — {date}
- Keyword: {keyword}
- Score: {NN}/100
- Codex Feedback: {피드백 원문 요약}
- Action Taken: {이번 반복에서 프롬프트에 뭘 바꿨는지}
- Next: {다음 반복에서 시도할 것}
```

### Step 5: 판정
- Score >= 70 → PASS. 키워드 [x] 표시. 다음 키워드로.
- Score < 70 → 같은 키워드로 재시도 (최대 3회). 프롬프트에 피드백 반영.
- 같은 키워드 3회 실패 → 에스컬레이션. 다음 키워드로.

### Step 6: SEO 체크 (PASS된 글만)
- 키워드 밀도 3회+
- 메타 디스크립션 120-155자
- H2 3개+, FAQ 2개+
- 실패 항목 있으면 Sonnet 서브에이전트로 부분 수정

### Step 7: 완료 체크
- keywords.md에 미완료 키워드 남아있으면 → Step 0으로
- 모든 키워드 완료 또는 전체 70+ 달성 → BATCH_DONE

## 인간 블로거 참고글 (벤치마크 기준)
글B 고정 텍스트 (Codex 평가 시 매번 동일하게 사용):
```
로봇청소기 쓴 지 3년차인데요. 작년에 드리미 쓰다가 올해 로보락으로 갈아탔어요.
솔직히 처음엔 뭐가 다른가 했는데 써보니까 확실히 달라요. 우선 매핑이 진짜 빠름.
처음 돌릴 때 집 구조 파악하는 게 체감 2배는 빠른 느낌? 근데 걸레질은 좀 아쉬워요.
드리미가 물을 더 많이 써서 그런지 바닥이 더 촉촉하게 닦였거든요. 가격은 로보락이
한 20만원 더 비쌌는데 그만한 값어치가 있나 하면... 음 반반이에요 솔직히.
```

## 핵심 원칙
1. **프롬프트 수정은 feedback-log.md 근거로만** — 감으로 바꾸지 않는다
2. **규칙 추가 < 규칙 제거** — v3→v5 실험에서 규칙 과다가 역효과임을 확인
3. **Managed Agent + Codex = 5H 소비 0** — 루프 오케스트레이션만 5H 소비
4. **벤치마크 글B는 고정** — 평가 기준이 흔들리면 점수 비교 무의미

## Constraints
- Draft: 2000+ chars, H2 x3+, FAQ x2+
- AI cliches: "다양한/혁신적인/획기적인/알아보겠습니다" 금지
- No loading="lazy" (P-001)
- Keyword density: 3+ natural mentions
- Max iterations per keyword: 3
- Max total iterations: 8
