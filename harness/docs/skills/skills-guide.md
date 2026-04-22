# 슬래시 커맨드(스킬) 작성 가이드

> How-To | 대상: JamesClaw 하네스 관리자 | 최종 업데이트: 2026-04-18

---

## 1. 스킬이란

스킬은 `.md` 파일로 작성된 절차 문서입니다. Claude가 `/skill-name`을 입력받으면 해당 파일을 프롬프트로 해석하여 순서대로 실행합니다. 코드가 아닌 자연어 + 도구 호출 지시로 구성되므로, 복잡한 반복 작업을 한 줄 명령으로 실행할 수 있습니다.

현재 하네스에는 21개 스킬이 등록되어 있습니다 (`D:/jamesclew/harness/commands/`).

---

## 2. 파일 위치

```
D:/jamesclew/harness/commands/{skill-name}.md   <- 소스 편집 위치
~/.claude/commands/{skill-name}.md              <- Claude가 읽는 위치
```

소스에서 편집 후 반드시 배포를 실행해야 적용됩니다.

```bash
bash D:/jamesclew/harness/deploy.sh
```

배포 후 Claude Code를 재시작하거나 `/reload`하면 새 스킬이 `/skills` 목록에 나타납니다.

---

## 3. frontmatter 구조

파일 최상단에 YAML frontmatter를 반드시 포함합니다.

```yaml
---
description: "한 줄 용도 설명 — /skills 목록에 표시됨"
argument-hint: "<필수인자> [선택인자]"
allowed-tools: ["Read", "Edit", "Bash", "Grep", "Glob"]
---
```

| 필드 | 필수 | 설명 |
|------|------|------|
| `description` | 권장 | `/skills` 메뉴에서 표시. 없으면 파일명만 표시 |
| `argument-hint` | 선택 | 인자가 있는 스킬에서 입력 힌트 제공 |
| `allowed-tools` | 선택 | 명시하면 해당 도구만 사용 가능. 생략하면 전체 허용 |

---

## 4. 본문 절차 작성

frontmatter 아래에 스킬의 목적, 사용 시점, 절차를 작성합니다.

```markdown
# /skill-name — 스킬 제목

## Purpose
이 스킬이 해결하는 문제를 1-2줄로 설명합니다.

## When to use
어떤 상황에서 이 스킬을 실행해야 하는지 명시합니다.

## Procedure

### 1단계 — 입력 확인
- `$ARGUMENTS`로 전달된 인자를 Read 또는 Grep으로 확인
- 인자가 없으면 기본값 사용 또는 중단 후 보고

### 2단계 — 작업 실행
- 도구 호출 예시를 구체적으로 작성
- 분기 조건 명시: "X 상황이면 옵션 A, Y 상황이면 옵션 B"

### 3단계 — 검증 및 보고
- 결과 확인 방법
- 대표님께 200자 이내 요약 보고
```

**절차 작성 원칙**:
- 단계별 번호 부여 (Claude가 순서를 인식)
- 조건 분기를 명시 (모델이 직접 판단하게 두지 않음)
- 도구 호출 예시를 실제로 실행 가능한 형태로 포함
- 실패 시 행동 지침 포함

---

## 5. 자동 스킬 생성 규칙

CLAUDE.md Auditability 섹션에 명시된 자동 스킬 생성 트리거입니다. 대표님 지시 없이도 다음 조건에서 에이전트가 자율적으로 스킬을 생성합니다.

| 트리거 조건 | 예시 |
|------------|------|
| 5회+ 도구 호출이 필요한 복합 작업 완료 후 | 블로그 발행 전체 플로우 |
| 에러 → 해결 성공 패턴 (dead-end 돌파) 후 | Prisma v7 Windows 설치 우회 |
| 대표님 교정이 있었던 접근법 발견 후 | 이미지 캡처 방식 교정 |

생성 후 동시에 두 곳에 저장합니다.

```bash
# 1. harness commands 디렉토리
# D:/jamesclew/harness/commands/{skill-name}.md 작성

# 2. gbrain 동기 저장
gbrain put skill-{name} < D:/jamesclew/harness/commands/{skill-name}.md
```

---

## 6. Plugin 스킬과의 차이

하네스 스킬(`.md` 파일)과 Plugin 스킬은 다릅니다.

| 구분 | 위치 | 호출 방식 | 예시 |
|------|------|----------|------|
| 하네스 스킬 | `~/.claude/commands/` | `/skill-name` | `/blog-pipeline`, `/annotate-plan` |
| Plugin 스킬 | Plugin 레지스트리 | `/plugin:name:action` | `/plugin:ralph-claude-code:loop` |

Plugin 스킬은 외부 패키지로 관리되며 `harness/tools/` 디렉토리에 별도 설치됩니다. 하네스 스킬은 대표님이 직접 관리하는 내부 절차 문서입니다.

---

## 7. 실전 예시: /annotate-plan.md 구조 분해

`D:/jamesclew/harness/commands/annotate-plan.md`는 플랜 파일에 주석을 수집·반영하는 품질 게이트 스킬입니다.

```
frontmatter:
  description: "Plan 산출물에 대표님 인라인 주석을 수집·반영하는 반복 루프"
  argument-hint: "<plan-file-path>"
  allowed-tools: ["Read", "Edit", "Grep", "Bash"]

본문 구조:
  ## When to use  <- 실행 시점 명시
  ## Why this exists  <- 존재 이유 (Claude가 의도를 이해)
  ## Procedure
    ### 1단계 — 주석 수집  <- Grep으로 <!-- 👉 --> 패턴 추출
    ### 2단계 — 주석 분류  <- 표로 카테고리 정의
    ### 3단계 — 플랜 업데이트  <- Edit 도구로 직접 수정
    ### 4단계 — 변경 요약  <- 200자 이내 보고
    ### 5단계 — 재제출  <- 다음 라운드 대기
  ## Convergence rules  <- 최대 6회, 수렴 완료 헤더 삽입 조건
  ## Output format  <- 출력 형식 템플릿
  ## Related  <- 연관 스킬 목록
```

이 구조가 스킬 작성의 기준 형식입니다. Purpose → When → Procedure → Rules → Output → Related 순서를 따르십시오.

---

## 관련 파일

- 스킬 소스: `D:/jamesclew/harness/commands/` (21개)
- 배포 스크립트: `D:/jamesclew/harness/deploy.sh`
- 대표 예시: `D:/jamesclew/harness/commands/annotate-plan.md`
- gbrain 동기: `gbrain put skill-{name} < commands/{name}.md`
