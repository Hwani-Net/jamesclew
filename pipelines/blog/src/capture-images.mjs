/**
 * Capture product thumbnail images from Coupang product pages.
 * Uses Playwright with separate browser instances per product (bot detection bypass).
 */

import { existsSync, mkdirSync, readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const IMAGES_DIR = resolve(__dirname, '..', 'dist', 'images');
const log = (msg) => console.log(`[CAPTURE] ${msg}`);

/**
 * Capture product thumbnail from a Coupang product page.
 * Each product uses a separate browser instance to avoid bot blocking.
 */
async function captureOne(slug, url, idx) {
  const { chromium } = await import('playwright');
  const tempDir = `${process.env.LOCALAPPDATA || '/tmp'}/pw-capture-${idx}-${Date.now()}`;
  const browser = await chromium.launchPersistentContext(tempDir, {
    headless: false,
    viewport: { width: 1280, height: 900 },
    args: ['--disable-blink-features=AutomationControlled'],
  });

  try {
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 20000 });
    await page.waitForTimeout(8000);

    // Find the largest image in viewport (product thumbnail)
    const imgRect = await page.evaluate(() => {
      const imgs = Array.from(document.querySelectorAll('img'));
      let best = null;
      for (const img of imgs) {
        const rect = img.getBoundingClientRect();
        if (rect.width > 100 && rect.height > 100 && rect.y < 800 && rect.y > 0) {
          if (!best || rect.width * rect.height > best.area) {
            best = { x: Math.max(0, Math.round(rect.x)), y: Math.max(0, Math.round(rect.y)),
                     w: Math.round(rect.width), h: Math.round(rect.height),
                     area: rect.width * rect.height };
          }
        }
      }
      return best;
    });

    if (imgRect) {
      const outPath = resolve(IMAGES_DIR, `${slug}.jpg`);
      await page.screenshot({ path: outPath, clip: { x: imgRect.x, y: imgRect.y, width: imgRect.w, height: imgRect.h } });
      log(`✅ ${slug}: ${imgRect.w}x${imgRect.h} saved`);
      return true;
    } else {
      log(`❌ ${slug}: no product image found in viewport`);
      return false;
    }
  } catch (e) {
    log(`❌ ${slug}: ${e.message.slice(0, 80)}`);
    return false;
  } finally {
    await browser.close();
  }
}

/**
 * Capture all product images.
 * @param {Array<{slug: string, coupangUrl: string}>} products
 * @param {number} maxRetries - max retries per product
 */
export async function captureProductImages(products, maxRetries = 2) {
  mkdirSync(IMAGES_DIR, { recursive: true });

  for (let i = 0; i < products.length; i++) {
    const p = products[i];
    let success = false;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      if (attempt > 0) {
        log(`Retry ${attempt}/${maxRetries} for ${p.slug}...`);
        await new Promise(r => setTimeout(r, 3000));
      }
      success = await captureOne(p.slug, p.coupangUrl, i * 10 + attempt);
      if (success) {
        // Verify the captured image
        const outPath = resolve(IMAGES_DIR, `${p.slug}.jpg`);
        const buf = readFileSync(outPath);
        const isJPEG = buf[0] === 0xFF && buf[1] === 0xD8;
        const isPNG = buf[0] === 0x89 && buf[1] === 0x50;
        if (!isJPEG && !isPNG) {
          log(`⚠️ ${p.slug}: captured file is not a valid image, retrying...`);
          success = false;
          continue;
        }
        if (isPNG) {
          // Rename to .png to match actual format
          const { renameSync } = await import('fs');
          const pngPath = resolve(IMAGES_DIR, `${p.slug}.png`);
          renameSync(outPath, pngPath);
          log(`📝 ${p.slug}: renamed to .png (actual format is PNG)`);
        }
        break;
      }
    }

    if (!success) {
      log(`⛔ ${p.slug}: FAILED after ${maxRetries + 1} attempts`);
    }

    // Wait between products to avoid rate limiting
    if (i < products.length - 1) {
      await new Promise(r => setTimeout(r, 3000));
    }
  }

  // Return final file list
  const files = {};
  for (const p of products) {
    const jpg = resolve(IMAGES_DIR, `${p.slug}.jpg`);
    const png = resolve(IMAGES_DIR, `${p.slug}.png`);
    if (existsSync(jpg)) files[p.slug] = `/images/${p.slug}.jpg`;
    else if (existsSync(png)) files[p.slug] = `/images/${p.slug}.png`;
    else files[p.slug] = null;
  }
  return files;
}
