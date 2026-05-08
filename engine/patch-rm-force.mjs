// Post-install patch: On Windows, wrap all fs/promises.rm() calls to first run
// `attrib -R` so read-only .git pack files (EACCES) don't break plugin cleanup.
// Runs after every `npm install` / `npm update`. Also runs at START.bat launch.

import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const cliPath = join(__dirname, 'node_modules', '@gitlawb', 'openclaude', 'dist', 'cli.mjs');

try {
  let code = readFileSync(cliPath, 'utf-8');
  let modified = false;

  // 1. Patch getFsImplementation().rm() — the main fs wrapper
  const rmMethodPattern = `async rm(fsPath, options) {
      return rmPromise(fsPath, options);
    }`;
  const rmMethodReplacement = `async rm(fsPath, options) {
      if (process.platform === "win32" && typeof fsPath === "string") {
        try { (await import("child_process")).execSync(\`attrib -R "\${fsPath}" /S /D\`, { timeout: 3e3, windowsHide: true }); } catch {}
      }
      return rmPromise(fsPath, { ...options, force: true });
    }`;

  if (code.includes(rmMethodPattern)) {
    code = code.replace(rmMethodPattern, rmMethodReplacement);
    modified = true;
    console.log('[patch-rm-force] ✓ Patched fsImplementation.rm()');
  } else if (!code.includes(rmMethodReplacement)) {
    console.log('[patch-rm-force] ⚠ Could not find fsImplementation.rm() pattern - may already be updated');
  } else {
    console.log('[patch-rm-force] ✓ fsImplementation.rm() already patched');
  }

  // 2. Patch ALL `import { rm as rmX } from "fs/promises"` — these bypass fsImplementation
  //    Wrap each with attrib -R on Windows + force:true
  const importPattern = /import\s*\{([^}]*)\}\s*from\s*["']fs\/promises["']/g;
  let match;
  while ((match = importPattern.exec(code)) !== null) {
    const fullStmt = match[0];
    const imports = match[1];
    const rmMatch = imports.match(/\brm\s+as\s+(\w+)\b/);
    if (!rmMatch) continue;
    const name = rmMatch[1];  // e.g. "rm9"
    // Skip if already wrapped
    const wrapperPattern = `const ${name} = (`;
    if (code.slice(match.index + fullStmt.length).startsWith(`\nconst ${name} = (`)) continue;

    // Insert wrapper right after the import statement
    const wrapperCode = `
const ${name} = (...args) => {
  if (process.platform === "win32" && typeof args[0] === "string") {
    try { require("child_process").execSync(\`attrib -R "\${args[0]}" /S /D\`, { timeout: 3e3, windowsHide: true }); } catch {}
  }
  return args[0] ? 1 : 0;
};
`;
    // We need to use Promise.resolve().then() to avoid circular issues
    // Actually, simpler: just rename import and wrap
    const oldImport = fullStmt;
    const newImport = fullStmt.replace(`rm as ${name}`, `rm as _${name}`);
    const wrapperAtEnd = `\nconst ${name} = (...args) => { const p = typeof args[0] === "string" && process.platform === "win32" ? require("child_process").execSync(\`attrib -R "\${args[0]}" /S /D\`, { timeout: 3e3, windowsHide: true }) : void 0; return _${name}(...args); };`;

    code = code.replace(oldImport, newImport);
    // Find a good insertion point - right after the import block
    const importEndIndex = code.indexOf('\n', match.index) + 1;
    code = code.slice(0, importEndIndex) + wrapperAtEnd + code.slice(importEndIndex);
    modified = true;
    console.log(`[patch-rm-force] ✓ Wrapped ${name} from fs/promises.rm`);
  }

  // 3. Remove leftover temp directories at startup too
  //    No change needed - attrib handles the permissions

  if (!modified) {
    // Check if already fully patched (all rm imports have wrappers)
    const rmImports = code.match(/import\s*\{[^}]*rm\s+as\s+\w+[^}]*\}\s*from\s*["']fs\/promises["']/g) || [];
    const unwrapped = rmImports.filter(imp => {
      const name = imp.match(/rm\s+as\s+(\w+)/)?.[1];
      if (!name) return false;
      const afterImport = code.slice(code.indexOf(imp) + imp.length);
      return !afterImport.startsWith(`\nconst ${name} =`);
    });
    if (unwrapped.length === 0) {
      console.log('[patch-rm-force] ✓ Already fully patched, no changes needed.');
    } else {
      console.log(`[patch-rm-force] ⚠ ${unwrapped.length} imports still unwrapped. They may cause issues on Windows.`);
    }
    process.exit(0);
  }

  writeFileSync(cliPath, code, 'utf-8');
  console.log('[patch-rm-force] ✓ All patches applied successfully.');
} catch (err) {
  console.error(`[patch-rm-force] ERROR: ${err.message}`);
  process.exit(1);
}
