/**
 * Static Site Generator for Firebase Hosting.
 * Generates HTML pages from Firestore blog posts.
 * SEO-optimized with AdSense support.
 */

import { mkdir, writeFile, readFile, cp } from 'fs/promises';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { generateStructuredData } from './seo.mjs';
import { ADSENSE, CONTENT } from './config.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DIST_DIR = resolve(__dirname, '..', 'dist');

const SITE_NAME = process.env.SITE_NAME || 'JamesClaw Blog';
const SITE_URL = process.env.SITE_URL || 'https://example.com';

function baseTemplate({ title, description, content, url, datePublished, tags, jsonLd, adsensePubId }) {
  return `<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)} | ${SITE_NAME}</title>
  <meta name="description" content="${escapeHtml(description || '')}">
  <link rel="canonical" href="${SITE_URL}${url}">

  <!-- Open Graph -->
  <meta property="og:type" content="article">
  <meta property="og:title" content="${escapeHtml(title)}">
  <meta property="og:description" content="${escapeHtml(description || '')}">
  <meta property="og:url" content="${SITE_URL}${url}">
  <meta property="og:site_name" content="${SITE_NAME}">

  <!-- JSON-LD -->
  ${jsonLd ? `<script type="application/ld+json">${JSON.stringify(jsonLd)}</script>` : ''}

  <!-- AdSense -->
  ${adsensePubId ? `<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${adsensePubId}" crossorigin="anonymous"></script>` : ''}

  <style>
    :root { --max-w: 720px; --fg: #1a1a1a; --bg: #fff; --accent: #0066cc; --gray: #666; }
    @media (prefers-color-scheme: dark) { :root { --fg: #e0e0e0; --bg: #1a1a1a; --accent: #66b3ff; --gray: #999; } }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: var(--fg); background: var(--bg); line-height: 1.7; }
    .container { max-width: var(--max-w); margin: 0 auto; padding: 2rem 1.5rem; }
    header { border-bottom: 1px solid #eee; padding-bottom: 1rem; margin-bottom: 2rem; }
    header a { color: var(--fg); text-decoration: none; font-weight: 700; font-size: 1.2rem; }
    article h1 { font-size: 2rem; margin-bottom: 0.5rem; line-height: 1.3; }
    .meta { color: var(--gray); font-size: 0.9rem; margin-bottom: 2rem; }
    .tags { display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1rem; }
    .tag { background: #f0f0f0; padding: 0.2rem 0.6rem; border-radius: 4px; font-size: 0.8rem; color: var(--gray); }
    article h2 { font-size: 1.5rem; margin: 2rem 0 1rem; }
    article h3 { font-size: 1.2rem; margin: 1.5rem 0 0.8rem; }
    article p { margin-bottom: 1rem; }
    article a { color: var(--accent); }
    article img { max-width: 100%; height: auto; border-radius: 8px; margin: 1rem 0; }
    .ad-container { margin: 2rem 0; text-align: center; }
    footer { border-top: 1px solid #eee; margin-top: 3rem; padding-top: 1rem; color: var(--gray); font-size: 0.85rem; }
  </style>
</head>
<body>
  <div class="container">
    <header><a href="/">${SITE_NAME}</a></header>
    <article>
      <h1>${escapeHtml(title)}</h1>
      <div class="meta">${datePublished ? new Date(datePublished).toLocaleDateString('ko-KR') : ''}</div>
      ${tags?.length ? `<div class="tags">${tags.map(t => `<span class="tag">${escapeHtml(t)}</span>`).join('')}</div>` : ''}
      <div class="content">${content}</div>
    </article>
    <footer>&copy; ${new Date().getFullYear()} ${SITE_NAME}</footer>
  </div>
</body>
</html>`;
}

function indexTemplate(posts) {
  const sorted = posts.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  // 첫 번째 글에서 이미지 추출 (히어로용)
  const firstPost = sorted[0];
  const heroImg = firstPost?.content?.match(/<img[^>]+src="([^"]+)"/)?.[1] || '';

  const postList = sorted.map(p => {
    const thumb = p.content?.match(/<img[^>]+src="([^"]+)"/)?.[1] || '';
    return `
      <article class="post-card">
        ${thumb ? `<a href="/posts/${p.slug}/" class="post-thumb"><img src="${thumb}" alt="${escapeHtml(p.title)}" loading="lazy"></a>` : ''}
        <div class="post-info">
          <span class="post-category">${escapeHtml(p.category || '리뷰')}</span>
          <h2><a href="/posts/${p.slug}/">${escapeHtml(p.title)}</a></h2>
          <p>${escapeHtml(p.excerpt || '')}</p>
          <div class="meta">${new Date(p.createdAt).toLocaleDateString('ko-KR')}</div>
        </div>
      </article>`;
  }).join('\n');

  return `<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${SITE_NAME} — 생활 꿀팁 & 비교 리뷰</title>
  <meta name="description" content="가성비 제품 비교, 생활 꿀팁, 실속 리뷰. 다나와 최저가 기준 객관적 비교.">
  <link rel="canonical" href="${SITE_URL}/">
  <meta property="og:type" content="website">
  <meta property="og:title" content="${SITE_NAME} — 생활 꿀팁 & 비교 리뷰">
  <meta property="og:url" content="${SITE_URL}/">
  ${heroImg ? `<meta property="og:image" content="${SITE_URL}${heroImg}">` : ''}
  ${ADSENSE.pubId ? `<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${ADSENSE.pubId}" crossorigin="anonymous"></script>` : ''}
  <style>
    :root { --max-w: 820px; --fg: #1a1a1a; --bg: #fafafa; --accent: #2563eb; --accent-light: #eff6ff; --gray: #64748b; --card-bg: #fff; --radius: 12px; }
    @media (prefers-color-scheme: dark) { :root { --fg: #e2e8f0; --bg: #0f172a; --accent: #60a5fa; --accent-light: #1e293b; --gray: #94a3b8; --card-bg: #1e293b; } }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: var(--fg); background: var(--bg); line-height: 1.7; }
    .container { max-width: var(--max-w); margin: 0 auto; padding: 0 1.5rem; }

    /* Header */
    .site-header { background: var(--card-bg); border-bottom: 1px solid rgba(0,0,0,.06); padding: 1rem 0; position: sticky; top: 0; z-index: 10; }
    .site-header .container { display: flex; align-items: center; justify-content: space-between; }
    .site-header h1 { font-size: 1.3rem; font-weight: 800; }
    .site-header h1 a { color: var(--fg); text-decoration: none; }
    .site-header nav a { color: var(--gray); text-decoration: none; font-size: 0.9rem; margin-left: 1.5rem; }
    .site-header nav a:hover { color: var(--accent); }

    /* Hero */
    .hero { background: linear-gradient(135deg, var(--accent), #7c3aed); color: #fff; padding: 3rem 0; margin-bottom: 2rem; }
    .hero h2 { font-size: 1.8rem; font-weight: 800; margin-bottom: 0.5rem; line-height: 1.3; }
    .hero p { font-size: 1.05rem; opacity: 0.9; max-width: 500px; }

    /* Post Cards */
    .posts { padding: 1rem 0 3rem; }
    .posts-title { font-size: 1.1rem; font-weight: 700; margin-bottom: 1.2rem; padding-bottom: 0.5rem; border-bottom: 2px solid var(--accent); display: inline-block; }
    .post-card { display: flex; gap: 1.2rem; background: var(--card-bg); border-radius: var(--radius); padding: 1.2rem; margin-bottom: 1rem; box-shadow: 0 1px 3px rgba(0,0,0,.04); transition: box-shadow .2s; }
    .post-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,.08); }
    .post-thumb { flex-shrink: 0; width: 120px; height: 120px; border-radius: 8px; overflow: hidden; background: #f1f5f9; }
    .post-thumb img { width: 100%; height: 100%; object-fit: cover; }
    .post-info { flex: 1; display: flex; flex-direction: column; justify-content: center; }
    .post-category { font-size: 0.75rem; color: var(--accent); font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 0.3rem; }
    .post-card h2 { font-size: 1.1rem; margin-bottom: 0.3rem; line-height: 1.4; }
    .post-card h2 a { color: var(--fg); text-decoration: none; }
    .post-card h2 a:hover { color: var(--accent); }
    .post-card p { font-size: 0.88rem; color: var(--gray); display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
    .meta { color: var(--gray); font-size: 0.8rem; margin-top: 0.4rem; }

    /* Footer */
    .site-footer { border-top: 1px solid rgba(0,0,0,.06); padding: 1.5rem 0; text-align: center; color: var(--gray); font-size: 0.82rem; }

    @media (max-width: 600px) {
      .hero h2 { font-size: 1.4rem; }
      .post-card { flex-direction: column; gap: 0.8rem; }
      .post-thumb { width: 100%; height: 180px; }
    }
  </style>
</head>
<body>
  <header class="site-header">
    <div class="container">
      <h1><a href="/">${SITE_NAME}</a></h1>
      <nav>
        <a href="/">홈</a>
        <a href="/sitemap.xml">사이트맵</a>
      </nav>
    </div>
  </header>

  <section class="hero">
    <div class="container">
      <h2>돈 쓰기 전에,<br>비교부터.</h2>
      <p>다나와 최저가 기준 객관적 비교 리뷰. 가성비 제품, 생활 꿀팁을 정리합니다.</p>
    </div>
  </section>

  <div class="container">
    <section class="posts">
      <div class="posts-title">최신 리뷰</div>
      ${postList || '<p>아직 게시글이 없습니다.</p>'}
    </section>
  </div>

  <footer class="site-footer">
    <div class="container">&copy; ${new Date().getFullYear()} ${SITE_NAME}. All rights reserved.</div>
  </footer>
</body>
</html>`;
}

function escapeHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

/**
 * Build static site from posts array.
 */
export async function buildSite(posts) {
  await mkdir(DIST_DIR, { recursive: true });

  const published = posts.filter(p => p.status === 'publish');
  const log = (msg) => console.log(`[SSG] ${msg}`);

  // Generate index
  log(`Building index with ${published.length} posts...`);
  await writeFile(resolve(DIST_DIR, 'index.html'), indexTemplate(published));

  // Generate individual post pages
  for (const post of published) {
    const postDir = resolve(DIST_DIR, 'posts', post.slug);
    await mkdir(postDir, { recursive: true });

    const jsonLd = generateStructuredData({
      title: post.title,
      excerpt: post.excerpt,
      url: `/posts/${post.slug}/`,
      datePublished: post.createdAt,
    });

    const html = baseTemplate({
      title: post.title,
      description: post.excerpt,
      content: post.content,
      url: `/posts/${post.slug}/`,
      datePublished: post.createdAt,
      tags: post.tags,
      jsonLd,
      adsensePubId: ADSENSE.pubId,
    });

    await writeFile(resolve(postDir, 'index.html'), html);
    log(`  Built: /posts/${post.slug}/`);
  }

  // Generate sitemap
  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>${SITE_URL}/</loc><changefreq>daily</changefreq><priority>1.0</priority></url>
${published.map(p => `  <url><loc>${SITE_URL}/posts/${p.slug}/</loc><lastmod>${p.updatedAt || p.createdAt}</lastmod></url>`).join('\n')}
</urlset>`;
  await writeFile(resolve(DIST_DIR, 'sitemap.xml'), sitemap);

  // Generate robots.txt
  await writeFile(resolve(DIST_DIR, 'robots.txt'), `User-agent: *\nAllow: /\nSitemap: ${SITE_URL}/sitemap.xml\n`);

  // 404 page
  await writeFile(resolve(DIST_DIR, '404.html'), baseTemplate({
    title: '페이지를 찾을 수 없습니다',
    description: '404 Not Found',
    content: '<p>요청하신 페이지를 찾을 수 없습니다. <a href="/">홈으로 돌아가기</a></p>',
    url: '/404',
  }));

  log(`Build complete: ${published.length} posts, sitemap, robots.txt, 404`);
  return { distDir: DIST_DIR, postCount: published.length };
}
