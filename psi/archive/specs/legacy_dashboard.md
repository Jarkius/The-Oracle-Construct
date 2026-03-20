# Legacy Dashboard Spec (Modern CIS)

**Source**: Architect's Analysis of http://localhost:8888/
**Date**: 2026-01-07

## 1. Navigation Menu (Sidebar)

| Legacy Label | Route | Icon | Priority |
|--------------|-------|------|----------|
| Home | `/dashboard` | LayoutDashboard | P0 |
| Search | `/search` | Search | P1 |
| Asset Management | `/assets` | Box | P0 |
| Service Tasks | `/tasks` | Wrench | P1 |
| Report | `/reports` | FileText | P2 |
| Administrator | `/admin` | Settings | P1 |

## 2. Dashboard Widgets

### 2.1 Ticket Status (P0)
**Data Source**: `/api/tickets/status`
```json
{
  "inhouse": { "queue": 5, "fixing": 3, "returnToGS": 2 },
  "outside": { "outsideFix": 1, "supplier": 0 }
}
```
**Display**: Grid of status counts with labels.

### 2.2 Inventory Status (P0)
**Data Source**: `/api/inventory/status`
```json
{
  "gsStorage": 245,
  "itStorage": 120,
  "assignedToUsers": 1110,
  "fixing": 15,
  "obsolete": 498,
  "total": 1988
}
```
**Display**: Vertical list with counts and calculated total.

### 2.3 My Tasks (P1)
**Data Source**: `/api/tasks/mine`
**Actions**: "Add New", "Show All"
**Display**: List of task items with status.

### 2.4 My Tickets (P0)
**Data Source**: `/api/tickets/mine`
**Columns**: ID, Date, Service Type, Serial No., Name, BU, Hire Date, Failure Details, Status
**Display**: Data table with pagination.

### 2.5 Quick Actions (P1)
**Actions**: 
- "New KBS" (Knowledge Base) -> `/kbs/new`
- "New Ticket" -> `/tickets/new`
**Display**: Large icon buttons.

## 3. Visual Style (Legacy Fidelity)

- **Header**: Dark blue/black with Deloitte logo
- **Accents**: Green (#86bc25) for status indicators
- **Tables**: Green headers, alternating row colors
- **Status Dot**: Green "ONLINE" indicator in header

## 4. Implementation Order

1. [x] Shell (Sidebar, Layout) - DONE
2. [ ] **Inventory Status Widget** - Connect to API
3. [ ] **Ticket Status Widget** - Connect to API
4. [ ] **My Tickets Table** - Connect to API
5. [ ] Quick Actions
6. [ ] Search Page
