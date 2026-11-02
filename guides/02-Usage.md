# Usage and interpretation

Extract all files together and keep the two report scripts in scripts/. Read prerequisites and safe workflow. Run the collector in its own fresh PowerShell process; it exits with an assessment code.

```powershell
.\scripts\Invoke-XTAPAssessment.ps1 -ExpectedTenantId 'CUSTOMER-TENANT-GUID' -UserPrincipalName 'reader@customer.example' -OutputPath 'C:\Assessments\Customer-Full'
```

Authenticate interactively. Existing output paths are refused. The default requests unlimited active mailbox metadata, including SharingPolicy. It never reads message bodies or calendar items. Large tenants can take time and generate large assignment pages.

For an initial configuration-only run, add -SkipMailboxAssignments. For a limited test, add -MailboxLimit 100. A limit is not a representative sample; counts are lower bounds and cannot be extrapolated. Unlimited reads still obey RBAC scope and exclude inactive/soft-deleted mailboxes.

Advanced operators can use -UseExistingConnection only when exactly one active session matches ExpectedTenantId; that session remains open. Otherwise existing connections cause a safe stop. The collector creates and disconnects its own session and does not switch tenants automatically.

## Exit codes
- 0: requested reads completed. Skipped/limited coverage and all XTAP readiness gaps can still exist.
- 1: inventory denied, unavailable, partial or missing required properties.
- 2: module, authentication or tenant verification failed; no inventory calls attempted.

Unexpected local filesystem/report errors raise an error rather than a reliable assessment code. Check index.html, data/Metadata.json and collection statuses before using any output. When invoked from another process, inspect that process exit code; $LASTEXITCODE applies to native process invocation.

## Outputs
index.html summarizes outcomes and links to seven detail pages and collection-status.html. Each dataset has CSV/JSON under data/. Metadata records runtime/module versions, tenant verification, retrieval UTC, coverage and statuses. JSON is always an array, including empty []. Empty CSV contains a NoRows header only: consult status before interpreting emptiness.

HTML escapes values and contains no active scripts, external assets or telemetry. CSV text starting with formula-significant or whitespace characters is apostrophe-prefixed to reduce spreadsheet formula risk; JSON retains exact selected strings. Multi-value fields use semicolon separators; policy rules have a separate export. These selected-field exports are assessment evidence, not a restorable backup.

PolicyApplicability matches explicit mailbox policy references against Name, Identity, GUID and DistinguishedName. A blank SharingPolicy is inferred to use the single default policy. Missing properties, ambiguous/missing defaults and unmatched references remain unresolved. ObservedMailboxCount includes only resolved visible rows. Zero observed assignments cannot prove unused policy, and assignment cannot prove actual sharing activity.

PlanningWorksheet contains review prompts, not equivalent XTAP policies or deployment commands. Disabled objects remain visible. Confirm domains, hosting and partner tenant IDs independently. Wildcard, anonymous, contact-sharing and hybrid/on-premises rules require separate review. Existing XTAP trust/capabilities and rollout remain unverified.

Regenerate HTML offline on a copy of a completed report:

```powershell
.\scripts\New-XTAPHtmlReport.ps1 -ReportPath 'C:\Assessments\Customer-Full-Copy'
```

This overwrites generated HTML only. Preserve original evidence. Complete templates/Partner-Confirmation.csv separately with verified IDs, direction, owners, scopes and decisions; never include credentials.
