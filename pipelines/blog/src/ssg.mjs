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

  // Category glow map
  const glowMap = { '가전': 'blue', '생활용품': 'green', '뷰티/건강': 'pink', 'IT/디지털': 'purple', '리뷰': 'blue' };
  const getGlow = (cat) => glowMap[cat] || 'blue';

  // Category icon map (Material Symbols)
  const iconMap = { '가전': 'kitchen', '생활용품': 'home', '뷰티/건강': 'spa', 'IT/디지털': 'devices', '리뷰': 'rate_review' };
  const getIcon = (cat) => iconMap[cat] || 'star';

  // Fallback for no-image cards: gradient + icon
  const gradMap = { blue: 'from-blue-900/40 to-indigo-900/40', green: 'from-emerald-900/40 to-teal-900/40', pink: 'from-pink-900/40 to-rose-900/40', purple: 'from-purple-900/40 to-violet-900/40' };
  const noImgFallback = (cat, size) => {
    const glow = getGlow(cat);
    const grad = gradMap[glow] || gradMap.blue;
    const icon = getIcon(cat);
    const iconSize = size === 'large' ? 'text-7xl' : size === 'wide' ? 'text-5xl' : 'text-4xl';
    return `<div class="${size === 'square' ? 'aspect-square rounded-2xl' : size === 'wide' ? 'w-2/5 relative h-full' : 'absolute inset-0'} bg-gradient-to-br ${grad} flex items-center justify-center ${size === 'square' ? 'mb-4' : ''}"><span class="material-symbols-outlined ${iconSize} text-white/20">${icon}</span></div>`;
  };

  // Category nav tabs
  const catTabs = categories.map(c =>
    `<a class="text-slate-400 font-medium hover:text-white transition-colors" href="#">${escapeHtml(c)}</a>`
  ).join('\n            ');

  // Bento grid cards — first card is 2x2 featured, rest alternate sizes
  const bentoCards = sorted.map((p, i) => {
    const thumb = getThumb(p);
    const cat = p.category || '리뷰';
    const glow = getGlow(cat);
    const glowColors = { blue: 'blue-500', green: 'emerald-500', pink: 'pink-500', purple: 'purple-500' };
    const gc = glowColors[glow] || 'blue-500';

    if (i === 0) {
      // 2x2 large featured card
      return `<a href="/posts/${p.slug}/" class="md:col-span-2 md:row-span-2 group bento-glow-${glow} relative overflow-hidden bg-[#1c1c1e] rounded-[2.5rem] border border-white/5 transition-all duration-500 cursor-pointer block">
        ${thumb ? `<img class="absolute inset-0 w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" src="${thumb}" alt="${escapeHtml(p.title)}" loading="lazy">` : noImgFallback(cat, 'large')}
        <div class="absolute inset-0 bg-gradient-to-t from-black via-black/20 to-transparent"></div>
        <div class="absolute bottom-8 left-8 right-8 space-y-4">
          <span class="px-3 py-1 rounded bg-${gc}/20 text-${gc.replace('500','300')} text-[10px] font-black uppercase tracking-widest border border-${gc}/30">${escapeHtml(cat)}</span>
          <h3 class="text-3xl lg:text-4xl font-black text-white leading-tight">${escapeHtml(p.title)}</h3>
          <p class="text-slate-300 line-clamp-2 max-w-lg">${escapeHtml(p.excerpt || '')}</p>
        </div>
      </a>`;
    }

    if (i % 4 === 1 || i % 4 === 2) {
      // 1x1 small cards
      return `<a href="/posts/${p.slug}/" class="group bento-glow-${glow} bg-[#1c1c1e] rounded-[2rem] p-6 border border-white/5 transition-all duration-500 cursor-pointer flex flex-col justify-between block">
        ${thumb ? `<div class="aspect-square rounded-2xl overflow-hidden mb-4"><img class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" src="${thumb}" alt="${escapeHtml(p.title)}" loading="lazy"></div>` : noImgFallback(cat, 'square')}
        <h3 class="font-bold text-white leading-tight">${escapeHtml(p.title)}</h3>
        <div class="flex justify-between items-center mt-2">
          <span class="text-slate-500 text-[10px]">${escapeHtml(cat)}</span>
        </div>
      </a>`;
    }

    // 2x1 wide cards (col-span-2)
    return `<a href="/posts/${p.slug}/" class="md:col-span-2 group bento-glow-${glow} relative overflow-hidden bg-[#1c1c1e] rounded-[2rem] border border-white/5 transition-all duration-500 cursor-pointer flex block">
      ${thumb ? `<div class="w-2/5 relative h-full"><img class="absolute inset-0 w-full h-full object-cover" src="${thumb}" alt="${escapeHtml(p.title)}" loading="lazy"></div>` : noImgFallback(cat, 'wide')}
      <div class="flex-1 p-8 flex flex-col justify-center gap-3">
        <span class="w-fit px-3 py-1 rounded-full bg-${gc}/10 text-${gc.replace('500','400')} text-[10px] font-black uppercase">${escapeHtml(cat)}</span>
        <h3 class="text-2xl font-black text-white">${escapeHtml(p.title)}</h3>
        <p class="text-slate-400 text-sm line-clamp-2">${escapeHtml(p.excerpt || '')}</p>
      </div>
    </a>`;
  }).join('\n');

  // TOP 5 sidebar
  const top5 = sorted.slice(0, 5).map((p, i) => {
    const rank = String(i + 1).padStart(2, '0');
    const textColor = i === 0 ? 'text-transparent bg-clip-text bg-gradient-to-b from-blue-400 to-transparent opacity-80' : 'text-transparent bg-clip-text bg-gradient-to-b from-slate-600 to-transparent opacity-50';
    const titleColor = i === 0 ? 'text-white' : 'text-slate-400';
    return `<a href="/posts/${p.slug}/" class="flex items-start gap-6 group cursor-pointer">
      <span class="text-5xl font-black ${textColor} leading-none">${rank}</span>
      <div class="flex-1 pt-1">
        <p class="${titleColor} font-bold text-sm leading-snug group-hover:text-blue-400 transition-colors">${escapeHtml(p.title)}</p>
      </div>
    </a>`;
  }).join('\n');

  // Category pill tags
  const catPills = categories.map(c => {
    const glow = getGlow(c);
    return `<span class="px-5 py-2.5 rounded-full bg-slate-800 text-slate-400 text-xs font-bold cursor-pointer hover:text-white hover:bg-slate-700 transition-all border border-white/5">${escapeHtml(c)}</span>`;
  }).join('\n');

  return `<!DOCTYPE html>
<html class="dark" lang="ko"><head>
<meta charset="utf-8">
<meta content="width=device-width, initial-scale=1.0" name="viewport">
<title>${SITE_NAME} — 똑똑한 소비의 시작</title>
<meta name="description" content="가성비 제품 비교, 생활 꿀팁, 실속 리뷰. 정직한 비교 리뷰와 실시간 최저가.">
<link rel="canonical" href="${SITE_URL}/">
<meta property="og:type" content="website">
<meta property="og:title" content="${SITE_NAME} — 똑똑한 소비의 시작">
<meta property="og:url" content="${SITE_URL}/">
${featuredThumb ? `<meta property="og:image" content="${SITE_URL}${featuredThumb}">` : ''}
${ADSENSE.pubId ? `<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${ADSENSE.pubId}" crossorigin="anonymous"></script>` : ''}
<link href="https://fonts.googleapis.com/css2?family=Archivo+Black&family=Manrope:wght@400;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet">
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script>
tailwind.config = { darkMode: "class", theme: { extend: {
  colors: { surface: "#131315", "surface-container": "#1f1f21", "surface-container-high": "#2a2a2c", "surface-container-low": "#1b1b1d" },
  borderRadius: { DEFAULT: "1rem", lg: "2rem", xl: "3rem" },
  fontFamily: { headline: ["Manrope","sans-serif"], body: ["Plus Jakarta Sans","sans-serif"], display: ["Archivo Black","sans-serif"] }
}}}
</script>
<style>
  body { background-color: #0e0e10; color: #e4e2e4; font-family: 'Plus Jakarta Sans', sans-serif; }
  .material-symbols-outlined { font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24; }
  .bento-glow-blue:hover { box-shadow: 0 0 30px rgba(77, 142, 255, 0.2); border-color: rgba(77, 142, 255, 0.3); }
  .bento-glow-green:hover { box-shadow: 0 0 30px rgba(52, 211, 153, 0.2); border-color: rgba(52, 211, 153, 0.3); }
  .bento-glow-pink:hover { box-shadow: 0 0 30px rgba(244, 114, 182, 0.2); border-color: rgba(244, 114, 182, 0.3); }
  .bento-glow-purple:hover { box-shadow: 0 0 30px rgba(167, 139, 250, 0.2); border-color: rgba(167, 139, 250, 0.3); }
  .no-scrollbar::-webkit-scrollbar { display: none; }
  .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
</head>
<body class="selection:bg-blue-500/30">
<!-- Nav -->
<nav class="fixed top-0 w-full z-50 bg-[#131315]/80 backdrop-blur-xl shadow-[0_20px_40px_rgba(0,0,0,0.4)]">
  <div class="flex justify-between items-center px-8 h-16 max-w-full">
    <a href="/" class="text-2xl font-display text-white tracking-tighter uppercase">스마트리뷰</a>
    <div class="hidden md:flex gap-8 items-center font-['Manrope'] font-bold text-sm tracking-tight">
      ${catTabs}
    </div>
    <div class="flex items-center gap-4">
      <span class="material-symbols-outlined text-slate-400 cursor-pointer hover:text-white transition-all">search</span>
      <span class="material-symbols-outlined text-slate-400 cursor-pointer hover:text-white transition-all md:hidden">menu</span>
    </div>
  </div>
</nav>

<main class="pt-24 pb-20 px-6 lg:px-12 max-w-[1440px] mx-auto space-y-12">
  <!-- Hero -->
  ${featured ? `<a href="/posts/${featured.slug}/" class="block relative group cursor-pointer overflow-hidden rounded-[2.5rem] bg-surface-container-low aspect-[21/9] min-h-[400px] lg:min-h-[500px]">
    <div class="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-transparent z-10"></div>
    <div class="absolute -bottom-20 -left-20 w-[60%] h-[60%] bg-blue-600/20 blur-[120px] rounded-full z-0 group-hover:bg-blue-500/30 transition-all duration-700"></div>
    <div class="absolute -bottom-20 -right-20 w-[60%] h-[60%] bg-purple-600/20 blur-[120px] rounded-full z-0 group-hover:bg-purple-500/30 transition-all duration-700"></div>
    ${featuredThumb ? `<img class="absolute inset-0 w-full h-full object-cover transition-transform duration-1000 group-hover:scale-105" src="${featuredThumb}" alt="${escapeHtml(featured.title)}" loading="eager">` : ''}
    <div class="absolute top-10 left-10 z-20">
      <span class="px-6 py-2 rounded-full bg-blue-600 text-white text-xs font-black tracking-[0.2em] uppercase">BEST PICK</span>
    </div>
    <div class="absolute bottom-10 lg:bottom-16 left-8 lg:left-16 right-8 lg:right-16 z-20 space-y-4 lg:space-y-6">
      <h1 class="font-headline text-3xl lg:text-6xl font-extrabold text-white leading-none tracking-tighter max-w-4xl">${escapeHtml(featured.title)}</h1>
      <p class="text-slate-300 text-lg lg:text-xl font-body max-w-2xl opacity-80">${escapeHtml(featured.excerpt || '')}</p>
    </div>
  </a>` : ''}

  <!-- Content + Sidebar -->
  <div class="flex flex-col lg:flex-row gap-12">
    <!-- Bento Grid -->
    <div class="flex-1">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 auto-rows-[280px] gap-6">
        ${bentoCards}
      </div>
    </div>

    <!-- Sidebar -->
    <aside class="w-full lg:w-80 space-y-8">
      <div class="bg-[#1B1B1D] rounded-[2.5rem] p-8 border border-white/5 shadow-2xl">
        <div class="mb-10">
          <h2 class="font-headline font-black text-blue-400 text-sm tracking-[0.2em] uppercase">TOP 5 REVIEWS</h2>
          <p class="text-slate-500 text-xs mt-1">가장 많이 읽힌 리뷰</p>
        </div>
        <div class="space-y-8">
          ${top5}
        </div>
      </div>
      <div class="bg-[#1B1B1D] rounded-[2.5rem] p-8 border border-white/5">
        <h2 class="font-headline font-black text-slate-500 text-xs tracking-[0.2em] uppercase mb-6">CATEGORIES</h2>
        <div class="flex flex-wrap gap-2">
          ${catPills}
        </div>
      </div>
    </aside>
  </div>
</main>

<!-- Footer -->
<footer class="w-full border-t border-white/5 mt-20 bg-[#0e0e10]">
  <div class="flex flex-col items-center py-20 px-8 w-full max-w-[1440px] mx-auto">
    <div class="text-2xl font-display text-white mb-2 tracking-tighter">스마트리뷰</div>
    <p class="text-slate-500 text-sm font-body mb-12">똑똑한 소비의 시작 — 정직한 리뷰와 실시간 최저가</p>
    <div class="flex flex-wrap justify-center gap-10 mb-12">
      <a class="text-xs uppercase tracking-[0.2em] text-slate-500 hover:text-blue-400 transition-colors font-bold" href="/sitemap.xml">사이트맵</a>
      <a class="text-xs uppercase tracking-[0.2em] text-slate-500 hover:text-blue-400 transition-colors font-bold" href="#">이용약관</a>
      <a class="text-xs uppercase tracking-[0.2em] text-slate-500 hover:text-blue-400 transition-colors font-bold" href="#">개인정보처리방침</a>
    </div>
    <div class="text-[10px] uppercase tracking-[0.3em] text-slate-600 font-bold opacity-40">
      &copy; ${new Date().getFullYear()} SMART REVIEW. ALL RIGHTS RESERVED.
    </div>
  </div>
</footer>
</body></html>`;
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
