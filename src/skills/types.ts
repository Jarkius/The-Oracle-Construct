/**
 * Skill Registry Types
 *
 * Interfaces for the skill manifest, versioning, and resolution system.
 * Part of Phase 12: Skill Registry + Versioning.
 */

/**
 * A skill's manifest — the declarative contract describing what a skill is,
 * what it needs, and how to invoke it.
 */
export interface SkillManifest {
  /** Unique skill identifier (e.g. "neo", "commit:push") */
  id: string;
  /** Semantic version string (e.g. "1.2.3") */
  version: string;
  /** Human-readable description of what this skill does */
  description: string;
  /** Author or owning agent/team */
  author?: string;
  /** Skill IDs this skill depends on (id@versionRange) */
  dependencies: string[];
  /** File path or workflow path to invoke the skill */
  entrypoint: string;
  /** Permissions this skill requires (e.g. "fs:read", "net:connect") */
  permissions: string[];
  /** Categorization tags for search/filtering */
  tags: string[];
  /** Other skill IDs this skill can compose with */
  compose?: string[];
}

/**
 * A specific installed version of a skill with lifecycle state.
 */
export interface SkillVersion {
  /** Skill identifier */
  id: string;
  /** Semantic version string */
  version: string;
  /** ISO timestamp when this version was installed */
  installedAt: string;
  /** ISO timestamp when this version was last invoked */
  lastUsed?: string;
  /** Lifecycle status */
  status: 'active' | 'deprecated' | 'removed';
}

/**
 * Result of resolving a skill — includes the manifest, filesystem path,
 * and whether the resolution was successful.
 */
export interface SkillResolution {
  /** The resolved skill manifest */
  manifest: SkillManifest;
  /** Filesystem path to the skill entrypoint */
  path: string;
  /** Whether the skill was fully resolved (dependencies met, etc.) */
  resolved: boolean;
}
