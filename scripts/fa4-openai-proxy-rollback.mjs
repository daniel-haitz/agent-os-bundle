#!/usr/bin/env node
// Executable rollback helper for the F-A4 OpenAI proxy transaction.
//
// This helper restores or removes paths listed in a rollback manifest. It is
// intentionally manifest-driven and refuses to operate without an explicit
// manifest path. Production use requires operator review of the manifest first.

import { chmodSync, copyFileSync, existsSync, mkdirSync, readFileSync, rmSync } from "node:fs";
import { dirname } from "node:path";

if (process.argv.length !== 3) {
  console.error("Usage: fa4-openai-proxy-rollback.mjs <rollback-manifest.json>");
  process.exit(64);
}

const manifestPath = process.argv[2];
if (!existsSync(manifestPath)) {
  console.error(`Rollback manifest missing: ${manifestPath}`);
  process.exit(66);
}

const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
if (!Array.isArray(manifest.entries)) {
  console.error("Rollback manifest lacks entries[]");
  process.exit(65);
}

for (const entry of [...manifest.entries].reverse()) {
  if (!entry.path || typeof entry.path !== "string") {
    console.error("Rollback entry missing path");
    process.exit(65);
  }
  if (entry.existedBefore) {
    if (!entry.backupPath || !existsSync(entry.backupPath)) {
      console.error(`Rollback backup missing for ${entry.path}`);
      process.exit(66);
    }
    mkdirSync(dirname(entry.path), { recursive: true });
    copyFileSync(entry.backupPath, entry.path);
    if (entry.mode) chmodSync(entry.path, Number.parseInt(entry.mode, 8));
    console.log(`RESTORED ${entry.path}`);
  } else if (existsSync(entry.path)) {
    rmSync(entry.path, { recursive: true, force: true });
    console.log(`REMOVED ${entry.path}`);
  } else {
    console.log(`ABSENT ${entry.path}`);
  }
}

console.log("ROLLBACK VERIFIED: PASS");
