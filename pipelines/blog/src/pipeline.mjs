/**
 * Content pipeline orchestrator.
 * Flow: Generate → SEO Analyze → Optimize → Save to Firestore → Build SSG → Deploy
 */

import { createClient } from './firebase-client.mjs';
import { analyzeSEO, formatForWP, insertAdPlaceholders } from './seo.mjs';
import { generateArticle, parseMarkdownArticle } from './generator.mjs';
import { buildSite } from './ssg.mjs';
import { verifyImageFormats, runFullVerification } from './verify.mjs';
import { ADSENSE, CONTENT } from './config.mjs';
import { writeFile, readFile, mkdir } from 'fs/promises';
import { resolve, dirname } from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

export async function runPipeline(topic, opts = {}) {
  const {
    dryRun = false,
    status = 'draft',
    keywords = [],
    tone = 'informative',
    markdownFile = null,
    deploy = false,
  } = opts;

  const log = (step, msg) => console.log(`[${step}] ${msg}`);

  // Step 1: Generate content
  log('GENERATE', markdownFile ? `Parsing ${markdownFile}` : `Generating article: "${topic}"`);
  let article;
  if (markdownFile) {
    const md = await readFile(markdownFile, 'utf-8');
    article = parseMarkdownArticle(md);
  } else {
    article = await generateArticle(topic, { keywords, tone });
  }
  log('GENERATE', `Title: "${article.title}" (${article.tags.length} tags)`);

  // Step 2: SEO analysis
  log('SEO', 'Analyzing content...');
  const seoResult = analyzeSEO(article);
  log('SEO', `Score: ${seoResult.score}/100 (${seoResult.pass ? 'PASS' : 'FAIL'})`);
  for (const issue of seoResult.issues) {
    log('SEO', `  [${issue.severity}] ${issue.msg}`);
  }

  if (!seoResult.pass && !dryRun) {
    log('SEO', 'Score below 60 — continuing with warning');
  }

  // Step 3: Insert ad placeholders
  if (ADSENSE.pubId) {
    log('ADS', 'Inserting AdSense placeholders...');
    article.content = insertAdPlaceholders(article.content, { pubId: ADSENSE.pubId });
  }

  // Step 4: Save draft locally
  const draftDir = resolve(CONTENT.outputDir, 'drafts');
  await mkdir(draftDir, { recursive: true });
  const slug = slugify(article.title);
  const draftPath = resolve(draftDir, `${slug}.json`);
  await writeFile(draftPath, JSON.stringify({
    ...article,
    slug,
    status,
    seo: seoResult,
    generatedAt: new Date().toISOString(),
  }, null, 2));
  log('SAVE', `Draft saved: ${draftPath}`);

  if (dryRun) {
    log('DRY-RUN', 'Skipping Firestore save and deploy');
    return { article, seo: seoResult, slug, draftPath, published: false };
  }

  // Step 5: Save to Firestore
  log('FIRESTORE', 'Saving to Firestore...');
  const db = createClient();
  const doc = await db.createPost(slug, {
    title: article.title,
    content: article.content,
    excerpt: article.excerpt,
    focusKeyword: article.focusKeyword || '',
    tags: article.tags || [],
    category: article.category || CONTENT.defaultCategory,
    status,
    seoScore: seoResult.score,
  });
  log('FIRESTORE', `Saved: posts/${slug}`);

  // Step 6: Build static site
  if (status === 'publish') {
    log('BUILD', 'Building static site...');
    const posts = await db.listPosts({ status: 'publish' });
    const { distDir, postCount } = await buildSite(posts);
    log('BUILD', `Built ${postCount} posts → ${distDir}`);

    // Step 7: Pre-deploy image format verification
    log('VERIFY', 'Checking image file formats...');
    const imgIssues = verifyImageFormats();
    if (imgIssues.length > 0) {
      for (const issue of imgIssues) {
        log('VERIFY', `❌ ${issue.file}: ${issue.issue}`);
      }
      log('VERIFY', `⛔ ${imgIssues.length} image issues found — fix before deploying`);
      return { article, seo: seoResult, slug, draftPath, published: false, deployed: false, imageIssues: imgIssues };
    }
    log('VERIFY', '✅ All image formats match extensions');

    // Step 8: Deploy to Firebase Hosting
    if (deploy) {
      log('DEPLOY', 'Deploying to Firebase Hosting...');
      const projectDir = resolve(__dirname, '..');
      execSync(`firebase deploy --only hosting`, { cwd: projectDir, stdio: 'inherit' });
      log('DEPLOY', 'Deployed successfully');

      // Step 9: Post-deploy live rendering verification
      const siteUrl = process.env.SITE_URL || 'https://smartreview-kr.web.app';
      const postUrl = `${siteUrl}/posts/${slug}/`;
      log('VERIFY', `Checking live rendering: ${postUrl}`);
      const verification = await runFullVerification(postUrl);
      if (!verification.passed) {
        log('VERIFY', `⛔ Live verification FAILED — ${verification.issues.length} issues`);
        for (const issue of verification.issues) {
          log('VERIFY', `  ❌ ${issue.file}: ${issue.issue}`);
        }
      } else {
        log('VERIFY', '✅ Live verification PASSED — all images rendered');
      }
    }
  }

  return { article, seo: seoResult, slug, draftPath, published: status === 'publish', deployed: deploy };
}

/**
 * Build and deploy without generating new content.
 */
export async function buildAndDeploy() {
  const log = (step, msg) => console.log(`[${step}] ${msg}`);
  const db = createClient();

  log('FETCH', 'Loading published posts from Firestore...');
  const posts = await db.listPosts({ status: 'publish' });
  log('FETCH', `Found ${posts.length} published posts`);

  log('BUILD', 'Building static site...');
  const { distDir, postCount } = await buildSite(posts);
  log('BUILD', `Built ${postCount} posts → ${distDir}`);

  log('DEPLOY', 'Deploying to Firebase Hosting...');
  const projectDir = resolve(__dirname, '..');
  execSync(`firebase deploy --only hosting`, { cwd: projectDir, stdio: 'inherit' });
  log('DEPLOY', 'Deployed successfully');

  return { postCount };
}

function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^\w\s가-힣-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .slice(0, 60);
}
