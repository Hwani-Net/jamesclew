#!/usr/bin/env node

/**
 * CLI entry point for Firebase blog content pipeline.
 *
 * Usage:
 *   node src/cli.mjs pipeline "topic" [--dry-run] [--status draft|publish] [--deploy]
 *   node src/cli.mjs pipeline --file content/my-post.md [--status publish]
 *   node src/cli.mjs generate "topic" [--keywords kw1,kw2]
 *   node src/cli.mjs build                 # Build SSG from Firestore
 *   node src/cli.mjs deploy                # Build + deploy to Firebase Hosting
 *   node src/cli.mjs check                 # Test Firestore connection
 */

import './config.mjs';
import { runPipeline, buildAndDeploy } from './pipeline.mjs';
import { createClient } from './firebase-client.mjs';
import { generateArticle } from './generator.mjs';
import { analyzeSEO } from './seo.mjs';
import { buildSite } from './ssg.mjs';
import { readFile, writeFile, mkdir } from 'fs/promises';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);

function parseFlags(args) {
  const flags = {};
  const positional = [];
  for (let i = 0; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      const key = args[i].slice(2);
      const next = args[i + 1];
      if (!next || next.startsWith('--')) {
        flags[key] = true;
      } else {
        flags[key] = next;
        i++;
      }
    } else {
      positional.push(args[i]);
    }
  }
  return { flags, positional };
}

const { flags, positional } = parseFlags(args);
const command = positional[0];

async function main() {
  switch (command) {
    case 'pipeline': {
      const topic = positional[1] || flags.topic;
      if (!topic && !flags.file) {
        console.error('Usage: pipeline "topic" or pipeline --file post.md');
        process.exit(1);
      }
      const result = await runPipeline(topic, {
        dryRun: !!flags['dry-run'],
        status: flags.status || 'draft',
        keywords: flags.keywords ? flags.keywords.split(',') : [],
        markdownFile: flags.file || null,
        deploy: !!flags.deploy,
      });
      console.log(`\nResult: ${result.published ? 'Published' : 'Draft saved'}`);
      console.log(`SEO Score: ${result.seo.score}/100`);
      break;
    }

    case 'generate': {
      const topic = positional[1];
      if (!topic) { console.error('Usage: generate "topic"'); process.exit(1); }
      const article = await generateArticle(topic, {
        keywords: flags.keywords ? flags.keywords.split(',') : [],
      });
      const seo = analyzeSEO(article);
      console.log(`Title: ${article.title}`);
      console.log(`SEO Score: ${seo.score}/100`);

      const outDir = resolve(__dirname, '..', 'content', 'drafts');
      await mkdir(outDir, { recursive: true });
      const outPath = resolve(outDir, `${Date.now()}.json`);
      await writeFile(outPath, JSON.stringify(article, null, 2));
      console.log(`Saved: ${outPath}`);
      break;
    }

    case 'build': {
      const db = createClient();
      const posts = await db.listPosts({ status: 'publish' });
      console.log(`Building ${posts.length} published posts...`);
      const { distDir, postCount } = await buildSite(posts);
      console.log(`Built: ${postCount} posts → ${distDir}`);
      break;
    }

    case 'deploy': {
      const { postCount } = await buildAndDeploy();
      console.log(`Deployed ${postCount} posts to Firebase Hosting`);
      break;
    }

    case 'check': {
      const db = createClient();
      const ok = await db.ping();
      console.log(ok ? 'Firestore connection OK' : 'Firestore connection FAILED');
      process.exit(ok ? 0 : 1);
      break;
    }

    default:
      console.log(`Firebase Blog Content Pipeline

Commands:
  pipeline "topic"           Generate, optimize, and publish
  pipeline --file post.md    Publish from markdown file
  generate "topic"           Generate article only (Claude API)
  build                      Build static site from Firestore
  deploy                     Build + deploy to Firebase Hosting
  check                      Test Firestore connection

Flags:
  --dry-run                  Skip Firestore save and deploy
  --status draft|publish     Post status (default: draft)
  --keywords kw1,kw2         Target keywords
  --file path.md             Use markdown file
  --deploy                   Auto-deploy after publish`);
  }
}

main().catch(err => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
