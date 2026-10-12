# Troubleshooting

| Outcome | Safe response |
|---|---|
| Connection Failed / code 2 | Check module/runtime compatibility, interactive MFA, Conditional Access and network. Use a fresh process and independently verify the customer GUID. No inventory was attempted. |
| CommandUnavailable | Check imported command set, module version, effective RBAC and propagation. Absence alone does not prove denied permission. |
| PermissionDenied | Ask the customer's existing administrator to review the specific read and effective scope. Keep the view-only baseline. |
| ReadFailed | Possible service, network, throttling or unsupported-parameter failure. Resolve locally and rerun to a new folder; do not interpret as no configuration. |
| PartialRead | Rows were received before failure. Evidence and counts are incomplete; rerun after correction. |
| IncompleteProperties | Required fields were omitted. Check module/property support and permissions. Missing SharingPolicy is never treated as default. |
| Success, zero rows | Read completed within account visibility; verify scope before claiming none exist. |
| Limited / Skipped | Mailbox applicability is incomplete by choice; rerun with full approved coverage. |
| Unresolved policy | Compare raw reference with policy Name, Identity, GUID and DistinguishedName; check policy read/default state. Do not guess. |
| Wrong/multiple tenant sessions | Close process and authenticate anew; do not relax tenant verification. |
| Local export/report error | Check directory access, storage and endpoint protection. Incomplete local reports are not authoritative. |
| Missing HTML links | Keep HTML and data directory together; open locally in a browser. |

The collector suppresses raw errors, exports sanitized categories and never records transcripts, tokens or connection dumps. This can limit diagnosis. A customer's administrator can test an individual approved Get command interactively and review diagnostics locally before sharing redacted evidence.

Do not solve discovery failures by giving this tool Organization Management, Exchange Administrator, Global Administrator or write scopes. Investigate the approved view-only reads first. If an acceptable read-only path is unavailable, retain the gap or obtain separately approved evidence. There are no automatic retries or privilege upgrades.
