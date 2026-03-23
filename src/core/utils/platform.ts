import { platform, homedir, tmpdir } from 'os';
import { readFileSync } from 'fs';

export type MatrixPlatform = 'macos' | 'linux' | 'windows' | 'wsl';

export function getPlatform(): MatrixPlatform {
  if (platform() === 'win32') return 'windows';
  if (platform() === 'darwin') return 'macos';
  try {
    const version = readFileSync('/proc/version', 'utf8');
    if (/microsoft/i.test(version)) return 'wsl';
  } catch {}
  return 'linux';
}

export const getHomeDir = (): string => homedir();
export const getTempDir = (): string => tmpdir();

export async function isPortOpen(port: number, host = '127.0.0.1'): Promise<boolean> {
  return new Promise((resolve) => {
    const socket = new (require('net').Socket)();
    socket.setTimeout(2000);
    socket.on('connect', () => { socket.destroy(); resolve(true); });
    socket.on('error', () => resolve(false));
    socket.on('timeout', () => { socket.destroy(); resolve(false); });
    socket.connect(port, host);
  });
}

export function isProcessAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

export function getPythonCmd(): string {
  return getPlatform() === 'windows' ? 'python' : 'python3';
}
