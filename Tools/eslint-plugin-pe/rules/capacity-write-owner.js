// ADR-DATA-002 R3 (regla de Capa 1): solo dos repositorios escriben capacidad.
import { normalized, prismaCall, propertyName, WRITE_OPS } from '../lib.js';

const REPOSITORIES =
  /\/backend\/src\/modules\/availability-booking\/(.+\/)?infrastructure\/(provider|package)-daily-capacity\.repository\.ts$/;
const EXEMPT = /\/backend\/src\/(tests|prisma\/seed)\//;
const MODELS = new Set(['providerDailyCapacity', 'packageDailyCapacity']);
const SQL = /_daily_capacity/i;

export default {
  meta: {
    type: 'problem',
    schema: [],
    messages: {
      write:
        'La capacidad solo se escribe en los repositorios `provider-daily-capacity.repository.ts` y `package-daily-capacity.repository.ts` de availability-booking.',
    },
  },
  create(context) {
    const file = normalized(context);
    if (EXEMPT.test(file) || REPOSITORIES.test(file)) return {};
    const report = (node) => context.report({ node, messageId: 'write' });
    return {
      CallExpression(node) {
        const call = prismaCall(node);
        if (call !== undefined && MODELS.has(call.model) && WRITE_OPS.has(call.op)) report(node);
      },
      Property(node) {
        if (node.key.type !== 'Identifier' || node.key.name !== 'consumed') return;
        const holder = node.parent.parent;
        if (holder?.type === 'Property' && ['data', 'update', 'create'].includes(holder.key.name))
          report(node);
      },
      AssignmentExpression(node) {
        if (propertyName(node.left) === 'consumed') report(node);
      },
      Literal(node) {
        if (typeof node.value === 'string' && SQL.test(node.value)) report(node);
      },
      TemplateElement(node) {
        if (SQL.test(node.value.raw)) report(node);
      },
    };
  },
};
