#!/usr/bin/env node
// Fixture tests for the OpenAI proxy cutover rollback model.
// This does not read or mutate production OpenClaw state.

const scenarios = [
  {
    name: "proxy fails before config cutover",
    stage: "before-config-cutover",
    expected: ["stop proxy fixture", "remove absent-before proxy artifacts", "preserve OpenClaw config", "preserve direct credential source"],
    mayRestoreDirectRoute: false,
  },
  {
    name: "proxy fails after config cutover",
    stage: "after-config-cutover",
    expected: ["restore backed-up OpenClaw config", "restart gateway", "verify direct route restored only with operator approval", "preserve proxy evidence"],
    mayRestoreDirectRoute: true,
  },
  {
    name: "OpenClaw restart fails",
    stage: "gateway-restart",
    expected: ["restore backed-up OpenClaw config", "restore auth stores", "restart gateway", "verify health", "direct route restoration requires operator approval"],
    mayRestoreDirectRoute: true,
  },
  {
    name: "model invocation fails",
    stage: "post-cutover-functional-test",
    expected: ["retain proxy evidence", "restore config only if operator approval permits temporary direct route", "do not delete upstream custody evidence"],
    mayRestoreDirectRoute: true,
  },
  {
    name: "egress wall blocks required traffic",
    stage: "egress-validation",
    expected: ["disable only fixture/contained egress changes", "preserve Gmail broker untouched", "restore previous OpenClaw config if operator approval permits temporary direct route"],
    mayRestoreDirectRoute: true,
  },
  {
    name: "auth cleanup removes too much",
    stage: "residue-cleanup",
    expected: ["restore auth/profile backups", "restart gateway", "rerun local-agent checks", "direct route restoration requires operator approval"],
    mayRestoreDirectRoute: true,
  },
  {
    name: "reboot persistence fails",
    stage: "reboot-validation",
    expected: ["use captured pre-reboot rollback manifest", "restore service ordering", "verify gateway and proxy health", "direct route restoration requires operator approval"],
    mayRestoreDirectRoute: true,
  },
];

let failed = 0;
for (const scenario of scenarios) {
  const hasEvidencePreservation = scenario.expected.some((step) => /evidence|backup|preserve|restore/.test(step));
  const hasDirectRouteRule = scenario.mayRestoreDirectRoute === false || scenario.expected.some((step) => /operator approval|preserve direct credential source/.test(step));
  const ok = hasEvidencePreservation && hasDirectRouteRule;
  console.log(`ROLLBACK FIXTURE ${scenario.name}: ${ok ? "PASS" : "FAIL"}`);
  if (!ok) failed += 1;
}

console.log(JSON.stringify({
  scenarios: scenarios.length,
  passed: scenarios.length - failed,
  failed,
  directRouteRestorationRule: "Temporary direct-route restoration after cutover requires explicit operator approval and evidence.",
}, null, 2));

if (failed) process.exit(1);
