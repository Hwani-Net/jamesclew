/**
 * Content generator using Claude API.
 * Generates SEO-optimized Korean blog posts.
 */

import { ANTHROPIC, CONTENT } from './config.mjs';

const SYSTEM_PROMPT = `You are a Korean content writer specializing in SEO-optimized blog posts.
Target locale: ${CONTENT.locale}. Write entirely in Korean.

Output JSON with these fields:
- title: SEO-optimized title (50-60 chars)
- excerpt: meta description (120-155 chars)
- focusKeyword: primary keyword
- tags: array of 3-5 tag strings
- category: category name
- content: full HTML blog post with H2/H3 structure, FAQ section, and CTA

HTML rules:
- Use <h2>, <h3> for headings (no <h1>, WordPress handles it)
- Use <p> for paragraphs
- Include a FAQ section with <h2>자주 묻는 질문</h2>
- End with a CTA paragraph
- Min 800 words, aim for 1200-1500`;

export async function generateArticle(topic, { keywords = [], tone = 'informative' } = {}) {
  if (!ANTHROPIC.apiKey) {
    throw new Error('ANTHROPIC_API_KEY required for content generation');
  }

  const userPrompt = `Write a comprehensive blog post about: ${topic}
${keywords.length ? `Target keywords: ${keywords.join(', ')}` : ''}
Tone: ${tone}
Category: ${CONTENT.defaultCategory}`;

  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': ANTHROPIC.apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      messages: [{ role: 'user', content: userPrompt }],
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Claude API error ${res.status}: ${err}`);
  }

  const data = await res.json();
  const text = data.content[0].text;

  // Extract JSON from response (handle markdown code blocks)
  const jsonMatch = text.match(/```json\s*([\s\S]*?)```/) || text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new Error('Failed to parse article JSON from Claude response');

  const jsonStr = jsonMatch[1] || jsonMatch[0];
  return JSON.parse(jsonStr);
}

/**
 * Generate article from a pre-written markdown file (offline mode).
 * Supports YAML frontmatter with arrays, quoted strings, nested keys.
 */
export function parseMarkdownArticle(markdown) {
  const fmMatch = markdown.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!fmMatch) throw new Error('Invalid markdown: missing frontmatter');

  const meta = parseYamlFrontmatter(fmMatch[1]);
  const content = markdownToHTML(fmMatch[2].trim());

  return {
    title: unquote(meta.title || 'Untitled'),
    excerpt: unquote(meta.excerpt || meta.description || ''),
    focusKeyword: unquote(meta.focusKeyword || meta.keyword || ''),
    tags: Array.isArray(meta.tags) ? meta.tags.map(unquote) : String(meta.tags || '').split(',').map(t => t.trim()).filter(Boolean),
    category: unquote(meta.category || CONTENT.defaultCategory),
    content,
  };
}

function unquote(str) {
  if (typeof str !== 'string') return str;
  return str.replace(/^["']|["']$/g, '');
}

function parseYamlFrontmatter(yaml) {
  const meta = {};
  let currentKey = null;
  let currentArray = null;

  for (const line of yaml.split('\n')) {
    // YAML array item: "  - value"
    if (/^\s+-\s+/.test(line) && currentKey) {
      const val = line.replace(/^\s+-\s+/, '').trim();
      if (!currentArray) currentArray = [];
      currentArray.push(unquote(val));
      meta[currentKey] = currentArray;
      continue;
    }

    // Key-value pair: "key: value" or "key:"
    const kvMatch = line.match(/^(\w[\w\s]*?):\s*(.*)/);
    if (kvMatch) {
      // Flush previous array
      if (currentArray && currentKey) {
        meta[currentKey] = currentArray;
      }

      currentKey = kvMatch[1].trim();
      const val = kvMatch[2].trim();
      currentArray = null;

      if (val) {
        meta[currentKey] = val;
      }
    }
  }

  return meta;
}

function markdownToHTML(md) {
  const lines = md.split('\n');
  const html = [];
  let inTable = false;
  let inList = false;
  let listType = null;

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];

    // Skip HTML comments
    if (line.trim().startsWith('<!--')) {
      while (i < lines.length && !lines[i].includes('-->')) i++;
      continue;
    }

    // Image: ![alt](src)
    const imgMatch = line.trim().match(/^!\[([^\]]*)\]\(([^)]+)\)$/);
    if (imgMatch) {
      if (inList) { html.push(listType === 'ul' ? '</ul>' : '</ol>'); inList = false; }
      html.push(`<img src="${imgMatch[2]}" alt="${imgMatch[1]}" loading="lazy">`);
      continue;
    }

    // Blockquote: > text
    if (line.trim().startsWith('> ')) {
      if (inList) { html.push(listType === 'ul' ? '</ul>' : '</ol>'); inList = false; }
      html.push('<blockquote><p>' + inline(line.trim().slice(2)) + '</p></blockquote>');
      continue;
    }

    // Horizontal rule
    if (/^---+$/.test(line.trim())) {
      if (inList) { html.push(listType === 'ul' ? '</ul>' : '</ol>'); inList = false; }
      html.push('<hr>');
      continue;
    }

    // Headings
    if (/^### (.+)$/.test(line)) {
      if (inList) { html.push(listType === 'ul' ? '</ul>' : '</ol>'); inList = false; }
      html.push(line.replace(/^### (.+)$/, '<h3>$1</h3>'));
      continue;
    }
    if (/^## (.+)$/.test(line)) {
      if (inList) { html.push(listType === 'ul' ? '</ul>' : '</ol>'); inList = false; }
      html.push(line.replace(/^## (.+)$/, '<h2>$1</h2>'));
      continue;
    }
    if (/^# (.+)$/.test(line)) {
      if (inList) { html.push(listType === 'ul' ? '</ul>' : '</ol>'); inList = false; }
      // Skip H1 — SSG template handles it
      continue;
    }

    // Table
    if (line.trim().startsWith('|')) {
      // Skip separator row
      if (/^\|[\s-|]+\|$/.test(line.trim())) continue;

      if (!inTable) {
        if (inList) { html.push(listType === 'ul' ? '</ul>' : '</ol>'); inList = false; }
        inTable = true;
        // First row is header
        const cells = line.split('|').filter(c => c.trim()).map(c => `<th>${inline(c.trim())}</th>`);
        html.push('<table><thead><tr>' + cells.join('') + '</tr></thead><tbody>');
        // Skip separator row
        if (i + 1 < lines.length && /^\|[\s-|]+\|$/.test(lines[i + 1].trim())) i++;
        continue;
      }
      const cells = line.split('|').filter(c => c.trim()).map(c => `<td>${inline(c.trim())}</td>`);
      html.push('<tr>' + cells.join('') + '</tr>');
      continue;
    }
    if (inTable) {
      html.push('</tbody></table>');
      inTable = false;
    }

    // Unordered list
    if (/^[-*]\s+/.test(line.trim())) {
      if (!inList || listType !== 'ul') {
        if (inList) html.push(listType === 'ul' ? '</ul>' : '</ol>');
        html.push('<ul>');
        inList = true;
        listType = 'ul';
      }
      html.push('<li>' + inline(line.trim().replace(/^[-*]\s+/, '')) + '</li>');
      continue;
    }

    // Ordered list
    if (/^\d+\.\s+/.test(line.trim())) {
      if (!inList || listType !== 'ol') {
        if (inList) html.push(listType === 'ul' ? '</ul>' : '</ol>');
        html.push('<ol>');
        inList = true;
        listType = 'ol';
      }
      html.push('<li>' + inline(line.trim().replace(/^\d+\.\s+/, '')) + '</li>');
      continue;
    }

    // Close list if non-list line
    if (inList && line.trim() === '') {
      html.push(listType === 'ul' ? '</ul>' : '</ol>');
      inList = false;
      continue;
    }

    // Empty line
    if (line.trim() === '') continue;

    // Paragraph (with inline formatting)
    if (inList) { html.push(listType === 'ul' ? '</ul>' : '</ol>'); inList = false; }
    html.push('<p>' + inline(line) + '</p>');
  }

  // Close any open tags
  if (inTable) html.push('</tbody></table>');
  if (inList) html.push(listType === 'ul' ? '</ul>' : '</ol>');

  return html.join('\n');
}

function inline(text) {
  return text
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/`(.+?)`/g, '<code>$1</code>')
    .replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2">$1</a>');
}
