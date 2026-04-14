# Korean Law MCP 사용 가이드

> 패키지: korean-law-mcp v2.3.2 (chrisryugj) | 87개 도구
> lazy-mcp 등록: `npx -y korean-law-mcp` (온디맨드)
> 최종 조사: 2026-04-07 | 근거: npm + GitHub + GeekNews + Perplexity 5개 소스
> API: 법제처 Open API (무료, OPEN_LAW_ID 환경변수 필요)

## 개요
국가법령정보센터 Open API 기반 MCP 서버.
법령, 판례, 행정규칙, 자치법규, 헌재결정, 조세심판, 관세해석, 조약, 기관규정까지 검색·조회·분석.
**87개 도구** — 약칭 자동 인식, 조문번호 변환, HWP/HWPX 별표 추출, 3단 위임 구조 시각화.

---

## 설치/연결

### 온디맨드 (lazy-mcp, 현재 설정)
```bash
# architecture.md 규칙: 89도구 → 상시 로드 금지
claude mcp add korean-law -s user -- cmd /c npx -y korean-law-mcp
```
사용 후 제거: `claude mcp remove korean-law`

### 원격 엔드포인트 (설치 없이)
```
https://korean-law-mcp.fly.dev/mcp
```

### 환경변수
| 변수 | 설명 | 필수 |
|------|------|------|
| `OPEN_LAW_ID` | 법제처 Open API 아이디 | ✅ |

API 키 발급: law.go.kr → 회원가입 → Open API 신청 (무료, 즉시 승인)

---

## 핵심 도구 카테고리 (87개)

### 1. 법령 검색·조회 (기본)
| 도구 | 설명 | 예시 |
|------|------|------|
| `search_korean_law` | 법령 키워드 검색 | "건축법", "화관법" |
| `get_law_text` | 특정 조문 조회 (MST + jo) | 관세법 제38조 |
| `read_legal_resource` | 법령/판례 전문 조회 | `statute:12345` |
| `search_legal_terms` | 법률 용어 정의 검색 | "근로자" |

### 2. 판례
| 도구 | 설명 |
|------|------|
| `search_precedent` | 판례 검색 |
| `get_precedent_detail` | 판례 상세 (판시사항, 전문) |

### 3. 헌법재판소
| 도구 | 설명 |
|------|------|
| `search_prec_const` | 헌재 결정례 검색 |
| `get_prec_const_detail` | 결정례 상세 |

### 4. 행정규칙·자치법규
| 도구 | 설명 |
|------|------|
| `search_admin_rule` | 행정규칙 (고시, 훈령) 검색 |
| `search_autonomous_law` | 자치법규 (조례, 규칙) 검색 |

### 5. 법령 해석·비교
| 도구 | 설명 |
|------|------|
| `search_statutory_interpretations` | 법제처 유권해석 검색 |
| `compare_old_new` | 개정 전후 비교 |
| `get_article_history` | 조문 연혁 (제개정, 시행일, 이유) |

### 6. 별표·서식
| 도구 | 설명 |
|------|------|
| `get_annexes` | 별표/별지서식 목록 |
| `get_statute_attachments` | 첨부 파일 목록 |
| (자동) | HWPX/HWP → Markdown 변환 (kordoc 라이브러리) |

### 7. 체인 도구 (복합 리서치) ⭐
| 도구 | 설명 |
|------|------|
| `chain_full_research` | **AI검색→법령→판례→해석 한 번에** |
| `explore_legal_chain` | 특정 조문의 위임 법령 + 참조 조문 전체 탐색 (Deep Search) |

### 8. 조약·기관규정 (v2.2.0+)
| 도구 | 설명 |
|------|------|
| (조약 검색) | 대한민국 체결 조약 |
| (기관규정) | 학칙, 공공기관 규정 |

### 9. 문서 분석 (v2.2.0+)
| 도구 | 설명 |
|------|------|
| (문서 분석) | 계약서/MOU 법적 리스크 구조화 분석 |

### 10. 유틸리티
| 도구 | 설명 |
|------|------|
| `get_external_links` | 국가법령정보센터 공식 URL 생성 |
| (약칭 인식) | "화관법" → "화학물질관리법" 자동 변환 |
| (조문번호 변환) | "제38조" ↔ "003800" |
| (자연어 날짜) | "최근 3개월", "작년" → 기간 자동 변환 |

---

## 핵심 워크플로우

### 1. 특정 법 조문 조회
```
"관세법 제38조 알려줘"
→ search_korean_law("관세법") → MST 획득
→ get_law_text(mst, jo="003800")
```

### 2. 법령 개정 비교
```
"화관법 최근 개정 비교"
→ "화관법" → "화학물질관리법" 자동 변환
→ compare_old_new(mst)
```

### 3. 판례 + 해석례 리서치
```
"근로기준법 제74조 해석례"
→ search_statutory_interpretations("근로기준법 제74조")
→ get_interpretation_text(id)
```

### 4. 별표 서식 추출
```
"산업안전보건법 별표1 내용"
→ get_annexes(lawName="산업안전보건법 별표1")
→ HWPX 다운로드 → Markdown 변환
```

### 5. 전체 리서치 (체인) ⭐
```
"고등교육법 제20조 관련 전체 리서치"
→ chain_full_research("고등교육법 제20조")
→ AI검색 + 법령 + 판례 + 해석 + 위임 구조 한 번에
```

### 6. Deep Search (위임 구조 탐색)
```
"고등교육법 제20조의 하위 법령 전체"
→ explore_legal_chain("고등교육법", "제20조")
→ 시행령/시행규칙 + 참조 조문 전체 트리
```

---

## 스마트 검색 기능
- **약칭 자동 인식**: "김영란법" → "부정청탁 및 금품등 수수의 금지에 관한 법률"
- **조문번호 자동 변환**: "제38조" ↔ "003800" (API 내부 형식)
- **자연어 날짜**: "최근 3개월", "작년", "2024년" → 기간 필터
- **자치법규 연계**: 법률 ↔ 조례 위임 관계 양방향 추적

---

## 캐시 정책
- 검색 결과: 1시간 TTL
- 조문 내용: 24시간 TTL
- 캐시로 API 호출 최소화 (법제처 API 무료지만 rate limit 존재)

---

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| 401 Unauthorized | OPEN_LAW_ID 미설정 | 환경변수 설정 확인 |
| 검색 결과 없음 | 약칭 미인식 | 정식 법명으로 재검색 |
| HWP 변환 실패 | kordoc 의존성 | npm 재설치 |
| 89도구 로드 시 서브에이전트 실패 | 도구 수 초과 | lazy-mcp 온디맨드 사용 (상시 로드 금지) |
| 조문번호 형식 오류 | "제38조" vs "003800" | 도구가 자동 변환하므로 한글로 입력 |

---

## 흔한 실수
- ❌ 상시 로드 (89도구 → 서브에이전트 실패 원인)
- ❌ OPEN_LAW_ID 없이 실행 시도
- ❌ 단순 검색에 chain_full_research 사용 (무거움, search_korean_law가 빠름)
- ❌ 조문번호를 API 형식(003800)으로 수동 변환 (도구가 자동 처리)
- ❌ 별표 내용을 텍스트로 기대 (HWP/HWPX 파일이므로 kordoc 변환 필요)

---

## JamesClaw 활용 전략
1. **온디맨드 로드**: 법률 작업 시에만 `claude mcp add`, 완료 후 `claude mcp remove`
2. **체인 도구 우선**: 복합 리서치는 `chain_full_research`로 한 번에 해결
3. **NotebookLM 연계**: 법령 리서치 결과를 NotebookLM에 소스로 추가 → 영구 지식화
4. **결과 검증**: 법령 해석은 항상 원문 링크(`get_external_links`)와 대조
5. **약칭 활용**: "화관법", "김영란법" 등 약칭으로 자연스럽게 질의
