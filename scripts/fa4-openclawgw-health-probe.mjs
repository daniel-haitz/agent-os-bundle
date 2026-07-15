#!/usr/bin/env node
// Fixed OpenClaw health probe executed under the gateway runtime identity.
//
// The companion shell wrapper derives the command and environment from the
// installed ai.openclaw.gateway LaunchDaemon. This worker accepts no caller
// arguments and exposes no general command execution surface.

import { spawnSync } from "node:child_process";

function fail(message, code = 70) {
  console.error(message);
  process.exit(code);
}

if (process.argv.length !== 2) {
  fail("USAGE_REJECTED: health probe accepts no arguments", 64);
}

const nodeBin = process.env.AGENT_OS_OPENCLAW_NODE;
const entrypoint = process.env.AGENT_OS_OPENCLAW_ENTRYPOINT;
const home = process.env.AGENT_OS_OPENCLAW_HOME;
const configPath = process.env.AGENT_OS_OPENCLAW_CONFIG_PATH;
const stateDir = process.env.AGENT_OS_OPENCLAW_STATE_DIR;
const pathValue = process.env.AGENT_OS_OPENCLAW_PATH;

for (const [name, value] of Object.entries({
  AGENT_OS_OPENCLAW_NODE: nodeBin,
  AGENT_OS_OPENCLAW_ENTRYPOINT: entrypoint,
  AGENT_OS_OPENCLAW_HOME: home,
  AGENT_OS_OPENCLAW_CONFIG_PATH: configPath,
  AGENT_OS_OPENCLAW_STATE_DIR: stateDir,
  AGENT_OS_OPENCLAW_PATH: pathValue,
})) {
  if (!value) {
    fail(`HEALTH_PROBE_CONFIG_ERROR: missing ${name}`, 70);
  }
}

if (process.env.AGENT_OS_HEALTH_PROBE_ALLOW_NONROOT_TEST !== "1") {
  if (typeof process.getuid === "function" && process.getuid() !== 0) {
    fail("IDENTITY_SWITCH_UNAVAILABLE: health probe must run as root", 70);
  }
  try {
    if (typeof process.initgroups === "function") {
      process.initgroups("openclawgw", "openclawgw");
    }
    process.setgid("openclawgw");
    process.setuid("openclawgw");
  } catch (error) {
    fail(`IDENTITY_SWITCH_FAILED: ${error.message}`, 70);
  }
}

if (process.env.AGENT_OS_HEALTH_PROBE_REPORT_IDENTITY === "1") {
  console.error(`HEALTH_PROBE_UID=${typeof process.getuid === "function" ? process.getuid() : "unknown"}`);
  console.error(`HEALTH_PROBE_GID=${typeof process.getgid === "function" ? process.getgid() : "unknown"}`);
}

const result = spawnSync(nodeBin, [entrypoint, "health"], {
  env: {
    HOME: home,
    OPENCLAW_CONFIG_PATH: configPath,
    OPENCLAW_STATE_DIR: stateDir,
    PATH: pathValue,
    ...(process.env.AGENT_OS_HEALTH_PROBE_ALLOW_NONROOT_TEST === "1"
      ? { AGENT_OS_FIXTURE_HEALTH_FAIL: process.env.AGENT_OS_FIXTURE_HEALTH_FAIL ?? "" }
      : {}),
  },
  shell: false,
  stdio: "inherit",
});

if (result.error) {
  fail(`HEALTH_COMMAND_EXEC_FAILED: ${result.error.message}`, 71);
}

if (result.signal) {
  fail(`HEALTH_COMMAND_SIGNAL: ${result.signal}`, 128);
}

process.exit(result.status ?? 0);
