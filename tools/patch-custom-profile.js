#!/usr/bin/env node
/**
 * patch-custom-profile.js
 *
 * Permanently patches OpenClaude's cli.mjs to add proper "custom" profile support.
 * This patch survives npm update because it's re-applied by a postinstall hook
 * in engine/package.json.
 *
 * Run this manually if npm update wipes the patch:
 *   node tools/patch-custom-profile.js
 */

const fs = require('fs');
const path = require('path');

const CLI_PATH = path.join(__dirname, '..', 'engine', 'node_modules', '@gitlawb', 'openclaude', 'dist', 'cli.mjs');

const CUSTOM_HANDLER_CODE = `  if (options.profile === "custom") {
    console.error('[DEBUG] CUSTOM PROFILE HANDLER REACHED');
    const customBaseUrl = sanitizeProviderConfigValue(processEnv.ANTHROPIC_BASE_URL) || sanitizeProviderConfigValue(persistedEnv.ANTHROPIC_BASE_URL);
    const customApiKey = sanitizeApiKey(processEnv.ANTHROPIC_API_KEY) || sanitizeApiKey(persistedEnv.ANTHROPIC_API_KEY);
    const customModel = normalizeProfileModel(sanitizeProviderConfigValue(processEnv.ANTHROPIC_MODEL)) || normalizeProfileModel(sanitizeProviderConfigValue(persistedEnv.ANTHROPIC_MODEL)) || "claude-sonnet-4-6";
    const result = buildCompatibilityProcessEnv({
      processEnv,
      compatibilityMode: "anthropic",
      profileEnv: {
        ...customBaseUrl ? { ANTHROPIC_BASE_URL: customBaseUrl } : {},
        ANTHROPIC_MODEL: customModel,
        ...customApiKey ? { ANTHROPIC_API_KEY: customApiKey } : {},
        __OC_CUSTOM_PROFILE: "1"
      }
    });
    return result;
  }
`;

function patchIsProviderProfile(content) {
  // Check if "custom" is already in isProviderProfile
  if (content.includes('value === "custom"')) {
    console.log('[patch-custom-profile] isProviderProfile already includes "custom"');
    return content;
  }

  // Add "custom" to the isProviderProfile return statement
  const pattern = /(function isProviderProfile\(value\) \{\s*return )([^;]+)(;?\s*\})/;
  const match = content.match(pattern);
  if (!match) {
    console.error('[patch-custom-profile] Could not find isProviderProfile function');
    return null;
  }

  const replacement = `$1$2 || value === "custom"$3`;
  const result = content.replace(pattern, replacement);
  console.log('[patch-custom-profile] Patched isProviderProfile to include "custom"');
  return result;
}

function patchCustomHandler(content) {
  // Check if custom handler already exists
  if (content.includes('options.profile === "custom"') && content.includes('__OC_CUSTOM_PROFILE: "1"')) {
    console.log('[patch-custom-profile] Custom profile handler already exists');
    return content;
  }

  // Insert before bedrock profile block
  const bedrockPattern = /\n  if \(options\.profile === "bedrock"\) \{/;
  const match = content.match(bedrockPattern);
  if (!match) {
    console.error('[patch-custom-profile] Could not find insertion point (bedrock profile block)');
    return null;
  }

  const insertPos = match.index + 1;
  const result = content.slice(0, insertPos) + CUSTOM_HANDLER_CODE + content.slice(insertPos);
  console.log('[patch-custom-profile] Inserted custom profile handler before bedrock block');
  return result;
}

function patchStartupValidation(content) {
  // Check if the __OC_CUSTOM_PROFILE bypass is already in place
  if (content.includes('const isCustomProfile = startupEnv.__OC_CUSTOM_PROFILE === "1"')) {
    console.log('[patch-custom-profile] Startup validation bypass already exists');
    return content;
  }

  // Find where isCustomProfile would be set (after startupEnv assignment)
  // Look for: const startupProfileError = await getProviderValidationError(startupEnv);
  const pattern = /const startupProfileError = await getProviderValidationError\(startupEnv\);/;
  const match = content.match(pattern);
  if (!match) {
    console.error('[patch-custom-profile] Could not find startup validation error location');
    return null;
  }

  // Insert isCustomProfile check after startupProfileError
  const insertCode = `const startupProfileError = await getProviderValidationError(startupEnv);
    const isCustomProfile = startupEnv.__OC_CUSTOM_PROFILE === "1";`;

  const result = content.replace(pattern, insertCode);
  console.log('[patch-custom-profile] Added isCustomProfile check for startup validation bypass');
  return result;
}

function patch() {
  if (!fs.existsSync(CLI_PATH)) {
    console.error('[patch-custom-profile] cli.mjs not found at:', CLI_PATH);
    process.exit(1);
  }

  let content = fs.readFileSync(CLI_PATH, 'utf8');
  let patched = false;

  // Patch 1: isProviderProfile
  const result1 = patchIsProviderProfile(content);
  if (result1 === null) {
    process.exit(1);
  }
  if (result1 !== content) {
    content = result1;
    patched = true;
  }

  // Patch 2: Custom handler
  const result2 = patchCustomHandler(content);
  if (result2 === null) {
    process.exit(1);
  }
  if (result2 !== content) {
    content = result2;
    patched = true;
  }

  // Patch 3: Startup validation bypass
  const result3 = patchStartupValidation(content);
  if (result3 === null) {
    process.exit(1);
  }
  if (result3 !== content) {
    content = result3;
    patched = true;
  }

  if (patched) {
    fs.writeFileSync(CLI_PATH, content, 'utf8');
    console.log('[patch-custom-profile] Successfully patched cli.mjs with custom profile support');
  } else {
    console.log('[patch-custom-profile] All patches already applied - no changes needed');
  }
}

patch();
