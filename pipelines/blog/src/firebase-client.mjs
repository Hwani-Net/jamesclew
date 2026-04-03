/**
 * Firebase client for blog content management.
 * Uses Firebase Admin SDK REST API via native fetch (no SDK dependency).
 * Requires: FIREBASE_PROJECT_ID, GOOGLE_APPLICATION_CREDENTIALS (or FIREBASE_TOKEN)
 */

import { readFile } from 'fs/promises';

export class FirestoreClient {
  #projectId;
  #token;

  constructor({ projectId, token }) {
    if (!projectId) throw new Error('FIREBASE_PROJECT_ID required');
    this.#projectId = projectId;
    this.#token = token;
  }

  get #baseUrl() {
    return `https://firestore.googleapis.com/v1/projects/${this.#projectId}/databases/(default)/documents`;
  }

  async #getToken() {
    if (this.#token) return this.#token;
    // Use gcloud CLI for token (works on dev machines with gcloud configured)
    const { execSync } = await import('child_process');
    this.#token = execSync('gcloud auth print-access-token', { encoding: 'utf-8' }).trim();
    return this.#token;
  }

  async #request(method, path, body = null) {
    const token = await this.#getToken();
    const url = `${this.#baseUrl}${path}`;
    const opts = {
      method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    };
    if (body) opts.body = JSON.stringify(body);

    const res = await fetch(url, opts);
    const data = await res.json();
    if (!res.ok) {
      throw new Error(`Firestore ${method} ${path} → ${res.status}: ${JSON.stringify(data.error?.message || data)}`);
    }
    return data;
  }

  // --- Firestore value encoding ---

  static encode(value) {
    if (value === null || value === undefined) return { nullValue: null };
    if (typeof value === 'string') return { stringValue: value };
    if (typeof value === 'number') return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
    if (typeof value === 'boolean') return { booleanValue: value };
    if (value instanceof Date) return { timestampValue: value.toISOString() };
    if (Array.isArray(value)) return { arrayValue: { values: value.map(v => FirestoreClient.encode(v)) } };
    if (typeof value === 'object') {
      const fields = {};
      for (const [k, v] of Object.entries(value)) {
        fields[k] = FirestoreClient.encode(v);
      }
      return { mapValue: { fields } };
    }
    return { stringValue: String(value) };
  }

  static decode(firestoreValue) {
    if ('stringValue' in firestoreValue) return firestoreValue.stringValue;
    if ('integerValue' in firestoreValue) return parseInt(firestoreValue.integerValue);
    if ('doubleValue' in firestoreValue) return firestoreValue.doubleValue;
    if ('booleanValue' in firestoreValue) return firestoreValue.booleanValue;
    if ('nullValue' in firestoreValue) return null;
    if ('timestampValue' in firestoreValue) return new Date(firestoreValue.timestampValue);
    if ('arrayValue' in firestoreValue) return (firestoreValue.arrayValue.values || []).map(v => FirestoreClient.decode(v));
    if ('mapValue' in firestoreValue) {
      const obj = {};
      for (const [k, v] of Object.entries(firestoreValue.mapValue.fields || {})) {
        obj[k] = FirestoreClient.decode(v);
      }
      return obj;
    }
    return null;
  }

  #encodeDoc(data) {
    const fields = {};
    for (const [key, value] of Object.entries(data)) {
      fields[key] = FirestoreClient.encode(value);
    }
    return { fields };
  }

  #decodeDoc(doc) {
    const result = {};
    for (const [key, value] of Object.entries(doc.fields || {})) {
      result[key] = FirestoreClient.decode(value);
    }
    const nameParts = doc.name.split('/');
    result._id = nameParts[nameParts.length - 1];
    return result;
  }

  // --- CRUD ---

  async createPost(slug, data) {
    const doc = this.#encodeDoc({
      ...data,
      slug,
      status: data.status || 'draft',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
    return this.#decodeDoc(
      await this.#request('PATCH', `/posts/${slug}`, doc)
    );
  }

  async getPost(slug) {
    return this.#decodeDoc(
      await this.#request('GET', `/posts/${slug}`)
    );
  }

  async updatePost(slug, fields) {
    const doc = this.#encodeDoc({
      ...fields,
      updatedAt: new Date().toISOString(),
    });
    const updateMask = Object.keys(fields).concat('updatedAt').map(f => `updateMask.fieldPaths=${f}`).join('&');
    return this.#decodeDoc(
      await this.#request('PATCH', `/posts/${slug}?${updateMask}`, doc)
    );
  }

  async listPosts({ status } = {}) {
    const result = await this.#request('GET', '/posts?pageSize=100');
    const docs = (result.documents || []).map(d => this.#decodeDoc(d));
    if (status) return docs.filter(d => d.status === status);
    return docs;
  }

  async deletePost(slug) {
    await this.#request('DELETE', `/posts/${slug}`);
  }

  // --- Health ---

  async ping() {
    try {
      await this.#request('GET', '/posts?pageSize=1');
      return true;
    } catch {
      return false;
    }
  }
}

export function createClient() {
  return new FirestoreClient({
    projectId: process.env.FIREBASE_PROJECT_ID,
    token: process.env.FIREBASE_TOKEN || null,
  });
}
