# Product Context: CIS Modernization

## The Challenge
We are modernizing a legacy PHP/MySQL Customer Information System (CIS). The existing system is monolithic, using outdated PHP 5.x and a legacy driver, making it hard to maintain and scale.

## The Solution: Hybrid Service Architecture
We are moving from a Monolith to a **Hybrid Service** using the "Strangler Pattern".

### Architecture map
- **Gateway**: Nginx (Load Balancer)
- **New Core**: Laravel 11 API (handling `/api/*`)
- **UI**: React SPA (handling `/app/*`)
- **Legacy**: PHP 5.x Container (handling `/legacy/*`)

## The Vision (CIS 2026)
A modern, responsive application where:
1.  **Data is Safe**: Passwords are hashed, history is preserved.
2.  **API is Contractual**: Frontend and Backend are decoupled.
3.  **UI is Componentized**: Built with React, designed by The Woman in Red.

## Core Goals
- [ ] **Phase 1**: Foundation (Nginx, Laravel, Docker)
- [ ] **Phase 2**: Read-Only Views (Inventory)
- [ ] **Phase 3**: Write Logic (Tickets)
- [ ] **Phase 4**: Authentication
- [ ] **Phase 5**: Decommission Legacy
