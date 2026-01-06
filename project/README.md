# CIS Modernization Project

> "We are building the New World on top of the Old."

## Structure
*   **`legacy/`**: The original PHP 5.6 / MySQL application.
    *   *Status*: Migrated from `legacy_cis`. Awaiting Docker setup.
*   **`modern/api/`**: The new Laravel 11 Core.
    *   *Technology*: Laravel 11, MySQL, Redis.
    *   *Driver*: Docker (Laravel Sail).
    *   *Setup*: `cd modern/api && ./vendor/bin/sail up`
*   **`modern/web/`**: The new React User Interface.
    *   *Technology*: React, Vite.
    *   *Aesthetics*: The Woman in Red.
    *   *Setup*: `cd modern/web && npm run dev`
*   **`tests/`**: End-to-End Testing Suite.
    *   *Technology*: Playwright (TypeScript).
    *   *Goal*: Visual Regression (Legacy vs Modern).
    *   *Setup*: `cd tests && npx playwright test`

## Development Guide
### Prerequisites
- Docker & Docker Compose
- Node.js (for Frontend/Tests)

### Starting the New Core
```bash
# 1. API (Laravel)
cd modern/api
./vendor/bin/sail up -d

# 2. Frontend (React)
cd modern/web
npm run dev

# 3. Tests (Playwright)
cd tests
npx playwright test
```
