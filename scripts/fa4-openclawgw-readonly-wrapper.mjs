#!/usr/bin/env node
// Fixed-command OpenClaw runtime-identity validation wrapper for F-A4.
//
// This script must be invoked by the operator-owned read-only validation
// harness as root. It accepts exactly one approved operation id, drops to the
// openclawgw identity, then executes a fixed argv with shell disabled.

import { spawnSync } from "node:child_process";

const OPENCLAW_BIN = "/Users/agent/.local/bin/openclaw";
const NODE_BIN = "/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node";
const BROKER_CLIENT = "/Users/agent/.openclaw/scripts/gmail-broker-client.mjs";
const GATE_SCRIPT = "/Users/agent/.openclaw/scripts/research-handoff-gate.mjs";
const GATE_TEST = "/Users/agent/.openclaw/scripts/test-research-handoff-gate.mjs";

const FIXED_ENV = {
  HOME: "/Users/agent",
  OPENCLAW_CONFIG_PATH: "/Users/agent/.openclaw/openclaw.json",
  OPENCLAW_STATE_DIR: "/Users/agent/.openclaw/state",
  PATH: [
    "/Users/agent/.local/bin",
    "/Users/agent/.local/openclaw/tools/node-v22.22.0/bin",
    "/opt/homebrew/bin",
    "/usr/local/bin",
    "/usr/bin",
    "/bin",
    "/usr/sbin",
    "/sbin",
  ].join(":"),
};

const OPERATIONS = Object.freeze({
  "openclaw-version": [OPENCLAW_BIN, ["--version"]],
  "openclaw-security-audit": [OPENCLAW_BIN, ["security", "audit", "--json"]],
  "openclaw-security-audit-deep": [OPENCLAW_BIN, ["security", "audit", "--deep", "--json"]],
  "openclaw-doctor-lint": [OPENCLAW_BIN, ["doctor", "--lint", "--json"]],
  "openclaw-secrets-audit": [OPENCLAW_BIN, ["secrets", "audit", "--json"]],
  "sandbox-main": [OPENCLAW_BIN, ["sandbox", "explain", "--agent", "main", "--json"]],
  "sandbox-gmail-reader": [OPENCLAW_BIN, ["sandbox", "explain", "--agent", "gmail-reader", "--json"]],
  "sandbox-email-researcher": [OPENCLAW_BIN, ["sandbox", "explain", "--agent", "email-researcher", "--json"]],
  "broker-health": [NODE_BIN, [BROKER_CLIENT, "health_check", "{}"]],
  "broker-search": [NODE_BIN, [BROKER_CLIENT, "search_threads", '{"query":"newer_than:30d","limit":1}']],
  "f-a3-clean": [
    GATE_SCRIPT,
    [
      "--no-log",
      '{"thread_summary":"discarded by gate","research_request":{"kind":"company_fact","entity":"OpenAI","topic":"products"}}',
    ],
  ],
  "f-a3-adversarial-suite": [NODE_BIN, [GATE_TEST]],
});

function failUsage(message) {
  console.error(`USAGE_REJECTED: ${message}`);
  console.error(`Approved operations: ${Object.keys(OPERATIONS).join(", ")}`);
  process.exit(64);
}

if (process.argv.length !== 3) {
  failUsage("expected exactly one operation id");
}

const operationId = process.argv[2];
const operation = OPERATIONS[operationId];
if (!operation) {
  failUsage(`unknown operation id: ${operationId}`);
}

if (typeof process.getuid === "function" && process.getuid() !== 0) {
  console.error("IDENTITY_SWITCH_UNAVAILABLE: wrapper must run as root");
  process.exit(70);
}

try {
  if (typeof process.initgroups === "function") {
    process.initgroups("openclawgw", "openclawgw");
  }
  process.setgid("openclawgw");
  process.setuid("openclawgw");
} catch (error) {
  console.error(`IDENTITY_SWITCH_FAILED: ${error.message}`);
  process.exit(70);
}

const [command, args] = operation;
const result = spawnSync(command, args, {
  env: FIXED_ENV,
  shell: false,
  stdio: "inherit",
});

if (result.error) {
  console.error(`COMMAND_EXEC_FAILED: ${result.error.message}`);
  process.exit(71);
}

if (result.signal) {
  console.error(`COMMAND_SIGNAL: ${result.signal}`);
  process.exit(128);
}

process.exit(result.status ?? 0);
