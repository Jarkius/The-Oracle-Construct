# Skill Development

Skill ecosystem for composable, versioned agent capabilities (Phases 12-13).

## Skill Manifest Format

Each skill is defined by a `skill.manifest.json` file:

```json
{
  "id": "commit:push",
  "version": "1.2.0",
  "description": "Stage, commit, and push changes to remote",
  "author": "Tank",
  "dependencies": ["commit:stage@^1.0"],
  "entrypoint": ".agent/workflows/commit.md",
  "permissions": ["fs:write", "exec:git"],
  "tags": ["git", "workflow"],
  "compose": ["commit:stage", "commit:verify"]
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier (e.g. `"neo"`, `"commit:push"`) |
| `version` | Yes | Semver string (e.g. `"1.2.0"`) |
| `description` | Yes | What this skill does |
| `author` | No | Owning agent or team |
| `dependencies` | Yes | Skill IDs with optional version ranges (`id@^1.0`) |
| `entrypoint` | Yes | File path or workflow path to invoke |
| `permissions` | Yes | Required permissions (e.g. `"fs:read"`, `"exec:git"`) |
| `tags` | Yes | Categorization for search/filtering |
| `compose` | No | Other skill IDs this skill bundles together |

## Versioning

Versions follow semver (`major.minor.patch`). Range matching supports:

| Range | Meaning |
|-------|---------|
| `^1.2.0` | Compatible: `>=1.2.0 <2.0.0` |
| `~1.2.0` | Patch-level: `>=1.2.0 <1.3.0` |
| `1.2.0` | Exact match |

The `latest()` function picks the highest version. `bump()` increments by major/minor/patch.

## Registry

SQLite-backed storage for skill manifests with lifecycle management.

```typescript
const registry = getSkillRegistry();

registry.register(manifest, '/path/to/skill');     // Store a skill
registry.resolve('commit:push', '^1.0');            // Find best matching version
registry.search('git');                             // Full-text search
registry.listByTag('workflow');                     // Filter by tag
registry.deprecate('old-skill', '0.9.0');           // Mark version deprecated
registry.listAll();                                 // All active skills
registry.getVersionHistory('commit:push');          // Version timeline
```

Status lifecycle: `active` -> `deprecated` -> `removed`

## Hot-Loading

`SkillHotLoader` watches skill directories and keeps the registry in sync with the filesystem.

| Behavior | Detail |
|----------|--------|
| Watch dirs | `.claude/skills/`, `.agent/skills/` (configurable) |
| File pattern | `skill.manifest.json` or `*.manifest.json` |
| Detection | `fs.watch` + periodic scan fallback (5s) |
| Events | `skill:added`, `skill:updated`, `skill:removed` |

## Composition

Skills with a `compose` field are bundles. The `SkillComposer` resolves them into ordered execution plans.

- **Topological sort**: Dependencies execute before dependents
- **Circular detection**: Errors on `A -> B -> A` cycles
- **Permission union**: Collects all permissions from component skills
- **Partial resolution**: Continues even if some components fail

## Creating a New Skill

1. Create a directory under `.claude/skills/` or `.agent/skills/`
2. Add `skill.manifest.json` with required fields
3. Implement the entrypoint (workflow markdown or TypeScript)
4. If the hot-loader is running, the skill registers automatically
5. Otherwise, call `POST /reload` on the loader daemon (port 37891)

### Loader Daemon API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/skills` | GET | List all registered skills |
| `/skills/:id` | GET | Get skill detail by ID |
| `/reload` | POST | Force re-scan of skill directories |
| `/health` | GET | Status, skill count, uptime |

## Key Source Files

| File | Purpose |
|------|---------|
| `src/skills/types.ts` | SkillManifest, SkillVersion, SkillResolution interfaces |
| `src/skills/versioning.ts` | Semver parsing, comparison, range matching |
| `src/skills/registry.ts` | SQLite-backed registration and resolution |
| `src/skills/hot-loader.ts` | Filesystem watcher with event emission |
| `src/skills/composer.ts` | Bundle resolution and dependency graphs |
| `src/skills/loader-daemon.ts` | Hono HTTP API for the skill registry |
| `src/skills/migration.ts` | Registry schema migrations |
| `src/skills/index.ts` | Barrel exports |
