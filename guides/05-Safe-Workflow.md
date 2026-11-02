# Safe customer workflow

1. Agree scope, customer tenant GUID, reader identity and visibility with the customer administrator. Use an identity without unrelated write privileges for the initial test.
2. Prepare a trusted workstation and approved Exchange module. Review scripts/checksums. Follow execution/signing policy and interactive MFA; do not supply credential files or tokens.
3. Run synthetic offline tests and inspect the sample report; neither requires a customer connection.
4. Run configuration-only discovery first if preferred. Confirm verified tenant and collection outcomes before interpreting counts.
5. Run full active mailbox metadata collection to a new folder when authorized. Resolve denied, partial, missing-property and unresolved-reference gaps. Customer administrator confirmation of tenant-wide visibility is required before treating totals as complete.
6. Store original dated exports in restricted customer storage under their retention policy. Mailbox addresses, partner configuration and scopes are confidential. Never add customer data to a broadly distributed bundle.
7. Review legacy items with business owners and partners. Verify tenant IDs, Microsoft 365 hosting, direction, access detail, resource/external-user scopes, wildcard/anonymous rules and coexistence. Preserve other relationship functions, particularly mailbox moves. Configuration is not evidence of actual business use.
8. Keep existing XTAP trust/capabilities and rollout unverified until separately approved evidence is available. Optional Graph uses only a separately approved read scope and can still have capability-read gaps.
9. Produce a human-approved migration design outside this assessment, including implementation, real-client testing in both directions, rollback and cleanup approval. Never deploy or remove configuration from these scripts.
10. Secure output, close the process and disconnect owned sessions (automatic on normal collection completion). No configuration rollback is needed. Microsoft can record sign-in and service audit events even for reads.

There is no apply or cleanup mode. The collector cannot prove its identity has no additional privileges; an administrator must confirm that. Selected-field exports are not a complete rollback backup.
