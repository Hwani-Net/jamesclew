# PITFALL-230: 보고서 산출 형식 HTML 규칙 미등록

날짜: 2026-05-27
세션: youtube_longform / Google Flow 자동화 분석

## Symptom
대표님께 최종 보고서를 Markdown(.md) 파일 경로로 제시. 대표님이 "내가 볼 파일이라면 md로 작성해서 보여주는게 맞아?" 지적. 후속 "규칙에 html로 보여줘야 한다고 했는데 규칙이 도달되지 않는것 보니 규칙이 무시되는것 같은데?"

## Cause
"대표님이 직접 볼 보고서는 HTML로 변환해서 제공"이라는 규칙이 시스템 영구 레이어에 미등록.
- `C:/Users/AIcreator/.claude/CLAUDE.md` STICKY DECISIONS 미등록
- `D:/jamesclew/harness/pitfalls/` PITFALL 미존재
- agentmemory MCP 미저장
- 옵시디언 vault 미저장
→ 신규 세션이 자동으로 인지 불가.

## Fix
1. 본 PITFALL 파일 생성 (영구 레이어 1)
2. agentmemory `memory_save` (영구 레이어 2)
3. CLAUDE.md STICKY DECISIONS 또는 "출력 규약" 섹션에 등록 (영구 레이어 3)
4. MEMORY.md (`C:/Users/AIcreator/.claude/projects/E--youtube-longform/memory/MEMORY.md`)에 인덱스 (영구 레이어 4)

## Prevention
- 대표님께 보고서 산출물 제출 시 기본 형식: **HTML 변환 후 절대 경로 제시**
- md는 작업 중간 산출물(draft)에만 사용
- 매 세션 시작 시 SessionStart hook이 본 규칙 additionalContext로 주입되도록 추후 hook 등록 검토
- "내가 볼 파일" / "보고서" / "최종" / "final" 키워드 감지 시 즉시 HTML 변환 게이트
