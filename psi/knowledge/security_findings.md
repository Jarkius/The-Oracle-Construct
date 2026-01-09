# Security Findings

**Last Updated**: 2026-01-10

## Legacy Authentication (`checklogin.php`)

**Source**: `psi/memory/learnings/2026-01-06-legacy-auth-discovery.md`

### Backdoor Roles
The legacy system allows login via specific usernames hardcoded to check against MD5 hashes, bypassing standard authentication.

- **Check**: Username in `["administrator", "it", "gs", "itm", "dataviewer"]`.
- **Method**: MD5 Hash.
- **Credential Found**: `administrator` / `password`.
- **Hash**: `5f4dcc3b5aa765d61d8327deb882cf99`.

### Standard Authentication
- **Method**: Active Directory (LDAP).
- **Function**: `adLDAP->authenticate()`.

**Implication**: Modernization must account for these hardcoded roles or explicitly deprecate them.
