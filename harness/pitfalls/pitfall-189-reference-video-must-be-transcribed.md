# PITFALL-189 — 레퍼런스 영상 자막 미확보 후 추측 진행

등록일: 2026-05-20
슬러그: reference-video-must-be-transcribed
관련: P-188 (매뉴얼 정독 누락), P-184 (Native Windows 환경 차이)

---

## 증상

대표님이 레퍼런스 영상(YouTube) URL 제공 → WebFetch 1회 실패(transcript 없음) → 추측으로 진행 → B 시나리오 정확 구성 모름 → A로 단정 → 다시 B로 정정 → 200턴+ 낭비.

---

## 원인

영상도 매뉴얼·문서와 동일한 **기준 1차 source**. WebFetch 1회 실패에서 포기하고 yt-dlp 같은 대안 도구를 시도하지 않음. 추측으로 작업 진행한 것이 핵심 원인.

---

## 해결

레퍼런스 영상 받으면 즉시 자막 확보:

```bash
wsl -d Ubuntu -e bash -lc "pip3 install --user --break-system-packages yt-dlp && ~/.local/bin/yt-dlp --skip-download --write-auto-subs --write-subs --sub-langs 'ko,en' --sub-format 'vtt' --output 'opvid.%(ext)s' '<YouTube_URL>'"
```

→ 자막 vtt 다운로드 후 서브에이전트에 정독 + 핵심 timestamp·인용 보고 위임.

자막 fetch 실패 시 폴백 순서:
1. cobalt.tools 또는 downsub 같은 외부 서비스
2. 대표님께 영상 내용 직접 설명 요청

자막 확보 즉시 `$OBSIDIAN_VAULT/06-raw/{YYYY-MM-DD}-{slug}.md`에 BASB Raw tier로 저장.

---

## 재발 방지

- 대표님이 "레퍼런스 영상", "이 영상 봐줘" 등 명시하면 1차 source = 자막 정독 필수
- transcript fetch 1회 실패 시 즉시 yt-dlp 폴백. 포기 금지.
- "추측으로 진행"은 200턴+ 낭비 사고의 패턴 (P-188과 유사)
- BASB Raw tier 원칙: 영상 자막은 즉시 `06-raw/`에 저장

---

## 연관 PITFALL

- [[pitfall-184-openclaw-windows-discord-readiness]] — Native Windows 환경 차이 미인식 사고
- [[pitfall-188-openclaw-wsl2-deployment-complete-2026-05-20]] — 매뉴얼 정독 누락 교훈

## Backlinks

- `06-raw/2026-05-20-openclaw-claude-codex-tikitaka-video.md` (병렬 작업)
