# Microsoft references
Reviewed 12 October 2026. Recheck before a later implementation; APIs, roles and rollout can change.

- [CTAP migration inventory and rollout](https://learn.microsoft.com/en-us/exchange/sharing/migrate-to-m365-xtap)
- [Exchange RBAC and view-only role groups](https://learn.microsoft.com/en-us/exchange/permissions-exo/permissions-exo)
- [Effective feature permissions](https://learn.microsoft.com/en-us/exchange/permissions-exo/feature-permissions)
- [Mailbox property sets](https://learn.microsoft.com/en-us/powershell/exchange/cmdlet-property-sets?view=exchange-ps)
- [Exchange module compatibility](https://learn.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps)
- [Connection information](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/get-connectioninformation?view=exchange-ps)
- [Graph partner reads](https://learn.microsoft.com/en-us/graph/api/crosstenantaccesspolicy-list-partners?view=graph-rest-1.0)
- [Graph default policy reads](https://learn.microsoft.com/en-us/graph/api/crosstenantaccesspolicyconfigurationdefault-get?view=graph-rest-1.0)
- [Capability reads and delegated role caveat](https://learn.microsoft.com/en-us/graph/api/crosstenantaccesspolicyconfigurationpartner-list-m365capabilities?view=graph-rest-1.0)
- [Microsoft 365 CTAP API concepts](https://learn.microsoft.com/en-us/graph/api/resources/m365-cross-tenant-access-policy-overview?view=graph-rest-1.0)

View-Only-first is a practical RBAC-based test, not an override of the broader role stated in the migration procedure. Planning does not automatically translate legacy grants into CTAP policies.
