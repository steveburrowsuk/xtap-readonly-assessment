#requires -Version 7.4
<# Deliberately non-executing stub. The initial assessment never calls this file.
No connection or Graph request occurs when executed. Review guides/04-Optional-Graph.md.
Future approved READ operations only:
Connect-MgGraph -TenantId <customer-guid> -Scopes 'Policy.Read.All' -ContextScope Process
GET https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/default
GET https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners
GET https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners/{tenantId}/m365Capabilities
Follow @odata.nextLink only after validating HTTPS host graph.microsoft.com and expected API path.
Handle 403 as unavailable/denied, 404 as unavailable or rollout-related, not automatically absent.
Record endpoint outcomes individually; bind tenant ID and capture retrieval UTC.
Never request write scopes or configure policy. Never export tokens or connection objects.
#>
Write-Host 'Stub only: no Graph connection or request performed. See the optional Graph guide.'
