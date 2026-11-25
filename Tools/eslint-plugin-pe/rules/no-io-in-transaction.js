// ADR-DATA-005 R2 y R4 (parte estática): sin efectos externos dentro de una transacción.
import { propertyName } from '../lib.js';

const WRAPPERS =
  /^(\$transaction|withTransaction|withTenant|withTenantTransaction|runInTransaction|transaction)$/;
const PORTS =
  /^(identityProvider|emailProvider|mediaStorage|mapsProvider|pdfRenderer|redis|redisClient)$/i;
const QUEUE = /queue/i;

const calleeName = (node) => (node.type === 'Identifier' ? node.name : propertyName(node));

export default {
  meta: {
    type: 'problem',
    schema: [],
    messages: {
      io: 'Prohibido `{{what}}` dentro de una transacción (ADR-DATA-005): usa el outbox.',
    },
  },
  create(context) {
    let depth = 0;
    const callbacks = new WeakSet();
    const isFunction = (node) =>
      node.type === 'ArrowFunctionExpression' || node.type === 'FunctionExpression';
    const enter = (node) => {
      if (callbacks.has(node)) depth += 1;
    };
    const exit = (node) => {
      if (callbacks.has(node)) depth -= 1;
    };
    return {
      CallExpression(node) {
        const name = calleeName(node.callee);
        if (name !== undefined && WRAPPERS.test(name)) {
          for (const argument of node.arguments) if (isFunction(argument)) callbacks.add(argument);
        }
        if (depth === 0) return;
        if (name === 'fetch') context.report({ node, messageId: 'io', data: { what: 'fetch' } });
        if (node.callee.type !== 'MemberExpression') return;
        const owner = calleeName(node.callee.object) ?? '';
        if (PORTS.test(owner) || (name === 'add' && QUEUE.test(owner))) {
          context.report({ node, messageId: 'io', data: { what: `${owner}.${name}` } });
        }
      },
      ArrowFunctionExpression: enter,
      'ArrowFunctionExpression:exit': exit,
      FunctionExpression: enter,
      'FunctionExpression:exit': exit,
    };
  },
};
