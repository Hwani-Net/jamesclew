# NotebookLM MCP 사용 가이드

> 설치 패키지: notebooklm-mcp-cli v0.4.8 (jacob-bd) + notebooklm-mcp-server v0.1.15 (roomi-fields)
> lazy-mcp 등록: notebooklm-mcp.exe (stdio)
> 최종 조사: 2026-04-07 | 근거: GitHub README + Perplexity 5개 소스

## 개요
Google NotebookLM (notebooklm.google.com) — 문서 기반 AI Q&A + 콘텐츠 생성 도구.
소스(PDF, URL, YouTube, 텍스트) 업로드 → Gemini가 전처리 → 질의 무제한 → 콘텐츠 생성(9종).
**핵심 장점**: 제로 할루시네이션 (소스에 없는 내용은 답변 거부), 무료, 소스 50개+ 상관 분석.

---

## 왜 NotebookLM인가? (vs 로컬 RAG vs 웹 검색)

| 방식 | 할루시네이션 | 소스 관리 | 비용 |
|------|------------|----------|------|
| 로컬 RAG | 중간 | 직접 구축 | 높음 |
| 웹 검색 (Perplexity) | 낮음 | 없음 (일회성) | 유료 |
| **NotebookLM** | **거의 없음** | **영구 누적** | **무료** |

**최적 사용 시나리오**:
- 반복 참조하는 문서 (기술 문서, 규정, 디자인 가이드)
- 여러 소스를 교차 분석해야 하는 리서치
- 콘텐츠 생성 (팟캐스트, 영상, 보고서)
- 프로젝트 영구 지식 베이스 구축

---

## 사용 가능한 두 패키지

### 1. notebooklm-mcp-cli (jacob-bd) — 현재 v0.4.8
**25개+ 도구, 가장 기능이 풍부**

| 카테고리 | 도구 | 설명 |
|----------|------|------|
| **노트북** | `notebook_list` | 전체 노트북 목록 |
| | `notebook_create` | 새 노트북 생성 |
| | `notebook_get` | 노트북 상세 + 소스 목록 |
| | `notebook_describe` | AI 요약 + 추천 주제 |
| | `notebook_rename` | 이름 변경 |
| | `notebook_delete` | 삭제 (confirm=True 필수) |
| **소스** | `source_add` | 통합 소스 추가 (url/text/file/drive) |
| | `source_list_drive` | Drive 소스 최신성 확인 |
| | `source_sync_drive` | 오래된 Drive 소스 동기화 |
| | `source_delete` | 소스 삭제 |
| | `source_describe` | AI 요약 + 키워드 |
| | `source_get_content` | 원본 텍스트 추출 (AI 처리 없음) |
| **질의** | `notebook_query` | AI Q&A (인용 포함) |
| | `chat_configure` | 대화 목표/스타일/응답 길이 설정 |
| **리서치** | `research_start` | 웹/Drive 검색 → 소스 발견 |
| | `research_status` | 진행 상황 폴링 |
| | `research_import` | 발견된 소스를 노트북에 가져오기 |
| **스튜디오** | `audio_overview_create` | 팟캐스트 생성 (deep_dive/brief/critique/debate) |
| | `video_overview_create` | 영상 생성 (explainer/brief, 6종 비주얼 스타일) |
| | `infographic_create` | 인포그래픽 생성 (가로/세로) |
| | `slide_deck_create` | 슬라이드 데크 생성 |
| | `studio_status` | 생성 상태 확인 |
| | `studio_delete` | 아티팩트 삭제 |
| **배치** | `batch` | 여러 노트북 일괄 작업 (query/add_source/create/delete/studio) |
| | `cross_notebook_query` | 여러 노트북 교차 질의 + 노트북별 인용 |
| **태그** | `tag` | 노트북 태그 관리 (add/remove/select) |

### 2. notebooklm-mcp-server (roomi-fields) — v0.1.15
**Q&A + 콘텐츠 생성 + REST API**

| 도구 | 설명 |
|------|------|
| `ask_question` | AI Q&A (인용 형식 5가지: none/inline/footnotes/json/expanded) |
| `add_notebook` | 노트북 라이브러리에 추가 |
| `list_notebooks` | 목록 |
| `select_notebook` | 활성 노트북 선택 |
| `get_notebook` | 상세 |
| `search_notebooks` | 키워드 검색 |
| `setup_auth` | Google 인증 |
| `list_sessions` | 세션 목록 |
| `generate_audio` | 팟캐스트 생성 |
| `generate_video` | 영상 생성 |
| `generate_infographic` | 인포그래픽 |
| `generate_report` | 보고서 |
| `generate_presentation` | 프레젠테이션 |
| `generate_data_table` | 데이터 테이블 |
| `cleanup_data` | 데이터 정리 |
| `get_library_stats` | 통계 |

---

## 인증
두 패키지 모두 **브라우저 기반 Google 로그인** 필요.
```bash
# jacob-bd (CLI): 첫 실행 시 자동 브라우저 열림
# roomi-fields: 명시적 인증
notebooklm-mcp.exe  # 첫 실행 시 브라우저 인증
```

---

## 핵심 워크플로우

### 1. 프로젝트 지식 베이스 구축
```
notebook_create("BiteLog Design System")
→ source_add(type="url", url="https://...")  # 디자인 가이드
→ source_add(type="file", file_path="DESIGN.md")  # 로컬 파일
→ source_add(type="text", text="...")  # 텍스트
→ notebook_query("다크 테마에서 Glass morphism 가이드라인은?")
```

### 2. 딥 리서치 → 소스 영구 저장
```
research_start(query="premium fishing app UI trends 2026", mode="deep")
→ research_status(notebook_id, max_wait=300)
→ research_import(notebook_id, task_id)  # 발견 소스 가져오기
→ notebook_query("최신 트렌드 요약해줘")
```

### 3. 콘텐츠 생성 파이프라인
```
# 팟캐스트
audio_overview_create(notebook_id, format="deep_dive", confirm=True)
→ studio_status(notebook_id)  # 완료까지 폴링
→ download_artifact(notebook_id, "audio", "podcast.mp3")

# 보고서
studio_create(notebook_id, artifact_type="report", report_format="Briefing Doc")

# 인포그래픽
infographic_create(notebook_id, orientation="vertical")

# 슬라이드
slide_deck_create(notebook_id, detail_level="overview")
```

### 4. 교차 노트북 분석
```
# 태그로 관련 노트북 그룹핑
tag(action="add", notebook_id="abc", tags="fishing,design")
tag(action="add", notebook_id="def", tags="fishing,competitors")

# 여러 노트북에서 교차 질의
cross_notebook_query(query="경쟁 앱 대비 우리 디자인의 차별점은?", tags="fishing")

# 일괄 팟캐스트 생성
batch(action="studio", artifact_type="audio", tags="fishing", confirm=True)
```

---

## 도구 선택 가이드 (NotebookLM vs 다른 도구)

| 상황 | 최적 도구 | 이유 |
|------|----------|------|
| 빠른 팩트 확인 | Perplexity search | 속도 + 비용 |
| URL 원문 추출 | Tavily extract | 직접 마크다운 |
| 반복 참조 문서 | **NotebookLM** | 영구 저장 + 무제한 질의 |
| 심층 리서치 + 영구 저장 | **NotebookLM research_start** | 무료 + 소스 누적 |
| 콘텐츠 생성 (팟캐스트 등) | **NotebookLM studio** | 9종 형식 무료 |
| 여러 문서 교차 분석 | **NotebookLM cross_notebook_query** | 50개+ 소스 상관 |
| 최신 뉴스/트렌드 | Perplexity search | 실시간 웹 |
| 사이트 크롤링 | Tavily crawl | 재귀적 수집 |

---

## 스튜디오 콘텐츠 유형 (9종)

| 유형 | 형식 옵션 | 설명 |
|------|----------|------|
| **audio** | deep_dive, brief, critique, debate | 팟캐스트 (80+ 언어) |
| **video** | explainer, brief (6 비주얼 스타일) | 영상 요약 |
| **report** | Briefing Doc, Study Guide, Blog Post | 텍스트 보고서 |
| **quiz** | 객관식 (난이도/문항수 설정) | 퀴즈 |
| **flashcards** | easy/medium/hard | 학습 카드 |
| **mind_map** | - | 마인드맵 |
| **slide_deck** | overview/detailed | 프레젠테이션 |
| **infographic** | horizontal/vertical | 인포그래픽 |
| **data_table** | simple/detailed | 데이터 테이블 |

---

## 환경변수

| 변수 | 설명 |
|------|------|
| `NOTEBOOKLM_MCP_TRANSPORT` | 전송 방식 (stdio/http/sse) |
| `NOTEBOOKLM_MCP_HOST` | 바인드 호스트 (기본 127.0.0.1) |
| `NOTEBOOKLM_MCP_PORT` | 포트 (기본 8000) |
| `NOTEBOOKLM_MCP_DEBUG` | 디버그 로깅 (true/false) |
| `NOTEBOOKLM_HL` | 인터페이스 언어 (기본 en, ko 가능) |
| `NOTEBOOKLM_QUERY_TIMEOUT` | 쿼리 타임아웃 (기본 120초) |

---

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| 인증 실패 | 브라우저 로그인 필요 | `setup_auth` 또는 첫 실행 시 브라우저 |
| 질의 타임아웃 | 120초 기본 제한 | `--query-timeout 300` |
| 소스 추가 후 즉시 질의 실패 | 소스 처리 미완료 | `source_add(..., wait=True)` |
| studio 생성 확인 안 됨 | 비동기 생성 | `studio_status`로 폴링 |
| lazy-mcp에서 도구 안 보임 | MCP 미로드 | `invoke_command`로 직접 호출 |

---

## 흔한 실수
- ❌ source_add 후 즉시 질의 (처리 완료 대기 필요, wait=True)
- ❌ studio_create 후 결과 즉시 요청 (studio_status로 폴링 필수)
- ❌ 일회성 질문에 NotebookLM 사용 (Perplexity가 빠르고 저렴)
- ❌ 노트북 삭제 시 confirm=True 빼먹기
- ❌ 대량 소스에 research_import timeout 부족 (timeout=600 권장)

---

## JamesClaw 활용 전략
1. **프로젝트별 노트북 생성**: BiteLog 디자인, 경쟁사 분석, 법률/규정 등
2. **리서치 결과 영구 저장**: Perplexity/Tavily로 찾은 핵심 소스를 NotebookLM에 누적
3. **세션 간 지식 유지**: compact 후에도 NotebookLM에 질의하면 이전 리서치 활용
4. **콘텐츠 파이프라인**: 블로그 글 → NotebookLM 리서치 → 팟캐스트/인포그래픽 자동 생성
5. **교차 검수 소스**: 외부 모델 검수 시 NotebookLM의 인용 기반 답변을 참고 자료로 활용
