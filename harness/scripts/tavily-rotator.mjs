/**
 * Tavily MCP Key Rotator
 * - Wraps the original tavily-mcp with automatic API key rotation
 * - On 429 (rate limit) or 402 (payment required), switches to next key
 * - Cycles through all keys before giving up
 */
import { readFileSync } from "fs";
import { pathToFileURL } from "url";
import { resolve } from "path";
import { execSync } from "child_process";

const HOME = process.env.HOME || process.env.USERPROFILE;
const KEYS_FILE = process.env.TAVILY_KEYS_FILE || resolve(HOME, ".claude/tavily-keys.json");

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
let currentKeyIndex = 0;

const log = (msg) => process.stderr.write(`[tavily-rotator] ${msg}\n`);

log(`Loaded ${keys.length} API keys`);

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
      } catch {
        // Not JSON body, skip
      }
    }

    // Also set auth headers
    opts.headers = {
      ...(opts.headers || {}),
      Authorization: `Bearer ${key}`,
    };

    const res = await originalFetch(url, opts);

    if (res.status === 429 || res.status === 402) {
      const prev = currentKeyIndex + 1;
      currentKeyIndex = (currentKeyIndex + 1) % keys.length;
      log(`Key #${prev} exhausted (${res.status}), rotating to #${currentKeyIndex + 1}`);
      continue;
    }

    return res;
  }

  log("All keys exhausted!");
  return originalFetch(url, options);
};

// Set initial env key and load original tavily-mcp
process.env.TAVILY_API_KEY = keys[currentKeyIndex];
await import(pathToFileURL(TAVILY_MCP).href);
