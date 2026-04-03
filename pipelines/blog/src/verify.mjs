/**
 * Self-verification module for blog pipeline.
 * Ensures quality before reporting to user.
 */

import { readFileSync, readdirSync, statSync } from 'fs';
import { resolve, dirname, extname } from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DIST_DIR = resolve(__dirname, '..', 'dist');
const log = (step, msg) => console.log(`[VERIFY:${step}] ${msg}`);

/**
 * Verify all images in dist/images/ have correct format matching extension.
 * Returns list of issues.
 */
export function verifyImageFormats() {
  const imgDir = resolve(DIST_DIR, 'images');
  const issues = [];

  try {
    const files = readdirSync(imgDir);
    for (const f of files) {
      if (f.startsWith('verify') || f.startsWith('.')) continue;
      const path = resolve(imgDir, f);
      const stat = statSync(path);
      if (stat.size < 1000) {
        issues.push({ file: f, issue: `Too small (${stat.size} bytes) — likely not a real image` });
        continue;
      }

      // Read first bytes to detect actual format
      const buf = readFileSync(path);
      const ext = extname(f).toLowerCase();
      const isPNG = buf[0] === 0x89 && buf[1] === 0x50; // PNG magic bytes
      const isJPEG = buf[0] === 0xFF && buf[1] === 0xD8; // JPEG magic bytes

      if (ext === '.jpg' || ext === '.jpeg') {
        if (!isJPEG) {
          issues.push({ file: f, issue: `Extension is ${ext} but actual format is ${isPNG ? 'PNG' : 'unknown'}` });
        }
      } else if (ext === '.png') {
        if (!isPNG) {
          issues.push({ file: f, issue: `Extension is ${ext} but actual format is ${isJPEG ? 'JPEG' : 'unknown'}` });
        }
      }
    }
  } catch (e) {
    issues.push({ file: 'images/', issue: `Directory error: ${e.message}` });
  }

  return issues;
}

/**
 * Verify deployed site with Playwright — check all images render.
 * Returns { passed, results: [{alt, loaded, width, height}] }
 */
export async function verifyLiveRendering(url) {
  try {
    const result = execSync(`node -e "
      const { chromium } = require('playwright');
      (async () => {
        const browser = await chromium.launch({ headless: false });
        const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
        await page.goto('${url}', { waitUntil: 'networkidle', timeout: 20000 });
        await page.evaluate(async () => {
          for (let i = 0; i < 30; i++) { window.scrollBy(0, 400); await new Promise(r => setTimeout(r, 200)); }
          window.scrollTo(0, 0);
        });
        await page.waitForTimeout(3000);
        const imgs = await page.evaluate(() => {
          return Array.from(document.querySelectorAll('img')).map(img => ({
            alt: img.alt,
            loaded: img.complete && img.naturalWidth > 0,
            width: img.naturalWidth,
            height: img.naturalHeight,
            visible: img.getBoundingClientRect().height > 10,
          }));
        });
        await page.screenshot({ path: '${DIST_DIR.replace(/\\/g, '/')}/verify-live.png', fullPage: true });
        await browser.close();
        console.log(JSON.stringify(imgs));
      })();
    "`, { encoding: 'utf-8', timeout: 60000, cwd: resolve(__dirname, '..') });

    const imgs = JSON.parse(result.trim());
    const allOk = imgs.every(i => i.loaded && i.visible);
    return { passed: allOk, results: imgs };
  } catch (e) {
    return { passed: false, results: [], error: e.message.slice(0, 200) };
  }
}

/**
 * Verify HTTP status codes for key URLs.
 */
export async function verifyHTTPStatus(urls) {
  const results = [];
  for (const url of urls) {
    try {
      const status = execSync(`curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${url}"`, { encoding: 'utf-8' }).trim();
      results.push({ url, status: parseInt(status), ok: status === '200' });
    } catch {
      results.push({ url, status: 0, ok: false });
    }
  }
  return results;
}

/**
 * Run all verifications. Returns { passed, issues[] }
 */
export async function runFullVerification(postUrl) {
  const issues = [];

  // 1. Image format verification
  log('FORMAT', 'Checking image file formats...');
  const formatIssues = verifyImageFormats();
  for (const fi of formatIssues) {
    log('FORMAT', `❌ ${fi.file}: ${fi.issue}`);
    issues.push(fi);
  }
  if (formatIssues.length === 0) log('FORMAT', '✅ All image formats match extensions');

  // 2. HTTP status verification
  log('HTTP', 'Checking HTTP status codes...');
  const urls = [
    postUrl,
    postUrl.replace(/\/posts\/.*/, '/'),
    postUrl.replace(/\/posts\/.*/, '/sitemap.xml'),
  ];
  const httpResults = await verifyHTTPStatus(urls);
  for (const hr of httpResults) {
    if (!hr.ok) {
      log('HTTP', `❌ ${hr.url} → ${hr.status}`);
      issues.push({ file: hr.url, issue: `HTTP ${hr.status}` });
    } else {
      log('HTTP', `✅ ${hr.url} → ${hr.status}`);
    }
  }

  // 3. Live rendering verification
  log('RENDER', 'Checking live rendering with Playwright...');
  const renderResult = await verifyLiveRendering(postUrl);
  if (renderResult.error) {
    log('RENDER', `⚠️ Playwright error: ${renderResult.error}`);
    issues.push({ file: 'playwright', issue: renderResult.error });
  } else {
    for (const img of renderResult.results) {
      const ok = img.loaded && img.visible;
      log('RENDER', `${ok ? '✅' : '❌'} ${img.alt} (${img.width}x${img.height})`);
      if (!ok) issues.push({ file: img.alt, issue: `Not rendered (${img.width}x${img.height})` });
    }
  }

  const passed = issues.length === 0;
  log('RESULT', passed ? '✅ ALL VERIFICATIONS PASSED' : `❌ ${issues.length} ISSUES FOUND`);
  return { passed, issues };
}
