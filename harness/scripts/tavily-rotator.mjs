/**
 * Tavily MCP Key Rotator
 * - Wraps the original tavily-mcp with automatic API key rotation
 * - Rotates on 401/402/403/429/432 (usage_limit/auth/payment) and "usage limit" body match
 * - Persists current key index across MCP server restarts (P-152)
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync, renameSync } from "fs";
import { pathToFileURL } from "url";
import { resolve, dirname } from "path";
import { execSync } from "child_process";
import { createRequire } from "module";

const HOME = process.env.HOME || process.env.USERPROFILE;
const KEYS_FILE = process.env.TAVILY_KEYS_FILE || resolve(HOME, ".claude/tavily-keys.json");
const STATE_FILE = process.env.TAVILY_STATE_FILE || resolve(HOME, ".harness-state/tavily-rotation-index.json");

// Auto-detect tavily-mcp install path (cross-platform)
let TAVILY_MCP = process.env.TAVILY_MCP_PATH;
if (!TAVILY_MCP) {
  try {
    const npmRoot = execSync("npm root -g", { encoding: "utf-8" }).trim();
    TAVILY_MCP = resolve(npmRoot, "tavily-mcp/build/index.js");
  } catch {
    throw new Error("tavily-mcp not found. Run: npm install -g tavily-mcp");
  }
}

const keys = JSON.parse(readFileSync(KEYS_FILE, "utf-8"));
const log = (msg) => process.stderr.write(`[tavily-rotator] ${msg}\n`);

// Persistent rotation state (survives MCP server restarts)
const ROTATE_STATUSES = new Set([401, 402, 403, 429, 432]);

function loadIndex() {
  try {
    if (!existsSync(STATE_FILE)) return 0;
    const d = JSON.parse(readFileSync(STATE_FILE, "utf-8"));
    const idx = Number(d.currentKeyIndex);
    if (Number.isInteger(idx) && idx >= 0 && idx < keys.length) return idx;
    log(`state file has invalid index (${d.currentKeyIndex}), starting at #1`);
    return 0;
  } catch (e) {
    // Corrupt/unreadable state file. Log but do not throw — a fresh start at #1 is safe;
    // the next rotation will overwrite the state file with a valid value.
    console.error(`[tavily-rotator] state load error: ${e.message}`);
    return 0;
  }
}

function saveIndex(idx) {
  try {
    const stateDir = dirname(STATE_FILE);
    if (!existsSync(stateDir)) mkdirSync(stateDir, { recursive: true });
    // Atomic write: tmp file + rename so a concurrent reader never sees a partial file,
    // and concurrent writers can't interleave bytes. process.pid disambiguates parallel
    // MCP-rotator instances (Codex review 2026-05-15).
    const tmp = `${STATE_FILE}.${process.pid}.tmp`;
    writeFileSync(tmp, JSON.stringify({
      currentKeyIndex: idx,
      updatedAt: new Date().toISOString(),
      keyCount: keys.length,
    }, null, 2));
    renameSync(tmp, STATE_FILE);
  } catch (e) {
    // Disk full or perms revoked — surface to stderr so an alerting hook can pick it up.
    // We intentionally do not throw: rotation must continue even if persistence fails;
    // the next process restart will simply lose the index (degrades to old behavior).
    console.error(`[tavily-rotator] state save error (rotation will not persist): ${e.message}`);
  }
}

let currentKeyIndex = loadIndex();
log(`Loaded ${keys.length} API keys (resume at #${currentKeyIndex + 1})`);

// Monkey-patch fetch to intercept Tavily API calls
const originalFetch = globalThis.fetch;

globalThis.fetch = async function (url, options = {}) {
  const urlStr = String(url);

  // Pass through non-Tavily requests
  if (!urlStr.includes("tavily.com")) {
    return originalFetch(url, options);
  }

  for (let attempt = 0; attempt < keys.length; attempt++) {
    const key = keys[currentKeyIndex];

    // Replace api_key in POST body
    let opts = { ...options };
    if (opts.body) {
      try {
        const body = JSON.parse(opts.body);
        if ("api_key" in body) {
          body.api_key = key;
          opts.body = JSON.stringify(body);
        }
      } catch (e) {
        // Body is not JSON (e.g. URLSearchParams) — that's expected for some Tavily endpoints.
        // Header-based auth still applies via the Authorization header set below.
        console.error(`[tavily-rotator] body parse skipped (non-JSON): ${e.message}`);
      }
    }

    // Also set auth headers
    opts.headers = {
      ...(opts.headers || {}),
      Authorization: `Bearer ${key}`,
    };

    const res = await originalFetch(url, opts);

    // Rotate on known limit/auth status codes (P-057, P-152)
    if (ROTATE_STATUSES.has(res.status)) {
      const prev = currentKeyIndex + 1;
      currentKeyIndex = (currentKeyIndex + 1) % keys.length;
      saveIndex(currentKeyIndex);
      log(`Key #${prev} exhausted (HTTP ${res.status}), rotating to #${currentKeyIndex + 1}`);
      continue;
    }

    // Some plans return 200 with usage-limit message in body — peek via clone, never consume original
    if (res.status === 200) {
      const clone = res.clone();
      try {
        const txt = await clone.text();
        if (/usage[_ ]?limit|exceeds your plan|quota.*exceeded/i.test(txt)) {
          const prev = currentKeyIndex + 1;
          currentKeyIndex = (currentKeyIndex + 1) % keys.length;
          saveIndex(currentKeyIndex);
          log(`Key #${prev} usage_limit in body, rotating to #${currentKeyIndex + 1}`);
          continue;
        }
      } catch (e) {
        // Clone read failed — surface the error but still return the original response so
        // the upstream tavily-mcp call doesn't silently break.
        console.error(`[tavily-rotator] body peek failed (returning original response): ${e.message}`);
      }
    }

    return res;
  }

  log("All keys exhausted!");
  return originalFetch(url, options);
};

// Set initial env key
process.env.TAVILY_API_KEY = keys[currentKeyIndex];

// P-152 fix #4 (2026-05-15): tavily-mcp uses axios, which bypasses globalThis.fetch
// monkey-patch. Previous attempts to grab axios via createRequire (fix #2) and ESM
// dynamic import (fix #3) both hit Node's ESM/CJS dual-package-hazard — our patched
// axios sat in a different module cache than the one tavily-mcp's `import axios from
// "axios"` resolved to.
//
// Real fix: tavily-mcp/build/index.js was patched (harness/scripts/patch-tavily-mcp.sh)
// to do `globalThis.__TAVILY_MCP_AXIOS__ = axios;` right after its import. We define a
// setter on globalThis so the moment tavily-mcp sets that property, our setter fires
// and patches the *exact* axios instance tavily-mcp will use — no matter when its
// axios.create() calls happen (module load, constructor, or per-request).
{
  // Build the fetch-based adapter once — it reuses our monkey-patched globalThis.fetch,
  // which already runs the rotation loop above.
  const fetchAdapter = async function (config) {
    const baseURL = config.baseURL || "";
    const url = baseURL && !/^https?:/i.test(config.url || "")
      ? new URL(config.url, baseURL).href
      : config.url;

    const method = String(config.method || "GET").toUpperCase();
    const headers = { ...(config.headers || {}) };
    if (headers.common) { Object.assign(headers, headers.common); delete headers.common; }
    if (headers[method.toLowerCase()]) { Object.assign(headers, headers[method.toLowerCase()]); delete headers[method.toLowerCase()]; }

    let body;
    if (!["GET", "HEAD"].includes(method) && config.data != null) {
      body = typeof config.data === "string" ? config.data : JSON.stringify(config.data);
      if (!headers["Content-Type"] && !headers["content-type"]) {
        headers["Content-Type"] = "application/json";
      }
    }

    const res = await globalThis.fetch(url, { method, headers, body });
    const text = await res.text();
    let data;
    try { data = text ? JSON.parse(text) : ""; } catch { data = text; }

    const axiosResponse = {
      data,
      status: res.status,
      statusText: res.statusText || "",
      headers: Object.fromEntries(res.headers),
      config,
      request: {},
    };

    const validate = config.validateStatus || ((s) => s >= 200 && s < 300);
    if (!validate(res.status)) {
      const err = new Error(`Request failed with status code ${res.status}`);
      err.config = config;
      err.response = axiosResponse;
      err.isAxiosError = true;
      throw err;
    }
    return axiosResponse;
  };

  const patchAxios = (axios) => {
    if (!axios || axios.__JAMESCLAW_PATCHED__) return;
    axios.defaults.adapter = fetchAdapter;
    const origCreate = axios.create.bind(axios);
    axios.create = function patchedCreate(instanceConfig = {}) {
      const inst = origCreate({ ...instanceConfig, adapter: fetchAdapter });
      inst.defaults.adapter = fetchAdapter;
      return inst;
    };
    axios.__JAMESCLAW_PATCHED__ = true;
    log("axios.create patched on tavily-mcp's actual axios instance");
  };

  // Setter trap: fires the instant tavily-mcp assigns `globalThis.__TAVILY_MCP_AXIOS__ = axios`.
  let _axiosRef = null;
  Object.defineProperty(globalThis, "__TAVILY_MCP_AXIOS__", {
    configurable: true,
    set(v) { _axiosRef = v; patchAxios(v); },
    get() { return _axiosRef; },
  });
}

// Load original tavily-mcp. The globalThis setter trap defined above will fire the
// instant tavily-mcp's patched build/index.js does `globalThis.__TAVILY_MCP_AXIOS__ = axios`,
// so by the time tavily-mcp constructs its axios instance, axios.create is already patched
// to route through our fetchAdapter (which in turn runs our rotation loop).
await import(pathToFileURL(TAVILY_MCP).href);

if (!globalThis.__TAVILY_MCP_AXIOS__ || !globalThis.__TAVILY_MCP_AXIOS__.__JAMESCLAW_PATCHED__) {
  console.error(
    "[tavily-rotator] WARN: tavily-mcp loaded but globalThis.__TAVILY_MCP_AXIOS__ was not set " +
    "— is harness/scripts/patch-tavily-mcp.sh applied? Rotation will be ineffective without it."
  );
}
