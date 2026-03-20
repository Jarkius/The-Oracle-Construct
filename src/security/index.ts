/**
 * Security Module — Permission Enforcement Layer
 *
 * Barrel exports for the security module.
 */

// Types
export type {
  PermissionMode,
  PermissionDeclaration,
  PermissionCheckResult,
  ElevationRequest,
  ElevationGrant,
} from './types';

export {
  PERMISSION_MODE_MAP,
  WRITE_TOOLS,
  EXEC_TOOLS,
  SPAWN_TOOLS,
  READ_TOOLS,
  MODE_RESTRICTIONS,
} from './types';

// Permission Resolver
export { PermissionResolver, getPermissionResolver } from './permission-resolver';

// Enforcement Engine
export { EnforcementEngine, getEnforcementEngine } from './enforcement-engine';

// Elevation Manager
export { ElevationManager, getElevationManager } from './elevation';
