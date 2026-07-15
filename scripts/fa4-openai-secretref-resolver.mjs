#!/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node
// OpenClaw exec SecretRef resolver for Agent OS OpenAI static credentials.
//
// OpenClaw invokes this as a fixed exec provider command. It reads the
// OpenClaw SecretRef request JSON from stdin and forwards only approved ids to
// the local Agent OS credential broker over a Unix socket. It does not accept
// command-line ids, file paths, shell fragments, or environment-supplied secret
// values.

import net from "node:net";

const SOCKET_PATH =
  process.env.AGENT_OS_OPENAI_CREDENTIAL_SOCKET ||
  "/var/run/agent-os/openai-credential-broker.sock";
const PROVIDER = "agent_os_openai";
const MAX_STDIN_BYTES = 8192;
const TIMEOUT_MS = 3000;
const ALLOWED_IDS = new Set([
  "models.providers.openai.apiKey",
  "profiles.openai:manual.key",
]);

function fail(message, code = 1) {
  process.stderr.write(`${message}\n`);
  process.exit(code);
}

async function readStdin() {
  const chunks = [];
  let size = 0;
  for await (const chunk of process.stdin) {
    size += chunk.length;
    if (size > MAX_STDIN_BYTES) fail("request too large", 64);
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString("utf8");
}

function parseRequest(raw) {
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    fail("invalid JSON request", 64);
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    fail("request must be an object", 64);
  }
  if (parsed.protocolVersion !== 1 || parsed.provider !== PROVIDER) {
    fail("unsupported SecretRef provider request", 64);
  }
  if (!Array.isArray(parsed.ids) || parsed.ids.length < 1 || parsed.ids.length > ALLOWED_IDS.size) {
    fail("invalid ids", 64);
  }
  const ids = [];
  for (const id of parsed.ids) {
    if (typeof id !== "string" || !ALLOWED_IDS.has(id)) {
      ids.push(id);
      continue;
    }
    if (!ids.includes(id)) ids.push(id);
  }
  return { protocolVersion: 1, provider: PROVIDER, ids };
}

function requestBroker(payload) {
  return new Promise((resolve, reject) => {
    const socket = net.createConnection(SOCKET_PATH);
    let output = "";
    const timer = setTimeout(() => {
      socket.destroy();
      reject(new Error("credential broker timeout"));
    }, TIMEOUT_MS);

    socket.setEncoding("utf8");
    socket.on("connect", () => {
      socket.end(`${JSON.stringify(payload)}\n`);
    });
    socket.on("data", (chunk) => {
      output += chunk;
      if (Buffer.byteLength(output, "utf8") > MAX_STDIN_BYTES) {
        socket.destroy();
        reject(new Error("credential broker response too large"));
      }
    });
    socket.on("error", (error) => {
      clearTimeout(timer);
      reject(error);
    });
    socket.on("end", () => {
      clearTimeout(timer);
      resolve(output);
    });
  });
}

const request = parseRequest(await readStdin());
let rawResponse;
try {
  rawResponse = await requestBroker(request);
} catch (error) {
  fail(`credential broker unavailable: ${error instanceof Error ? error.message : String(error)}`, 69);
}

let response;
try {
  response = JSON.parse(rawResponse);
} catch {
  fail("credential broker returned invalid JSON", 70);
}

if (!response || typeof response !== "object" || Array.isArray(response)) {
  fail("credential broker response must be an object", 70);
}
if (response.protocolVersion !== 1) {
  fail("credential broker response protocolVersion must be 1", 70);
}
const values = response.values && typeof response.values === "object" && !Array.isArray(response.values)
  ? response.values
  : {};
const errors = response.errors && typeof response.errors === "object" && !Array.isArray(response.errors)
  ? response.errors
  : {};

const out = { protocolVersion: 1, values: {}, errors: {} };
for (const id of request.ids) {
  if (!ALLOWED_IDS.has(id)) {
    out.errors[id] = { message: "unknown credential id" };
  } else if (typeof values[id] === "string" && values[id].length > 0) {
    out.values[id] = values[id];
  } else if (errors[id]) {
    out.errors[id] = { message: "credential unavailable" };
  } else {
    out.errors[id] = { message: "credential unavailable" };
  }
}
if (Object.keys(out.errors).length === 0) delete out.errors;
process.stdout.write(`${JSON.stringify(out)}\n`);
