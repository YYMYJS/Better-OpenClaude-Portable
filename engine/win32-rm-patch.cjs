// Node.js --require preload: wraps fs.promises.rm on Windows to run `attrib -R`
// before deletion, so read-only .git pack files don't cause EACCES.
// This runs BEFORE any ESM import, so ALL `import { rm } from "fs/promises"`
// in the engine code receive the patched version automatically.
'use strict';
if (process.platform === 'win32') {
  const fs = require('fs');
  const cp = require('child_process');
  const origRm = fs.promises.rm.bind(fs.promises);
  fs.promises.rm = function patchedRm(path, options) {
    console.error(`[rm-patch] rm called: ${path}`);
    if (typeof path === 'string') {
      const cmd = `attrib -R "${path}" /S /D`;
      try { cp.execSync(cmd, { timeout: 3000, windowsHide: true }); console.error(`[rm-patch] attrib OK: ${path}`); } catch (e) { console.error(`[rm-patch] attrib failed: ${e.message}`); }
    }
    return origRm(path, options);
  };
  // Also patch the sync version
  const origRmSync = fs.rmSync;
  if (origRmSync) {
    fs.rmSync = function patchedRmSync(path, options) {
      if (typeof path === 'string') {
        try { cp.execSync(`attrib -R "${path}" /S /D`, { timeout: 3000, windowsHide: true }); } catch {}
      }
      return origRmSync(path, options);
    };
  }
}
