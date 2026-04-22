---
title: 페르소나 커스터마이즈
type: reference
diátaxis: Reference
source: D:/jamesclew/harness/persona.yaml.example
---

# 페르소나 커스터마이즈

하네스는 `persona.yaml` 을 통해 에이전트의 호칭, 톤, 언어, 활성 모듈을 커스터마이즈합니다. `install.sh` 가 이 파일을 읽어 `CLAUDE.md` 의 플레이스홀더를 sed로 치환한 뒤 배포합니다.

---

## 파일 위치

| 파일 | 역할 |
|------|------|
| `D:/jamesclew/harness/persona.yaml.example` | 스키마 예시. 직접 편집하지 않음. |
| `~/.harness/persona.yaml` | 실제 적용 파일. `install.sh` 가 example을 복사 후 대화형으로 수정. |

---

## persona.yaml 스키마

```yaml
# ─── Identity ───
agent_name: "JamesClaw"     # 에이전트 이름. CLAUDE.md에서 치환됨.
honorific: "대표님"          # 사용자 호칭. "사장님", "팀장님", 실명도 가능.
language: "ko"               # 대화 언어. ko | en | ja | zh
tone: "witty"                # formal | casual | witty
style_notes: "초기 설계 중시, 검증 필수, 불확실한 정보는 솔직히 명시"

# ─── Paths ───
obsidian_vault: ""           # 세션 저장·위키 파이프라인. 비워두면 비활성.
claude_home: "~/.claude"     # 하네스 배포 경로.
state_dir: "~/.harness-state" # hook 상태 파일 경로.

# ─── Modules ───
modules:
  telegram_notify: false     # 작업 완료 텔레그램 알림
  obsidian_sync: false       # 세션→옵시디언 자동 저장
  gbrain: false              # 영구 지식 베이스
  copilot_api: false         # GPT-4.1 프록시 (localhost:4141)
  codex_cli: false           # Codex CLI (6계정 로테이션)
  ollama_fallback: false     # Gemma 4 로컬 폴백 (localhost:11434)
  wiki_pipeline: false       # 일일 raw 소스 ingest
  hydra_teams: false         # Agent Teams GPT 프록시 (localhost:3456)

# ─── MCP Servers ───
mcp_servers:
  perplexity: true           # 웹 검색·리서치 (PERPLEXITY_API_KEY 필요)
  tavily: true               # 크롤링·추출 (TAVILY_API_KEY 필요)
  stitch: false              # Google AI UI 디자인 (온디맨드 권장)
  telegram: false            # 텔레그램 봇
  desktop_control: false     # Computer Use
  korean_law: false          # 한국 법령 (89 도구, 상시 로드 금지)
```

---

## install.sh 치환 흐름

```
persona.yaml 읽기
    │
    ├── agent_name  → CLAUDE.md 내 "JamesClaw" 치환
    ├── honorific   → "대표님" 치환
    ├── style_notes → Identity 섹션 주입
    └── modules     → 해당 hook/script 활성화 여부 결정
    │
    ▼
~/.claude/CLAUDE.md 생성 (렌더링 완료)
~/.claude/hooks/, rules/, commands/ 복사
```

---

## 수정 후 재배포

페르소나를 변경한 후 전체 재렌더링이 필요합니다.

```bash
# 대화형 (질문 포함)
bash harness/install.sh

# 자동 (현재 persona.yaml 그대로 적용)
bash harness/install.sh --non-interactive
```

호칭·톤만 바꾸는 경우 `~/.harness/persona.yaml` 을 직접 편집한 뒤 `--non-interactive` 로 재실행하십시오.

---

## modules.yaml 역할

`D:/jamesclew/harness/modules.yaml` 은 각 모듈(Telegram, gbrain, Codex 등)에 필요한 파일 목록과 환경변수를 정의합니다. `install.sh` 가 이 카탈로그를 읽어 `persona.yaml`의 `modules` 설정에 따라 선택적으로 복사합니다.

모듈을 추가하거나 비활성화하려면 `persona.yaml` 의 `modules` 섹션을 수정 후 재설치하십시오. `modules.yaml` 자체는 직접 편집하지 않습니다.

---

## 자주 묻는 커스터마이즈

| 변경 사항 | 수정 파일 | 키 |
|----------|----------|-----|
| 호칭을 "사장님"으로 변경 | `~/.harness/persona.yaml` | `honorific` |
| 영어 응답으로 전환 | `~/.harness/persona.yaml` | `language: en` |
| 텔레그램 알림 활성화 | `~/.harness/persona.yaml` | `modules.telegram_notify: true` |
| Obsidian 연동 | `~/.harness/persona.yaml` | `obsidian_vault: "C:/..."` + `modules.obsidian_sync: true` |
| GPT-4.1 외부 검수 활성화 | `~/.harness/persona.yaml` | `modules.copilot_api: true` |
