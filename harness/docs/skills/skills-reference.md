# Skills Reference — JamesClaw Harness

최종 갱신: 2026-04-18 | 소스: `D:/jamesclew/harness/commands/` | 총 21개 커맨드

---

## 1. 개요

슬래시 커맨드(스킬)는 복잡한 다단계 작업을 하나의 호출로 실행하는 재사용 절차입니다. 호출법은 `/{커맨드명}` 또는 `/{커맨드명} <인자>`이며, 각 파일은 YAML frontmatter(`description`, `argument-hint`, `allowed-tools`)와 Markdown 절차 본문으로 구성됩니다. 새 스킬은 `harness/commands/{skill-name}.md`에 저장하고 gbrain에도 동시 등록합니다.

---

## 2. 용도별 그룹

### 플래닝
PRD 작성부터 플랜 승인까지 빌드 진입 전 단계를 담당합니다.

| 커맨드 | 설명 |
|--------|------|
| `/prd` | 요구사항 인터뷰 → PRD.md 생성 |
| `/annotate-plan` | 플랜 주석 반영 루프 (최대 6회 수렴, ANNOTATE-APPROVED 헤더 삽입) |
| `/contest-idea` | 공모전 아이디어 기획·검증·고도화 |

### 빌드 / 오케스트레이션
프로젝트 구조 설치, 에이전트 팀 구성, 장기 루프 관리를 담당합니다.

| 커맨드 | 설명 |
|--------|------|
| `/pipeline-install` | 11단계 품질 파이프라인 초기 설치 |
| `/agent-team` | 영상식 6역할 Agent Teams 스캐폴드 v11 구성 |
| `/ralph-loop` | Ralph Loop(자율 개선 루프) 시작 |
| `/self-heal` | 3 에이전트 경쟁 수정으로 버그 자가 치유 |

### 품질
생성된 결과물의 다단계 검증과 외부 모델 교차 검수를 담당합니다.

| 커맨드 | 설명 |
|--------|------|
| `/pipeline-run` | 7단계 품질 파이프라인 실행 (Multi-Pass Review) |
| `/qa` | 외부 모델 QA 루프 (사용자 관점 검증) |
| `/blog-review` | 7단계 품질게이트 + AI냄새 + SEO 검수 |
| `/design-review` | Vision 기반 Stitch 디자인 리뷰 (Opus 고정) |
| `/feedback-loop` | 배포 후 피드백 수집 → 개선 태스크 생성 |

### 콘텐츠
블로그 글 생성부터 위키 동기화까지 콘텐츠 파이프라인 전체를 담당합니다.

| 커맨드 | 설명 |
|--------|------|
| `/blog-generate` | 키워드 → SEO → 초안 → 팩트 → 이미지 전 과정 자동화 |
| `/blog-fix` | 품질게이트 실패 항목 자동 수정 |
| `/blog-pipeline` | blog-generate → blog-review → blog-fix → blog-publish 전체 파이프라인 |
| `/wiki-sync` | gbrain 지식과 Obsidian Wiki 양방향 동기화 |

### 배포
Firebase 자동 발행을 담당합니다.

| 커맨드 | 설명 |
|--------|------|
| `/blog-publish` | Firebase 자동 발행 (검증 포함) |

### 감사 / 유틸
세션 감사, 비용 확인, 유틸리티 작업을 담당합니다.

| 커맨드 | 설명 |
|--------|------|
| `/audit` | 세션 감사 (audit-session.sh 실행) |
| `/cost` | API 비용 요약 보고 |
| `/reset-ping-setup` | 5H/7D 리셋 Remote Trigger 설정 |
| `/저장` | 세션 저장 + compact 실행 |

---

## 3. 개별 커맨드 상세 표

| 커맨드 | description | argument-hint | 용도 | 소스 파일 | 줄수 |
|--------|-------------|---------------|------|-----------|------|
| `/agent-team` | 영상식 6역할 Agent Teams 스캐폴드 v11 | `<task-description>` | 복잡한 병렬 작업 팀 구성 | commands/agent-team.md | 882 |
| `/annotate-plan` | Plan 주석 반영 루프, 수렴 시 ANNOTATE-APPROVED 헤더 삽입 | `<plan-file>` | 플랜 승인 게이트 통과 | commands/annotate-plan.md | 75 |
| `/audit` | 세션 감사 실행, 규칙 준수·품질·보안 항목 체크 | — | 정기 감사·이슈 발굴 | commands/audit.md | 55 |
| `/blog-fix` | 품질게이트 실패 항목 자동 수정, 외부 모델 교차 검증 | `<post-slug>` | 리뷰 후 자동 보정 | commands/blog-fix.md | 169 |
| `/blog-generate` | 키워드→SEO→초안→팩트검증→이미지 전 과정 자동화 | `<keyword>` | 블로그 글 신규 생성 | commands/blog-generate.md | 181 |
| `/blog-pipeline` | generate→review→fix→publish 전체 파이프라인 | `<keyword>` | 원스톱 블로그 발행 | commands/blog-pipeline.md | 56 |
| `/blog-publish` | Firebase 자동 발행 + 라이브 검증 | `<post-slug>` | 검증 포함 배포 | commands/blog-publish.md | 170 |
| `/blog-review` | 7단계 품질게이트 + AI냄새 + SEO + 이미지 검수 | `<post-slug>` | 발행 전 품질 보증 | commands/blog-review.md | 229 |
| `/contest-idea` | 공모전 아이디어 기획→검증→고도화 3단계 | `<theme>` | 공모전 준비 | commands/contest-idea.md | 51 |
| `/cost` | api_cost_log.jsonl 파싱, 일별/서비스별 비용 요약 | — | 비용 모니터링 | commands/cost.md | 53 |
| `/design-review` | Stitch 스크린샷 ↔ 라이브 pixel 비교, Opus Vision 고정 | `<url>` | UI 디자인 품질 검증 | commands/design-review.md | 96 |
| `/feedback-loop` | 배포 후 피드백 수집 → 우선순위 개선 태스크 생성 | `<project>` | 지속 개선 루프 | commands/feedback-loop.md | 187 |
| `/pipeline-install` | 11단계 품질 파이프라인 프로젝트 초기 설치 | `<project-dir>` | 신규 프로젝트 기반 구축 | commands/pipeline-install.md | 169 |
| `/pipeline-run` | 7단계 Multi-Pass Review 실행 (구조→SEO→AI냄새→사실→이미지→경쟁→배포) | — | 결과물 종합 품질 검증 | commands/pipeline-run.md | 208 |
| `/prd` | 요구사항 인터뷰 → PRD.md 자동 생성 | `<project-name>` | 빌드 착수 전 설계 문서화 | commands/prd.md | 228 |
| `/qa` | 외부 모델(Codex+GPT-4.1) QA 루프, 사용자 관점 검증 | `<url>` | 배포 후 외부 검수 | commands/qa.md | 127 |
| `/ralph-loop` | Ralph Loop 자율 개선 루프 시작 | — | 장기 자율 개선 | commands/ralph-loop.md | 17 |
| `/reset-ping-setup` | 5H/7D 리셋 Remote Trigger 설정 (헬스체크 자동화) | — | 사용량 모니터링 설정 | commands/reset-ping-setup.md | 44 |
| `/self-heal` | 3 에이전트 경쟁 수정으로 버그 자가 치유 | `<issue-description>` | 반복 버그 자동 해결 | commands/self-heal.md | 94 |
| `/wiki-sync` | gbrain 지식 ↔ Obsidian Wiki 양방향 동기화 | — | 지식 베이스 최신 유지 | commands/wiki-sync.md | 58 |
| `/저장` | 옵시디언 세션 저장 + /compact 실행 | — | compact 전 필수 저장 | commands/저장.md | 55 |

---

## 4. 자주 쓰는 조합 (워크플로우)

### 새 프로젝트 시작
```
/prd <project-name>
  → /pipeline-install <project-dir>
  → /plan (중복잡도 / 오프라인) 또는 /ultraplan (고복잡도 · 클라우드 병렬). `/deep-plan`은 deprecated(2026-04-21)
  → /annotate-plan <plan-file>
  → 코드 구현
```
플랜에 `<!-- ANNOTATE-APPROVED -->` 헤더가 없으면 `enforce-build-transition.sh`가 구현 진입을 차단합니다.

### 블로그 글 발행
```
/blog-generate <keyword>
  → /blog-review <post-slug>
  → /blog-fix <post-slug>   (review FAIL 항목 자동 수정)
  → /blog-publish <post-slug>
```
각 단계는 `/blog-pipeline <keyword>` 단일 호출로 자동 순서 실행됩니다.

### 품질 검증 루프
```
/pipeline-run
  → /qa <url>
  → /audit
```
`/pipeline-run`이 Multi-Pass Review를 수행하고, `/qa`가 외부 모델(Codex+GPT-4.1) 사용자 관점 검수를 추가합니다. `/audit`으로 세션 규칙 준수 상태를 최종 확인합니다.

### 공모전 준비
```
/contest-idea <theme>
  → /prd <project-name>
  → /pipeline-install <project-dir>
```
아이디어 검증 후 바로 PRD와 파이프라인 설치로 이어집니다.
