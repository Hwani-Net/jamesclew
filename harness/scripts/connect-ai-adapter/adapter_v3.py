"""Connect AI <-> copilot-api Adapter v3
Ollama API emulator: /api/tags, /api/chat, /api/generate
copilot-api 4141 (OpenAI 형식)을 Ollama 형식으로 변환하여 Connect AI에게 노출.

v3 변경사항:
- /api/tags: supported_endpoints에 /chat/completions 포함된 모델만 노출
- /api/chat: 미지원 모델 → gpt-4.1 자동 fallback + X-Model-Fallback 헤더
- 화이트리스트: 시작 시 1회 fetch + 5분 TTL 캐시
"""
import http.server, socketserver, urllib.request, json, sys, time, datetime, threading, subprocess, os

UPSTREAM = "http://127.0.0.1:4141"
PORT = 4142
FALLBACK_MODEL = "gpt-4.1"
WHITELIST_TTL = 300  # 5분 캐시

# v4: claude-* 모델은 `claude -p` subprocess로 라우팅 (Anthropic Pro/Max OAuth 풀 활용)
# 환경변수 CLAUDE_VIA_CLI=0 으로 비활성 가능 (default ON)
CLAUDE_VIA_CLI = os.environ.get("CLAUDE_VIA_CLI", "1") == "1"

# claude CLI 모델명 매핑 (copilot-api 형식 → claude CLI 형식)
CLAUDE_CLI_MODEL_MAP = {
    "claude-sonnet-4.6": "claude-sonnet-4-6",
    "claude-sonnet-4.5": "claude-sonnet-4-5",
    "claude-sonnet-4": "claude-sonnet-4-0",
    "claude-haiku-4.5": "claude-haiku-4-5",
    "claude-opus-4.6": "claude-opus-4-6",
    "claude-opus-4.7": "claude-opus-4-7",
}

# v4: claude-cli 전용 노출 모델 (copilot-api 미노출, Anthropic Pro/Max OAuth만 사용 가능)
# /api/tags 응답에 강제 추가하여 Connect AI dropdown에 표시
ANTHROPIC_CLI_EXCLUSIVE = [
    "claude-opus-4.7",
    "claude-opus-4.6",
]


def call_claude_cli(model_id, messages, timeout=180):
    """`claude -p` subprocess로 Anthropic Pro/Max OAuth 풀 호출.
    Returns: (content_text, eval_count_estimate)
    """
    cli_model = CLAUDE_CLI_MODEL_MAP.get(model_id, model_id.replace(".", "-"))
    # messages를 단일 prompt로 평탄화 (system + user/assistant turns)
    prompt_parts = []
    for m in messages:
        role = m.get("role", "user")
        content = m.get("content", "")
        if role == "system":
            prompt_parts.append(f"[SYSTEM]\n{content}")
        elif role == "assistant":
            prompt_parts.append(f"[ASSISTANT]\n{content}")
        else:
            prompt_parts.append(f"[USER]\n{content}")
    prompt = "\n\n".join(prompt_parts)
    try:
        result = subprocess.run(
            f'claude -p --model {cli_model} --output-format text',
            input=prompt, capture_output=True, text=True, encoding="utf-8",
            timeout=timeout, shell=True,
        )
        if result.returncode != 0:
            err = (result.stderr or "")[:500]
            raise RuntimeError(f"claude CLI exit={result.returncode}: {err}")
        out = result.stdout or ""
        # eval token 추정 (대략 4자/토큰)
        return out.strip(), max(1, len(out) // 4)
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"claude CLI timeout after {timeout}s")

# 화이트리스트 캐시 (thread-safe)
_whitelist_lock = threading.Lock()
_whitelist = set()
_whitelist_fetched_at = 0.0


def fetch_whitelist():
    """supported_endpoints에 /chat/completions 포함된 모델 ID 집합 반환"""
    try:
        req = urllib.request.Request(UPSTREAM + "/v1/models")
        req.add_header("Content-Type", "application/json")
        with urllib.request.urlopen(req, timeout=15) as r:
            data = json.loads(r.read())
        result = set()
        for m in data.get("data", []):
            endpoints = m.get("supported_endpoints", [])
            if "/chat/completions" in endpoints:
                result.add(m.get("id"))
        sys.stderr.write(f"[{time.strftime('%H:%M:%S')}] whitelist fetched: {sorted(result)}\n")
        return result
    except Exception as e:
        sys.stderr.write(f"[{time.strftime('%H:%M:%S')}] whitelist fetch error: {e}\n")
        return set()


def get_whitelist():
    """캐시된 화이트리스트 반환 (TTL 만료 시 재fetch)"""
    global _whitelist, _whitelist_fetched_at
    now = time.time()
    with _whitelist_lock:
        if now - _whitelist_fetched_at > WHITELIST_TTL or not _whitelist:
            _whitelist = fetch_whitelist()
            _whitelist_fetched_at = now
        return set(_whitelist)


def resolve_model(requested_model):
    """화이트리스트에 없으면 fallback. claude-cli 전용 모델은 그대로 통과."""
    wl = get_whitelist()
    if requested_model in wl:
        return requested_model, None
    # claude-cli 전용 모델 (Opus 등)은 화이트리스트와 무관하게 통과
    if CLAUDE_VIA_CLI and requested_model in ANTHROPIC_CLI_EXCLUSIVE:
        return requested_model, None
    return FALLBACK_MODEL, requested_model


def http_call(method, path, body=None, headers=None, timeout=120):
    req = urllib.request.Request(UPSTREAM + path, data=body, method=method)
    req.add_header("Content-Type", "application/json")
    if headers:
        for k, v in headers.items():
            if k.lower() not in ("host", "content-length", "content-type", "accept-encoding"):
                req.add_header(k, v)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.status, r.read(), dict(r.headers)


class Adapter(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write(f"[{time.strftime('%H:%M:%S')}] {self.command} {self.path} {fmt % args}\n")

    def _send_json(self, status, obj, extra_headers=None):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        if extra_headers:
            for k, v in extra_headers.items():
                self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        # Ollama: /api/tags → chat/completions 지원 모델만 노출
        if self.path == "/api/tags":
            try:
                status, body, _ = http_call("GET", "/v1/models")
                upstream = json.loads(body)
                wl = get_whitelist()
                now = datetime.datetime.now(datetime.timezone.utc).isoformat()
                ollama_models = []
                exposed = set()
                for m in upstream.get("data", []):
                    mid = m.get("id")
                    if mid not in wl:
                        continue
                    exposed.add(mid)
                    ollama_models.append({
                        "name": mid, "model": mid, "modified_at": now, "size": 1,
                        "digest": "sha256:" + (mid or "").ljust(64, "0")[:64],
                        "details": {"parent_model": "", "format": "gguf",
                                    "family": "openai", "families": ["openai"],
                                    "parameter_size": "?", "quantization_level": "F16"},
                    })
                # Anthropic CLI 전용 모델 (copilot-api 미노출) 강제 추가
                if CLAUDE_VIA_CLI:
                    for mid in ANTHROPIC_CLI_EXCLUSIVE:
                        if mid in exposed:
                            continue
                        ollama_models.append({
                            "name": mid, "model": mid, "modified_at": now, "size": 1,
                            "digest": "sha256:" + mid.ljust(64, "0")[:64],
                            "details": {"parent_model": "", "format": "gguf",
                                        "family": "anthropic", "families": ["anthropic"],
                                        "parameter_size": "?", "quantization_level": "F16"},
                        })
                self._send_json(200, {"models": ollama_models})
            except Exception as e:
                self._send_json(502, {"error": f"tags upstream: {e}"})
            return

        # OpenAI passthrough
        if self.path.startswith("/v1/"):
            try:
                status, body, hdrs = http_call("GET", self.path)
                self.send_response(status)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(body)
            except Exception as e:
                self._send_json(502, {"error": str(e)})
            return

        self._send_json(404, {"error": "not found"})

    def do_POST(self):
        n = int(self.headers.get("content-length", "0"))
        raw = self.rfile.read(n) if n else b""
        try:
            inbody = json.loads(raw) if raw else {}
        except Exception:
            inbody = {}

        # Ollama /api/chat 또는 /api/generate → OpenAI /v1/chat/completions 변환
        if self.path in ("/api/chat", "/api/generate"):
            if self.path == "/api/generate":
                msgs = [{"role": "user", "content": inbody.get("prompt", "")}]
            else:
                msgs = inbody.get("messages", [])

            requested_model = inbody.get("model", FALLBACK_MODEL)
            resolved_model, fallback_from = resolve_model(requested_model)

            openai_req = {
                "model": resolved_model,
                "messages": msgs,
                "temperature": (inbody.get("options") or {}).get("temperature", 0.7),
                "stream": bool(inbody.get("stream", False)),
            }
            num_predict = (inbody.get("options") or {}).get("num_predict")
            if num_predict:
                openai_req["max_tokens"] = num_predict

            # fallback 로그
            if fallback_from:
                sys.stderr.write(
                    f"[{time.strftime('%H:%M:%S')}] model fallback: {fallback_from} -> {resolved_model}\n"
                )

            try:
                stream_requested = bool(openai_req["stream"])
                openai_req["stream"] = False  # upstream은 항상 non-stream
                use_cli = CLAUDE_VIA_CLI and resolved_model.startswith("claude-")
                route = "claude-cli" if use_cli else "copilot-api"
                sys.stderr.write(f"[DEBUG] msgs_n={len(msgs)} model={resolved_model} stream={stream_requested} route={route}\n")
                t0 = time.time()

                if use_cli:
                    # Anthropic Pro/Max OAuth 풀 (claude -p subprocess)
                    content, eval_tok_est = call_claude_cli(resolved_model, msgs)
                    elapsed_ms = int((time.time() - t0) * 1000)
                    finish = "stop"
                    prompt_tok = sum(len(m.get("content", "")) for m in msgs) // 4
                    eval_tok = eval_tok_est
                    resp = None  # CLI 경로 — usage 정확값 없음
                    sys.stderr.write(f"[DEBUG] claude-cli {elapsed_ms}ms {len(content)}chars\n")
                else:
                    status, body, _ = http_call(
                        "POST",
                        "/v1/chat/completions",
                        body=json.dumps(openai_req).encode("utf-8"),
                        headers=dict(self.headers),
                        timeout=180,
                    )
                    elapsed_ms = int((time.time() - t0) * 1000)
                    resp = json.loads(body)
                    content = resp["choices"][0]["message"]["content"]
                    finish = resp["choices"][0].get("finish_reason", "stop")
                    prompt_tok = resp.get("usage", {}).get("prompt_tokens", 0)
                    eval_tok = resp.get("usage", {}).get("completion_tokens", 0)
                now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()

                if stream_requested:
                    # Ollama NDJSON 스트리밍 (2-청크: content + done 마커)
                    self.send_response(200)
                    self.send_header("Content-Type", "application/x-ndjson")
                    if fallback_from:
                        self.send_header("X-Model-Fallback", f"{fallback_from}->{resolved_model}")
                    self.end_headers()
                    chunk1 = {"model": resolved_model, "created_at": now_iso, "done": False}
                    if self.path == "/api/chat":
                        chunk1["message"] = {"role": "assistant", "content": content}
                    else:
                        chunk1["response"] = content
                    self.wfile.write((json.dumps(chunk1) + "\n").encode("utf-8"))
                    chunk2 = {
                        "model": resolved_model, "created_at": now_iso,
                        "done": True, "done_reason": finish,
                        "total_duration": elapsed_ms * 1_000_000, "load_duration": 0,
                        "prompt_eval_count": prompt_tok, "eval_count": eval_tok,
                        "eval_duration": 1,
                    }
                    if self.path == "/api/chat":
                        chunk2["message"] = {"role": "assistant", "content": ""}
                    else:
                        chunk2["response"] = ""
                    self.wfile.write((json.dumps(chunk2) + "\n").encode("utf-8"))
                    sys.stderr.write(f"[DEBUG] streamed 2 chunks ({len(content)} chars) in {elapsed_ms}ms\n")
                    return

                ollama_resp = {
                    "model": resolved_model, "created_at": now_iso,
                    "done": True, "done_reason": finish,
                    "total_duration": elapsed_ms * 1_000_000, "load_duration": 0,
                    "prompt_eval_count": prompt_tok, "eval_count": eval_tok,
                    "eval_duration": 1,
                }
                if self.path == "/api/chat":
                    ollama_resp["message"] = {"role": "assistant", "content": content}
                else:
                    ollama_resp["response"] = content
                extra = {}
                if fallback_from:
                    extra["X-Model-Fallback"] = f"{fallback_from}->{resolved_model}"
                self._send_json(200, ollama_resp, extra_headers=extra or None)
            except urllib.error.HTTPError as e:
                self._send_json(e.code, {"error": e.read().decode("utf-8", "replace")[:500]})
            except Exception as e:
                self._send_json(502, {"error": f"chat upstream: {e}"})
            return

        # OpenAI passthrough (/v1/chat/completions 등)
        if self.path.startswith("/v1/") or self.path == "/chat/completions":
            target = self.path if self.path.startswith("/v1/") else "/v1" + self.path
            try:
                status, body, _ = http_call("POST", target, body=raw, headers=dict(self.headers), timeout=180)
                self.send_response(status)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(body)
            except Exception as e:
                self._send_json(502, {"error": str(e)})
            return

        self._send_json(404, {"error": "not found"})


if __name__ == "__main__":
    # 시작 시 화이트리스트 1회 pre-fetch
    sys.stderr.write(f"[adapter v3] pre-fetching model whitelist...\n")
    initial_wl = fetch_whitelist()
    with _whitelist_lock:
        _whitelist = initial_wl
        _whitelist_fetched_at = time.time()
    sys.stderr.write(f"[adapter v3] {len(initial_wl)} chat-completions-capable models loaded\n")

    socketserver.ThreadingTCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer(("127.0.0.1", PORT), Adapter) as srv:
        print(f"[adapter v3] listening on http://127.0.0.1:{PORT} -> {UPSTREAM}", flush=True)
        srv.serve_forever()
