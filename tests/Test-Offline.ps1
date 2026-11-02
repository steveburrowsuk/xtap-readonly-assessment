#requires -Version 7.4
# Synthetic tests only. Fake Exchange module takes precedence in child processes.
[CmdletBinding()]
param([string]$WorkPath = (Join-Path ([IO.Path]::GetTempPath()) ('XTAP-Tests-'+[guid]::NewGuid().ToString('N'))))
$ErrorActionPreference='Stop'
if (Test-Path -LiteralPath $WorkPath) { throw 'Test work directory must not exist.' }
$null=New-Item -ItemType Directory -Path $WorkPath
$moduleDir=Join-Path $WorkPath 'modules/ExchangeOnlineManagement'
$null=New-Item -ItemType Directory -Path $moduleDir -Force
@'
function Connect-ExchangeOnline { [CmdletBinding()]param($ShowBanner,$UserPrincipalName) }
function Disconnect-ExchangeOnline { [CmdletBinding(SupportsShouldProcess)]param() }
function Get-ConnectionInformation {
    [CmdletBinding()]param()
    # Before connection the mock returns empty once; after connect it reports the fixture tenant.
    if (-not $script:checked) { $script:checked=$true; return }
    $tenant='11111111-1111-1111-1111-111111111111'
    if ($env:XTAP_TEST_CASE -eq 'WrongTenant') { $tenant='22222222-2222-2222-2222-222222222222' }
    [pscustomobject]@{State='Connected';TenantID=$tenant}
}
function Get-OrganizationRelationship {
    [CmdletBinding()]param()
    if ($env:XTAP_TEST_CASE -eq 'Denied') {
        Write-Error 'Access denied fixture' -Category PermissionDenied; return
    }
    if ($env:XTAP_TEST_CASE -eq 'Empty') { return }
    [pscustomobject]@{Name='<script>alert(1)</script>';Identity='Fixture';Guid='r1';DomainNames=@('partner.example','second.example');Enabled=$true;FreeBusyAccessEnabled=$true;FreeBusyAccessLevel='LimitedDetails';MailTipsAccessEnabled=$true;MailboxMoveEnabled=$true;FreeBusyAccessScope='ResourceGroup'}
    if ($env:XTAP_TEST_CASE -eq 'Partial') { Write-Error 'Synthetic transport interruption' -Category ConnectionError }
}
function Get-SharingPolicy {
    [CmdletBinding()]param()
    if ($env:XTAP_TEST_CASE -eq 'Empty') { return }
    [pscustomobject]@{Name='Default policy';Identity='Default policy';Guid='p1';DistinguishedName='CN=Default policy';Enabled=$true;Default=$true;Domains=@('*:CalendarSharingFreeBusySimple','Anonymous:CalendarSharingFreeBusySimple','partner.example:CalendarSharingFreeBusyDetail')}
}
function Get-AvailabilityAddressSpace {
    [CmdletBinding()]param()
    if ($env:XTAP_TEST_CASE -eq 'Empty') { return }
    [pscustomobject]@{Identity='aas1';ForestName='partner.example';AccessMethod='OrgWideFBToken';TargetTenantId='';TargetAutodiscoverEpr='https://autodiscover.example'}
}
function Get-EXOMailbox {
    [CmdletBinding()]param($ResultSize,$Properties)
    if ($env:XTAP_TEST_CASE -eq 'Empty') { return }
    if ($env:XTAP_TEST_CASE -eq 'MissingProperty') {
        [pscustomobject]@{DisplayName='Missing';PrimarySmtpAddress='missing@example.test';RecipientTypeDetails='UserMailbox'}; return
    }
    [pscustomobject]@{DisplayName='=FORMULA';PrimarySmtpAddress='one@example.test';RecipientTypeDetails='UserMailbox';SharingPolicy=$null}
    [pscustomobject]@{DisplayName='Explicit';PrimarySmtpAddress='two@example.test';RecipientTypeDetails='SharedMailbox';SharingPolicy='p1'}
    [pscustomobject]@{DisplayName='Unresolved';PrimarySmtpAddress='three@example.test';RecipientTypeDetails='UserMailbox';SharingPolicy='unknown-reference'}
}
if ($env:XTAP_TEST_CASE -eq 'Unavailable') {
    Export-ModuleMember -Function Connect-ExchangeOnline,Disconnect-ExchangeOnline,Get-ConnectionInformation,Get-OrganizationRelationship,Get-SharingPolicy,Get-EXOMailbox
} else { Export-ModuleMember -Function * }
'@ | Set-Content -LiteralPath (Join-Path $moduleDir 'ExchangeOnlineManagement.psm1') -Encoding utf8
$main=Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Invoke-XTAPAssessment.ps1'
$oldModulePath=$env:PSModulePath
$oldCase=$env:XTAP_TEST_CASE
$results=[Collections.Generic.List[object]]::new()
function Assert($Condition,$Message) { if (-not $Condition) { throw "Assertion failed: $Message" } }
try {
    $env:PSModulePath=(Join-Path $WorkPath 'modules')+[IO.Path]::PathSeparator+$oldModulePath
    foreach ($case in @('Success','Empty','Denied','Partial','WrongTenant','MissingProperty','Unavailable','Limited','Skipped')) {
        $env:XTAP_TEST_CASE=$case
        $out=Join-Path $WorkPath $case
        $extra=@()
        if ($case -eq 'Limited') { $extra=@('-MailboxLimit','100') }
        if ($case -eq 'Skipped') { $extra=@('-SkipMailboxAssignments') }
        & (Join-Path $PSHOME 'pwsh.exe') -NoProfile -File $main -ExpectedTenantId '11111111-1111-1111-1111-111111111111' -OutputPath $out @extra | Out-Null
        $exitCode=$LASTEXITCODE
        $meta=Get-Content (Join-Path $out 'data/Metadata.json') -Raw | ConvertFrom-Json
        $expected=if($case -eq 'WrongTenant'){2}elseif($case -in @('Denied','Partial','MissingProperty','Unavailable')){1}else{0}
        Assert ($exitCode -eq $expected) "$case exit code $exitCode expected $expected"
        Assert (Test-Path (Join-Path $out 'index.html')) "$case summary exists"
        if ($case -eq 'WrongTenant') { Assert (@($meta.Statuses | Where-Object Status -eq 'NotAttempted').Count -eq 4) 'wrong tenant inventory blocked' }
        if ($case -eq 'Partial') {
            Assert (@($meta.Statuses | Where-Object Status -eq 'PartialRead').Count -eq 1) 'partial status'
            Assert (@(Get-Content (Join-Path $out 'data/OrganizationRelationships.json') -Raw | ConvertFrom-Json).Count -eq 1) 'partial row retained'
        }
        if ($case -eq 'Empty') { Assert ((Get-Content (Join-Path $out 'data/SharingPolicies.json') -Raw).Trim() -eq '[]') 'empty JSON array' }
        if ($case -eq 'MissingProperty') {
            $assignment=Get-Content (Join-Path $out 'data/SharingPolicyAssignments.json') -Raw | ConvertFrom-Json
            Assert ($assignment[0].Resolution -like 'PropertyMissing*') 'missing property not default'
        }
        if ($case -eq 'Success') {
            $html=Get-Content (Join-Path $out 'OrganizationRelationships.html') -Raw
            Assert ($html.Contains('&lt;script&gt;') -and -not $html.Contains('<script>')) 'HTML escaping'
            $csv=Import-Csv (Join-Path $out 'data/SharingPolicyAssignments.csv')
            Assert ($csv[0].DisplayName -eq "'=FORMULA") 'CSV formula mitigation'
            $assignment=Get-Content (Join-Path $out 'data/SharingPolicyAssignments.json') -Raw | ConvertFrom-Json
            Assert ($assignment[0].Resolution -eq 'DefaultInferred') 'default policy resolution'
            Assert ($assignment[1].Resolution -eq 'ExplicitMatched') 'GUID reference resolution'
            Assert ($assignment[2].Resolution -like '*Unresolved') 'unknown policy preserved'
        }
        $results.Add([pscustomobject]@{Case=$case;ExitCode=$exitCode;Result='PASS'})
    }
    # Existing output must not be overwritten.
    $env:XTAP_TEST_CASE='Success'
    & (Join-Path $PSHOME 'pwsh.exe') -NoProfile -File $main -ExpectedTenantId '11111111-1111-1111-1111-111111111111' -OutputPath (Join-Path $WorkPath 'Success') 2>$null | Out-Null
    Assert ($LASTEXITCODE -ne 0) 'existing output refused'
    $results.Add([pscustomobject]@{Case='ExistingOutput';ExitCode=$LASTEXITCODE;Result='PASS'})
    # Syntax validation and prohibition of tenant mutation commands in collector.
    foreach ($file in Get-ChildItem (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts') -Filter '*.ps1') {
        $parseErrors=$null; $tokens=$null
        $ast=[Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$parseErrors)
        Assert ($parseErrors.Count -eq 0) "syntax $($file.Name)"
        $commands=$ast.FindAll({param($node) $node -is [Management.Automation.Language.CommandAst]},$true)
        foreach ($command in $commands) {
            $name=$command.GetCommandName()
            Assert ($name -notmatch '^(Set|New|Remove|Add|Update)-(Mg|Mailbox|SharingPolicy|OrganizationRelationship|AvailabilityAddressSpace|Role|ManagementRole)') "forbidden mutation: $name"
            Assert ($name -notin @('Invoke-RestMethod','Invoke-WebRequest','Invoke-MgGraphRequest','Connect-MgGraph')) "no live HTTP/Graph in bundle: $name"
        }
    }
    $results | Export-Csv (Join-Path $WorkPath 'TestResults.csv') -NoTypeInformation
    $results | Format-Table
    Write-Host "Synthetic evidence: $WorkPath"
} finally {
    $env:PSModulePath=$oldModulePath
    $env:XTAP_TEST_CASE=$oldCase
}
