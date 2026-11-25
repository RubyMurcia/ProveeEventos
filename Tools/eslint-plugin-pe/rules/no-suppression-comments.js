// ADR-GOV-003 R1: ningún comentario puede desactivar un control. Complementa noInlineConfig y ban-ts-comment.
const FORBIDDEN =
  /eslint-(disable|enable)|^\s*eslint\s|@ts-(ignore|expect-error|nocheck)|prettier-ignore|\b(v8|c8|istanbul)\s+ignore\b|gitleaks:allow/i;

export default {
  meta: {
    type: 'problem',
    schema: [],
    messages: { suppression: 'Directiva de supresión prohibida (ADR-GOV-003). Corrige la causa.' },
  },
  create(context) {
    return {
      Program() {
        for (const comment of context.sourceCode.getAllComments()) {
          if (FORBIDDEN.test(comment.value)) {
            context.report({ loc: comment.loc, messageId: 'suppression' });
          }
        }
      },
    };
  },
};
