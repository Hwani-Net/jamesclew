/**
 * SEO optimization module.
 * Analyzes and enhances content for search engine visibility.
 */

export function analyzeSEO(article) {
  const issues = [];
  const { title, content, excerpt, focusKeyword, tags } = article;

  // Title checks
  if (!title) issues.push({ severity: 'error', msg: 'Title is missing' });
  else {
    if (title.length > 60) issues.push({ severity: 'warn', msg: `Title too long (${title.length}/60)` });
    if (title.length < 20) issues.push({ severity: 'warn', msg: `Title too short (${title.length}/20)` });
    if (focusKeyword) {
      const titleLower = title.toLowerCase();
      const kwLower = focusKeyword.toLowerCase();
      const kwWords = kwLower.split(/\s+/);
      const allWordsInTitle = kwWords.every(w => titleLower.includes(w));
      if (!titleLower.includes(kwLower) && !allWordsInTitle) {
        issues.push({ severity: 'warn', msg: 'Focus keyword not in title' });
      }
    }
  }

  // Content checks
  if (!content) issues.push({ severity: 'error', msg: 'Content is missing' });
  else {
    const wordCount = content.replace(/<[^>]*>/g, '').split(/\s+/).filter(Boolean).length;
    if (wordCount < 300) issues.push({ severity: 'warn', msg: `Content too short (${wordCount} words, min 300)` });

    const h2Count = (content.match(/<h2/gi) || []).length;
    if (h2Count < 2) issues.push({ severity: 'warn', msg: `Need more H2 headings (${h2Count}, min 2)` });

    if (focusKeyword) {
      const kwLower = focusKeyword.toLowerCase();
      const contentLower = content.toLowerCase();
      const kwCount = contentLower.split(kwLower).length - 1;
      const density = (kwCount / wordCount) * 100;
      if (density < 0.3) issues.push({ severity: 'warn', msg: `Keyword density too low (${density.toFixed(1)}%)` });
      if (density > 3) issues.push({ severity: 'warn', msg: `Keyword density too high (${density.toFixed(1)}%)` });
    }

    // Check for images
    const imgCount = (content.match(/<img/gi) || []).length;
    if (imgCount === 0) issues.push({ severity: 'info', msg: 'No images found — consider adding visuals' });

    // Check for internal/external links
    const linkCount = (content.match(/<a\s/gi) || []).length;
    if (linkCount === 0) issues.push({ severity: 'info', msg: 'No links found — add internal/external links' });
  }

  // Excerpt / meta description
  if (!excerpt) issues.push({ severity: 'warn', msg: 'Meta description (excerpt) missing' });
  else if (excerpt.length > 155) issues.push({ severity: 'warn', msg: `Excerpt too long (${excerpt.length}/155)` });

  // Tags
  if (!tags || tags.length === 0) issues.push({ severity: 'info', msg: 'No tags — add 3-5 relevant tags' });

  const score = computeScore(issues);
  return { score, issues, pass: score >= 60 };
}

function computeScore(issues) {
  let score = 100;
  for (const i of issues) {
    if (i.severity === 'error') score -= 25;
    else if (i.severity === 'warn') score -= 10;
    else if (i.severity === 'info') score -= 3;
  }
  return Math.max(0, score);
}

/**
 * Generate structured data (JSON-LD) for a blog post.
 */
export function generateStructuredData({ title, excerpt, url, datePublished, author = 'JamesClaw', image }) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BlogPosting',
    headline: title,
    description: excerpt,
    url,
    datePublished,
    dateModified: datePublished,
    author: { '@type': 'Person', name: author },
    publisher: {
      '@type': 'Organization',
      name: author,
    },
    ...(image && { image: { '@type': 'ImageObject', url: image } }),
  };
}

/**
 * Generate AdSense-friendly ad insertion points in content.
 * Inserts ad placeholders after every N paragraphs.
 */
export function insertAdPlaceholders(html, { pubId, interval = 3 } = {}) {
  if (!pubId) return html;

  const adUnit = `
<div class="ad-container" style="margin:1.5em 0;text-align:center;">
  <!-- AdSense auto-ad managed by site-level code -->
  <ins class="adsbygoogle"
       style="display:block"
       data-ad-client="${pubId}"
       data-ad-format="auto"
       data-full-width-responsive="true"></ins>
</div>`;

  const paragraphs = html.split('</p>');
  const result = [];

  for (let i = 0; i < paragraphs.length; i++) {
    result.push(paragraphs[i]);
    if (i < paragraphs.length - 1) {
      result.push('</p>');
      if ((i + 1) % interval === 0) {
        result.push(adUnit);
      }
    }
  }
  return result.join('');
}

/**
 * Format article for WordPress with SEO enhancements.
 */
export function formatForWP(article, { adsensePubId } = {}) {
  let { content } = article;

  // Add FAQ structured data if FAQ section exists
  if (content.includes('<h2') && content.toLowerCase().includes('faq')) {
    const jsonLd = generateStructuredData(article);
    content = `<!-- JSON-LD -->\n<script type="application/ld+json">${JSON.stringify(jsonLd)}</script>\n${content}`;
  }

  // Insert ad placeholders
  if (adsensePubId) {
    content = insertAdPlaceholders(content, { pubId: adsensePubId });
  }

  return { ...article, content };
}
