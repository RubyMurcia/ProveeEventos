// Utilidades compartidas por las reglas propias.
import { readFileSync } from 'node:fs';

export const readJson = (name) => JSON.parse(readFileSync(new URL(name, import.meta.url), 'utf8'));

export const normalized = (context) => context.filename.replaceAll('\\', '/');

export const READ_OPS = new Set([
  'findUnique',
  'findUniqueOrThrow',
  'findFirst',
  'findFirstOrThrow',
  'findMany',
  'count',
  'aggregate',
  'groupBy',
]);
export const DELETE_OPS = new Set(['delete', 'deleteMany']);
export const WRITE_OPS = new Set([
  'create',
  'createMany',
  'createManyAndReturn',
  'update',
  'updateMany',
  'updateManyAndReturn',
  'upsert',
  ...DELETE_OPS,
]);
export const ALL_OPS = new Set([...READ_OPS, ...WRITE_OPS]);

export const propertyName = (node) => {
  if (node?.type !== 'MemberExpression') return undefined;
  if (!node.computed && node.property.type === 'Identifier') return node.property.name;
  if (node.property.type === 'Literal') return String(node.property.value);
  return undefined;
};

/** Reconoce `cliente.modelo.operacion(...)` y devuelve sus partes. */
export function prismaCall(node) {
  const callee = node.callee;
  const op = propertyName(callee);
  if (op === undefined || !ALL_OPS.has(op)) return undefined;
  const target = callee.object;
  const model = propertyName(target);
  if (model === undefined) return undefined;
  const root = target.object;
  const client = root.type === 'Identifier' ? root.name : propertyName(root);
  return { op, model, client };
}
