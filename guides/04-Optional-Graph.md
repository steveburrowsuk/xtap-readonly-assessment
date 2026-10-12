# Optional Graph expansion — stub only

The initial collector never loads Graph or requests consent. Executing Graph-ReadOnly-Expansion.stub.ps1 only prints an explanation; its commented operations are an implementation outline.

A later collector requires separate customer approval for delegated **Policy.Read.All**, consent managed outside this bundle and a supported Entra role. For ordinary partner/default reads, a supported read role such as Global Reader can be suitable. Exchange View-Only Organization Management alone does not grant Graph policy access. No write scopes are required or requested here.

Future GET-only endpoints:

```text
GET /v1.0/policies/crossTenantAccessPolicy/default
GET /v1.0/policies/crossTenantAccessPolicy/partners
GET /v1.0/policies/crossTenantAccessPolicy/partners/{confirmed-tenant-id}/m365Capabilities
```

The commented connection outline requests only Policy.Read.All with a customer tenant and process-scoped context. Consent is an administrative setup action outside the no-change initial assessment.

Microsoft's current capability-list documentation specifies delegated Global Administrator or Exchange Administrator (the latter for Free/Busy, Calendar Sharing and MailTips only), despite listing Policy.Read.All as the least-privileged OAuth scope. These roles have write authority. This bundle does not require, assign or recommend adding them. A Global Reader may read partners yet fail capability discovery. Keep capabilities unknown or review separately supplied evidence from an existing authorized customer administrator. Read scope alone does not guarantee capability access.

A future collector must verify tenant/context/scopes, perform GET only, validate the fixed HTTPS Graph host and paths including pagination links, retrieve all pages, implement bounded throttling retries and disconnect only its own session. Record endpoint-specific success/denied/unavailable/partial outcomes and retrieval UTC. Do not export tokens or connection objects. Treat 403 as denied and 404 as ambiguous until endpoint/rollout support is checked.

Basic partner/B2B configuration alone does not prove Microsoft 365 collaboration trust or capability readiness. Review defaults/inheritance, trust, rollout, confirmed partner ID and both tenant directions. No trust, scope, capability or policy is created by this bundle.
