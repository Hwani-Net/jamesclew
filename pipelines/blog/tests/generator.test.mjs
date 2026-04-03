import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { parseMarkdownArticle } from '../src/generator.mjs';

describe('parseMarkdownArticle', () => {
  it('parses YAML array tags correctly', () => {
    const md = `---
title: "테스트 제목"
excerpt: "테스트 설명입니다"
focusKeyword: "테스트 키워드"
tags:
  - 태그1
  - 태그2
  - 태그3
category: 리뷰
---

## 소개

본문 내용입니다.`;

    const article = parseMarkdownArticle(md);
    assert.equal(article.title, '테스트 제목');
    assert.equal(article.excerpt, '테스트 설명입니다');
    assert.equal(article.focusKeyword, '테스트 키워드');
    assert.deepEqual(article.tags, ['태그1', '태그2', '태그3']);
    assert.equal(article.category, '리뷰');
  });

  it('strips quotes from values', () => {
    const md = `---
title: "따옴표 제목"
focusKeyword: '작은따옴표'
tags: 태그A, 태그B
category: tech
---

본문`;

    const article = parseMarkdownArticle(md);
    assert.equal(article.title, '따옴표 제목');
    assert.equal(article.focusKeyword, '작은따옴표');
    assert.deepEqual(article.tags, ['태그A', '태그B']);
  });

  it('converts markdown tables to HTML', () => {
    const md = `---
title: 테이블 테스트
---

## 비교

| 제품 | 가격 |
|---|---|
| A | 1000원 |
| B | 2000원 |`;

    const article = parseMarkdownArticle(md);
    assert.ok(article.content.includes('<table>'));
    assert.ok(article.content.includes('<th>제품</th>'));
    assert.ok(article.content.includes('<td>A</td>'));
  });

  it('converts markdown lists to HTML', () => {
    const md = `---
title: 리스트 테스트
---

## 장점

- 첫 번째 장점
- 두 번째 장점
- **강조된** 장점

## 순서

1. 첫째
2. 둘째`;

    const article = parseMarkdownArticle(md);
    assert.ok(article.content.includes('<ul>'));
    assert.ok(article.content.includes('<li>첫 번째 장점</li>'));
    assert.ok(article.content.includes('<strong>강조된</strong>'));
    assert.ok(article.content.includes('<ol>'));
    assert.ok(article.content.includes('<li>첫째</li>'));
  });

  it('handles inline formatting', () => {
    const md = `---
title: 인라인 테스트
---

**볼드**와 *이탤릭*과 [링크](https://example.com)와 \`코드\``;

    const article = parseMarkdownArticle(md);
    assert.ok(article.content.includes('<strong>볼드</strong>'));
    assert.ok(article.content.includes('<em>이탤릭</em>'));
    assert.ok(article.content.includes('<a href="https://example.com">링크</a>'));
    assert.ok(article.content.includes('<code>코드</code>'));
  });

  it('skips H1 (SSG handles it) and HTML comments', () => {
    const md = `---
title: H1 테스트
---

# 이건 스킵됨

## 이건 남음

<!-- 이 주석도 스킵 -->

본문`;

    const article = parseMarkdownArticle(md);
    assert.ok(!article.content.includes('<h1>'));
    assert.ok(article.content.includes('<h2>이건 남음</h2>'));
    assert.ok(!article.content.includes('주석'));
  });

  it('parses the actual sample article correctly', async () => {
    const { readFileSync } = await import('fs');
    const md = readFileSync('content/drafts/wireless-earbuds-2026.md', 'utf-8');
    const article = parseMarkdownArticle(md);

    assert.ok(article.title.includes('무선 이어폰'));
    assert.ok(!article.title.startsWith('"'), 'Title should not start with quote');
    assert.equal(article.focusKeyword, '가성비 무선 이어폰');
    assert.ok(article.tags.length >= 3, `Expected >= 3 tags, got ${article.tags.length}: ${article.tags}`);
    assert.ok(article.tags.includes('무선이어폰'));
    assert.ok(article.content.includes('<table>'), 'Should have comparison table');
    assert.ok(article.content.includes('<ul>'), 'Should have lists');
    assert.ok(article.content.includes('<h2>'), 'Should have H2 headings');
    assert.ok(article.content.includes('<h3>'), 'Should have H3 headings (FAQ)');
  });
});
