#!/usr/bin/env python3
"""
11개 MultiBlog 페이지에 schema.org Product + Article JSON-LD 일괄 삽입
"""
import json
import re
import sys
from pathlib import Path

BASE = Path("D:/jamesclew/MultiBlog/public")
BASE_URL = "https://multi-blog-personal.web.app"

# 쿠팡 파트너스 ID 코드 → 전체 URL 변환
def coupang_url(source: str) -> str:
    # "쿠팡 파트너스 dXXXXX" 또는 "쿠팡 파트너스 추출 dXXXXX" 패턴
    m = re.search(r'(d[A-Za-z0-9]+)$', source.strip())
    if m:
        return f"https://link.coupang.com/a/{m.group(1)}"
    return ""

# 가격 문자열에서 숫자만 추출
def parse_price(claim: str) -> str:
    m = re.search(r'[\d,]+원', claim)
    if m:
        return m.group(0).replace(',', '').replace('원', '')
    return ""

# 제품명 추출 (claim 앞부분)
def parse_name(claim: str) -> str:
    # "제품명 XXXXX원" 패턴
    m = re.match(r'^(.+?)\s+[\d,]+원', claim)
    if m:
        return m.group(1).strip()
    return claim.strip()

# ============================================================
# 페이지별 데이터 정의
# ============================================================

PAGES = {
    "fan-circulator-2026-05-07": {
        "title": "2026 선풍기 추천 비교 서큘레이터",
        "date": "2026-05-07",
        "products": [
            {"name": "샤오미 BPLDS03DM BLDC 선풍기", "price": "129700", "image": "xiaomi-fan2pro.jpg", "url": ""},
            {"name": "신일 SIF-D14BN BLDC 선풍기", "price": "72000", "image": "sinil-d14bn.jpg", "url": ""},
            {"name": "신일 SIF-E14AT BLDC 선풍기", "price": "68230", "image": "sinil-sif-e14at.jpg", "url": "https://link.coupang.com/a/vp/products/8329723109"},
            {"name": "한일 BBF-BL12W BLDC 써큘레이터", "price": "99000", "image": "hanil-bbf-bl12w.jpg", "url": "https://link.coupang.com/a/vp/products/9517539287"},
            {"name": "보국 제로팬 BKF-21W30DC", "price": "104400", "image": "boguk-zerofan.jpg", "url": ""},
        ],
    },
    "budget-27inch-monitor-2026-05-07": {
        "title": "2026 가성비 모니터 추천 27인치 비교",
        "date": "2026-05-07",
        "products": [
            {"name": "한성컴퓨터 TFG27F14P2", "price": "139000", "image": "한성컴퓨터-tfg27f14p2.jpg", "url": "https://link.coupang.com/a/dQUWoIrnK8"},
            {"name": "LG 27GS50F", "price": "362560", "image": "lg-27gs50f.jpg", "url": "https://link.coupang.com/a/dQUZJTUJ4K"},
            {"name": "삼성 S27AG300", "price": "350000", "image": "삼성-s27ag300.jpg", "url": "https://link.coupang.com/a/dQU0vmljX2"},
            {"name": "알파스캔 AOC Q27G4/D", "price": "469000", "image": "알파스캔-aoc-q27g4-d.jpg", "url": "https://link.coupang.com/a/dQU1f3lx1w"},
        ],
    },
    "cordless-vacuum-single-2026-05-07": {
        "title": "2026 무선청소기 추천 비교 1인가구 TOP5",
        "date": "2026-05-07",
        "products": [
            {"name": "디베아 ALLNEW22000+", "price": "279000", "image": "디베아-allnew22000.jpg", "url": "https://link.coupang.com/a/dQU10jOLfM"},
            {"name": "샤오미 G10", "price": "500000", "image": "샤오미-g10.jpg", "url": "https://link.coupang.com/a/dQU3ckiwSG"},
            {"name": "LG AX920BWE 코드제로", "price": "1549000", "image": "lg-ax920bwe.jpg", "url": "https://link.coupang.com/a/dQU3WzVZIG"},
            {"name": "삼성 VS20B956", "price": "794990", "image": "삼성-vs20b956.jpg", "url": "https://link.coupang.com/a/dQU4Hgd2ei"},
            {"name": "다이슨 V12 Detect Slim Complete", "price": "829000", "image": "다이슨-v12-detect-slim-complete.jpg", "url": "https://link.coupang.com/a/dQU5rkuSjc"},
        ],
    },
    "fan-vs-circulator-2026-05-07": {
        "title": "선풍기 vs 서큘레이터 비교 추천 2026",
        "date": "2026-05-07",
        "products": [
            {"name": "보국전자 에어젯 BLDC 서큘레이터", "price": "109000", "image": "보국전자-에어젯-bldc-서큘레이터.jpg", "url": "https://link.coupang.com/a/dQU6br05v2"},
            {"name": "신일 SIF-SE10SC", "price": "210000", "image": "신일-sif-se10sc.jpg", "url": "https://link.coupang.com/a/dQU7nVtq68"},
            {"name": "파세코 PDF-MT9120W", "price": "159000", "image": "파세코-pdf-mt9120w.jpg", "url": "https://link.coupang.com/a/dQU9tDShs4"},
            {"name": "보네이도 6303DC", "price": "287800", "image": "보네이도-6303dc.jpg", "url": "https://link.coupang.com/a/dQVa78bXIO"},
            {"name": "다이슨 AM07", "price": "399000", "image": "다이슨-am07.jpg", "url": "https://link.coupang.com/a/dQVbSqEmRw"},
        ],
    },
    "dishwasher-compact-builtin-2026-05-07": {
        "title": "식기세척기 추천 소형 빌트인 2026",
        "date": "2026-05-07",
        "products": [
            {"name": "매직쉐프 MEDW-B06B", "price": "561300", "image": "매직쉐프-medw-b06b.jpg", "url": "https://link.coupang.com/a/dQVdYbtE6e"},
            {"name": "쉐프본 WQP6-8404Y1", "price": "1000000", "image": "쉐프본-wqp6-8404y1.jpg", "url": "https://link.coupang.com/a/dQVf31n07E"},
            {"name": "마이디어 MDWEF1235G", "price": "839800", "image": "마이디어-mdwef1235g.jpg", "url": "https://link.coupang.com/a/dQVgOihOLI"},
            {"name": "쿠쿠 CDW-BS1420BGIE", "price": "410980", "image": "쿠쿠-cdw-bs1420bgie.jpg", "url": "https://link.coupang.com/a/dQViUaUdNY"},
            {"name": "LG 디오스 오브제 식기세척기 12인용", "price": "838000", "image": "lg-디오스-오브제-12인용.jpg", "url": "https://link.coupang.com/a/dQVjEPvIw8"},
        ],
    },
    "airfryer-large-oven-2026-05-07": {
        "title": "에어프라이어 추천 대용량 오븐겸용 2026",
        "date": "2026-05-07",
        "products": [
            {"name": "필립스 HD9285", "price": "795900", "image": "필립스-hd9285.jpg", "url": "https://link.coupang.com/a/dQVkose5ym"},
            {"name": "쿠쿠 CAF-G1610TBL", "price": "69820", "image": "쿠쿠-caf-g1610tbl.jpg", "url": "https://link.coupang.com/a/dQVmuACp1U"},
            {"name": "닌자 AF161", "price": "392000", "image": "닌자-af161.jpg", "url": "https://link.coupang.com/a/dQVnfpz5hI"},
            {"name": "삼성 NQ50T8539BS 오븐", "price": "597000", "image": "삼성-nq50t8539bs.jpg", "url": "https://link.coupang.com/a/dQVnYKzIoC"},
            {"name": "한일 HAF-K70 에어프라이어", "price": "159000", "image": "한일-haf-k70.jpg", "url": "https://link.coupang.com/a/dQVp4HrheK"},
        ],
    },
    "dryer-heatpump-2026-05-07": {
        "title": "의류건조기 추천 비교 히트펌프 2026",
        "date": "2026-05-07",
        "products": [
            {"name": "위닉스 텀블 8kg 건조기", "price": "300240", "image": "위닉스-텀블-8kg.jpg", "url": "https://link.coupang.com/a/dQVzWwHft6"},
            {"name": "삼성 비스포크 그랑데 AI 17kg", "price": "3058000", "image": "삼성-비스포크-그랑데-ai-17kg.jpg", "url": "https://link.coupang.com/a/dQVAG61Igo"},
            {"name": "LG 트롬 오브제 19kg 건조기", "price": "2074820", "image": "lg-트롬-오브제-19kg.jpg", "url": "https://link.coupang.com/a/dQVBq1lLDU"},
            {"name": "LG 트롬 오브제 21kg 건조기", "price": "2322930", "image": "lg-트롬-오브제-21kg.jpg", "url": "https://link.coupang.com/a/dQVCbc8MWO"},
        ],
    },
    "rice-cooker-ih-6p-2026-05-07": {
        "title": "2026 전기밥솥 추천 비교 IH 6인용",
        "date": "2026-05-07",
        "products": [
            {"name": "쿠쿠 CRP-LHTR0610FW IH 전기밥솥", "price": "499000", "image": "쿠쿠-crp-lhtr0610fw.jpg", "url": "https://link.coupang.com/a/dQVC2JnBu0"},
            {"name": "쿠첸 CRT-RPK0670W", "price": "435600", "image": "쿠첸-crt-rpk0670w.jpg", "url": "https://link.coupang.com/a/dQVD7KHuDs"},
            {"name": "쿠쿠 CRP-JHR0609F", "price": "579100", "image": "쿠쿠-crp-jhr0609f.jpg", "url": "https://link.coupang.com/a/dQVGxphqsm"},
            {"name": "쿠첸 CRH-TWK0640W", "price": "319000", "image": "쿠첸-crh-twk0640w.jpg", "url": "https://link.coupang.com/a/dQVHBRgTkb"},
            {"name": "쿠첸 LJP-SB066F", "price": "519000", "image": "쿠첸-ljp-sb066f.jpg", "url": "https://link.coupang.com/a/dQVJ0uPSgK"},
        ],
    },
    "dehumidifier-compact-2026-05-07": {
        "title": "2026 제습기 추천 비교 소형 중형",
        "date": "2026-05-07",
        "products": [
            {"name": "위닉스 뽀송 12L 제습기", "price": "254000", "image": "위닉스-뽀송-12l.jpg", "url": "https://link.coupang.com/a/dQVK5Hd7tI"},
            {"name": "LG 휘센 인버터 13L 제습기", "price": "520000", "image": "lg-휘센-인버터-13l.jpg", "url": "https://link.coupang.com/a/dQVL9f8Xpk"},
            {"name": "위닉스 뽀송 인버터 16L", "price": "579000", "image": "위닉스-뽀송-인버터-16l.jpg", "url": "https://link.coupang.com/a/dQVNeuvznE"},
            {"name": "위닉스 DN2H160-IWK 제습기", "price": "399000", "image": "위닉스-dn2h160-iwk.jpg", "url": "https://link.coupang.com/a/dQVOJEUCmy"},
            {"name": "캐리어 20L 제습기", "price": "247000", "image": "캐리어-캐리어-20l-제습기.jpg", "url": "https://link.coupang.com/a/dQVPNhFFYq"},
        ],
    },
    "home-icemaker-2026-05-18": {
        "title": "가정용 아이스메이커 추천 2026",
        "date": "2026-05-18",
        "products": [
            {"name": "큐빙 사각얼음 제빙기 물탱크급수 가정용", "price": "187900", "image": "cubing-icemaker.jpg", "url": "https://link.coupang.com/a/dQ9jYxN5fU"},
            {"name": "에어셀 아이스 2026 프리미엄 너겟형", "price": "369000", "image": "aircel-icemaker.jpg", "url": "https://link.coupang.com/a/dQ9kIP7Syi"},
            {"name": "가정용 미니 제빙기 9구 12kg", "price": "173990", "image": "mini-9hole-icemaker.jpg", "url": "https://link.coupang.com/a/dQ9lsVXj7Q"},
            {"name": "블랙앤데커 급속 제빙기 BXEM1260-A", "price": "129000", "image": "blackdecker-icemaker.jpg", "url": "https://link.coupang.com/a/dQ9mc5K9wi"},
            {"name": "쿠참 올스텐 자동세척 가정용 17kg", "price": "299000", "image": "kucham-icemaker.jpg", "url": "https://link.coupang.com/a/dQ9mXBQiT6"},
        ],
    },
    "mini-fan-portable-2026-05-19": {
        "title": "휴대용 미니 선풍기 추천 2026 — 목걸이·핸디·BLDC 5가지 완전 비교",
        "date": "2026-05-19",
        "products": [
            {"name": "블루아이디 무선 넥밴드 휴대용 목 선풍기 140g", "price": "29800", "image": "bluid-neck.jpg", "url": "https://link.coupang.com/a/dRc89qgH7c"},
            {"name": "PERFFIER 가성비 급속 냉각 휴대용 미니 손선풍기", "price": "21800", "image": "perffier-handy.jpg", "url": "https://link.coupang.com/a/dRc9UeF0fY"},
            {"name": "무쿠 BLDC 초소형 3단 미니 손 휴대용 선풍기", "price": "9900", "image": "mukoo-bldc.jpg", "url": "https://link.coupang.com/a/dRdaECOnZY"},
            {"name": "맨큐 초미니 휴대용 선풍기 무선 손선풍기 대용량", "price": "9900", "image": "mankiw-handy.jpg", "url": "https://link.coupang.com/a/dRdbpho3z2"},
            {"name": "오아 아이스볼트맥스 100단 미니 급속 냉각 핸디 휴대용", "price": "29800", "image": "oa-icebolt.png", "url": "https://link.coupang.com/a/dRdcabK6i4"},
        ],
    },
}


def build_jsonld(slug: str, data: dict) -> str:
    title = data["title"]
    date = data["date"]
    products = data["products"]
    slug_url = f"{BASE_URL}/{slug}/"

    # ItemList + Product
    item_list_elements = []
    for i, p in enumerate(products, 1):
        img_url = f"{BASE_URL}/{slug}/images/{p['image']}"
        offer = {
            "@type": "Offer",
            "price": p["price"],
            "priceCurrency": "KRW",
            "availability": "https://schema.org/InStock",
        }
        if p.get("url"):
            offer["url"] = p["url"]

        item_list_elements.append({
            "@type": "ListItem",
            "position": i,
            "item": {
                "@type": "Product",
                "name": p["name"],
                "image": img_url,
                "offers": offer,
            },
        })

    itemlist_schema = {
        "@context": "https://schema.org",
        "@type": "ItemList",
        "name": title,
        "url": slug_url,
        "itemListElement": item_list_elements,
    }

    # Article
    article_schema = {
        "@context": "https://schema.org",
        "@type": "Article",
        "headline": title,
        "datePublished": date,
        "dateModified": date,
        "url": slug_url,
        "author": {"@type": "Organization", "name": "스마트리뷰"},
        "publisher": {
            "@type": "Organization",
            "name": "스마트리뷰",
            "url": BASE_URL,
        },
    }

    il_json = json.dumps(itemlist_schema, ensure_ascii=False, indent=2)
    ar_json = json.dumps(article_schema, ensure_ascii=False, indent=2)

    return (
        f'<script type="application/ld+json">\n{il_json}\n</script>\n'
        f'    <script type="application/ld+json">\n{ar_json}\n</script>'
    )


def inject(slug: str, data: dict):
    html_path = BASE / slug / "index.html"
    if not html_path.exists():
        print(f"  [SKIP] {slug} — index.html 없음")
        return 0

    content = html_path.read_text(encoding="utf-8")

    # 이미 삽입된 경우 skip
    if 'application/ld+json' in content:
        print(f"  [SKIP] {slug} — 이미 JSON-LD 존재")
        return 0

    jsonld_block = build_jsonld(slug, data)

    # </head> 직전에 삽입
    new_content = content.replace("  </head>", f"    {jsonld_block}\n  </head>", 1)
    if new_content == content:
        # 공백 없는 케이스 fallback
        new_content = content.replace("</head>", f"    {jsonld_block}\n</head>", 1)

    if new_content == content:
        print(f"  [FAIL] {slug} — </head> 패턴 미발견")
        return 0

    html_path.write_text(new_content, encoding="utf-8")
    product_count = len(data["products"])
    print(f"  [OK]   {slug} — 제품 {product_count}개 JSON-LD 삽입")
    return product_count


def main():
    total_products = 0
    total_pages = 0
    for slug, data in PAGES.items():
        n = inject(slug, data)
        if n > 0:
            total_products += n
            total_pages += 1
    print(f"\n완료: {total_pages}개 페이지, 제품 합계 {total_products}개")


if __name__ == "__main__":
    main()
