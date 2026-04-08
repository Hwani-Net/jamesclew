#!/usr/bin/env node
/**
 * Obsidian Persona Enhancer
 * Reads existing persona .md files, detects missing sections,
 * and enhances them using OpenRouter LLM (with key rotation).
 */
import { readFileSync, writeFileSync, readdirSync } from 'fs';
import { join, resolve } from 'path';

const PERSONAS_DIR = resolve(process.env.HOME || process.env.USERPROFILE, 'Obsidian-Vault/03-knowledge/personas');
const KEYS_FILE = resolve(process.env.HOME || process.env.USERPROFILE, '.claude/openrouter-keys.json');
const MODEL = 'qwen/qwen3.6-plus:free';
const REQUIRED_SECTIONS = ['## 목표 (Goals)', '## 제약조건 (Constraints)', '## 사용 맥락 (Scenario)', '## 대표 발화'];

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

let keys = JSON.parse(readFileSync(KEYS_FILE, 'utf-8'));
let keyIndex = 0;
const log = (msg) => process.stderr.write(`[enhancer] ${msg}\n`);

async function notifyTelegram(msg) {
  try {
    await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chat_id: CHAT_ID, text: msg })
    });
  } catch {}
}

function getNextKey() {
  const key = keys[keyIndex];
  keyIndex = (keyIndex + 1) % keys.length;
  return key;
}

function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) return { frontmatter: '', body: content };
  return { frontmatter: match[1], body: match[2] };
}

function getMissingSections(body) {
  return REQUIRED_SECTIONS.filter(s => !body.includes(s));
}

async function callLLM(prompt, retries = 3) {
  for (let i = 0; i < retries; i++) {
    const key = getNextKey();
    try {
      const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${key}`,
          'Content-Type': 'application/json',
          'X-Title': 'JamesClaw Persona Enhancer'
        },
        body: JSON.stringify({
          model: MODEL,
          messages: [
            { role: 'system', content: '당신은 한국 시장에 특화된 UX 리서치 전문가입니다. 기존 페르소나를 보강합니다. 마크다운 형식으로만 응답하세요. 추가 설명이나 인사말 없이 섹션 내용만 출력하세요.' },
            { role: 'user', content: prompt }
          ],
          max_tokens: 600,
          temperature: 0.7
        })
      });

      if (res.status === 429 || res.status === 402) {
        log(`Key #${keyIndex} exhausted (${res.status}), rotating...`);
        continue;
      }

      const data = await res.json();
      return data.choices?.[0]?.message?.content || '';
    } catch (e) {
      log(`Error: ${e.message}, retrying...`);
    }
  }
  return '';
}

async function enhancePersona(filePath) {
  const content = readFileSync(filePath, 'utf-8');
  const { frontmatter, body } = parseFrontmatter(content);
  const missing = getMissingSections(body);

  if (missing.length === 0) {
    return { file: filePath, status: 'skip', missing: 0 };
  }

  // Extract persona info for context
  const nameMatch = body.match(/당신은 \*\*(.+?)\*\*/);
  const name = nameMatch ? nameMatch[1] : 'unknown';
  const bgMatch = body.match(/## 배경\n([\s\S]*?)(?=\n##|$)/);
  const background = bgMatch ? bgMatch[1].trim() : '';
  const painMatch = body.match(/## 불편한 점[\s\S]*?\n([\s\S]*?)(?=\n##|$)/);
  const painPoints = painMatch ? painMatch[1].trim() : '';

  const prompt = `다음 페르소나의 누락된 섹션만 생성해주세요.

페르소나: ${name}
배경: ${background}
불편한 점: ${painPoints}

생성할 섹션: ${missing.join(', ')}

각 섹션의 형식:
- "## 목표 (Goals)" → bullet 2개 (이 사람이 달성하려는 것)
- "## 제약조건 (Constraints)" → bullet 2개 (시간/예산/기술/환경 제약)
- "## 사용 맥락 (Scenario)" → 1-2줄 (이 사람이 제품을 사용하는 구체적 상황)
- "## 대표 발화" → > "인용문" 형식 1개 (이 사람이 실제로 할 법한 말)

누락된 섹션만 출력하세요. 기존 섹션은 출력하지 마세요.`;

  const generated = await callLLM(prompt);

  if (!generated) {
    return { file: filePath, status: 'error', missing: missing.length };
  }

  // Insert generated sections before "## 말투" or at the end
  let newBody = body;
  const insertPoint = body.indexOf('## 말투');
  if (insertPoint > 0) {
    newBody = body.slice(0, insertPoint) + generated.trim() + '\n\n' + body.slice(insertPoint);
  } else {
    newBody = body + '\n\n' + generated.trim();
  }

  writeFileSync(filePath, `---\n${frontmatter}\n---\n${newBody}`, 'utf-8');
  return { file: filePath, status: 'enhanced', missing: missing.length };
}

async function main() {
  const files = readdirSync(PERSONAS_DIR)
    .filter(f => f.endsWith('.md') && !f.startsWith('_'))
    .map(f => join(PERSONAS_DIR, f));

  log(`Found ${files.length} persona files`);
  await notifyTelegram(`🔧 페르소나 보강 시작 (${files.length}개 파일)`);

  let enhanced = 0, skipped = 0, errors = 0;

  for (const file of files) {
    const result = await enhancePersona(file);
    const shortName = file.split('/').pop() || file.split('\\').pop();

    if (result.status === 'enhanced') {
      enhanced++;
      log(`✅ ${shortName} — added ${result.missing} sections`);
    } else if (result.status === 'skip') {
      skipped++;
      log(`⏭️ ${shortName} — already complete`);
    } else {
      errors++;
      log(`❌ ${shortName} — failed`);
    }

    // Progress notification every 10 files
    if ((enhanced + skipped + errors) % 10 === 0) {
      await notifyTelegram(`📊 진행 ${enhanced + skipped + errors}/${files.length} (보강: ${enhanced}, 스킵: ${skipped}, 에러: ${errors})`);
    }

    // Rate limit: 1 request per 2 seconds
    if (result.status === 'enhanced') {
      await new Promise(r => setTimeout(r, 2000));
    }
  }

  const summary = `✅ 페르소나 보강 완료!\n보강: ${enhanced}개 | 스킵: ${skipped}개 | 에러: ${errors}개`;
  log(`\n${summary}`);
  await notifyTelegram(summary);
}

main().catch(e => { log(`Fatal: ${e.message}`); process.exit(1); });
