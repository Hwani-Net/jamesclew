---
description: "Obsidian 00-inbox/ 비우기 — BASB Organize 단계"
user_invocable: true
---

# /inbox-process — Obsidian inbox 정리

## 사용법
- `/inbox-process` — 00-inbox/ 전체 처리
- `/inbox-process <filename>` — 특정 파일만 처리

## 실행 절차

### Step 1: inbox 파일 목록 수집
```bash
VAULT="${OBSIDIAN_VAULT:-C:/Users/AIcreator/Obsidian-Vault}"
INBOX="$VAULT/00-inbox"
mapfile -d '' FILES < <(find "$INBOX" -maxdepth 1 -name "*.md" -print0 2>/dev/null)
```
`$ARGUMENTS` 가 있으면 해당 파일만 대상으로 제한.

### Step 2: inbox 비어있으면 즉시 종료
파일이 0개이면:
```
[inbox-process] Inbox 비어있음. 정리 불필요.
```
출력 후 종료.

### Step 3: 각 파일 처리

파일마다 아래 순서 실행:

#### 3a. 파일 내용 읽기 (첫 200자)
```bash
head -c 200 "$FILE"
```

#### 3b. 목적지 결정 룰 (우선순위 순)

| 조건 | 목적지 |
|------|--------|
| `http://` 또는 `https://` URL 포함 | `05-wiki/sources/` |
| 파일명/내용에 프로젝트명 포함 (예: smartreview, agentlens, blog) | `02-projects/` |
| `실수`, `교훈`, `pitfall`, `오류` 키워드 포함 | pitfall 변환 권고 (수동 승인) |
| `개념`, `패턴`, `원칙`, `정의`, `란?` 포함 | `05-wiki/concepts/` |
| 개인 메모 또는 날짜 기반 파일명 | `04-personal/` |
| 판단 불가 (위 조건 해당 없음) | AskUserQuestion으로 위치 선택 |

#### 3c. pitfall 변환 권고 처리
목적지가 pitfall인 경우 이동 전 대표님 확인:
- 파일 내용 요약 + "harness/pitfalls/pitfall-NNN-{slug}.md 로 변환을 권고합니다. 이동할까요?" 출력
- **이동은 수동 승인 대기** — 자동 이동 금지
- 승인 시: `D:/jamesclew/harness/pitfalls/` 로 복사 후 `gbrain import D:/jamesclew/harness/pitfalls/` 실행

#### 3d. 모호한 경우 AskUserQuestion
위 룰로 판단 불가 시:
```
파일: {filename}
내용 미리보기: {첫 200자}

목적지를 선택하십시오:
1. 05-wiki/sources/ (외부 레퍼런스)
2. 05-wiki/concepts/ (개념·패턴)
3. 02-projects/ (프로젝트 관련)
4. 04-personal/ (개인 메모)
5. 건너뜀 (나중에 처리)
```

#### 3e. 파일 이동
```bash
DEST="$VAULT/{목적지}"
DEST_FILE="$DEST/$(basename "$FILE")"

# 충돌 방지
if [ -f "$DEST_FILE" ]; then
  SUFFIX=$(date +%Y%m%d%H%M)
  BASENAME=$(basename "$FILE" .md)
  DEST_FILE="$DEST/${BASENAME}-${SUFFIX}.md"
fi

mv "$FILE" "$DEST_FILE"
```
한국어 파일명은 큰따옴표로 감싸서 처리 (이미 변수 참조로 안전).
이동 실패 시 해당 파일 건너뛰고 실패 목록에 기록 후 계속 진행.

### Step 4: gbrain import 재실행
```bash
gbrain import "$VAULT/05-wiki/"
```
이동된 파일이 sources/ 또는 concepts/로 갔을 경우만 실행.
실패 시 경고 출력 후 계속.

### Step 5: 처리 결과 요약 출력
```
[inbox-process 완료]
- 총 처리: N건
- 05-wiki/sources/: X건
- 05-wiki/concepts/: X건
- 02-projects/: X건
- 04-personal/: X건
- pitfall 변환 대기: X건 (수동 승인 필요)
- 건너뜀: X건
- 실패: X건 (파일명 목록)
```

## 전제 조건
- `$OBSIDIAN_VAULT` 환경변수 설정 (미설정 시 `C:/Users/AIcreator/Obsidian-Vault` 기본값)
- `00-inbox/`, `02-projects/`, `04-personal/`, `05-wiki/sources/`, `05-wiki/concepts/` 디렉토리 존재
- gbrain CLI 실행 가능

## 주의사항
- 기존 파일 덮어쓰기 금지 — 충돌 시 `-YYYYMMDDHHMM` 접미사 자동 부여
- 한국어 파일명: 변수 참조 시 큰따옴표 필수 (`"$FILE"` 형태)
- pitfall 변환은 반드시 수동 승인 대기 — 자동 이동하면 harness/pitfalls/ 넘버링 충돌 위험
- `mv` 실패는 건너뜀 처리 (abort 금지). 실패 목록은 Step 5 요약에 포함
- gbrain import는 이동 완료 후 1회만 실행 (파일별 반복 금지 — 성능 저하)
