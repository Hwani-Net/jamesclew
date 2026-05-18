#!/usr/bin/env python3
"""
gate_cd_check.py — PARTNERS GATE C (PRICE_CONSISTENCY) + D (CATEGORY_MATCH)
P-164 v2 — Called from blog-publish.sh after Gate A/B pass.

Exit codes:
  0 — both gates pass
  2 — one or more gates fail (publishing must be blocked)

Usage:
  python3 gate_cd_check.py <html_or_md_file> <slug>
"""
import re
import sys
import os

def normalize_price(s: str) -> str:
    """Strip commas, spaces, discount annotations → bare integer string."""
    s = re.sub(r'\s*\([^)]*할인[^)]*\)', '', s)   # remove "(23% 할인)" etc.
    s = re.sub(r'[,\s]', '', s)
    return s.strip()

# ─── Gate C: PRICE_CONSISTENCY ───────────────────────────────────────────────

MODEL_RE = re.compile(r'\b([A-Z]{2,}[\-/]?[A-Z0-9]{2,})\b')
PRICE_RE = re.compile(r'(\d{1,3}(?:,\d{3})+)\s*원')
WINDOW = 150  # chars around each model mention to look for price

def gate_c(content: str) -> bool:
    """Return True (PASS) if all same-model price mentions are consistent."""
    model_prices: dict[str, set] = {}
    for m in MODEL_RE.finditer(content):
        model = m.group(1)
        start = max(0, m.start() - WINDOW)
        end   = min(len(content), m.end() + WINDOW)
        snippet = content[start:end]
        prices = PRICE_RE.findall(snippet)
        if prices:
            normalized = {normalize_price(p) for p in prices}
            if model not in model_prices:
                model_prices[model] = normalized
            else:
                model_prices[model] |= normalized

    fail = False
    for model, prices in model_prices.items():
        if len(prices) >= 2:
            print(
                f"[GATE_C FAIL] 모델 '{model}' 가격 불일치: {', '.join(sorted(prices))}원",
                file=sys.stderr,
            )
            fail = True

    if not fail:
        print("[GATE_C PASS] 가격 일관성 검증 통과")
    return not fail


# ─── Gate D: CATEGORY_MATCH ──────────────────────────────────────────────────

# slug/title keyword → (page_keywords, exclude_patterns)
CATEGORY_RULES: list[tuple[list[str], list[str]]] = [
    # dryer
    (['건조기', '의류건조기'], ['세탁기 세트', 'WF24', 'WF20', '세탁건조기', '건조겸용세탁기']),
    # monitor
    (['모니터'], ['CCTV', '블랙박스', '스마트TV', ' TV ']),
    # air-fryer
    (['에어프라이어'], ['큐커', 'MO22', 'MO26', 'MO28', '복합기']),
    # dishwasher (식기세척기 vs 식기건조기 단독)
    (['식기세척기'], ['식기건조기(?!.*세척)'])    ,  # 식기건조기 단독 언급
    # fan / circulator
    (['선풍기', '서큘레이터'], ['캠핑 드라이기', '헤어드라이기', '헤어 드라이기']),
]

COUPANG_LINK_RE = re.compile(r'link\.coupang\.com/a/[^\s"\'<>)]+')
LINK_CONTEXT_WINDOW = 200  # chars before/after link to check


def _slug_category(slug: str) -> tuple[list[str], list[str]] | None:
    for page_kws, excludes in CATEGORY_RULES:
        if any(kw in slug for kw in page_kws):
            return page_kws, excludes
    return None


def gate_d(content: str, slug: str) -> bool:
    """Return True (PASS) if all coupang links are consistent with slug category."""
    rule = _slug_category(slug)
    if rule is None:
        print("[GATE_D SKIP] 슬러그에서 카테고리 규칙 미감지 — 검사 생략")
        return True

    page_kws, excludes = rule

    links = list(COUPANG_LINK_RE.finditer(content))
    if not links:
        print("[GATE_D SKIP] 쿠팡 링크 없음 — Gate D 검사 생략")
        return True

    fail = False
    for m in links:
        start = max(0, m.start() - LINK_CONTEXT_WINDOW)
        end   = min(len(content), m.end() + LINK_CONTEXT_WINDOW)
        snippet = content[start:end]

        for exc_pattern in excludes:
            if re.search(exc_pattern, snippet):
                print(
                    f"[GATE_D FAIL] '{page_kws[0]}' 페이지에 부적합 패턴 감지: "
                    f"'{exc_pattern}' (링크: ...{m.group()[-40:]}...)",
                    file=sys.stderr,
                )
                fail = True
                break

    if not fail:
        print(f"[GATE_D PASS] 카테고리 일치 검증 통과 (슬러그: {slug})")
    return not fail


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 3:
        print("Usage: gate_cd_check.py <file> <slug>", file=sys.stderr)
        sys.exit(1)

    filepath, slug = sys.argv[1], sys.argv[2]

    if not os.path.isfile(filepath):
        print(f"ERROR: file not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    with open(filepath, encoding='utf-8', errors='replace') as f:
        content = f.read()

    pass_c = gate_c(content)
    sys.stdout.flush()
    sys.stderr.flush()
    pass_d = gate_d(content, slug)
    sys.stdout.flush()
    sys.stderr.flush()

    if pass_c and pass_d:
        print("[PARTNERS GATE C+D] PASS — 발행 계속")
        sys.exit(0)
    else:
        print("[PARTNERS GATE C+D] FAIL — 발행 차단", file=sys.stderr)
        sys.exit(2)


if __name__ == '__main__':
    main()
