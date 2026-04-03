import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { analyzeSEO, insertAdPlaceholders, generateStructuredData } from '../src/seo.mjs';

describe('analyzeSEO', () => {
  it('returns high score for well-optimized article', () => {
    const article = {
      title: '2024년 최고의 프로그래밍 언어 추천 가이드',
      content: `<h2>서론</h2><p>${'프로그래밍 언어 선택은 중요합니다. '.repeat(50)}</p>
        <h2>JavaScript</h2><p>${'JavaScript는 프로그래밍 언어 중 가장 인기 있습니다. '.repeat(30)}</p>
        <h2>Python</h2><p>${'Python은 프로그래밍 언어 중 배우기 쉽습니다. '.repeat(30)}</p>
        <h2>자주 묻는 질문</h2><p>Q: 어떤 프로그래밍 언어를 배워야 하나요?</p>
        <a href="/other">관련 글</a>`,
      excerpt: '2024년에 배울 만한 최고의 프로그래밍 언어를 추천합니다.',
      focusKeyword: '프로그래밍 언어',
      tags: ['프로그래밍', 'JavaScript', 'Python'],
    };
    const result = analyzeSEO(article);
    assert.ok(result.score >= 60, `Expected score >= 60, got ${result.score}`);
    assert.ok(result.pass);
  });

  it('fails for empty content', () => {
    const result = analyzeSEO({ title: '', content: '', excerpt: '', tags: [] });
    assert.ok(result.score < 60);
    assert.ok(!result.pass);
  });

  it('warns on missing excerpt', () => {
    const result = analyzeSEO({
      title: '테스트 제목 - 충분히 긴 제목입니다 여기까지',
      content: '<h2>A</h2><h2>B</h2><p>' + '단어 '.repeat(300) + '</p>',
      tags: ['tag1'],
    });
    const hasExcerptWarn = result.issues.some(i => i.msg.includes('excerpt') || i.msg.includes('Meta'));
    assert.ok(hasExcerptWarn);
  });
});

describe('insertAdPlaceholders', () => {
  it('inserts ads after every N paragraphs', () => {
    const html = '<p>One</p><p>Two</p><p>Three</p><p>Four</p>';
    const result = insertAdPlaceholders(html, { pubId: 'pub-test', interval: 2 });
    assert.ok(result.includes('adsbygoogle'));
    assert.ok(result.includes('pub-test'));
  });

  it('returns unchanged html if no pubId', () => {
    const html = '<p>Test</p>';
    assert.equal(insertAdPlaceholders(html), html);
  });
});

describe('generateStructuredData', () => {
  it('produces valid JSON-LD', () => {
    const data = generateStructuredData({
      title: 'Test Post',
      excerpt: 'A test post',
      url: 'https://example.com/test',
      datePublished: '2024-01-01',
    });
    assert.equal(data['@type'], 'BlogPosting');
    assert.equal(data.headline, 'Test Post');
  });
});
