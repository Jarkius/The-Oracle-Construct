/**
 * Skill Registry + Versioning — Phase 12
 *
 * Barrel exports for the skill system.
 */

// Types
export type { SkillManifest, SkillVersion, SkillResolution } from './types';

// Versioning utilities
export { parseSemver, compareSemver, satisfies, latest, bump } from './versioning';
export type { SemverParts } from './versioning';

// Registry
export { SkillRegistry, getSkillRegistry } from './registry';

// Migration
export { migrateSkillRegistry } from './migration';

// Hot-Loader (Phase 13)
export { SkillHotLoader, getSkillHotLoader } from './hot-loader';

// Composer (Phase 13)
export { SkillComposer, getSkillComposer } from './composer';
export type { CompositionPlan } from './composer';
