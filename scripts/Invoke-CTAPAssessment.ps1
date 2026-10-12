#requires -Version 7.4
<# Read-only Exchange inventory. No Graph calls, role changes or migration commands.
Use a fresh PowerShell process. Output directories must not exist.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ExpectedTenantId,
    [string]$UserPrincipalName,
    [string]$OutputPath = (Join-Path (Get-Location) ('CTAP-Assessment-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,6))),
    [switch]$SkipMailboxAssignments,
    [ValidateRange(0,2147483647)][int]$MailboxLimit = 0,
    [switch]$UseExistingConnection
)
$ErrorActionPreference = 'Stop'
$expectedGuid = [guid]::Empty
if (-not [guid]::TryParse($ExpectedTenantId,[ref]$expectedGuid)) { throw 'ExpectedTenantId must be a customer tenant GUID.' }
if (Test-Path -LiteralPath $OutputPath) { throw 'OutputPath already exists. Choose a new directory; existing reports are never overwritten.' }
$null = New-Item -ItemType Directory -Path $OutputPath
$OutputPath = (Resolve-Path -LiteralPath $OutputPath).Path
$null = New-Item -ItemType Directory -Path (Join-Path $OutputPath 'data')
$statuses = [System.Collections.Generic.List[object]]::new()
$datasets = [ordered]@{}
$connectedByScript = $false
$connectionOK = $false
function Add-Status($Dataset,$Status,$Count,$Detail) {
    $statuses.Add([pscustomobject]@{Dataset=$Dataset;Status=$Status;Count=$Count;Detail=$Detail;TimeUtc=[datetime]::UtcNow.ToString('o')})
}
function Read-Dataset($Name,$Command,[hashtable]$Arguments,[string[]]$RequiredProperties) {
    $rows = [System.Collections.Generic.List[object]]::new()
    if (-not $connectionOK) { Add-Status $Name 'NotAttempted' 0 'Verified customer connection unavailable.'; return }
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Add-Status $Name 'CommandUnavailable' 0 'Command absent: check module version, imported command set and effective RBAC. Absence alone does not prove denial.'; return
    }
    try {
        # Capture streamed rows so a later failure cannot silently discard partial evidence.
        & $Command @Arguments -ErrorAction Stop | ForEach-Object { $rows.Add($_) }
        $missing = @($rows | Where-Object {
            $row = $_
            @($RequiredProperties | Where-Object { -not $row.PSObject.Properties[$_] }).Count -gt 0
        }).Count
        if ($missing -gt 0) { Add-Status $Name 'IncompleteProperties' $rows.Count "$missing rows omit required properties; values must not be inferred." }
        else { Add-Status $Name 'Success' $rows.Count 'Read completed; visibility remains subject to customer RBAC scope.' }
    } catch {
        # Do not export raw exception text, connection objects, tokens or diagnostic dumps.
        $category = [string]$_.CategoryInfo.Category
        $kind = if ($category -in @('PermissionDenied','SecurityError') -or $_.Exception.Message -match '(?i)access.denied|unauthorized|not authorized|forbidden|insufficient.*permission') {'PermissionDenied'} else {'ReadFailed'}
        if ($rows.Count -gt 0) { $kind = 'PartialRead' }
        Add-Status $Name $kind $rows.Count "Read did not complete. Error category: $category. See troubleshooting guide; raw exception suppressed."
    }
    $rows.ToArray()
}
function Flat($Objects,[string[]]$Columns) {
    foreach ($obj in $Objects) {
        $record = [ordered]@{}
        foreach ($column in $Columns) {
            $value = $obj.$column
            $record[$column] = if ($null -eq $value) { $null } elseif ($value -is [bool] -or $value -is [int]) { $value } else { (@($value | ForEach-Object { [string]$_ }) -join '; ') }
        }
        [pscustomobject]$record
    }
}
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not $UseExistingConnection) {
        if (@(Get-ConnectionInformation -ErrorAction Stop | Where-Object State -eq 'Connected').Count -gt 0) {
            throw 'Existing connection detected. Use a fresh process, or explicitly select UseExistingConnection.'
        }
        $argsConnect = @{ShowBanner=$false;ErrorAction='Stop'}
        if ($UserPrincipalName) { $argsConnect.UserPrincipalName=$UserPrincipalName }
        Connect-ExchangeOnline @argsConnect
        $connectedByScript = $true
    }
    $connections = @(Get-ConnectionInformation -ErrorAction Stop | Where-Object State -eq 'Connected')
    if ($connections.Count -ne 1 -or [string]$connections[0].TenantID -ne $expectedGuid.ToString()) {
        throw 'A single connected session matching ExpectedTenantId is required.'
    }
    $connectionOK = $true
    Add-Status 'Connection' 'Success' 1 'Customer tenant GUID verified against connected Exchange session.'
} catch {
    Add-Status 'Connection' 'Failed' 0 'Module, authentication or customer tenant verification failed. No inventory reads attempted. Use a fresh process and see troubleshooting.'
}
try {
    $orCols = @('Name','Identity','Guid','DomainNames','Enabled','FreeBusyAccessEnabled','FreeBusyAccessLevel','FreeBusyAccessScope','MailTipsAccessEnabled','MailTipsAccessLevel','MailTipsAccessScope','TargetSharingEpr','TargetAutodiscoverEpr','TargetApplicationUri','MailboxMoveEnabled','MailboxMoveCapability','MailboxMovePublishedScopes','PhotosEnabled','DeliveryReportEnabled','ArchiveAccessEnabled','TargetOwaURL')
    $spCols = @('Name','Identity','Guid','DistinguishedName','Enabled','Default','Domains')
    $aaCols = @('Identity','ForestName','AccessMethod','TargetAutodiscoverEpr','TargetServiceEpr','TargetTenantId','UseServiceAccount')
    $rels = @(Read-Dataset 'OrganizationRelationships' 'Get-OrganizationRelationship' @{} @('Name','DomainNames','Enabled','FreeBusyAccessEnabled','MailTipsAccessEnabled'))
    $policies = @(Read-Dataset 'SharingPolicies' 'Get-SharingPolicy' @{} @('Name','Identity','Enabled','Default','Domains'))
    $spaces = @(Read-Dataset 'AvailabilityAddressSpaces' 'Get-AvailabilityAddressSpace' @{} @('ForestName','AccessMethod'))
    $datasets.OrganizationRelationships = @(Flat $rels $orCols)
    $datasets.SharingPolicies = @(Flat $policies $spCols)
    $datasets.AvailabilityAddressSpaces = @(Flat $spaces $aaCols)
    $rules = @(foreach ($policy in $policies) {
        foreach ($rule in @($policy.Domains)) {
            $text = [string]$rule
            $parts = $text -split ':',2
            [pscustomobject]@{PolicyName=[string]$policy.Name;PolicyIdentity=[string]$policy.Identity;Enabled=$policy.Enabled;Domain=$parts[0].Trim();Actions=if($parts.Count -gt 1){$parts[1].Trim()}else{''};RawRule=$text}
        }
    })
    $datasets.SharingPolicyRules = $rules
    $assignments = @()
    if ($SkipMailboxAssignments) { Add-Status 'SharingPolicyAssignments' 'Skipped' 0 'Mailbox policy applicability unknown.' }
    else {
        $limit = if ($MailboxLimit -eq 0) {'Unlimited'} else {$MailboxLimit}
        $mailboxes = @(Read-Dataset 'SharingPolicyAssignments' 'Get-EXOMailbox' @{ResultSize=$limit;Properties=@('SharingPolicy','RecipientTypeDetails','DisplayName','PrimarySmtpAddress')} @('SharingPolicy','RecipientTypeDetails','PrimarySmtpAddress'))
        if ($MailboxLimit -gt 0) { Add-Status 'MailboxCoverage' 'Limited' $mailboxes.Count 'Explicit result limit used; policy counts are lower bounds, never tenant totals.' }
        else { Add-Status 'MailboxCoverage' 'RequestedUnlimited' $mailboxes.Count 'Active mailbox inventory only; scoped RBAC can still restrict visibility. Inactive and soft-deleted mailboxes excluded.' }
        $defaults = @($policies | Where-Object { $_.Default -eq $true })
        $assignments = @(foreach ($mailbox in $mailboxes) {
            $raw = [string]$mailbox.SharingPolicy
            $resolved = @()
            $basis = 'ExplicitUnresolved'
            if (-not $mailbox.PSObject.Properties['SharingPolicy']) { $basis='PropertyMissing' }
            elseif ([string]::IsNullOrWhiteSpace($raw)) { $resolved=$defaults; $basis='DefaultInferred' }
            else {
                $resolved = @($policies | Where-Object { $raw -in @([string]$_.Identity,[string]$_.Name,[string]$_.Guid,[string]$_.DistinguishedName) })
                $basis = 'ExplicitMatched'
            }
            if ($resolved.Count -ne 1) { $basis += '-Unresolved'; $effective='' } else { $effective=[string]$resolved[0].Identity }
            [pscustomobject]@{DisplayName=[string]$mailbox.DisplayName;PrimarySmtpAddress=[string]$mailbox.PrimarySmtpAddress;RecipientTypeDetails=[string]$mailbox.RecipientTypeDetails;RawSharingPolicy=$raw;EffectivePolicyIdentity=$effective;Resolution=$basis}
        })
    }
    $datasets.SharingPolicyAssignments = $assignments
    $datasets.PolicyApplicability = @(foreach ($policy in $policies) {
        [pscustomobject]@{PolicyName=[string]$policy.Name;PolicyIdentity=[string]$policy.Identity;Enabled=$policy.Enabled;Default=$policy.Default;ObservedMailboxCount=@($assignments | Where-Object EffectivePolicyIdentity -eq ([string]$policy.Identity)).Count;Interpretation='Observed assignments only; absence does not prove unused. Check collection status, limits, scope and unresolved rows.'}
    })
    $planning = [System.Collections.Generic.List[object]]::new()
    foreach ($rel in $rels) {
        foreach ($domain in @($rel.DomainNames)) {
            $planning.Add([pscustomobject]@{Source='OrganizationRelationship';SourceName=[string]$rel.Name;PartnerDomain=[string]$domain;Capabilities='Review FreeBusyAccessEnabled and MailTipsAccessEnabled with Enabled';Disposition='Review';LegacyScope=([string]$rel.FreeBusyAccessScope + '; ' + [string]$rel.MailTipsAccessScope);PartnerTenantId='';BusinessOwner='';PartnerHosting='Unverified';ExistingCTAP='Not assessed';OtherFeatures='Preserve relationship; inspect mailbox moves, photos, archive, delivery reports and OWA';NextStep='Confirm partner tenant, reciprocal configuration, direction, scopes, access levels and current business use.'})
        }
    }
    foreach ($rule in $rules) {
        $planning.Add([pscustomobject]@{Source='SharingPolicy';SourceName=$rule.PolicyName;PartnerDomain=$rule.Domain;Capabilities=$rule.Actions;Disposition='Review';LegacyScope='Observed mailbox policy assignments; see applicability';PartnerTenantId='';BusinessOwner='';PartnerHosting='Unverified';ExistingCTAP='Not assessed';OtherFeatures='Anonymous, wildcard and contact-sharing rules require separate review';NextStep='Confirm enabled policy, applicability and intended calendar detail. Wildcard is not a tenant ID; do not map automatically.'})
    }
    foreach ($space in $spaces) {
        $planning.Add([pscustomobject]@{Source='AvailabilityAddressSpace';SourceName=[string]$space.ForestName;PartnerDomain=[string]$space.ForestName;Capabilities='Free/Busy review';Disposition='Review';LegacyScope=[string]$space.AccessMethod;PartnerTenantId=[string]$space.TargetTenantId;BusinessOwner='';PartnerHosting='Unverified';ExistingCTAP='Not assessed';OtherFeatures='OrgWideFBToken is not dependent on EWS; do not label every address space EWS-affected';NextStep='Confirm hosting and access method; assess CTAP separately. Preserve hybrid/on-premises configuration.'})
    }
    $datasets.PlanningWorksheet = $planning.ToArray()
    Add-Status 'GraphCTAP' 'NotAssessed' 0 'Exchange-only run. No Graph connection, trust lookup, capabilities lookup or rollout verification.'
    foreach ($name in @($datasets.Keys)) {
        $rows = @($datasets[$name])
        ConvertTo-Json -InputObject $rows -Depth 12 | Set-Content -LiteralPath (Join-Path $OutputPath "data/$name.json") -Encoding utf8
        # Prevent spreadsheet formula execution. JSON preserves exact strings; CSV strings beginning with
        # = + - @ or whitespace/control characters are prefixed with an apostrophe.
        $safe = @(foreach ($row in $rows) {
            $record = [ordered]@{}
            foreach ($prop in $row.PSObject.Properties) {
                $value=$prop.Value
                if ($value -is [string] -and $value -match '^[=+@\-\s]') { $value="'"+$value }
                $record[$prop.Name]=$value
            }
            [pscustomobject]$record
        })
        if ($safe.Count -gt 0) { $safe | Export-Csv -LiteralPath (Join-Path $OutputPath "data/$name.csv") -NoTypeInformation -Encoding utf8 }
        else { '"NoRows"' | Set-Content -LiteralPath (Join-Path $OutputPath "data/$name.csv") -Encoding utf8 }
    }
    $metadata = [ordered]@{SchemaVersion='1.0';BundleVersion='1.0.0';GeneratedUtc=[datetime]::UtcNow.ToString('o');ExpectedTenantId=$expectedGuid.ToString();TenantVerified=$connectionOK;PowerShellVersion=[string]$PSVersionTable.PSVersion;ExchangeModuleVersion=[string](Get-Module ExchangeOnlineManagement | Select-Object -First 1 -ExpandProperty Version);MailboxLimit=$MailboxLimit;MailboxSkipped=[bool]$SkipMailboxAssignments;ReadOnly=$true;Readiness='Incomplete: Exchange inventory only; CTAP trust, capabilities, rollout, partner identity and real use unverified';Statuses=$statuses.ToArray()}
    $metadata | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $OutputPath 'data/Metadata.json') -Encoding utf8
    $statuses | Export-Csv -LiteralPath (Join-Path $OutputPath 'data/CollectionStatus.csv') -NoTypeInformation -Encoding utf8
    & (Join-Path $PSScriptRoot 'New-CTAPHtmlReport.ps1') -ReportPath $OutputPath
    Write-Host "Report saved to $OutputPath"
    $failures = @($statuses | Where-Object Status -in @('Failed','NotAttempted','CommandUnavailable','IncompleteProperties','PermissionDenied','ReadFailed','PartialRead'))
    $code = if (-not $connectionOK) {2} elseif ($failures.Count -gt 0) {1} else {0}
    Write-Host "Inventory exit code: $code (0 = requested reads complete, 1 = incomplete inventory, 2 = connection failure). CTAP readiness remains unverified."
} finally {
    if ($connectedByScript) { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue }
}
exit $code
