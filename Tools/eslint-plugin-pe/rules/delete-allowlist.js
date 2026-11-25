// ADR-DATA-017 R1: solo filas reemplazables y, en el worker, tablas técnicas. El resto lo borra
// únicamente el job de retención, cuyo repositorio se nombra `*.retention.ts`.
import { DELETE_OPS, normalized, prismaCall, readJson } from '../lib.js';

const allow = readJson('./delete-allowlist.json');
const owners = readJson('./table-ownership.json');
const replaceable = new Set(allow.replaceable);
const technical = new Set(allow.technicalWorkerOnly);
const modelByTable = new Map(Object.entries(owners).map(([model, { table }]) => [table, model]));
const SQL_DELETE = /\bDELETE\s+FROM\s+(?:ONLY\s+)?(?:public\.)?"?(\w+)"?/gi;
const EXEMPT = /\/backend\/src\/(tests|prisma\/seed)\//;
const WORKER = /\/backend\/src\/(jobs|shared\/infrastructure)\//;
const RETENTION = /\/modules\/[^/]+\/(.+\/)?infrastructure\/[^/]+\.retention\.ts$/;

export default {
  meta: {
    type: 'problem',
    schema: [],
    messages: {
      delete:
        '`{{model}}.{{op}}` no está permitido (ADR-DATA-017 R1): usa borrado lógico o el job de retención.',
    },
  },
  create(context) {
    const file = normalized(context);
    if (EXEMPT.test(file) || RETENTION.test(file)) return {};
    const permitted = (model) =>
      replaceable.has(model) || (technical.has(model) && WORKER.test(file));
    const checkSql = (node, text) => {
      for (const [, table] of text.matchAll(SQL_DELETE)) {
        const model = modelByTable.get(table);
        if (model !== undefined && !permitted(model)) {
          context.report({ node, messageId: 'delete', data: { model, op: 'DELETE' } });
        }
      }
    };
    return {
      Literal(node) {
        if (typeof node.value === 'string') checkSql(node, node.value);
      },
      TemplateElement(node) {
        checkSql(node, node.value.raw);
      },
      CallExpression(node) {
        const call = prismaCall(node);
        if (call === undefined || !DELETE_OPS.has(call.op) || !Object.hasOwn(owners, call.model))
          return;
        if (permitted(call.model)) return;
        context.report({ node, messageId: 'delete', data: call });
      },
    };
  },
};
