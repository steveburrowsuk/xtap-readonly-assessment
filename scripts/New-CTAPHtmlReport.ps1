#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ReportPath)
$ErrorActionPreference='Stop'
function Encode-Html($Value) { [System.Net.WebUtility]::HtmlEncode([string]$Value) }
function Table($Rows) {
    $items=@($Rows)
    if ($items.Count -eq 0) { return '<p>No rows recorded. Check collection status before interpreting an empty dataset.</p>' }
    $columns=@($items[0].PSObject.Properties.Name)
    $html='<div class="scroll"><table><thead><tr>'
    foreach ($col in $columns) { $html+='<th scope="col">'+(Encode-Html $col)+'</th>' }
    $html+='</tr></thead><tbody>'
    foreach ($row in $items) {
        $html+='<tr>'
        foreach ($col in $columns) { $html+='<td>'+(Encode-Html $row.$col)+'</td>' }
        $html+='</tr>'
    }
    $html+'</tbody></table></div>'
}
function Page($Title,$Body,$File) {
    $html='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src ''none''; style-src ''unsafe-inline''; img-src ''none''; base-uri ''none''; form-action ''none''"><title>'+(Encode-Html $Title)+'</title><style>body{font:16px system-ui,sans-serif;max-width:1500px;margin:2rem auto;padding:0 1rem;color:#17263b;background:#f5f7fb}h1,h2{color:#153b66}a{color:#145aa6}nav{margin:1rem 0}table{border-collapse:collapse;background:white;font-size:14px;width:100%}td,th{padding:.65rem;border:1px solid #ccd6e2;text-align:left;vertical-align:top;overflow-wrap:anywhere;min-width:120px}th{background:#e2eaf4}.scroll{overflow:auto}.notice{padding:1rem;background:#fff0cc;border-left:5px solid #a86400}li{margin:.6rem 0}</style></head><body><nav><a href="index.html">Summary</a> | <a href="collection-status.html">Collection status</a></nav><h1>'+(Encode-Html $Title)+'</h1>'+$Body+'<footer><p>Confidential customer configuration. Static local report; no external assets or telemetry.</p></footer></body></html>'
    $html | Set-Content -LiteralPath (Join-Path $ReportPath $File) -Encoding utf8
}
$meta=Get-Content -LiteralPath (Join-Path $ReportPath 'data/Metadata.json') -Raw | ConvertFrom-Json
Page 'Collection status' ('<p>Success means the read completed within the account visibility. Partial, denied and missing results cannot prove absence.</p>'+(Table $meta.Statuses)) 'collection-status.html'
$names=@('OrganizationRelationships','SharingPolicies','SharingPolicyRules','AvailabilityAddressSpaces','SharingPolicyAssignments','PolicyApplicability','PlanningWorksheet')
$body='<p class="notice">ASSESSMENT INCOMPLETE: Exchange inventory only. Existing CTAP trust and capabilities, rollout availability, partner identity and business use remain unverified. This report does not authorize migration or removal.</p><p>Generated UTC: '+(Encode-Html $meta.GeneratedUtc)+'<br>Expected customer tenant: '+(Encode-Html $meta.ExpectedTenantId)+'<br>Tenant verified: '+(Encode-Html $meta.TenantVerified)+'<br>Mailbox limit: '+(Encode-Html $meta.MailboxLimit)+' (0 requests unlimited); skipped: '+(Encode-Html $meta.MailboxSkipped)+'</p><h2>Collection outcome</h2>'+(Table $meta.Statuses)+'<h2>Inventory and planning details</h2><ul>'
foreach ($name in $names) {
    $rows=@(Get-Content -LiteralPath (Join-Path $ReportPath "data/$name.json") -Raw | ConvertFrom-Json)
    $body+='<li><a href="'+$name+'.html">'+(Encode-Html $name)+'</a> — '+$rows.Count+' observed rows; <a href="data/'+$name+'.csv">CSV</a> / <a href="data/'+$name+'.json">JSON</a></li>'
    Page $name ('<p>Interpret results alongside <a href="collection-status.html">collection status</a>. Null values may mean unset configuration; missing properties are flagged separately. Planning rows are review prompts, not equivalent CTAP policies.</p>'+(Table $rows)) "$name.html"
}
$body+='</ul><h2>Next review</h2><p>Resolve collection gaps first. Confirm partner tenant IDs and Microsoft 365 hosting with the customer and partners. Review direction, scopes, enabled flags, access levels and other relationship functions. Policy assignment is not evidence of actual sharing. Retain all legacy configuration throughout assessment.</p><p><a href="data/Metadata.json">Run metadata</a> | <a href="data/CollectionStatus.csv">Collection status CSV</a></p>'
Page 'CTAP migration assessment — Exchange inventory' $body 'index.html'

