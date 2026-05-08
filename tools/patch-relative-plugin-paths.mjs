/**
 * patch-relative-plugin-paths.mjs
 *
 * Patches cli.mjs to store relative installPath values in installed_plugins.json
 * instead of absolute paths. This makes the portable environment work across
 * different drive letters on different computers.
 *
 * This script is called by engine/package.json postinstall, so it runs after
 * every `npm install` or `npm update` in the engine directory. The patch is
 * re-applied to the newly installed cli.mjs each time.
 */

import { readFileSync, writeFileSync, existsSync } from "fs";
import { dirname, resolve, relative } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const engineDir = resolve(__dirname, "..", "engine");
const cliMjsPath = resolve(engineDir, "node_modules/@gitlawb/openclaude/dist/cli.mjs");

if (!existsSync(cliMjsPath)) {
  console.log("patch-relative-plugin-paths: cli.mjs not found, skipping");
  process.exit(0);
}

const content = readFileSync(cliMjsPath, "utf-8");

// Check if already patched
if (content.includes("relative(join93(getPluginsDirectory(), \"cache\"), finalPath)")) {
  console.log("patch-relative-plugin-paths: already patched");
  process.exit(0);
}

// Try exact pattern first
const oldPattern = `addInstalledPlugin(pluginId, {
    version: version2,
    installedAt: now2,
    lastUpdated: now2,
    installPath: finalPath,
    gitCommitSha
  }, scope, projectPath);`;

const newCode = `addInstalledPlugin(pluginId, {
    version: version2,
    installedAt: now2,
    lastUpdated: now2,
    installPath: finalPath ? relative(join93(getPluginsDirectory(), "cache"), finalPath) : finalPath,
    gitCommitSha
  }, scope, projectPath);`;

if (content.includes(oldPattern)) {
  const newContent = content.replace(oldPattern, newCode);
  writeFileSync(cliMjsPath, newContent, "utf-8");
  console.log("patch-relative-plugin-paths: patched successfully");
  process.exit(0);
}

// If exact pattern not found, try a more flexible regex search
// This handles cases where variable names or whitespace might differ slightly between versions
const flexiblePattern = /addInstalledPlugin\(pluginId,\s*\{[\s\S]*?installPath:\s*finalPath,[\s\S]*?\}, scope, projectPath\);/;

if (flexiblePattern.test(content)) {
  const newContent = content.replace(flexiblePattern, newCode);
  writeFileSync(cliMjsPath, newContent, "utf-8");
  console.log("patch-relative-plugin-paths: patched successfully (flexible match)");
  process.exit(0);
}

// Pattern not found - this could mean the engine code was restructured in an update
// Don't fail the postinstall, just warn
console.log("patch-relative-plugin-paths: WARNING - target pattern not found in cli.mjs");
console.log("patch-relative-plugin-paths: The relative path fix may not be applied.");
console.log("patch-relative-plugin-paths: Plugin installs may still use absolute paths on this engine version.");
process.exit(0);
