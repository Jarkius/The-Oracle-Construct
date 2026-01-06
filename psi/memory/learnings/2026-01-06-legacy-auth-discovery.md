---
date: 2026-01-06
type: discovery
tags: [legacy, auth, security]
---

# Legacy Authentication Logic

**Source**: `project/legacy/phpsecurepages/checklogin.php`
**Table**: `tis_users`

## Mechanisms
1.  **Backdoor Roles**: Checks if username is in `["administrator", "it", "gs", "itm", "dataviewer"]`.
    *   **Method**: MD5 Hash comparison.
    *   **Default Creds**: `administrator` / `password` (Hash: `5f4dcc3b5aa765d61d8327deb882cf99`).
2.  **Standard Users**:
    *   **Method**: Active Directory (LDAP).
    *   **Logic**: `adLDAP->authenticate($en_login, $en_password)`.

## Implications for Modernization
*   We can easily test the "Backdoor" roles using the localized DB.
*   LDAP testing will require mocking or an actual AD connection (unlikely in local env).
*   **Strategy**: Focus verification on `administrator` role first.
