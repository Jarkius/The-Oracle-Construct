/**
 * Lightweight Semver Utilities
 *
 * Provides parsing, comparison, range matching, and bumping for
 * semantic version strings. No external dependencies.
 */

export interface SemverParts {
  major: number;
  minor: number;
  patch: number;
}

const SEMVER_RE = /^(\d+)\.(\d+)\.(\d+)$/;

/**
 * Parse a semver string into its components.
 * Returns null if the string is not a valid semver.
 */
export function parseSemver(version: string): SemverParts | null {
  const m = SEMVER_RE.exec(version.trim());
  if (!m) return null;
  return {
    major: parseInt(m[1], 10),
    minor: parseInt(m[2], 10),
    patch: parseInt(m[3], 10),
  };
}

/**
 * Compare two semver strings.
 * Returns -1 if a < b, 0 if equal, 1 if a > b.
 */
export function compareSemver(a: string, b: string): -1 | 0 | 1 {
  const pa = parseSemver(a);
  const pb = parseSemver(b);
  if (!pa || !pb) return 0;

  if (pa.major !== pb.major) return pa.major < pb.major ? -1 : 1;
  if (pa.minor !== pb.minor) return pa.minor < pb.minor ? -1 : 1;
  if (pa.patch !== pb.patch) return pa.patch < pb.patch ? -1 : 1;
  return 0;
}

/**
 * Check if a version satisfies a range.
 *
 * Supported range formats:
 * - Exact: "1.2.3" — must match exactly
 * - Caret: "^1.2.3" — >=1.2.3 and <2.0.0 (compatible with major)
 * - Tilde: "~1.2.3" — >=1.2.3 and <1.3.0 (compatible with minor)
 * - Wildcard: "*" — matches any version
 */
export function satisfies(version: string, range: string): boolean {
  const trimmed = range.trim();

  // Wildcard
  if (trimmed === '*') return true;

  const ver = parseSemver(version);
  if (!ver) return false;

  // Caret range: ^X.Y.Z — same major, >= minor.patch
  if (trimmed.startsWith('^')) {
    const rangeVer = parseSemver(trimmed.slice(1));
    if (!rangeVer) return false;
    if (ver.major !== rangeVer.major) return false;
    if (ver.minor < rangeVer.minor) return false;
    if (ver.minor === rangeVer.minor && ver.patch < rangeVer.patch) return false;
    return true;
  }

  // Tilde range: ~X.Y.Z — same major.minor, >= patch
  if (trimmed.startsWith('~')) {
    const rangeVer = parseSemver(trimmed.slice(1));
    if (!rangeVer) return false;
    if (ver.major !== rangeVer.major) return false;
    if (ver.minor !== rangeVer.minor) return false;
    if (ver.patch < rangeVer.patch) return false;
    return true;
  }

  // Exact match
  const rangeVer = parseSemver(trimmed);
  if (!rangeVer) return false;
  return ver.major === rangeVer.major &&
         ver.minor === rangeVer.minor &&
         ver.patch === rangeVer.patch;
}

/**
 * Return the latest (highest) version from an array of semver strings.
 * Invalid versions are ignored. Returns empty string if no valid versions.
 */
export function latest(versions: string[]): string {
  let best: string = '';
  for (const v of versions) {
    if (!parseSemver(v)) continue;
    if (!best || compareSemver(v, best) > 0) {
      best = v;
    }
  }
  return best;
}

/**
 * Bump a version by the specified component.
 * Returns the bumped version string, or the original if invalid.
 */
export function bump(version: string, type: 'major' | 'minor' | 'patch'): string {
  const parts = parseSemver(version);
  if (!parts) return version;

  switch (type) {
    case 'major':
      return `${parts.major + 1}.0.0`;
    case 'minor':
      return `${parts.major}.${parts.minor + 1}.0`;
    case 'patch':
      return `${parts.major}.${parts.minor}.${parts.patch + 1}`;
  }
}
