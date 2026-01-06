## Blueprint - Authentication Bridge

### Current State
*   **Legacy**: PHP Monolith, Dual-Auth (MD5 for Admin/Backdoor, LDAP for Users). Table: `tis_users`.
*   **Modern**: Laravel 11 API (Fresh), React SPA (Vite).
*   **Gap**: Modern System has no knowledge of Legacy Users.

### Constraints
*   **Single Source of Truth**: Must use `tis_users` table. Cannot migrate users to a new table yet.
*   **Algorithm Compatibility**: Must support MD5 (Legacy) for specific users.
*   **Protocol**: State must be shared via Laravel Sanctum (SPA Cookie) or Token.

### Options
| Option | Pros | Cons |
|--------|------|------|
| **A: Sync Users** | Standard Laravel Auth works out of the box. | Data duplication. Sync issues. Passwords invalid (MD5 vs Bcrypt). |
| **B: Custom Provider (Read-Only)** | Single source of truth. Flexible. | Requires writing custom Laravel User Provider. |
| **C: Proxy to Legacy** | No logic duplication. | Slow. Tightly coupled to running legacy PHP code. |

### Recommendation
**Option B: Custom Legacy Provider**
We will implement a custom User Provider in Laravel that maps the `tis_users` table to a standard Eloquent model, but overrides the authentication logic to support the Legacy MD5 hashing.

### Implementation Outline
1.  **API Setup**: Run `php artisan install:api` to enable API routes.
2.  **Model Definition**: Create `LegacyUser` model mapped to `tis_users`.
    *   Map `users_name` -> `username`.
    *   Map `users_accesslevel` -> `role`.
3.  **Auth Logic**:
    *   Implement `LegacyGuard` or specific login controller logic.
    *   If `username` in `[administrator, it, ...]`: Hash input with MD5, compare with DB.
    *   Else: Fail (Mock LDAP later).
4.  **Sanctum**: Enable Sanctum for session management.
5.  **Frontend**: Connect Login Form to `/login` endpoint.
