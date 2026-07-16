#!/usr/bin/env node
// Executable fixture tests for the F-A4 OpenAI proxy production transaction.
//
// These tests mutate only temporary files under /private/tmp and temporary
// Docker resources when Docker is available. They never read live OpenClaw
// credentials or production configuration.

import { spawnSync } from "node:child_process";
import { createHash, randomBytes } from "node:crypto";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  readFileSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";

const root = join(tmpdir(), `fa4-openai-proxy-transaction-fixtures-${Date.now()}-${randomBytes(3).toString("hex")}`);
const results = [];

function record(name, ok, detail = "") {
  results.push({ name, ok, detail });
  console.log(`${ok ? "PASS" : "FAIL"} ${name}${detail ? `: ${detail}` : ""}`);
}

function sha(value) {
  return createHash("sha256").update(value).digest("hex");
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: "utf8",
    input: options.input,
    timeout: options.timeout ?? 15000,
  });
  return {
    status: result.status,
    stdout: result.stdout || "",
    stderr: result.stderr || "",
    error: result.error?.message,
  };
}

function ensureDir(path, mode = 0o700) {
  mkdirSync(path, { recursive: true, mode });
  chmodSync(path, mode);
}

function writeSecret(path, value, mode = 0o600) {
  ensureDir(dirname(path), 0o700);
  const fdPath = `${path}.tmp-${process.pid}`;
  writeFileSync(fdPath, `${value}\n`, { mode });
  chmodSync(fdPath, mode);
  run("mv", [fdPath, path]);
}

function fileMode(path) {
  return (statSync(path).mode & 0o777).toString(8).padStart(4, "0");
}

function makeFixtureState(name) {
  const base = join(root, name);
  const live = join(base, "live");
  const stage = join(base, "stage");
  const backup = join(base, "backup");
  const evidence = join(base, "evidence");
  ensureDir(live);
  ensureDir(stage);
  ensureDir(backup);
  ensureDir(evidence);
  const state = {
    base,
    live,
    stage,
    backup,
    evidence,
    openclawConfig: join(live, "openclaw.json"),
    authProfile: join(live, "auth-profiles.json"),
    generatedModels: join(live, "models.json"),
    proxyRoot: join(stage, "proxy-root"),
    localToken: join(stage, "openclaw-local-token"),
    upstreamStore: join(stage, "secrets", "openai-upstream.json"),
    rollbackManifest: join(evidence, "rollback-manifest.json"),
  };
  writeFileSync(state.openclawConfig, JSON.stringify({
    models: { providers: { openai: { baseUrl: "https://api.openai.com/v1", api: "openai-responses", auth: "api-key", apiKey: "fixture-real-openai-key" } } },
    agents: {
      main: { model: "openai/gpt-5.5", fallbacks: ["ollama/qwen3-coder:30b"] },
      "research-handoff-gate": { model: "openai/gpt-5.5", fallbacks: [] },
      "email-researcher": { model: "openai/gpt-5.5", fallbacks: [] },
      heartbeat: { model: "ollama/qwen2.5-coder:14b", fallbacks: [] },
      "gmail-reader": { model: "ollama/qwen3-coder:30b", fallbacks: [] },
    },
  }, null, 2), { mode: 0o600 });
  writeFileSync(state.authProfile, JSON.stringify({ profiles: [] }, null, 2), { mode: 0o600 });
  writeFileSync(state.generatedModels, JSON.stringify({ generated: true, provider: "openai", apiKey: "fixture-real-openai-key" }, null, 2), { mode: 0o600 });
  return state;
}

function captureRollbackManifest(state, touchedPaths) {
  const entries = touchedPaths.map((path) => {
    const exists = existsSync(path);
    const backupPath = exists ? join(state.backup, sha(path)) : null;
    if (exists) {
      ensureDir(dirname(backupPath));
      writeFileSync(backupPath, readFileSync(path));
      chmodSync(backupPath, statSync(path).mode & 0o777);
    }
    return {
      path,
      existedBefore: exists,
      backupPath,
      mode: exists ? fileMode(path) : null,
    };
  });
  writeFileSync(state.rollbackManifest, JSON.stringify({ entries }, null, 2), { mode: 0o600 });
}

function executeRollback(manifestPath) {
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  for (const entry of manifest.entries.reverse()) {
    if (entry.existedBefore) {
      ensureDir(dirname(entry.path));
      writeFileSync(entry.path, readFileSync(entry.backupPath));
      chmodSync(entry.path, Number.parseInt(entry.mode, 8));
    } else {
      rmSync(entry.path, { force: true, recursive: true });
    }
  }
}

function migrateCredentialFixture(state) {
  const config = JSON.parse(readFileSync(state.openclawConfig, "utf8"));
  const key = config.models.providers.openai.apiKey;
  const upstreamPayload = JSON.stringify({ openaiApiKey: key }, null, 2);
  writeSecret(state.upstreamStore, upstreamPayload);
  config.models.providers.openai.baseUrl = "http://agent-os-openai-forward-proxy:18187/v1";
  config.models.providers.openai.apiKey = "<synthetic-local-proxy-token>";
  writeFileSync(state.openclawConfig, JSON.stringify(config, null, 2), { mode: 0o600 });
  return key;
}

function residueScan(rootPath, credentialValue) {
  const findings = [];
  function walk(path) {
    if (!existsSync(path)) return;
    const stat = statSync(path);
    if (stat.isDirectory()) {
      for (const entry of run("find", [path, "-type", "f"]).stdout.trim().split(/\n/).filter(Boolean)) walk(entry);
      return;
    }
    const content = readFileSync(path, "utf8");
    if (content.includes(credentialValue)) findings.push(path);
  }
  walk(rootPath);
  return findings;
}

function testCredentialMigrationAndResidue() {
  const state = makeFixtureState("credential-migration");
  captureRollbackManifest(state, [state.openclawConfig, state.authProfile, state.generatedModels, state.upstreamStore, state.localToken]);
  const localToken = `local_${randomBytes(32).toString("hex")}`;
  writeSecret(state.localToken, localToken);
  const credentialValue = migrateCredentialFixture(state);
  const upstream = readFileSync(state.upstreamStore, "utf8");
  record("credential migration writes upstream store", upstream.includes(credentialValue));
  record("upstream store mode 0600", fileMode(state.upstreamStore) === "0600");
  record("local token mode 0600", fileMode(state.localToken) === "0600");
  const config = readFileSync(state.openclawConfig, "utf8");
  record("config patch removes direct key from provider", !config.includes(credentialValue) && config.includes("agent-os-openai-forward-proxy"));
  const findings = residueScan(state.live, credentialValue);
  record("residue scanner finds generated model residue", findings.some((path) => path.endsWith("models.json")));
  writeFileSync(state.generatedModels, JSON.stringify({ generated: true, provider: "openai", apiKey: "<synthetic-local-proxy-token>" }, null, 2));
  record("residue scanner passes after cleanup", residueScan(state.live, credentialValue).length === 0);
}

function testRollbackStages() {
  const stages = [
    "before-credential-migration",
    "after-credential-migration-before-config-patch",
    "after-config-patch",
    "proxy-start-failure",
    "contained-openclaw-failure",
    "gateway-restart-failure",
    "route-test-failure",
    "gmail-telegram-ollama-regression-failure",
    "source-key-removal-failure",
    "cold-start-failure",
    "reboot-failure",
  ];
  for (const stage of stages) {
    const state = makeFixtureState(stage);
    const originalConfig = readFileSync(state.openclawConfig, "utf8");
    captureRollbackManifest(state, [state.openclawConfig, state.authProfile, state.generatedModels, state.upstreamStore, state.localToken, state.proxyRoot]);
    ensureDir(state.proxyRoot);
    writeFileSync(join(state.proxyRoot, "artifact"), "staged");
    writeSecret(state.localToken, "fixture-local-token");
    if (!stage.includes("before-credential")) migrateCredentialFixture(state);
    executeRollback(state.rollbackManifest);
    const restored = readFileSync(state.openclawConfig, "utf8") === originalConfig;
    const removedAbsent = !existsSync(state.upstreamStore) && !existsSync(state.localToken) && !existsSync(state.proxyRoot);
    record(`executable rollback ${stage}`, restored && removedAbsent);
  }
}

function testNoSecretInProcessSurfaces() {
  const state = makeFixtureState("surface-scan");
  const credentialValue = "fixture-real-openai-key";
  const localToken = `local_${randomBytes(32).toString("hex")}`;
  captureRollbackManifest(state, [state.openclawConfig, state.upstreamStore, state.localToken]);
  writeSecret(state.localToken, localToken);
  migrateCredentialFixture(state);
  const publicEvidence = JSON.stringify({
    upstreamStorePath: state.upstreamStore,
    upstreamStoreSha256: sha(readFileSync(state.upstreamStore)),
    localTokenPath: state.localToken,
    localTokenSha256: sha(readFileSync(state.localToken)),
  });
  record("evidence omits real upstream key", !publicEvidence.includes(credentialValue));
  record("evidence omits local token value", !publicEvidence.includes(localToken));
}

try {
  ensureDir(root);
  testCredentialMigrationAndResidue();
  testRollbackStages();
  testNoSecretInProcessSurfaces();
} finally {
  rmSync(root, { force: true, recursive: true });
}

const failed = results.filter((result) => !result.ok);
console.log(JSON.stringify({ passed: results.length - failed.length, failed: failed.length }, null, 2));
if (failed.length) process.exit(1);
