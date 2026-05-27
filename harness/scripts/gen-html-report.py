#!/usr/bin/env python3
"""
gen-html-report.py — JSON/텍스트 리포트를 color-coded HTML로 변환
Usage:
  python3 gen-html-report.py <input> <output> [--type blog-review|qa|pipeline|prd|design-review]
"""
import sys
import json
import os
import re
from datetime import datetime

def color(verdict):
    v = str(verdict).upper()
    if v in ("PASS", "TRUE", "OK", "COMPLETE"):
        return "#22c55e"  # green
    if v in ("FAIL", "FAILED", "FALSE", "ERROR"):
        return "#ef4444"  # red
    if v in ("WARN", "WARNING", "REWORK", "SKIP"):
        return "#f59e0b"  # amber
    return "#94a3b8"  # slate

def badge(verdict):
    c = color(verdict)
    return f'<span style="background:{c};color:#fff;padding:2px 10px;border-radius:999px;font-size:0.8rem;font-weight:700">{verdict}</span>'

def card(title, content, verdict=None):
    border = color(verdict) if verdict else "#334155"
    vbadge = f"  {badge(verdict)}" if verdict else ""
    return f"""
<div style="background:#1e293b;border:1px solid {border};border-radius:10px;padding:16px 20px;margin:10px 0">
  <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px">
    <span style="font-weight:700;font-size:1rem;color:#f1f5f9">{title}</span>{vbadge}
  </div>
  <div style="color:#cbd5e1;font-size:0.9rem;line-height:1.6">{content}</div>
</div>"""

def render_blog_review(data):
    slug = data.get("slug", "unknown")
    ts = data.get("timestamp", "")[:19].replace("T", " ")
    overall = data.get("overall", "?")

    # AI Smell
    ai = data.get("aiSmell", {})
    ai_score = ai.get("final", ai.get("codex", "?"))
    ai_verdict = ai.get("verdict", "?")
    ai_content = f"""
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:8px">
        <div style="text-align:center"><div style="font-size:2rem;font-weight:800;color:#f1f5f9">{ai_score}</div><div style="color:#94a3b8;font-size:0.8rem">최종 점수</div></div>
        <div style="text-align:center"><div style="font-size:1.5rem;font-weight:700;color:#94a3b8">{ai.get('codex','?')}</div><div style="color:#94a3b8;font-size:0.8rem">Codex</div></div>
        <div style="text-align:center"><div style="font-size:1.5rem;font-weight:700;color:#94a3b8">{ai.get('benchmark', ai.get('gpt41','?'))}</div><div style="color:#94a3b8;font-size:0.8rem">벤치마크</div></div>
      </div>
      <div style="margin-top:8px;color:#94a3b8;font-size:0.8rem">기준: &gt;65 PASS / 50~65 WARN / &lt;50 FAIL (벤치마크 비교)</div>"""

    # SEO
    seo = data.get("seo", {})
    seo_items = []
    checks = [
        ("키워드", seo.get("keywordCount","?"), "3회+"),
        ("메타설명", seo.get("metaDescLen","?"), "120~155자"),
        ("H2", seo.get("h2Count","?"), "3개+"),
        ("내부링크", seo.get("internalLinks","?"), "2개+"),
        ("FAQ", seo.get("faqCount","?"), "2개+"),
        ("본문길이", seo.get("wordCount","?"), "2000자+"),
    ]
    for label, val, req in checks:
        seo_items.append(f'<div style="background:#0f172a;border-radius:6px;padding:6px 10px;font-size:0.82rem"><span style="color:#94a3b8">{label}</span> <span style="color:#f1f5f9;font-weight:600">{val}</span> <span style="color:#475569">({req})</span></div>')
    seo_content = f'<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:6px;margin-top:8px">{"".join(seo_items)}</div>'
    failed = seo.get("failedItems", [])
    if failed:
        seo_content += f'<div style="margin-top:8px;color:#ef4444;font-size:0.82rem">실패: {", ".join(failed)}</div>'

    # Images
    imgs = data.get("images", {})
    img_content = f'이미지 수: <b>{imgs.get("count","?")}</b> | 유효: {badge("PASS" if imgs.get("allValid") else "FAIL")} | 주제매칭: {badge("PASS" if imgs.get("topicMatch") else "FAIL")}'

    # Expect Gates
    gates = data.get("expectGates", [])
    gate_rows = "".join([
        f'<tr><td style="color:#94a3b8;padding:4px 8px">{g.get("name","step"+str(g.get("step","")))}</td>'
        f'<td style="padding:4px 8px">{badge("PASS" if g.get("pass") else "FAIL")}</td>'
        f'<td style="color:#64748b;padding:4px 8px;font-size:0.8rem">{g.get("detail","")}</td></tr>'
        for g in gates
    ]) if gates else '<tr><td colspan="3" style="color:#475569;padding:4px 8px">스킵됨</td></tr>'
    gates_content = f'<table style="width:100%;border-collapse:collapse">{gate_rows}</table>'

    return f"""
    <div style="margin-bottom:24px">
      <div style="font-size:0.85rem;color:#475569;margin-bottom:4px">{slug} · {ts}</div>
      <div style="font-size:2.5rem;font-weight:800;color:#f1f5f9">Blog Review {badge(overall)}</div>
    </div>
    {card("🤖 AI냄새 검사", ai_content, ai_verdict)}
    {card("🔍 SEO 분석", seo_content, seo.get("verdict","?"))}
    {card("🖼️ 이미지 검증", img_content, imgs.get("verdict","?"))}
    {card("⚡ expect MCP 7단계", gates_content)}
    """

def md_to_html(md):
    """마크다운을 스타일링된 HTML 요소로 변환 (외부 라이브러리 불필요)."""
    lines = md.split("\n")
    out = []
    in_table = False
    in_code = False
    code_buf = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # 코드블록
        if line.strip().startswith("```"):
            if not in_code:
                in_code = True
                lang = line.strip()[3:].strip()
                code_buf = []
            else:
                in_code = False
                code = "\n".join(code_buf).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
                out.append(f'<pre style="background:#0f172a;border:1px solid #1e293b;border-radius:8px;padding:14px 16px;overflow-x:auto;font-size:0.82rem;color:#7dd3fc;margin:10px 0"><code>{code}</code></pre>')
            i += 1
            continue
        if in_code:
            code_buf.append(line)
            i += 1
            continue
        # 테이블
        if "|" in line and line.strip().startswith("|"):
            if not in_table:
                in_table = True
                out.append('<div style="overflow-x:auto;margin:12px 0"><table style="width:100%;border-collapse:collapse;font-size:0.87rem">')
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if all(re.match(r'^[-:]+$', c) for c in cells if c):
                i += 1
                continue
            is_header = i > 0 and "|" in lines[i-1] and not (i > 1 and all(re.match(r'^[-:]+$', c.strip()) for c in lines[i-1].strip().strip("|").split("|") if c.strip()))
            # 헤더 판별: 다음 줄이 구분선이면 헤더
            is_hdr = (i+1 < len(lines) and "|" in lines[i+1] and all(re.match(r'^[-:]+$', c.strip()) for c in lines[i+1].strip().strip("|").split("|") if c.strip()))
            tag = "th" if is_hdr else "td"
            style = 'style="border:1px solid #1e293b;padding:7px 12px;text-align:left;color:#f1f5f9;background:#1e293b"' if is_hdr else 'style="border:1px solid #1e293b;padding:7px 12px;text-align:left;color:#cbd5e1"'
            row = "".join(f"<{tag} {style}>{c}</{tag}>" for c in cells)
            out.append(f"<tr>{row}</tr>")
            i += 1
            continue
        else:
            if in_table:
                in_table = False
                out.append("</table></div>")
        # 제목
        m = re.match(r'^(#{1,4})\s+(.+)', line)
        if m:
            lvl = len(m.group(1))
            txt = m.group(2)
            sizes = {1:"1.7rem",2:"1.35rem",3:"1.1rem",4:"1rem"}
            mt = {1:"32px",2:"24px",3:"18px",4:"14px"}
            border = ' border-bottom:1px solid #1e293b; padding-bottom:8px;' if lvl <= 2 else ''
            out.append(f'<h{lvl} style="font-size:{sizes[lvl]};font-weight:700;color:#f1f5f9;margin:{mt[lvl]} 0 8px;{border}">{txt}</h{lvl}>')
            i += 1
            continue
        # 가로선
        if re.match(r'^---+$', line.strip()):
            out.append('<hr style="border:none;border-top:1px solid #1e293b;margin:20px 0">')
            i += 1
            continue
        # 인용
        if line.startswith("> "):
            out.append(f'<blockquote style="border-left:3px solid #f59e0b;padding:8px 14px;margin:10px 0;background:#1e293b;border-radius:0 6px 6px 0;color:#94a3b8;font-size:0.9rem">{line[2:]}</blockquote>')
            i += 1
            continue
        # 체크박스 리스트
        if re.match(r'^[-*]\s+\[[ xX]\]', line):
            checked = "[x]" in line.lower() or "[X]" in line
            icon = "✅" if checked else "⬜"
            text = re.sub(r'^[-*]\s+\[[ xX]\]\s*', '', line)
            out.append(f'<div style="padding:3px 0;color:#cbd5e1;font-size:0.9rem">{icon} {text}</div>')
            i += 1
            continue
        # 불릿 리스트
        if re.match(r'^[-*•]\s+', line):
            text = re.sub(r'^[-*•]\s+', '', line)
            # 인라인 강조
            text = re.sub(r'\*\*(.+?)\*\*', r'<strong style="color:#f1f5f9">\1</strong>', text)
            text = re.sub(r'`(.+?)`', r'<code style="background:#0f172a;padding:1px 5px;border-radius:4px;font-size:0.85rem;color:#7dd3fc">\1</code>', text)
            out.append(f'<div style="padding:2px 0 2px 14px;color:#cbd5e1;font-size:0.9rem">• {text}</div>')
            i += 1
            continue
        # 빈 줄
        if not line.strip():
            out.append('<div style="height:6px"></div>')
            i += 1
            continue
        # 일반 단락 (인라인 처리)
        text = line
        text = re.sub(r'\*\*(.+?)\*\*', r'<strong style="color:#f1f5f9">\1</strong>', text)
        text = re.sub(r'\*(.+?)\*', r'<em style="color:#94a3b8">\1</em>', text)
        text = re.sub(r'`(.+?)`', r'<code style="background:#0f172a;padding:1px 5px;border-radius:4px;font-size:0.85rem;color:#7dd3fc">\1</code>', text)
        out.append(f'<p style="color:#cbd5e1;font-size:0.9rem;line-height:1.7;margin:4px 0">{text}</p>')
        i += 1
    if in_table:
        out.append("</table></div>")
    return "\n".join(out)


def render_prd(md_text):
    # 제목 추출
    title_m = re.search(r'^#\s+(.+)', md_text, re.MULTILINE)
    title = title_m.group(1) if title_m else "PRD"
    # 버전/날짜 추출
    meta_m = re.search(r'작성일[:\s]+([^\|]+)', md_text)
    meta = meta_m.group(1).strip() if meta_m else ""

    # 섹션별 분리
    sections = re.split(r'\n(?=## )', md_text)
    toc_items = []
    section_html = []
    for sec in sections:
        hdr = re.match(r'^## (.+)', sec.strip())
        if hdr:
            sec_title = hdr.group(1)
            anchor = re.sub(r'[^a-zA-Z0-9가-힣]', '-', sec_title).lower()
            toc_items.append(f'<a href="#{anchor}" style="display:block;padding:5px 12px;color:#94a3b8;font-size:0.85rem;border-radius:5px;text-decoration:none;transition:background 0.15s" onmouseover="this.style.background=\'#1e293b\';this.style.color=\'#f1f5f9\'" onmouseout="this.style.background=\'transparent\';this.style.color=\'#94a3b8\'">{sec_title}</a>')
            section_html.append(f'<div id="{anchor}" style="margin-bottom:32px">{md_to_html(sec)}</div>')
        else:
            section_html.append(f'<div style="margin-bottom:32px">{md_to_html(sec)}</div>')

    toc = f'''
<div style="position:sticky;top:24px;background:#0f172a;border:1px solid #1e293b;border-radius:10px;padding:14px 8px;margin-bottom:0">
  <div style="font-size:0.75rem;color:#475569;padding:0 12px;margin-bottom:8px;letter-spacing:0.08em">목차</div>
  {"".join(toc_items)}
</div>'''

    return f'''
<div style="display:grid;grid-template-columns:200px 1fr;gap:32px;align-items:start">
  <div>{toc}</div>
  <div>
    <div style="margin-bottom:28px">
      <div style="font-size:0.85rem;color:#475569">{meta}</div>
      <div style="font-size:2rem;font-weight:800;color:#f1f5f9;margin-top:4px">{title}</div>
    </div>
    {"".join(section_html)}
  </div>
</div>'''


def render_design_review(raw_text):
    """design-review 결과 텍스트 or JSON → HTML rubric 카드."""
    # JSON 파싱 시도
    data = None
    try:
        data = json.loads(raw_text)
    except Exception:
        pass

    axes = [
        ("일관성", "consistency", "#6366f1"),
        ("독창성", "originality", "#ec4899"),
        ("완성도", "polish", "#f59e0b"),
        ("기능성", "functionality", "#22c55e"),
    ]

    if data and isinstance(data, dict) and "consistency" in data:
        scores = data
    else:
        # 텍스트에서 점수 파싱 시도
        scores = {}
        for _, key, _ in axes:
            m = re.search(rf'"{key}"[^}}]*"score"\s*:\s*(\d+)', raw_text)
            if not m:
                m = re.search(rf'{key}[^\d]*(\d+)', raw_text, re.IGNORECASE)
            scores[key] = {"score": int(m.group(1)), "reason": ""} if m else {"score": 0, "reason": "파싱 불가"}

    verdict = data.get("verdict", "?") if data else "?"
    fixes = (data.get("fixes", []) if data else [])
    cliches = (data.get("originality", {}).get("ai_cliches", []) if data and isinstance(data.get("originality"), dict) else [])

    # Rubric 점수 카드들
    score_cards = []
    for label, key, accent in axes:
        entry = scores.get(key, {}) if isinstance(scores.get(key), dict) else {"score": scores.get(key, 0)}
        sc = entry.get("score", 0)
        reason = entry.get("reason", "")
        bar_w = f"{sc * 10}%"
        c = "#22c55e" if sc >= 8 else "#f59e0b" if sc >= 6 else "#ef4444"
        score_cards.append(f'''
<div style="background:#1e293b;border:1px solid #334155;border-radius:10px;padding:16px 18px;margin:8px 0">
  <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
    <span style="font-weight:700;color:#f1f5f9;font-size:0.95rem">{label}</span>
    <span style="font-size:1.6rem;font-weight:800;color:{c}">{sc}<span style="font-size:0.9rem;color:#475569">/10</span></span>
  </div>
  <div style="background:#0f172a;border-radius:999px;height:6px;overflow:hidden;margin-bottom:8px">
    <div style="width:{bar_w};background:{c};height:100%;border-radius:999px;transition:width 0.4s"></div>
  </div>
  {f'<div style="color:#94a3b8;font-size:0.83rem">{reason}</div>' if reason else ''}
</div>''')

    # AI 클리셰 목록
    cliche_block = ""
    if cliches:
        items = "".join(f'<div style="background:#450a0a;border:1px solid #7f1d1d;border-radius:5px;padding:4px 10px;font-size:0.82rem;color:#fca5a5">{c}</div>' for c in cliches)
        cliche_block = f'<div style="margin:12px 0"><div style="color:#ef4444;font-size:0.85rem;font-weight:600;margin-bottom:6px">⚠️ AI 클리셰 감지</div><div style="display:flex;flex-wrap:wrap;gap:6px">{items}</div></div>'

    # 수정 제안
    fix_block = ""
    if fixes:
        fix_items = "".join(f'<div style="padding:5px 0;color:#cbd5e1;font-size:0.88rem;border-bottom:1px solid #1e293b">→ {f}</div>' for f in fixes)
        fix_block = f'<div style="margin:16px 0"><div style="color:#f59e0b;font-weight:600;font-size:0.9rem;margin-bottom:8px">🛠️ 수정 제안</div>{fix_items}</div>'

    # 전체 판정
    v_color = color(verdict)
    return f'''
<div style="margin-bottom:24px">
  <div style="font-size:2.2rem;font-weight:800;color:#f1f5f9">Design Review
    <span style="background:{v_color};color:#fff;padding:3px 14px;border-radius:999px;font-size:1rem;margin-left:12px;vertical-align:middle">{verdict}</span>
  </div>
</div>
<div style="display:grid;grid-template-columns:repeat(2,1fr);gap:4px">
  {"".join(score_cards)}
</div>
{cliche_block}
{fix_block}
<div style="margin-top:16px;padding:12px 16px;background:#1e293b;border-radius:8px;font-size:0.82rem;color:#475569">
  기준: 4개 축 모두 8점+ = PASS · 5점 이하 1개 = FAIL
</div>'''


def render_qa(raw_text):
    lines = raw_text.strip().split("\n") if raw_text else []
    verdict = "UNKNOWN"
    for line in lines:
        upper = line.upper()
        if "PASS" in upper and "FAIL" not in upper:
            verdict = "PASS"; break
        if "FAIL" in upper:
            verdict = "FAIL"; break
        if "REWORK" in upper:
            verdict = "REWORK"; break

    pre = "\n".join(lines[:80])
    return f"""
    <div style="margin-bottom:24px">
      <div style="font-size:2.5rem;font-weight:800;color:#f1f5f9">QA Report {badge(verdict)}</div>
    </div>
    {card("📋 외부 모델 평가 원문", f'<pre style="white-space:pre-wrap;font-size:0.82rem;color:#cbd5e1;max-height:600px;overflow-y:auto">{pre}</pre>')}
    """

def render_pipeline(data_or_text):
    if isinstance(data_or_text, dict):
        step = data_or_text.get("step", "?")
        verdict = data_or_text.get("verdict", "?")
        content = f"Step {step} 완료<br>" + json.dumps(data_or_text, ensure_ascii=False, indent=2)
    else:
        text = str(data_or_text)[:3000]
        verdict = "PASS" if "PASS" in text.upper() and "FAIL" not in text.upper() else "FAIL" if "FAIL" in text.upper() else "?"
        content = f'<pre style="white-space:pre-wrap;font-size:0.82rem;color:#cbd5e1">{text}</pre>'

    return f"""
    <div style="margin-bottom:24px">
      <div style="font-size:2.5rem;font-weight:800;color:#f1f5f9">Pipeline Report {badge(verdict)}</div>
    </div>
    {card("📊 최종 판정 결과", content, verdict)}
    """

def make_html(body_content, title="Report"):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M")
    return f"""<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title>
<style>
  * {{ box-sizing:border-box; margin:0; padding:0 }}
  body {{ background:#0f172a; color:#e2e8f0; font-family:'Pretendard','Apple SD Gothic Neo',system-ui,sans-serif; min-height:100vh; padding:32px 24px }}
  .container {{ max-width:860px; margin:0 auto }}
  .header {{ border-bottom:1px solid #1e293b; padding-bottom:16px; margin-bottom:24px }}
  .header .meta {{ font-size:0.8rem; color:#475569; margin-top:4px }}
  b {{ color:#f1f5f9 }}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <div style="font-size:0.75rem;color:#475569;letter-spacing:0.1em">JAMESCLAW · HARNESS</div>
    <div class="meta">생성: {ts}</div>
  </div>
  {body_content}
</div>
</body>
</html>"""

def main():
    args = sys.argv[1:]
    if len(args) < 2:
        print("Usage: gen-html-report.py <input> <output> [--type blog-review|qa|pipeline]")
        sys.exit(1)

    inp, out = args[0], args[1]
    report_type = "auto"
    for i, a in enumerate(args):
        if a == "--type" and i+1 < len(args):
            report_type = args[i+1]

    # 입력 읽기
    if not os.path.exists(inp):
        print(f"[gen-html-report] 입력 파일 없음: {inp}", file=sys.stderr)
        sys.exit(1)

    with open(inp, "r", encoding="utf-8") as f:
        raw = f.read()

    # JSON 파싱 시도
    data = None
    try:
        data = json.loads(raw)
    except Exception:
        pass

    # 타입 자동 감지
    if report_type == "auto":
        if inp.endswith(".md") or (raw.strip().startswith("#") and "## " in raw):
            report_type = "prd"
        elif data and "aiSmell" in data:
            report_type = "blog-review"
        elif data and "consistency" in str(data):
            report_type = "design-review"
        elif data and "step" in data:
            report_type = "pipeline"
        else:
            report_type = "qa"

    # 렌더링
    if report_type == "blog-review":
        body = render_blog_review(data or {})
        title = f"Blog Review — {(data or {}).get('slug', '')}"
    elif report_type == "pipeline":
        body = render_pipeline(data or raw)
        title = "Pipeline Report"
    elif report_type == "prd":
        body = render_prd(raw)
        # 제목 추출
        m = re.search(r'^#\s+(.+)', raw, re.MULTILINE)
        title = m.group(1) if m else "PRD"
    elif report_type == "design-review":
        body = render_design_review(raw)
        title = "Design Review"
    else:
        body = render_qa(raw)
        title = "QA Report"

    html = make_html(body, title)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"[gen-html-report] ✅ {out}")

if __name__ == "__main__":
    main()
