# Application Shell Spec (Modern CIS)

**Component**: `Layout.jsx`
**Type**: Global Wrapper

## 1. Requirements
- **Protected Routes**: Must wrap all dashboard pages. Redirect to `/login` if no auth.
- **Responsive Navigation**: 
  - Desktop: Sidebar (Left)
  - Mobile: Hamburger Menu (Top)
- **Persistent State**: Current user / active menu item must persist on reload.

## 2. Layout Structure (Grid)

```
+------------------+-----------------------------------------------+
|                  |                                               |
|   SIDEBAR        |   TOPBAR (Breadcrumbs, User Profile)          |
|   (Fixed)        |                                               |
|   w-64           +-----------------------------------------------+
|   bg-card        |                                               |
|                  |   MAIN CONTENT AREA                           |
|                  |   (Scrollable)                                |
|                  |   bg-background                               |
|                  |   p-6                                         |
|                  |                                               |
+------------------+-----------------------------------------------+
```

## 3. Navigation Items (Sidebar)

| Label | Icon | Route |
|-------|------|-------|
| Dashboard | LayoutDashboard | `/dashboard` |
| Inventory | Box | `/inventory` |
| Users | Users | `/users` |
| Settings | Settings | `/settings` |

## 4. Visual Style
- **Sidebar**: Border-right (`border-border`), clean white/gray background.
- **Active Item**: Text (`text-primary`), Background (`bg-primary/10`), Left Border Indicator.
- **Transitions**: Smooth fade-in for main content (`fade-in-up`).

## 5. Implementation Plan
1. Fix `tailwind.config.js` to enable semantic colors.
2. Create `components/Layout/Sidebar.jsx`.
3. Create `components/Layout/Layout.jsx` (Outlet wrapper).
4. Update `App.jsx` to use Layout.
