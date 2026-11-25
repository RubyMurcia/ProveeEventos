import { readFileSync } from 'node:fs';
import path from 'node:path';

export const REPO_ROOT = path.resolve(import.meta.dirname, '../../../..');

/** Imagen fijada por digest en docker/images.env (única fuente). */
export function pinnedImage(name: string): string {
  const env = readFileSync(path.join(REPO_ROOT, 'docker/images.env'), 'utf8');
  const line = env.split('\n').find((entry) => entry.startsWith(`${name}=`));
  if (line === undefined) throw new Error(`Falta ${name} en docker/images.env`);
  return line.slice(name.length + 1).trim();
}
