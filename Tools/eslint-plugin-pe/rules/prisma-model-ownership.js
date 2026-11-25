// ADR-ARCH-005 R1, R3, R4 y ADR-DATA-016 R1, R3.
import { normalized, prismaCall, readJson } from '../lib.js';

const owners = readJson('./table-ownership.json');
const CLIENT_NAMES = /^(prisma|prismaClient|client|tx|db)$/;
const EXEMPT = /\/backend\/src\/(tests|prisma\/seed)\//;
const APPEND_ONLY = new Set([
  'update',
  'updateMany',
  'updateManyAndReturn',
  'upsert',
  'delete',
  'deleteMany',
  'create',
  'createManyAndReturn',
]);

function ownerPath(owner) {
  return owner === 'platform'
    ? /\/backend\/src\/shared\/infrastructure\//
    : new RegExp(`/backend/src/modules/${owner}/(.+/)?infrastructure/`);
}

export default {
  meta: {
    type: 'problem',
    schema: [],
    messages: {
      owner:
        '`{{model}}` solo se accede desde la infraestructura de su escritor ({{owner}}), TDD §2.',
      computed: 'Prohibido acceder al cliente Prisma por clave calculada.',
      auditAppendOnly: '`auditLog` es de solo inserción con `createMany` (ADR-DATA-016 R3).',
    },
  },
  create(context) {
    const file = normalized(context);
    if (EXEMPT.test(file)) return {};
    return {
      MemberExpression(node) {
        if (!node.computed || node.property.type === 'Literal') return;
        if (node.object.type === 'Identifier' && CLIENT_NAMES.test(node.object.name)) {
          context.report({ node, messageId: 'computed' });
        }
      },
      CallExpression(node) {
        const call = prismaCall(node);
        if (call === undefined || !Object.hasOwn(owners, call.model)) return;
        const { owner } = owners[call.model];
        if (!ownerPath(owner).test(file)) {
          context.report({ node, messageId: 'owner', data: { model: call.model, owner } });
        } else if (call.model === 'auditLog' && APPEND_ONLY.has(call.op)) {
          context.report({ node, messageId: 'auditAppendOnly' });
        }
      },
    };
  },
};
