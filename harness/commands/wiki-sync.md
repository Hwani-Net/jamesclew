---
description: "gbrain ↔ Wiki 양방향 동기화"
user_invocable: true
---

# /wiki-sync — gbrain ↔ Wiki 브릿지

## 사용법
- `/wiki-sync` — 양방향 동기화 실행

## 실행 절차

### Phase 1: gbrain → Wiki (새 지식 → 위키 인제스트)
1. gbrain에서 최근 7일 내 저장된 페이지 목록 조회: `gbrain list -n 50`
2. 각 페이지의 slug를 위키 index.md (`C:/Users/AIcreator/Obsidian-Vault/05-wiki/index.md`) 와 대조
3. 위키에 없는 새 지식 → `C:/Users/AIcreator/Obsidian-Vault/06-raw/` 에 마크다운으로 저장
   - 파일명: `{slug}.md`
   - 내용: `gbrain get {slug}` 출력 그대로 저장
4. `C:/Users/AIcreator/Obsidian-Vault/06-raw/.ingest-queue` 에 새 파일명 append

### Phase 2: Wiki → gbrain (위키 페이지 → gbrain 동기화)
1. `C:/Users/AIcreator/Obsidian-Vault/05-wiki/` 하위 모든 .md 파일 목록 수집
   - 대상 디렉토리: `concepts/`, `entities/`, `analyses/`, `sources/`
2. 각 파일에 대해 slug = 파일명(확장자 제외) 로 gbrain에 업서트:
   ```bash
   gbrain put {slug} < "{wiki_file_path}"
   ```
3. 신규 청크 임베딩 반영: `gbrain doctor` 로 상태 확인

### Phase 3: 인제스트 큐 처리
1. `C:/Users/AIcreator/Obsidian-Vault/06-raw/.ingest-queue` 파일 확인
2. 큐에 있는 파일들 내용을 `05-wiki/` 적절한 서브디렉토리로 분류 이동:
   - 개념/패턴/원칙 → `concepts/`
   - 엔티티(도구/서비스/인물) → `entities/`
   - 분석/리서치 결과 → `analyses/`
   - 출처/참조 → `sources/`
3. `C:/Users/AIcreator/Obsidian-Vault/05-wiki/index.md` 에 신규 항목 append
4. 처리 완료된 항목은 큐에서 제거 (빈 줄로 처리)

### Phase 4: 결과 보고
다음 형식으로 대표님께 보고:
```
[wiki-sync 완료]
- gbrain → Wiki: {N}개 신규 페이지 → 06-raw/ 저장
- Wiki → gbrain: {N}개 페이지 업서트
- 큐 처리: {N}개 항목 05-wiki/ 분류 완료
- gbrain 총 청크: {N} (doctor 출력)
```

## 전제 조건
- gbrain CLI 설치 및 `~/.gbrain/brain.pglite` 초기화 완료
- `C:/Users/AIcreator/Obsidian-Vault/06-raw/` 디렉토리 존재
- Obsidian Vault 경로: `C:/Users/AIcreator/Obsidian-Vault/`

## 주의사항
- 위키 파일 덮어쓰기 금지 — gbrain 내용이 위키보다 오래됐을 경우 skip
- `.ingest-queue` 처리 후 원본(`06-raw/`) 파일은 삭제하지 않음 (백업 보존)
- gbrain put 실패 시 3회 재시도 후 실패 목록만 보고, 나머지 계속 진행
