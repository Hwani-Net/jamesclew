import { config } from 'dotenv';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
config({ path: resolve(__dirname, '..', '.env') });

export const FIREBASE = {
  projectId: process.env.FIREBASE_PROJECT_ID,
  token: process.env.FIREBASE_TOKEN || null,
};

export const SITE = {
  name: process.env.SITE_NAME || 'JamesClaw Blog',
  url: process.env.SITE_URL || 'https://example.com',
};

export const ADSENSE = {
  pubId: process.env.ADSENSE_PUB_ID || '',
};

export const CONTENT = {
  locale: process.env.TARGET_LOCALE || 'ko_KR',
  defaultCategory: process.env.DEFAULT_CATEGORY || 'technology',
  outputDir: resolve(__dirname, '..', 'content'),
};

export const ANTHROPIC = {
  apiKey: process.env.ANTHROPIC_API_KEY,
};
