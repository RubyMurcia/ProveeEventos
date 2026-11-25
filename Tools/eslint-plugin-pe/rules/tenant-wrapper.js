// ADR-DATA-008 R3: los modelos de clase (a) se usan solo con el cliente transaccional del envoltorio (`tx`).
import { normalized, prismaCall, readJson } from '../lib.js';

const tenantModels = new Set(readJson('./tenant-tables.json').models);
const EXEMPT = /\/backend\/src\/(tests|prisma\/seed)\//;

export default {
  meta: {
    type: 'problem',
    schema: [],
    messages: {
      wrapper:
        '`{{model}}` es de tenant: úsalo con `tx` dentro del envoltorio que ejecuta `set_config(..., true)`.',
    },
  },
  create(context) {
    if (EXEMPT.test(normalized(context))) return {};
    return {
      CallExpression(node) {
        const call = prismaCall(node);
        if (call !== undefined && tenantModels.has(call.model) && call.client !== 'tx') {
          context.report({ node, messageId: 'wrapper', data: { model: call.model } });
        }
      },
    };
  },
};
