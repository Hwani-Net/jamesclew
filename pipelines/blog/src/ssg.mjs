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
  const featured = sorted[0];
  const rest = sorted.slice(1);

  const getThumb = (p) => p?.content?.match(/<img[^>]+src="([^"]+)"/)?.[1] || '';
  const featuredThumb = getThumb(featured);

  // Collect unique categories
  const categories = [...new Set(sorted.map(p => p.category || '리뷰'))];

  // Category chips
  const catChips = categories.map(c => `<a href="#" class="cat-chip">${escapeHtml(c)}</a>`).join('');

  // All cards as grid
  const allCards = sorted.map(p => {
    const thumb = getThumb(p);
    return `
      <a href="/posts/${p.slug}/" class="grid-card">
        ${thumb ? `<div class="grid-img"><img src="${thumb}" alt="${escapeHtml(p.title)}" loading="lazy"></div>` : '<div class="grid-img"></div>'}
        <div class="grid-body">
          <span class="chip">${escapeHtml(p.category || '리뷰')}</span>
          <h3>${escapeHtml(p.title)}</h3>
          <p>${escapeHtml(p.excerpt || '')}</p>
          <div class="meta">${new Date(p.createdAt).toLocaleDateString('ko-KR')}</div>
        </div>
      </a>`;
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
  ${featuredThumb ? `<meta property="og:image" content="${SITE_URL}${featuredThumb}">` : ''}
  ${ADSENSE.pubId ? `<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${ADSENSE.pubId}" crossorigin="anonymous"></script>` : ''}
  <style>
    :root { --max-w: 1080px; --fg: #334155; --bg: #faf8f5; --accent: #e879a0; --accent-dark: #d4567a; --accent-light: #fdf2f5; --gray: #94a3b8; --card-bg: #fff; --radius: 24px; --shadow: 0 2px 12px rgba(0,0,0,.03); --shadow-hover: 0 16px 40px rgba(0,0,0,.08); --warm: #f9e4c8; }
    @media (prefers-color-scheme: dark) { :root { --fg: #e2e8f0; --bg: #1a1520; --accent: #f0a0bf; --accent-dark: #e879a0; --accent-light: #2a1f2e; --gray: #94a3b8; --card-bg: #231e2a; --warm: #2a2030; } }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: var(--fg); background: var(--bg); line-height: 1.7; -webkit-font-smoothing: antialiased; }
    a { text-decoration: none; color: inherit; }
    .container { max-width: var(--max-w); margin: 0 auto; padding: 0 1.5rem; }

    /* Header */
    .site-header { background: var(--card-bg); border-bottom: 1px solid rgba(0,0,0,.04); padding: 0.8rem 0; position: sticky; top: 0; z-index: 100; backdrop-filter: blur(12px); }
    .site-header .container { display: flex; align-items: center; justify-content: space-between; }
    .logo { font-size: 1.3rem; font-weight: 800; color: var(--fg); letter-spacing: -0.02em; }
    .logo span { color: var(--accent); }
    .site-header nav { display: flex; gap: 1.2rem; }
    .site-header nav a { color: var(--gray); font-size: 0.85rem; font-weight: 500; transition: color .15s; }
    .site-header nav a:hover { color: var(--accent); }

    /* Hero */
    .hero { background: linear-gradient(135deg, #fdf2f5 0%, #fce7f3 30%, #f0e4ff 70%, #ede9fe 100%); color: var(--fg); padding: 4rem 0 3rem; position: relative; overflow: hidden; }
    @media (prefers-color-scheme: dark) { .hero { background: linear-gradient(135deg, #2a1f2e 0%, #1e1528 50%, #1a1028 100%); color: #e2e8f0; } }
    .hero::after { content: ''; position: absolute; right: -60px; top: -30px; width: 280px; height: 280px; border-radius: 50%; background: rgba(232,121,160,.08); }
    .hero-content { display: flex; justify-content: space-between; align-items: center; gap: 2rem; }
    .hero-text h2 { font-size: 2.4rem; font-weight: 900; line-height: 1.25; margin-bottom: 0.8rem; letter-spacing: -0.03em; }
    .hero-text p { font-size: 1.05rem; color: var(--gray); max-width: 420px; margin-bottom: 1.5rem; }
    .hero-stats { display: flex; gap: 1.2rem; }
    .stat-box { background: var(--card-bg); border-radius: 20px; padding: 1.2rem 1.5rem; text-align: center; min-width: 110px; box-shadow: var(--shadow); }
    .stat-num { font-size: 2rem; font-weight: 900; color: var(--accent); }
    .stat-label { font-size: 0.72rem; color: var(--gray); margin-top: 0.2rem; }

    /* Category Chips */
    .cat-bar { display: flex; gap: 0.5rem; flex-wrap: wrap; }
    .cat-chip { background: var(--card-bg); color: var(--fg); font-size: 0.8rem; font-weight: 600; padding: 0.45rem 1rem; border-radius: 99px; box-shadow: var(--shadow); transition: all .2s; border: 1px solid rgba(0,0,0,.04); }
    .cat-chip:hover { background: var(--accent); color: #fff; transform: translateY(-2px); box-shadow: 0 4px 12px rgba(232,121,160,.2); }

    /* Section Title */
    .section-title { font-size: 1.3rem; font-weight: 800; margin-bottom: 1.5rem; letter-spacing: -0.01em; }

    /* Chip */
    .chip { display: inline-block; background: var(--accent); color: #fff; font-size: 0.68rem; font-weight: 600; padding: 0.2rem 0.7rem; border-radius: 99px; letter-spacing: 0.5px; }

    /* Grid Cards */
    .grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem; margin-bottom: 3rem; }
    .grid-card { background: var(--card-bg); border-radius: var(--radius); overflow: hidden; box-shadow: var(--shadow); transition: box-shadow .25s, transform .25s; }
    .grid-card:hover { box-shadow: var(--shadow-hover); transform: translateY(-4px); }
    .grid-img { aspect-ratio: 4/3; overflow: hidden; background: linear-gradient(135deg, #fdf8f4, #f5eee8); display: flex; align-items: center; justify-content: center; }
    @media (prefers-color-scheme: dark) { .grid-img { background: linear-gradient(135deg, #231e2a, #1a1520); } }
    .grid-img img { width: 65%; height: 65%; object-fit: contain; transition: transform .3s; }
    .grid-card:hover .grid-img img { transform: scale(1.08); }
    .grid-body { padding: 1.3rem; }
    .grid-body h3 { font-size: 1rem; font-weight: 700; line-height: 1.4; margin: 0.5rem 0 0.4rem; }
    .grid-body p { color: var(--gray); font-size: 0.83rem; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; margin-bottom: 0.5rem; }
    .meta { color: var(--gray); font-size: 0.75rem; }

    /* Footer */
    .site-footer { background: var(--card-bg); border-top: 1px solid rgba(0,0,0,.04); padding: 2rem 0; margin-top: 3rem; }
    .footer-inner { display: flex; justify-content: space-between; align-items: center; }
    .footer-brand { font-weight: 800; font-size: 1rem; color: var(--fg); }
    .footer-brand span { color: var(--accent); }
    .footer-links { display: flex; gap: 1rem; }
    .footer-links a { color: var(--gray); font-size: 0.82rem; }
    .footer-links a:hover { color: var(--accent); }
    .footer-copy { text-align: center; color: var(--gray); font-size: 0.72rem; margin-top: 1rem; padding-top: 1rem; border-top: 1px solid rgba(0,0,0,.04); }

    @media (max-width: 768px) {
      .hero-text h2 { font-size: 1.7rem; }
      .hero-content { flex-direction: column; text-align: center; }
      .hero-stats { justify-content: center; }
      .hero-text p { margin: 0 auto 1.5rem; }
      .grid { grid-template-columns: 1fr; }
      .footer-inner { flex-direction: column; gap: 0.8rem; text-align: center; }
      .cat-bar { justify-content: center; }
    }
    @media (min-width: 769px) and (max-width: 1024px) {
      .grid { grid-template-columns: repeat(2, 1fr); }
    }
  </style>
</head>
<body>
  <header class="site-header">
    <div class="container">
      <a href="/" class="logo"><span>스마트</span>리뷰</a>
      <nav>
        <a href="/">홈</a>
        <a href="/sitemap.xml">사이트맵</a>
      </nav>
    </div>
  </header>

  <section class="hero">
    <div class="container">
      <div class="hero-content">
        <div class="hero-text">
          <h2>사기 전에 먼저,<br>비교해봤어요.</h2>
          <p>매번 뭘 사야 할지 고민되시죠? 다나와 최저가 기준으로 가성비 제품을 꼼꼼하게 비교해드려요.</p>
          <div class="cat-bar">${catChips}</div>
        </div>
        <div class="hero-stats">
          <div class="stat-box">
            <div class="stat-num">${sorted.length}</div>
            <div class="stat-label">비교 리뷰</div>
          </div>
          <div class="stat-box">
            <div class="stat-num">${sorted.length * 5}</div>
            <div class="stat-label">비교 제품</div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <div class="container">
    <div class="section-title">최신 리뷰</div>
    <div class="grid">
      ${allCards || '<p>아직 게시글이 없습니다.</p>'}
    </div>
  </div>

  <footer class="site-footer">
    <div class="container">
      <div class="footer-inner">
        <div class="footer-brand"><span>스마트</span>리뷰</div>
        <div class="footer-links">
          <a href="/sitemap.xml">사이트맵</a>
        </div>
      </div>
      <div class="footer-copy">&copy; ${new Date().getFullYear()} ${SITE_NAME}. 다나와 최저가 기준 객관적 비교 리뷰.</div>
    </div>
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
