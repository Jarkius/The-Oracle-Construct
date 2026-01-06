## Implementation Plan - The Construct (Dashboard Expansion)

# Goal
Transform the basic `Dashboard.jsx` into a fully functional "Construct" with navigation, persistent layout, and system widgets.

## User Review Required
> [!NOTE]
> **Design Philosophy**: We will maintain the "Woman in Red" aesthetic (Dark/Crimson/Glass) but ensure it is functional for a data-heavy interface.

## Proposed Changes

### 1. Layout Structure
#### [NEW] [Layout.jsx](file:///Users/jarkius/workspace/The-matrix/project/modern/web/src/components/Layout/Layout.jsx)
-   **Sidebar**: Collapsible navigation menu.
    -   *Links*: Dashboard, Inventory (Future), Users (Future), Settings.
-   **TopBar**: Breadcrumbs, User Profile, Logout.
-   **MainContent**: Slot for page content.

### 2. Dashboard Widgets
#### [MODIFY] [Dashboard.jsx](file:///Users/jarkius/workspace/The-matrix/project/modern/web/src/pages/Dashboard.jsx)
-   Replace text dump with Grid Layout of Widgets.
-   **Widget 1: System Status** (Green/Red indicators for Legacy/Modern/Auth).
-   **Widget 2: Recent Activity** (Mock list of recent logins).
-   **Widget 3: User Stats** (Role, ID, Session Time).

### 3. Authentication Persistence ("Remember Me")
#### [MODIFY] [LoginForm.jsx](file:///Users/jarkius/workspace/The-matrix/project/modern/web/src/components/Login/LoginForm.jsx)
-   Add "Remember Me" Checkbox.
-   If checked, use `localStorage` (Persistent).
-   If unchecked, use `sessionStorage` (Session only).
-   Update `AuthProvider` (or Context) to check both.

## Verification
-   [ ] **Visual**: Verify Layout responsiveness.
-   [ ] **Functional**: Verify "Remember Me" behavior (Close tab -> Reopen -> Still logged in vs Logged out).
