# 🕶️ Morpheus Research Report: Legacy -> Laravel 11

**Topic**: Migrating Legacy Native PHP (2005) to Modern Laravel 11.
**Source**: The Real World (Web Search).
**Date**: 2026-01-05

## 1. The Strategy: "The Strangler Fig"
Do not rewrite everything at once. Use **Incremental Migration**.
*   **Parallel Operation**: Run the old PHP app *inside* the `public/legacy` folder of Laravel.
*   **Routing**: Use Laravel routes for new features, fallback to legacy files for old features.
*   **Outcome**: Zero downtime.

## 2. Key Tools (The Weaponry)
1.  **Rector**: A CLI tool that *automatically* upgrades PHP syntax (e.g., adds Types, fixes `mysql_` to `mysqli`).
    *   *Command*: `vendor/bin/rector process src`
2.  **Laravel Shift**: Automated service to upgrade Laravel versions (future proofing).
3.  **Migrations Generator**: `oscarfdev/migrations-generator`.
    *   *Usage*: Reverse engineers your existing MySQL DB into Laravel Migration files.

## 3. The Path (Step-by-Step)
1.  **Install Laravel 11**: `composer create-project laravel/laravel cis-modern`.
2.  **Reverse Engineer DB**: Generate migrations from your old DB.
3.  **Replace Auth**: Replace your insecure `users` table logic with `Laravel Breeze` or `Fortify`.
4.  **Refactor**: Move logic file-by-file.
    *   Old: `$_POST['user']`
    *   New: `request()->input('user')`

## 4. Morpheus Recommendation
Use **Rector** immediately. It can automate 40% of the syntax cleanup (changing `array()` to `[]`, adding type hints) before you even start the logic transfer.
