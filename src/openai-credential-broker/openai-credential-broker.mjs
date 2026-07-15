#!/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node
// Agent OS OpenAI credential broker for OpenClaw exec SecretRefs.
//
// Runtime model:
// - Runs as a dedicated non-OpenClaw OS user.
// - Reads its owner-only credential store.
// - Exposes only two OpenAI static credential ids over a local Unix socket.
// - Does not log or accept arbitrary secret names, files, commands, or paths.

import { createServer } from "node:net";
import {
  chmodSync,
  closeSync,
  constants,
  existsSync,
  fstatSync,
  lstatSync,
  openSync,
  readFileSync,
  unlinkSync,
} from "node:fs";
import { dirname } from "node:path";

const TEST_MODE = process.env.AGENT_OS_OPENAI_SECRETREF_TEST_MODE === "1";
const PRODUCTION_SOCKET_PATH = "/var/run/agent-os/openai-credential-broker/openai-credential-broker.sock";
const PRODUCTION_STORE_PATH = "/Users/openai-credential-broker/agent-os-openai-credential-broker/secrets/openai-static-credentials.json";
const SOCKET_PATH = TEST_MODE && process.env.AGENT_OS_OPENAI_CREDENTIAL_SOCKET
  ? process.env.AGENT_OS_OPENAI_CREDENTIAL_SOCKET
  : PRODUCTION_SOCKET_PATH;
const STORE_PATH = TEST_MODE && process.env.AGENT_OS_OPENAI_CREDENTIAL_STORE
  ? process.env.AGENT_OS_OPENAI_CREDENTIAL_STORE
  : PRODUCTION_STORE_PATH;
const SOCKET_MODE = 0o660;
const MAX_REQUEST_BYTES = 8192;
const ALLOWED_IDS = new Set([
  "models.providers.openai.apiKey",
  "profiles.openai:manual.key",
]);

function brokerResponse(values, errors = {}) {
  const response = { protocolVersion: 1, values };
  if (Object.keys(errors).length > 0) response.errors = errors;
  return `${JSON.stringify(response)}\n`;
}

function errorFor(id, message) {
  return { [id]: { message } };
}

function readCredentialStore() {
  let meta;
  try {
    meta = lstatSync(STORE_PATH);
  } catch {
    throw new Error("credential store inaccessible");
  }
  if (meta.isSymbolicLink() || !meta.isFile()) {
    throw new Error("credential store must be a regular non-symlink file");
  }

  let fd;
  try {
    fd = openSync(STORE_PATH, constants.O_RDONLY | constants.O_NOFOLLOW);
  } catch {
    throw new Error("credential store open failed");
  }

  try {
    const stat = fstatSync(fd);
    if (stat.uid !== process.getuid()) {
      throw new Error("credential store owner mismatch");
    }
    if ((stat.mode & 0o077) !== 0) {
      throw new Error("credential store permissions too broad");
    }
    const raw = readFileSync(fd, "utf8");
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      throw new Error("credential store must be a JSON object");
    }
    const out = {};
    for (const id of ALLOWED_IDS) {
      if (typeof parsed[id] === "string" && parsed[id].length > 0) {
        out[id] = parsed[id];
      }
    }
    return out;
  } finally {
    closeSync(fd);
  }
}

function handleRequest(raw) {
  let request;
  try {
    request = JSON.parse(raw);
  } catch {
    return brokerResponse({}, { request: { message: "invalid JSON" } });
  }
  if (!request || typeof request !== "object" || Array.isArray(request)) {
    return brokerResponse({}, { request: { message: "request must be an object" } });
  }
  if (request.protocolVersion !== 1 || request.provider !== "agent_os_openai") {
    return brokerResponse({}, { request: { message: "unsupported provider request" } });
  }
  if (!Array.isArray(request.ids) || request.ids.length < 1 || request.ids.length > ALLOWED_IDS.size) {
    return brokerResponse({}, { request: { message: "invalid ids" } });
  }

  let store;
  try {
    store = readCredentialStore();
  } catch {
    const errors = {};
    for (const id of request.ids) errors[id] = { message: "credential unavailable" };
    return brokerResponse({}, errors);
  }

  const values = {};
  const errors = {};
  for (const id of request.ids) {
    if (typeof id !== "string" || !ALLOWED_IDS.has(id)) {
      Object.assign(errors, errorFor(String(id), "unknown credential id"));
    } else if (store[id]) {
      values[id] = store[id];
    } else {
      Object.assign(errors, errorFor(id, "credential unavailable"));
    }
  }
  return brokerResponse(values, errors);
}

try {
  const socketDirMeta = lstatSync(dirname(SOCKET_PATH));
  if (socketDirMeta.isSymbolicLink() || !socketDirMeta.isDirectory() || (socketDirMeta.mode & 0o022) !== 0) {
    throw new Error("socket directory is insecure");
  }
  if (existsSync(SOCKET_PATH)) {
    const socketMeta = lstatSync(SOCKET_PATH);
    if (socketMeta.isSymbolicLink() || !socketMeta.isSocket()) {
      throw new Error("stale socket path is not a socket");
    }
    unlinkSync(SOCKET_PATH);
  }
} catch {
  process.stderr.write("failed to prepare broker socket path\n");
  process.exit(1);
}

const server = createServer((socket) => {
  let raw = "";
  socket.setEncoding("utf8");
  socket.on("data", (chunk) => {
    raw += chunk;
    if (Buffer.byteLength(raw, "utf8") > MAX_REQUEST_BYTES) {
      socket.end(brokerResponse({}, { request: { message: "request too large" } }));
      socket.destroy();
    }
  });
  socket.on("end", () => {
    socket.end(handleRequest(raw.trim()));
  });
});

server.listen(SOCKET_PATH, () => {
  chmodSync(SOCKET_PATH, SOCKET_MODE);
  process.stdout.write(`openai-credential-broker listening on ${SOCKET_PATH}\n`);
});

for (const signal of ["SIGTERM", "SIGINT"]) {
  process.on(signal, () => {
    server.close(() => {
      try {
        if (existsSync(SOCKET_PATH)) unlinkSync(SOCKET_PATH);
      } catch {}
      process.exit(0);
    });
  });
}
