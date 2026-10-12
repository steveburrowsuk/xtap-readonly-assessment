# CTAP read-only customer assessment
Version 1.0.0 — guidance reviewed 12 October 2026.

Start with the prerequisite and usage guides. This bundle assesses Exchange Free/Busy, calendar sharing and MailTips migration to Microsoft 365 cross-tenant access policy. It is not a mailbox migration tool. It never modifies or removes tenant configuration. Graph is excluded from the initial run.

## Files
- scripts/Invoke-CTAPAssessment.ps1: verified customer connection, Exchange inventory, planning worksheet, CSV/JSON exports and HTML generation.
- scripts/New-CTAPHtmlReport.ps1: offline report regeneration.
- scripts/Graph-ReadOnly-Expansion.stub.ps1: non-executing future Graph outline.
- guides/: permissions, usage, troubleshooting, optional Graph, safe workflow and sources.
- templates/Partner-Confirmation.csv: blank review worksheet.
- tests/Test-Offline.ps1: isolated synthetic verification; no tenant connections.
- sample-report/: invented example data and linked HTML pages.
- VALIDATION.md and SHA256SUMS.csv: verification results and file checksums.

Run in a fresh PowerShell 7.4+ process with a supported ExchangeOnlineManagement v3 module already installed:

```powershell
.\scripts\Invoke-CTAPAssessment.ps1 -ExpectedTenantId 'CUSTOMER-TENANT-GUID' -UserPrincipalName 'reader@customer.example' -OutputPath 'C:\Assessments\Customer-FirstRun'
```

Replace placeholders. Open the resulting index.html and review collection status before interpreting counts. This assessment cannot establish CTAP readiness without further evidence. Reports contain confidential configuration and mailbox addresses. No customer tenant was contacted to prepare this bundle.

## Download
[Complete version 1.0.0 ZIP](downloads/CTAP-ReadOnly-Assessment-v1.0.0.zip) contains the original scripts, guides and synthetic sample report. Individual files are available in this repository. Keep customer output outside source control.
