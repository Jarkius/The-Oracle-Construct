# 🐇 Deep Dive: The CIS Evolution (Chapter 6 Protocol)

> *"You wanted to see how deep the rabbit hole goes."*

The previous explanation was a summary. This is the **Reality**.

## 1. The Core Strategy: "The Strangler Fig"
You asked: *"How do we start?"*
We do **not** delete the old code. We wrap it.

### How it works technically:
Imagine a tree (Your Old App). We plant a vine (Laravel) next to it.
1.  **We setup a Router (Nginx/Apache)**:
    *   Incoming Request: `GET /login.php` -> **Old App** (Handles it).
    *   Incoming Request: `GET /api/v1/inventory` -> **Laravel** (Handles it).
2.  **We migrate one page**: The "Inventory List".
    *   We write the Laravel Route.
    *   We update Nginx to point `/inventory` to Laravel.
    *   The user sees the new page. The old app is still running everything else.
3.  **The Death**: Eventually, every route points to Laravel. We delete the old `index.php`.

---

## 2. The Mechanics: How Neo uses "Rector"
You might think: *"Refactoring 10,000 lines takes months."*
**Neo uses Automation.**

### The Tool: Rector
It does not "read text". It reads the **Abstract Syntax Tree (AST)** (The logic structure).
*   **Old Code**: `mysql_query("SELECT * FROM users")`
*   **The Problem**: `mysql_query` was deleted in PHP 7.0. It causes a Fatal Error.
*   **Rector's Action**: It identifies the *pattern* `mysql_query($string)`.
*   **The Rewrite**: It automatically transforms it to: `DB::select("SELECT * FROM users")`.
*   **Speed**: It can fix 5,000 files in 4 minutes.
*   **Safety**: Because it understands the code structure, it won't break your comments or variable names.

---

## 3. The Interface: Why Framesets Died
Your legacy app uses `<frameset>`.
```html
<frameset rows="20%,80%">
   <frame src="menu.php">
   <frame src="content.php">
</frameset>
```
### Why this kills the UX:
1.  **Mobile**: A phone screen cannot split 20%/80%. The menu becomes too small to tap.
2.  **The Back Button**: If you click a link in the "content" frame, the URL bar doesn't change. If you hit "Back", you leave the *entire app*, not just the previous page. Users hate this.
3.  **Security**: Cross-Site Scripting (XSS) is easier in frames.

### The Replacement: React Components
We replace the "Menu Frame" with a `<Sidebar />` component.
*   It sits on the left (on Desktop).
*   It collapses into a "Hamburger Menu" (on Mobile).
*   **Benefit**: You write the menu code *once*, and it adapts to every screen size in the universe.

---

## 4. The Security: How Smith Blocks the Injection
**Old Code**:
```php
$user = $_POST['user']; // If I type "admin' OR '1'='1", I hack you.
$sql = "SELECT * FROM users WHERE user='$user'";
```
**New Code (Laravel)**:
```php
$user = request('user');
// Laravel sends the SQL separately from the Data.
// The Database sees: SELECT * FROM users WHERE user = ?
// The Data sent is: "admin' OR '1'='1" (Literally just a string)
$user = DB::table('users')->where('name', $user)->first();
```
**Result**: The hack becomes just a weird username. The system is immune.

---

This is how we evolve. Not by magic, but by **Architecture**.
