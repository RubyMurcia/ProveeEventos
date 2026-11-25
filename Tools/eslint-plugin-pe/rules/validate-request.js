// ADR-API-002 R1: `req.body|query|params` solo se leen en el middleware de validación.
import { normalized, propertyName } from '../lib.js';

const VALIDATION = /\/backend\/src\/shared\/http\/validate-request\.ts$/;
const EXEMPT = /\/backend\/src\/tests\//;
const FIELDS = new Set(['body', 'query', 'params']);

export default {
  meta: {
    type: 'problem',
    schema: [],
    messages: {
      raw: 'No leas `{{name}}` directamente: pasa por el middleware `shared/http/validate-request.ts` (ADR-API-002).',
    },
  },
  create(context) {
    const file = normalized(context);
    if (VALIDATION.test(file) || EXEMPT.test(file)) return {};
    const isRequest = (node) =>
      node.type === 'Identifier' && /^(req|request|_req)$/.test(node.name);
    return {
      MemberExpression(node) {
        const field = propertyName(node);
        if (field !== undefined && FIELDS.has(field) && isRequest(node.object)) {
          context.report({
            node,
            messageId: 'raw',
            data: { name: `${node.object.name}.${field}` },
          });
        }
      },
      VariableDeclarator(node) {
        if (node.id.type !== 'ObjectPattern' || node.init === null || !isRequest(node.init)) return;
        for (const property of node.id.properties) {
          if (property.type === 'Property' && FIELDS.has(property.key.name)) {
            context.report({
              node: property,
              messageId: 'raw',
              data: { name: `req.${property.key.name}` },
            });
          }
        }
      },
    };
  },
};
