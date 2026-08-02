#!/usr/bin/env python3
"""token-usage-report.py — 세션별·작업별 토큰 사용량을 1시간 단위로 집계하고 이상치를 탐지한다.

배경
----
Claude Code 세션은 assistant 메시지마다 `message.usage`를 트랜스크립트
(~/.claude/projects/<proj>/<session-id>.jsonl)에 기록한다. 원격 세션 컨테이너는
휘발성이라 세션이 끝나면 트랜스크립트가 사라지므로, Stop hook
(token-usage-tracker.sh)이 시간대별 롤업을 ~/.harness-state/token_usage.jsonl 에
누적하고, 이 스크립트가 그것과 살아있는 트랜스크립트를 함께 읽는다.

입력 (있는 것만 사용)
  1) ~/.claude/projects/*/*.jsonl        현재 컨테이너의 라이브 트랜스크립트
  2) ~/.harness-state/token_usage.jsonl  Stop hook이 남긴 시간대별 롤업
  3) harness/docs/token-usage/*.jsonl    리포에 커밋된 과거 롤업 (컨테이너 사후 생존)

출력
  - 시간대(UTC/KST) × 작업 표
  - 작업별 합계
  - 비정상 사용량 플래그 (중앙값 + 3·MAD, 또는 중앙값의 3배 초과)

사용법
  python3 harness/scripts/token-usage-report.py                 # 마크다운 리포트
  python3 harness/scripts/token-usage-report.py --json          # JSON
  python3 harness/scripts/token-usage-report.py --since 24      # 최근 24시간만
  python3 harness/scripts/token-usage-report.py --emit-ledger   # 롤업 JSONL만 출력
"""

import argparse
import glob
import json
import os
import re
import statistics
import sys
from collections import defaultdict
from datetime import datetime, timedelta, timezone

KST = timezone(timedelta(hours=9))

# 100만 토큰당 USD (input, output). platform.claude.com 기준.
# 캐시 배수는 input 가격 기준: 읽기 0.1x, 5분 쓰기 1.25x, 1시간 쓰기 2.0x.
PRICES = {
    "claude-fable-5":    (10.0, 50.0),
    "claude-mythos-5":   (10.0, 50.0),
    "claude-opus-5":     (5.0, 25.0),
    "claude-opus-4-8":   (5.0, 25.0),
    "claude-opus-4-7":   (5.0, 25.0),
    "claude-opus-4-6":   (5.0, 25.0),
    "claude-opus-4-5":   (5.0, 25.0),
    "claude-sonnet-5":   (3.0, 15.0),
    "claude-sonnet-4-6": (3.0, 15.0),
    "claude-sonnet-4-5": (3.0, 15.0),
    "claude-haiku-4-5":  (1.0, 5.0),
}
DEFAULT_PRICE = (5.0, 25.0)  # 모르는 모델은 Opus 요금으로 보수적 추정

CACHE_READ_MULT = 0.1
CACHE_WRITE_5M_MULT = 1.25
CACHE_WRITE_1H_MULT = 2.0

STATE_DIR = os.path.expanduser("~/.harness-state")
LEDGER = os.path.join(STATE_DIR, "token_usage.jsonl")
REPO_LEDGER_GLOB = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "docs", "token-usage", "*.jsonl",
)
TRANSCRIPT_GLOB = os.path.expanduser("~/.claude/projects/*/*.jsonl")

# 프롬프트 머리표 "[작업: 이름]" → 작업명. 정기 작업 구분용.
TASK_MARKER_RE = re.compile(r"^\[\s*작업\s*[::]\s*([^\]]{1,60})\]")


def price_for(model):
    if not model:
        return DEFAULT_PRICE
    return PRICES.get(model, DEFAULT_PRICE)


def cost_usd(model, inp, cw5, cw1h, cr, out):
    """토큰 구성별 배수를 적용한 USD 추정치."""
    p_in, p_out = price_for(model)
    return (
        inp * p_in
        + cw5 * p_in * CACHE_WRITE_5M_MULT
        + cw1h * p_in * CACHE_WRITE_1H_MULT
        + cr * p_in * CACHE_READ_MULT
        + out * p_out
    ) / 1_000_000


def blank_bucket():
    return {
        "input": 0, "cache_write_5m": 0, "cache_write_1h": 0,
        "cache_read": 0, "output": 0, "calls": 0,
        "models": set(), "cost_usd": 0.0,
    }


def add_usage(bucket, model, usage):
    cc = usage.get("cache_creation") or {}
    cw5 = cc.get("ephemeral_5m_input_tokens", 0)
    cw1h = cc.get("ephemeral_1h_input_tokens", 0)
    if not cw5 and not cw1h:
        # cache_creation 세부가 없으면 합계를 5분 쓰기로 간주
        cw5 = usage.get("cache_creation_input_tokens", 0)
    inp = usage.get("input_tokens", 0)
    cr = usage.get("cache_read_input_tokens", 0)
    out = usage.get("output_tokens", 0)

    bucket["input"] += inp
    bucket["cache_write_5m"] += cw5
    bucket["cache_write_1h"] += cw1h
    bucket["cache_read"] += cr
    bucket["output"] += out
    bucket["calls"] += 1
    # <synthetic>(중단 안내 등 CLI가 만든 가짜 응답)은 usage가 전부 0이라
    # 합계엔 영향이 없지만 모델 목록만 오염시킨다. 토큰을 쓴 모델만 기록한다.
    if model and (inp or cw5 or cw1h or cr or out):
        bucket["models"].add(model)
    bucket["cost_usd"] += cost_usd(model, inp, cw5, cw1h, cr, out)
    return inp + cw5 + cw1h + cr + out


def merge_rollup(bucket, row):
    """Stop hook이 남긴 롤업 행을 버킷에 합친다."""
    for k in ("input", "cache_write_5m", "cache_write_1h", "cache_read", "output", "calls"):
        bucket[k] += row.get(k, 0)
    bucket["cost_usd"] += row.get("cost_usd", 0.0)
    for m in row.get("models", []):
        bucket["models"].add(m)


def scan_transcripts(buckets, labels):
    seen_files = []
    # Claude Code는 API 응답 하나를 content block마다 별도 레코드로 기록하는데,
    # 각 레코드가 같은 usage 객체를 통째로 들고 있다. 레코드를 그대로 세면
    # 블록 수만큼 사용량이 부풀려지므로(실측 161레코드 = 76호출) 응답 단위로 중복 제거한다.
    counted = set()
    for path in sorted(glob.glob(TRANSCRIPT_GLOB)):
        seen_files.append(path)
        for line in open(path, errors="replace"):
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue

            sid = rec.get("sessionId")
            if not sid:
                continue

            # 작업 라벨: 첫 사용자 프롬프트 + 브랜치
            if rec.get("type") == "user" and sid not in labels:
                msg = rec.get("message") or {}
                content = msg.get("content")
                text = ""
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    text = " ".join(
                        b.get("text", "") for b in content
                        if isinstance(b, dict) and b.get("type") == "text"
                    )
                text = " ".join(text.split())
                if text and not text.startswith("<"):
                    # 프롬프트가 "[작업: 이름]"으로 시작하면 그 이름을 작업명으로 쓴다.
                    # 정기 작업(routine)은 프롬프트가 고정이라, 머리표만 붙여두면
                    # 환경변수 없이도 목록에서 항상 같은 이름으로 묶인다.
                    m = TASK_MARKER_RE.match(text)
                    labels[sid] = {
                        "label": m.group(1).strip() if m else text[:70],
                        "branch": rec.get("gitBranch"),
                        "cwd": rec.get("cwd"),
                        "entrypoint": rec.get("entrypoint"),
                    }

            if rec.get("type") != "assistant":
                continue
            msg = rec.get("message") or {}
            usage = msg.get("usage")
            ts = rec.get("timestamp")
            if not usage or not ts:
                continue
            # 한 API 응답당 1회만 계상 (위 counted 주석 참조)
            resp_id = msg.get("id") or rec.get("requestId") or rec.get("uuid")
            if resp_id in counted:
                continue
            counted.add(resp_id)
            hour = ts[:13]  # "YYYY-MM-DDTHH"
            key = (sid, hour)
            if key not in buckets:
                buckets[key] = blank_bucket()
            buckets[key]["sidechain"] = buckets[key].get("sidechain", 0) + (
                1 if rec.get("isSidechain") else 0
            )
            add_usage(buckets[key], msg.get("model"), usage)
            labels.setdefault(sid, {}).setdefault("branch", rec.get("gitBranch"))
    return seen_files


def scan_ledgers(buckets, labels):
    """롤업 원장을 읽어 버킷에 합친다.

    Stop hook은 세션이 멈출 때마다 그 세션의 누적 롤업을 통째로 다시 기록하므로,
    같은 (세션, 시간) 키가 여러 번 등장한다. 누적값이 중복 합산되지 않도록
    rev(기록 시각)가 가장 큰 행 하나만 채택한다. 라이브 트랜스크립트가 이미
    같은 키를 채웠다면 그쪽이 최신이므로 원장 행은 버린다.
    """
    paths = []
    if os.path.exists(LEDGER):
        paths.append(LEDGER)
    paths.extend(sorted(glob.glob(REPO_LEDGER_GLOB)))

    latest = {}  # (sid, hour) -> row (rev 최대)
    for path in paths:
        for line in open(path, errors="replace"):
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            sid, hour = row.get("session_id"), row.get("hour")
            if not sid or not hour:
                continue
            key = (sid, hour)
            prev = latest.get(key)
            if prev is None or row.get("rev", 0) >= prev.get("rev", 0):
                latest[key] = row

    for (sid, hour), row in latest.items():
        # 명시된 작업명(task)은 첫 프롬프트에서 추출한 라벨을 덮는다 —
        # 정기 작업은 목록에서 고정된 이름으로 보여야 구분이 된다.
        if row.get("task"):
            labels.setdefault(sid, {})["label"] = row["task"]
        elif row.get("label"):
            labels.setdefault(sid, {}).setdefault("label", row["label"])
        if row.get("branch"):
            labels.setdefault(sid, {}).setdefault("branch", row["branch"])
        key = (sid, hour)
        if key in buckets:
            continue  # 라이브 트랜스크립트 값이 더 최신
        buckets[key] = blank_bucket()
        merge_rollup(buckets[key], row)

    return paths


def total_tokens(b):
    return b["input"] + b["cache_write_5m"] + b["cache_write_1h"] + b["cache_read"] + b["output"]


def billable_weight(b):
    """가격 배수를 반영한 '유효 토큰'. 이상치 판정 기준."""
    return (
        b["input"]
        + b["cache_write_5m"] * CACHE_WRITE_5M_MULT
        + b["cache_write_1h"] * CACHE_WRITE_1H_MULT
        + b["cache_read"] * CACHE_READ_MULT
        + b["output"] * 5.0
    )


def detect_outliers(values):
    """중앙값 + 3·MAD 또는 중앙값의 3배 초과를 이상치로 본다.

    표본이 3개 미만이면 통계적 판단이 무의미하므로 이상치 없음으로 처리한다.
    """
    if len(values) < 3:
        return None
    med = statistics.median(values)
    mad = statistics.median([abs(v - med) for v in values])
    # MAD가 0이면(값이 대부분 동일) 중앙값 배수 기준만 사용
    mad_thresh = med + 3 * mad if mad > 0 else float("inf")
    ratio_thresh = med * 3 if med > 0 else float("inf")
    return {"median": med, "mad": mad, "threshold": min(mad_thresh, ratio_thresh)}


def fmt_int(n):
    return f"{n:,}"


def kst_label(hour_utc):
    dt = datetime.strptime(hour_utc, "%Y-%m-%dT%H").replace(tzinfo=timezone.utc)
    return dt.astimezone(KST).strftime("%m-%d %H시")


def build(since_hours=None):
    buckets, labels = {}, {}
    files = scan_transcripts(buckets, labels)
    ledgers = scan_ledgers(buckets, labels)

    if since_hours:
        cutoff = (datetime.now(timezone.utc) - timedelta(hours=since_hours)).strftime("%Y-%m-%dT%H")
        buckets = {k: v for k, v in buckets.items() if k[1] >= cutoff}

    rows = []
    for (sid, hour), b in sorted(buckets.items(), key=lambda kv: (kv[0][1], kv[0][0])):
        meta = labels.get(sid, {})
        rows.append({
            "session_id": sid,
            "hour_utc": hour,
            "hour_kst": kst_label(hour),
            "label": meta.get("label") or "(라벨 없음)",
            "branch": meta.get("branch"),
            "models": sorted(b["models"]),
            "calls": b["calls"],
            "subagent_calls": b.get("sidechain", 0),
            "input": b["input"],
            "cache_write_5m": b["cache_write_5m"],
            "cache_write_1h": b["cache_write_1h"],
            "cache_read": b["cache_read"],
            "output": b["output"],
            "total": total_tokens(b),
            "weighted": round(billable_weight(b)),
            "cost_usd": round(b["cost_usd"], 4),
        })

    stats = detect_outliers([r["weighted"] for r in rows])
    for r in rows:
        r["outlier"] = bool(stats and r["weighted"] > stats["threshold"])
        r["vs_median"] = (
            round(r["weighted"] / stats["median"], 1)
            if stats and stats["median"] > 0 else None
        )

    per_task = defaultdict(lambda: {
        "hours": 0, "calls": 0, "total": 0, "weighted": 0, "cost_usd": 0.0,
        "label": "", "branch": None, "models": set(),
    })
    for r in rows:
        t = per_task[r["session_id"]]
        t["hours"] += 1
        t["calls"] += r["calls"]
        t["total"] += r["total"]
        t["weighted"] += r["weighted"]
        t["cost_usd"] += r["cost_usd"]
        t["label"] = t["label"] or r["label"]
        t["branch"] = t["branch"] or r["branch"]
        t["models"].update(r["models"])

    tasks = [
        {"session_id": k, **{kk: (sorted(vv) if isinstance(vv, set) else vv)
                             for kk, vv in v.items()}}
        for k, v in per_task.items()
    ]
    for t in tasks:
        t["cost_usd"] = round(t["cost_usd"], 4)
    tasks.sort(key=lambda t: -t["weighted"])

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "sources": {"transcripts": files, "ledgers": ledgers},
        "hourly": rows,
        "tasks": tasks,
        "outlier_stats": stats,
        "grand_total": {
            "tokens": sum(r["total"] for r in rows),
            "weighted": sum(r["weighted"] for r in rows),
            "cost_usd": round(sum(r["cost_usd"] for r in rows), 4),
        },
    }


def render_markdown(rep):
    out = []
    gt = rep["grand_total"]
    out.append(f"# 토큰 사용량 리포트 (1시간 단위)\n")
    out.append(f"- 생성: {rep['generated_at']}")
    out.append(f"- 총 토큰: {fmt_int(gt['tokens'])} / 가중 토큰: {fmt_int(gt['weighted'])} / 추정 비용: ${gt['cost_usd']}")
    out.append(f"- 데이터 소스: 트랜스크립트 {len(rep['sources']['transcripts'])}개, 롤업 원장 {len(rep['sources']['ledgers'])}개\n")

    if not rep["hourly"]:
        out.append("> 집계할 사용량 기록이 없습니다.\n")
        return "\n".join(out)

    out.append("## 시간대별 (KST)\n")
    out.append("| 시각(KST) | 작업 | 호출 | input | 캐시쓰기 | 캐시읽기 | output | 합계 | 가중 | $ | 이상 |")
    out.append("|---|---|---:|---:|---:|---:|---:|---:|---:|---:|:--:|")
    for r in rep["hourly"]:
        cw = r["cache_write_5m"] + r["cache_write_1h"]
        flag = f"⚠️ ×{r['vs_median']}" if r["outlier"] else ""
        out.append(
            f"| {r['hour_kst']} | {r['label'][:40]} | {r['calls']} | {fmt_int(r['input'])} | "
            f"{fmt_int(cw)} | {fmt_int(r['cache_read'])} | {fmt_int(r['output'])} | "
            f"{fmt_int(r['total'])} | {fmt_int(r['weighted'])} | {r['cost_usd']} | {flag} |"
        )

    out.append("\n## 작업별 합계\n")
    out.append("| 작업 | 브랜치 | 시간 수 | 호출 | 합계 토큰 | 가중 | $ |")
    out.append("|---|---|---:|---:|---:|---:|---:|")
    for t in rep["tasks"]:
        out.append(
            f"| {t['label'][:45]} | {t['branch'] or '-'} | {t['hours']} | {t['calls']} | "
            f"{fmt_int(t['total'])} | {fmt_int(t['weighted'])} | {t['cost_usd']} |"
        )

    out.append("\n## 비정상 사용량\n")
    st = rep["outlier_stats"]
    if not st:
        out.append("> 표본이 3개 미만이라 통계적 이상치 판정을 하지 않았습니다. "
                   "여러 세션이 기록을 남긴 뒤 다시 실행하세요.\n")
    else:
        flagged = [r for r in rep["hourly"] if r["outlier"]]
        out.append(f"판정 기준: 가중 토큰 중앙값 {fmt_int(round(st['median']))}, "
                   f"MAD {fmt_int(round(st['mad']))}, 임계값 {fmt_int(round(st['threshold']))}\n")
        if not flagged:
            out.append("> 임계값을 넘은 시간대 없음.\n")
        else:
            for r in flagged:
                out.append(
                    f"- **{r['hour_kst']}** · {r['label'][:60]}\n"
                    f"  - 가중 {fmt_int(r['weighted'])} (중앙값의 {r['vs_median']}배), "
                    f"호출 {r['calls']}회 (서브에이전트 {r['subagent_calls']}회), "
                    f"추정 ${r['cost_usd']}\n"
                    f"  - 구성: 캐시읽기 {fmt_int(r['cache_read'])} / "
                    f"캐시쓰기 {fmt_int(r['cache_write_5m'] + r['cache_write_1h'])} / "
                    f"output {fmt_int(r['output'])}"
                )
    return "\n".join(out)


def emit_ledger(task=None):
    """현재 라이브 트랜스크립트를 롤업 JSONL로 표준출력에 내보낸다 (Stop hook용).

    task: 작업명. 명시하면 첫 프롬프트에서 추출한 라벨 대신 이 이름을 쓴다.
    정기 작업(routine)은 이름이 고정이라 이걸로 목록에서 구분된다.
    """
    task = task or os.environ.get("HARNESS_TASK") or None
    buckets, labels = {}, {}
    scan_transcripts(buckets, labels)
    rev = int(datetime.now(timezone.utc).timestamp())
    for (sid, hour), b in sorted(buckets.items()):
        meta = labels.get(sid, {})
        print(json.dumps({
            "session_id": sid,
            "hour": hour,
            "rev": rev,
            "task": task,
            "label": task or meta.get("label"),
            "branch": meta.get("branch"),
            "models": sorted(b["models"]),
            "calls": b["calls"],
            "input": b["input"],
            "cache_write_5m": b["cache_write_5m"],
            "cache_write_1h": b["cache_write_1h"],
            "cache_read": b["cache_read"],
            "output": b["output"],
            "cost_usd": round(b["cost_usd"], 6),
        }, ensure_ascii=False))


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--json", action="store_true", help="JSON으로 출력")
    ap.add_argument("--since", type=int, metavar="HOURS", help="최근 N시간만 집계")
    ap.add_argument("--emit-ledger", action="store_true",
                    help="라이브 트랜스크립트를 롤업 JSONL로 출력 (Stop hook용)")
    ap.add_argument("--task", metavar="NAME",
                    help="작업명. 목록에서 이 이름으로 구분된다 (env HARNESS_TASK로도 지정 가능)")
    args = ap.parse_args()

    if args.emit_ledger:
        emit_ledger(task=args.task)
        return

    rep = build(since_hours=args.since)
    if args.json:
        json.dump(rep, sys.stdout, ensure_ascii=False, indent=2, default=str)
        print()
    else:
        print(render_markdown(rep))


if __name__ == "__main__":
    main()
