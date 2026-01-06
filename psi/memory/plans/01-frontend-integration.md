## Implementation Plan - Connecting the Woman in Red

# Goal
Connect the React Frontend (`LoginForm.jsx`) to the Laravel API (`/api/login`) to enable real authentication using the Legacy Bridge.

## User Review Required
> [!IMPORTANT]
> **Cross-Origin Resource Sharing (CORS)**: The Frontend (Port 5173) and Backend (Port 8889) are on different ports. We must ensure Laravel's CORS configuration permits this connection.

## Proposed Changes

### Frontend (React)
#### [MODIFY] [LoginForm.jsx](file:///Users/jarkius/workspace/The-matrix/project/modern/web/src/components/Login/LoginForm.jsx)
-   Replace `setTimeout` simulation with actual `fetch` call to `http://localhost:8889/api/login`.
-   Handle `200 OK`:
    -   Extract `token`.
    -   Save to `localStorage.setItem('auth_token', token)`.
    -   Save user info to Context/State (for now, just log it).
-   Handle `422 Unprocessable Entity` (Validation Errors):
    -   Display error messages from the API.

### Backend (Laravel)
#### [MODIFY] [cors.php](file:///Users/jarkius/workspace/The-matrix/project/modern/api/config/cors.php)
-   Ensure `allowed_origins` includes `http://localhost:5173`.

## Verification Plan

### Automated Tests
1.  **Playwright (`verification.spec.ts`)**:
    -   Update the test to actually fill in the credentials (`administrator` / `password`).
    -   Intercept the network request to verify the token exchange occurrs.
    -   Assert that the UI transitions (e.g., button state changes or redirect).

### Manual Verification
1.  Open `http://localhost:5173`.
2.  Open DevTools -> Network.
3.  Enter `administrator` / `password`.
4.  Click Login.
5.  Observe `POST /api/login` 200 OK.
6.  Check Application -> Local Storage for `auth_token`.
