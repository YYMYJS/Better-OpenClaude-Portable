#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const [, , command, storePath, envPath, selectedIndex] = process.argv;

function readEnv(file) {
  const env = {};
  if (!file || !fs.existsSync(file)) return env;
  const text = fs.readFileSync(file, 'utf8').replace(/\r/g, '');
  for (const line of text.split('\n')) {
    if (!line || /^\s*#/.test(line) || !line.includes('=')) continue;
    const idx = line.indexOf('=');
    const key = line.slice(0, idx).trim();
    const value = line.slice(idx + 1);
    if (key) env[key] = value;
  }
  return env;
}

function writeEnv(file, env) {
  const ordered = [
    'AI_PROVIDER',
    'AI_DISPLAY_MODEL',
    'CLAUDE_CODE_USE_OPENAI',
    'CLAUDE_CODE_USE_GEMINI',
    'OPENAI_API_KEY',
    'OPENAI_BASE_URL',
    'OPENAI_MODEL',
    'ANTHROPIC_API_KEY',
    'ANTHROPIC_AUTH_TOKEN',
    'ANTHROPIC_BASE_URL',
    'ANTHROPIC_MODEL',
    'GEMINI_API_KEY',
    'GEMINI_MODEL',
    'CLAUDE_CODE_AGENT_LIST_IN_MESSAGES',
    'CLAUDE_CODE_SIMPLE',
  ];
  const lines = [
    '# ========================================================',
    '# Portable AI - Master Switchboard (Updated)',
    '# ========================================================',
  ];
  for (const key of ordered) {
    if (env[key] !== undefined && env[key] !== '') lines.push(`${key}=${env[key]}`);
  }
  for (const key of Object.keys(env).sort()) {
    if (!ordered.includes(key) && env[key] !== undefined && env[key] !== '') lines.push(`${key}=${env[key]}`);
  }
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${lines.join('\n')}\n`, 'utf8');
}

function readStore(file) {
  try {
    if (file && fs.existsSync(file)) {
      const parsed = JSON.parse(fs.readFileSync(file, 'utf8'));
      if (parsed && Array.isArray(parsed.profiles)) return parsed;
    }
  } catch {}
  return { profiles: [] };
}

function writeStore(file, store) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(store, null, 2)}\n`, 'utf8');
}

function providerType(env) {
  if (env.AI_PROVIDER === 'custom') return env.CLAUDE_CODE_USE_OPENAI === '0' ? 'custom-anthropic' : 'custom-openai';
  if (env.AI_PROVIDER === 'openai') {
    const url = env.OPENAI_BASE_URL || '';
    if (url.includes('openrouter')) return 'openrouter';
    if (url.includes('integrate.api.nvidia.com')) return 'nvidia';
    if (url.includes('api.deepseek.com')) return 'deepseek';
    if (url.includes('localhost')) return 'ollama';
  }
  return env.AI_PROVIDER || 'unknown';
}

function modelOf(env) {
  return env.AI_DISPLAY_MODEL || env.OPENAI_MODEL || env.ANTHROPIC_MODEL || env.GEMINI_MODEL || 'unknown-model';
}

function urlOf(env) {
  return env.OPENAI_BASE_URL || env.ANTHROPIC_BASE_URL || '';
}

function keyOf(env) {
  return env.OPENAI_API_KEY || env.ANTHROPIC_AUTH_TOKEN || env.ANTHROPIC_API_KEY || env.GEMINI_API_KEY || '';
}

function maskKey(key) {
  if (!key) return 'not set';
  if (key.length <= 10) return `${key[0] || ''}****`;
  return `${key.slice(0, 6)}****${key.slice(-4)}`;
}

function comparableEnv(env) {
  const keys = Object.keys(env).filter((key) => env[key] !== undefined && env[key] !== '').sort();
  return JSON.stringify(keys.map((key) => [key, env[key]]));
}

function makeProfile(env, previous) {
  const now = new Date().toISOString();
  const type = providerType(env);
  const model = modelOf(env);
  const url = urlOf(env);
  const safeModel = model.replace(/[^a-zA-Z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 48) || 'model';
  return {
    id: previous?.id || `${now.replace(/[-:.TZ]/g, '').slice(0, 14)}-${type}-${safeModel}`,
    name: `${type} | ${model}${url ? ` | ${url}` : ''}`,
    createdAt: previous?.createdAt || now,
    lastUsedAt: now,
    env,
  };
}

function saveProfile() {
  const env = readEnv(envPath);
  if (!env.AI_PROVIDER) return;
  const store = readStore(storePath);
  const signature = comparableEnv(env);
  const existingIndex = store.profiles.findIndex((profile) => comparableEnv(profile.env || {}) === signature);
  const existing = existingIndex >= 0 ? store.profiles[existingIndex] : undefined;
  const profile = makeProfile(env, existing);
  if (existingIndex >= 0) store.profiles[existingIndex] = profile;
  else store.profiles.push(profile);
  writeStore(storePath, store);
}

function listProfiles() {
  const store = readStore(storePath);
  if (!store.profiles.length) {
    console.log('NO_PROFILES');
    return;
  }
  store.profiles.forEach((profile, index) => {
    const env = profile.env || {};
    const type = providerType(env);
    const model = modelOf(env);
    const url = urlOf(env) || 'default-url';
    const key = maskKey(keyOf(env));
    console.log(`${index + 1}) ${type} | ${model} | ${url} | key: ${key}`);
  });
}

function switchProfile() {
  const store = readStore(storePath);
  const index = Number(selectedIndex) - 1;
  if (!Number.isInteger(index) || index < 0 || index >= store.profiles.length) {
    console.error('Invalid profile selection.');
    process.exit(1);
  }
  const profile = store.profiles[index];
  profile.lastUsedAt = new Date().toISOString();
  writeEnv(envPath, profile.env || {});
  writeStore(storePath, store);
  console.log(`Switched to: ${profile.name}`);
}

if (!command || !storePath || !envPath) {
  console.error('Usage: provider_profiles.js <save|list|switch> <storePath> <envPath> [index]');
  process.exit(1);
}

if (command === 'save') saveProfile();
else if (command === 'list') listProfiles();
else if (command === 'switch') switchProfile();
else {
  console.error(`Unknown command: ${command}`);
  process.exit(1);
}
