# Validation
Validated locally on 12 October 2026 using PowerShell 7. No customer credentials or tenant connection were used.

All ten isolated synthetic scenarios passed: successful reads, empty datasets, permission denial, partial streamed results, wrong customer tenant, missing mailbox properties, unavailable command, limited coverage, skipped assignments and refusal to overwrite output.

Additional checks passed: PowerShell syntax parsing, scan for known Exchange/Graph mutation commands and live HTTP/Graph calls, HTML escaping of hostile fixture values, CSV formula mitigation, JSON array shape, inferred-default/GUID/unresolved policy handling, and 48 static report links. The scan supports code review; it is not a formal security proof. Dynamic reads are restricted by the fixed command calls in the collector.

The sample report is prominently labeled synthetic. Test evidence is in tests/Last-Offline-TestResults.csv. To repeat, run tests/Test-Offline.ps1 in PowerShell 7.4+; it creates a fresh temporary fake module and child processes and restores the parent module path. It does not connect to Microsoft. Fixture directories are retained as local evidence.

Limitations: not tested against a live customer tenant, actual Exchange View-Only RBAC, MFA/Conditional Access or national clouds. Large-tenant performance and browser rendering were not tested. Static HTML structure, links and encoded values were verified. Tenant-wide visibility must be confirmed externally. Existing CTAP trust/capabilities, actual sharing activity, partner hosting/IDs and rollout are not established. Graph expansion remains a non-executing stub.
