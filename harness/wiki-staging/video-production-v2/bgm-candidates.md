# BGM 후보 (2026-04-28)
프로젝트: 심해의 청룡 1분 데모 / K-fantasy mythology

---

## 1순위 — Hypnotic Orient (soundimage.org)
- **제목**: Hypnotic Orient
- **아티스트**: Eric Matyas (soundimage.org)
- **페이지 URL**: https://soundimage.org/world/
- **직접 다운로드 URL**: https://soundimage.org/wp-content/uploads/2016/04/Hypnotic-Orient.mp3
- **길이**: 2:53 (173초 — ffmpeg trim으로 60초 추출 가능)
- **파일 크기**: 4.0 MB (HTTP 200 확인됨)
- **라이선스**: Creative Commons Attribution 4.0 (상업·개인 재배포 OK, 크레딧 필요)
- **형식**: MP3
- **분위기 매칭**: Oriental/mystical 분위기. 동양 타악기+현악 추정. 수미상관 구조 편집 시 87% climax 설정 가능. "심해의 청룡" 신화적 분위기에 적합.
- **검증 상태**: HTTP 200 확인됨

---

## 2순위 — A Thousand Exotic Places (soundimage.org)
- **제목**: A Thousand Exotic Places
- **아티스트**: Eric Matyas (soundimage.org)
- **페이지 URL**: https://soundimage.org/world/
- **직접 다운로드 URL**: https://soundimage.org/wp-content/uploads/2018/08/A-Thousand-Exotic-Places.mp3
- **길이**: 3:07 (187초 — ffmpeg trim 가능)
- **파일 크기**: 7.2 MB (HTTP 200 확인됨)
- **라이선스**: Creative Commons Attribution 4.0
- **형식**: MP3
- **분위기 매칭**: 이국적 cinematic 분위기. 풀오케스트라 스타일. 길이가 길어 climax 배치 자유로움.
- **검증 상태**: HTTP 200 확인됨

---

## 3순위 — Ancient Troops Amassing (soundimage.org)
- **제목**: Ancient Troops Amassing
- **아티스트**: Eric Matyas (soundimage.org)
- **페이지 URL**: https://soundimage.org/epic-battle/
- **직접 다운로드 URL**: https://soundimage.org/wp-content/uploads/2016/07/Ancient-Troops-Amassing.mp3
- **길이**: 1:36 (96초 — 60초 편집 가능)
- **파일 크기**: 2.2 MB (HTTP 200 확인됨)
- **라이선스**: Creative Commons Attribution 4.0
- **형식**: MP3
- **분위기 매칭**: "드래곤 공+남성 보컬" 포함 — 용/신화 전투 분위기. 1분 타이트 편집 시 climax 구조 살리기 좋음.
- **검증 상태**: HTTP 200 확인됨

---

## 4순위 (Pixabay — 수동 다운로드 필요)
- **제목**: Grace in Hanbok
- **아티스트**: DreamPixelz
- **트랙 페이지**: https://pixabay.com/music/folk-grace-in-hanbok-321003/
- **직접 다운로드 URL**: Pixabay Cloudflare 차단으로 자동 검증 불가 — 브라우저에서 수동 다운로드 필요
- **길이**: 2:01 (페이지 메타 기준)
- **라이선스**: Pixabay License (상업·개인 재배포 OK, attribution 불필요)
- **형식**: MP3
- **분위기 매칭**: 한복+한국 전통 folk — K-fantasy 분위기에 가장 직접적으로 부합. 60초 trim 필요.
- **검증 상태**: 페이지 존재 확인, 직접 URL 미검증

---

## 5순위 (Pixabay — 수동 다운로드 필요)
- **제목**: Dragon's FLight
- **아티스트**: (Pixabay 등록 아티스트)
- **트랙 페이지**: https://pixabay.com/music/epic-classical-dragonx27s-flight-447566/
- **직접 다운로드 URL**: Pixabay Cloudflare 차단으로 자동 검증 불가
- **길이**: 미확인 (Pixabay 페이지 직접 방문 필요)
- **라이선스**: Pixabay License (attribution 불필요)
- **형식**: MP3
- **분위기 매칭**: Epic classical + 드래곤 테마 — 제목에서 직접 부합.
- **검증 상태**: 페이지 존재 확인, 직접 URL 미검증

---

## ffmpeg trim 명령 (1~3순위 공통)
```bash
# 60초 추출 (0초~60초)
ffmpeg -i input.mp3 -ss 0 -t 60 -c copy output_60s.mp3

# 87% climax 맞추기 (52초 지점 climax 배치용 페이드)
ffmpeg -i input.mp3 -ss 0 -t 60 -af "afade=t=out:st=55:d=5" output_60s_fade.mp3
```

## 크레딧 표기 (soundimage.org 트랙 사용 시)
```
Music: "[트랙명]" by Eric Matyas (soundimage.org)
Licensed under CC BY 4.0: https://creativecommons.org/licenses/by/4.0/
```
