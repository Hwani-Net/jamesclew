import { describe, it, after } from 'node:test';
import assert from 'node:assert/strict';
import { buildSite } from '../src/ssg.mjs';
import { readFile, rm } from 'fs/promises';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DIST_DIR = resolve(__dirname, '..', 'dist');

const mockPosts = [
  {
    slug: 'test-post-1',
    title: '테스트 포스트 1번',
    content: '<h2>소개</h2><p>첫 번째 테스트 포스트입니다.</p><h2>본문</h2><p>본문 내용입니다.</p>',
    excerpt: '테스트 포스트 설명',
    tags: ['테스트', '블로그'],
    category: 'technology',
    status: 'publish',
    createdAt: '2024-01-15T00:00:00Z',
    updatedAt: '2024-01-15T00:00:00Z',
  },
  {
    slug: 'test-post-2',
    title: '테스트 포스트 2번',
    content: '<h2>두 번째</h2><p>두 번째 테스트 포스트입니다.</p>',
    excerpt: '두 번째 설명',
    tags: ['테스트'],
    category: 'technology',
    status: 'publish',
    createdAt: '2024-01-16T00:00:00Z',
    updatedAt: '2024-01-16T00:00:00Z',
  },
  {
    slug: 'draft-post',
    title: '드래프트 포스트',
    content: '<p>이건 드래프트입니다.</p>',
    excerpt: '',
    tags: [],
    category: 'technology',
    status: 'draft',
    createdAt: '2024-01-17T00:00:00Z',
  },
];

describe('buildSite', () => {
  after(async () => {
    await rm(DIST_DIR, { recursive: true, force: true });
  });

  it('generates correct number of HTML files (excludes drafts)', async () => {
    const { postCount } = await buildSite(mockPosts);
    assert.equal(postCount, 2, 'Should only build published posts');
  });

  it('creates index.html', async () => {
    const html = await readFile(resolve(DIST_DIR, 'index.html'), 'utf-8');
    assert.ok(html.includes('테스트 포스트 1번'));
    assert.ok(html.includes('테스트 포스트 2번'));
    assert.ok(!html.includes('드래프트 포스트'));
  });

  it('creates individual post pages', async () => {
    const html = await readFile(resolve(DIST_DIR, 'posts', 'test-post-1', 'index.html'), 'utf-8');
    assert.ok(html.includes('테스트 포스트 1번'));
    assert.ok(html.includes('첫 번째 테스트 포스트입니다'));
    assert.ok(html.includes('application/ld+json'));
  });

  it('creates sitemap.xml', async () => {
    const xml = await readFile(resolve(DIST_DIR, 'sitemap.xml'), 'utf-8');
    assert.ok(xml.includes('test-post-1'));
    assert.ok(xml.includes('test-post-2'));
  });

  it('creates robots.txt', async () => {
    const txt = await readFile(resolve(DIST_DIR, 'robots.txt'), 'utf-8');
    assert.ok(txt.includes('Sitemap:'));
    assert.ok(txt.includes('User-agent: *'));
  });

  it('creates 404.html', async () => {
    const html = await readFile(resolve(DIST_DIR, '404.html'), 'utf-8');
    assert.ok(html.includes('찾을 수 없습니다'));
  });
});
