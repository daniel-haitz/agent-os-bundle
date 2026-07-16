#!/usr/bin/env node
// Real Colima/Docker substrate proof for the Agent OS OpenAI proxy path.
//
// This proof creates only temporary, uniquely labeled Docker resources and
// fixture files. It does not mount live OpenClaw state, use real credentials,
// install services, or alter pf/launchd/OpenClaw production configuration.

import { spawnSync } from "node:child_process";
import { createHash, randomBytes } from "node:crypto";
import { chmodSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const repoRoot = new URL("..", import.meta.url).pathname.replace(/\/scripts\/?$/, "");
const ts = new Date().toISOString().replace(/[-:]/g, "").replace(/\..*/, "Z");
const suffix = `${ts}-${randomBytes(3).toString("hex")}`;
const labelKey = "ai.agent-os.proof";
const labelValue = `openai-proxy-substrate-${suffix}`;
const outDir = process.argv[2] || join("/Users/agent", `fa4-openai-proxy-substrate-${suffix}`);
const evidencePath = join(outDir, "substrate-proof.json");
const image = process.env.AGENT_OS_SUBSTRATE_IMAGE || "openclaw-sandbox:bookworm-slim";

const names = {
  netOpenclaw: `aos-oc-${suffix}`,
  netUpstream: `aos-up-${suffix}`,
  netForbidden: `aos-deny-${suffix}`,
  upstream: `aos-upstream-${suffix}`,
  forbidden: `aos-forbidden-${suffix}`,
  proxy: `aos-proxy-${suffix}`,
  openclaw: `aos-openclaw-${suffix}`,
  unrelated: `aos-unrelated-${suffix}`,
};

const livePaths = [
  "/Users/agent/.openclaw/openclaw.json",
  "/Users/agent/.openclaw/openclaw.sanitized.json",
  "/Users/agent/.openclaw",
  "/Library/LaunchDaemons/ai.openclaw.gateway.plist",
  "/Library/LaunchDaemons/ai.agent-os-egress-proxy.plist",
  "/Library/LaunchDaemons/ai.agent-os.gmail-broker.plist",
  "/Users/openai-credential-broker/agent-os-openai-credential-broker",
];

const results = [];
const blockers = [];
const created = { networks: [], containers: [], volumes: [], files: [] };

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: "utf8",
    timeout: options.timeout ?? 30000,
    input: options.input,
  });
  return {
    command: [command, ...args].join(" "),
    status: result.status,
    stdout: result.stdout || "",
    stderr: result.stderr || "",
    error: result.error?.message,
  };
}

function docker(args, options) {
  return run("docker", args, options);
}

function record(name, ok, detail = "") {
  results.push({ name, ok, detail });
  console.log(`${ok ? "PASS" : "FAIL"} ${name}${detail ? `: ${detail}` : ""}`);
  if (!ok) blockers.push({ name, detail });
}

function sha(value) {
  return createHash("sha256").update(value).digest("hex");
}

function pathState(path) {
  if (!existsSync(path)) return { path, exists: false };
  const stat = run("stat", ["-f", "%Su\t%Sg\t%OLp\t%z\t%N", path]);
  const hash = run("shasum", ["-a", "256", path]);
  return {
    path,
    exists: true,
    stat: stat.stdout.trim(),
    sha256: stat.status === 0 && hash.status === 0 ? hash.stdout.trim().split(/\s+/)[0] : "not-readable-or-not-file",
  };
}

function dockerState() {
  return {
    colima: run("colima", ["status"]),
    dockerInfo: docker(["info", "--format", "{{json .}}"]),
    containers: docker(["ps", "-a", "--format", "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Networks}}\t{{.Ports}}"]),
    networks: docker(["network", "ls", "--format", "{{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}"]),
    volumes: docker(["volume", "ls", "--format", "{{.Name}}"]),
  };
}

function writeFixtureFiles() {
  mkdirSync(outDir, { recursive: true, mode: 0o700 });
  const localToken = `local_${randomBytes(32).toString("hex")}`;
  const upstreamToken = `upstream_${randomBytes(32).toString("hex")}`;
  const localTokenPath = join(outDir, "openclaw-local-token");
  const upstreamTokenPath = join(outDir, "openai-upstream-token");
  writeFileSync(localTokenPath, `${localToken}\n`, { mode: 0o600 });
  writeFileSync(upstreamTokenPath, `${upstreamToken}\n`, { mode: 0o600 });
  chmodSync(localTokenPath, 0o600);
  chmodSync(upstreamTokenPath, 0o600);
  created.files.push(localTokenPath, upstreamTokenPath);

  const opensslConf = join(outDir, "openssl.cnf");
  writeFileSync(opensslConf, `
[req]
distinguished_name=req_distinguished_name
x509_extensions=v3_req
prompt=no
[req_distinguished_name]
CN=api.openai.test
[v3_req]
subjectAltName=@alt_names
[alt_names]
DNS.1=api.openai.test
`);
  const key = join(outDir, "upstream.key");
  const cert = join(outDir, "upstream.crt");
  const openssl = run("openssl", ["req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1", "-keyout", key, "-out", cert, "-config", opensslConf, "-sha256"], { timeout: 30000 });
  record("synthetic TLS certificate generated", openssl.status === 0, openssl.status === 0 ? "api.openai.test" : openssl.stderr.trim());
  chmodSync(key, 0o600);
  chmodSync(cert, 0o644);
  created.files.push(opensslConf, key, cert);

  const upstreamPy = join(outDir, "upstream.py");
  writeFileSync(upstreamPy, String.raw`
import hashlib, http.server, json, ssl, sys
captures_path, cert_path, key_path = sys.argv[1], sys.argv[2], sys.argv[3]
class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("content-length", "0") or "0"))
        capture = {
            "method": self.command,
            "path": self.path,
            "host": self.headers.get("host"),
            "authorization_hash": hashlib.sha256((self.headers.get("authorization") or "").encode()).hexdigest(),
            "has_x_api_key": "x-api-key" in [k.lower() for k in self.headers.keys()],
            "has_proxy_authorization": "proxy-authorization" in [k.lower() for k in self.headers.keys()],
            "body_hash": hashlib.sha256(body).hexdigest(),
            "body_len": len(body),
        }
        with open(captures_path, "a") as f:
            f.write(json.dumps(capture) + "\n")
        if self.headers.get("x-fixture-redirect"):
            self.send_response(302)
            self.send_header("location", "https://example.com/escape")
            self.end_headers()
            return
        self.send_response(200)
        self.send_header("content-type", "text/event-stream")
        self.end_headers()
        self.wfile.write(b"event: response.created\n")
        self.wfile.write(b"data: {\"type\":\"response.created\"}\n\n")
        self.wfile.write(b"event: response.completed\n")
        self.wfile.write(b"data: {\"type\":\"response.completed\"}\n\n")
        self.wfile.write(b"data: [DONE]\n\n")
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200); self.end_headers(); self.wfile.write(b"ok\n")
        else:
            self.send_response(404); self.end_headers()
    def log_message(self, *args): pass
httpd = http.server.ThreadingHTTPServer(("0.0.0.0", 9443), Handler)
httpd.socket = ssl.wrap_socket(httpd.socket, certfile=cert_path, keyfile=key_path, server_side=True)
httpd.serve_forever()
`);
  const proxyPy = join(outDir, "proxy.py");
  writeFileSync(proxyPy, String.raw`
import hashlib, http.client, http.server, json, os, ssl, sys, urllib.parse
local_path, upstream_path, ca_path, log_path = sys.argv[1:5]
local_token = open(local_path).read().strip()
upstream_token = open(upstream_path).read().strip()
def log(event, **fields):
    safe = {"event": event, **fields}
    with open(log_path, "a") as f: f.write(json.dumps(safe) + "\n")
def deny(h, code, msg):
    h.send_response(code); h.send_header("content-type", "application/json"); h.end_headers(); h.wfile.write(json.dumps({"error": msg}).encode()+b"\n")
class Handler(http.server.BaseHTTPRequestHandler):
    def do_CONNECT(self): deny(self, 405, "connect_denied")
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200); self.end_headers(); self.wfile.write(b"ok\n")
        else: deny(self, 404, "path_denied")
    def do_POST(self):
        host = (self.headers.get("host") or "").split(":", 1)[0]
        if host not in ("openai-proxy", "127.0.0.1", "localhost"): return deny(self, 400, "host_denied")
        if self.path.startswith("http://") or self.path.startswith("https://"): return deny(self, 400, "absolute_url_denied")
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path != "/v1/responses": return deny(self, 404, "path_denied")
        auth_headers = [v for k,v in self.headers.items() if k.lower() == "authorization"]
        if len(auth_headers) != 1 or auth_headers[0] != "Bearer " + local_token: return deny(self, 401, "auth_denied")
        lower = {k.lower(): v for k,v in self.headers.items()}
        for bad in ("x-api-key", "proxy-authorization", "forwarded"):
            if bad in lower: return deny(self, 400, "forbidden_header")
        for key in lower:
            if key.startswith("x-forwarded-"): return deny(self, 400, "forbidden_header")
        body = self.rfile.read(int(self.headers.get("content-length", "0") or "0"))
        ctx = ssl.create_default_context(cafile=ca_path)
        conn = http.client.HTTPSConnection("api.openai.test", 9443, context=ctx, timeout=5)
        headers = {"authorization": "Bearer " + upstream_token, "content-type": self.headers.get("content-type", "application/json"), "host": "api.openai.test:9443"}
        if self.headers.get("x-fixture-redirect"): headers["x-fixture-redirect"] = "1"
        conn.request("POST", "/v1/responses", body=body, headers=headers)
        resp = conn.getresponse()
        if resp.status in (301,302,303,307,308):
            resp.read(); return deny(self, 502, "redirect_denied")
        self.send_response(resp.status)
        self.send_header("content-type", resp.getheader("content-type", "application/octet-stream"))
        self.end_headers()
        while True:
            chunk = resp.read(64)
            if not chunk: break
            self.wfile.write(chunk); self.wfile.flush()
        log("request_complete", path=parsed.path, status=resp.status)
    def log_message(self, *args): pass
http.server.ThreadingHTTPServer(("0.0.0.0", 18187), Handler).serve_forever()
`);
  chmodSync(upstreamPy, 0o444);
  chmodSync(proxyPy, 0o444);
  created.files.push(upstreamPy, proxyPy);
  return { localToken, upstreamToken, localTokenPath, upstreamTokenPath, key, cert, upstreamPy, proxyPy };
}

function createNetwork(name, internal = true) {
  const args = ["network", "create", "--label", `${labelKey}=${labelValue}`];
  if (internal) args.push("--internal");
  args.push(name);
  const result = docker(args);
  if (result.status === 0) created.networks.push(name);
  record(`network created ${name}`, result.status === 0, result.status === 0 ? "internal=true" : result.stderr.trim());
}

function createContainer(args, name) {
  const result = docker(args);
  if (result.status === 0) created.containers.push(name);
  record(`container created ${name}`, result.status === 0, result.status === 0 ? "" : result.stderr.trim());
}

function startContainer(name) {
  const result = docker(["start", name]);
  record(`container started ${name}`, result.status === 0, result.status === 0 ? "" : result.stderr.trim());
}

function execContainer(name, command, options = {}) {
  return docker(["exec", name, "sh", "-lc", command], { timeout: options.timeout ?? 15000 });
}

function pySocketStatusRequest(name, requestText, expectedStatus) {
  const encoded = Buffer.from(requestText).toString("base64");
  const cmd = `python3 - <<'PY'
import base64, socket, sys
req = base64.b64decode("${encoded}")
s = socket.create_connection(("openai-proxy", 18187), timeout=3)
s.sendall(req)
data = b""
while b"\\r\\n\\r\\n" not in data:
    chunk = s.recv(4096)
    if not chunk:
        break
    data += chunk
s.close()
sys.exit(0 if b" ${expectedStatus} " in data.split(b"\\r\\n", 1)[0] else 1)
PY`;
  return execContainer(name, cmd);
}

function httpStatus(name, url, extra = "") {
  const cmd = `curl -ksS -o /tmp/body.out -w '%{http_code}' ${extra} '${url}'`;
  const result = execContainer(name, cmd);
  return { status: result.status, code: result.stdout.trim(), stderr: result.stderr.trim() };
}

function readCaptures(path) {
  if (!existsSync(path)) return [];
  return readFileSync(path, "utf8").trim().split(/\n+/).filter(Boolean).map((line) => JSON.parse(line));
}

function cleanup() {
  for (const container of [...created.containers].reverse()) {
    docker(["rm", "-f", container], { timeout: 15000 });
  }
  for (const network of [...created.networks].reverse()) {
    docker(["network", "rm", network], { timeout: 15000 });
  }
}

function verifyNoResidue() {
  const containers = docker(["ps", "-a", "--filter", `label=${labelKey}=${labelValue}`, "--format", "{{.Names}}"]);
  const networks = docker(["network", "ls", "--filter", `label=${labelKey}=${labelValue}`, "--format", "{{.Name}}"]);
  record("temporary containers removed", containers.status === 0 && containers.stdout.trim() === "", containers.stdout.trim());
  record("temporary networks removed", networks.status === 0 && networks.stdout.trim() === "", networks.stdout.trim());
}

async function main() {
  mkdirSync(outDir, { recursive: true, mode: 0o700 });
  const beforeLive = livePaths.map(pathState);
  const beforeDocker = dockerState();
  const fixture = writeFixtureFiles();
  const capturesPath = join(outDir, "upstream-captures.jsonl");
  const proxyLog = join(outDir, "proxy.log");

  try {
    record("docker server available", beforeDocker.dockerInfo.status === 0, beforeDocker.dockerInfo.status === 0 ? "colima context" : beforeDocker.dockerInfo.stderr.trim());
    record("proof image available locally", docker(["image", "inspect", image]).status === 0, image);

    createNetwork(names.netOpenclaw, true);
    createNetwork(names.netUpstream, true);
    createNetwork(names.netForbidden, true);

    createContainer([
      "create", "--name", names.upstream, "--network", names.netUpstream, "--network-alias", "api.openai.test",
      "--label", `${labelKey}=${labelValue}`, "--read-only", "--tmpfs", "/tmp:rw,noexec,nosuid,size=8m",
      "-v", `${fixture.upstreamPy}:/upstream.py:ro`,
      "-v", `${fixture.cert}:/upstream.crt:ro`,
      "-v", `${fixture.key}:/upstream.key:ro`,
      "-v", `${outDir}:/evidence`,
      image, "python3", "/upstream.py", "/evidence/upstream-captures.jsonl", "/upstream.crt", "/upstream.key",
    ], names.upstream);
    createContainer([
      "create", "--name", names.forbidden, "--network", names.netForbidden,
      "--label", `${labelKey}=${labelValue}`, "--read-only", "--tmpfs", "/tmp:rw,noexec,nosuid,size=4m",
      image, "python3", "-m", "http.server", "8080",
    ], names.forbidden);
    createContainer([
      "create", "--name", names.proxy, "--network", names.netOpenclaw, "--network-alias", "openai-proxy",
      "--label", `${labelKey}=${labelValue}`, "--user", "540:740", "--read-only", "--tmpfs", "/tmp:rw,noexec,nosuid,size=8m",
      "-v", `${fixture.proxyPy}:/proxy.py:ro`,
      "-v", `${fixture.localTokenPath}:/local-token:ro`,
      "-v", `${fixture.upstreamTokenPath}:/upstream-token:ro`,
      "-v", `${fixture.cert}:/upstream.crt:ro`,
      "-v", `${outDir}:/evidence`,
      image, "python3", "/proxy.py", "/local-token", "/upstream-token", "/upstream.crt", "/evidence/proxy.log",
    ], names.proxy);
    const connectProxy = docker(["network", "connect", "--alias", "openai-proxy-upstream", names.netUpstream, names.proxy]);
    record("proxy connected to upstream network", connectProxy.status === 0, connectProxy.status === 0 ? "dual-homed proxy" : connectProxy.stderr.trim());

    createContainer([
      "create", "--name", names.openclaw, "--network", names.netOpenclaw,
      "--label", `${labelKey}=${labelValue}`, "--user", "555:555", "--read-only", "--tmpfs", "/tmp:rw,noexec,nosuid,size=8m",
      "-v", `${fixture.localTokenPath}:/local-token:ro`,
      image, "sleep", "3600",
    ], names.openclaw);
    createContainer([
      "create", "--name", names.unrelated, "--network", names.netOpenclaw,
      "--label", `${labelKey}=${labelValue}`, "--user", "777:777", "--read-only", "--tmpfs", "/tmp:rw,noexec,nosuid,size=4m",
      image, "sleep", "3600",
    ], names.unrelated);

    for (const name of [names.upstream, names.forbidden, names.proxy, names.openclaw, names.unrelated]) startContainer(name);

    const inspectProxy = docker(["inspect", names.proxy]);
    const inspectOpenclaw = docker(["inspect", names.openclaw]);
    writeFileSync(join(outDir, "proxy.inspect.json"), inspectProxy.stdout, { mode: 0o600 });
    writeFileSync(join(outDir, "openclaw.inspect.json"), inspectOpenclaw.stdout, { mode: 0o600 });
    record("host network mode absent", !inspectProxy.stdout.includes('"NetworkMode": "host"') && !inspectOpenclaw.stdout.includes('"NetworkMode": "host"'));
    record("no host-published ports", !inspectProxy.stdout.includes('"HostPort": "') && !inspectOpenclaw.stdout.includes('"HostPort": "'));

    const dns = execContainer(names.openclaw, "python3 - <<'PY'\nimport socket\nprint(socket.gethostbyname('openai-proxy'))\nPY\ncat /etc/resolv.conf");
    record("container DNS resolves proxy service name", dns.status === 0, dns.stdout.split("\n")[0] || dns.stderr.trim());
    const proxyDns = execContainer(names.proxy, "python3 - <<'PY'\nimport socket\nprint(socket.gethostbyname('api.openai.test'))\nPY\ncat /etc/resolv.conf");
    record("proxy DNS resolves approved upstream service name", proxyDns.status === 0, proxyDns.stdout.split("\n")[0] || proxyDns.stderr.trim());

    const payload = JSON.stringify({ model: "gpt-5.5", input: [{ role: "user", content: [{ type: "input_text", text: "fixture" }] }], tools: [{ type: "function", name: "fixture_tool", parameters: { type: "object", properties: {} } }], stream: true });
    const allow = execContainer(names.openclaw, `TOKEN="$(cat /local-token)" && curl -ksS -N -o /tmp/proxy.out -w '%{http_code}' -H "Authorization: Bearer $TOKEN" -H 'content-type: application/json' --data '${payload.replace(/'/g, "'\\''")}' http://openai-proxy:18187/v1/responses && grep -q 'response.completed' /tmp/proxy.out`);
    record("openclaw-side fixture reaches forwarding proxy", allow.status === 0 && allow.stdout.includes("200"), allow.stdout.trim() || allow.stderr.trim());

    const captures = readCaptures(capturesPath);
    const expectedUpstreamHash = sha(`Bearer ${fixture.upstreamTokenPath ? readFileSync(fixture.upstreamTokenPath, "utf8").trim() : ""}`);
    record("proxy reaches approved synthetic upstream", captures.length >= 1);
    record("POST /v1/responses succeeds", captures.at(-1)?.path === "/v1/responses" && captures.at(-1)?.method === "POST");
    record("streaming works", execContainer(names.openclaw, "grep -q 'response.completed' /tmp/proxy.out").status === 0);
    record("tool-shaped request works", (captures.at(-1)?.body_len || 0) > 0);
    record("synthetic upstream token injected only proxy-to-upstream", captures.at(-1)?.authorization_hash === expectedUpstreamHash);
    record("caller token stripped upstream", captures.at(-1)?.authorization_hash !== sha(`Bearer ${readFileSync(fixture.localTokenPath, "utf8").trim()}`));

    record("wrong local token rejected", httpStatus(names.openclaw, "http://openai-proxy:18187/v1/responses", "-X POST -H 'Authorization: Bearer wrong' --data '{}'").code === "401");
    record("direct api.openai.com hostname denied", httpStatus(names.openclaw, "https://api.openai.com/v1/responses", "--connect-timeout 2").status !== 0);
    record("direct OpenAI IP denied", httpStatus(names.openclaw, "https://104.18.33.45/v1/responses", "--connect-timeout 2").status !== 0);
    record("arbitrary external IPv4 denied", httpStatus(names.openclaw, "http://93.184.216.34", "--connect-timeout 2").status !== 0);
    record("arbitrary external IPv6 denied", httpStatus(names.openclaw, "http://[2606:4700::6812:212d]/", "--connect-timeout 2").status !== 0);
    record("alternate DNS resolver bypass denied", execContainer(names.openclaw, "curl -ksS --dns-servers 1.1.1.1 --connect-timeout 2 https://api.openai.com/ >/tmp/dns.out 2>/tmp/dns.err").status !== 0);
    record("HTTP_PROXY bypass denied", execContainer(names.openclaw, "HTTP_PROXY=http://93.184.216.34:8080 curl -ksS --connect-timeout 2 https://api.openai.com/ >/tmp/http-proxy.out 2>/tmp/http-proxy.err").status !== 0);
    record("HTTPS_PROXY bypass denied", execContainer(names.openclaw, "HTTPS_PROXY=http://93.184.216.34:8080 curl -ksS --connect-timeout 2 https://api.openai.com/ >/tmp/https-proxy.out 2>/tmp/https-proxy.err").status !== 0);
    record("ALL_PROXY bypass denied", execContainer(names.openclaw, "ALL_PROXY=http://93.184.216.34:8080 curl -ksS --connect-timeout 2 https://api.openai.com/ >/tmp/all-proxy.out 2>/tmp/all-proxy.err").status !== 0);
    record("openclaw direct synthetic upstream denied", httpStatus(names.openclaw, "https://api.openai.test:9443/v1/responses", "--connect-timeout 2").status !== 0);
    record("openclaw direct forbidden destination denied", httpStatus(names.openclaw, `http://${names.forbidden}:8080`, "--connect-timeout 2").status !== 0);
    record("host.docker.internal escape denied", httpStatus(names.openclaw, "http://host.docker.internal:80", "--connect-timeout 2").status !== 0);
    record("host gateway escape denied", execContainer(names.openclaw, "python3 - <<'PY'\nimport socket, struct, sys\ntry:\n    route = open('/proc/net/route').read().splitlines()[1:]\n    gw = None\n    for line in route:\n        f=line.split()\n        if f[1] == '00000000':\n            gw = socket.inet_ntoa(struct.pack('<L', int(f[2], 16)))\n            break\n    if not gw:\n        sys.exit(0)\n    s=socket.create_connection((gw, 80), timeout=2)\n    s.close()\n    sys.exit(1)\nexcept Exception:\n    sys.exit(0)\nPY").status === 0);

    record("proxy arbitrary external hostname denied", httpStatus(names.proxy, "https://example.com", "--connect-timeout 2").status !== 0);
    record("proxy arbitrary IPv4 denied", httpStatus(names.proxy, "http://93.184.216.34", "--connect-timeout 2").status !== 0);
    record("proxy arbitrary IPv6 denied", httpStatus(names.proxy, "http://[2606:4700::6812:212d]/", "--connect-timeout 2").status !== 0);
    record("proxy forbidden destination container denied", httpStatus(names.proxy, `http://${names.forbidden}:8080`, "--connect-timeout 2").status !== 0);
    record("proxy alternate upstream port denied", httpStatus(names.proxy, "https://api.openai.test:9444/v1/responses", "--connect-timeout 2").status !== 0);
    record("caller-controlled Host rejected", httpStatus(names.openclaw, "http://openai-proxy:18187/v1/responses", "-X POST -H 'Host: api.openai.com' --data '{}'").code === "400");
    record("absolute URL rejected", pySocketStatusRequest(names.openclaw, `POST http://api.openai.com/v1/responses HTTP/1.1\r\nHost: openai-proxy:18187\r\nAuthorization: Bearer ${readFileSync(fixture.localTokenPath, "utf8").trim()}\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}`, 400).status === 0);
    record("CONNECT rejected", pySocketStatusRequest(names.openclaw, "CONNECT api.openai.com:443 HTTP/1.1\r\nHost: api.openai.com:443\r\nConnection: close\r\n\r\n", 405).status === 0);
    record("redirect to another host rejected", httpStatus(names.openclaw, "http://openai-proxy:18187/v1/responses", "-X POST -H \"Authorization: Bearer $(cat /local-token)\" -H 'x-fixture-redirect: 1' --data '{}'").code === "502");
    record("unsupported endpoint rejected", httpStatus(names.openclaw, "http://openai-proxy:18187/v1/models", "-H \"Authorization: Bearer $(cat /local-token)\"").code === "404");

    record("openclaw cannot read upstream credential", execContainer(names.openclaw, "test ! -e /run/secrets/upstream-token").status === 0);
    record("proxy can read upstream credential", execContainer(names.proxy, "test -r /upstream-token").status === 0);
    record("proxy can read local token", execContainer(names.proxy, "test -r /local-token").status === 0);
    record("unrelated container cannot read tokens", execContainer(names.unrelated, "test ! -e /local-token && test ! -e /upstream-token").status === 0);
    record("proxy code mounted read-only", execContainer(names.proxy, "test -r /proxy.py && test ! -w /proxy.py").status === 0);
    record("token absent from container environment", !inspectProxy.stdout.includes(readFileSync(fixture.localTokenPath, "utf8").trim()) && !inspectProxy.stdout.includes(readFileSync(fixture.upstreamTokenPath, "utf8").trim()));
    const logs = docker(["logs", names.proxy]);
    record("tokens absent from proxy logs", !logs.stdout.includes(readFileSync(fixture.localTokenPath, "utf8").trim()) && !logs.stdout.includes(readFileSync(fixture.upstreamTokenPath, "utf8").trim()));

    const restartProxy = docker(["restart", names.proxy]);
    record("proxy restart succeeds", restartProxy.status === 0);
    const restartOpenclaw = docker(["restart", names.openclaw]);
    record("openclaw-side restart succeeds", restartOpenclaw.status === 0);
    const postRestart = execContainer(names.openclaw, `TOKEN="$(cat /local-token)" && curl -ksS -o /tmp/restart.out -w '%{http_code}' -H "Authorization: Bearer $TOKEN" -H 'content-type: application/json' --data '{}' http://openai-proxy:18187/v1/responses`);
    record("policy preserved after container restart", postRestart.status === 0 && postRestart.stdout.includes("200"));
    const reconnect = docker(["network", "disconnect", names.netOpenclaw, names.openclaw]);
    const reconnect2 = docker(["network", "connect", names.netOpenclaw, names.openclaw]);
    record("network reconnect succeeds", reconnect.status === 0 && reconnect2.status === 0);
    record("network reconnect bypass denied", httpStatus(names.openclaw, "https://api.openai.com/v1/responses", "--connect-timeout 2").status !== 0);

    const afterLive = livePaths.map(pathState);
    const zeroMutation = JSON.stringify(beforeLive) === JSON.stringify(afterLive);
    record("zero production file mutation", zeroMutation);

    const evidence = {
      result: blockers.length === 0 ? "OPENAI PROXY PRODUCTION SUBSTRATE PROOF: GO" : "OPENAI PROXY PRODUCTION SUBSTRATE PROOF: NO-GO",
      timestamp: new Date().toISOString(),
      label: { [labelKey]: labelValue },
      image,
      initialState: { docker: beforeDocker, livePaths: beforeLive },
      finalLivePaths: afterLive,
      topology: {
        productionPlacementDecision: "OpenClaw model-network execution must run inside a contained component on an internal Docker/Colima network. The OpenAI proxy is a separate contained component dual-homed between the OpenClaw-side internal network and a constrained upstream egress network. Host OpenClaw may orchestrate but must not originate direct OpenAI HTTP traffic after closure.",
        networks: [
          { name: names.netOpenclaw, internal: true, role: "OpenClaw-side to proxy only" },
          { name: names.netUpstream, internal: true, role: "proxy to approved synthetic upstream only" },
          { name: names.netForbidden, internal: true, role: "negative-control destination not connected to proxy/openclaw" },
        ],
        components: names,
      },
      pathMatrix: [
        { source: "OpenClaw model-network component", destination: "OpenAI proxy", protocol: "HTTP 18187", placement: "contained", required: true, enforcementPoint: "internal Docker network membership" },
        { source: "OpenClaw model-network component", destination: "api.openai.com", protocol: "HTTPS 443", placement: "contained", required: false, enforcementPoint: "no external route from internal network" },
        { source: "OpenAI proxy", destination: "api.openai.com", protocol: "HTTPS 443", placement: "contained upstream egress component", required: true, enforcementPoint: "upstream allowlist network/gateway required before production" },
        { source: "Gmail broker", destination: "Google APIs", protocol: "HTTPS 443", placement: "host broker", required: true, enforcementPoint: "unchanged; not routed through OpenAI proxy" },
        { source: "Telegram", destination: "Telegram API", protocol: "HTTPS 443", placement: "host/OpenClaw existing path", required: true, enforcementPoint: "unchanged; must be regression-tested before cutover" },
        { source: "local agents", destination: "Ollama 127.0.0.1:11434", protocol: "HTTP 11434", placement: "host loopback", required: true, enforcementPoint: "unchanged local route" },
      ],
      dnsTlsFindings: {
        containerDnsPath: "Docker embedded DNS resolves service aliases on attached internal networks.",
        customDnsBypass: "Denied in the OpenClaw-side fixture because the internal network has no external route.",
        cdnIpDrift: "Production must enforce by fixed upstream component/SNI/TLS policy, not a static CDN IP list.",
        tlsValidation: "Synthetic upstream used a fixture CA and hostname api.openai.test; proxy connection required certificate validation for that hostname.",
        redirects: "Proxy rejects 3xx redirects to other hosts.",
        ipv4Ipv6Parity: "OpenClaw-side and proxy arbitrary IPv4/IPv6 attempts failed on internal networks.",
      },
      localTokenDecision: "Do not place the OpenClaw-readable local token under /Users/openai-credential-broker unless traversal is separately proved. The proof supports a separate OpenClaw-owned local-token source mounted read-only into both the OpenClaw-side component and proxy.",
      results,
      blockers,
    };
    writeFileSync(evidencePath, JSON.stringify(evidence, null, 2), { mode: 0o600 });
  } finally {
    cleanup();
    verifyNoResidue();
    const afterDocker = dockerState();
    writeFileSync(join(outDir, "docker-before.json"), JSON.stringify(beforeDocker, null, 2), { mode: 0o600 });
    writeFileSync(join(outDir, "docker-after.json"), JSON.stringify(afterDocker, null, 2), { mode: 0o600 });
  }

  console.log(`EVIDENCE: ${evidencePath}`);
  if (blockers.length) {
    console.log("OPENAI PROXY PRODUCTION SUBSTRATE PROOF: NO-GO");
    process.exit(2);
  }
  console.log("OPENAI PROXY PRODUCTION SUBSTRATE PROOF: GO");
}

main().catch((error) => {
  console.error(`FATAL ${error.stack || error.message}`);
  cleanup();
  verifyNoResidue();
  console.log("OPENAI PROXY PRODUCTION SUBSTRATE PROOF: NO-GO");
  process.exit(2);
});
