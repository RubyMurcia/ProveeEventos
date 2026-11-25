// ADR-ARCH-008 R2: un módulo 'use client' no importa lib/api.
const API_CLIENT = /(^@\/lib\/api(\/|$))|((^|\/)lib\/api(\/|$))/;

export default {
  meta: {
    type: 'problem',
    schema: [],
    messages: { client: "Un módulo 'use client' no puede importar `lib/api` (solo servidor)." },
  },
  create(context) {
    const isClient = context.sourceCode.ast.body.some(
      (node) => node.type === 'ExpressionStatement' && node.directive === 'use client',
    );
    if (!isClient) return {};
    const check = (node) => {
      const source = node.source?.value;
      if (typeof source === 'string' && API_CLIENT.test(source))
        context.report({ node, messageId: 'client' });
    };
    return {
      ImportDeclaration: check,
      ImportExpression: check,
      ExportNamedDeclaration: check,
      ExportAllDeclaration: check,
    };
  },
};
