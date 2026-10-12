# Prerequisites and permissions

Use a customer identity already assigned Exchange Online **View-Only Organization Management**, containing View-Only Configuration and View-Only Recipients, with the intended read scope. The scripts do not assign roles. No Graph consent, app registration, secret, Entra administrator role or write permission is required initially.

Microsoft's CTAP migration procedure states Organization Management for inventory. Its RBAC documentation supports trying the view-only configuration and recipient roles first. This is a least-privilege test, not a guarantee of every cmdlet and parameter in every tenant. Actual reads are tested independently; failed reads do not trigger elevation.

| Read | Purpose | Initial strategy |
|---|---|---|
| Get-ConnectionInformation | Verify session tenant GUID | Module/session metadata |
| Get-OrganizationRelationship | Sharing flags, levels, scopes and other functions | View-Only Configuration |
| Get-SharingPolicy | Enabled/default state and rules | View-Only Configuration |
| Get-AvailabilityAddressSpace | Forest, method and targets | Attempt view-only configuration read |
| Get-EXOMailbox with SharingPolicy | Active mailbox policy applicability | View-Only Recipients |

An existing authorized customer administrator must confirm effective role membership, cmdlet/parameter access, propagation and read scope. Successful execution does not establish tenant-wide visibility. Get-ManagementRoleAssignment is deliberately not called because it can require Role Management. Missing commands may reflect RBAC, module version or restricted imports.

Use a supported Windows workstation, PowerShell 7.4+ and a current supported ExchangeOnlineManagement v3 release compatible with that runtime. Install the module separately through the customer's approved repository and process; the collector does not install dependencies. Interactive modern authentication, MFA, Conditional Access and Microsoft endpoint connectivity apply. Scripts are unsigned: follow customer signing/execution policy without disabling controls.

Confirm the expected tenant GUID independently in the customer's Entra overview. A fresh process is recommended. The collector requires exactly one connected Exchange session matching that GUID. Delegated partner scenarios need separate testing and can intentionally fail this guard. National/government cloud endpoint selection is outside this version; adapt and review before use there.

Graph Policy.Read.All is optional later. Exchange RBAC does not grant Entra policy reads. Its consent and supported role requirements are separate customer-admin setup decisions; see the optional guide. The bundle never requests write scopes or assigns privileged roles.
